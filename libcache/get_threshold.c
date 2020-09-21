#include "cache.h"

void main()
{   
    CACHE_MISS = detect_flush_reload_threshold();
    printf("%ld", CACHE_MISS);
}