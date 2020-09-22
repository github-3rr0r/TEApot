#ifndef CACHE_H
#define CACHE_H
#endif

#include <stdint.h> // uint64_t等价于unsigned long long
#include <stdio.h>  // 输入输出
#include <stdlib.h> // malloc函数
#include <string.h> // memset函数
#include <signal.h> // 用于信号处理
#include <setjmp.h> // 配合信号实现异常处理
#include <unistd.h> // _SC_PAGESIZE的定义

// User configuration
#define USE_RDTSCP 1 // 默认处理器支持rdtscp指令
static size_t CACHE_MISS = 0;
jmp_buf trycatch_buf;
static size_t pagesize = 0;
char *mem;

// 1. x86-64
#if defined(__x86_64__)
uint64_t rdtsc();
void flush(void *p);
void maccess(void *p);
void mfence();
void nospec();
#include <cpuid.h> // __get_cpuid_max()函数和__cpuid_count函数，仅支持x86-64和x86
unsigned int xbegin();
void xend();
int has_tsx();
void maccess_tsx(void *ptr);
// 2. x86
#elif defined(__i386__)
uint32_t rdtsc();
void flush(void *p);
void maccess(void *p);
void mfence();
void nospec();
#include <cpuid.h>
int has_tsx();
// 3. arm 64
#elif defined(__aarch64__)
// arm处理器获取时间的方式有三种
// ARM_PERF、ARM_CLOCK_MONOTONIC和ARM_TIMER
// 其中PERF_COUNT_HW_CPU_CYCLES很多处理器已经不支持
// TIMER在用户态也没有权限访问
// 所以只能用monotonic方式，返回开机到现在的时间
// 如果使用monotonic方式则需要使用头文件time.h
#include <time.h>
uint64_t rdtsc();
void flush(void *p);
void maccess(void *p);
void mfence();
void nospec();
#endif

int flush_reload_t(void *ptr);
int flush_reload(void *ptr);
int reload_t(void *ptr);
size_t detect_flush_reload_threshold();

void unblock_signal(int signum __attribute__((__unused__)));
void trycatch_segfault_handler(int signum);
int try_start();
void try_end();
void try_abort();

void cache_encode(char data);
char cache_decode();
void cache_decode_array(char *leaked, int index);
void flush_shared_memory();

// *****需要根据硬件平台来确定相应的汇编指令序列*****
// 关于预定义编译器宏：https://sourceforge.net/p/predef/wiki/Architectures/
// 1. x86-64
#if defined(__x86_64__)

// 用于获取当前的tsc寄存器的值
// TSC是Time Stamp Counter寄存器，每个时钟周期加一，可用于计时
uint64_t rdtsc()
{
    uint64_t result;
    // 串行化之前的读写操作，同步作用
    asm volatile("mfence");
// 这里有两种方式获取时间
// 一个是rdtscp，可以保证周围的指令不会重排序，但是只有比较新的处理器才支持
// 一个是rdtsc，不能保证指令序列化，但是前面调用了mfence所以也能按照预期执行
// rdtsc是一条读取TSC的指令，对于64位的处理器，该指令可以将64位TSC的值放入寄存器
#if USE_RDTSCP
    asm volatile("rdtscp"
                 : "=A"(result)::"rcx");
#else
    asm volatile("rdtsc"
                 : "=A"(result));
#endif
    // 同步
    asm volatile("mfence");
    return result;
}

// flush指定地址的缓存
void flush(void *p)
{
    // clflush可以使包含源操作数指定的线性地址的缓存线失效（cacheline flush）
    asm volatile("clflush 0(%0)\n"
                 :
                 : "c"(p)
                 : "rax");
}

// 访问内存的某地址，从而将内存中的数据加载到cache中
void maccess(void *p)
{
    // 此处使用movq指令将指定地址的数据存放到rax中，从而达成目的
    asm volatile("movq (%0), %%rax\n"
                 :
                 : "c"(p)
                 : "rax");
}

// mfence指令的包装，确保串行化之前的读写操作，同步作用
void mfence()
{
    asm volatile("mfence" ::
                     :);
}

// lfence指令的包装，防止推测执行
void nospec()
{
    asm volatile("lfence" ::
                     :);
}

// 下面的部分是关于TSX的
// 参考https://blog.csdn.net/jqwang1992/article/details/53377302
/*  TSX(Transactional Synchronization Extensions)是x86指令集体系结构的扩展，
        增加了对事务内存的支持，实现了硬件层面的无锁机制，可以加速多线程程序的执行。
        TSX为指定代码事务性执行提供了两个软解接口，
        分别是HLE(Hardware Lock Elision)和RTM(Restricated Transactional Memory)。
        HLE通过给特定指令加前缀实现的，能够向后兼容不支持TSX的处理器。
        RTM提供了新的指令，可以更加灵活的供程序员使用。 */
/*  RTM增加了三条新指令，分别是：
        XBEGIN,XEND和XABORT。
        XBEGIN和XEND标记了事务性代码的开始和结束，
        XABORT指令用来终止一个事务。
        如果事务失败，根据返回的状态值，指定一条备选路径；
        返回的状态值存放在eax中。 */
