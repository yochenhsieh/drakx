package install_steps_gtk;

use diagnostics;
use strict;
use vars qw(@ISA);

@ISA = qw(install_steps_interactive interactive_gtk);

#-######################################################################################
#- misc imports
#-######################################################################################
use common qw(:common :file :functional :system);
use partition_table qw(:types);
use my_gtk qw(:helpers :wrappers);
use Gtk;
use Gtk::XmHTML;
use devices;
use fsedit;
use keyboard;
use network;
use modules;
use printer;
use install_steps;
use run_program;
use install_steps_interactive;
use Xconfigurator;
use Xconfig;
use interactive_gtk;
use install_any;
use diskdrake;
use pkgs;
use log;
use help;
use lang;

#-#####################################################################################
#-INTERN CONSTANT
#-#####################################################################################
my $w_help;
my $itemsNB = 1;
my (@background1, @background2);
my ($width,       $height)       = (640,   480);
my ($stepswidth,  $stepsheight)  = (140,   $height);
my ($logowidth,   $logoheight)   = ($width - $stepswidth, 40);
my ($helpwidth,   $helpheight)   = ($width - $stepswidth, 100);
my ($windowwidth, $windowheight) = ($width - $stepswidth, $height - $helpheight - $logoheight);

my @themes_vga16 = qw(blue blackwhite savane);
my @themes = qw(DarkMarble marble3d blueHeart);

my @circle_head = (
    "19 17 4 1"
);

my @circle_body = (
" c None",
"+ c #FFFFFF",
"        =====      ",
"      =========    ",
"     =+++=======   ",
"    =++==========  ",
"   ==+============ ",
"   +++============ ",
"  ================o",
"  ================o",
"  ================o",
"  ===============oo",
"  ===============oo",
"   =============oo ",
"   ============ooo ",
"    o=========ooo  ",
"     oo=====oooo   ",
"      ooooooooo    ",
"        ooooo      ",
);

