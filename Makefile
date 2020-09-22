all: libcache/get libpte/mod meltdown/AC/main meltdown/US/main

libcache/get: 
	cd libcache && make

libpte/mod:
	cd libpte && make

meltdown/AC/main:
	cd meltdown/AC && make x86

meltdown/US/main:
	cd meltdown/US && make x86

clean:
	cd libcache && make clean
	cd libpte && make clean
	cd meltdown/US && make clean