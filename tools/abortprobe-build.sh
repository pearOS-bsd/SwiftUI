cd "$(dirname "$0")" && clang -arch x86_64 -dynamiclib abortprobe.c -o libabortprobe.dylib