#-my @questionmark_head = (
#-"39 97 6 1",
#-" 	c None",
#-".	c #000000",
#-"+	c #FFFFFF",
#-"o	c #AAAAAA",
#-);
#-my @questionmark_body = (
#-("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO") x 10,
#-"OOOOOOOOOOOOO.......OOOOOOOOOOOOOOOOOOO",
#-"OOOOOOOOOOOO..OOOOOOO.OOOOOOOOOOOOOOOOO",
#-"OOOOOOOOOO..OOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOOOOOOO..OOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOOOOO..OOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOOOOO..OOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOOOO..OOOOOOOOOOOOOOOOOOXOOOOOOOOOOO",
#-"OOOOOOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOOO.OOOOOOOOOOOOOOOOOOOOOXOOOOOOOOOO",
#-"OOOOO..OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOOO.OOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOOO",
#-"OOOO..OOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOO",
#-"OOOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOOO.OOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOO",
#-"OOO..OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",
#-"OOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOO",
#-"OO..OOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOO",
#-"OOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOO",
#-"OO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"OO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"O..OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"OO.OOOOOOOOOOOoo+++++ooOOOOOOOOOOXOOOOO",
#-"O.OOOOOOOOOOo+++o+++++++oOOOOOOOOOXOOOO",
#-"O.OOOOOOOOO+++OOOOo+++++++OOOOOOOOXOOOO",
#-"O.OOOOOOOOo++oOOOOOo++++++oOOOOOOOXOOOO",
#-"O.OOOOOOOo+++oOOOOOO+++++++OOOOOOOXOOOO",
#-"..OOOOOOOo++++OOOOOOo++++++oOOOOOOXOOOO",
#-"O.OOOOOOO+++++oOOOOOo+++++++OOOOOOXOOOO",
#-".OOOOOOOO++++++OOOOOo+++++++OOOOOOOXOOO",
#-".OOOOOOOO++++++OOOOOo+++++++OOOOOOXOOOO",
#-".OOOOOOOOo++++oOOOOOo++++++oOOOOOOOXOOO",
#-".OOOOOOOOOo++oOOOOOOo++++++oOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOOO+++++++OOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOOO++++++OOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOOo+++++oOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOO+++++OOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOo+++oOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOO+++oOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOo++OOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOO++OOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOO+oOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOO+OOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOO+OOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOoOOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOO",
#-"O.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOO",
#-"OOOOOOOOOOOOOOOOoooOOOOOOOOOOOOOOOOXOOO",
#-".OOOOOOOOOOOOOO+++++OOOOOOOOOOOOOOXOOOO",
#-"O.OOOOOOOOOOOO++++++oOOOOOOOOOOOOOXXOOO",
#-"O.OOOOOOOOOOOo+++++++OOOOOOOOOOOOOXOOOO",
#-"O.OOOOOOOOOOOo+++++++OOOOOOOOOOOOOXOOOO",
#-"O.OOOOOOOOOOOo+++++++OOOOOOOOOOOOOXOOOO",
#-"OOOOOOOOOOOOOO++++++oOOOOOOOOOOOOOXOOOO",
#-"O.OOOOOOOOOOOOO+++++OOOOOOOOOOOOOXXOOOO",
#-"OO.OOOOOOOOOOOOOoooOOOOOOOOOOOOOOOXOOOO",
#-"OO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"OO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOXXOOOOO",
#-"OOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOO",
#-"OOO.OOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOO",
#-"OOOO.OOOOOOOOOOOOOOOOOOOOOOOOOOXXOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOO",
#-"OOOOO.OOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXXOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOO",
#-"OOOOOO.OOOOOOOOOOOOOOOOOOOOOOXXOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOOXXOOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOXXOOOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOXXXOOOOOOOOOOO",
#-"OOOOOOOOOOOOOOOOOOOOOOOOOXOOOOOOOOOOOOO",
#-"OOOOOOOOOOOOXOOOOOOOOOOXXXOOOOOOOOOOOOO",
#-"OOOOOOOOOOOOOOXOOOOOOXXXOOOOOOOOOOOOOOO",
#-"OOOOOOOOOOOOOOOXXXXXXXOOOOOOOOOOOOOOOOO",
#-("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO") x 10);

my    @red_circle = (@circle_head, "= c #FF0000", "o c #AA5500", @circle_body);
my @orange_circle = (@circle_head, "= c #FFAA00", "o c #AA5500", @circle_body);
my  @green_circle = (@circle_head, "= c #00FF00", "o c #00AA00", @circle_body);

#-######################################################################################
#- In/Out Steps Functions
#-######################################################################################
sub new($$) {
    my ($type, $o) = @_;

    my $old = $SIG{__DIE__};
    $SIG{__DIE__} = sub { $_[0] !~ /my_gtk\.pm/ and goto $old };

    $ENV{DISPLAY} = $o->{display} || ":0";
    unless ($::testing) {
	$my_gtk::force_focus = $ENV{DISPLAY} eq ":0";

	my $f = "/tmp/Xconf";
	createXconf($f, @{$o->{mouse}}{"XMOUSETYPE", "device"});

	if ($ENV{DISPLAY} eq ":0") {
	    my $launchX = sub {
		my $ok = 1;
		local $SIG{CHLD} = sub { $ok = 0 };
		unless (fork) {
		    exec $_[0], "-kb", "-dpms","-s" ,"240", "-allowMouseOpenFail", "-xf86config", $f or exit 1;
		}
		foreach (1..10) {
		    sleep 1;
		    return 0 if !$ok;
		    return 1 if c::Xtest($ENV{DISPLAY});
		}
		0;
	    };

	     if (listlength(cat_("/proc/fb"))) {
		 &$launchX("XF86_FBDev");
		 $o->{allowFB} = 1; #- keep in mind FB is used.
	     } else {
		my $dir = "/usr/X11R6/bin";
		unless (-x "$dir/XF86_VGA16") {
		    unlink "$dir/XF86_FBDev";
		    local *F; open F, ">$dir/XF86_VGA16" or die '';
		    local $/ = \ (16 * 1024);
		    my $f = install_any::getFile("$dir/XF86_VGA16") or die '';
		    syswrite F, $_ foreach <$f>;
		    chmod 0755, "$dir/XF86_VGA16";
		}
	        &$launchX("XF86_VGA16");
	    }
	}
    }
    @themes = @themes_vga16 if $o->{simple_themes} || !$o->{display} && !($o->{allowFB} ||= $::testing);

    install_theme($o);
    create_logo_window($o);

    $my_gtk::force_center = [ $width - $windowwidth, $logoheight, $windowwidth, $windowheight ];

    (bless {}, ref $type || $type)->SUPER::new($o);
}

