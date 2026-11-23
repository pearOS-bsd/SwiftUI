/* DYLD_INSERT_LIBRARIES=msglog.dylib (on the Mac): the Objective-C runtime logs every message send that misses the method cache to /tmp/msgSends-<pid> from MSGLOG_FROM to MSGLOG_TO seconds after start (default 0..25).  On pearOS the same log is switched on by the Metal driver (PEAR_METAL_MSGLOG=1) because DYLD_INSERT_LIBRARIES is unusable there.  Built: clang -dynamiclib -undefined dynamic_lookup -o msglog.dylib msglog.c */
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
extern void instrumentObjcMessageSends(int);
static void *run(void *a) { int f = getenv("MSGLOG_FROM") ? atoi(getenv("MSGLOG_FROM")) : 0, t = getenv("MSGLOG_TO") ? atoi(getenv("MSGLOG_TO")) : 25; sleep(f); instrumentObjcMessageSends(1); sleep(t - f); instrumentObjcMessageSends(0); return 0; }
__attribute__((constructor)) static void init(void) { pthread_t th; pthread_create(&th, 0, run, 0); pthread_detach(th); }
