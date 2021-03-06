package modules;

use common;
use detect_devices;
use run_program;
use log;
use list_modules;
use modules::any_conf;

sub modules_descriptions() {
    my $f = '/lib/modules/' . c::kernel_version() . '/modules.description';
    map { my ($m, $d) = /(\S+)\s+(.*)/; $m =~ s/-/_/g; ($m => $d) } cat_($f);
}

sub module2description { +{ modules_descriptions() }->{$_[0]} }

sub category2modules_and_description {
    my ($categories) = @_;
    my %modules_descriptions = modules_descriptions();
    map { $_ => $modules_descriptions{$_} } category2modules($categories);
}

my %mappings_24_26 = (
    "usb_ohci" => "ohci_hcd",
    "usb_uhci" => "uhci_hcd",
    "uhci" => "uhci_hcd",
    "printer" => "usblp",
    "bcm4400" => "b44",
    "3c559" => "3c359",
    "3c90x" => "3c59x",
    "dc395x_trm" => "dc395x",
);
my %mappings_26_24 = reverse %mappings_24_26;
$mappings_26_24{uhci_hcd} = 'usb_uhci';

my @parallel_zip_modules = qw(imm ppa);

sub mapping_24_26 {
    my ($modname) = @_;
    $mappings_24_26{$modname} || $modname;
}
sub mapping_26_24 {
    my ($modname) = @_;
    $mappings_26_24{$modname} || $modname;
}

sub cond_mapping_24_26 {
    my ($modname) = @_;
    $mappings_24_26{$modname} || list_modules::filename2modname($modname);
}

sub module_is_available {
    my ($module) = @_;
    defined list_modules::modname2filename($module);
}

#-###############################################################################
#- module loading
#-###############################################################################
# handles dependencies
sub load_raw {
    my ($lm, $h_options) = @_;

    my $l;

    #  try to detect built-in modules by looking at /sys/module
    #  unfortunately it does not work for all modules eg :
    #  - networks protocols  like af_packet
    #  - filesystems
    foreach my $mod (@$lm) {
	$mod =~ s/-/_/g;
        if (-d "/sys/module/$mod") {
	  log::l("$mod already loaded");
    	} elsif ($mod =~ /af_packet/) {
	  if (-f "/proc/net/packet") {
	    log::l("$mod already loaded");
	  } else {
	    push @$l, $mod;
	  }
	} elsif (cat_("/proc/filesystems") =~ /$mod/) {
	  log::l("$mod already loaded");
	} elsif ($mod =~ /serial/) {
	  # hack ... must find who tries to load the module serial
	} else {
	  push @$l, $mod;
	}
    }

    if ($::testing || $::local_install) {
	log::l("i would load module $_ ($h_options->{$_})") foreach @$l;
    } else {
	run_program::run('/sbin/modprobe', $_, split(' ', $h_options->{$_})) 
	  or !run_program::run('/sbin/modprobe', '-n', $_) #- ignore missing modules
	  or die "insmod'ing module $_ failed" foreach @$l;
    }
    if (any { /^(mousedev|printer)$/ } @$l) {
	sleep 2;
    } elsif (member('usb_storage', @$l)) {
	#- usb_storage is only modprobed when we know there is some scsi devices
	#- so trying hard to wait for devices to be detected
	run_program::run('udevadm', 'settle');
    }
}
sub load_with_options {
    my ($l, $h_options) = @_;

    my @l = map {
	if_(member($_, 'plip', @parallel_zip_modules), 'parport_pc'),
	if_($_ eq 'vfat', 'nls_cp437', 'nls_iso8859_1'),
	if_(member($_, qw(btrfs xfs)), 'crc32c', 'crc32c-intel'),
	cond_mapping_24_26($_);
    } @$l;

    @l = filter_out_loaded_modules(@l) or return;

    my %options = map { cond_mapping_24_26($_) => $h_options->{$_} } keys %$h_options;
    load_raw(\@l, \%options);
}
sub load {
    my (@l) = @_;
    load_with_options(\@l, {});
}

# eg: load_and_configure($modules_conf, 'bt878', [ bttv => 'no_overlay=1' ])
sub load_and_configure {
    my ($conf, $module, $o_options) = @_;

    my @l = filter_out_loaded_modules(cond_mapping_24_26($module));
    load_raw(\@l, { cond_mapping_24_26($module) => $o_options });

    if (member($module, @parallel_zip_modules)
	&& ! -d "/proc/sys/dev/parport/parport0/devices/$module") {
	log::l("$module loaded but is not useful, removing");
	unload($module);
	return;
    }

    $conf->set_options($module, $o_options) if $o_options;

    when_load($conf, $module);
}

sub unload {
    if ($::testing) {
	log::l("rmmod $_") foreach @_;
    } else {
	run_program::run("rmmod", $_) foreach @_;
    }
}

