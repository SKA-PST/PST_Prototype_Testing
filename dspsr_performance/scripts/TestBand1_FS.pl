#!/usr/bin/env perl

use strict;
use warnings;
use dspsr_benchmarker;

$dspsr_benchmarker::centre_frequency = 700;
$dspsr_benchmarker::total_bandwidth = 700;

@dspsr_benchmarker::subband_bandwidths = ( 62.5, 81.25, 225, 331.25);

@dspsr_benchmarker::channelisations = ( 1 );
@dspsr_benchmarker::nbins = ( 2048 );

dspsr_benchmarker->benchmark_mid_fs ();