/* 
        RTM的指令可以用头文件immintrin.h实现，也可以用内联汇编实现，此处用内联汇编
    */
// xbegin
unsigned int xbegin()
{
    unsigned status;
    asm volatile(".byte 0xc7, 0xf8; .long 0"
                 : "=a"(status)
                 : "a"(-1UL)
                 : "memory");
    return status;
}
// xend
void xend()
{
    asm volatile(".byte 0x0f, 0x01, 0xd5" ::
                     : "memory");
}
// has_tsx(rtm)，判断是否支持tsx中的rtm
int has_tsx()
{
    if (__get_cpuid_max(0, NULL) >= 7)
    {
        unsigned a, b, c, d;
        __cpuid_count(7, 0, a, b, c, d);
        return (b & (1 << 11)) ? 1 : 0;
    }
    return 0;
}
// 如果支持tsx，访问内存使用maccess_tsx()
void maccess_tsx(void *ptr)
{
    if (xbegin() == (~0u))
    {
        maccess(ptr);
        xend();
    }
}

// 2. x86，和x86-64基本相同
#elif defined(__i386__)
// 用于获取当前的tsc寄存器的值
uint32_t rdtsc()
{
    uint32_t result;
    asm volatile("mfence");
#if USE_RDTSCP
    asm volatile("rdtscp"
                 : "=a"(result)::"edx");
#else
    asm volatile("rdtsc"
                 : "=a"(result)::"edx");
#endif
    asm volatile("mfence");
    return result;
}

// flush指定地址的缓存
void flush(void *p)
{
    asm volatile("clflush 0(%0)\n"
                 :
                 : "c"(p)
                 : "eax");
}

// 访问内存的某地址，从而将内存中的数据加载到cache中
void maccess(void *p)
{
    asm volatile("mov (%0), %%eax\n"
                 :
                 : "c"(p)
                 : "eax");
}

// mfence指令的包装，确保串行化之前的读写操作，同步作用
void mfence()
{
    asm volatile("mfence" ::
                     :);
}

// lfence指令的包装，防止推测执行
void nospec()
{
    asm volatile("lfence" ::
                     :);
}

// has_tsx(rtm)，判断是否支持tsx中的rtm
int has_tsx()
{
    if (__get_cpuid_max(0, NULL) >= 7)
    {
        unsigned a, b, c, d;
        __cpuid_count(7, 0, a, b, c, d);
        return (b & (1 << 11)) ? 1 : 0;
    }
    return 0;
}

// 3. arm 64
#elif defined(__aarch64__)
// 关于arm中的barrier指令
/* 
        DMB
        数据存储器隔离。前面的存储器访问操作执行完毕后，
        才提交(commit)在它后面的存储器访问操作。
        DSB
        数据同步隔离。比DMB严格，前面的存储器访问操作执行完毕后，
        才执行在它后面的指令（任何指令都需要等待）
        ISB
        指令同步隔离。最严格：前面的所有指令执行完毕后，
        才执行它后面的指令。
        DSB要求
        位于此指令前的所有显式内存访问均完成。
        位于此指令前的所有缓存、跳转预测和 TLB 维护操作全部完成。
        参数用SY时是完整的系统 DSB 操作。 这是缺省情况，可以省略。
        ISB 指令完成后，才从高速缓存或内存中提取位于该指令后的其他所有指令
        此外，ISB 指令可确保程序中位于其后的所有跳转指令总会被写入跳转预测逻辑
    */
// 使用monotonic方式获取当前时间
uint64_t rdtsc()
{
    // 同步
    asm volatile("DSB SY");
    asm volatile("ISB"); // 两条组合相当于lfence
    // 获取时间结构体
    struct timespec t1;
    clock_gettime(CLOCK_MONOTONIC, &t1);
    // 计算时间（单位纳秒）
    uint64_t res = t1.tv_sec * 1000 * 1000 * 1000ULL + t1.tv_nsec;
    asm volatile("ISB");
    asm volatile("DSB SY");
    return res;
}

// flush指定地址的缓存
void flush(void *p)
{
    // clean & invalidate缓存
    // 将cacheline的行写回并将cacheline置为invalidate
    // https://community.arm.com/developer/ip-products/processors/f/cortex-a-forum/3731/clean-and-invalidate-cache-memory
    asm volatile("DC CIVAC, %0" ::"r"(p));
    // 此处为何要再同步呢？
    asm volatile("DSB ISH"); // 相当于mfence
    asm volatile("ISB");
}

// 访问内存的某地址，从而将内存中的数据加载到cache中
void maccess(void *p)
{
    volatile uint64_t value;
    asm volatile("LDR %0, [%1]\n\t"
                 : "=r"(value)
                 : "r"(p));
    asm volatile("DSB ISH");
    asm volatile("ISB");
}

// DSB ISH指令的封装，确保串行化之前的读写操作，同步作用
void mfence()
{
    asm volatile("DSB ISH");
}

// DSB SY; ISB指令的封装，防止推测执行
void nospec()
{
    asm volatile("DSB SY");
    asm volatile("ISB");
}
#endif

