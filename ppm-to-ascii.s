@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Original author: Gordon Griesel
@ Date:            Fall 2024
@ Purpose:         Open and read a file
@                  If a valid PPM file, display image information.
@
@ Usage: ./lab8            <---- will default to filename stored in fname:
@        ./lab8 some.ppm   <---- will process some.ppm file
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@   Registers: 
@       r0: function argument and return value
@       r1: 
@       r2: 
@       r3: 
@       r4: argc - number of command-line arguments (temporary)
@       r5: fd for file
@       r6: address of string of characters read from file
@       r7: reserved for svc
@       r8:
@       r9:
@      r10: 
@      r11: FP - frame pointer, if needed 
@      r12: 
@      r13: SP - stack pointer
@      r14: LR - link register
@      r15: PC - program counter
@
@ notes:
@      end-of-file status is stored in a data variable named eof_flag.
@
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@   .include "./files/write.s"
@   Outputs a null terminated string to stdout
@
@   r0  -   output str address
@   r1  -   search address
@   r2  -   tmp search bit
@   r3  -   str length
@
@   labels:
@       1: Length loop
@       2: Output syscall
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
.macro swrite outstr
                            @ Find length of string
    ldr   r0, =\outstr      @ load outstring address
    mov   r1, r0            @ copy address for len calc later
1:
    ldrb  r2, [r1]          @ load first char
    cmp   r2, #0            @ check to see if we have a null char 
    beq   2f                @ branch to label 2 forward
                            @ branch if null terminator
    add   r1, #1            @ Increment search address 
    b     1b                @ branch to label 1 backwards (beginning of loop)
2:
    sub   r3, r1, r0        @ calculate string length. Subtract left address
                            @ from right address.
    mov   r7, #4            @ 4 = write. Setup write syscall
    mov   r0, #1            @ 1 = stdout 
    ldr   r1, =\outstr      @ outstr address of string to be displayed
    mov   r2, r3            @ load length
    svc   0                 @ system call
.endm
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ write the string at an address. addr can be passed in as a register.
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
.macro swrite_address addr
                            @ Find length of string
    mov   r0, \addr           @ load outstring address
    mov   r1, r0            @ copy address for len calc later
1:
    ldrb  r2, [r1]          @ load first char
    cmp   r2, #0            @ check to see if we have a null char 
    beq   2f                @ branch to label 2 forward
                            @ branch if null terminator
    add   r1, #1            @ Increment search address 
    b     1b                @ branch to label 1 backwards (beginning of loop)
2:
    sub   r3, r1, r0        @ calculate string length. Subtract left address
                            @ from right address.
    mov   r7, #4            @ 4 = write. Setup write syscall
    mov   r0, #1            @ 1 = stdout 
    mov   r1, \addr           @ outstr address of string to be displayed
    mov   r2, r3            @ load length
    svc   0                 @ system call
.endm
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
.macro newline
    mov     r7, #4          @ 4 = write
    mov     r0, #1          @ 1 = stdout
    ldr     r1, =nline      @
    mov     r2, #1          @ load length of write to r2
    svc     0
.endm
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Program starts here
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.equ    O_RDONLY, 0x0

.global _start
.extern atoi
.extern itoa

