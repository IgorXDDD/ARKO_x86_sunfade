cc -m32 -std=c99 -c test.c
nasm -f elf32 sunfade.s
cc -m32 -o glowny test.o sunfade.o