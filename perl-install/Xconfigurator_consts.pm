use common qw(:common);

%depths = (
      8 => __("256 colors (8 bits)"),
     15 => __("32 thousand colors (15 bits)"),
     16 => __("65 thousand colors (16 bits)"),
     24 => __("16 million colors (24 bits)"),
     32 => __("4 billion colors (32 bits)"),
);
@depths = ikeys(%depths);

$resolution_wanted = "1024x768";
@resolutions = qw(640x480 800x600 1024x768 1152x864 1280x1024 1600x1200);

@window_managers = qw(icewm wmaker kwm afterstep fvwm fvwm2 fvwm95 mwm twm enlightenment xfce blackbox);

%serversdriver = (
    'SVGA'      => "svga",
    'Rage128'   => "svga",
    '3dfx'      => "svga",
    'S3'        => "accel",
    'Mach32'    => "accel",
    'Mach8'     => "accel",
    '8514'      => "accel",
    'P9000'     => "accel",
    'AGX'       => "accel",
    'W32'       => "accel",
    'Mach64'    => "accel",
    'I128'      => "accel",
    'S3V'       => "accel",
    '3DLabs'    => "accel",
    'Mono'      => "vga2",
    'VGA16'     => "vga16",
    'FBDev'     => "fbdev",
);
@svgaservers = grep { $serversdriver{$_} eq "svga" } keys(%serversdriver);
@accelservers = grep { $serversdriver{$_} eq "accel" } keys(%serversdriver);
@allbutfbservers = grep { $serversdriver{$_} ne "fbdev" } keys(%serversdriver);
@allservers = keys(%serversdriver);

%vgamodes = (
    '640xx8'       => 769,
    '640x480x8'    => 769,
    '800xx8'       => 771,
    '800x600x8'    => 771,
    '1024xx8'      => 773,
    '1024x768x8'   => 773,
    '1280xx8'      => 775,
    '1280x1024x8'  => 775,
    '640xx15'      => 784,
    '640x480x15'   => 784,
    '800xx15'      => 787,
    '800x600x15'   => 787,
    '1024xx15'     => 790,
    '1024x768x15'  => 790,
    '1280xx15'     => 793,
    '1280x1024x15' => 793,
    '640xx16'      => 785,
    '640x480x16'   => 785,
    '800xx16'      => 788,
    '800x600x16'   => 788,
    '1024xx16'     => 791,
    '1024x768x16'  => 791,
    '1280xx16'     => 794,
    '1280x1024x16' => 794,
#-    '640xx24'      => 786, #- there is a problem with these resolutions since the BIOS may take 24 or 32 planes.
#-    '640x480x24'   => 786,
#-    '800xx24'      => 789,
#-    '800x600x24'   => 789,
#-    '1024xx24'     => 792,
#-    '1024x768x24'  => 792,
#-    '1280xx24'     => 795,
#-    '1280x1024x24' => 795,
);

{ #- @monitorSize2resolution
    my %l = my @l = ( #- size in inch
	13 => "640x480",
	14 => "800x600",
	15 => "800x600",
	16 => "1024x768",
	17 => "1024x768",
	18 => "1024x768",
	19 => "1280x1024",
        20 => "1600x1200",
    );
    for (my $i = 0; $i < $l[0]; $i++) {
	$monitorSize2resolution[$i] = $l[1];
    }
    while (my ($s, $r) = each %l) {
	$monitorSize2resolution[$s] = $r;
    }
}

%videomemory = (
    __("256 kB") => 256,
    __("512 kB") => 512,
    __("1 MB") => 1024,
    __("2 MB") => 2048,
    __("4 MB") => 4096,
    __("8 MB") => 8192,
    __("16 MB or more") => 16384,
);

%standard_monitors = (
  __("Standard VGA, 640x480 at 60 Hz")                             => [ '640x480@60',      "31.5"            , "60" ],
  __("Standard VGA, 640x480 at 60 Hz")                             => [ '640x480@60',      "31.5"            , "60" ],
  __("Super VGA, 800x600 at 56 Hz") 				   => [ '800x600@56',      "31.5-35.1"       , "55-60" ],
  __("8514 Compatible, 1024x768 at 87 Hz interlaced (no 800x600)") => [ '8514 compatible', "31.5,35.5"       , "60,70,87" ],
  __("Super VGA, 1024x768 at 87 Hz interlaced, 800x600 at 56 Hz")  => [ '1024x768@87i',    "31.5,35.15,35.5" , "55-90" ],
  __("Extended Super VGA, 800x600 at 60 Hz, 640x480 at 72 Hz")     => [ '800x600@60',      "31.5-37.9"       , "55-90" ],
  __("Non-Interlaced SVGA, 1024x768 at 60 Hz, 800x600 at 72 Hz")   => [ '1024x768@60',     "31.5-48.5"       , "55-90" ],
  __("High Frequency SVGA, 1024x768 at 70 Hz") 		           => [ '1024x768@70',     "31.5-57.0"       , "50-90" ],
  __("Multi-frequency that can do 1280x1024 at 60 Hz") 	           => [ '1280x1024@60',    "31.5-64.3"       , "50-90" ],
  __("Multi-frequency that can do 1280x1024 at 74 Hz") 	           => [ '1280x1024@74',    "31.5-79.0"       , "50-100" ],
  __("Multi-frequency that can do 1280x1024 at 76 Hz") 	           => [ '1280x1024@76',    "31.5-82.0"       , "40-100" ],
  __("Monitor that can do 1600x1200 at 70 Hz")                     => [ '1600x1200@70',    "31.5-88.0"       , "50-120" ],
  __("Monitor that can do 1600x1200 at 76 Hz")		           => [ '1600x1200@76',    "31.5-94.0"       , "50-160" ],
);

