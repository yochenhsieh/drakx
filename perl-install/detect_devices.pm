package detect_devices; # $Id$

use diagnostics;
use strict;
use vars qw($pcitable_addons $usbtable_addons);

#-######################################################################################
#- misc imports
#-######################################################################################
use log;
use common;
use devices;
use run_program;
use c;

#-#####################################################################################
#- Globals
#-#####################################################################################
my @netdevices = map { my $l = $_; map { "$l$_" } (0..3) } qw(eth tr fddi plip);
my %serialprobe = ();

#-######################################################################################
#- Functions
#-######################################################################################
sub dev_is_devfs { -e "/dev/.devfsd" }


sub get {
    #- Detect the default BIOS boot harddrive is kind of tricky. We may have IDE,
    #- SCSI and RAID devices on the same machine. From what I see so far, the default
    #- BIOS boot harddrive will be
    #- 1. The first IDE device if IDE exists. Or
    #- 2. The first SCSI device if SCSI exists. Or
    #- 3. The first RAID device if RAID exists.

    getIDE(), getSCSI(), getDAC960(), getCompaqSmartArray(), getATARAID();
}
sub hds         { grep { $_->{media_type} eq 'hd' && ($::isStandalone || !isRemovableDrive($_)) } get() }
sub tapes       { grep { $_->{media_type} eq 'tape' && ($::isStandalone || !isRemovableDrive($_)) } get() }
sub cdroms      { grep { $_->{media_type} eq 'cdrom' } get() }
sub burners     { grep { isBurner($_) } cdroms() }
sub dvdroms     { grep { isDvdDrive($_) } cdroms() }
sub raw_zips    { grep { member($_->{media_type}, 'fd', 'hd') && isZipDrive($_) } get() }
#-sub jazzs     { grep { member($_->{media_type}, 'fd', 'hd') && isJazzDrive($_) } get() }
sub ls120s      { grep { member($_->{media_type}, 'fd', 'hd') && isLS120Drive($_) } get() }
sub zips        { 
    map { 
	$_->{device} .= 4; 
	$_->{devfs_device} = $_->{devfs_prefix} . '/part4'; 
	$_;
    } raw_zips();
}

sub cdroms__faking_ide_scsi {
    my @l = cdroms();
    return @l if $::isStandalone;
    if (my @l_ide = grep { $_->{bus} eq 'ide' && isBurner($_) } @l) {
	require modules;
	modules::add_alias('scsi_hostadapter', 'ide-scsi');
	my $nb = 1 + max(-1, map { $_->{device} =~ /scd(\d+)/ } @l);
	foreach my $e (@l_ide) {	    
	    log::l("IDEBurner: $e->{device}");
	    $e->{device} = "scd" . $nb++;
	}
    }
    @l;
}
sub zips__faking_ide_scsi {
    my @l = raw_zips();
    if (my @l_ide = grep { $_->{bus} eq 'ide' && $::isInstall } @l) {
	require modules;
	modules::add_alias('scsi_hostadapter', 'ide-scsi');
	my $nb = 1 + max(-1, map { if_($_->{device} =~ /sd(\w+)/, ord($1) - ord('a')) } getSCSI());
	foreach my $e (@l_ide) {	    
	    my $faked = "sd" . chr(ord('a') + $nb++);
	    log::l("IDE Zip: $e->{device} => $faked");
	    $e->{device} = $faked;
	}
    }
    map { $_->{device} .= 4; $_ } @l;
}

sub floppies() {
    require modules;
    eval { modules::load("floppy") };
    my @fds = map {
	my $info = (!dev_is_devfs() || -e "/dev/fd$_") && c::floppy_info(devices::make("fd$_"));
	if_($info && $info ne '(null)', { device => "fd$_", devfs_device => "floppy/$_", media_type => 'fd', info => $info })
    } qw(0 1);
    my @ide = ls120s() and eval { modules::load("ide-floppy") };

    eval { modules::load("usb-storage") } if usbStorage();
    my @scsi = grep { $_->{media_type} eq 'fd' && !isZipDrive($_) && !isJazzDrive($_) } getSCSI();
    @ide, @scsi, @fds;
}
sub floppies_dev() { map { $_->{device} } floppies() }
sub floppy { first(floppies_dev()) }
#- example ls120, model = "LS-120 SLIM 02 UHD Floppy"

