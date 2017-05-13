#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use blib;
use LibUSB;

my $ctx = LibUSB->new();
my @devices = $ctx->get_device_list();

for my $dev (@devices) {
    printf("Bus: %03d ", $dev->get_bus_number());
    printf("Device: %03d:", $dev->get_device_address());
    
    printf("\n");
}

my @ports = $devices[7]->get_port_numbers();

say "ports: @ports";

my $parent = $devices[7]->get_parent();
say "parent: $parent";

$parent = $devices[1]->get_parent();
say "parent: $parent";
