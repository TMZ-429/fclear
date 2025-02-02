#!/bin/make

make:
	nasm -f elf64 fclear.asm -o fclear.o
	ld fclear.o -o fclear

32:
	nasm -f elf fclear32.asm -o fclear.o
	ld -m elf_i386 -s -o fclear fclear.o

install:
	chmod 755 ./fclear
	cp ./fclear /usr/local/bin/fclear