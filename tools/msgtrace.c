/* msgtrace: measuring tool.  Interposes mach_msg: prints the id of every message that the program sends ("MSG: id N size S"), in order.  Run a program on a Mac with
 * DYLD_INSERT_LIBRARIES=./libmsgtrace.dylib and compare the SkyLight requests (30000..34000) with what the same program does on pearOS. */
#include <mach/mach.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <servers/bootstrap.h>
#include <xpc/xpc.h>
static mach_msg_return_t pear_mach_msg(mach_msg_header_t *m, mach_msg_option_t o, mach_msg_size_t s, mach_msg_size_t r, mach_port_t rn, mach_msg_timeout_t t, mach_port_t n)
{
	if ((o & MACH_SEND_MSG) && m) { char b[80]; snprintf(b, sizeof b, "MSG: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); }
	mach_msg_return_t kr = mach_msg(m, o, s, r, rn, t, n);
	if ((o & MACH_RCV_MSG) && kr == 0 && m) { char b[80]; snprintf(b, sizeof b, "RCV: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); }
	return kr;
}
static void say2(const char *a, const char *b) { char l[300]; snprintf(l, sizeof l, "%s %s\n", a, b ? b : "(null)"); write(2, l, strlen(l)); }
static kern_return_t pear_look_up(mach_port_t bp, const char *name, mach_port_t *sp) { say2("LOOKUP:", name); return bootstrap_look_up(bp, name, sp); }
static xpc_connection_t pear_xpc(const char *name, dispatch_queue_t q, uint64_t flags) { say2("XPCSERVICE:", name); return xpc_connection_create_mach_service(name, q, flags); }
static void pear_xpc_send_reply(xpc_connection_t c, xpc_object_t m, dispatch_queue_t q, xpc_handler_t h)
{
	char *d = xpc_copy_description(m);
	if (strstr(d, "_CodableBody")) { write(2, "XPCSEND: ", 9); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_connection_send_message_with_reply(c, m, q, ^(xpc_object_t r) {
		char *rd = xpc_copy_description(r);
		if (strstr(rd, "_CodableBody")) { write(2, "XPCREPLY: ", 10); write(2, rd, strlen(rd)); write(2, "\n", 1); }
		free(rd);
		if (h) h(r);
	});
}
static void pear_xpc_send(xpc_connection_t c, xpc_object_t m)
{
	char *d = xpc_copy_description(m);
	if (strstr(d, "_CodableBody")) { write(2, "XPCSEND1: ", 10); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_connection_send_message(c, m);
}
static xpc_object_t pear_xpc_send_sync(xpc_connection_t c, xpc_object_t m)
{
	char *d = xpc_copy_description(m);
	if (strstr(d, "_CodableBody")) { write(2, "XPCSENDSYNC: ", 13); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_object_t r = xpc_connection_send_message_with_reply_sync(c, m);
	char *rd = xpc_copy_description(r);
	if (strstr(rd, "_CodableBody")) { write(2, "XPCSYNCREPLY: ", 14); write(2, rd, strlen(rd)); write(2, "\n", 1); }
	free(rd);
	return r;
}
typedef struct { const void *r; const void *o; } ip_t;
__attribute__((used)) static const ip_t ip[] __attribute__((section("__DATA,__interpose"))) = { { (const void *)pear_mach_msg, (const void *)mach_msg }, { (const void *)pear_look_up, (const void *)bootstrap_look_up }, { (const void *)pear_xpc, (const void *)xpc_connection_create_mach_service }, { (const void *)pear_xpc_send_reply, (const void *)xpc_connection_send_message_with_reply }, { (const void *)pear_xpc_send, (const void *)xpc_connection_send_message }, { (const void *)pear_xpc_send_sync, (const void *)xpc_connection_send_message_with_reply_sync } };
