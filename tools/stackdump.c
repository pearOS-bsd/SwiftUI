/* DYLD_INSERT_LIBRARIES=stackdump.dylib: after STACKDUMP_AFTER seconds (default 30) every thread of the process (up to 64) gets SIGUSR2 and prints its own call stack to stderr: where is the program waiting (the main thread of a program that never commits, for example).  Built on the Mac: clang -dynamiclib -o stackdump.dylib stackdump.c */
#include <execinfo.h>
#include <mach/mach.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void on_usr2(int sig)
{
	void *bt[48]; char b[96]; int n = backtrace(bt, 48);
	int k = snprintf(b, sizeof b, "STACKDUMP thread %#x:\n", (unsigned)mach_thread_self()); write(2, b, k);
	backtrace_symbols_fd(bt, n, 2);
}

static void *watcher(void *arg)
{
	int secs = getenv("STACKDUMP_AFTER") ? atoi(getenv("STACKDUMP_AFTER")) : 30;
	sleep(secs);
	thread_act_array_t th; mach_msg_type_number_t n = 0;
	if (task_threads(mach_task_self(), &th, &n) != KERN_SUCCESS) return NULL;
	for (mach_msg_type_number_t i = 0; i < n && i < 64; i++) {
		if (th[i] == mach_thread_self()) continue;
		/* the thread's pthread: through its mach port */
		pthread_t pt = pthread_from_mach_thread_np(th[i]);
		if (pt) { pthread_kill(pt, SIGUSR2); usleep(150000); }
	}
	return NULL;
}

__attribute__((constructor)) static void init(void)
{
	signal(SIGUSR2, on_usr2);
	pthread_t t; pthread_create(&t, NULL, watcher, NULL); pthread_detach(t);
}
