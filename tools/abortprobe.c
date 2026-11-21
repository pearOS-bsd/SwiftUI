/* abortprobe: measuring tool.  Interposes abort(): prints the return addresses of the real frame-pointer chain of the calling thread (hex, one per line, "ABORT: frame N 0x...")
 * and then calls the original.  The addresses are symbolised offline (the dyld cache is mapped at a slide: see SwiftUI/docs/EVIDENCE.md).  Add it to a program as a dependency with
 * Metal/tools/trace-device/add-dylib.py.  Build on a Mac: sh abortprobe-build.sh */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <execinfo.h>
#include <stdarg.h>
static int nva;
static int pear_vasprintf(char **out, const char *fmt, va_list ap)	/* AttributeGraph formats its precondition message with vasprintf: print what it formats */
{
	va_list ap2;
	int r;

	va_copy(ap2, ap);
	r = vasprintf(out, fmt, ap);
	if (r > 0 && *out != NULL && nva++ < 40) { write(2, "VASPRINTF: ", 11); write(2, *out, strlen(*out) > 400 ? 400 : strlen(*out)); write(2, "\n", 1); }
	va_end(ap2);
	return r;
}
static void pear_abort(void)
{
	void **fp = (void **)__builtin_frame_address(0), **fp0 = fp;
	char b[64];
	int i;

	write(2, "ABORT: abort() called\n", 22);
	{ void *bt[40]; int nb = backtrace(bt, 40); write(2, "ABORT: backtrace()\n", 19); backtrace_symbols_fd(bt, nb, 2); }
	for (i = 0; i < 48 && fp != NULL && ((unsigned long)fp & 7) == 0 && (unsigned long)fp > 0x10000; i++) {
		snprintf(b, sizeof b, "ABORT: frame %d %p\n", i, fp[1]);
		write(2, b, strlen(b));
		if (fp[0] <= (void *)fp) break;
		fp = (void **)fp[0];
	}
	{	/* the message that the caller formatted into a buffer on its stack: printable runs of 16+ bytes in the 4 KB above this frame */
		unsigned char *q = (unsigned char *)fp0, *end = q + 40960;

		while (q < end) {
			unsigned char *r = q;

			while (r < end && *r >= 32 && *r < 127) r++;
			if (r - q >= 10) { write(2, "ABORT: text: ", 13); write(2, q, (size_t)(r - q)); write(2, "\n", 1); }
			q = r + 1;
		}
	}
	if (getenv("PEAR_ABORT_RETURNS")) { write(2, "ABORT: returning instead (PEAR_ABORT_RETURNS)\n", 46); return; }	/* an experiment: what happens when the failure is treated as non fatal */
	abort();
}
typedef struct { const void *r; const void *o; } ip_t;
__attribute__((used)) static const ip_t ip[] __attribute__((section("__DATA,__interpose"))) = { { (const void *)pear_abort, (const void *)abort }, { (const void *)pear_vasprintf, (const void *)vasprintf } };
