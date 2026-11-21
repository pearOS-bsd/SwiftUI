/* IOSurface from a plain program: create, map, fill, look up by id.  The IOKit calls it makes are the ones that the window server has to
 * serve for the layers of an AppKit program (their contents are IOSurfaces).  Build on a Mac: clang iosurf.c -framework IOSurface -framework CoreFoundation -o iosurf */
#include <IOSurface/IOSurface.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

static void put(CFMutableDictionaryRef d, CFStringRef k, int v)
{
	CFNumberRef n = CFNumberCreate(NULL, kCFNumberIntType, &v);
	CFDictionarySetValue(d, k, n); CFRelease(n);
}

int
main(int argc, char **argv)
{
	int W = argc > 1 ? atoi(argv[1]) : 64, H = argc > 2 ? atoi(argv[2]) : 48, B = argc > 3 ? atoi(argv[3]) : 4;
	CFMutableDictionaryRef p = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	IOSurfaceRef s, t;
	IOSurfaceID id;
	unsigned char *px;
	int i;

	put(p, kIOSurfaceWidth, W); put(p, kIOSurfaceHeight, H); put(p, kIOSurfaceBytesPerElement, B); put(p, kIOSurfacePixelFormat, 'BGRA');
	fprintf(stderr, "iosurf: creating\n");
	s = IOSurfaceCreate(p);
	if (!s) { fprintf(stderr, "iosurf: IOSurfaceCreate failed\n"); return 1; }
	id = IOSurfaceGetID(s);
	fprintf(stderr, "iosurf: id %u, %zux%zu, row %zu, alloc %zu, base %p\n", id, IOSurfaceGetWidth(s), IOSurfaceGetHeight(s), IOSurfaceGetBytesPerRow(s), IOSurfaceGetAllocSize(s), IOSurfaceGetBaseAddress(s));
	if (IOSurfaceLock(s, 0, NULL)) { fprintf(stderr, "iosurf: lock failed\n"); return 2; }
	px = IOSurfaceGetBaseAddress(s);
	for (i = 0; i < W * H; i++) { px[i * 4] = 0xff; px[i * 4 + 1] = 0; px[i * 4 + 2] = 0; px[i * 4 + 3] = 0xff; }
	IOSurfaceUnlock(s, 0, NULL);
	t = IOSurfaceLookup(id);
	fprintf(stderr, "iosurf: lookup %u -> %p (%s), first pixel %02x%02x%02x%02x\n", id, t, t ? "found" : "NOT found", t ? ((unsigned char *)IOSurfaceGetBaseAddress(t))[0] : 0, t ? ((unsigned char *)IOSurfaceGetBaseAddress(t))[1] : 0, t ? ((unsigned char *)IOSurfaceGetBaseAddress(t))[2] : 0, t ? ((unsigned char *)IOSurfaceGetBaseAddress(t))[3] : 0);
	sleep(2);
	return 0;
}
