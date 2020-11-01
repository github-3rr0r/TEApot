all: x86

x86: main_x86

module/kernel_module.ko: ../../libcr3/kernel_module.c
	cd ../../libcr3/ && make

main_x86: main.c module/kernel_module.ko
	gcc main.c -o poc -O3 -I../../

clean:
	rm -f poc && cd ../../libcr3/ && make clean
