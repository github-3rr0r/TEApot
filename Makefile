all: libcache/get libpte/mod meltdowns

meltdowns: AC BR DE GP NM US

libcache/get: 
	cd libcache && make

libpte/mod:
	cd libpte && make

AC:
	cd meltdown/AC && make x86

BR:
	cd meltdown/BR && make x86

DE:
	cd meltdown/DE && make x86

GP:
	cd meltdown/GP && make x86

NM:
	cd meltdown/NM && make x86

US:
	cd meltdown/US && make x86

clean:
	cd libcache && make clean
	cd libpte && make clean
	cd meltdown/AC && make clean
	cd meltdown/BR && make clean
	cd meltdown/DE && make clean
	cd meltdown/GP && make clean
	cd meltdown/NM && make clean
	cd meltdown/US && make clean