sub get_sys_cdrom_info {
    my (@drives) = @_;

    my @drives_order;
    foreach (cat_("/proc/sys/dev/cdrom/info")) {
	my ($t, $l) = split ':';
	my @l = split ' ', $l;
	if ($t eq 'drive name') {
	    @drives_order = map {
		s/^sr/scd/;
		my $dev = $_;
		first(grep { $_->{device} eq $dev } @drives);
	    } @l;
	} else {
	    my $capacity;
	    if ($t eq 'Can write CD-R') {
		$capacity = 'burner';
	    } elsif ($t eq 'Can read DVD') {
		$capacity = 'DVD';
	    }
	    if ($capacity) {
		each_index {
		    ($drives_order[$::i] || {})->{capacity} .= "$capacity " if $_;
		} @l;
	    }
	}
    }
}

sub get_devfs_devices {
    my (@l) = @_;

    my %h = (cdrom => 'cd', hd => 'disc');

    foreach (@l) {
	my $t = $h{$_->{media_type}} or next;
	$_->{devfs_device} = $_->{devfs_prefix} . '/' . $t;
    }
}

sub isBurner { 
    my ($e) = @_;
    $e->{capacity} =~ /burner/ and return 1;
      
    #- do not work for SCSI
    my $f = tryOpen($e->{device}); #- SCSI burner are not detected this way.
    $f && c::isBurner(fileno($f));
}
sub isDvdDrive {
    my ($e) = @_;
    $e->{capacity} =~ /DVD/ || $e->{info} =~ /DVD/ and return 1;

    #- do not work for SCSI
    my $f = tryOpen($e->{device});
    $f && c::isDvdDrive(fileno($f));
}
sub isZipDrive { $_[0]->{info} =~ /ZIP\s+\d+/ } #- accept ZIP 100, untested for bigger ZIP drive.
sub isJazzDrive { $_[0]->{info} =~ /\bJAZZ?\b/i } #- accept "iomega jaz 1GB"
sub isLS120Drive { $_[0]->{info} =~ /LS-?120|144MB/ }
sub isRemovableDrive { &isZipDrive || &isLS120Drive || $_[0]->{media_type} eq 'fd' } #-or &isJazzDrive }

sub isFloppyOrHD {
    my ($dev) = @_;
    require partition_table::raw;
    my $geom = partition_table::raw::get_geometry(devices::make($dev));
    $geom->{totalsectors} < 10 << 11 ? 'fd' : 'hd';
}

sub getSCSI() {
    my $err = sub { log::l("ERROR: unexpected line in /proc/scsi/scsi: $_[0]"); };

    my ($first, @l) = common::join_lines(cat_("/proc/scsi/scsi"));
    $first =~ /^Attached devices:/ or $err->($first);

    @l = map_index {
	my ($host, $channel, $id, $lun) = m/^Host: scsi(\d+) Channel: (\d+) Id: (\d+) Lun: (\d+)/ or $err->($_);
	my ($vendor, $model) = /^\s*Vendor:\s*(.*?)\s+Model:\s*(.*?)\s+Rev:/m or $err->($_);
	my ($type) = /^\s*Type:\s*(.*)/m or $err->($_);
	{ info => "$vendor $model", channel => $channel, id => $id, lun => $lun, 
	  device => "sg$::i", devfs_prefix => sprintf('scsi/host%d/bus%d/target%d/lun%d', $host, $channel, $id, $lun),
          raw_type => $type, bus => 'SCSI' };
    } @l;

    each_index {
	my $dev = "sd" . chr($::i + ord('a'));
	put_in_hash $_, { device => $dev, media_type => isZipDrive($_) ? 'hd' : isFloppyOrHD($dev) };
    } grep { $_->{raw_type} =~ /Direct-Access/ } @l;

    each_index {
	put_in_hash $_, { device => "st$::i", media_type => 'tape' };
    } grep { $_->{raw_type} =~ /Sequential-Access/ } @l;

    each_index {
	put_in_hash $_, { device => "scd$::i", media_type => 'cdrom' };
    } grep { $_->{raw_type} =~ /CD-ROM|WORM/ } @l;

    each_index {
	put_in_hash $_, { media_type => 'scanner' };
    } grep { $_->{raw_type} =~ /Scanner/ } @l;

    get_devfs_devices(@l);
    get_sys_cdrom_info(@l);
    @l;
}

