all: x86

x86: main_x86
arm: main_arm

main_x86: main.c victim.c
	gcc main.c -o poc -Os -I../../
	gcc victim.c -o victim -Os

main_arm: main.c victim.c
	aarch64-linux-gnu-gcc -march=armv8-a -D__ARM_ARCH_8A__ -static -Os main.c -o poc -I../../
	aarch64-linux-gnu-gcc -march=armv8-a -D__ARM_ARCH_8A__ -static -Os victim.c -o victim -I../../

clean:
	rm -f poc victim