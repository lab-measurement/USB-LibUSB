#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use blib;
use LibUSB;
use YAML::XS;

my $ctx = LibUSB->init();
$ctx->set_debug(LIBUSB_LOG_LEVEL_WARNING);

my @devices = $ctx->get_device_list();

for my $dev (@devices) {
    my $bus =  $dev->get_bus_number();
    my $address = $dev->get_device_address();
    
    my $descriptor = $dev->get_device_descriptor();
    my $idvendor = $descriptor->{idVendor};
    my $idproduct = $descriptor->{idProduct};
    
    printf("Bus %03d Device %03d: ID %04x:%04x\n",
           $bus, $address, $idvendor, $idproduct);
}

my $dev = $devices[8];

