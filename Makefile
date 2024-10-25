all: ppm-to-ascii

ppm-to-ascii: ppm-to-ascii.o
	arm-linux-gnueabi-ld -o ppm-to-ascii ppm-to-ascii.o

ppm-to-ascii.o: ppm-to-ascii.s
	arm-linux-gnueabi-as -o ppm-to-ascii.o ppm-to-ascii.s

clean:
	rm -f ppm-to-ascii ppm-to-ascii.o