// cache其他操作
// 进行一次flush+reload并返回时间
int flush_reload_t(void *ptr)
{
    uint64_t start = 0, end = 0;
    start = rdtsc();
    maccess(ptr);
    end = rdtsc();
    mfence();
    flush(ptr);
    return (int)(end - start);
}

// 进行一次flush+reload，如果小于阈值则返回true，即表示该内存在缓存中
int flush_reload(void *ptr)
{
    uint64_t start = 0, end = 0;
    start = rdtsc();
    maccess(ptr);
    end = rdtsc();
    mfence();
    flush(ptr);
    if (end - start < CACHE_MISS)
    {
        return 1;
    }
    return 0;
}

// 进行一次flush+reload并返回时间
int reload_t(void *ptr)
{
    uint64_t start = 0, end = 0;
    start = rdtsc();
    maccess(ptr);
    end = rdtsc();
    mfence();
    return (int)(end - start);
}

// 探测flush+reload的阈值
size_t detect_flush_reload_threshold()
{
    size_t reload_time = 0, flush_reload_time = 0, i, count = 1000000;
    size_t dummy[16];
    // ptr指向dummy[8]
    size_t *ptr = dummy + 8;
    // 访问该地址，将该内存放入cache
    maccess(ptr);
    // 测量数据在cache中时的访问时间
    for (i = 0; i < count; i++)
    {
        reload_time += reload_t(ptr);
    }
    // 测量数据不在cache中时的访问时间
    for (i = 0; i < count; i++)
    {
        flush_reload_time += flush_reload_t(ptr);
    }
    reload_time /= count;
    flush_reload_time /= count;
    // printf("%ld,%ld\n", flush_reload_time, reload_time);
    // 返回两个时间的加权平均，偏向于加载在cache中的数据的时间
    // in-cache------------阈值------------------------not-in-cache
    return (flush_reload_time + reload_time * 2) / 3;
}

// 异常处理实现
// c语言使用setjmp()函数与longjmp()函数实现异常处理机制
// 信号解屏蔽
void unblock_signal(int signum __attribute__((__unused__)))
{
    sigset_t sigs;
    sigemptyset(&sigs);
    sigaddset(&sigs, signum);
    sigprocmask(SIG_UNBLOCK, &sigs, NULL);
}

// 信号处理程序
void trycatch_segfault_handler(int signum)
{
    // 防止编译器认为signum未使用，没有实际意义
    (void)signum;

    int i;
    for (i = 1; i < 32; i++)
    {
        unblock_signal(i);
    }
    // unblock_signal(signum);
    longjmp(trycatch_buf, 1);
}

// try的实现start
int try_start()
{
#if defined(__i386__) || defined(__x86_64__)
    if (has_tsx())
    {
        unsigned status;
        // tsx begin
        asm volatile(".byte 0xc7,0xf8,0x00,0x00,0x00,0x00"
                     : "=a"(status)
                     : "a"(-1UL)
                     : "memory");
        return status == (~0u);
    }
    else
#endif
    {
        int i;
        for (i = 1; i < 32; i++)
        {
            signal(i, trycatch_segfault_handler);
        }
        return !setjmp(trycatch_buf);
    }
}
// try的实现end
void try_end()
{
#if defined(__i386__) || defined(__x86_64__)
    if (!has_tsx())
#endif
    {
        int i;
        for (i = 1; i < 32; i++)
        {
            signal(i, SIG_DFL);
        }
    }
}
// try的实现abort
void try_abort()
{
#if defined(__i386__) || defined(__x86_64__)
    if (has_tsx())
    {
        asm volatile(".byte 0x0f; .byte 0x01; .byte 0xd5" ::
                         : "memory");
    }
    else
#endif
    {
        maccess(0);
    }
}

// 将数据编码到内存中
void cache_encode(char data)
{
    // 根据data访问内存的特定位置，第data页就会取入cache中
    maccess(mem + data * pagesize);
}

// 从cache中恢复单个数据
char cache_decode()
{
    for (int i = 0; i < 256; i++)
    {
        int mix_i = ((i * 167) + 13) & 255; // avoid prefetcher
        if (flush_reload(mem + mix_i * pagesize))
        {
            // return (char)mix_i;
            if (mix_i >= 'A' && mix_i <= 'Z')
            {
                return (char)mix_i;
            }
        }
    }
    return 0;
}

// 从cache中恢复字符数组
void cache_decode_array(char *leaked, int index)
{
    for (int i = 0; i < 256; i++)
    {
        int mix_i = ((i * 167) + 13) & 255; // avoid prefetcher
        if (flush_reload(mem + mix_i * pagesize))
        {
            if ((mix_i >= 'A' && mix_i <= 'Z') && leaked[index] == ' ')
            {
                leaked[index] = mix_i;
                // printf("\x1b[33m%s\x1b[0m\r", leaked);
            }
    //         fflush(stdout);
    //   sched_yield();
        }
    }
}

// 清理cache
void flush_shared_memory()
{
    for (int j = 0; j < 256; j++)
    {
        flush(mem + j * pagesize);
    }
}