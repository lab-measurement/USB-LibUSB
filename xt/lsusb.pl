#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use LibUSB;
use YAML::XS;

my $ctx = LibUSB->init();

my @dev_list = $ctx->get_device_list();

say "number of devices on the USB: ", (@dev_list + 0);
for my $dev (@dev_list) {
    print Dump $dev->get_device_descriptor();
}
