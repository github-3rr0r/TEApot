#ifndef GLOBAL_H
    #define GLOBAL_H
#endif

#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

#define MAX_TRY_TIMES      100000

#define PREPARE() \
    if (argc != 3)\
    {\
        printf("Usage\t: ./poc_* [pagesize] [threshold]\nExample\t: ./poc_x86 4096 200\n");\
        return;\
    }\
    sscanf(argv[1], "%ld", &pagesize);\
    sscanf(argv[2], "%ld", &CACHE_MISS);\
    mem = (char *)malloc(pagesize * 256);\
    memset(mem, 1, pagesize * 256);\
    int passed_count = 0
