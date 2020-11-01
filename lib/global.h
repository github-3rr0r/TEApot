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

#define POC_ERROR          -1


#define PREPARE() \
    if (argc != 3)\
    {\
        printf("Usage\t: ./poc [pagesize] [threshold]\nExample\t: ./poc 4096 200\n");\
        exit(-1);\
    }\
    sscanf(argv[1], "%ld", &pagesize);\
    sscanf(argv[2], "%ld", &CACHE_MISS);\
    char *_mem = (char *)malloc(pagesize * (256 + 4));\
    mem = (char *)(((size_t)_mem & ~(pagesize-1)) + pagesize * 2);\
    memset(mem, 1, pagesize * 256);\
    int passed_count = 0
