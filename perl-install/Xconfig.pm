package Xconfig;

use common qw(:common :file :system);

# otherwise uses the rule substr($keymap, 0, 2)
my %keymap_translate = (
    cf => "ca_enhanced",
    uk => "gb", 
);


1;

sub keymap_translate {
    $keymap_translate{$_[0]} || substr($_[0], 0, 2);
}


sub getinfo {
    my $o = {};
#    getinfoFromXF86Config($o);
    getinfoFromSysconfig($o);

    unless ($o->{mouse}{xtype}) {
	my ($type, $dev) = split("\n", `mouseconfig --nointeractive 2>/dev/null`) or die "mouseconfig failed";
	$o->{mouse}{emulate3buttons} = 1;
	$o->{mouse}{xtype} ||= $type;
	$o->{mouse}{device} ||= "/dev/$dev";
    }
    $o->{mouse}{device} ||= "/dev/mouse" if -e "/dev/mouse";
    $o;
}

sub getinfoFromXF86Config {
    my $o = shift || {};
    my (%c, $depth);

    $o->{card}{server} ||= $1 if readlink("/etc/X11/X") =~ /XF86_ (\w+)$/x; # /x for perl2fcalls
    
    local *F;
    open F, "/etc/X11/XF86Config" or return {};
    foreach (<F>) {
	if (/^Section "Keyboard"/ .. /^EndSection/) {
	    $o->{keyboard}{xkb_keymap} ||= $1 if /^\s*XkbLayout\s+"(.*?)"/;
	} elsif (/^Section "Pointer"/ .. /^EndSection/) {
	    $o->{mouse}{xtype} ||= $1 if /^\s*Protocol\s+"(.*?)"/;
	    $o->{mouse}{device} ||= $1 if /^\s*Device\s+"(.*?)"/;
	} elsif (my $i = /^Section "Device"/ .. /^EndSection/) {
	    if ($i = 1 && $c{type} && $c{type} ne "Generic VGA") {
		add2hash($o->{card} ||= {}, \%c);
		%c = ();
	    }
	    $c{type} ||= $1 if /^\s*Identifier\s+"(.*?)"/;
	    $c{memory} ||= $1 if /^\s*VideoRam\s+(\d+)/;
	    $c{vendor} ||= $1 if /^\s*VendorName\s+"(.*?)"/;
	    $c{board} ||= $1 if /^\s*BoardName\s+"(.*?)"/;
		
	    push @{$c{lines}}, $_ unless /(Section|Identifier|VideoRam|VendorName|BoardName)/;
	} elsif (/^Section "Monitor"/ .. /^EndSection/) {
	    $o->{monitor}{type} ||= $1 if /^\s*Identifier\s+"(.*?)"/;
	    $o->{monitor}{hsyncrange} ||= $1 if /^\s*HorizSync\s+(.*)/;
	    $o->{monitor}{vsyncrange} ||= $1 if /^\s*VertRefresh\s+(.*)/;
	    $o->{monitor}{vendor} ||= $1 if /^\s*VendorName\s+"(.*?)"/;
	    $o->{monitor}{model} ||= $1 if /^\s*ModelName\s+"(.*?)"/;
	} elsif (/^Section "Screen"/ .. /^EndSection/) {
	    $o->{card}{default_depth} ||= $1 if /^\s*DefaultColorDepth\s+(\d+)/;
	    if (my $i = /^\s*Subsection\s+"Display"/ .. /^\s*EndSubsection/) {
		$depth = undef if $i == 1;
		$depth = $1 if /^\s*Depth\s+(\d*)/;
		if (/^\s*Modes\s+(.*)/) {
		    my $a = 0;
		    push @{$o->{card}{depth}{$depth || 8}},
		        grep { $_->[0] >= 640 } map { [ /"(\d+)x(\d+)"/ ] } split ' ', $1;
		}
	    }
	}
    }
    $o;
}

sub getinfoFromSysconfig {
    my $o = shift || {};
    if (my %mouse = getVarsFromSh "/etc/sysconfig/mouse") {
	$o->{mouse}{xtype} ||= $mouse{XMOUSETYPE};
    }
    if (my %keyboard = getVarsFromSh "/etc/sysconfig/keyboard") {
	$keyboard{KEYTABLE} or last;
	$o->{keyboard}{xkb_keymap} ||= keymap_translate($keyboard{KEYTABLE});
    }
}
