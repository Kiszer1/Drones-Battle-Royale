all: battle

battle: battle.o drone.o printer.o scheduler.o target.o 
	gcc -m32 -Wall -g battle.o drone.o printer.o scheduler.o target.o -o battle

battle.o: battle.s
	nasm -f elf battle.s -o battle.o

drone.o: drone.s
	nasm -f elf drone.s -o drone.o

printer.o: printer.s
	nasm -f elf printer.s -o printer.o

scheduler.o: scheduler.s
	nasm -f elf scheduler.s -o scheduler.o

target.o: target.s
	nasm -f elf target.s -o target.o

.PHONY : run clean

clean : 
	rm -f *.o battle
 