sub enteringStep {
    my ($o, $step) = @_;

    $o->SUPER::enteringStep($step);
    create_steps_window($o);
    create_help_window($o);
}
sub leavingStep {
    my ($o, $step) = @_;
    $o->SUPER::leavingStep($step);
}



#-######################################################################################
#- Steps Functions
#-######################################################################################
sub selectLanguage {
    my ($o) = @_;
    $o->SUPER::selectLanguage;
    Gtk->set_locale;
    install_theme($o);
}

#------------------------------------------------------------------------------
sub doPartitionDisks($$) {
    my ($o, $hds, $raid) = @_;

    while (1) {
	diskdrake::main($hds, $raid, interactive_gtk->new, $o->{partitions});
	if (!grep { isSwap($_) } fsedit::get_fstab(@{$o->{hds}})) {
	    if ($::beginner) {
		$o->ask_warn('', _("You must have a swap partition"));
	    } elsif (!$::expert) {
		$o->ask_okcancel('', _("You don't have a swap partition\n\nContinue anyway?")) and last;
	    } else { last }
	} else { last }
    }
}

#------------------------------------------------------------------------------
sub choosePackages {
    my ($o, $packages, $compss, $compssUsers, $first_time) = @_;

    return if $::beginner;
    chooseSizeToInstall(@_);
    install_steps_interactive::choosePackages(@_) unless $::expert;
    choosePackagesTree(@_) if $::expert;
}
sub chooseSizeToInstall {
    my ($o, $packages, $compss, $compssUsers, $first_time) = @_;
    my $availableSpace = int(install_any::getAvailableSpace($o) / sqr(1024));
    my $default = pkgs::correctSize((sum map { $_->{size} } grep { $_->{selected} } values %$packages) / sqr(1024) || $availableSpace * 0.7);
    my $w = my_gtk->new('');
    my $adj = create_adjustment($default, 100, $availableSpace);
    my $spin = gtkset_usize(new Gtk::SpinButton($adj, 0, 0), 100, 0);

    gtkadd($w->{window},
	  gtkpack(new Gtk::VBox(0,20),
		 create_packtable({ col_spacings => 10 },
				  [ _("Choose the size you want to install"), $spin, _("MB"), ],
				  [ undef, new Gtk::HScrollbar($adj) ],
			       ),
		 create_okcancel($w)
		)
	 );
    $spin->signal_connect(activate => sub { $w->{retval} = 1; Gtk->main_quit });
    $spin->grab_focus();
    $w->main or return;

    $_->{selected} = 0 foreach values %$packages;
    pkgs::setSelectedFromCompssList($o->{compssListLevels}, $o->{packages}, pkgs::invCorrectSize($spin->get_value_as_int) * sqr(1024), $o->{installClass}, $o->{lang}, $o->{isUpgrade});
}
sub choosePackagesTree {
    my ($o, $packages, $compss, $compssUsers) = @_;
    my $availableSpace = int(install_any::getAvailableSpace($o) / sqr(1024));
    my $w = my_gtk->new('');
    add2hash_($o->{packages_}, { show_level => 0 }); #- keep show more or less 80 });

    my ($current, $ignore, $showall, $selectall, $w_size, $info_widget, $showall_button, $selectall_button, $go, %items) = 0, 0, 0, 0;
    my $details = new Gtk::VBox(0,0);
    $compss->{tree} = new Gtk::Tree();
    $compss->{tree}->set_selection_mode('multiple');

    my $clean; $clean = sub {
	my ($p) = @_;
	foreach (values %{$p->{childs}}) {
	    &$clean($_) if $_->{childs};
	    delete $_->{itemNB};
	    delete $_->{tree};
	    delete $_->{packages_item};
	}
    }; &$clean($compss);

    my $update = sub {
	my $size = 0;
	$ignore = 1;
	foreach (grep { $_->[0] } values %items) {
	    $compss->{tree}->unselect_child($_->[0]);
	    $compss->{tree}->select_child($_->[0]) if $_->[1]{selected};
	}
	$ignore = 0;
	
	foreach (values %$packages) {
	    $size += $_->{size} - ($_->{installedCumulSize} || 0) if $_->{selected}; #- on upgrade, installed packages will be removed.
	}

	$w_size->set(_("Total size: ") . int (pkgs::correctSize($size / sqr(1024))) . " / $availableSpace " . _("MB") );
    };
    my $new_item = sub {
	my ($p, $name, $parent) = @_;
	my $w = create_treeitem($name);
	$items{++$itemsNB} = [ $w, $p ];
	$parent->{packages_item}{$itemsNB} = undef if $parent;
	$w->show;
	$w->set_sensitive(!$p->{base} && !$p->{installed});
	$w->signal_connect(focus_in_event => sub {
	    my $p = pkgs::getHeader($p);
	    gtktext_insert($info_widget,
			   _("Version: %s\n", c::headerGetEntry($p, 'version') . '-' . c::headerGetEntry($p, 'release')) .
			   _("Size: %d KB\n", c::headerGetEntry($p, 'size') / 1024) .

			   formatLines(c::headerGetEntry($p, 'description')));
	}) unless $p->{childs};
	$itemsNB;
    };

    $compss->{tree}->signal_connect(selection_changed => sub {
	$ignore and return;

	my %s; @s{$_[0]->selection} = ();
	my @changed;
	#- needs to find @changed first, _then_ change the selected, otherwise
	#- we won't be able to find the changed
	foreach (values %items) {
	    push @changed, $_->[1] if ($_->[1]{selected} xor exists $s{$_->[0]});
	}
	#- works before @changed is (or must be!) one element
	foreach (@changed) {
	    if ($_->{childs}) {
		my $s = invbool \$_->{selected};
		my $f; $f = sub {
		    my ($p) = @_;
		    $p->{itemNB} or return;
		    if ($p->{packages}) {
			foreach (keys %{$p->{packages_item} || {}}) {
			    my ($a, $b) = @{$items{$_}};
			    $a and pkgs::set($packages, $b, $s);
			}
		    } else {
			foreach (values %{$p->{childs}}) {
			    $_->{selected} = $s;
			    &$f($_);
			}
		    }
		}; &$f($_);
#-	      } elsif ($_->{base}) {
#-		  $o->ask_warn('', _("Sorry, i won't unselect this package. The system needs it"));
#-	      } elsif ($_->{installed}) {
#-		  $o->ask_warn('', _("Sorry, i won't select this package. A more recent version is already installed"));
	    } else {
		pkgs::toggle($packages, $_);		
	    }
	}
	&$update();
    });

    my $select_add = sub {
	my ($ind, $level) = @{$o->{packages_}}{"ind", "select_level"};
	$level = max(0, min(100, ($level + $_[0])));
	$o->{packages_}{select_level} = $level;

	pkgs::unselect_all($packages);
	foreach (pkgs::allpackages($packages)) {
	    pkgs::select($packages, $_) if $_->{values}[$ind] >= $level;
	}
	&$update;
    };

    my $show_add = sub {
	my ($ind, $level) = @{$o->{packages_}}{"ind", "show_level"};
	$level = max(0, min(90, ($level + $_[0])));
	$o->{packages_}{show_level} = $level;

	my $update_tree = sub {
	    my $P = shift;
	    my $i = 0; foreach (@_) {
		my ($flag, $itemNB, $q) = @$_;
		my $item = $items{$flag || $itemNB}[0] if $flag || $itemNB;
		if ($flag) {
		    $P->{tree}->insert($item, $i) if $flag ne "1";
		    $item->set_subtree($q->{tree}) if $flag ne "1" && $q->{tree};
		    $i++;
		} elsif ($itemNB) {
		    delete $items{$itemNB};
		    delete $P->{packages_item}{$itemNB};
		    $P->{tree}->remove_item($item) if $P->{tree};
		}
	    }
	};
	my $f; $f = sub {
	    my ($p) = @_;
	    if ($p->{packages}) {
		my %l; $l{$items{$_}[1]} = $_ foreach keys %{$p->{packages_item}};
		map {
		    [ $_->{values}[$ind] >= $level ?
		      ($l{$_} ? 1 : &$new_item($_, $_->{name}, $p)) : '', $l{$_}, $_ ];
		} sort { 
		    $a->{name} cmp $b->{name} } @{$p->{packages}};
	    } else {
		map {
		    my $P = $p->{childs}{$_};
		    my @L; @L = &$f($P) if !$P->{values} || $P->{values}[$ind] > ($::expert ? -1 : 0);
		    if (grep { $_->[0] } @L) {
			my $r = $P->{tree} ? 1 : do {
			    my $t = $P->{tree} = new Gtk::Tree(); $t->show;
			    $P->{itemNB} = &$new_item($P, $_);
			};
			&$update_tree($P, @L);
			[ $r, $P->{itemNB}, $P ];
		    } else {
			&$update_tree($P, @L);
			delete $P->{tree};
			[ '', delete $P->{itemNB}, $P ];
		    }
		} sort keys %{$p->{childs} || {}};
	    }
	};
	$ignore = 1;
	&$update_tree($compss, &$f($compss));
	&$update;
	$ignore = 0;
    };

    gtkadd($w->{window}, gtkpack_(new Gtk::VBox(0,5),
				  0, _("Choose the packages you want to install"),
				  1, gtkpack(new Gtk::HBox(0,0),
					     createScrolledWindow($compss->{tree}),
					     gtkadd(gtkset_usize(new Gtk::Frame(_("Info")), 150, 0),
						    createScrolledWindow($info_widget = new Gtk::Text),
						   ),
					     ),
				 0, gtkpack_(new Gtk::HBox(0,0), 0, $w_size = new Gtk::Label('')),
				 0, gtkpack(new Gtk::HBox(0,10),
					    map { $go ||= $_; $_ }
					    map { gtksignal_connect(new Gtk::Button($_->[0]), "clicked" => $_->[1]) }
					    [ _("Install") => sub { $w->{retval} = 1; Gtk->main_quit } ],
					    #- keep show more or less [ _("Show less") => sub { &$show_add(+10) } ],
					    #- keep show more or less [ _("Show more") => sub { &$show_add(-10) } ],
					   )
    ));
    $w->{window}->set_usize(map { $_ - 2 * $my_gtk::border - 4 } $windowwidth, $windowheight);
    $w->show;
    &$show_add(0);
    &$update();
    $go->grab_focus;
    $w->main;
}

