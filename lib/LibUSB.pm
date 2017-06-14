use strict;
use warnings;
package LibUSB;

use Moo;
use LibUSB::XS;
use LibUSB::Device;
use LibUSB::Device::Handle;
use Carp;

our $VERSION = '0.01';

has 'ctx' => (
    is => 'ro',
    init_arg => undef,
    writer => '_ctx',
    );

has last_retval => (
    is => 'ro',
    init_arg => undef,
    writer => '_last_retval',
    default => sub {0;},
    );

sub _handle_error {
    my ($self, $rv, $function) = @_;

    if ($rv >= 0) {
        return $rv;
    }
    $function = "libusb_$function";
    my $strerror = libusb_strerror($rv);

    $self->_last_retval($rv);

    croak("error in $function: $strerror");
}

sub BUILD {
    my ($self, @args) = @_;

    my ($rv, $ctx) = LibUSB::XS->init();
    $self->_handle_error($rv, "init");
    $self->_ctx($ctx);
}

sub init {
    return new(@_);
}

sub set_debug {
    my $self = shift;
    $self->ctx()->set_debug(@_);
}

# libusb_open_device_with_vid_pid: create LibUSB::Device::Handle objects

sub exit {
    my $self = shift;
    $self->ctx()->exit();
}

sub get_device_list {
    my $self = shift;
    my $ctx = $self->ctx();
    my ($rv, @dev_list) = $ctx->get_device_list();
    $self->_handle_error($rv, "get_device_list");
    return map LibUSB::Device->new(ctx => $self, device => $_), @dev_list;
}

sub open_device_with_vid_pid {
    my $self = shift;
    my $ctx = $self->ctx();
    my $handle = $ctx->open_device_with_vid_pid(@_);
    if (not defined $handle) {
        croak "Error in libusb_open_device_with_vid_pid.",
        " use libusb_open for detailed error message.";
    }
    return LibUSB::Device::Handle->new(ctx => $self, handle => $handle);
}

sub open_device_with_vid_pid_unique {
    my ($self, $target_vid, $target_pid) = @_;
    
    my $vid_pid_string = sprintf("%04x:%04x", $target_vid, $target_pid);

    my @device_list = $self->get_device_list();

    @device_list = grep {
        my $dev = $_;
        my $desc = $dev->get_device_descriptor();
        ($desc->{idVendor} == $target_vid
         && $desc->{idProduct} == $target_pid);
    } @device_list;

    my $num_devs = @device_list;
    
    if ($num_devs == 0) {
        croak "did not find any device with vid:pid = $vid_pid_string.";
    }
    
    if ($num_devs > 1) {
        croak "non-unique vid:pid combination $vid_pid_string. ".
            "Found $num_devs device with this combination.";
    } 
    
    return $device_list[0]->open();
}

sub open_device_with_vid_pid_serial {
    my ($self, $target_vid, $target_pid, $target_serial_number) = @_;
    
    my $vid_pid_string = sprintf("%04x:%04x", $target_vid, $target_pid);

    my @device_list = $self->get_device_list();

    if (@device_list == 0) {
        croak "did not find any devices";
    }

    my $valid_device;
    
    for my $dev (@device_list) {
        my $desc = $dev->get_device_descriptor();
        my $vid = $desc->{idVendor};
        my $pid = $desc->{idProduct};
        
        if ($vid != $target_vid || $pid != $target_pid) {
            next;
        }

        # correct vid and pid. Look at serial number.
        my $iserial = $desc->{iSerialNumber};
        if ($iserial == 0) {
            croak "device with vid/pid = $vid_pid_string does have a serial number.";
        }

        my $handle = $dev->open();
        my $serial_number = $handle->get_string_descriptor_ascii(
            $iserial, 1000
            );
        
        if ($serial_number eq $target_serial_number) {
            if (defined $valid_device) {
                croak "non-unique serial number";
            }
            $valid_device = $dev;
        }
        $handle->close();
    }
    
    if (not defined $valid_device) {
        croak "did not find any device with pid:vid = $vid_pid_string".
            " and serial number $target_serial_number.";
    }
    
    return $valid_device->open();
}

1;

=head1 NAME

LibUSB - Perl interface to the libusb-1.0 API.

=head1 SYNOPSIS

 use LibUSB;

 #
 # simple program to list all devices on the USB
 #
 
 my $ctx = LibUSB->init();
 my @devices = $ctx->get_device_list();
 
 for my $dev (@devices) {
     my $bus_number = $dev->get_bus_number();
     my $device_address = $dev->get_device_address();
     my $desc = $dev->get_device_descriptor();
     my $idVendor = $desc->{idVendor};
     my $idProduct = $desc->{idProduct};
     
     printf("Bus %03d Device %03d: ID %04x:%04x\n", $bus_number,
            $device_address, $idVendor, $idProduct);
 }
    
 #
 # Synchronous bulk transfers
 #

 my $ctx = LibUSB->init();
 my $handle = $ctx->open_device_with_vid_pid(0x1111, 0x2222);
 $handle->claim_interface(0);

 $handle->bulk_transfer_write($endpoint, $data, $timeout);
 $handle->bulk_transfer_read($endpoint, $length, $timeout);
 

=head1 DESCRIPTION

 FIXME:
 - what is libusb-1.0?
 - this package vs LibUSB::XS.

=head1 INSTALLATION

This requires libusb development files and pkg-config installed.

On Debian-like B<Linux> you need to run

 $ apt-get install libusb-1.0-0-dev pkg-config

On B<Windows>, the only tested build so far is with
L<Cygwin|https://www.cygwin.com/>. You need the pkg-config, libusb1.0-devel and
libcrypt-devel packages.

