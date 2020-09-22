all: x86

x86: main_x86

main_x86: main.c
	gcc -m32 -DM32=1 -I../../ main.c -o poc

clean:
	rm -f poc
