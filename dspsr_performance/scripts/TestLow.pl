#!/usr/bin/env perl

use strict;
use warnings;
use dspsr_benchmarker;

# 800 kHz channels

$dspsr_benchmarker::dl = 1;
$dspsr_benchmarker::centre_frequency = 200;
$dspsr_benchmarker::total_bandwidth = 300;

@dspsr_benchmarker::subband_bandwidths = ( 24, 64, 96, 116);
@dspsr_benchmarker::channelisations = ( 1 );
@dspsr_benchmarker::nbins = ( 1024);

# until DSPSR has the inverting FB, use coarse channels
dspsr_benchmarker->benchmark_low_coarse ();

