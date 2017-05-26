#!perl
use strict;
use warnings;

use Test::More;
BEGIN { use_ok('LibUSB') };

my $ctx = LibUSB->init();
$ctx->set_debug(LIBUSB_LOG_LEVEL_WARNING);
$ctx->exit();

done_testing();
