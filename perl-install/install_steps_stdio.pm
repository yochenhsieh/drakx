package install_steps_stdio;

use diagnostics;
use strict;
use vars qw(@ISA);

@ISA = qw(install_steps);

use common qw(:common);
use partition_table qw(:types);
use devices;
use run_program;
use install_steps;
use install_any;
use diskdrake;
use lang;
use log;

1;

sub chooseLanguage($) {
    my $lang = ask_from_list('Language', 'Which language do you want?', [ lang::list() ]);
    run_program::run('xmodmap', "/usr/bin/$lang.map");
    $lang;
}

sub selectInstallOrUpgrade($) {
    ask_yesorno('Install/Upgrade', 'Do you want to upgrade an already installed Mandrake?');
}

sub rebootNeeded($) {
    my ($o) = @_;
    ask_warn('', "You need to reboot for the partition table modifications to take place");
    $o->SUPER::rebootNeeded;
}

sub choosePartitionsToFormat($$) {
    my ($o, $fstab) = @_;
    my @l = grep { $_->{mntpoint} && (isExt2($_) || isSwap($_)) } @$fstab;
    my @r = ask_many_from_list('', "Choose the partitions you want to format", 
			       [ map { $_->{mntpoint} } @l ], 
			       [ map { $_->{notFormatted} } @l ]);
    for (my $i = 0; $i < @l; $i++) {
	$l[$i]->{toFormat} = $r[$i];
    }
}

sub choosePackages($$$) {
    my ($o, $packages, $comps) = @_;
    my @comps = values %$comps;
    my @r = ask_many_from_list('',
			       "Choose the packages you want to install",
			       [ map { $_->{name} } @comps ], 
			       [ map { $_->{selected} } @comps ]);
    
    for (my $i = 0; $i < @comps; $i++) {
	$comps[$i]->{selected} = $r[$i];
    }
}

sub installPackages {
    my $o = shift;

    $::testing and exit 0;

    my $old = \&log::ld;
    local *log::ld = sub { 
	my $m = shift;
	if ($m =~ /^starting installing/) {
	    my $name = first($_[0] =~ m|([^/]*)-.+?-|);
	    print("installing package $name");
	} else { goto $old }
    };    
    $o->SUPER::installPackages(@_);
}


sub setRootPassword($) {
    my ($o) = @_;
    
    my (%w);
    do {
	$w{password} and print "You must enter the same password, please try again\n";
	print "Password: "; $w{password} = readln(); 
	print "Password (again for confirmation): "; 
    } until ($w{password} eq readln());

    $o->{default}->{rootPassword} = $w{password};
    $o->SUPER::setRootPassword;
}

sub addUser($) {
    my ($o) = @_;
    my %w;
    print "\nCreating a normal user account:\n";
    print "Name: "; $w{name} = readln() or return;
    do {
	$w{password} and print "You must enter the same password, please try again\n";
	print "Password: "; $w{password} = readln(); 
	print "Password (again for confirmation): "; 
    } until ($w{password} eq readln());
    print "Real name: "; $w{realname} = readln();
    
    $w{shell} = ask_from_list('', 'Shell', $o->{default}->{shells});
    
    $o->{default}->{user} = { map { $_ => $w{$_}->get_text } qw(name password realname shell) };
    $o->SUPER::addUser;
}

sub createBootdisk($) {
    my ($o) = @_;
    
    $o->SUPER::createBootdisk if 
	$o->{default}->{mkbootdisk} = ask_yesorno('',
"A custom bootdisk provides a way of booting into your Linux system without
depending on the normal bootloader. This is useful if you don't want to install
lilo on your system, or another operating system removes lilo, or lilo doesn't
work with your hardware configuration. A custom bootdisk can also be used with
the Mandrake rescue image, making it much easier to recover from severe system
failures. Would you like to create a bootdisk for your system?");
}

sub exitInstall {
    ask_warn('', 
"Congratulations, installation is complete.
Remove the boot media and press return to reboot.
For information on fixes which are available for this release of Linux Mandrake,
consult the Errata available from http://www.linux-mandrake.com/.
Information on configuring your system is available in the post
install chapter of the Official Linux Mandrake User's Guide.");
}



sub readln {
    my $l = <STDIN>;
    chomp $l;
    $l;
}

sub ask_warn {
    my ($title, @msgs) = @_;
    print "----------\n", map { "$_\n" } @_;
    print "Press enter"; readln();
}

sub ask_yesorno {
    my ($title, @msgs) = @_;
    print "----------\n", join("\n", @_);
    print " (yes/No) "; readln() =~ /y/i;

}

sub check_it {
    my ($i, $n) = @_;
    $i =~ /^\s*\d+\s*$/ && 1 <= $i && $i <= $n    
}

sub ask_from_list {
    my ($title, @msgs) = @_;
    my $list = pop @msgs;
    print "----------\n", map { "$_\n" } @msgs;
    my $n = 0; foreach (@$list) { $n++; print "$n: $_\n"; }
    my $i;
    do {
	defined $i and print "Bad choice, try again\n";
	print "Your choice? (1/$n) ";
	$i = readln();
    } until (check_it($i, $n));
    $list->[$i - 1];
}

sub ask_many_from_list {
    my ($title, @msgs) = @_;
    my $default = pop @msgs;
    my $list = pop @msgs;
    my @defaults;
    print "----------\n", map { "$_\n" } @msgs;
    my $n = 0; foreach (@$list) { 
	$n++; 
	print "$n: $_\n"; 
	push @defaults, $n if $default->[$n - 1];
    }
    my $i;
    TRY_AGAIN:
    defined $i and print "Bad choice, try again\n";
    print "Your choice? (default ", join(',', @defaults), "  enter `none' for none) ";
    $i = readln();
    my @t = split ',', $i;
    foreach (@t) { check_it($_, $n) or goto TRY_AGAIN }

    my @rr = (0) x @$list;
    foreach (@t) { $rr[$_ - 1] = 1; }
    @rr;
}

