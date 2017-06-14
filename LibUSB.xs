#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libusb.h>

#include "const-c.inc"

typedef libusb_context *LibUSB__XS;
typedef libusb_device *LibUSB__XS__Device;
typedef libusb_device_handle *LibUSB__XS__Device__Handle;

static void
do_not_warn_unused(void *x __attribute__((__unused__)))
{
}

static SV *
endpoint_descriptor_to_HV(pTHX_ const struct libusb_endpoint_descriptor *endpoint)
{
  HV *rv = newHV();
  hv_stores(rv, "bLength", newSVuv(endpoint->bLength));
  hv_stores(rv, "bDescriptorType", newSVuv(endpoint->bDescriptorType));
  hv_stores(rv, "bEndpointAddress", newSVuv(endpoint->bEndpointAddress));
  hv_stores(rv, "bmAttributes", newSVuv(endpoint->bmAttributes));
  hv_stores(rv, "wMaxPacketSize", newSVuv(endpoint->wMaxPacketSize));
  hv_stores(rv, "bInterval", newSVuv(endpoint->bInterval));
  hv_stores(rv, "bRefresh", newSVuv(endpoint->bRefresh));
  hv_stores(rv, "bSynchAddress", newSVuv(endpoint->bSynchAddress));
  hv_stores(rv, "extra", newSVpvn((const char *)endpoint->extra, endpoint->extra_length));
  return newRV_noinc((SV *) rv);
}

static SV *
endpoint_array_to_AV(pTHX_ const struct libusb_endpoint_descriptor *endpoint, int num_endpoints)
{
  AV *rv = newAV();
  for (int i = 0; i < num_endpoints; ++i)
      av_push(rv, endpoint_descriptor_to_HV(aTHX_ &endpoint[i]));
  return newRV_noinc((SV *) rv);
}


static SV *
interface_descriptor_to_HV(pTHX_ const struct libusb_interface_descriptor *interface)
{
  HV *rv = newHV();
  hv_stores(rv, "bLength", newSVuv(interface->bLength));
  hv_stores(rv, "bDescriptorType", newSVuv(interface->bDescriptorType));
  hv_stores(rv, "bInterfaceNumber", newSVuv(interface->bInterfaceNumber));
  hv_stores(rv, "bAlternateSetting", newSVuv(interface->bAlternateSetting));
  hv_stores(rv, "bNumEndpoints", newSVuv(interface->bNumEndpoints));
  hv_stores(rv, "bInterfaceClass", newSVuv(interface->bInterfaceClass));
  hv_stores(rv, "bInterfaceProtocol", newSVuv(interface->bInterfaceProtocol));
  hv_stores(rv, "iInterface", newSVuv(interface->iInterface));
  hv_stores(rv, "endpoint", endpoint_array_to_AV(aTHX_ interface->endpoint, interface->bNumEndpoints));
  hv_stores(rv, "extra", newSVpvn((const char *) interface->extra, interface->extra_length));
  return newRV_noinc((SV *) rv);
}

static SV *
interface_array_to_AV(pTHX_ const struct libusb_interface *interface)
{
  AV *rv = newAV();
  for (int i = 0; i < interface->num_altsetting; ++i)
    av_push(rv, interface_descriptor_to_HV(aTHX_ &interface->altsetting[i]));
  return newRV_noinc((SV *) rv);  
}

static SV *
config_descriptor_to_RV(pTHX_ struct libusb_config_descriptor *config)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(config->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(config->bDescriptorType));
    hv_stores(rv, "wTotalLength", newSVuv(config->wTotalLength));
    hv_stores(rv, "bNumInterfaces", newSVuv(config->bNumInterfaces));
    hv_stores(rv, "bConfigurationValue", newSVuv(config->bConfigurationValue));
    hv_stores(rv, "iConfiguration", newSVuv(config->iConfiguration));
    hv_stores(rv, "bmAttributes", newSVuv(config->bmAttributes));
    hv_stores(rv, "MaxPower", newSVuv(config->MaxPower));
    hv_stores(rv, "interface", interface_array_to_AV(aTHX_ config->interface));
    hv_stores(rv, "extra", newSVpvn((const char *) config->extra, config->extra_length));
    return newRV_noinc((SV *) rv);
}

static SV *
device_descriptor_to_RV(pTHX_ struct libusb_device_descriptor *desc)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(desc->bLength));    
    hv_stores(rv, "bDescriptorType", newSVuv(desc->bDescriptorType));
    hv_stores(rv, "bcdUSB", newSVuv(desc->bcdUSB));
    hv_stores(rv, "bDeviceClass", newSVuv(desc->bDeviceClass));
    hv_stores(rv, "bDeviceSubClass", newSVuv(desc->bDeviceSubClass));
    hv_stores(rv, "bDeviceProtocol", newSVuv(desc->bDeviceProtocol));
    hv_stores(rv, "bMaxPacketSize0", newSVuv(desc->bMaxPacketSize0));
    hv_stores(rv, "idVendor", newSVuv(desc->idVendor));
    hv_stores(rv, "idProduct", newSVuv(desc->idProduct));
    hv_stores(rv, "bcdDevice", newSVuv(desc->bcdDevice));
    hv_stores(rv, "iManufacturer", newSVuv(desc->iManufacturer));
    hv_stores(rv, "iProduct", newSVuv(desc->iProduct));
    hv_stores(rv, "iSerialNumber", newSVuv(desc->iSerialNumber));
    hv_stores(rv, "bNumConfigurations", newSVuv(desc->bNumConfigurations));
    return newRV_noinc((SV *) rv);
}