#------------------------------------------------------------------------------
sub installPackages {
    my ($o, $packages) = @_;

    my ($current_total_size, $last_size, $nb, $total_size, $start_time, $last_dtime);

    my $w = my_gtk->new(_("Installing"), grab => 1);
    $w->{window}->set_usize($windowwidth * 0.8, $windowheight * 0.5);
    my $text = new Gtk::Label;
    my ($msg, $msg_time_remaining, $msg_time_total) = map { new Gtk::Label } (1..3);
    my ($progress, $progress_total) = map { new Gtk::ProgressBar } (1..2);
    gtkadd($w->{window}, gtkadd(new Gtk::EventBox,
				gtkpack(new Gtk::VBox(0,10),
			       _("Please wait, "), $msg, $progress,
			       create_packtable({},
						[_("Time remaining "), $msg_time_remaining],
						[_("Total time "), $msg_time_total],
						),
			       $text,
			       $progress_total,
			      )));
    $msg->set(_("Preparing installation"));
    $w->sync;

    my $old = \&log::ld;
    local *log::ld = sub {
	my $m = shift;
	if ($m =~ /^starting installation:/) {
	    $nb = $_[0];
	    $total_size = $_[2]; $current_total_size = 0;
	    $start_time = time();
	    $msg->set(join '', @_);
	    $w->flush;
	} elsif ($m =~ /^starting installing/) {
	    $progress->update(0);
	    my $name = $_[0];
	    $msg->set(_("Installing package %s", $name));
	    $current_total_size += $last_size;
	    $last_size = c::headerGetEntry($o->{packages}{$name}{header}, 'size');
	    $text->set((split /\n/, c::headerGetEntry($o->{packages}{$name}{header}, 'summary'))[0] || '');
	    $w->flush;
	} elsif ($m =~ /^progressing installation/) {
	    $progress->update($_[2] ? $_[0] / $_[2] : 0);

	    my $dtime = time() - $start_time;
	    my $ratio = $total_size ? ($_[0] + $current_total_size) / $total_size : 0;
	    my $total_time = $ratio ? $dtime / $ratio : time();

	    $progress_total->update($ratio);
	    if ($dtime != $last_dtime) {
		$msg_time_total->set(formatTime($total_time));
		$msg_time_remaining->set(formatTime(max($total_time - $dtime, 0)));
		$last_dtime = $dtime;
	    }
	    $w->flush;
	} else { goto $old }
    };
    catch_cdie { $o->install_steps::installPackages($packages); }
      sub {
	  if ($@ =~ /^error ordering package list: (.*)/) {
	      $o->ask_yesorno('', [
_("There was an error ordering packages:"), $1, _("Go on anyway?") ], 1) and return 1;
	      ${$_[0]} = "already displayed";
	  }
	  0;
      };
    $w->destroy;
}