@vsyncranges = ("50-70", "50-90", "50-100", "40-150");

@hsyncranges = (
	"31.5",
	"31.5-35.1",
	"31.5, 35.5",
	"31.5, 35.15, 35.5",
	"31.5-37.9",
	"31.5-48.5",
	"31.5-57.0",
	"31.5-64.3",
	"31.5-79.0",
	"31.5-82.0",
	"31.5-88.0",
	"31.5-94.0",
);

%min_hsync4wres = (
	 640 => 31.5,
	 800 => 35.1,
	1024 => 35.5,
	1152 => 44.0,
	1280 => 51.0,
	1600 => 75.0,
);


%lines = (
#-    'Cirrus Logic|GD 5446' => [ '	Option "no_bitblt"' ],
      'Silicon Integrated Systems [SiS]|86C326' => [ '	Option "noaccel"' ],
      'Trident Microsystems|Cyber 9525' => [ '	Option "noaccel"' ],
      'S3 Inc.|86c368 [Trio 3D/2X]' => [ '	ChipID  0x8a10' ],
);

#- most usefull server options have to be accessible at the beginning, since
#- no more than a small set of options will be available for the user, maybe ?
@options = (
	    [ 'power_saver',       'Mono',        '.*' ],
	    [ 'hibit_low',         'VGA16',       'Tseng.*ET4000' ],
	    [ 'hibit_high',        'VGA16',       'Tseng.*ET4000' ],
	    [ 'power_saver',       'VGA16',       '.*' ],
	    [ 'noaccel',           'SVGA',        'Cirrus|C&T|SiS|Oak|Western Digital|Alliance|Trident|Tseng' ],
	    [ 'no_accel',          'SVGA',        'ARK|MGA|i740|Oak|ET6000|W32|Media.*GX|Neomagic' ],
	    [ 'linear',            'SVGA',        'Cirrus|ET6000|ET4000/W32p rev [CD]|Oak|Neomagic|Triden|Tseng' ],
	    [ 'nolinear',          'SVGA',        'Cirrus|C&T|Trident' ],
	    [ 'no_linear',         'SVGA',        'ARK|SiS|Neomagic|Tseng' ],
	    [ 'no_bitblt',         'SVGA',        'Cirrus|C&T|SiS' ],
	    [ 'no_imageblt',       'SVGA',        'Cirrus|C&T|SiS' ],
	    [ 'sw_cursor',         'SVGA',        '.*' ],
	    [ 'slow_dram',         'SVGA',        'Cirrus|Trident|ET6000|W32|Western Digital|Tseng' ],
	    [ 'mga_sdram',         'SVGA',        'MGA' ],
	    [ 'no_pixmap_cache',   'SVGA',        'ARK|Cirrus|C&T|MGA|SiS|Trident.*9440|Trident.*9680|Tseng' ],
	    [ 'no_mmio',           'SVGA',        'Cirrus|Neomagic|Trident' ],
	    [ 'pci_burst_off',     'SVGA',        'ET6000|W32|Trident|Tseng' ],
	    [ 'hw_clocks',         'SVGA',        'SiS|C&T' ],
	    [ 'use_modeline',      'SVGA',        'C&T' ],
	    [ 'enable_bitblt',     'SVGA',        'Oak' ],
	    [ 'w32_interleave_off', 'SVGA',       'ET6000|W32|Tseng' ],
	    [ 'fifo_conservative', 'SVGA',        'Cirrus|ARK|SiS|Oak' ],
	    [ 'fifo_moderate',     'SVGA',        'Cirrus|ARK|SiS' ],
	    [ 'all_wait',          'SVGA',        'Oak' ],
	    [ 'one_wait',          'SVGA',        'Oak' ],
	    [ 'first_wait',        'SVGA',        'Oak' ],
	    [ 'first_wwait',       'SVGA',        'Oak' ],
	    [ 'write_wait',        'SVGA',        'Oak' ],
	    [ 'read_wait',         'SVGA',        'Oak' ],
	    [ 'clgd6225_lcd',      'SVGA',        'Cirrus' ],
	    [ 'fix_panel_size',    'SVGA',        'C&T' ],
	    [ 'lcd_center',        'SVGA',        'C&T|Neomagic|Trident' ],
	    [ 'cyber_shadow',      'SVGA',        'Trident' ],
	    [ 'STN',               'SVGA',        'C&T' ],
	    [ 'no_stretch',        'SVGA',        'C&T|Cirrus|Neomagic|Trident' ],
	    [ 'no_prog_lcd_mode_regs', 'SVGA',    'Neomagic' ],
	    [ 'prog_lcd_mode_stretch', 'SVGA',    'Neomagic' ],
	    [ 'suspend_hack',      'SVGA',        'C&T' ],
	    [ 'use_18bit_bus',     'SVGA',        'C&T' ],
	    [ 'hibit_low',         'SVGA',        'Tseng.*ET4000' ],
	    [ 'hibit_high',        'SVGA',        'Tseng.*ET4000' ],
	    [ 'probe_clocks',      'SVGA',        'Cirrus' ],
	    [ 'power_saver',       'SVGA',        '.*' ],
	    [ 'use_vlck1',         'SVGA',        'C&T' ],
	    [ 'sgram',             'SVGA',        'i740' ],
	    [ 'sdram',             'SVGA',        'i740' ],
	    [ 'no_2mb_banksel',    'SVGA',        'Cirrus' ],
	    [ 'tgui_pci_read_on',  'SVGA',        'Trident' ],
	    [ 'tgui_pci_write_on', 'SVGA',        'Trident' ],
	    [ 'no_program_clocks', 'SVGA',        'Trident' ],
	    [ 'mmio',              'SVGA',        'Cirrus|C&T|Neomagic' ],
	    [ 'sync_on_green',     'SVGA',        'C&T|MGA' ],
	    [ 'pci_retry',         'SVGA',        'Tseng|MGA|Cirrus' ],
	    [ 'hw_cursor',         'SVGA',        'C&T|SiS|ARK|ET6000|i740|Tseng' ],
	    [ 'xaa_no_color_exp',  'SVGA',        'C&T|Cirrus|Trident|Tseng' ],
	    [ 'xaa_benchmarks',    'SVGA',        'C&T' ],
	    [ 'pci_burst_on',      'SVGA',        'Trident|Tseng' ],
	    [ 'prog_lcd_mode_regs', 'SVGA',       'Neomagic' ],
	    [ 'no_prog_lcd_mode_stretch', 'SVGA', 'Neomagic' ],
	    [ 'no_wait',           'SVGA',        'Oak' ],
	    #- [ 'med_dram',          'SVGA',        'Cirrus|Trident|Western Digital' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'fast_dram',         'SVGA',        'C&T|Cirrus|ET[46]000|Trident|Western Digital' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'fast_vram',         'SVGA',        'SiS' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'clock_50',          'SVGA',        'Oak' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'clock_66',          'SVGA',        'Oak' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'fifo_aggressive',   'SVGA',        'Cirrus|ARK|SiS|Oak' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'override_validate_mode', 'SVGA',   'Neomagic' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'tgui_mclk_66',      'SVGA',        'Trident' ], #- WARNING, MAY DAMAGE CARD
	    #- [ 'favour_bitblt',     'SVGA',        'Cirrus' ], #- OBSELETE
	    [ 'sw_cursor',         '3DLabs',      '.*' ],
	    [ 'no_pixmap_cache',   '3DLabs',      '.*' ],
	    [ 'no_accel',          '3DLabs',      '.*' ],
	    [ 'firegl_3000',       '3DLabs',      '.*' ],
	    [ 'sync_on_green',     '3DLabs',      '.*' ],
	    [ 'pci_retry',         '3DLabs',      '.*' ],
	    #- [ 'overclock_mem',     '3DLabs',      '.*' ], #- WARNING, MAY DAMAGE CARD
	    [ 'dac_8_bit',         'I128',        '.*' ],
	    [ 'no_accel',          'I128',        '.*' ],
	    [ 'sync_on_green',     'I128',        '.*' ],
	    [ 'composite',         'Mach32',      '.*' ],
	    [ 'sw_cursor',         'Mach32',      '.*' ],
	    [ 'dac_8_bit',         'Mach32',      '.*' ],
	    [ 'ast_mach32',        'Mach32',      '.*' ],
	    [ 'intel_gx',          'Mach32',      '.*' ],
	    [ 'no_linear',         'Mach32',      '.*' ],
	    [ 'sw_cursor',         'Mach64',      '.*' ],
	    [ 'nolinear',          'Mach64',      '.*' ],
	    [ 'no_block_write',    'Mach64',      '.*' ],
	    [ 'block_write',       'Mach64',      '.*' ],
	    [ 'fifo_conservative', 'Mach64',      '.*' ],
	    [ 'no_font_cache',     'Mach64',      '.*' ],
	    [ 'no_pixmap_cache',   'Mach64',      '.*' ],
	    [ 'composite',         'Mach64',      '.*' ],
	    [ 'power_saver',       'Mach64',      '.*' ],
	    [ 'no_program_clocks', 'Mach64',      '.*' ],
	    [ 'no_bios_clocks',    'Mach64',      '.*' ],
	    [ 'dac_6_bit',         'Mach64',      '.*' ],
	    [ 'dac_8_bit',         'Mach64',      '.*' ],
	    [ 'hw_cursor',         'Mach64',      '.*' ],
	    #- [ 'override_bios',     'Mach64',      '.*' ], #- WARNING, MAY DAMAGE CARD
	    [ 'sw_cursor',         'P9000',       '.*' ],
	    [ 'noaccel',           'P9000',       '.*' ],
	    [ 'sync_on_green',     'P9000',       '.*' ],
	    [ 'vram_128',          'P9000',       '.*' ],
	    [ 'nolinear',          'S3',          '.*' ],
	    [ 'dac_8_bit',         'S3',          '.*' ],
	    [ 'slow_vram',         'S3',          'S3.*964' ],
	    [ 'stb_pegasus',       'S3',          'S3.*928' ],
	    [ 'SPEA_Mercury',      'S3',          'S3.*(928|964)' ],
	    [ 'number_nine',       'S3',          'S3.*(864|928)' ],
	    [ 'lcd_center',        'S3',          'S3.*Aurora64V' ],
	    [ 'noaccel',           'S3V',         '.*' ],
	    [ 'slow_edodram',      'S3V',         '.*' ],
	    [ 'pci_burst_on',      'S3V',         '.*' ],
	    [ 'early_ras_precharge', 'S3V',       '.*' ],
	    [ 'late_ras_precharge', 'S3V',        '.*' ],
	    [ 'fifo_conservative', 'S3V',         '.*' ],
	    [ 'fifo_aggressive',   'S3V',         '.*' ],
	    [ 'fifo_moderate',     'S3V',         '.*' ],
	    [ 'lcd_center',        'S3V',         'S3.*ViRGE\/MX' ],
	    [ 'hw_cursor',         'S3V',         '.*' ],
	    [ 'pci_retry',         'S3V',         '.*' ],
	    [ 'dac_6_bit',         'AGX',         '.*' ],
	    [ 'dac_8_bit',         'AGX',         '.*' ],
	    [ 'sync_on_green',     'AGX',         '.*' ],
	    [ '8_bit_bus',         'AGX',         '.*' ],
	    [ 'wait_state',        'AGX',         '.*' ],
	    [ 'no_wait_state',     'AGX',         '.*' ],
	    [ 'noaccel',           'AGX',         '.*' ],
	    [ 'crtc_delay',        'AGX',         '.*' ],
	    [ 'fifo_conserv',      'AGX',         '.*' ],
	    [ 'fifo_aggressive',   'AGX',         '.*' ],
	    [ 'fifo_moderate',     'AGX',         '.*' ],
	    [ 'vram_delay_latch',  'AGX',         '.*' ],
	    [ 'vram_delay_ras',    'AGX',         '.*' ],
	    [ 'vram_extend_ras',   'AGX',         '.*' ],
	    [ 'slow_dram',         'AGX',         '.*' ],
	    [ 'slow_vram',         'AGX',         '.*' ],
	    [ 'med_dram',          'AGX',         '.*' ],
	    [ 'med_vram',          'AGX',         '.*' ],
	    [ 'fast_dram',         'AGX',         '.*' ],
	    [ 'fast_vram',         'AGX',         '.*' ],
	    [ 'engine_delay',      'AGX',         '.*' ],
	    [ 'vram_128',          'AGX',         '.*' ],
	    [ 'vram_256',          'AGX',         '.*' ],
	    [ 'refresh_20',        'AGX',         '.*' ],
	    [ 'refresh_25',        'AGX',         '.*' ],
	    [ 'screen_refresh',    'AGX',         '.*' ],
	    [ 'vlb_a',             'AGX',         '.*' ],
	    [ 'vlb_b',             'AGX',         '.*' ],
	    [ 'slow_dram',         'W32',         '.*' ],
	    [ 'pci_burst_off',     'W32',         '.*' ],
	    [ 'w32_interleave_off', 'W32',        '.*' ],
	    [ 'no_accel',          'W32',         '.*' ],
	    [ 'nolinear',          '8514',        '.*' ],
	    [ 'sw_cursor',         '8514',        '.*' ],
	    [ 'no_block_write',    '8514',        '.*' ],
	    [ 'block_write',       '8514',        '.*' ],
	    [ 'fifo_conservative', '8514',        '.*' ],
	    [ 'no_font_cache',     '8514',        '.*' ],
	    [ 'no_pixmap_cache',   '8514',        '.*' ],
	    [ 'composite',         '8514',        '.*' ],
	    [ 'power_saver',       '8514',        '.*' ],
	    [ 'power_saver',       'FBDev',       '.*' ],
);

