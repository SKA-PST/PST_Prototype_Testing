#!/usr/bin/env perl

use strict;
use warnings;
use dspsr_benchmarker;

$dspsr_benchmarker::dl = 1;
$dspsr_benchmarker::centre_frequency = 5850;
$dspsr_benchmarker::total_bandwidth = 2500;

@dspsr_benchmarker::subband_bandwidths = ( 600, 620, 630, 650 );
@dspsr_benchmarker::channelisations = ( 1 );
@dspsr_benchmarker::nbins = ( 1024 );

dspsr_benchmarker->benchmark_mid ();