my %eide_hds = (
    "ASUS" => "Asus",
    "CD-ROM CDU" => "Sony",
    "CD-ROM Drive/F5D" => "ASUSTeK",
    "Compaq" => "Compaq",
    "CONNER" => "Conner Peripherals",
    "IBM" => "IBM",
    "FUJITSU" => "Fujitsu",
    "HITACHI" => "Hitachi",
    "Lite-On" => "Lite-On Technology Corp.",
    "LTN" => "Lite-On Technology Corp.",
    "IOMEGA" => "Iomega",
    "MAXTOR" => "Maxtor",
    "Maxtor" => "Maxtor",
    "Micropolis" => "Micropolis",
    "PLEXTOR" => "Plextor",
    "QUANTUM" => "Quantum", 
    "SAMSUNG" => "Samsung",
    "Seagate " => "Seagate Technology",
    "ST3" => "Seagate Technology",
    "TEAC" => "Teac",
    "TOSHIBA" => "Toshiba",
    "TEAC" => "Teac",
    "TOSHIBA" => "Toshiba",
    "WDC" => "Western Digital Corp.",
);


sub getIDE() {
    my @idi;

    #- what about a system with absolutely no IDE on it, like some sparc machine.
    -e "/proc/ide" or return ();

    #- Great. 2.2 kernel, things are much easier and less error prone.
    foreach my $d (sort @{[glob_('/proc/ide/hd*')]}) {
	cat_("$d/driver") =~ /ide-scsi/ and next; #- already appears in /proc/scsi/scsi
	my $t = chomp_(cat_("$d/media"));
	my $type = $ {{disk => 'hd', cdrom => 'cdrom', tape => 'tape', floppy => 'fd'}}{$t} or next;
	my $info = chomp_(cat_("$d/model")) || "(none)";

	my $num = ord (($d =~ /(.)$/)[0]) - ord 'a';
	my ($vendor, $model) = map { 
	    if_($info =~ /^$_\b(-|\s*)(.*)/, $eide_hds{$_}, $2);
	} keys %eide_hds;

	my ($channel, $id) = ($num / 2, $num % 2);
	my $devfs_prefix = sprintf('ide/host0/bus%d/target%d/lun0', $channel, $id);

	push @idi, { media_type => $type, device => basename($d), 
		     devfs_prefix => $devfs_prefix,
		     info => $info, channel => $channel, id => $id, bus => 'ide', 
		     Vendor => $vendor, Model => $model };
    }
    get_devfs_devices(@idi);
    get_sys_cdrom_info(@idi);
    @idi;
}

sub getCompaqSmartArray() {
    my (@idi, $f);

    foreach ('array/ida', 'cpqarray/ida', 'cciss/cciss') {
	my $prefix = "/proc/driver/$_"; #- kernel 2.4 places it here
	$prefix = "/proc/$_" if !-e "${prefix}0"; #- kernel 2.2

	my ($name) = m|/(.*)|;
	for (my $i = 0; -r ($f = "${prefix}$i"); $i++) {
	    foreach (cat_($f)) {
		if (m|^\s*($name/.*?):|) {
		    push @idi, { device => $1, info => "Compaq RAID logical disk", media_type => 'hd', bus => 'ida' };
		}
	    }
	}
    }
    @idi;
}