%xkb_options = (
    'ru' => [ 'XkbVariant "winkeys"', 'XkbOptions "grp:caps_toggle"' ],
);

#-#- * Screen/video card configuration.
#-%ramdacs = (
#-    __("No RAMDAC Setting (recommended)")               => '',
#-    __("AT&T 20C490 (S3 and AGX servers, ARK driver)"), => 'att20c490',
#-    __("AT&T 20C498/21C498/22C498 (S3, autodetected)"),	=> 'att20c498',
#-    __("AT&T 20C409/20C499 (S3, autodetected)"),	=> 'att20c409',
#-    __("AT&T 20C505 (S3)"),				=> 'att20c505',
#-    __("BrookTree BT481 (AGX)"),			=> 'bt481',
#-    __("BrookTree BT482 (AGX)"),			=> 'bt482',
#-    __("BrookTree BT485/9485 (S3)"),			=> 'bt485',
#-    __("Sierra SC15025 (S3, AGX)"),			=> 'sc15025',
#-    __("S3 GenDAC (86C708) (autodetected)"),		=> 's3gendac',
#-    __("S3 SDAC (86C716) (autodetected)"),		=> 's3_sdac',
#-    __("STG-1700 (S3, autodetected)"),			=> 'stg1700',
#-    __("STG-1703 (S3, autodetected)"),			=> 'stg1703',
#-    __("TI 3020 (S3)"),					=> 'ti3020',
#-    __("TI 3025 (S3, autodetected)"),			=> 'ti3025',
#-    __("TI 3026 (S3, autodetected)"),			=> 'ti3026',
#-    __("IBM RGB 514 (S3, autodetected)"),		=> 'ibm_rgb514',
#-    __("IBM RGB 524 (S3, autodetected)"),		=> 'ibm_rgb524',
#-    __("IBM RGB 525 (S3, autodetected)"),		=> 'ibm_rgb525',
#-    __("IBM RGB 526 (S3)"),				=> 'ibm_rgb526',
#-    __("IBM RGB 528 (S3, autodetected)"),		=> 'ibm_rgb528',
#-    __("ICS5342 (S3, ARK)"),				=> 'ics5342',
#-    __("ICS5341 (W32)"),				=> 'ics5341',
#-    __("IC Works w30C516 ZoomDac (ARK)"),		=> 'zoomdac',
#-    __("Normal DAC"),					=> 'normal',
#-);
#-
#-@clockchip_name = (
#-    __("No Clockchip Setting (recommended)")                         => '',
#-    __("Chrontel 8391")                                              => 'ch8391',
#-    __("ICD2061A and compatibles (ICS9161A => DCS2824)")	     => 'icd2061a',
#-    __("ICS2595")                                                    => 'ics2595',
#-    __("ICS5342 (similar to SDAC, but not completely compatible)")   => 'ics5342',
#-    __("ICS5341")						     => 'ics5341',
#-    __("S3 GenDAC (86C708) and ICS5300 (autodetected)")	             => 's3gendac',
#-    __("S3 SDAC (86C716)")					     => 's3_sdac',
#-    __("STG 1703 (autodetected)")				     => 'stg1703',
#-    __("Sierra SC11412")					     => 'sc11412',
#-    __("TI 3025 (autodetected)")				     => 'ti3025',
#-    __("TI 3026 (autodetected)")				     => 'ti3026',
#-    __("IBM RGB 51x/52x (autodetected)")			     => 'ibm_rgb5xx',
#-);
#-

