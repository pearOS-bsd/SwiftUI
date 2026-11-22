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
static int rcv48;
static mach_msg_return_t pear_mach_msg(mach_msg_header_t *m, mach_msg_option_t o, mach_msg_size_t s, mach_msg_size_t r, mach_port_t rn, mach_msg_timeout_t t, mach_port_t n)
{
	if ((o & MACH_SEND_MSG) && m && m->msgh_id >= 11600 && m->msgh_id < 11700) {	/* the process manager (coreservicesd) MIG: whole message */
		char l[900]; int n = snprintf(l, sizeof l, "CSD-SEND: id %d size %u bits %#x to %u local %u:", m->msgh_id, m->msgh_size, m->msgh_bits, m->msgh_remote_port, m->msgh_local_port);
		for (unsigned i = 24; i < m->msgh_size && i < 200; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && m->msgh_id >= 29000 && m->msgh_id < 36000 && m->msgh_id != 34003) {	/* a frame of 200,200 400x332 (or 200,268) anywhere in a message of the window server protocol: as doubles or floats */
		const unsigned char *b = (const unsigned char *)m; unsigned len = m->msgh_size < 600 ? m->msgh_size : 600; if (len > 4096) len = 600;
		for (unsigned i = 24; i + 8 <= len; i++) { double d; float f; memcpy(&d, b + i, 8); memcpy(&f, b + i, 4);
			if (d == 200.0 || d == 268.0 || d == 332.0 || d == 400.0 || f == 200.0f || f == 268.0f || f == 332.0f || f == 400.0f) { char l[200]; int n = snprintf(l, sizeof l, "FRAMEHIT: id %d at %u: %g / %g\n", m->msgh_id, i, d, (double)f); write(2, l, n); } }
	}
	if ((o & MACH_SEND_MSG) && m && (m->msgh_id == 30263 || m->msgh_id == 30025)) {	/* the out-of-line region of the message */
		const unsigned char *b = (const unsigned char *)m; unsigned long addr; unsigned osz; memcpy(&addr, b + 0x1c, 8); memcpy(&osz, b + 0x28, 4);
		char l[600]; int n = snprintf(l, sizeof l, "WIN-REGION: id %d size %u:", m->msgh_id, osz);
		for (unsigned i = 0; i < osz && i < 128 && addr; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)addr)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && (m->msgh_id == 30263 || m->msgh_id == 30025 || m->msgh_id == 30610)) {	/* window creation: whole message (the shape of the window is in it) */
		char l[1500]; int n = snprintf(l, sizeof l, "WIN-SEND: id %d size %u bits %#x:", m->msgh_id, m->msgh_size, m->msgh_bits);
		for (unsigned i = 24; i < m->msgh_size && i < 260 && n < 1400; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && m->msgh_id >= 10000 && m->msgh_id < 10100) { void *bt[24]; int nb = backtrace(bt, 24); char l[80]; int n = snprintf(l, sizeof l, "BT10K: id %d\n", m->msgh_id); write(2, l, n); backtrace_symbols_fd(bt, nb, 2);
		const unsigned char *b = (const unsigned char *)m; char h[700]; int k = snprintf(h, sizeof h, "IOS-SEND: id %d bits %#x to %u:", m->msgh_id, m->msgh_bits, m->msgh_remote_port); for (unsigned i = 24; i < 120; i++) k += snprintf(h + k, sizeof h - k, " %02x", b[i]); h[k++] = '\n'; write(2, h, k); }
	if ((o & MACH_SEND_MSG) && m && m->msgh_id == 30051) {
		const unsigned char *b = (const unsigned char *)m; char l[2200]; int n = snprintf(l, sizeof l, "SETEV: id 30051 size %u bits %#x:", m->msgh_size, m->msgh_bits);
		for (unsigned i = 24; i < 560 && n < 2100; i++) n += snprintf(l + n, sizeof l - n, " %02x", b[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && m->msgh_id == 30429 && m->msgh_size >= 0x48) {	/* the transaction stream: inline length@0x40, bytes@0x44 (see SkyLight/server/sls_transaction.c) */
		const unsigned char *b = (const unsigned char *)m; unsigned ln = *(const unsigned *)(b + 0x40); char l[1200]; int n = snprintf(l, sizeof l, "TXN: len %u:", ln);
		for (unsigned i = 0; i < ln && i < 300 && n < 1100; i++) n += snprintf(l + n, sizeof l - n, " %02x", b[0x44 + i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_SEND_MSG) && m && m->msgh_id == 30429) { static int nbt; if (nbt++ < 2) { void *bt[40]; int nb = backtrace(bt, 40); write(2, "BT30429:\n", 9); backtrace_symbols_fd(bt, nb, 2); } }
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
	if ((o & MACH_RCV_MSG) && kr == 0 && m && m->msgh_id == 34103 && (m->msgh_bits & MACH_MSGH_BITS_COMPLEX)) {	/* the reply of GetDisplaySystemState (34003): the out-of-line state of the display, first dumped call only */
		static int dss_done; const unsigned char *d = (const unsigned char *)m + sizeof(mach_msg_header_t) + 4; unsigned long addr; unsigned sz; memcpy(&addr, d, 8); memcpy(&sz, d + 12, 4);
		if (!dss_done++) { char hb[60]; snprintf(hb, sizeof hb, "DSS: size %u\n", sz); write(2, hb, strlen(hb));
			for (unsigned i = 0; i < sz && i < 4096; i += 32) { char l[200]; int n = snprintf(l, sizeof l, "DSS: %04x:", i); for (unsigned k = 0; k < 32 && i + k < sz; k++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)addr)[i + k]); l[n++] = 10; write(2, l, n); } }
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m && (m->msgh_id == 30411 || m->msgh_id == 30282 || m->msgh_id == 30425 || m->msgh_id == 30470 || m->msgh_id == 30473 || m->msgh_id == 30545 || m->msgh_id == 30493 || m->msgh_id == 30499)) {	/* replies of the window server around the first order of a window */
		char l[900]; int n = snprintf(l, sizeof l, "SLSREPLY: id %d size %u bits %#x:", m->msgh_id, m->msgh_size, m->msgh_bits);
		for (unsigned i = 24; i < m->msgh_size && i < 160; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m && m->msgh_id >= 11700 && m->msgh_id < 11800) {
		char l[900]; int n = snprintf(l, sizeof l, "CSD-RCV: id %d size %u bits %#x:", m->msgh_id, m->msgh_size, m->msgh_bits);
		for (unsigned i = 24; i < m->msgh_size && i < 200; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m && ((m->msgh_id >= 40300 && m->msgh_id < 40500) || m->msgh_id == 536870912 || m->msgh_id == 0x726d6663 || m->msgh_id == 0x726c6667)) {	/* what the CoreAnimation render server sends to a client after its registration */
		char l[400]; int n = snprintf(l, sizeof l, "CARS: id %d size %u bits %#x:", m->msgh_id, m->msgh_size, m->msgh_bits);
		for (unsigned i = 0; i < m->msgh_size && i < 128; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((unsigned char *)m)[i]);
		l[n++] = '\n'; write(2, l, n);
	}
	if ((o & MACH_RCV_MSG) && kr == 0 && m) { char b[80]; snprintf(b, sizeof b, "RCV: id %d size %u\n", m->msgh_id, m->msgh_size); write(2, b, strlen(b)); if ((m->msgh_id == 0x20000000 && m->msgh_size <= 256) || (m->msgh_id == 0 && m->msgh_size == 48 && memcmp((char *)m + 24, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 24) != 0 && ++rcv48 <= 40)) { char h[1200]; int hn = snprintf(h, sizeof h, "RCVNOTE:"); for (unsigned q = 0; q < m->msgh_size; q++) hn += snprintf(h + hn, sizeof h - hn, " %02x", ((unsigned char *)m)[q]); h[hn++] = 10; write(2, h, hn); } }
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
	if ((strstr(d, "_CodableBody") || strstr(d, "\"command\""))) { write(2, "XPCSEND: ", 9); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_connection_send_message_with_reply(c, m, q, ^(xpc_object_t r) {
		char *rd = xpc_copy_description(r);
		if ((strstr(rd, "_CodableBody") || strstr(rd, "\"success\"") || strstr(rd, "\"result\""))) { write(2, "XPCREPLY: ", 10); write(2, rd, strlen(rd)); write(2, "\n", 1); }
		free(rd);
		if (h) h(r);
	});
}
static void pear_xpc_send(xpc_connection_t c, xpc_object_t m)
{
	char *d = xpc_copy_description(m);
	if ((strstr(d, "_CodableBody") || strstr(d, "\"command\""))) { write(2, "XPCSEND1: ", 10); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_connection_send_message(c, m);
}
static xpc_object_t pear_xpc_send_sync(xpc_connection_t c, xpc_object_t m)
{
	char *d = xpc_copy_description(m);
	if ((strstr(d, "_CodableBody") || strstr(d, "\"command\""))) { write(2, "XPCSENDSYNC: ", 13); write(2, d, strlen(d)); write(2, "\n", 1); }
	free(d);
	xpc_object_t r = xpc_connection_send_message_with_reply_sync(c, m);
	char *rd = xpc_copy_description(r);
	if ((strstr(rd, "_CodableBody") || strstr(rd, "\"success\"") || strstr(rd, "\"result\""))) { write(2, "XPCSYNCREPLY: ", 14); write(2, rd, strlen(rd)); write(2, "\n", 1); }
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
#include <IOKit/IOKitLib.h>
/* IOKit user client calls: which service, which selector, how many bytes */
static kern_return_t pear_IOServiceOpen(io_service_t service, task_port_t owner, uint32_t type, io_connect_t *conn)
{
	io_name_t nm = ""; char l[300]; kern_return_t kr;
	IOObjectGetClass(service, nm);
	kr = IOServiceOpen(service, owner, type, conn);
	{ int n = snprintf(l, sizeof l, "IOK: IOServiceOpen class %s type %u -> kr %#x conn %u\n", nm, type, kr, conn ? *conn : 0); write(2, l, n); }
	return kr;
}
static kern_return_t pear_IOConnectCallMethod(mach_port_t c, uint32_t sel, const uint64_t *in, uint32_t inc, const void *ins, size_t insz, uint64_t *out, uint32_t *outc, void *outs, size_t *outsz)
{
	char l[2400]; int n = snprintf(l, sizeof l, "IOK: CallMethod conn %u selector %u scalars %u:", c, sel, inc);
	for (uint32_t i = 0; i < inc && i < 8; i++) n += snprintf(l + n, sizeof l - n, " %llx", (unsigned long long)in[i]);
	n += snprintf(l + n, sizeof l - n, " | struct in %zu:", insz); for (size_t i = 0; i < insz && i < 220 && ins; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((const unsigned char *)ins)[i]);
	kern_return_t kr = IOConnectCallMethod(c, sel, in, inc, ins, insz, out, outc, outs, outsz);
	n += snprintf(l + n, sizeof l - n, " => kr %#x out scalars %u:", kr, outc ? *outc : 0);
	for (uint32_t i = 0; outc && out && i < *outc && i < 8; i++) n += snprintf(l + n, sizeof l - n, " %llx", (unsigned long long)out[i]);
	n += snprintf(l + n, sizeof l - n, " struct out %zu:", outsz ? *outsz : 0); for (size_t i = 0; outsz && outs && i < *outsz && i < 420; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((const unsigned char *)outs)[i]);
	l[n++] = '\n'; write(2, l, n);
	return kr;
}
static kern_return_t pear_IOConnectCallScalarMethod(mach_port_t c, uint32_t sel, const uint64_t *in, uint32_t inc, uint64_t *out, uint32_t *outc)
{
	kern_return_t kr = IOConnectCallScalarMethod(c, sel, in, inc, out, outc); char l[400]; int n = snprintf(l, sizeof l, "IOK: CallScalarMethod conn %u selector %u in %u:", c, sel, inc);
	for (uint32_t i = 0; i < inc && i < 8; i++) n += snprintf(l + n, sizeof l - n, " %llx", (unsigned long long)in[i]);
	n += snprintf(l + n, sizeof l - n, " => kr %#x out %u:", kr, outc ? *outc : 0); for (uint32_t i = 0; outc && out && i < *outc && i < 8; i++) n += snprintf(l + n, sizeof l - n, " %llx", (unsigned long long)out[i]);
	l[n++] = '\n'; write(2, l, n); return kr;
}
static kern_return_t pear_IOConnectCallStructMethod(mach_port_t c, uint32_t sel, const void *ins, size_t insz, void *outs, size_t *outsz)
{
	kern_return_t kr = IOConnectCallStructMethod(c, sel, ins, insz, outs, outsz); char l[1200]; int n = snprintf(l, sizeof l, "IOK: CallStructMethod conn %u selector %u in %zu:", c, sel, insz);
	for (size_t i = 0; i < insz && i < 64 && ins; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((const unsigned char *)ins)[i]);
	n += snprintf(l + n, sizeof l - n, " => kr %#x out %zu:", kr, outsz ? *outsz : 0); for (size_t i = 0; outsz && outs && i < *outsz && i < 64; i++) n += snprintf(l + n, sizeof l - n, " %02x", ((const unsigned char *)outs)[i]);
	l[n++] = '\n'; write(2, l, n); return kr;
}
extern kern_return_t IOConnectTrap6(io_connect_t, uint32_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t);
static kern_return_t pear_IOConnectTrap6(io_connect_t c, uint32_t idx, uintptr_t a, uintptr_t b, uintptr_t d, uintptr_t e, uintptr_t f, uintptr_t g)
{
	kern_return_t kr = IOConnectTrap6(c, idx, a, b, d, e, f, g); char l[300]; int n = snprintf(l, sizeof l, "IOK: Trap6 conn %u index %u args %lx %lx %lx %lx %lx %lx => kr %#x\n", c, idx, a, b, d, e, f, g, kr); write(2, l, n); return kr;
}
static kern_return_t pear_IOConnectMapMemory64(io_connect_t c, uint32_t memtype, task_port_t task, mach_vm_address_t *addr, mach_vm_size_t *size, IOOptionBits opt)
{
	kern_return_t kr = IOConnectMapMemory64(c, memtype, task, addr, size, opt); char l[200]; int n = snprintf(l, sizeof l, "IOK: MapMemory conn %u type %u opt %#x -> kr %#x size %llu\n", c, memtype, opt, kr, size ? (unsigned long long)*size : 0); write(2, l, n); return kr;
}

/* what the program listens to: SLSRegisterNotifyProc / SLSRegisterConnectionNotifyProc (SkyLight notifications: AppKit asks for the occlusion and order ones).  The procedure is replaced by one of 64 trampolines that
 * log the notification (type, length, first bytes of the data) and call the real one. */
typedef void (*note_proc_t)(uint32_t type, void *data, uint32_t len, void *ctx, int cid);
extern int SLSRegisterNotifyProc(void *proc, uint32_t type, void *ctx);
extern int SLSRegisterConnectionNotifyProc(int cid, void *proc, uint32_t type, void *ctx);
#define NTR 64
static struct { note_proc_t real; uint32_t type; } ntr[NTR];
static int nntr;
static void note_log(int i, uint32_t type, void *data, uint32_t len, int cid)
{
	char h[600]; int n = snprintf(h, sizeof h, "SLSNOTE: type %u (registered as %u) len %u cid %d data", type, ntr[i].type, len, cid);
	for (uint32_t q = 0; data && q < len && q < 64; q++) n += snprintf(h + n, sizeof h - n, " %02x", ((unsigned char *)data)[q]);
	h[n++] = 10; write(2, h, n);
}
#define TR(i) static void ntramp##i(uint32_t t, void *d, uint32_t l, void *c, int cid) { note_log(i, t, d, l, cid); ntr[i].real(t, d, l, c, cid); }
#define TR8(i) TR(i##0) TR(i##1) TR(i##2) TR(i##3) TR(i##4) TR(i##5) TR(i##6) TR(i##7)
TR8(0) TR8(1) TR8(2) TR8(3) TR8(4) TR8(5) TR8(6)
TR(70) TR(71) TR(72) TR(73) TR(74) TR(75) TR(76) TR(77)
static note_proc_t ntramps[NTR] = {
#define E(i) ntramp##i,
#define E8(i) E(i##0) E(i##1) E(i##2) E(i##3) E(i##4) E(i##5) E(i##6) E(i##7)
	E8(0) E8(1) E8(2) E8(3) E8(4) E8(5) E8(6) E(70) E(71) E(72) E(73) E(74) E(75) E(76) E(77)
};
static note_proc_t note_wrap(void *proc, uint32_t type)
{
	if (nntr >= NTR) return (note_proc_t)proc;
	ntr[nntr].real = (note_proc_t)proc; ntr[nntr].type = type;
	return ntramps[nntr++];
}
static int pear_SLSRegisterNotifyProc(void *proc, uint32_t type, void *ctx) { char b[120]; int n = snprintf(b, sizeof b, "SLSNOTIFY: RegisterNotifyProc type %u proc %p\n", type, proc); write(2, b, n); return SLSRegisterNotifyProc((void *)note_wrap(proc, type), type, ctx); }
static int pear_SLSRegisterConnectionNotifyProc(int cid, void *proc, uint32_t type, void *ctx) { char b[120]; int n = snprintf(b, sizeof b, "SLSNOTIFY: RegisterConnectionNotifyProc cid %d type %u proc %p\n", cid, type, proc); write(2, b, n); return SLSRegisterConnectionNotifyProc(cid, (void *)note_wrap(proc, type), type, ctx); }

/* display links: CVDisplayLinkStart / CreateWithActiveCGDisplays (what drives the update cycle of AppKit) */
extern int CVDisplayLinkStart(void *l);
extern int CVDisplayLinkCreateWithActiveCGDisplays(void **l);
extern int CVDisplayLinkCreateWithCGDisplay(uint32_t d, void **l);
static int pear_CVDisplayLinkStart(void *l) { char b[100]; int n = snprintf(b, sizeof b, "CVDL: CVDisplayLinkStart %p\n", l); write(2, b, n); return CVDisplayLinkStart(l); }
static int pear_CVDisplayLinkCreateWithActiveCGDisplays(void **l) { int r = CVDisplayLinkCreateWithActiveCGDisplays(l); char b[100]; int n = snprintf(b, sizeof b, "CVDL: CreateWithActiveCGDisplays -> %d\n", r); write(2, b, n); return r; }
static int pear_CVDisplayLinkCreateWithCGDisplay(uint32_t d, void **l) { int r = CVDisplayLinkCreateWithCGDisplay(d, l); char b[100]; int n = snprintf(b, sizeof b, "CVDL: CreateWithCGDisplay %u -> %d\n", d, r); write(2, b, n); return r; }

__attribute__((used)) static const ip_t ip[] __attribute__((section("__DATA,__interpose"))) = { { (const void *)pear_mach_msg, (const void *)mach_msg },  { (const void *)pear_CVDisplayLinkStart, (const void *)CVDisplayLinkStart }, { (const void *)pear_CVDisplayLinkCreateWithActiveCGDisplays, (const void *)CVDisplayLinkCreateWithActiveCGDisplays }, { (const void *)pear_CVDisplayLinkCreateWithCGDisplay, (const void *)CVDisplayLinkCreateWithCGDisplay }, { (const void *)pear_SLSRegisterNotifyProc, (const void *)SLSRegisterNotifyProc }, { (const void *)pear_SLSRegisterConnectionNotifyProc, (const void *)SLSRegisterConnectionNotifyProc }, { (const void *)pear_IOServiceOpen, (const void *)IOServiceOpen }, { (const void *)pear_IOConnectCallMethod, (const void *)IOConnectCallMethod }, { (const void *)pear_IOConnectMapMemory64, (const void *)IOConnectMapMemory64 }, { (const void *)pear_IOConnectCallScalarMethod, (const void *)IOConnectCallScalarMethod }, { (const void *)pear_IOConnectCallStructMethod, (const void *)IOConnectCallStructMethod }, { (const void *)pear_IOConnectTrap6, (const void *)IOConnectTrap6 }, { (const void *)pear_get_msg, (const void *)dispatch_mach_msg_get_msg }, { (const void *)pear_look_up, (const void *)bootstrap_look_up }, { (const void *)pear_look_up3, (const void *)bootstrap_look_up3 }, { (const void *)pear_xpc, (const void *)xpc_connection_create_mach_service }, { (const void *)pear_xpc_send_reply, (const void *)xpc_connection_send_message_with_reply }, { (const void *)pear_xpc_send, (const void *)xpc_connection_send_message }, { (const void *)pear_xpc_send_sync, (const void *)xpc_connection_send_message_with_reply_sync } };