sub getDAC960() {
    my %idi;

    #- We are looking for lines of this format:DAC960#0:
    #- /dev/rd/c0d0: RAID-7, Online, 17928192 blocks, Write Thru0123456790123456789012
    foreach (syslog()) {
	my ($device, $info) = m|/dev/(rd/.*?): (.*?),| or next;
	$idi{$device} = { info => $info, media_type => 'hd', device => $device, bus => 'dac960' };
    }
    values %idi;
}

sub getATARAID {
    my %l;
    foreach (syslog()) {
	my ($device) = m|^\s*(ataraid/d\d+):| or next;
	$l{$device} = { info => 'ATARAID block device', media_type => 'hd', device => $device, bus => 'ataraid' };
	log::l("ATARAID: $device");
    }
    values %l;
}

sub getNet() {
    grep { !(($::isStandalone || $::live) && /plip/) && c::hasNetDevice($_) } @netdevices;
}

#sub getISDN() {
#    mapgrep(sub {member (($_[0] =~ /\s*(\w*):/), @netdevices), $1 }, split(/\n/, cat_("/proc/net/dev")));
#}

$pcitable_addons = <<'EOF';
# add here lines conforming the pcitable format (0xXXXX\t0xXXXX\t"\w+"\t".*")
EOF

$usbtable_addons = <<'EOF';
# add here lines conforming the usbtable format (0xXXXX\t0xXXXX\t"\w+"\t".*")
EOF

sub add_addons {
    my ($addons, @l) = @_;

    foreach (split "\n", $addons) {
	/^\s/ and die "bad detect_devices::probeall_addons line \"$_\"";
	s/^#.*//;
	s/"(.*?)"/$1/g;
	next if /^$/;
	my ($vendor, $id, $driver, $description) = split("\t", $_, 4) or die "bad detect_devices::probeall_addons line \"$_\"";
	foreach (@l) {
	    $_->{vendor} == hex $vendor && $_->{id} == hex $id or next;
	    put_in_hash($_, { driver => $driver, description => $description });
	}
    }
    @l;
}

sub pci_probe {
    my ($probe_type) = @_;
    log::l("full pci_probe") if $probe_type;
    add_addons($pcitable_addons, map {
	my %l;
	@l{qw(vendor id subvendor subid pci_bus pci_device pci_function media_type driver description)} = split "\t";
	$l{$_} = hex $l{$_} foreach qw(vendor id subvendor subid);
	$l{bus} = 'PCI';
	\%l
    } c::pci_probe($probe_type || 0));
}

sub usb_probe {
    -e "/proc/bus/usb/devices" or return ();

    add_addons($usbtable_addons, map {
	my %l;
	@l{qw(vendor id media_type driver description)} = split "\t";
	$l{$_} = hex $l{$_} foreach qw(vendor id);
	$l{bus} = 'USB';
	\%l
    } c::usb_probe());
}

sub pcmcia_probe {
    -e '/var/run/stab' || -e '/var/lib/pcmcia/stab' or return ();

    my (@devs, $desc);
    foreach (cat_('/var/run/stab'), cat_('/var/lib/pcmcia/stab')) {
	if (/^Socket\s+\d+:\s+(.*)/) {
	    $desc = $1;
	} else {
	    my (undef, $type, $module, undef, $device) = split;
	    push @devs, { description => $desc, driver => $module, type => $type, device => $device };
	}
    }
    @devs;
}

