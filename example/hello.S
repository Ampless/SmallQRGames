ldr 255
ldg 255
ldb 255
ldx 0
ldy 0

loop:
    pxl
    inx
    ldy 20
    cmp
    beq spin
    phx
    ppy
    jmp loop

spin:
    rst
    jmp spin
