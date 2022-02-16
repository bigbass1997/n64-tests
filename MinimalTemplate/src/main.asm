arch n64.cpu
endian msb
output "../minimal.z64", create
fill 0x00101000 // Set ROM Size // 1024 KB + 4 KB = 1028 KB = 0x00101000 bytes

origin 0x00000000
base 0x80000000

constant zero(0)
constant at(1)
constant v0(2)
constant v1(3)
constant a0(4)
constant a1(5)
constant a2(6)
constant a3(7)
constant t0(8)
constant t1(9)
constant t2(10)
constant t3(11)
constant t4(12)
constant t5(13)
constant t6(14)
constant t7(15)
constant s0(16)
constant s1(17)
constant s2(18)
constant s3(19)
constant s4(20)
constant s5(21)
constant s6(22)
constant s7(23)
constant t8(24)
constant t9(25)
constant k0(26)
constant k1(27)
constant gp(28)
constant sp(29)
constant s8(30)
constant ra(31)

constant fp(s8) // frame pointer (being used as framebuffer pointer)
constant BUF_BASE(0xA0140000)

include "header.asm" // DEBUG ONLY
insert "n64_bootcode.bin" // DEBUG ONLY

macro SWOffset(value, temp_reg, offset, base_reg) {
    la {temp_reg}, {value}
    sw {temp_reg}, {offset}({base_reg})
}

Start:
    // --- Setup VI Registers --- //
    la fp, BUF_BASE // Sets framepointer for later
    la t0, 0xA4400000 // VI_BASE
    SWOffset(0x00003303, t1, 0x00, t0) // VI_CTRL
    SWOffset(BUF_BASE,   t1, 0x04, t0) // VI_ORIGIN
    SWOffset(0x00000140, t1, 0x08, t0) // VI_WIDTH
    SWOffset(0x00000208, t1, 0x0C, t0) // VI_V_INTR
    SWOffset(0x03E52239, t1, 0x14, t0) // VI_TIMING
    SWOffset(0x0000020D, t1, 0x18, t0) // VI_V_SYNC
    SWOffset(0x00000C15, t1, 0x1C, t0) // VI_H_SYNC
    SWOffset(0x0C150C15, t1, 0x20, t0) // VI_H_SYNC_LEAP
    SWOffset(0x006C02EC, t1, 0x24, t0) // VI_H_VIDEO
    SWOffset(0x002501FF, t1, 0x28, t0) // VI_V_VIDEO
    SWOffset(0x000E0204, t1, 0x2C, t0) // VI_V_BURST
    SWOffset(0x00000200, t1, 0x30, t0) // VI_X_SCALE
    SWOffset(0x00000400, t1, 0x34, t0) // VI_Y_SCALE
    
    
    // --- Clear Framebuffer --- // This section is optional, but recommended for a clean display
    addu s4, zero, fp
    la s3, (4 * 320 * 240)
    addu s4, s4, s3
    
    addu s3, zero, fp
    la s2, 0x222222FF // Background color
Clear:
    sw s2, 0(s3)
    bne s4, s3, Clear
    addi s3, s3, 4
    
    
    // --- Print Message --- //
    la t1, 4 * ((320 * 40) + 76) // start position
    addu t1, t1, fp
    la a3, 0xFFFFFFFF // font color
    la t0, Text
    la t9, TextEnd
    
StartPrint:
    addiu t7, zero, 8
PrintChar:
    addi t7, t7, -1
    
    lbu t3, 0(t0) // Load row
    addiu t0, t0, 1
    addiu t8, zero, 8
PrintRow:
    addi t8, t8, -1
    andi t4, t3, 0b10000000
    sll t3, t3, 1
    beq t4, zero, PrintSkipPixel
    nop
    
    sw a3, 0(t1)
PrintSkipPixel:
    addiu t1, t1, 4 // increment cursor
    bne t8, zero, PrintRow
    nop
    
    addiu t1, t1, -(4 * 8) + (4 * 320)
    bne t7, zero, PrintChar
    nop
    
    addi t1, t1, -(4 * 320 * 8) + 36
    bne t0, t9, StartPrint
    nop
    
    
    
    // --- Spin Forever --- //
Spin:    
    j Spin
    nop
    
    
Text:
    insert TestText, "text.bin"
TextEnd:
    nop