#------------------------------------------------------------------------------
sub load_rc($) {
    if (my ($f) = grep { -r $_ } map { "$_/$_[0].rc" } (".", "/usr/share", dirname(__FILE__))) {
	Gtk::Rc->parse($f);
	foreach (cat_($f)) {
	    if (/style\s+"background"/ .. /^\s*$/) {
		@background1 = map { $_ * 256 * 256 } split ',', $1 if /NORMAL.*\{(.*)\}/;
		@background2 = map { $_ * 256 * 256 } split ',', $1 if /PRELIGHT.*\{(.*)\}/;
	    }
	}
    }
}

sub install_theme {
    my ($o, $theme) = @_;    
    $o->{theme} = $theme || $o->{theme} || $themes[0];

    gtkset_mousecursor(68);

    load_rc($_) foreach "themes-$o->{theme}", "install", "themes";

    if (my ($font, $font2) = lang::get_x_fontset($o->{lang})) {
	$font2 ||= $font;
	Gtk::Rc->parse_string(qq(
style "default-font" 
{
   fontset = "$font"
}
style "steps"
{
   fontset = "$font2"
}
widget "*" style "default-font"
widget "*Steps*" style "steps"

));
   }
    gtkset_background(@background1);# unless $::testing;

    create_logo_window($o);
    create_help_window($o);
}

