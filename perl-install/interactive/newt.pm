package interactive::newt; # $Id$

use diagnostics;
use strict;
use vars qw(@ISA);

@ISA = qw(interactive);

use interactive;
use common;
use log;
use Newt::Newt; #- !! provides Newt and not Newt::Newt

my ($width, $height) = (80, 25);
my @wait_messages;

sub new() {
    Newt::Init();
    Newt::Cls();
    Newt::SetSuspendCallback();
    ($width, $height) = Newt::GetScreenSize();
    open STDERR, ">/dev/null" if $::isStandalone && !$::testing;
    bless {}, $_[0];
}

sub enter_console { Newt::Suspend() }
sub leave_console { Newt::Resume() }
sub suspend { Newt::Suspend() }
sub resume { Newt::Resume() }
sub end() { Newt::Finished() }
sub exit() { end(); exit($_[1]) }
END { end() }

sub messages { warp_text(join("\n", @_), $width - 9) }

sub myTextbox {
    my ($allow_scroll, $free_height, @messages) = @_;

    my @l = messages(@messages);
    my $h = min($free_height - 13, int @l);

    my $want_scroll;
    if ($h < @l) {
	if ($allow_scroll) {
	    $want_scroll = 1;
	} else {
	    # remove the text, no other way!
	    @l = @l[0 .. $h-1];
	}
    }

    my $mess = Newt::Component::Textbox(1, 0, my $w = max(map { length } @l) + 1, $h, $want_scroll);
    $mess->TextboxSetText(join("\n", @l));
    $mess, $w + 1, $h;
}

sub separator {
    my $blank = Newt::Component::Form(\undef, '', 0);
    $blank->FormSetWidth($_[0]);
    $blank->FormSetHeight($_[1]);
    $blank;
}
sub checkval { $_[0] && $_[0] ne ' '  ? '*' : ' ' }

sub ask_fromW {
    my ($o, $common, $l, $l2) = @_;

    if (@$l == 1 && $l->[0]{list} && @{$l->[0]{list}} == 2 && listlength(map { split "\n" } @{$common->{messages}}) > 20) {
	#- special ugly case, esp. for license agreement
	my $e = $l->[0];
	my $ok_disabled = $common->{callbacks} && delete $common->{callbacks}{ok_disabled};
	($common->{ok}, $common->{cancel}) = map { may_apply($e->{format}, $_) } @{$e->{list}};
	do {
	    ${$e->{val}} = ask_fromW_real($o, $common, [], $l2) ? $e->{list}[0] : $e->{list}[1];
	} while $ok_disabled && $ok_disabled->();
	1;
    } elsif ((any { $_->{type} ne 'button' } @$l) || @$l < 5) {
	&ask_fromW_real;
    } else {
	$common->{cancel} = N("Do") if $common->{cancel} eq '';
	my $r;
	do {
	    my @choices = map {
		my $s = simplify_string(may_apply($_->{format}, ${$_->{val}}));
		$s = "$_->{label}: $s" if $_->{label};
		{ label => $s, clicked_may_quit => $_->{clicked_may_quit} }
	    } @$l;
	    #- replace many buttons with a list
	    my $new_l = [ { val => \$r, type => 'list', list => \@choices, format => sub { $_[0]{label} }, sort => 0 } ];
	    ask_fromW_real($o, $common, $new_l, $l2) and return;
	} until $r->{clicked_may_quit}->();
	1;
    }
}