# pci_probe with $probe_type is unsafe for pci! (bug in kernel&hardware)
# pcmcia_probe provides field "device", used in network.pm
# => probeall with $probe_type is unsafe
sub probeall {
    my ($probe_type) = @_;

    return if $::noauto;

    require sbus_probing::main;
    pci_probe($probe_type), usb_probe(), pcmcia_probe(), sbus_probing::main::probe();
}
sub matching_desc {
    my ($regexp) = @_;
    grep { $_->{description} =~ /$regexp/i } probeall();
}
sub stringlist { 
    map {
	sprintf("%-16s: %s%s%s", 
		$_->{driver} ? $_->{driver} : 'unknown', 
		$_->{description} eq '(null)' ? sprintf("Vendor=0x%04x Device=0x%04x", $_->{vendor}, $_->{id}) : $_->{description},
		$_->{media_type} ? sprintf(" [%s]", $_->{media_type}) : '',
		$_->{subid} && $_->{subid} != 0xffff ? sprintf(" SubVendor=0x%04x SubDevice=0x%04x", $_->{subvendor}, $_->{subid}) : '',
	       );
    } probeall(@_); 
}

sub tryOpen($) {
    local *F;
    sysopen F, devices::make($_[0]), c::O_NONBLOCK() and *F;
}

sub tryWrite($) {
    local *F;
    sysopen F, devices::make($_[0]), 1 | c::O_NONBLOCK() and *F;
}

sub syslog {
    -r "/tmp/syslog" and return map { /<\d+>(.*)/ } cat_("/tmp/syslog");
    `$ENV{LD_LOADER} /bin/dmesg`;
}

sub get_mac_model() {
    my $mac_model = cat_("/proc/device-tree/model") || die "Can't open /proc/device-tree/model";
    log::l("Mac model: $mac_model");
    $mac_model;	
}

sub get_mac_generation() {
    my $generation = cat_("/proc/cpuinfo") || die "Can't open /proc/cpuinfo";
    my @genarray = split(/\n/, $generation);
    my $count = 0;
    while ($count <= @genarray) {
	if ($genarray[$count] =~ /pmac-generation/) {
	    @genarray = split(/:/, $genarray[$count]);
	    return $genarray[1];
	}
	$count++;
    }
    return "Unknown Generation";	
}

sub hasSMP { c::detectSMP() }
sub hasPCMCIA { $::o->{pcmcia} } #- because /proc/pcmcia seems not to be present on 2.4 at least (or use /var/run/stab)

#- try to detect a laptop, we assume pcmcia service is an indication of a laptop or
#- the following regexp to match graphics card apparently only used for such systems.
sub isLaptop {
    hasPCMCIA() || (matching_desc('C&T.*655[45]\d') || matching_desc('C&T.*68554') ||
		    matching_desc('Neomagic.*Magic(Media|Graph)') ||
		    matching_desc('ViRGE.MX') || matching_desc('S3.*Savage.*[IM]X') ||
		    matching_desc('ATI.*(Mobility|LT)'));
}

sub hasUltra66 {
    die "hasUltra66 deprecated";
    #- keep it BUT DO NOT USE IT as now included in kernel.
    cat_("/proc/cmdline") =~ /(ide2=(\S+)(\s+ide3=(\S+))?)/ and return $1;

    my @l = map { $_->{verbatim} } matching_desc('HPT|Ultra66') or return;
    
    my $ide = sprintf "ide2=0x%x,0x%x ide3=0x%x,0x%x",
      @l == 2 ?
	(map_index { hex($_) + (odd($::i) ? 1 : -1) } map { (split ' ')[3..4] } @l) :
	(map_index { hex($_) + (odd($::i) ? 1 : -1) } map { (split ' ')[3..6] } @l);

    log::l("HPT|Ultra66: found $ide");
    $ide;
}

sub whatParport() {
    my @res = ();
    foreach (0..3) {
	my $elem = {};
	local *F;
	open F, "/proc/parport/$_/autoprobe" or open F, "/proc/sys/dev/parport/parport$_/autoprobe" or next;
	{
	    local $_;
	    while (<F>) { 
		if (/(.*):(.*);/) {
		    $elem->{$1} = $2;
		    $elem->{$1} =~ s/Hewlett[-\s_]Packard/HP/;
		    $elem->{$1} =~ s/HEWLETT[-\s_]PACKARD/HP/;
		}
	    }
	}
	push @res, { port => "/dev/lp$_", val => $elem};
    }
    @res;
}

