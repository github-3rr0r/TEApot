all: libcache/get libpte/mod meltdown/US/main

libcache/get: 
	cd libcache && make

libpte/mod:
	cd libpte && make

meltdown/US/main:
	cd meltdown/US && make x86

clean:
	cd libcache && make clean
	cd libpte && make clean
	cd meltdown/US && make clean