$intro_text = "
This program will create a basic XF86Config file, based on menu selections you make.

The XF86Config file usually resides in /usr/X11R6/lib/X11 or /etc/X11. A
sample XF86Config file is supplied with XFree86; it is configured for a
standard VGA card and monitor with 640x480 resolution.

You can either take the sample XF86Config as a base and edit it for your
configuration, or let this program produce a base XF86Config file for your
configuration and fine-tune it. Refer to /usr/X11R6/lib/X11/doc/README.Config
for a detailed overview of the configuration process.

For accelerated servers (including accelerated drivers in the SVGA server),
there are many chipset and card-specific options and settings. This program
does not know about these. On some configurations some of these settings must
be specified. Refer to the server man pages and chipset-specific READMEs.

Before continuing with this program, make sure you know the chipset and
amount of video memory on your video card. SuperProbe can help with this.
It is also helpful if you know what server you want to run.";

$s3_comment = '
# Use Option "nolinear" if the server doesn\'t start up correctly
# (this avoids the linear framebuffer probe). If that fails try
# option \"nomemaccess\".
#
# Refer to /usr/X11R6/lib/doc/README.S3, and the XF86_S3 man page.
';

$cirrus_comment = '
# Use Option \"no_bitblt\" if you have graphics problems. If that fails
# try Option \"noaccel\".
# Refer to /usr/X11R6/lib/doc/README.cirrus.
# To allow linear addressing, uncomment the Option line and the
# address that the card maps the framebuffer to.
';