sub usbMice      { grep { $_->{media_type} =~ /\|Mouse/ && $_->{driver} !~ /Tablet:wacom/ ||
			  $_->{driver} =~ /Mouse:USB/ } usb_probe() }
sub usbWacom     { grep { $_->{driver} =~ /Tablet:wacom/ } usb_probe() }
sub usbKeyboards { grep { $_->{media_type} =~ /\|Keyboard/ } usb_probe() }
sub usbStorage   { grep { $_->{media_type} =~ /Mass Storage\|/ } usb_probe() }

sub whatUsbport() {
    # The printer manufacturer and model names obtained with the usb_probe()
    # function were very messy, once there was a lot of noise around the
    # manufacturers name ("Inc.", "SA", "International", ...) and second,
    # all Epson inkjets answered with the name "Epson Stylus Color 760" which
    # lead many newbies to install their Epson Stylus Photo XXX as an Epson
    # Stylus Color 760 ...
    #
    # This routine based on an ioctl request gives very clean and correct
    # manufacturer and model names, so that they are easily matched to the
    # printer entries in the Foomatic database
    my $i; 
    my @res = ();
    foreach $i (0..15) {
	my $port = "/dev/usb/lp$i";
	my $realport = devices::make("$port");
	next if (!$realport);
	next if (! -r $realport);
	open PORT, "$realport" or do next;
	my $idstr = "";
	# Calculation of IOCTL function 0x84005001 (to get device ID
	# string):
	# len = 1024
	# IOCNR_GET_DEVICE_ID = 1
	# LPIOC_GET_DEVICE_ID(len) =
	#     _IOC(_IOC_READ, 'P', IOCNR_GET_DEVICE_ID, len)
	# _IOC(), _IOC_READ as defined in /usr/include/asm/ioctl.h
	# Use "eval" so that program does not stop when IOCTL fails
	eval{ my $output = "\0" x 1024; 
	      ioctl(PORT, 0x84005001, $output);
	      $idstr = $output; } or do {
		  close PORT;
		  next;
	      };
	close PORT;
	# Remove non-printable characters
	$idstr =~ tr/[\x00-\x1f]/\./;
	# Extract the printer data from the ID string
	my ($manufacturer, $model, $description) = ("", "", "");
	if (($idstr =~ /MFG:([^;]+);/) ||
	    ($idstr =~ /MANUFACTURER:([^;]+);/)) {
	    $manufacturer = $1;
	    $manufacturer =~ s/Hewlett[-\s_]Packard/HP/;
	    $manufacturer =~ s/HEWLETT[-\s_]PACKARD/HP/;
	}
	if (($idstr =~ /MDL:([^;]+);/) ||
	    ($idstr =~ /MODEL:([^;]+);/)) {
	    $model = $1;
	}
	if (($idstr =~ /DES:([^;]+);/) ||
	    ($idstr =~ /DESCRIPTION:([^;]+);/)) {
	    $description = $1;
	    $description =~ s/Hewlett[-\s_]Packard/HP/;
	    $description =~ s/HEWLETT[-\s_]PACKARD/HP/;
	}
	# Was there a manufacturer and a model in the string?
	if (($manufacturer eq "") || ($model eq "")) {
	    next;
	}
	# No description field? Make one out of manufacturer and model.
	if ($description eq "") {
	    $description = "$manufacturer $model";
	}
	# Store this auto-detection result in the data structure
	push @res, { port => $port, val => 
		     { CLASS => 'PRINTER',
		       MODEL => $model,
		       MANUFACTURER => $manufacturer,
		       DESCRIPTION => $description,
		   }};
    }
    @res;
}

#-CLASS:PRINTER;
#-MODEL:HP LaserJet 1100;
#-MANUFACTURER:Hewlett-Packard;
#-DESCRIPTION:HP LaserJet 1100 Printer;
#-COMMAND SET:MLC,PCL,PJL;
sub whatPrinter() {
    my @res = (whatParport(), whatUsbport());
    grep { $_->{val}{CLASS} eq "PRINTER"} @res;
}

