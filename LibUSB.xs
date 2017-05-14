#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libusb.h>

#include "const-c.inc"

typedef libusb_context *LibUSB;
typedef libusb_device *LibUSB__Device;
typedef libusb_device_handle *LibUSB__Device__Handle;

#define CROAK(arg1, ...) \
    call_va_list("Carp::croak", arg1, ## __VA_ARGS__, NULL)
#define CARP(arg1, ...) \
    call_va_list("Carp::carp", arg1, ## __VA_ARGS__, NULL)

static void
call_va_list(char *func, char *arg1, ...)
{
    va_list ap;
    va_start(ap, arg1);
    
    /* See perlcall.  */
    dSP;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    mXPUSHp(arg1, strlen(arg1));
    while (1) {
        char *arg = va_arg(ap, char *);
        if (arg == NULL)
            break;
        mXPUSHp(arg, strlen(arg));
    }
    PUTBACK;

    call_pv(func, G_DISCARD);

    FREETMPS;
    LEAVE;
}

static void
handle_error(ssize_t errcode, const char *function_name)
{
  /* Some functions like libusb_get_device_list return positive numbers
     on success. So do not check for == 0.  */
  if (errcode >= 0)
    return;
  const char *error = libusb_strerror(errcode);
  CROAK("Error in ", function_name, ": ", error);
}

MODULE = LibUSB		PACKAGE = LibUSB	 PREFIX = libusb_	

INCLUDE: const-xs.inc

LibUSB
new(const char *class)
CODE:
    LibUSB ctx;
    int rv = libusb_init(&ctx);
    handle_error(rv, "libusb_init");
    RETVAL = ctx;
OUTPUT:
    RETVAL


void
libusb_set_debug(LibUSB ctx, int level)
CODE:
    libusb_set_debug(ctx, level);





void
libusb_get_device_list(LibUSB ctx)
PPCODE:
    libusb_device **list;
    ssize_t num = libusb_get_device_list(ctx, &list);
    handle_error(num, "libusb_get_device_list");
    size_t i;
    for (i = 0; i < num; ++i) {
        SV *tmp = newSV(0);
        sv_setref_pv(tmp, "LibUSB::Device", (void *) list[i]);
        mXPUSHs(tmp);
    }
    libusb_free_device_list(list, 0);

LibUSB::Device::Handle
libusb_open_device_with_vid_pid(LibUSB ctx, unsigned vendor_id, unsigned product_id)
CODE:
    libusb_device_handle *handle;
    handle = libusb_open_device_with_vid_pid(ctx, vendor_id, product_id);
    if (handle == NULL)
        CROAK("Error in libusb_open_device_with_vid_pid.",
              " use libusb_open for detailed error message.");
    RETVAL = handle;
OUTPUT:
    RETVAL
        

void
DESTROY(LibUSB ctx)
CODE:
    libusb_exit(ctx);


MODULE = LibUSB      PACKAGE = LibUSB::Device       PREFIX = libusb_

unsigned
libusb_get_bus_number(LibUSB::Device dev)

unsigned
libusb_get_port_number(LibUSB::Device dev)

void
libusb_get_port_numbers(LibUSB::Device dev)
PPCODE:
    int len = 20;
    uint8_t port_numbers[len];
    int num = libusb_get_port_numbers(dev, port_numbers, len);
    handle_error(num, "libusb_get_port_numbers");
    int i;
    for (i = 0; i < num; ++i) {
        mXPUSHu(port_numbers[i]);
    }

LibUSB::Device
libusb_get_parent(LibUSB::Device dev)

unsigned
libusb_get_device_address(LibUSB::Device dev)

int
libusb_get_device_speed(LibUSB::Device dev)

int
libusb_get_max_packet_size(LibUSB::Device dev, unsigned char endpoint)
CODE:
    int rv = libusb_get_max_packet_size(dev, endpoint);
    handle_error(rv, "libusb_get_max_packet_size");
    RETVAL = rv;
OUTPUT:
    RETVAL


LibUSB::Device::Handle
libusb_open(LibUSB::Device dev)
CODE:
    libusb_device_handle *handle;
    int rv = libusb_open(dev, &handle);
    handle_error(rv, "libusb_open");
    RETVAL = handle;
OUTPUT:
    RETVAL


void
DESTROY(LibUSB::Device dev)
CODE:
    libusb_unref_device(dev);






MODULE = LibUSB      PACKAGE = LibUSB::Device::Handle       PREFIX = libusb_

void
DESTROY(LibUSB::Device::Handle handle)
CODE:
    libusb_close(handle);