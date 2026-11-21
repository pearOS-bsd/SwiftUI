#include <execinfo.h>
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
	if ((o & MACH_SEND_MSG) && m && (m->msgh_id == 40209 || m->msgh_id == 40004 || m->msgh_id == 40005)) { void *bt[24]; int nb = backtrace(bt, 24); write(2, "BT:\n", 4); backtrace_symbols_fd(bt, nb, 2); }
	if ((o & MACH_SEND_MSG) && m && m->msgh_id >= 40000 && m->msgh_id < 40500) {	/* every CoreAnimation render server message the program sends, whole (up to 192 bytes) */
		char l[900]; int n = snprintf(l, sizeof l, "CASEND: id %d size %u bits %#x to %u local %u:", m->msgh_id, m->msgh_size, m->msgh_bits, m->msgh_remote_port, m->msgh_local_port);
		for (unsigned i = 24; i < m->msgh_size && i < 192; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && m->msgh_id == 40202 && (m->msgh_bits & MACH_MSGH_BITS_COMPLEX)) {	/* CASRegisterClient: which of the five ports is the client's own (the one the server writes its notifications to) */
		const unsigned *w = (const unsigned *)m; unsigned cnt = w[6]; char l[300]; int n = snprintf(l, sizeof l, "CAREG: remote %u local %u ports:", m->msgh_remote_port, m->msgh_local_port);
		for (unsigned i = 0; i < cnt && i < 8; i++) n += snprintf(l + n, sizeof l - n, " %u(disp %u)", w[7 + 3 * i], (w[9 + 3 * i] >> 16) & 0xff);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m) { char b[80]; snprintf(b, sizeof b, "MSG: id %d size %u to %u\n", m->msgh_id, m->msgh_size, m->msgh_remote_port); write(2, b, strlen(b)); }
	mach_msg_return_t kr = mach_msg(m, o, s, r, rn, t, n);
	if ((o & MACH_RCV_MSG) && kr == 0 && m && m->msgh_id == 30217 && (m->msgh_bits & MACH_MSGH_BITS_COMPLEX)) {	/* the reply of GetPortStreamOutofline: out-of-line bytes = the events of the window server */
		const unsigned char *d = (const unsigned char *)m + sizeof(mach_msg_header_t) + 4;	/* body (descriptor count), then the descriptor: address, then size at +12 */
		unsigned long addr; unsigned sz; char hb[40];
		memcpy(&addr, d, 8); memcpy(&sz, d + 12, 4);
		snprintf(hb, sizeof hb, "EVENTS: size %u\n", sz); write(2, hb, strlen(hb));
		for (unsigned i = 0; i < sz && i < 512; i += 16) { char l[120]; int n = snprintf(l, sizeof l, "EVENTS: %04x:", i); for (unsigned k = 0; k < 16 && i + k < sz; k++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)addr)[i + k]); l[n++] = '\n'; write(2, l, n); }
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m && ((m->msgh_id >= 40300 && m->msgh_id < 40500) || m->msgh_id == 536870912 || m->msgh_id == 0x726d6663 || m->msgh_id == 0x726c6667)) {	/* what the CoreAnimation render server sends to a client after its registration */
		char l[400]; int n = snprintf(l, sizeof l, "CARS: id %d size %u bits %#x:", m->msgh_id, m->msgh_size, m->msgh_bits);
		for (unsigned i = 0; i < m->msgh_size && i < 128; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m) { char b[80]; snprintf(b, sizeof b, "RCV: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); }
	return kr;
}
static void say2(const char *a, const char *b) { char l[300]; snprintf(l, sizeof l, "%s %s\n", a, b ? b : "(null)"); write(2, l, strlen(l)); }
static kern_return_t pear_look_up(mach_port_t bp, const char *name, mach_port_t *sp) { kern_return_t kr = bootstrap_look_up(bp, name, sp); char l[200]; snprintf(l, sizeof l, "LOOKUP: %s -> port %u\n", name, sp ? *sp : 0); write(2, l, strlen(l)); return kr; }
extern kern_return_t bootstrap_look_up3(mach_port_t, const char *, mach_port_t *, pid_t, uint64_t);
static kern_return_t pear_look_up3(mach_port_t bp, const char *name, mach_port_t *sp, pid_t pid, uint64_t flags) { kern_return_t kr = bootstrap_look_up3(bp, name, sp, pid, flags); char l[200]; snprintf(l, sizeof l, "LOOKUP3: %s -> port %u\n", name, sp ? *sp : 0); write(2, l, strlen(l)); return kr; }
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
/* the messages that libdispatch hands to a dispatch_mach handler (the fence observer of QuartzCore gets 'cfmr' / 'gflr' this way: the receive is inside libdispatch, mach_msg is not seen) */
extern void *dispatch_mach_msg_get_msg(void *dmsg, unsigned long *size);
static void *
pear_get_msg(void *dmsg, unsigned long *size)
{
	void *m = dispatch_mach_msg_get_msg(dmsg, size);

	if (m != NULL) {
		const unsigned *w = (const unsigned *)m;

		if (w[5] == 0x726d6663 || w[5] == 0x726c6667) {
			char l[700]; int n = snprintf(l, sizeof l, "FENCEMSG: id %#x size %u:", w[5], w[1]);
			unsigned long addr = 0; unsigned osz = 0, i;
			memcpy(&addr, &w[7], 8); osz = w[10];
			for (i = 0; i < w[1] && i < 96; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((const unsigned char *)m)[i]);
			n += snprintf(l + n, sizeof l - n, " | names:");
			for (i = 0; i + 8 <= osz && i < 64 && addr; i += 8) { unsigned long long v; memcpy(&v, (void *)(addr + i), 8); n += snprintf(l + n, sizeof l - n, " %llx", v); }
			l[n++] = '\n'; write(2, l, n);
		}
	}
	return m;
}
__attribute__((used)) static const ip_t ip[] __attribute__((section("__DATA,__interpose"))) = { { (const void *)pear_mach_msg, (const void *)mach_msg }, { (const void *)pear_get_msg, (const void *)dispatch_mach_msg_get_msg }, { (const void *)pear_look_up, (const void *)bootstrap_look_up }, { (const void *)pear_look_up3, (const void *)bootstrap_look_up3 }, { (const void *)pear_xpc, (const void *)xpc_connection_create_mach_service }, { (const void *)pear_xpc_send_reply, (const void *)xpc_connection_send_message_with_reply }, { (const void *)pear_xpc_send, (const void *)xpc_connection_send_message }, { (const void *)pear_xpc_send_sync, (const void *)xpc_connection_send_message_with_reply_sync } };
