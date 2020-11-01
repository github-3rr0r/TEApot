all: pteditor ptedit.o

header: module/pteditor.c module/pteditor.h ptedit.c ptedit.h
	cat module/pteditor.h ptedit.h ptedit.c | sed 's/#include ".*"//g' > ptedit_header.h

pteditor: module/pteditor.c
	cd module && make

clean:
	cd module && make clean