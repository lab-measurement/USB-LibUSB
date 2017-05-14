#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use blib;
use LibUSB;

my $ctx = LibUSB->new();
$ctx->set_debug(LIBUSB_LOG_LEVEL_WARNING);

my @devices = $ctx->get_device_list();

for my $i (0..$#devices) {
    printf("$i: ");
    printf("Bus: %03d ", $devices[$i]->get_bus_number());
    printf("Device: %03d:", $devices[$i]->get_device_address());
    
    printf("\n");
}

my $dev = $devices[8];

my $handle = $dev->open();
