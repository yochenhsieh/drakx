package fs::get; # $Id$

use diagnostics;
use strict;

use partition_table;
use fs::type;
use fs;
use common;
use log;

sub empty_all_hds() {
    { hds => [], lvms => [], raids => [], loopbacks => [], raw_hds => [], nfss => [], smbs => [], davs => [], special => [] };
}
sub fstab {
    my ($all_hds) = @_;
    my @parts = map { partition_table::get_normal_parts($_) } hds($all_hds);
    my @raids = grep { $_ } @{$all_hds->{raids}};
    @parts, @raids, @{$all_hds->{loopbacks}};
}
sub really_all_fstab {
    my ($all_hds) = @_;
    my @l = fstab($all_hds);
    @l, @{$all_hds->{raw_hds}}, @{$all_hds->{nfss}}, @{$all_hds->{smbs}}, @{$all_hds->{davs}};
}

sub fstab_and_holes {
    my ($all_hds) = @_;
    my @raids = grep { $_ } @{$all_hds->{raids}};
    hds_fstab_and_holes(hds($all_hds)), @raids, @{$all_hds->{loopbacks}};
}

sub holes {
    my ($all_hds) = @_;
    grep { $_->{pt_type} == 0 } fstab_and_holes($all_hds);
}
sub hds_holes {
    grep { $_->{pt_type} == 0 } hds_fstab_and_holes(@_);
}
sub free_space {
    my ($all_hds) = @_;
    sum map { $_->{size} } holes($all_hds);
}
sub hds_free_space {
    sum map { $_->{size} } hds_holes(@_);
}

sub hds {
    my ($all_hds) = @_;
    (@{$all_hds->{hds}}, @{$all_hds->{lvms}});
}

#- get all normal partition including special ones as found on sparc.
sub hds_fstab {
    map { partition_table::get_normal_parts($_) } @_;
}

sub hds_fstab_and_holes {
    map {
	if (isLVM($_)) {
	    my @parts = partition_table::get_normal_parts($_);
	    my $free = $_->{totalsectors} - sum map { $_->{size} } @parts;
	    my $free_part = { start => 0, size => $free, pt_type => 0, rootDevice => $_->{VG_name} };
	    @parts, if_($free >= $_->cylinder_size, $free_part);
	} else {
	    partition_table::get_normal_parts_and_holes($_);
	}
    } @_;
}


sub device2part {
    my ($dev, $fstab) = @_;
    my $subpart = fs::subpart_from_wild_device_name($dev);
    my $part = find { fsedit::is_same_hd($subpart, $_) } @$fstab;
    log::l("fs::device2part: unknown device <<$dev>>") if !$part;
    $part;
}

sub part2hd {
    my ($part, $all_hds) = @_;
    my $hd = find { $part->{rootDevice} eq ($_->{device} || $_->{VG_name}) } hds($all_hds);
    $hd;
}

sub file2part {
    my ($fstab, $file, $b_keep_simple_symlinks) = @_;    
    my $part;

    $file = $b_keep_simple_symlinks ? common::expand_symlinks_but_simple("$::prefix$file") : expand_symlinks("$::prefix$file");
    unless ($file =~ s/^$::prefix//) {
	my $part = find { loopback::carryRootLoopback($_) } @$fstab or die;
	log::l("found $part->{mntpoint}");
	$file =~ s|/initrd/loopfs|$part->{mntpoint}|;
    }
    foreach (@$fstab) {
	my $m = $_->{mntpoint};
	$part = $_ if 
	  $file =~ /^\Q$m/ && 
	    (!$part || length $part->{mntpoint} < length $m);
    }
    $part or die "file2part: not found $file";
    $file =~ s|$part->{mntpoint}/?|/|;
    ($part, $file);
}

sub mntpoint2part {
    my ($mntpoint, $fstab) = @_;
    find { $mntpoint eq $_->{mntpoint} } @$fstab;
}
sub has_mntpoint {
    my ($mntpoint, $all_hds) = @_;
    mntpoint2part($mntpoint, [ really_all_fstab($all_hds) ]);
}
sub root_ {
    my ($fstab, $o_boot) = @_;
    $o_boot && mntpoint2part("/boot", $fstab) || mntpoint2part("/", $fstab);
}
sub root { &root_ || {} }

sub up_mount_point {
    my ($mntpoint, $fstab) = @_;
    while (1) {
	$mntpoint = dirname($mntpoint);
	$mntpoint ne "." or return;
	$_->{mntpoint} eq $mntpoint and return $_ foreach @$fstab;
    }
}

1;
