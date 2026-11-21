/* msgtrace: measuring tool.  Interposes mach_msg: prints the id of every message that the program sends ("MSG: id N size S"), in order.  Run a program on a Mac with
 * DYLD_INSERT_LIBRARIES=./libmsgtrace.dylib and compare the SkyLight requests (30000..34000) with what the same program does on pearOS. */
#include <mach/mach.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
static mach_msg_return_t pear_mach_msg(mach_msg_header_t *m, mach_msg_option_t o, mach_msg_size_t s, mach_msg_size_t r, mach_port_t rn, mach_msg_timeout_t t, mach_port_t n)
{
	if ((o & MACH_SEND_MSG) && m) { char b[80]; snprintf(b, sizeof b, "MSG: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); }
	mach_msg_return_t kr = mach_msg(m, o, s, r, rn, t, n);
	if ((o & MACH_RCV_MSG) && kr == 0 && m) { char b[80]; snprintf(b, sizeof b, "RCV: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); }
	return kr;
}
typedef struct { const void *r; const void *o; } ip_t;
__attribute__((used)) static const ip_t ip[] __attribute__((section("__DATA,__interpose"))) = { { (const void *)pear_mach_msg, (const void *)mach_msg } };
