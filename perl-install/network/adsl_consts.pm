package network::adsl_consts; # $Id$

# This should probably be splited out into ldetect-lst as some provider db

use vars qw(@ISA @EXPORT);
use common;

@ISA = qw(Exporter);
@EXPORT = qw(@adsl_data);

our %adsl_data = (
                  # country|provider => { VPI, VCI_hexa, ... }
                  # dns are provided for when !usepeerdns in peers config file
                  N("Belgium") . "|Tiscali BE" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '212.35.2.1',
                   dnsServer3 => '212.35.2.2',
                  },

                  N("Belgium") . "|Belgacom" =>
                  {
                   vpi => 8,
                   vci => 23,
                  },

                  N("France") . "|Free non d�group� 512/128" =>
                  { 
                   vpi => 8, 
                   vci => 23,
                   dnsServer2 => '213.228.0.68',
                   dnsServer3 => '212.27.32.176',
                   method => 'pppoa',
                  },

                  N("France") . "|Free d�group� 1024/256 (mini)" =>
                  {
                   vpi => 8,
                   vci => 24,
                   dnsServer2 => '213.228.0.68',
                   dnsServer3 => '212.27.32.176',
                  },

                  N("France") . "|9online 512" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '62.62.156.12',
                   dnsServer3 => '62.62.156.13',
                   method => 'pppoa',
                  },

                  N("France") . "|Club-Internet" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '194.117.200.10',
                   dnsServer3 => '194.117.200.15',
                   method => 'pppoa',
                  },

                  N("France") . "|Wanadoo" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '193.252.19.3',
                   dnsServer3 => '193.252.19.4',
                   method => 'pppoa',
                  },

                  N("France") . "|T�l�2 128k " =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '212.151.136.242',
                   dnsServer3 => '130.244.127.162',
                   method => 'pppoa',
                  },

                  N("France") . "|Tiscali.fr 128k" =>
                  {
                   vpi => 8,
                   vci => 23, 
                   dnsServer2 => '213.36.80.1',
                   dnsServer3 => '213.36.80.2',
                   method => 'pppoa',
                  },

                  N("France") . "|Tiscali.fr 512k" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '213.36.80.1',
                   dnsServer3 => '213.36.80.2',
                   method => 'pppoa',
                  },

                  N("Finland") . "|Sonera" =>
                  {
                   vpi => 0,
                   vci => 64,
                  },

                  N("Germany") . "|Deutsche Telekom (DT)" =>
                  {
                   vpi => 1,
                   vci => 20,
                   method => 'pppoe',
                  },

                  N("Germany") . "|1&1" =>
                  {
                   vpi => 1,
                   vci => 20,
                   dnsServer2 => '195.20.224.234',
                   dnsServer3 => '194.25.2.129',
                   method => 'pppoe',
                  },

                  N("Hungary") . "|Matav" =>
                  {
                   vpi => 1,
                   vci => 20,
                  },

                  N("Italy") . "|Telecom Italia" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '195.20.224.234',
                   dnsServer3 => '194.25.2.129',
                   method => 'pppoa',
                  },

                  N("Italy") . "|Tiscali.it" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '195.20.224.234',
                   dnsServer3 => '194.25.2.129',
                   method => 'pppoa',
                  },

                  N("Netherlands") . "|KPN" =>
                  {
                   vpi => 8,
                   vci => 30,
                  },

                  N("Poland") . "|Telekomunikacja Polska (TPSA/neostrada)" =>
                  {
                   vpi => 0,
                   vci => 23,
                   dnsServer2 => '194.204.152.34',
                   dnsServer3 => '217.98.63.164',
                   method => 'pppoa',
                  },

                  N("Portugal") . "|PT" =>
                  {
                   vpi => 0,
                   vci => 23,
                  },
                  
                  N("Spain") . "|Telef�nica IP din�mica" =>
                  {
                   vpi => 8,
                   vci => 20,
                   dnsServer2 => '80.58.32.33',
                   dnsServer3 => '80.58.0.97',
                   method => 'pppoe',
                  },
                  N("Spain") . "|Telefonica ip fija" =>
                  {
                   vpi => 8,
                   vci => 20,
                   protocol => 'static',
                   dnsServer2 => '80.58.32.33',
                   dnsServer3 => '80.58.0.97',
                   method => 'static',
                  },

                  N("Spain") . "|Wanadoo/Eresmas" =>
                  {
                   vpi => 8,
                   vci => 23,
                   dnsServer2 => '80.58.0.33',
                   dnsServer3 => '80.58.32.97',
                   method => 'pppoa',
                  },

                  N("Sweden") . "|Telia" =>
                  {
                   vpi => 8,
                   vci => 23,
                  },

                  N("United Kingdom") . "|Tiscali UK " =>
                  {
                   vpi => 0,
                   vci => 26,
                  },

                  N("United Kingdom") . "|British Telecom " =>
                  {
                   vpi => 0,
                   vci => 26
                  },
                 );

1;
