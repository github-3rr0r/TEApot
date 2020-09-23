all: x86

x86: main_x86

main_x86: main.c
	g++ main.c -o poc -O3 -I../../

clean:
	rm -f poc