static SV *
version_to_RV(pTHX_ const struct libusb_version *version)
{
    HV *rv = newHV();
    hv_stores(rv, "major", newSVuv(version->major));
    hv_stores(rv, "minor", newSVuv(version->minor));
    hv_stores(rv, "micro", newSVuv(version->micro));
    hv_stores(rv, "nano", newSVuv(version->nano));
    hv_stores(rv, "rc", newSVpv(version->rc, 0));
    // "describe" key is for ABI compatibilty only => do not implement
    return newRV_noinc((SV *) rv);
}

static SV *
pointer_object(pTHX_ const char *class_name, void *pv)
{
    SV *rv = newSV(0);
    sv_setref_pv(rv, class_name, pv);
    return rv;
}

MODULE = LibUSB::XS      PACKAGE = LibUSB::XS

int
libusb_has_capability(unsigned capability)


const char *
libusb_error_name(int error_code)


void
libusb_get_version(void)
PPCODE:
    const struct libusb_version *version = libusb_get_version();
    mXPUSHs(version_to_RV(aTHX_ version));


int
libusb_setlocale(const char *locale)


const char *
libusb_strerror(int error_code)


MODULE = LibUSB::XS		PACKAGE = LibUSB::XS     PREFIX = libusb_	

INCLUDE: const-xs.inc

void
libusb_set_debug(LibUSB::XS ctx, int level)

void
libusb_init(char *class)
PPCODE:
    libusb_context *ctx;
    int rv = libusb_init(&ctx);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(pointer_object(aTHX_ class, ctx));



void
libusb_exit(LibUSB::XS ctx)

void
libusb_get_device_list(LibUSB::XS ctx)
PPCODE:
    libusb_device **list;
    ssize_t num = libusb_get_device_list(ctx, &list);
    mXPUSHi(num);
    ssize_t i;
    for (i = 0; i < num; ++i) {
        SV *tmp = newSV(0);
        sv_setref_pv(tmp, "LibUSB::XS::Device", (void *) list[i]);
        mXPUSHs(tmp);
    }
    if (num >= 0)
        libusb_free_device_list(list, 0);

LibUSB::XS::Device::Handle
libusb_open_device_with_vid_pid(LibUSB::XS ctx, unsigned vendor_id, unsigned product_id)


void
DESTROY(LibUSB::XS ctx)
CODE:
    do_not_warn_unused(ctx);



MODULE = LibUSB::XS      PACKAGE = LibUSB::XS::Device       PREFIX = libusb_

unsigned
libusb_get_bus_number(LibUSB::XS::Device dev)

unsigned
libusb_get_port_number(LibUSB::XS::Device dev)

void
libusb_get_port_numbers(LibUSB::XS::Device dev)
PPCODE:
    int len = 20;
    uint8_t port_numbers[len];
    int num = libusb_get_port_numbers(dev, port_numbers, len);
    mXPUSHi(num);
    int i;
    for (i = 0; i < num; ++i) {
        mXPUSHu(port_numbers[i]);
    }

# libusb_get_port_path is deprecated => do not implement

LibUSB::XS::Device
libusb_get_parent(LibUSB::XS::Device dev)


unsigned
libusb_get_device_address(LibUSB::XS::Device dev)


int
libusb_get_device_speed(LibUSB::XS::Device dev)


int
libusb_get_max_packet_size(LibUSB::XS::Device dev, unsigned char endpoint)


int
libusb_get_max_iso_packet_size(LibUSB::XS::Device dev, unsigned char endpoint)


LibUSB::XS::Device
libusb_ref_device(LibUSB::XS::Device dev)


void
libusb_unref_device(LibUSB::XS::Device dev)

void
libusb_open(LibUSB::XS::Device dev)
PPCODE:
    libusb_device_handle *handle;
    int rv = libusb_open(dev, &handle);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(pointer_object(aTHX_ "LibUSB::XS::Device::Handle", handle));
    


void
libusb_get_device_descriptor(LibUSB::XS::Device dev)
PPCODE:
    struct libusb_device_descriptor desc;
    int rv = libusb_get_device_descriptor(dev, &desc);
    mXPUSHi(rv);
    // Function always succeeds since libusb 1.0.16
    mXPUSHs(device_descriptor_to_RV(aTHX_ &desc));

    
