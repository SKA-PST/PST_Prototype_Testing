#!/usr/bin/env perl

use strict;
use warnings;
use dspsr_benchmarker;

$dspsr_benchmarker::centre_frequency = 3990;
$dspsr_benchmarker::total_bandwidth = 2380;

@dspsr_benchmarker::subband_bandwidths = ( 590, 590, 600, 600 ); 
@dspsr_benchmarker::channelisations = ( 1 );
@dspsr_benchmarker::nbins = ( 1024 );

dspsr_benchmarker->benchmark_mid ();