The rest of the installation can be done by a cpan client like cpanm:

 $ cpanm LibUSB

 
=head1 METHODS/FUNCTIONS

FIXME: document all hash keys.

=head2 Library initialization/deinitialization

=head3 set_debug

 $ctx->set_debug(LIBUSB_LOG_LEVEL_DEBUG);

=head3 init

 my $ctx = LibUSB->init();

=head3 exit

 $ctx->exit();

=head2 Device handling and enumeration

=head3 get_device_list

 my @device_list = $ctx->get_device_list();

=head3 get_bus_number

 my $bus_number = $dev->get_bus_number();

=head3 get_port_number

 my $port_number = $dev->get_port_number();

=head3 get_port_numbers

 my @port_numbers = $dev->get_port_numbers();

=head3 get_parent

 my $parent_dev = $dev->get_parent();

=head3 get_device_address

 my $address = $dev->get_device_address();

=head3 get_device_speed

 my $speed = $dev->get_device_speed();

=head3 get_max_packet_size

 my $size = $dev->get_max_packet_size($endpoint);

=head3 get_max_iso_packet_size

 my $size = $dev->get_max_iso_packet_size($endpoint);

=head3 ref_device

 $dev->ref_device();

=head3 unref_device

 $dev->unref_device();

=head3 open

 my $handle = $dev->open();

Return a LibUSB::Device::Handle object.

=head3 open_device_with_vid_pid

 my $handle = $ctx->open_device_with_vid_pid(0x1111, 0x2222);

Return a LibUSB::Device::Handle object. If the vid:pid combination is not
unique, return the first device which is found.

=head3 open_device_with_vid_pid_unique

 my $handle = $ctx->open_device_with_vid_pid_unique(0x1111, 0x2222);

Like C<open_device_with_vid_pid>, but croak in case of multiple devices with
this vid:pid combination.

=head3 open_device_with_vid_pid_serial

 my $handle = $ctx->open_device_with_vid_pid_serial(0x0957, 0x0607, "MY47000419");

Like C<open_device_with_vid_pid>, but also requires a serial number.
 
=head3 close

 $handle->close();

=head3 get_device

 my $dev = $hanlde->get_device();

=head3 get_configuration

 my $config = $handle->get_configuration();

=head3 set_configuration

 $handle->set_configuration($config);

=head3 claim_interface

 $handle->claim_interface($interface_number);

=head3 release_interface

 $handle->release_interface($interface_number);

=head3 set_interface_alt_setting

 $handle->set_interface_alt_setting($interface_number, $alternate_setting);

=head3 clear_halt

 $handle->clear_halt($endpoint);

=head3 reset_device

 $handle->reset_device();

=head3 kernel_driver_active

 my $is_active = $handle->kernelt_driver_active($interface_number);

=head3 detach_kernel_driver

 $handle->detach_kernel_driver($interface_number);

=head3 attach_kernel_driver

 $handle->attach_kernel_driver($interface_number);

=head3 set_auto_detach_kernel_driver

 $handle->set_auto_detach_kernel_driver($enable);

=head2 Miscellaneous

FIXME: export these

=head3 libusb_has_capability

 my $has_cap = libusb_has_capability($capability);

=head3 libusb_error_name

 my $error_name = libusb_error_name($error_code);

=head3 libusb_get_version

 my $version_hash = libusb_get_version();
 my $major = $version_hash->{major};

=head3 libusb_setlocale

 my $rv = libusb_setlocale($locale);

=head3 libusb_strerror

 my $strerror = libusb_strerror($error_code);

=head2 USB descriptors

All descriptors are returned as hash references.

=head3 get_device_descriptor

 my $desc = $dev->get_device_descriptor();
 my $iSerialNumber = $desc->{iSerialNumber};

=head3 get_active_config_descriptor

 my $config = $dev->get_active_config_descriptor();
 my $iConfiguration = $config->{iConfiguration};

=head3 get_config_descriptor

 my $config = $dev->get_config_descriptor($config_index);

=head3 get_config_descriptor_by_value

 my $config = $dev->get_config_descriptor_by_value($bConfigurationValue);

=head3 get_string_descriptor_ascii

 my $data = $handle->get_string_descriptor_ascii($desc_index, $length);

=head3 get_descriptor

 my $data = $handle->get_descriptor($desc_type, $desc_index, $length);

=head3 get_string_descriptor

 my $data = $handle->get_string_descriptor($desc_index, $langid, $length);

 
=head2 Device hotplug event notification

To be implemented.

=head2 Asynchronous device I/O

To be implemented.

=head2 Polling and timing

To be implemented.

=head2 Synchronous device I/O

=head3 control_transfer_write

 $handle->control_transfer_write($bmRequestType, $bRequest, $wValue, $wIndex, $data, $timeout);

=head3 control_transfer_read

 my $data = $handle->control_transfer_read($bmRequestType, $bRequest, $wValue, $wIndex, $length, $timeout);
 
=head3 bulk_tranfer_write

 $handle->bulk_transfer_write($endpoint, $data, $timeout);
 
=head3 bulk_transfer_read

 my $data = $handle->bulk_transfer_read($endpoint, $length, $timeout);
 
=head3 interrupt_transfer_write

 $handle->interrupt_transfer_write($endpoint, $data, $timeout);

=head3 interrupt_transfer_read

 my $data = $handle->interrupt_transfer_read($endpoint, $length, $timeout);

=head1 AUTHOR

Simon Reinhardt, E<lt>simon.reinhardt@stud.uni-regensburg.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Simon Reinhardt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