_start:
							@ check for command-line argument
	ldr r4, [sp]			@ load number of command-line arguments
	cmp r4, #1				@ is there more than one?
	beq go					@ no. use the default file name (fname:)
							@ get the second command-line argument
	ldr r5, [sp, #8]		@ here is the address of it.
    swrite_address r5       @ display the string
    newline
	mov r0, r5
	b got_name
go:
                            @ open a file 
    ldr     r0, =fname      @ file name
got_name:
    mov     r1, #O_RDONLY   @ mode = readonly
    mov     r2, #0          @ not needed for read only
    mov     r7, #5          @ 5 = open syscall
    svc     0               @ 
    mov     r5, r0          @ move fd to store for use later

                            @ Read 1st character 
    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ r5 = fd of open file
    ldr     r1, =readbuf    @ read buffer
    mov     r2, #1          @ length is 1 character
    svc     0
    ldrb r0, [r1]            @ get the byte read 
    cmp r0, #'P'             @ check for eof
    bne not_ppm              @ if eof, treat as a whitespace
    
                            @ Read 2nd character
    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ r5 = fd of open file
    ldr     r1, =readbuf    @ read buffer
    mov     r2, #1          @ length is 1 character
    svc     0
    ldrb r0, [r1]             @ get the byte read 
    cmp r0, #'3'              @ check for eof
    bne not_ppm               @ if eof, treat as a whitespace

    bl parse                  @ get the width 
    bl check_for_comment      @ check for comment 
    swrite wid                @
    swrite string             @ print width 
    @ load load width_val with the itoa value of the string
    ldr r0, =string           @ load the string
    bl atoi                   @ convert the string to an integer
    ldr r1, =width_val        @ get the address of width_val
    str r0, [r1]              @ store the width value
    newline

    bl parse                  @ get the height
    bl check_for_comment      @ check for comment
    swrite height             @
    swrite string             @ print height
    @ load load height_val with the itoa value of the string
    ldr r0, =string           @ load the string
    bl atoi                   @ convert the string to an integer
    ldr r1, =height_val       @ get the address of height_val
    str r0, [r1]              @ store the width value
    newline

    bl parse                  @ get the max color
    bl check_for_comment      @ check for comment
    swrite maxcolor           @
    swrite string             @ print max color
    newline                   @

    @ now multiply the width and height to get the total number of pixels
    ldr r1, =width_val        @ get the address of width_val
    ldr r0, [r1]              @ get the value of width_val
    ldr r1, =height_val       @ get the address of height_val
    ldr r2, [r1]              @ get the value of height_val
    mul r3, r0, r2            @ multiply the width and height

    mov r0, r3                @ move the value to r0
    ldr r1, =total_pixs       @ get the address of total_pixs
    str r3, [r1]              @ store the total number of pixels
    swrite totalPixels        @ print total pixels
    ldr r0, =total_pixs       @ get the address of total_pixs
    ldr r0, [r0]              @ get the value of total_pixs
    bl show_register_value    @ display the value
 
    newline

    sub sp, #8                @ allocate space on the stack
    mov r1, #0                @ i = sp + 4 j = sp
    str r1, [sp, #4]          @ store 0 for i in stack
    str r1, [sp]              @ store 0 for j in stack

    @b end_of_program          @ end of program
                              @ program for info only
outer_loop:
                            @ nested loops through colors
    newline
innerloop:
    sub sp, #12               @ allocate space for 3 integers
                              @ r = [sp, #8]
                              @ g = [sp, #4]
                              @ b = [sp]

    @ parse r = atoi(parse())
    bl parse                  @ get the red value
    ldr r0, =string           @ load the string
    bl atoi                   @ convert the string to an integer
    str r0, [sp, #8]          @ store the red value

    @ parse g = atoi(parse())
    bl parse                  @ get the green value
    ldr r0, =string           @ load the string
    bl atoi                   @ convert the string to an integer
    str r0, [sp, #4]          @ store the green value

    @ parse b = atoi(parse())
    bl parse                  @ get the blue value
    ldr r0, =string           @ load the string
    bl atoi                   @ convert the string to an integer
    str r0, [sp]              @ store the blue value

    @ total = r + g + b
    ldr r1, [sp, #8]          @ get the value of r_value
    ldr r2, [sp, #4]          @ get the value of g_value
    add r1, r1, r2            @ add r_value and g_value
    ldr r2, [sp]              @ get the value of b_value
    add r1, r1, r2            @ add the result to b_value

    @ total logical bit shifted right 7
    lsr r1, r1, #7            @ shift the total right 7 bits

    @ use palette as an array to get the address of the character
    @ at index r1 and then store it in temp_buff then display temp_buff
    ldr r0, =palette          @ get the address of palette
    add r0, r0, r1            @ get the address of the character
    ldrb r1, [r0]             @ get the value of the character
    ldr r0, =temp_buff        @ get the address of temp_buff
    strb r1, [r0]             @ store the value of the character
    add r0, r0, #1            @ move to the next position in temp_buff
    mov r1, #0                @ move the null terminator to r1
    strb r1, [r0]             @ store the null terminator
    swrite temp_buff

    swrite test               @ print a space

    add sp, #12               @ deallocate space for 3 integers



    @ j++
    ldr r1, [sp]              @ get the value of j_value
    add r1, r1, #1            @ increment j_value
    str r1, [sp]              @ store the new value of j_value

    @ while (j < width)
    ldr r1, [sp]              @ get the value of j_value
    ldr r0, =width_val        @ get the address of width_val
    ldr r2, [r0]              @ get the value of width_val
    cmp r1, r2                @ compare j_value to width_val
    blo innerloop             @ if less than, go to innerloop

    @ j = 0
    mov r1, #0                @ reset j_value
    str r1, [sp]              @ store the new value of j_value

    @ i++
    ldr r1, [sp, #4]          @ get the value of i_value
    add r1, r1, #1            @ increment i_value
    str r1, [sp, #4]          @ store the new value of i_value

    @ while (i < height)
    ldr r1, [sp, #4]          @ get the value of i_value
    ldr r0, =height_val       @ get the address of height_val
    ldr r2, [r0]              @ get the value of height_val
    cmp r1, r2                @ compare i_value to height_val
    blo outer_loop            @ if less than, go to outerloop

    add sp, #8                @ deallocate space on the stack

    b end_of_program


                            @ check for eof
    ldr r1, =eof_flag       @ get address of eof variable
    ldr r2, [r1]            @ get the value at the address
    cmp r2, #1              @ 1 == end of file
    beq end_of_program
    b outer_loop 


@ ------------------------------------------------------------------------------
@  function: check_for_comment
@ ------------------------------------------------------------------------------
check_for_comment:
    push { lr }                 @ save return address

    ldr r1, =string        @ get address of string
    ldrb r2, [r1]          @ get first character
    cmp r2, #35            @ check if it is #
    bne leave              @ if not, leave

    swrite commentContentMsg  @ print comment message
    swrite string             @ print the comment

@ Should read until newline character
comment_loop:
    @ if comment ignore the whole line until 
    @ a newline character is found

    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ r5 = fd of open file
    ldr     r1, =readbuf    @ read buffer
    mov     r2, #1          @ length is 1 character
    svc     0 
    cmp r0, #0              @ check for eof
    beq end_of_program

    swrite readbuf          @ print the character

    ldrb    r4, [r1]        @ load char into r4
    cmp     r4, #10         @ newline?
    bne comment_loop
    bl parse

leave:
    pop { lr }              @ restore return address
    bx lr   

@-----------------------------------------------------------------------------
@ function
@-----------------------------------------------------------------------------
parse:
    push { lr }                 @ save return address
    ldr r6, =string             @ address of string for input
    bl read_past_whitespace     @
    bl read_until_whitespace    @
    pop { lr }                  @
    bx lr                       @

@-----------------------------------------------------------------------------
@ function
@-----------------------------------------------------------------------------
read_until_whitespace:
                            @ this is a function
                            @ read 1 character at a time
                            @ concatenate each character to a string at r6
                            @ r6 contains address of string
ruw:
    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ r5 = fd of open file
    ldr     r1, =readbuf    @ read buffer
    mov     r2, #1          @ length is 1 character
    svc     0 
    cmp r0, #0              @ check for eof
    beq eof1                @ if eof, treat as a whitespace
                            @ is this character a white space?
    ldrb    r4, [r1]        @ load char into r4
    cmp     r4, #32         @ space?
    beq     whitesp
    cmp     r4, #9          @ tab?
    beq     whitesp
    cmp     r4, #10         @ newline?
    beq     whitesp
    cmp     r4, #13         @ carriage return?
    beq     whitesp
                            @ not a white space
    str     r4, [r6]        @ concatenate 1 char to string
    add     r6, r6, #1
    b       ruw
eof1:
                            @ set eof flag in data variable
    ldr r1, =eof_flag       @ get address of variable
    mov r0, #1
    str r0, [r1]            @ store a 1 - true
                            @ fall through
whitesp:
    mov r10, #0             @ move null to
    str r10, [r6]           @ store the null terminator to the string
    bx lr

@-----------------------------------------------------------------------------
@ function
@-----------------------------------------------------------------------------
read_past_whitespace:
                            @ this is a function
                            @ read 1 character at a time
                            @ store the first non-whitespace in r0
                            @ then return
rpw:
    mov     r7, #3          @ 3 = read
    mov     r0, r5          @ r5 = fd of open file
    ldr     r1, =readbuf    @ read buffer
    mov     r2, #1          @ length is 1 character
    svc     0               @
    cmp r0, #0              @ check for eof
    beq eof2                @ if eof, treat as no character

                            @ is this character a non-white space?
    ldrb    r4, [r1]        @ load char into r4
    cmp     r4, #32         @ space?
    beq     rpw             @
    cmp     r4, #9          @ tab?
    beq     rpw             @
    cmp     r4, #10         @ newline?
    beq     rpw             @
    cmp     r4, #13         @ carriage return?
    beq     rpw             @
    @ldr     r6, =string    @ address of string for input
                            @ found a non whitespace
                            @ save and return
    ldr     r10, [r1]       @ get char
    str     r10, [r6]       @ put the char in string
    add     r6, r6, #1      @ increment string address
    b rpw_done
eof2:
                            @ set eof flag in data variable
    ldr r1, =eof_flag       @ get address of variable
    mov r0, #1
    str r0, [r1]            @ store a 1 - true
                            @ fall through
rpw_done:
    bx lr                   @

@-----------------------------------------------------------------------------
@ function
@-----------------------------------------------------------------------------
show_register_value:
    push { lr }         @
    mov r0, r0          @ setup itoa to display the number in register r0
    ldr r1, =outbuf     @
    mov r2, #0          @ store zero
    str r2, [r1]        @ fill buffer with zeros
    str r2, [r1, #4]    @
    str r2, [r1, #8]    @
    bl itoa             @
    swrite outbuf       @
    pop { lr }          @
    bx lr               @


not_ppm:
    swrite mess3

end_of_program:
							@ close file 
    mov     r7, #6			@ 6 = close syscall
    mov     r0, r5			@ file descriptor
    svc     0				@ 
    @ setup exit 
    newline

very_end:
    mov     r7, #1          @ 1 = exit 
    mov     r0, #0          @ 0 = no error 
    svc     0 


.data
                    @ the default file-name
fname:    .asciz    "csub.ppm"
                    @ some messages to use if you need them
                    @ you may delete these messages, and make your own
                    @ these were used during the original program development
mess1:    .asciz    "char\n"
mess2:    .asciz    "whitespace\n"
mess3:    .asciz    "Not a P3 file. Ending.\n"
mess4:    .asciz    "Found a P3 image file.\n"
mess5:    .asciz    "get 3 values...\n"
mess6:    .asciz    "out of loops.\n"
mess7:    .asciz    "end-of-pic.  \n"
mess8:    .asciz    "end-of-row.  \n"
mess9:    .asciz    "r8 is not 2! \n"
read1:    .asciz    "reading file...\n"
read2:    .asciz    "returned from read.\n"
wid:      .asciz    "Width: "
height:    .asciz    "Height: "
maxcolor:  .asciz    "Max color: "
totalPixels: .asciz "Total Pixels: "
commentContentMsg: .asciz "Comment: "
test:    .asciz    " "
                    @ data below is more useful or required 
palette: .asciz " .:o#@"
nline:    .asciz    "\n"
outbuf:   .fill     256
string:   .fill     256
readbuf:  .fill     256
eof_flag: .word     0
width_val: .word    0
height_val: .word   0
total_pixs: .word   0
temp_buff: .fill   256

