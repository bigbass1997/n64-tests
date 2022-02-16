arch n64.cpu
endian msb
output "../minimal.z64", create
fill 0x00101000 // Set ROM Size // 1024 KB + 4 KB = 1028 KB = 0x00101000 bytes

origin 0x00000000
base 0x80000000

include "header.asm"
insert "n64_bootcode.bin"


//// Everything below this point is what's absolutely required for this code to work by itself. ////


constant zero(0)
constant a3(7)
constant t0(8)
constant t1(9)
constant t2(10)
constant t3(11)
constant t4(12)
constant t7(15)
constant t8(24)
constant t9(25)
constant fp(30) // pointer to framebuffer

constant BUF_BASE(0xA0140000)  // base address for the framebuffer
constant CHAR_SPACING(1)  // number of pixels of whitespace between each printed character

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
    addu t1, zero, fp
    la t0, (4 * 320 * 240)
    addu t1, t1, t0
    
    addu t0, zero, fp
    la t2, 0x222222FF // Background color
Clear:
    sw t2, 0(t0)
    bne t1, t0, Clear
    addi t0, t0, 4
    
    
    // --- Print Message --- //
    la t1, 4 * ((320 * 40) + 76) // start position
    addu t1, t1, fp
    la a3, 0xFFFFFFFF // font color
    la t0, Text
    la t9, TextEnd
    
PrintText:
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
    
    addi t1, t1, -(4 * 320 * 8) + (4 * (8 + CHAR_SPACING))
    bne t0, t9, PrintText
    nop
    
    
    
    // --- Loop Forever --- //
Spin:    
    j Spin
    nop
    
    
    
// This text data is a sequence of characters (images), where each bit represents a pixel that is either on (1) or off (0).
// Each "character" is 8 x 8 bits. Each set of 8 bits is a row of pixels, and each set of 8 rows is a character.

// Example, the letter 'A' could be manually created like so:
// db 0b00011000
// db 0b00100100
// db 0b01000010
// db 0b10000001
// db 0b11111111
// db 0b10000001
// db 0b10000001
// db 0b10000001

Text:
    insert "text.bin" // binary format
    // include "text.inc" // assembly format
TextEnd:
    nop