package printerdrake;

use diagnostics;
use strict;

use common qw(:common :file :functional :system);
use detect_devices;
use commands;
use modules;
use network;
use log;
use printer;

1;

sub getinfo($) {
    my ($prefix) = @_;
    my $printer = {};

    printer::set_prefix($prefix);
    printer::read_configured_queue($printer);

    add2hash($printer, {
			want         => 0,
			complete     => 0,
			str_type     => $printer::printer_type_default,
			QUEUE        => "lp",
			SPOOLDIR     => "/var/spool/lpd/lp",
			DBENTRY      => "PostScript",
			PAPERSIZE    => "letter",
			ASCII_TO_PS  => undef,
			CRLF         => undef,
			NUP          => 1,
			RTLFTMAR     => 18,
			TOPBOTMAR    => 18,
			AUTOSENDEOF  => 1,

			DEVICE       => "/dev/lp0",

			REMOTEHOST   => "",
			REMOTEQUEUE  => "",

			NCPHOST      => "", #-"printerservername",
			NCPQUEUE     => "", #-"queuename",
			NCPUSER      => "", #-"user",
			NCPPASSWD    => "", #-"pass",

			SMBHOST      => "", #-"hostname",
			SMBHOSTIP    => "", #-"1.2.3.4",
			SMBSHARE     => "", #-"printername",
			SMBUSER      => "", #-"user",
			SMBPASSWD    => "", #-"passowrd",
			SMBWORKGROUP => "", #-"AS3",
		       });
    $printer;
}

sub copy_printer_params($$) {
    my ($from, $to) = @_;
    map { $to->{$_} = $from->{$_} } grep { $_ ne 'configured' } keys %$from; #- avoid cycles.
}

sub setup_local($$$) {
    my ($printer, $in, $install) = @_;

    {
	my $w = $in->wait_message(_("Test ports"), _("Detecting devices..."));
	eval { modules::load("parport_pc"); modules::load("parport_probe"); modules::load("lp"); };
    }

    my @port = ();
    my @str = ();
    my @parport = detect_devices::whatPrinter();
    eval { modules::unload("parport_probe") };
    foreach (@parport) {
	push @str, _("A printer, model \"%s\", has been detected on ", $_->{val}{DESCRIPTION}) . $_->{port};
    }
    if (@str) {
	@port = map { $_->{port} } @parport;
    } else {
	@port = detect_devices::whatPrinterPort();
    }
    $printer->{DEVICE} = $port[0] if $port[0];

    return if !$in->ask_from_entries_refH(_("Local Printer Device"),
					  _("What device is your printer connected to 
(note that /dev/lp0 is equivalent to LPT1:)?\n") . (join "\n", @str), [
_("Printer Device:") => {val => \$printer->{DEVICE}, list => \@port } ],
					 );

    #- select right DBENTRY according to device selected.
    foreach (@parport) {
	$printer->{DEVICE} eq $_->{port} or next;
	$printer->{DBENTRY} = $printer::descr_to_db{common::bestMatchSentence2($parport[0]{val}{DESCRIPTION},
									       @printer::entry_db_description)};
    }
    1;
}

sub setup_remote($$$) {
    my ($printer, $in, $install) = @_;

    $in->ask_from_entries_refH(_("Remote lpd Printer Options"),
_("To use a remote lpd print queue, you need to supply
the hostname of the printer server and the queue name
on that server which jobs should be placed in."), [
_("Remote hostname:") => \$printer->{REMOTEHOST},
_("Remote queue") => \$printer->{REMOTEQUEUE}, ],
			      );
}

sub setup_smb($$$) {
    my ($printer, $in, $install) = @_;

    return if !$in->ask_from_entries_refH(
					  _("SMB (Windows 9x/NT) Printer Options"),
_("To print to a SMB printer, you need to provide the
SMB host name (Note! It may be different from its
TCP/IP hostname!) and possibly the IP address of the print server, as
well as the share name for the printer you wish to access and any
applicable user name, password, and workgroup information."), [
_("SMB server host:") => \$printer->{SMBHOST},
_("SMB server IP:") => \$printer->{SMBHOSTIP},
_("Share name:") => \$printer->{SMBSHARE},
_("User name:") => \$printer->{SMBUSER},
_("Password:") => { val => \$printer->{SMBPASSWD}, hidden => 1 },
_("Workgroup:") => \$printer->{SMBWORKGROUP} ],
					 complete => sub {
					     unless (network::is_ip($printer->{SMBHOSTIP})) {
						 $in->ask_warn('', _("IP address should be in format 1.2.3.4"));
						 return (1,1);
					     }
					     return 0;
					 },
					);
    &$install('samba');
    1;
}

sub setup_ncp($$$) {
    my ($printer, $in, $install) = @_;

    return if !$in->ask_from_entries_refH(_("NetWare Printer Options"),
_("To print to a NetWare printer, you need to provide the
NetWare print server name (Note! it may be different from its
TCP/IP hostname!) as well as the print queue name for the printer you
wish to access and any applicable user name and password."), [
_("Printer Server:") => \$printer->{NCPHOST},
_("Print Queue Name:") => \$printer->{NCPQUEUE},
_("User name:") => \$printer->{NCPUSER},
_("Password:") => {val => \$printer->{NCPPASSWD}, hidden => 1} ],
					);
    &$install('ncpfs');
    1;
}

