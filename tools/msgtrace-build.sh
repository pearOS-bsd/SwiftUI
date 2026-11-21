cd "$(dirname "$0")" && clang -arch x86_64 -dynamiclib msgtrace.c -framework IOKit -framework CoreFoundation -o libmsgtrace.dylib
