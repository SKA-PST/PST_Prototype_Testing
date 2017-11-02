package dspsr_benchmarker;

use strict;
use warnings;
use POSIX;

BEGIN {

  require Exporter;
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

  require AutoLoader;

  $VERSION = '1.00';

  @ISA         = qw(Exporter AutoLoader);
  @EXPORT      = qw(&main);
  %EXPORT_TAGS = ( );
  @EXPORT_OK   = qw($dl $centre_frequency $total_bandwidth @subband_bandwidths @channelisations @nbins);

}

our @EXPORT_OK;

our $dl = 1;
our $centre_frequency = 0;
our $total_bandwidth = 0;
our @subband_bandwidths = ();
our @subband_cfreqs = ();
our @channelisations = ();
our @nbins = ();

sub configure_subbands ()
{
  my $bottom = $centre_frequency - ( $total_bandwidth / 2);
  my $top = $centre_frequency + ( $total_bandwidth / 2);
    
  my $high = $bottom;
  my ($bw, $low, $mid);
  for $bw ( @subband_bandwidths )
  {
    $low = $high;
    $mid = $low + ($bw / 2);
    $high = $low + $bw;
    
    print "SubBand: ".$low." - ".$high." (".$bw.")\n";
    push @subband_cfreqs, $mid;
  }
  
  if ($high != $top)
  {
    print STDERR "Error in the sub-band frequency division\n";
    return -1;
  }
}

sub benchmark_mid() 
{
  my ($nbin, $channelisation);

  configure_subbands ();

  my $nsub = $#subband_cfreqs;
  my $top_freq = ($subband_cfreqs[$nsub] + ($subband_bandwidths[$nsub]/2)) / 1000.0;
  my $chan_bw = 10;

  print "DM\tNBIN\tNCHAN_IN\tNCHAN_OUT\tSubband\tBW\tCFREQ\tNFFT\tPERF\n";
  foreach $nbin ( @nbins )
  {
    foreach $channelisation ( @channelisations )
    {
      process ($nbin,$channelisation, $top_freq, $chan_bw, " -overlap");
    }
  }
}

sub benchmark_mid_fs() 
{
  my ($nbin, $channelisation);

  configure_subbands ();

  my $nsub = $#subband_cfreqs;
  my $top_freq = ($subband_cfreqs[$nsub] + ($subband_bandwidths[$nsub]/2)) / 1000.0;
  my $chan_bw = 0.048828125;

  print "DM\tNBIN\tNCHAN_IN\tNCHAN_OUT\tSubband\tBW\tCFREQ\tNFFT\tPERF\n";
  foreach $nbin ( @nbins )
  {
    foreach $channelisation ( @channelisations )
    {
      process ($nbin,$channelisation, $top_freq, $chan_bw, " -overlap");
    }
  }
}


sub benchmark_low_fine() 
{
  my ($nbin, $channelisation);

  configure_subbands ();

  my $bottom_freq = ($subband_cfreqs[0] - ($subband_bandwidths[0]/2)) / 1000.0;
  my $chan_bw = 0.003125;

  print "DM\tNBIN\tNCHAN_IN\tNCHAN_OUT\tSubband\tBW\tCFREQ\tNFFT\tPERF\n";
  foreach $nbin ( @nbins )
  {
    foreach $channelisation ( @channelisations )
    {
      process ($nbin, $channelisation, $bottom_freq, $chan_bw, "");
    }
  }
}


sub benchmark_low_coarse()
{
  my ($nbin, $channelisation);

  configure_subbands ();

  my $bottom_freq = ($subband_cfreqs[0] - ($subband_bandwidths[0]/2)) / 1000.0;
  my $chan_bw = 0.8;

  print "DM\tNBIN\tNCHAN_IN\tNCHAN_OUT\tSubband\tBW\tCFREQ\tNFFT\tPERF\n";
  foreach $nbin ( @nbins )
  {
    foreach $channelisation ( @channelisations )
    {
      process ($nbin, $channelisation, $bottom_freq, $chan_bw, "");
    }
  }
}


sub process ($$$$$)
{
  my ($nbin, $channelisation, $ref_freq, $chan_bw, $opts) = @_;

  my ($tres, $dm_raw, $dm, $i, $cmd, @lines, $fft, $perf);
  my ($nchan_in, $nchan_out, $cfreq, $bw, $subband, $response);

  $tres = (1.0/($chan_bw * 1e6)) * $channelisation;
  $dm_raw = 10 ** ((1.0/2.14) * (-0.154 + sqrt(0.0247 + 4.28 * (13.46 + 3.86 * log10($ref_freq) + log10($tres)))));
  $dm = ceil($dm_raw);

  if ($dl > 1)
  {
    print "ref_freq=$ref_freq channelisation=$channelisation tres=$tres dm=$dm\n";
  }

  for ($i=0; $i<=$#subband_bandwidths; $i++)
  {
    $subband = $i + 1;
    $bw = $subband_bandwidths[$i];
    $cfreq = $subband_cfreqs[$i];
    $nchan_in = $bw / $chan_bw;
    $nchan_out = $nchan_in * $channelisation;

    $cmd = "./DSPSR_Optimal_FFT.pl ".$bw." ".$cfreq." -dm ".$dm." -nchan_coarse ".$nchan_in." -nchan_fine ".$nchan_out." -nbin ".$nbin." ".$opts;
    if ($dl > 1)
    {
      print $cmd."\n";
    }
    $response = `$cmd`;
    @lines = split(/\n/, $response);
    ($fft, $perf) = split(/ /, $lines[$#lines]);
    printf $dm."\t".$nbin."\t".$nchan_in."\t".$nchan_out."\t".$subband."\t".$bw."\t".$cfreq."\t".$fft."\t".$perf."\n";
  }

}

sub process_incoherent ($$$$$)
{
  my ($nbin, $channelisation, $ref_freq, $chan_bw, $opts) = @_;

  my ($tres, $dm_raw, $dm, $i, $cmd, @lines, $fft, $perf);
  my ($nchan_in, $nchan_out, $cfreq, $bw, $subband, $response);
  my ($delta_freq);

  # channel bandwidth in MHz
  $delta_freq = 1.0 / $chan_bw;

  $tres = (1.0/($chan_bw * 1e6)) * $channelisation;
  $dm_raw = $tres / ( (4.15 * 1000) * ($ref_freq ** -2) - (($ref_freq + $delta_freq) ** -2));
  $dm = ceil($dm_raw);

  if ($dl > 1)
  {
    print "ref_freq=$ref_freq channelisation=$channelisation tres=$tres dm=$dm\n";
  }

  for ($i=0; $i<=$#subband_bandwidths; $i++)
  {
    $subband = $i + 1;
    $bw = $subband_bandwidths[$i];
    $cfreq = $subband_cfreqs[$i];
    $nchan_in = $bw / $chan_bw;
    $nchan_out = $nchan_in * $channelisation;

    $cmd = "./DSPSR_Optimal_FFT.pl ".$bw." ".$cfreq." -incoherent -dm ".$dm." -nchan_coarse ".$nchan_in." -nchan_fine ".$nchan_out." -nbin ".$nbin." ".$opts;
    if ($dl > 1)
    {
      print $cmd."\n";
    }
    $response = `$cmd`;
    @lines = split(/\n/, $response);
    ($fft, $perf) = split(/ /, $lines[$#lines]);
    printf $dm."\t".$nbin."\t".$nchan_in."\t".$nchan_out."\t".$subband."\t".$bw."\t".$cfreq."\t".$fft."\t".$perf."\n";
  }

}


END { } 

1;


