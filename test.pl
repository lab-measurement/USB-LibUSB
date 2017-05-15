#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use blib;
use LibUSB;
use YAML::XS;
use Data::Dumper;

my $ctx = LibUSB->init();
$ctx->set_debug(LIBUSB_LOG_LEVEL_WARNING);

my @devices = $ctx->get_device_list();

my $agilent;

for my $dev (@devices) {
    my $bus =  $dev->get_bus_number();
    my $address = $dev->get_device_address();
    
    my $descriptor = $dev->get_device_descriptor();
    my $idvendor = $descriptor->{idVendor};
    my $idproduct = $descriptor->{idProduct};
    if ($idvendor == 0x957) {
        $agilent = $dev;
        last;
    }
}
my $device_descriptor = $agilent->get_device_descriptor();
my $config_descriptor = $agilent->get_active_config_descriptor();
print Dump $device_descriptor;
print Dump $config_descriptor;

# my @endpoints = map {$_->{bEndpointAddress}} @{$config_descriptor->{interface}[0]{endpoint}};
# say "\n\nEndpoints: ";
# for my $address (@endpoints) {
#     say "bEndpointAddress: $address";
#     say "address: ", $address & (0b1111);
#     my $direction = $address & LIBUSB_ENDPOINT_IN ? "IN" : "OUT";
#     say "direction: $direction";
# }
my $handle = $agilent->open();
my $product = $handle->get_descriptor(LIBUSB_DT_STRING, $device_descriptor->{iSerialNumber});
print Dump $product;
#say "product: '$product'";
say "len: ", length $product;