sub load_category {
    my ($conf, $category, $o_wait_message) = @_;

    my @try_modules = (
      if_($category =~ /scsi/,
	  if_(detect_devices::usbStorage(), 'usb_storage'),
      ),
    );
    my @l = (
	(map {
	    my $other = { ahci => 'ata_piix', ata_piix => 'ahci' }->{$_->{driver}};
	    $_->{try} = 1 if $other;
	    ($_, if_($other, { %$_, driver => $other }));
	} detect_devices::probe_category($category)),
	(map { { driver => $_, description => $_, try => 1 } } @try_modules),
    );

    foreach (@l) {
	$o_wait_message->($_->{description}, $_->{driver}) if $o_wait_message;
	eval { load_and_configure($conf, $_->{driver}, $_->{options}) };
	$_->{error} = $@;

	$_->{try} = 1 if member($_->{driver}, 'hptraid', 'ohci1394'); #- do not warn when this fails
    }
    eval { load_and_configure($conf, 'ide_generic') } if $category eq 'disk/ide';
    grep { !($_->{error} && $_->{try}) } @l;
}

sub load_parallel_zip {
    my ($conf) = @_;

    grep { 
	eval { load_and_configure($conf, $_); 1 };
    } @parallel_zip_modules;
}

#-###############################################################################
#- modules.conf functions
#-###############################################################################
sub write_preload_conf {
    my ($conf) = @_;
    my @l;
    my $is_laptop = detect_devices::isLaptop();
    my $manufacturer = detect_devices::dmidecode_category('System')->{Manufacturer};
    push @l, 'scsi_hostadapter' if $conf->get_probeall('scsi_hostadapter');
    push @l, detect_devices::probe_name('Module');
    push @l, 'nvram' if $is_laptop;
    push @l, map { $_->{driver} } detect_devices::probe_category($_) foreach qw(multimedia/dvb multimedia/tv various/agpgart various/laptop input/joystick various/crypto disk/card_reader);
    push @l, 'padlock-aes', 'padlock-sha' if cat_("/proc/cpuinfo") =~ /rng_en/;
    push @l, 'evdev' if detect_devices::hasTouchpad();
    push @l, 'evdev' if any { $_->{HWHEEL} } detect_devices::getInputDevices();
    push @l, 'hdaps' if $is_laptop && $manufacturer eq 'LENOVO';
    append_to_modules_loaded_at_startup("$::prefix/etc/modprobe.preload", @l);
}

sub append_to_modules_loaded_at_startup_for_all_kernels {
    append_to_modules_loaded_at_startup($_, @_) foreach "$::prefix/etc/modprobe.preload";
}

sub append_to_modules_loaded_at_startup {
    my ($file, @l) = @_;
    my $l = join '|', map { '^\s*' . $_ . '\s*$' } @l;
    log::l("to put in $file ", join(", ", @l));

    substInFile { 
	$_ = '' if $l && /$l/;
	$_ .= join '', map { "$_\n" } @l if eof;
    } $file;
}

sub set_preload_modules {
    my ($service, @modules) = @_;
    my $preload_file = "$::prefix/etc/modprobe.preload.d/$service";
    if (@modules) {
        output_p($preload_file, join("\n", @modules, ''));
    } else {
        unlink($preload_file);
    }
    eval { load(@modules) } if @modules && !$::isInstall;
}


#-###############################################################################
#- internal functions
#-###############################################################################
sub loaded_modules() { 
    map { /(\S+)/ } cat_("/proc/modules");
}
sub filter_out_loaded_modules {
    my (@l) = @_;
    difference2([ uniq(@l) ], [ map { my $s = $_; $s =~ s/_/-/g; $s, $_ } loaded_modules() ]);
}

sub read_already_loaded { 
    my ($conf) = @_;
    when_load($conf, $_) foreach reverse loaded_modules();
}

sub when_load {
    my ($conf, $name) = @_;

    if (my $category = module2category($name)) {
	when_load_category($conf, $name, $category);
    }

    if (my @above = $conf->get_above($name)) {
	load(@above); #- eg: for snd-pcm-oss set by set_sound_slot()
    }
}

sub when_load_category {
    my ($conf, $name, $category) = @_;

    if ($category =~ m,disk/ide,) {
	$conf->add_probeall('ide-controller', $name);
	eval { load('ide_gd_mod') };
    } elsif ($category =~ m,disk/(scsi|hardware_raid|sata|firewire|virtual),) {
	$conf->add_probeall('scsi_hostadapter', $name);
	eval { load('sd_mod') };
    } elsif ($category eq 'bus/usb') {
	$conf->add_probeall('usb-interface', $name);
        -f '/sys/kernel/debug/usb/devices' or eval {
	    require fs::mount; fs::mount::sys_kernel_debug('');
	    #- ensure keyboard is working, the kernel must do the job the BIOS was doing
	    sleep 4;
	    load("usbhid") if detect_devices::usbKeyboards();
        };
    } elsif ($category eq 'bus/firewire') {
	$conf->set_alias('ieee1394-controller', $name);
    } elsif ($category =~ /sound/) {
	my $sound_alias = find { /^sound-slot-[0-9]+$/ && $conf->get_alias($_) eq $name } $conf->modules;
	$sound_alias ||= 'sound-slot-0';
	$conf->set_sound_slot($sound_alias, $name);
    } elsif ($category =~ m!disk/card_reader!) {
        my @modules = ('mmc_block', if_($name =~ /tifm_7xx1/, 'tifm_sd'));
        $conf->set_above($name, join(' ', @modules));
    }
}

1;
