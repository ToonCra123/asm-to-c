@   converts an unsigned ASCII number to int
@
@   alphanumeric-to-integer
@
@   preserves r4 
@
@   Input
@       r0: address of null terminated input str 
@   Used
@       r4: total
@       r5: 10 constant for mul
@       r6: current num 
@       r7: current address
@   Output
@       r0: total 
@
@   ---------------------------------------------------------------------------
@   ---------------------------------------------------------------------------
@   This program has a bug.
@   The program will read this string "111 111"
@                        as the number 1094111
@
@   The space character is treated as a digit and ASCII '0' is subtracted
@   from it. 32 - 48 = -16.
@
@   Fix this bug by looking for white-space instead of only '\n' and '\0'
@   Fix the bug.
@   ---------------------------------------------------------------------------
@   ---------------------------------------------------------------------------

.global atoi

atoi:
    push    {r4-r8}         @ save r4, r5 before use 
    mov     r4, #0          @ init r4 
    mov     r5, #10         @ load 10 constant 
    mov     r7, r0          @ copy address to incr  

loop:
    @ find first number 
    ldrb    r6, [r7], #1    @ load byte and increment 
    cmp     r6, #0          @ see if we have a null 
    beq     exit            @ if we do, exit
    cmp     r6, #'\n'       @ see if we have a line ending 
    beq     exit            @ if we do exit 
                            @ the same thing could have been done with a 
                            @ single comp and checking if the char is less 
                            @ than ASCII 0 as both \0 and \n < '0'. This is 
                            @ just done here to be explicit. 
    mul     r4, r5, r4      @ if we have another digit, move current total 
                            @ over a space 
    sub     r6, r6, #'0'    @ subtract the value of ASCII zero to char 
    add     r4, r4, r6      @ add to total 
    b       loop 
exit: 
    mov     r0, r4          @ move total to r0 
    pop     {r4-r8}         @ restore registers
    bx      lr              @ return to calling fn  

