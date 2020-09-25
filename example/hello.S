ldr 255
ldg 255
ldb 255
zrx
zry

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