sub whatPrinterPort() {
    grep { tryWrite($_)} qw(/dev/lp0 /dev/lp1 /dev/lp2 /dev/usb/lp0 /dev/usb/lp1 /dev/usb/lp2 /dev/usb/lp3 /dev/usb/lp4 /dev/usb/lp5 /dev/usb/lp6 /dev/usb/lp7 /dev/usb/lp8 /dev/usb/lp9);
}

sub probeSerialDevices {
    #- make sure the device are created before probing.
    foreach (0..3) { devices::make("/dev/ttyS$_") }

    #- for device already probed, we can safely (assuming device are
    #- not moved during install :-)
    #- include /dev/mouse device if using an X server.
    -d "/var/lock" or mkdir "/var/lock", 0755;
    -l "/dev/mouse" and $serialprobe{"/dev/" . readlink "/dev/mouse"} = undef;
    foreach (keys %serialprobe) { m|^/dev/(.*)| and touch "/var/lock/LCK..$1" }

    print STDERR "Please wait while probing serial ports...\n";
    #- start probing all serial ports... really faster than before ...
    #- ... but still take some time :-)
    local *F; open F, "$ENV{LD_LOADER} serial_probe |";
    local $_;
    my %current = (); while (<F>) {
	$serialprobe{$current{DEVICE}} = { %current } and %current = () if /^\s*$/ && $current{DEVICE};
	$current{$1} = $2 if /^([^=]+)=(.*?)\s*$/;
    }
    close F;

    foreach (values %serialprobe) {
	$_->{DESCRIPTION} =~ /modem/i and $_->{CLASS} = 'MODEM'; #- hack to make sure a modem is detected.
	$_->{DESCRIPTION} =~ /olitec/i and $_->{CLASS} = 'MODEM'; #- hack to make sure such modem gets detected.
	log::l("probed $_->{DESCRIPTION} of class $_->{CLASS} on device $_->{DEVICE}");
    }
}

sub probeSerial($) { $serialprobe{$_[0]} }

sub hasModem($) {
    $serialprobe{$_[0]} and $serialprobe{$_[0]}{CLASS} eq 'MODEM' and $serialprobe{$_[0]}{DESCRIPTION};
}

sub hasMousePS2 {
    my $t; sysread(tryOpen($_[0]) || return, $t, 256) != 1 || $t ne "\xFE";
}

sub raidAutoStartIoctl {
    local *F;
    sysopen F, devices::make("md0"), 2 or return;
    ioctl F, 2324, 0;
}

sub raidAutoStartRaidtab {
    my (@parts) = @_;
    require raid;
    #- faking a raidtab, it seems to be working :-)))
    #- (choosing any inactive md)
    raid::inactivate_all();
    foreach (@parts) {
	my ($nb) = grep { !raid::is_active("md$_") } 0..7;
	output("/etc/raidtab", "raiddev /dev/md$nb\n  device " . devices::make($_->{device}) . "\n");
	run_program::run('raidstart', devices::make("md$nb"));
    }
}

sub raidAutoStart {
    my (@parts) = @_;

    log::l("raidAutoStart");
    eval { modules::load('md') };
    my %personalities = ( '1' => 'linear', '2' => 'raid0', '3' => 'raid1', '4' => 'raid5' );
    raidAutoStartIoctl() or raidAutoStartRaidtab(@parts);
    if (my @needed_perso = map { 
	if_(/^kmod: failed.*md-personality-(.)/ ||
	    /^md: personality (.) is not loaded/, $personalities{$1}) } syslog()) {
	eval { modules::load(@needed_perso) };
	raidAutoStartIoctl() or raidAutoStartRaidtab(@parts);
    }
}

sub is_a_recent_computer {
    my ($frequence) = map { /cpu MHz\s*:\s*(.*)/ } cat_("/proc/cpuinfo");
    $frequence > 600;
}

#-######################################################################################
#- Wonderful perl :(
#-######################################################################################
1; #

