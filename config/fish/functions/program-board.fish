
function program-board --description "Programs a connected ATTINY13A with main.c inside of current folder"
	bash -c '
		avr-gcc -Os -Wall -mmcu=attiny13a main.c -o main.elf
		avr-objcopy -O ihex main.elf main.hex
		avrdude -c avrisp2 -p attiny13a -U flash:w:main.hex:i
	'
end