#------------------------------------------------------------------------------
sub create_help_window {
    my ($o) = @_;

#    $o->{help_window}->destroy if $o->{help_window};

    my $w;
    if ($w = $o->{help_window}) {
	$_->destroy foreach $w->{window}->children;
    } else {
	$w = bless {}, 'my_gtk';
	$w->{rwindow} = $w->{window} = new Gtk::Window;
	$w->{rwindow}->set_uposition($width - $helpwidth, $height - $helpheight);
	$w->{rwindow}->set_usize($helpwidth, $helpheight);
	$w->sync;
    }

#-    my $b = new Gtk::Button;
#-    $b->signal_connect(clicked => sub {
#-	  my $w = my_gtk->new('', grab => 1, force_position => [ $stepswidth, $logoheight ]);
#-	  $w->{rwindow}->set_usize($logowidth, $height - $logoheight);
#-	  gtkadd($w->{window},
#-		 gtkpack_(new Gtk::VBox(0,0),
#-			  1, createScrolledWindow(gtktext_insert(new Gtk::Text, 
#-								 formatAlaTeX(translate($help::steps_long{$o->{step}})))),
#-			  0, gtksignal_connect(new Gtk::Button(_("Ok")), "clicked" => sub { Gtk->main_quit }),
#-			  ));
#-	  $w->main;
#-    });
#-    my @l = (@questionmark_head,
#-	       join('', "X c #", map { sprintf "%02X", $_ / 256 } @background1),
#-	       join('', "O c #", map { sprintf "%02X", $_ / 256 } @background2),
#-	       @questionmark_body);
#-    my @pixmap = Gtk::Gdk::Pixmap->create_from_xpm_d($w->{window}->window, undef, @l);
#-    gtkadd($b, new Gtk::Pixmap(@pixmap));

    Gtk::XmHTML->init;
    gtkadd($w->{window},
	   gtkpack_(new Gtk::HBox(0,-2),
#-		    0, $b,
		    1, createScrolledWindow($w_help = new Gtk::XmHTML)));
#-		    1, createScrolledWindow($w_help = new Gtk::Text)));
    $w_help->source($o->{step} ? translate($o->{steps}{$o->{step}}{help}) : '');
#-    gtktext_insert($w_help, $o->{step} ? formatAlaTeX(translate($o->{steps}{$o->{step}}{help})) : '');

    $w->show;
    $o->{help_window} = $w;
}