sub setup_gsdriver($$) {
    my ($printer, $in) = @_;
    my $action;
    my @action = qw(ascii ps both done);
    my %action = (
		  ascii  => _("Yes, print ASCII test page"),
		  ps     => _("Yes, print PostScript test page"),
		  both   => _("Yes, print both test pages"),
		  done   => _("No"),
		 );

    do {
	$printer->{DBENTRY} ||= $printer::thedb_gsdriver{$printer->{GSDRIVER}}{ENTRY};
	$printer->{DBENTRY} =
	  $printer::descr_to_db{
				$in->ask_from_list_(_("Configure Printer"),
						    _("What type of printer do you have?"),
						    [@printer::entry_db_description],
						    $printer::db_to_descr{$printer->{DBENTRY}},
						   )
			       };

	my %db_entry = %{$printer::thedb{$printer->{DBENTRY}}};

	my @list_res = @{$db_entry{RESOLUTION} || []};
	my @res = map { "$_->{XDPI}x$_->{YDPI}" } @list_res;
	my @list_col      = @{$db_entry{BITSPERPIXEL} || []};
	my @col           = map { "$_->{DEPTH} $_->{DESCR}" } @list_col;
	my %col_to_depth  = map { ("$_->{DEPTH} $_->{DESCR}", $_->{DEPTH}) } @list_col;
	my %depth_to_col  = reverse %col_to_depth;
	my $is_uniprint = $db_entry{GSDRIVER} eq "uniprint";

	$printer->{RESOLUTION} = @res ? $res[0] || "Default" : "Default" unless member($printer->{RESOLUTION}, @res);
	$printer->{ASCII_TO_PS} = $db_entry{GSDRIVER} eq 'POSTSCRIPT' unless defined($printer->{ASCII_TO_PS});
	$printer->{CRLF} = $db_entry{DESCR} =~ /HP/ unless defined($printer->{CRLF});
	$printer->{BITSPERPIXEL} = @list_col ? $depth_to_col{$printer->{BITSPERPIXEL}} || $col[0] : "Default";
	$printer->{NUP} = 1 unless member($printer->{NUP}, qw(1 2 4 8));
	$printer->{RTFLTMAP} = 18 unless $printer->{RTFLTMAP} =~ /^\d+$/;
	$printer->{TOPBOTMAP} = 18 unless $printer->{TOPBOTMAP} =~ /^\d+$/;
	$printer->{EXTRA_GS_OPTIONS} =~ s/^\"(.*)\"/$1/;
	$printer->{TEXTONLYOPTIONS} =~ s/^\"(.*)\"/$1/;

	return if !$in->ask_from_entries_refH('', _("Printer options"), [
_("Paper Size") => { val => \$printer->{PAPERSIZE}, type => 'list', not_edit => !$::expert, list => \@printer::papersize_type },
_("Eject page after job?") => { val => \$printer->{AUTOSENDEOF}, type => 'bool' },
@list_res > 1 ? (
_("Resolution") => { val => \$printer->{RESOLUTION}, type => 'list', not_edit => !$::expert, list => \@res } ) : (),
@list_col > 1 ? (
$is_uniprint ? (
_("Uniprint driver options") => { val => \$printer->{BITSPERPIXEL}, type => 'list', not_edit => 1, list => \@col } ) : (
_("Color depth options") => { val => \$printer->{BITSPERPIXEL}, type => 'list', not_edit => 1, list => \@col } ), ) : (),
$db_entry{GSDRIVER} ne 'TEXT' && $db_entry{GSDRIVER} ne 'POSTSCRIPT' ? (
_("Print text as PostScript?") => { val => \$printer->{ASCII_TO_PS}, type => 'bool' }, ) : (),
_("Reverse page order") => { val => \$printer->{REVERSE_ORDER}, type => 'bool' },
$db_entry{GSDRIVER} ne 'POSTSCRIPT' ? (
_("Fix stair-stepping text?") => { val => \$printer->{CRLF}, type => 'bool' },
) : (),
$db_entry{GSDRIVER} ne 'TEXT' ? (
_("Number of pages per output pages") => { val => \$printer->{NUP}, type => 'list', not_edit => !$::expert, list => [1,2,4,8] },
_("Right/Left margins in points (1/72 of inch)") => \$printer->{RTFLTMAP},
_("Top/Bottom margins in points (1/72 of inch)") => \$printer->{TOPBOTMAP},
) : (),
$::expert && $db_entry{GSDRIVER} ne 'TEXT' && $db_entry{GSDRIVER} ne 'POSTSCRIPT' ? (
_("Extra GhostScript options") => \$printer->{EXTRA_GS_OPTIONS},
) : (),
$::expert && $db_entry{GSDRIVER} ne 'POSTSCRIPT' ? (
_("Extra Text options") => \$printer->{TEXTONLYOPTIONS},
) : (),
]);

        $printer->{BITSPERPIXEL} = $col_to_depth{$printer->{BITSPERPIXEL}} || $printer->{BITSPERPIXEL}; #- translate back.

	$printer->{complete} = 1;
	copy_printer_params($printer, $printer->{configured}{$printer->{QUEUE}} ||= {});
	printer::configure_queue($printer);
	$printer->{complete} = 0;
	
	$action = ${{reverse %action}}{$in->ask_from_list('', _("Do you want to test printing?"),
							  [ map { $action{$_} } @action ], $action{'done'})};

	my @testpages;
	push @testpages, "/usr/lib/rhs/rhs-printfilters/testpage.asc"
	  if $action eq "ascii" || $action eq "both";
	push @testpages, "/usr/lib/rhs/rhs-printfilters/testpage". ($printer->{PAPERSIZE} eq 'a4' && '-a4') .".ps"
	  if $action eq "ps" || $action eq "both";

	if (@testpages) {
	    my @lpq_output;
	    {
		my $w = $in->wait_message('', _("Printing test page(s)..."));

		printer::restart_queue($printer->{QUEUE});
		@lpq_output = printer::print_pages($printer->{QUEUE}, @testpages);
	    }

	    if (@lpq_output) {
		$action = $in->ask_yesorno('', _("Test page(s) have been sent to the printer daemon.
This may take a little time before printer start.
Printing status:\n%s\n\nDoes it work properly?", "@lpq_output"), 1) ? 'done' : 'change';
	    } else {
		$action = $in->ask_yesorno('', _("Test page(s) have been sent to the printer daemon.
This may take a little time before printer start.
Does it work properly?"), 1) ? 'done' : 'change';
	    }
	}
    } while ($action ne 'done');
    $printer->{complete} = 1;
}

#- Program entry point.
sub main($$$) {
    my ($printer, $in, $install) = @_;
    my ($queue, $continue);

    printer::read_printer_db();
    do {
	if ($::beginner || !(scalar keys %{$printer->{configured} || {}})) {
	    $queue = $in->ask_yesorno(_("Printer"),
				      _("Would you like to configure a printer?"),
				      $printer->{want}) ? 'lp' : 'Done';
	} else {
	    $queue = $in->ask_from_list_([''],
_("Here are the following print queue.
You can add some more or change the existing ones."),
					 [ (sort keys %{$printer->{configured} || {}}), __("Add"), __("Done") ],
					);
	    if ($queue eq 'Add') {
		my $i = '';
		while ($i < 99) {
		    last unless $printer->{configured}{"lp$i"};
		    ++$i;
		}
		unless ($printer->{configured}{"lp$i"}) {
		    $queue = "lp$i";
		    $printer->{QUEUE} = $queue;
		    $printer->{SPOOLDIR} = "$printer::spooldir/$printer->{QUEUE}";
		}
	    }
	}
	$queue eq 'Done' and last;

	copy_printer_params($printer->{configured}{$queue}, $printer) if $printer->{configured}{$queue};
	$printer->{complete} = 0; #- ??? keep that

	&$install('rhs-printfilters') unless $::testing;

	do {
	    if ($::beginner) {
		$printer->{str_type} =
		  $in->ask_from_list_(_("Select Printer Connection"),
				      _("How is the printer connected?"),
				      [ keys %printer::printer_type ],
				      $printer::printer_type_inv{$printer->{TYPE}},
				     );
		$printer->{TYPE} = $printer::printer_type{$printer->{str_type}};
	    } else {
		$in->ask_from_entries_refH([_("Select Printer Connection"), _("Ok"), _("Remove queue")],
_("Every print queue (which print jobs are directed to) needs a
name (often lp) and a spool directory associated with it. What
name and directory should be used for this queue and how is the printer connected?"), [
_("Name of queue:") => { val => \$printer->{QUEUE} },
_("Spool directory:") => { val => \$printer->{SPOOLDIR} },
_("Printer Connection") => { val => \$printer->{str_type}, list => [ keys %printer::printer_type ] },
										      ],
					   changed => sub {
					       $printer->{SPOOLDIR} = "$printer::spooldir/$printer->{QUEUE}" unless $_[0];
					   },
					   complete => sub {
					       $printer->{TYPE} = $printer::printer_type{$printer->{str_type}} or
						 $in->ask_warn('', _("Unknown printer connection!")), return (1, 2);
					       return 0;
					   }
					  ) or delete $printer->{configured}{$queue}, redo; #- global redo on steps
	    }

	    $continue = '';
	    for ($printer->{TYPE}) {
		/LOCAL/  and setup_local ($printer, $in, $install) and last;
		/REMOTE/ and setup_remote($printer, $in, $install) and last;
		/SMB/    and setup_smb   ($printer, $in, $install) and last;
		/NCP/    and setup_ncp   ($printer, $in, $install) and last;
		$continue = 1; last;
	    }
	} while ($continue);

	#- configure ghostscript driver to be used.
	setup_gsdriver($printer, $in);

    } until ($::beginner || $queue eq 'Done');
}