void
libusb_get_active_config_descriptor(LibUSB::XS::Device dev)
PPCODE:
    struct libusb_config_descriptor *config;
    int rv = libusb_get_active_config_descriptor(dev, &config);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(config_descriptor_to_RV(aTHX_ config));

    
void
libusb_get_config_descriptor(LibUSB::XS::Device dev, unsigned config_index)
PPCODE:
    struct libusb_config_descriptor *config;
    int rv = libusb_get_config_descriptor(dev, config_index, &config);
    mXPUSHi(rv);
    if (rv == 0) {
        mXPUSHs(config_descriptor_to_RV(aTHX_ config));
        libusb_free_config_descriptor(config);
    }

    
void
DESTROY(LibUSB::XS::Device dev)
CODE:
    do_not_warn_unused(dev);




MODULE = LibUSB      PACKAGE = LibUSB::XS::Device::Handle       PREFIX = libusb_

void
libusb_close(LibUSB::XS::Device::Handle handle)


LibUSB::XS::Device
libusb_get_device(LibUSB::XS::Device::Handle dev_handle)

void
libusb_get_configuration(LibUSB::XS::Device::Handle dev)
PPCODE:
    int config;
    int rv = libusb_get_configuration(dev, &config);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHi(config);

int
libusb_set_configuration(LibUSB::XS::Device::Handle dev, int configuration)

int
libusb_claim_interface(LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_release_interface(LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_set_interface_alt_setting(LibUSB::XS::Device::Handle dev, int interface_number, int alternate_setting)

int
libusb_clear_halt(LibUSB::XS::Device::Handle dev, unsigned endpoint)

int
libusb_reset_device(LibUSB::XS::Device::Handle dev)

int
libusb_kernel_driver_active(LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_detach_kernel_driver(LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_attach_kernel_driver(LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_set_auto_detach_kernel_driver(LibUSB::XS::Device::Handle dev, int enable)

void
libusb_get_string_descriptor_ascii(LibUSB::XS::Device::Handle dev, unsigned desc_index, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_string_descriptor_ascii(dev, desc_index, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


void
libusb_get_descriptor(LibUSB::XS::Device::Handle dev, unsigned desc_type, unsigned desc_index, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_descriptor(dev, desc_type, desc_index, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


void
libusb_get_string_descriptor(LibUSB::XS::Device::Handle dev, unsigned desc_index, unsigned langid, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_string_descriptor(dev, desc_index, langid, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


############################
#
# Synchronous device I/O
#
############################

void
DESTROY(LibUSB::XS::Device::Handle handle)
CODE:
    do_not_warn_unused(handle);


void
libusb_control_transfer_write(LibUSB::XS::Device::Handle handle, unsigned bmRequestType, unsigned bRequest, unsigned wValue, unsigned wIndex, SV *data, unsigned timeout)
PPCODE:
    char *bytes;
    STRLEN len;
    bytes = SvPV(data, len);
    if (len == 0)
        bytes = NULL;
    mXPUSHi(libusb_control_transfer(handle, bmRequestType, bRequest, wValue, wIndex, (unsigned char *) bytes, len, timeout));

void
libusb_control_transfer_read(LibUSB::XS::Device::Handle handle, unsigned bmRequestType, unsigned bRequest, unsigned wValue, unsigned wIndex, unsigned length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int rv = libusb_control_transfer(handle, bmRequestType, bRequest, wValue, wIndex, (unsigned char *) data, length, timeout);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(data, rv);
    Safefree(data);

# Check whether endpoint is host-to-device in high-level code
void
libusb_bulk_transfer_write(LibUSB::XS::Device::Handle handle, unsigned endpoint, SV *data, unsigned timeout)
PPCODE:
    STRLEN len;
    char *bytes = SvPV(data, len);
    int transferred;
    int rv = libusb_bulk_transfer(handle, endpoint, (unsigned char *) bytes, len, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHi(transferred);

# Check whether endpoint is device-to-host in high-level code
void
libusb_bulk_transfer_read(LibUSB::XS::Device::Handle handle, unsigned endpoint, int length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int transferred;
    int rv = libusb_bulk_transfer(handle, endpoint, (unsigned char *) data, length, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHp(data, transferred);
    Safefree(data);

# Check whether endpoint is host-to-device in high-level code
void
libusb_interrupt_transfer_write(LibUSB::XS::Device::Handle handle, unsigned endpoint, SV *data, unsigned timeout)
PPCODE:
    STRLEN len;
    char *bytes = SvPV(data, len);
    int transferred;
    int rv = libusb_interrupt_transfer(handle, endpoint, (unsigned char *) bytes, len, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHi(transferred);

# Check whether endpoint is device-to-host in high-level code
void
libusb_interrupt_transfer_read(LibUSB::XS::Device::Handle handle, unsigned endpoint, int length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int transferred;
    int rv = libusb_interrupt_transfer(handle, endpoint, (unsigned char *) data, length, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHp(data, transferred);
    Safefree(data);
    
