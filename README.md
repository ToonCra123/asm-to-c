# PPM-TO-ASCII

Hello, I am your average computer science student doing low level things. This is my project to view ppm p3 images in command line by displaying them as ascii values. 

## USAGE

```bash
./ppm-to-ascii <file-name>
```
if no file-name is provided then it will default to csub.ppm, which then you will probably get an error or something idk. Have Fun

## PREREQUISITES

must have arm-gnueabi-as/ld

```bash
sudo apt update
sudo apt install libc6-armel-cross libc6-dev-armel-cross binutils-arm-linux-gnueabi libncurses5-dev build-essential bison flex libssl-dev bc
```