#------------------------------------------------------------------------------
sub create_steps_window {
    my ($o) = @_;

    $o->{steps_window}->destroy if $o->{steps_window};
    my %reachableSteps if 0;
    %reachableSteps = ();

    my $w = bless {}, 'my_gtk';
    $w->{rwindow} = $w->{window} = new Gtk::Window;
    $w->{rwindow}->set_uposition(0, 0);
    $w->{rwindow}->set_usize($stepswidth, $stepsheight);
    $w->{rwindow}->set_name("Steps");
    $w->{rwindow}->set_events('button_press_mask');
    $w->{rwindow}->signal_connect(button_press_event => sub {
	$::setstep or return;
        my $Y = $_[1]{'y'};
	map_each {
	    my (undef, $y, undef, $height) = @{$::b->allocation};
	    $y <= $Y && $Y < $y + $height and die "setstep $::a\n";
	} %reachableSteps;
    });
    $w->show;

    gtkadd($w->{window},
	   gtkpack_(new Gtk::VBox(0,0),
		    (map { 1, $_ } map {
			my $step = $o->{steps}{$_};
			my $circle =
			  $step->{done}    && \@green_circle  ||
			  $step->{entered} && \@orange_circle ||
			  \@red_circle;
			my @pixmap = Gtk::Gdk::Pixmap->create_from_xpm_d($w->{window}->window, undef, @$circle);

			my $w = new Gtk::Label(translate($step->{text}));

			$w->set_name("Steps" . ($step->{reachable} && "Reachable"));
			my $b = new Gtk::HBox(0,5);
			gtkpack_($b, 0, new Gtk::Pixmap(@pixmap), 0, $w);

			$reachableSteps{$_} = $b if $step->{reachable};
			$b;
		    } grep { !(($::beginner || !$o->{installClass}) && $o->{steps}{$_}{beginnerHidden}) } @{$o->{orderedSteps}}),
		    0, gtkpack(new Gtk::HBox(0,0), map {
			my $t = $_;
			my $w = new Gtk::Button('');
			$w->set_name($t);
			$w->set_usize(0, 7);
			gtksignal_connect($w, clicked => sub { install_theme($o, $t); die "theme_changed\n" });
		    } @themes)));
    $w->show;
    $o->{steps_window} = $w;
}

