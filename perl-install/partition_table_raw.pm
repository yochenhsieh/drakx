package partition_table_raw;

use diagnostics;
use strict;

use common qw(:common :system);
use c;

my @fields = qw(active start_head start_sec start_cyl type end_head end_sec end_cyl start size);
my $format = "C8 I2";
my $magic = "\x55\xAA";
my $nb_primary = 4;

my $offset = $common::SECTORSIZE - length($magic) - $nb_primary * common::psizeof($format);

1;


sub compute_CHS($$) {
    my ($hd, $e) = @_;
    my @l = qw(cyl head sec);
    @$e{map { "start_$_" } @l} = $e->{start} || $e->{type} ? CHS2rawCHS(sector2CHS($hd, $e->{start})) : (0,0,0);
    @$e{map { "end_$_"   } @l} = $e->{start} || $e->{type} ? CHS2rawCHS(sector2CHS($hd, $e->{start} + $e->{size} - 1)) : (0,0,0);
    1;
}

sub CHS2rawCHS($$$) {
    my ($c, $h, $s) = @_;
    $c = min($c, 1023); # no way to have a #cylinder >= 1024
    ($c & 0xff, $h, $s | ($c >> 2 & 0xc0));
}

# returns (cylinder, head, sector)
sub sector2CHS($$) {
    my ($hd, $start) = @_;
    my ($s, $h);
    ($start, $s) = divide($start, $hd->{geom}->{sectors});
    ($start, $h) = divide($start, $hd->{geom}->{heads});
    ($start, $h, $s + 1);
}

sub get_geometry($) {
    my ($dev) = @_;
    my $g = "";
   
    local *F; sysopen F, $dev, 0 or return;
    ioctl(F, c::HDIO_GETGEO(), $g) or return;

    my %geom; @geom{qw(heads sectors cylinders start)} = unpack "CCSL", $g;

    { geom => \%geom, totalsectors => $geom{heads} * $geom{sectors} * $geom{cylinders} };
}

sub openit($$;$) { sysopen $_[1], $_[0]->{file}, $_[2] || 0; }

# cause kernel to re-read partition table 
sub kernel_read($) {
    my ($hd) = @_;
    local *F; openit($hd, \*F) or return 0;
    ioctl(F, c::BLKRRPART(), 0) or die "kernel_read failed: need to reboot";
}

sub read($$) {
    my ($hd, $sector) = @_;
    my $tmp;

    local *F; openit($hd, \*F) or return;
    c::lseek_sector(fileno(F), $sector, $offset) or die "reading of partition in sector $sector failed";

    my @pt = map {
	sysread F, $tmp, psizeof($format) or return "error while reading partition table in sector $sector";
	my %h; @h{@fields} = unpack $format, $tmp;
	\%h;
    } (1..$nb_primary);

    # check magic number
    sysread F, $tmp, length $magic or die "error reading magic number";
    $tmp eq $magic or die "bad magic number";

    [ @pt ];
}

# write the partition table (and extended ones)
# for each entry, it uses fields: start, size, type, active
sub write($$$) {
    my ($hd, $sector, $pt) = @_;

    local *F; openit($hd, \*F, 2) or die "error opening device $hd->{device} for writing";
    c::lseek_sector(fileno(F), $sector, $offset) or return 0;

    @$pt == $nb_primary or die "partition table does not have $nb_primary entries";
    foreach (@$pt) {
	compute_CHS($hd, $_);
	local $_->{start} = $_->{local_start} || 0;
	$_->{active} ||= 0; $_->{type} ||= 0; $_->{size} ||= 0; # for no warning
	syswrite F, pack($format, @$_{@fields}) or return 0;
    }
    syswrite F, $magic or return 0;
    1;
}
sub zero_MBR($) { &write($_[0], 0, [ {} x $nb_primary ]); }
