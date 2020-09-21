#include "cache.h"

void main()
{
    pagesize = sysconf(_SC_PAGESIZE);
    printf("%ld", pagesize);
}