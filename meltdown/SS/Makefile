all: x86

x86: main_x86
arm: main_arm

main_x86:
	gcc -m32 -DM32=1 -o poc -I../../ main.c 

clean:
	rm -rf poc