sub ask_fromW_real {
    my ($_o, $common, $l, $_l2) = @_;
    my $ignore; #-to handle recursivity
    my $old_focus = -2;

    #-the widgets
    my (@widgets, $total_size, $has_scroll);

    my $set_all = sub {
	$ignore = 1;
	$_->{set}->(${$_->{e}{val}}) foreach @widgets;
#	$_->{w}->set_sensitive(!$_->{e}{disabled}()) foreach @widgets;
	$ignore = 0;
    };
    my $get_all = sub {
	${$_->{e}{val}} = $_->{get}->() foreach @widgets;
    };
    my $create_widget = sub {
	my ($e, $ind) = @_;

	$e->{type} = 'list' if $e->{type} =~ /iconlist/;

	#- combo doesn't exist, fallback to a sensible default
	$e->{type} = $e->{not_edit} ? 'list' : 'entry' if $e->{type} eq 'combo';

	my $changed = sub {
	    return if $ignore;
	    return $old_focus++ if $old_focus == -2; #- handle special first case
	    $get_all->();

	    #- TODO: this is very rough :(
	    $common->{callbacks}{$old_focus == $ind ? 'changed' : 'focus_out'}->($ind);

	    $set_all->();
	    $old_focus = $ind;
	};

	my ($w, $real_w, $set, $get, $expand, $size);
	if ($e->{type} eq 'bool') {
	    $w = Newt::Component::Checkbox($e->{text} || '', checkval(${$e->{val}}), " *");
	    $set = sub { $w->CheckboxSetValue(checkval($_[0])) };
	    $get = sub { $w->CheckboxGetValue == ord '*' };
	} elsif ($e->{type} eq 'button') {
	    $w = Newt::Component::Button(simplify_string(may_apply($e->{format}, ${$e->{val}})));
	} elsif ($e->{type} eq 'treelist') {
	    $e->{formatted_list} = [ map { may_apply($e->{format}, $_) } @{$e->{list}} ];
	    my $data_tree = interactive::helper_separator_tree_to_tree($e->{separator}, $e->{list}, $e->{formatted_list});

	    my $count; $count = sub {
		my ($t) = @_;
		1 + ($t->{_leaves_} ? int @{$t->{_leaves_}} : 0) 
		  + ($t->{_order_} ? sum(map { $count->($t->{$_}) } @{$t->{_order_}}) : 0);
	    };
	    $size = $count->($data_tree);
	    
	    my ($h) = @$l == 1 && $height > 30 ? 10 : 5;
	    my $scroll = $size > $h;
	    $has_scroll = 1;
	    $size = min($size, $h);

	    $w = Newt::Component::Tree($size, $scroll);

	    my $wi;
	    my $add_item = sub {
		my ($text, $data, $parents) = @_;
		$text = simplify_string($text, $width - 10);
		$wi = max($wi, length($text) + 3 * @$parents + 4);
		$w->TreeAdd($text, $data, $parents);
	    };

	    my $populate; $populate = sub {
		my ($node, $parents) = @_;
		if (my $l = $node->{_order_}) {
		    each_index {
			$add_item->($_, '', $parents);
			$populate->($node->{$_}, [ @$parents, $::i ]);
		    } @$l;
		}
		if (my $l = $node->{_leaves_}) {
		    $add_item->($_->[0], $_->[1], $parents) foreach @$l;
		}
	    };
	    $populate->($data_tree, []);

	    $w->TreeSetWidth($wi + 1);
	    $get = sub { $w->TreeGetCurrent };
	    $set = sub {
#		$w->TreeSetCurrent($_[0]);
		1;
	    };
	} elsif ($e->{type} =~ /list/) {
	    my ($h) = @$l == 1 && $height > 30 ? 10 : 5;
	    my $scroll = @{$e->{list}} > $h ? 1 << 2 : 0;
	    $has_scroll = 1;
	    $size = min(int @{$e->{list}}, $h);

	    $w = Newt::Component::Listbox($size, $scroll); #- NEWT_FLAG_SCROLL	    

	    my @l = map { 
		my $t = simplify_string(may_apply($e->{format}, $_), $width - 10);
		$w->ListboxAddEntry($t, $_);
		$t;
	    } @{$e->{list}};

	    $w->ListboxSetWidth(max(map { length($_) } @l) + 3); # 3 added for the scrollbar (?)
	    $get = sub { $w->ListboxGetCurrent };
	    $set = sub {
		my ($val) = @_;
		each_index {
		    $w->ListboxSetCurrent($::i) if $val eq $_;
		} @{$e->{list}};
	    };
	} else {
	    $w = Newt::Component::Entry('', 20, ($e->{hidden} && 1 << 11) | (1 << 2));
	    $get = sub { $w->EntryGetValue };
	    $set = sub { $w->EntrySet($_[0], 1) };
	}
	$total_size += $size || 1;

	#- !! callbacks must be kept otherwise perl will free them !!
	#- (better handling of addCallback needed)

	{ e => $e, w => $w, real_w => $real_w || $w, expand => $expand, callback => $changed,
	  get => $get || sub { ${$e->{val}} }, set => $set || sub {} };
    };
    @widgets = map_index { $create_widget->($_, $::i) } @$l;

    $_->{w}->addCallback($_->{callback}) foreach @widgets;

    $set_all->();

    my $grid = Newt::Grid::CreateGrid(3, max(1, int @$l));
    each_index {
	$grid->GridSetField(0, $::i, 1, ${Newt::Component::Label($_->{e}{label})}, 0, 0, 1, 0, 1, 0);
	$grid->GridSetField(1, $::i, 1, ${$_->{real_w}}, 0, 0, 0, 0, 1, 0);
    } @widgets;

    my $listg = do {
	my $wanted_header_height = min(8, listlength(messages(@{$common->{messages}})));
	my $height_avail = $height - $wanted_header_height - 13;
	#- use a scrolled window if there is a lot of checkboxes (aka 
	#- ask_many_from_list) or a lot of widgets in general (aka
	#- options of a native PostScript printer in printerdrake)
	#- !! works badly together with list's (lists are one widget, so a
	#- big list window will not switch to scrollbar mode) :-(
	if (@$l > 3 && $total_size > $height_avail) {
	    $grid->GridPlace(1, 1); #- Uh?? otherwise the size allocated is bad
	    $has_scroll = 1;
	    $total_size = $height_avail;

	    my $scroll = Newt::Component::VerticalScrollbar($height_avail, 9, 10); # 9=NEWT_COLORSET_CHECKBOX, 10=NEWT_COLORSET_ACTCHECKBOX
	    my $subf = $scroll->Form('', 0);
	    $subf->FormSetHeight($height_avail);
	    $subf->FormAddGrid($grid, 0);
	    Newt::Grid::HCloseStacked3($subf, separator(1, $height_avail-1), $scroll);
	} else {
	    $grid;
	}
    };

    my ($ok, $cancel) = ($common->{ok}, $common->{cancel});
    $cancel = $::isWizard ? N("<- Previous") : N("Cancel") if !defined $cancel && !defined $ok;
    $ok ||= $::isWizard ? ($::Wizard_finished ? N("Finish") : N("Next ->")) : N("Ok");

    my ($b1, $b2) = map { simplify_string($_) } $::isWizard ? (if_($cancel, $cancel), $ok) : ($ok, if_($cancel, $cancel));
    my ($buttonbar, @buttons) = Newt::Grid::ButtonBar(grep { $_ } $b1, $b2);
    my ($ok_button, $cancel_button) = @buttons > 1 && $::isWizard ? ($buttons[1], $buttons[0]) : @buttons;

    my $form = Newt::Component::Form(\undef, '', 0);
    my $window = Newt::Grid::GridBasicWindow(first(myTextbox(!$has_scroll, $height - $total_size, @{$common->{messages}})), $listg, $buttonbar);
    $window->GridWrappedWindow($common->{title} || '');
    $form->FormAddGrid($window, 1);

    my $check = sub {
	my ($f) = @_;

	$get_all->();
	my ($error, $_focus) = $f->();
	
	if ($error) {
	    $set_all->();
	}
	!$error;
    };

    my ($blocked, $canceled);
    do {
	my $r = $form->RunForm;

	$canceled = $cancel_button && $$r == $$cancel_button;

	$blocked = 
	  $$r == $$ok_button && 
	    $common->{callbacks}{ok_disabled} && 
	      do { $get_all->(); $common->{callbacks}{ok_disabled}() };

	if (my $button = find { $$r == ${$_->{w}} } @widgets) {
	    $get_all->();
	    my $v = $button->{e}{clicked_may_quit}();
	    $form->FormDestroy;
	    Newt::PopWindow();
	    return $v || &ask_fromW;
	}
    } until !$blocked && $check->($common->{callbacks}{$canceled ? 'canceled' : 'complete'});

    $form->FormDestroy;
    Newt::PopWindow();
    !$canceled;
}


sub waitbox {
    my ($title, $messages) = @_;
    my ($t, $w, $h) = myTextbox(1, $height, @$messages);
    my $f = Newt::Component::Form(\undef, '', 0);
    Newt::CenteredWindow($w, $h, $title);
    $f->FormAddComponent($t);
    $f->DrawForm;
    Newt::Refresh();
    $f->FormDestroy;
    push @wait_messages, $f;
    $f;
}


sub wait_messageW {
    my ($_o, $title, $messages) = @_;
    { form => waitbox($title, $messages), title => $title };
}

sub wait_message_nextW {
    my ($o, $messages, $w) = @_;
    $o->wait_message_endW($w);
    $o->wait_messageW($w->{title}, $messages);
}
sub wait_message_endW {
    my ($_o, $_w) = @_;
    my $_wait = pop @wait_messages;
#    log::l("interactive_newt does not handle none stacked wait-messages") if $w->{form} != $wait;
    Newt::PopWindow();
}

sub simplify_string {
    my ($s, $width) = @_;
    $s =~ s/\n/ /g;
    $s = substr($s, 0, $width || 40); #- truncate if too long
    $s;
}

1;
