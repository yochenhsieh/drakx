package install_steps;

use diagnostics;
use strict;

use common qw(:file :system :common);
use install_any qw(:all);
use partition_table qw(:types);
use modules;
use run_program;
use lilo;
use lang;
use keyboard;
use pkgs;
use cpio;
use log;
use fsedit;
use commands;
use network;
use fs;


my @etc_pass_fields = qw(name password uid gid realname home shell);


my $o;

1;


sub new($$) {
    my ($type, $o_) = @_;

    $o = bless $o_, ref $type || $type;
}

sub default {
    my ($o, $field) = @_;
    $o->{$field} || $o->{default}{$field};
}

sub enteringStep($$) {
    my ($o, $step) = @_;
    log::l("starting step `$step'");
    $o->kill;

    for (my $s = $o->{steps}{first}; $s; $s = $o->{steps}{$s}{next}) {

	next if $o->{steps}{$s}{done} && !$o->{steps}{$s}{redoable};

	my $reachable = 1;
	if (my $needs = $o->{steps}{$s}{needs}) {
	    my @l = ref $needs ? @$needs : $needs;
	    $reachable = min(map { $o->{steps}{$_}{done} } @l);
	}
	if ($reachable && !$o->{steps}{$s}{reachable}) {
	    $o->{steps}{$s}{reachable} = 1;
	    $o->step_set_reachable($s);
	}
    }
}
sub leavingStep($$) {
    my ($o, $step) = @_;
    log::l("step `$step' finished");

    unless ($o->{steps}{$step}{redoable}) {
	$o->{steps}{$step}{reachable} = 0;
	$o->step_set_unreachable($step);
    }

    while (my $f = shift @{$o->{steps}{$step}{toBeDone} || []}) {
	&$f();
    }
}

sub errorInStep($$) {}

sub chooseLanguage($) {
    $o->default("lang");
}
sub selectInstallOrUpgrade($) {
    $o->default("isUpgrade") || 0;
}
sub selectInstallClass($@) {
    $o->default("installClass") || $_[1];
}
sub setupSCSI {
    modules::load_thiskind('scsi');
}

sub doPartitionDisks($$) {
    my ($o, $hds) = @_;
    fsedit::auto_allocate($hds, $o->{default}{partitions});
}
sub rebootNeeded($) {
    my ($o) = @_;
    log::l("Rebooting...");
    exit(0);
}

sub choosePartitionsToFormat($$) {
    my ($o, $fstab) = @_;

    foreach (@$fstab) { 
	$_->{toFormat} = ($_->{mntpoint} && isExt2($_) || isSwap($_)) &&
	  ($_->{notFormatted} || $o->{default}{partitionning}{autoformat});
    }
}

sub formatPartitions {
    my $o = shift;
    foreach (@_) {
	fs::format_part($_) if $_->{toFormat};
    }
}

sub choosePackages($$$) {
    my ($o, $packages, $compss) = @_;
}

sub beforeInstallPackages($) {
    mkdir "$o->{prefix}/$_", 0755 foreach qw(dev etc home mnt tmp var var/tmp var/lib var/lib/rpm);
    network::add2hosts("$o->{prefix}/etc/hosts", "127.0.0.1", "localhost.localdomain");
    pkgs::init_db($o->{prefix}, $o->{isUpgrade});
}

sub installPackages($$) {
    my ($o, $packages) = @_;
    my $toInstall = [ grep { $_->{selected} } values %$packages ];
    pkgs::install($o->{prefix}, $toInstall, $o->{isUpgrade}, 0);
}

sub afterInstallPackages($) {
    my ($o) = @_;

    #  why not? 
    sync(); sync();

#    configPCMCIA($o->{rootPath}, $o->{pcmcia});
}

sub mouseConfig($) { 
    #TODO
}

sub finishNetworking($) {
    my ($o) = @_;
    my $etc = "$o->{prefix}/etc";
#
#    rc = checkNetConfig(&$o->{intf}, &$o->{netc}, &$o->{intfFinal},
#			 &$o->{netcFinal}, &$o->{driversLoaded}, $o->{direction});
    network::write_conf("$etc/sysconfig/network", $o->{netc});
    network::write_interface_conf("$etc/sysconfig/network-scripts/ifcfg-$o->{intf}{DEVICE}", $o->{intf});
    network::write_resolv_conf("$etc/resolv.conf", $o->{netc});
    network::add2hosts("$etc/hosts", $o->{intf}{IPADDR}, $o->{netc}{HOSTNAME});
#    syscall_('sethostname', $hostname, length $hostname) or warn "sethostname failed: $!";
    #res_init();		# reinit the resolver so DNS changes take affect     
}

sub timeConfig {}
sub servicesConfig {}

sub setRootPassword($) {
    my ($o) = @_;
    my %u = %{$o->default("superuser")};
    my $p = $o->{prefix};

    $u{password} = crypt_($u{password}) if $u{password};

    my $f = "$p/etc/passwd";
    my @lines = cat_($f, "failed to open file $f");

    local *F;
    open F, "> $f" or die "failed to write file $f: $!\n";
    foreach (@lines) {
	if (/^root:/) {
	    chomp;
	    my %l; @l{@etc_pass_fields} = split ':';
	    add2hash(\%u, \%l);
	    $_ = join(':', @u{@etc_pass_fields}) . "\n";
	}
	print F $_;
    }
}

sub addUser($) {
    my ($o) = @_;
    my %u = %{$o->default("user")};
    my $p = $o->{prefix};
    my @passwd = cat_("$p/etc/passwd");;

    !$u{name} || member($u{name}, map { (split ':')[0] } @passwd) and return;

    unless ($u{uid}) {
	my @uids = map { (split ':')[2] } @passwd;
	for ($u{uid} = 500; member($u{uid}, @uids); $u{uid}++) {}    
    }    
    unless ($u{gid}) {
	my @gids = map { (split ':')[2] } cat_("$p/etc/group");
	for ($u{gid} = 500; member($u{gid}, @gids); $u{gid}++) {}
    }
    $u{home} ||= "/home/$u{name}";

    $u{password} = crypt_($u{password}) if $u{password};

    local *F;
    open F, ">> $p/etc/passwd" or die "can't append to passwd file: $!";
    print F join(':', @u{@etc_pass_fields}), "\n";

    open F, ">> $p/etc/group" or die "can't append to group file: $!";
    print F "$u{name}::$u{gid}:\n";

    eval { commands::cp("-f", "$p/etc/skel", "$p$u{home}") }; $@ and log::l("copying of skel failed: $@"), mkdir("$p$u{home}", 0750);
    commands::chown_("-r", "$u{uid}.$u{gid}", "$p$u{home}");
}

sub createBootdisk($) {
    lilo::mkbootdisk($o->{prefix}, versionString()) if $o->default("mkbootdisk") && !$::testing;
}

sub setupBootloader($) {
    my ($o) = @_;
    my $versionString = versionString();
    lilo::install($o->{prefix}, $o->{hds}, $o->{fstab}, $versionString, $o->default("bootloader"));
}

sub setupXfree {
    my ($o) = @_;
}

sub exitInstall {}