#------------------------------------------------------------------------------
sub create_logo_window() {
    my ($o) = @_;
    gtkdestroy($o->{logo_window});
    my $w = bless {}, 'my_gtk';
    $w->{rwindow} = $w->{window} = new Gtk::Window;
    $w->{rwindow}->set_uposition($stepswidth, 0);
    $w->{rwindow}->set_usize($logowidth, $logoheight);
    $w->{rwindow}->set_name("background");
    $w->show;
    my $file = "logo-mandrake.xpm";
    -r $file or $file = "/usr/share/$file";
    if (-r $file) {
	my $ww = $w->{window};
	my @logo = Gtk::Gdk::Pixmap->create_from_xpm($ww->window, $ww->style->bg('normal'), $file);
	gtkadd($ww, new Gtk::Pixmap(@logo));
    }
    $o->{logo_window} = $w;
}

#------------------------------------------------------------------------------
sub createXconf($$$) {
    my ($file, $mouse_type, $mouse_dev) = @_;
    $mouse_type ||= "Microsoft";
    $mouse_dev = devices::make($mouse_dev || "ttyS0");

    local *F;
    open F, ">$file" or die "can't create X configuration file $file";
    print F <<END;
Section "Files"
   FontPath   "/usr/X11R6/lib/X11/fonts"
EndSection

Section "Keyboard"
   Protocol    "Standard"
   AutoRepeat  500 5

   LeftAlt         Meta
   RightAlt        Meta
   ScrollLock      Compose
   RightCtl        Control
EndSection

Section "Pointer"
   Protocol    "$mouse_type"
   Device      "$mouse_dev"
   Emulate3Buttons
   Emulate3Timeout    50
EndSection


Section "Monitor"
   Identifier  "My Monitor"
   VendorName  "Unknown"
   ModelName   "Unknown"
   HorizSync   31.5-35.5
   VertRefresh 50-70
   Modeline "640x480"     25.175 640  664  760  800   480  491  493  525
   Modeline "640x480"     28.3   640  664  760  800   480  491  493  525
EndSection


Section "Device"
   Identifier "Generic VGA"
   VendorName "Unknown"
   BoardName "Unknown"
   Chipset "generic"
EndSection


Section "Screen"
    Driver "svga"
    Device      "Generic VGA"
    Monitor     "My Monitor"
    Subsection "Display"
        Modes       "640x480"
        ViewPort    0 0
    EndSubsection
EndSection

Section "Screen"
    Driver      "vga16"
    Device      "Generic VGA"
    Monitor     "My Monitor"
    Subsection "Display"
        Modes       "640x480"
        ViewPort    0 0
    EndSubsection
EndSection

Section "Screen"
    Driver      "fbdev"
    Device      "Generic VGA"
    Monitor     "My Monitor"
    Subsection "Display"
        Depth       16
        Modes       "default"
        ViewPort    0 0
    EndSubsection
EndSection
END

}
#-   ModeLine "640x480"     28     640  672  768  800   480  490  492  525
#-######################################################################################
#- Wonderful perl :(
#-######################################################################################
1; #