$probeonlywarning_text = '
It is possible that the hardware detection routines in the server some how
cause the system to crash and the screen to remain blank. If this is the
case, skip this step the next time. The server may need a
Ramdac, ClockChip or special option (e.g. "nolinear" for S3) to probe
and start-up correctly.
';

$monitorintro_text = __('
Now we want to set the specifications of the monitor. The two critical
parameters are the vertical refresh rate, which is the rate at which the
the whole screen is refreshed, and most importantly the horizontal sync rate,
which is the rate at which scanlines are displayed.

The valid range for horizontal sync and vertical sync should be documented
in the manual of your monitor. If in doubt, check the monitor database
/usr/X11R6/lib/X11/doc/Monitors to see if your monitor is there.
');

$hsyncintro_text = __('
You must indicate the horizontal sync range of your monitor. You can either
select one of the predefined ranges below that correspond to industry-
standard monitor types, or give a specific range.

It is VERY IMPORTANT that you do not specify a monitor type with a horizontal
sync range that is beyond the capabilities of your monitor. If in doubt,
choose a conservative setting.
');

$vsyncintro_text = __('
You must indicate the vertical sync range of your monitor. You can either
select one of the predefined ranges below that correspond to industry-
standard monitor types, or give a specific range. For interlaced modes,
the number that counts is the high one (e.g. 87 Hz rather than 43 Hz).
');

$XF86firstchunk_text = '
# File generated by XConfigurator.

# **********************************************************************
# Refer to the XF86Config(4/5) man page for details about the format of
# this file.
# **********************************************************************

# **********************************************************************
# Files section.  This allows default font and rgb paths to be set
# **********************************************************************

Section "Files"

# The location of the RGB database.  Note, this is the name of the
# file minus the extension (like ".txt" or ".db").  There is normally
# no need to change the default.

    RgbPath	"/usr/X11R6/lib/X11/rgb"

# Multiple FontPath entries are allowed (they are concatenated together)
# By default, Red Hat 6.0 and later now use a font server independent of
# the X server to render fonts.

    FontPath   "unix/:-1"

EndSection

# **********************************************************************
# Server flags section.
# **********************************************************************

Section "ServerFlags"

    # Uncomment this to cause a core dump at the spot where a signal is
    # received.  This may leave the console in an unusable state, but may
    # provide a better stack trace in the core dump to aid in debugging
    #NoTrapSignals

    # Uncomment this to disable the <Crtl><Alt><BS> server abort sequence
    # This allows clients to receive this key event.
    #DontZap

    # Uncomment this to disable the <Crtl><Alt><KP_+>/<KP_-> mode switching
    # sequences.  This allows clients to receive these key events.
    #DontZoom

    # This  allows  the  server  to start up even if the
    # mouse device can\'t be opened/initialised.
    AllowMouseOpenFail

EndSection

# **********************************************************************
# Input devices
# **********************************************************************
';

$keyboardsection_start = '
# **********************************************************************
# Keyboard section
# **********************************************************************

Section "Keyboard"

    Protocol    "Standard"

    # when using XQUEUE, comment out the above line, and uncomment the
    # following line
    #Protocol   "Xqueue"

    AutoRepeat  0 0

    # Let the server do the NumLock processing.  This should only be
    # required when using pre-R6 clients
    #ServerNumLock

    # Specify which keyboard LEDs can be user-controlled (eg, with xset(1))
    #Xleds      1 2 3

    #To set the LeftAlt to Meta, RightAlt key to ModeShift,
    #RightCtl key to Compose, and ScrollLock key to ModeLock:

    LeftAlt        Meta
';

$keyboardsection_part2 = '
   ScrollLock      Compose
   RightCtl        Control

# To disable the XKEYBOARD extension, uncomment XkbDisable.

#    XkbDisable

# To customise the XKB settings to suit your keyboard, modify the
# lines below (which are the defaults).  For example, for a non-U.S.
# keyboard, you will probably want to use:
#    XkbModel    "pc102"
# If you have a US Microsoft Natural keyboard, you can use:
#    XkbModel    "microsoft"
#
# Then to change the language, change the Layout setting.
# For example, a german layout can be obtained with:
#    XkbLayout   "de"
# or:
#    XkbLayout   "de"
#    XkbVariant  "nodeadkeys"
#
# If you\'d like to switch the positions of your capslock and
# control keys, use:
#    XkbOptions  "ctrl:swapcaps"

# These are the default XKB settings for XFree86
#    XkbRules    "xfree86"
#    XkbModel    "pc101"
#    XkbLayout   "us"
#    XkbVariant  ""
#    XkbOptions  ""

    XkbKeycodes     "xfree86"
    XkbTypes        "default"
    XkbCompat       "default"
    XkbSymbols      "us(pc101)"
    XkbGeometry     "pc"
    XkbRules        "xfree86"
    XkbModel        "pc101"
';

$keyboardsection_end = '
EndSection
';

$pointersection_text1 = '
# **********************************************************************
# Pointer section
# **********************************************************************

Section "Pointer"
';

$pointersection_text2 = '

# When using XQUEUE, comment out the above two lines, and uncomment
# the following line.

#    Protocol	"Xqueue"

# Baudrate and SampleRate are only for some Logitech mice

#    BaudRate	9600
#    SampleRate	150

# Emulate3Buttons is an option for 2-button Microsoft mice
# Emulate3Timeout is the timeout in milliseconds (default is 50ms)
';

$monitorsection_text1 = '
# **********************************************************************
# Monitor section
# **********************************************************************

# Any number of monitor sections may be present

Section "Monitor"
';

$monitorsection_text2 = '
# HorizSync is in kHz unless units are specified.
# HorizSync may be a comma separated list of discrete values, or a
# comma separated list of ranges of values.
# NOTE: THE VALUES HERE ARE EXAMPLES ONLY.  REFER TO YOUR MONITOR\'S
# USER MANUAL FOR THE CORRECT NUMBERS.
';

$monitorsection_text3 = '
# VertRefresh is in Hz unless units are specified.
# VertRefresh may be a comma separated list of discrete values, or a
# comma separated list of ranges of values.
# NOTE: THE VALUES HERE ARE EXAMPLES ONLY.  REFER TO YOUR MONITOR\'S
# USER MANUAL FOR THE CORRECT NUMBERS.
';

$monitorsection_text4 = '
# Modes can be specified in two formats.  A compact one-line format, or
# a multi-line format.

# These two are equivalent

#    ModeLine "1024x768i" 45 1024 1048 1208 1264 768 776 784 817 Interlace

#    Mode "1024x768i"
#        DotClock	45
#        HTimings	1024 1048 1208 1264
#        VTimings	768 776 784 817
#        Flags		"Interlace"
#    EndMode
';

$modelines_text_Trident_TG_96xx = '
# This is a set of standard mode timings. Modes that are out of monitor spec
# are automatically deleted by the server (provided the HorizSync and
# VertRefresh lines are correct), so there\'s no immediate need to
# delete mode timings (unless particular mode timings don\'t work on your
# monitor). With these modes, the best standard mode that your monitor
# and video card can support for a given resolution is automatically
# used.

# These are special modelines for Trident Providia 9685. It is for VA Linux
# systems only.
# 640x480 @ 72 Hz, 36.5 kHz hsync
Modeline "640x480"     31.5   640  680  720  864   480  488  491  521
# 800x600 @ 72 Hz, 48.0 kHz hsync
Modeline "800x600"     50     800  856  976 1040   600  637  643  666 +hsync +vsync
# 1024x768 @ 60 Hz, 48.4 kHz hsync
#Modeline "1024x768"    65    1024 1032 1176 1344   768  771  777  806 -hsync -vsync
# 1024x768 @ 70 Hz, 56.5 kHz hsync
Modeline "1024x768"    75    1024 1048 1184 1328   768  771  777  806 -hsync -vsync
';
$modelines_text = '
# This is a set of standard mode timings. Modes that are out of monitor spec
# are automatically deleted by the server (provided the HorizSync and
# VertRefresh lines are correct), so there\'s no immediate need to
# delete mode timings (unless particular mode timings don\'t work on your
# monitor). With these modes, the best standard mode that your monitor
# and video card can support for a given resolution is automatically
# used.

# 640x400 @ 70 Hz, 31.5 kHz hsync
Modeline "640x400"     25.175 640  664  760  800   400  409  411  450
# 640x480 @ 60 Hz, 31.5 kHz hsync
Modeline "640x480"     25.175 640  664  760  800   480  491  493  525
# 800x600 @ 56 Hz, 35.15 kHz hsync
ModeLine "800x600"     36     800  824  896 1024   600  601  603  625
# 1024x768 @ 87 Hz interlaced, 35.5 kHz hsync
Modeline "1024x768"    44.9  1024 1048 1208 1264   768  776  784  817 Interlace

# 640x400 @ 85 Hz, 37.86 kHz hsync
Modeline "640x400"     31.5   640  672 736   832   400  401  404  445 -HSync +VSync
# 640x480 @ 72 Hz, 36.5 kHz hsync
Modeline "640x480"     31.5   640  680  720  864   480  488  491  521
# 640x480 @ 75 Hz, 37.50 kHz hsync
ModeLine  "640x480"    31.5   640  656  720  840   480  481  484  500 -HSync -VSync
# 800x600 @ 60 Hz, 37.8 kHz hsync
Modeline "800x600"     40     800  840  968 1056   600  601  605  628 +hsync +vsync

# 640x480 @ 85 Hz, 43.27 kHz hsync
Modeline "640x480"     36     640  696  752  832   480  481  484  509 -HSync -VSync
# 1152x864 @ 89 Hz interlaced, 44 kHz hsync
ModeLine "1152x864"    65    1152 1168 1384 1480   864  865  875  985 Interlace

# 800x600 @ 72 Hz, 48.0 kHz hsync
Modeline "800x600"     50     800  856  976 1040   600  637  643  666 +hsync +vsync
# 1024x768 @ 60 Hz, 48.4 kHz hsync
Modeline "1024x768"    65    1024 1032 1176 1344   768  771  777  806 -hsync -vsync

# 640x480 @ 100 Hz, 53.01 kHz hsync
Modeline "640x480"     45.8   640  672  768  864   480  488  494  530 -HSync -VSync
# 1152x864 @ 60 Hz, 53.5 kHz hsync
Modeline  "1152x864"   89.9  1152 1216 1472 1680   864  868  876  892 -HSync -VSync
# 800x600 @ 85 Hz, 55.84 kHz hsync
Modeline  "800x600"    60.75  800  864  928 1088   600  616  621  657 -HSync -VSync

# 1024x768 @ 70 Hz, 56.5 kHz hsync
Modeline "1024x768"    75    1024 1048 1184 1328   768  771  777  806 -hsync -vsync
# 1280x1024 @ 87 Hz interlaced, 51 kHz hsync
Modeline "1280x1024"   80    1280 1296 1512 1568  1024 1025 1037 1165 Interlace

# 800x600 @ 100 Hz, 64.02 kHz hsync
Modeline  "800x600"    69.65  800  864  928 1088   600  604  610  640 -HSync -VSync
# 1024x768 @ 76 Hz, 62.5 kHz hsync
Modeline "1024x768"    85    1024 1032 1152 1360   768  784  787  823
# 1152x864 @ 70 Hz, 62.4 kHz hsync
Modeline  "1152x864"   92    1152 1208 1368 1474   864  865  875  895
# 1280x1024 @ 61 Hz, 64.2 kHz hsync
Modeline "1280x1024"  110    1280 1328 1512 1712  1024 1025 1028 1054

# 1024x768 @ 85 Hz, 70.24 kHz hsync
Modeline "1024x768"   98.9  1024 1056 1216 1408   768 782 788 822 -HSync -VSync
# 1152x864 @ 78 Hz, 70.8 kHz hsync
Modeline "1152x864"   110   1152 1240 1324 1552   864  864  876  908

# 1280x1024 @ 70 Hz, 74.59 kHz hsync
Modeline "1280x1024"  126.5 1280 1312 1472 1696  1024 1032 1040 1068 -HSync -VSync
# 1600x1200 @ 60Hz, 75.00 kHz hsync
Modeline "1600x1200"  162   1600 1664 1856 2160  1200 1201 1204 1250 +HSync +VSync
# 1152x864 @ 84 Hz, 76.0 kHz hsync
Modeline "1152x864"   135    1152 1464 1592 1776   864  864  876  908

# 1280x1024 @ 74 Hz, 78.85 kHz hsync
Modeline "1280x1024"  135    1280 1312 1456 1712  1024 1027 1030 1064

# 1024x768 @ 100Hz, 80.21 kHz hsync
Modeline "1024x768"   115.5  1024 1056 1248 1440  768  771  781  802 -HSync -VSync
# 1280x1024 @ 76 Hz, 81.13 kHz hsync
Modeline "1280x1024"  135    1280 1312 1416 1664  1024 1027 1030 1064

# 1600x1200 @ 70 Hz, 87.50 kHz hsync
Modeline "1600x1200"  189    1600 1664 1856 2160  1200 1201 1204 1250 -HSync -VSync
# 1152x864 @ 100 Hz, 89.62 kHz hsync
Modeline "1152x864"   137.65 1152 1184 1312 1536   864  866  885  902 -HSync -VSync
# 1280x1024 @ 85 Hz, 91.15 kHz hsync
Modeline "1280x1024"  157.5  1280 1344 1504 1728  1024 1025 1028 1072 +HSync +VSync
# 1600x1200 @ 75 Hz, 93.75 kHz hsync
Modeline "1600x1200"  202.5  1600 1664 1856 2160  1200 1201 1204 1250 +HSync +VSync
# 1600x1200 @ 85 Hz, 105.77 kHz hsync
Modeline "1600x1200"  220    1600 1616 1808 2080  1200 1204 1207 1244 +HSync +VSync
# 1280x1024 @ 100 Hz, 107.16 kHz hsync
Modeline "1280x1024"  181.75 1280 1312 1440 1696  1024 1031 1046 1072 -HSync -VSync

# 1800x1440 @ 64Hz, 96.15 kHz hsync
ModeLine "1800X1440"  230    1800 1896 2088 2392 1440 1441 1444 1490 +HSync +VSync
# 1800x1440 @ 70Hz, 104.52 kHz hsync
ModeLine "1800X1440"  250    1800 1896 2088 2392 1440 1441 1444 1490 +HSync +VSync

# 512x384 @ 78 Hz, 31.50 kHz hsync
Modeline "512x384"    20.160 512  528  592  640   384  385  388  404 -HSync -VSync
# 512x384 @ 85 Hz, 34.38 kHz hsync
Modeline "512x384"    22     512  528  592  640   384  385  388  404 -HSync -VSync

# Low-res Doublescan modes
# If your chipset does not support doublescan, you get a \'squashed\'
# resolution like 320x400.

# 320x200 @ 70 Hz, 31.5 kHz hsync, 8:5 aspect ratio
Modeline "320x200"     12.588 320  336  384  400   200  204  205  225 Doublescan
# 320x240 @ 60 Hz, 31.5 kHz hsync, 4:3 aspect ratio
Modeline "320x240"     12.588 320  336  384  400   240  245  246  262 Doublescan
# 320x240 @ 72 Hz, 36.5 kHz hsync
Modeline "320x240"     15.750 320  336  384  400   240  244  246  262 Doublescan
# 400x300 @ 56 Hz, 35.2 kHz hsync, 4:3 aspect ratio
ModeLine "400x300"     18     400  416  448  512   300  301  302  312 Doublescan
# 400x300 @ 60 Hz, 37.8 kHz hsync
Modeline "400x300"     20     400  416  480  528   300  301  303  314 Doublescan
# 400x300 @ 72 Hz, 48.0 kHz hsync
Modeline "400x300"     25     400  424  488  520   300  319  322  333 Doublescan
# 480x300 @ 56 Hz, 35.2 kHz hsync, 8:5 aspect ratio
ModeLine "480x300"     21.656 480  496  536  616   300  301  302  312 Doublescan
# 480x300 @ 60 Hz, 37.8 kHz hsync
Modeline "480x300"     23.890 480  496  576  632   300  301  303  314 Doublescan
# 480x300 @ 63 Hz, 39.6 kHz hsync
Modeline "480x300"     25     480  496  576  632   300  301  303  314 Doublescan
# 480x300 @ 72 Hz, 48.0 kHz hsync
Modeline "480x300"     29.952 480  504  584  624   300  319  322  333 Doublescan

';

$devicesection_text = '
# **********************************************************************
# Graphics device section
# **********************************************************************

# Any number of graphics device sections may be present

Section "Device"
    Identifier        "Generic VGA"
    VendorName        "Unknown"
    BoardName "Unknown"
    Chipset   "generic"

#    VideoRam 256

#    Clocks   25.2 28.3

EndSection

# Device auto configured:
';

$screensection_text1 = '
# **********************************************************************
# Screen sections
# **********************************************************************
';

