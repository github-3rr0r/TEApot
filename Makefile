all: libcache/get libpte/mod meltdowns

meltdowns: AC BR DE GP NM P PK RW SS UD US

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

P:
	cd meltdown/P && make x86

PK:
	cd meltdown/PK && make x86

RW:
	cd meltdown/RW && make x86

SS:
	cd meltdown/SS && make x86

UD:
	cd meltdown/UD && make x86

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
	cd meltdown/P && make clean
	cd meltdown/PK && make clean
	cd meltdown/RW && make clean
	cd meltdown/SS && make clean
	cd meltdown/UD && make clean
	cd meltdown/US && make clean