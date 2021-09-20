j FUNCTIONS_END
nop


// Same as PrintHexW, but the render-buffer and data location is stored in a register instead of being hardcoded.
// Assumes the following constants are set:
//     SCREEN_WIDTH     = Width of the screen in pixels (e.g. 640 for a 640x480 resolution)
//     BYTES_PER_PIXEL  = Either 2 or 4, for BPP16 or BPP32 respectively
//     FONT_SPACING     = Number of pixels between each character (can be negative)
//
macro PrintHexRegW(buf_addr_reg, xpos, ypos, data_addr_reg, font_addr, color) {
    PrepareHexRegW({buf_addr_reg}, {xpos}, {ypos}, {data_addr_reg}, {font_addr}, {color})
    
    jal Func_HexW
    nop
}
macro PrepareHexRegW(buf_addr_reg, xpos, ypos, data_addr_reg, font_addr, color) {
    addu a1, zero, {data_addr_reg}  // performed first in case data_addr_reg is an a- register
    
    la a0, (({xpos} + (7 * (8 + FONT_SPACING))) * BYTES_PER_PIXEL) + (SCREEN_WIDTH * BYTES_PER_PIXEL * {ypos})
    addu a0, a0, {buf_addr_reg}
    la a2, {font_addr}
    la a3, {color}
}

// Assumes the following constants are set:
//     SCREEN_WIDTH     = Width of the screen in pixels (e.g. 640 for a 640x480 resolution)
//     BYTES_PER_PIXEL  = Either 2 or 4, for BPP16 or BPP32 respectively
//     FONT_SPACING     = Number of pixels between each character (can be negative)
//
macro PrintHexW(buf_addr, xpos, ypos, data_addr, font_addr, color) {
    PrepareHexW({buf_addr}, {xpos}, {ypos}, {data_addr}, {font_addr}, {color})
    
    jal Func_HexW
    nop
}
macro PrepareHexW(buf_addr, xpos, ypos, data_addr, font_addr, color) {
    la a0, {buf_addr} + (({xpos} + (7 * (8 + FONT_SPACING))) * BYTES_PER_PIXEL) + (SCREEN_WIDTH * BYTES_PER_PIXEL * {ypos})
    la a1, {data_addr}
    la a2, {font_addr}
    la a3, {color}
}

// Prints 8 hex characters representing 4 bytes
// Registers manipulated:
//   t0, t1, t2, t3, t5, t6, t7, t8, t9
//
// Registers read-only:
//   a0, a1, a2, a3
//
Func_HexW:
    // t9 will be used as a bitmask later
    addiu t9, zero, 1
    dsll t9, t9, 7          // t9 = 0b 00000000 00000000 00000000 10000000
    
    addu t3, zero, a0       // t3 = pixel cursor
    
    //grab word (32 bits)
    lwu t8, 0(a1)
    
    addiu t5, zero, 7       // t5 = nibble counter
    
FPH_LoadNextNibble:
    andi t0, t8, 0b00001111     // filter out next least-significant nibble into t0
    srl t8, t8, 4               // shift t8 right 4 bits for next loop
    
    addiu t1, zero, 8
    multu t1, t0
    mflo t1
    add t0, t1, a2          // t0 = font address + character offset
    
    addiu t7, zero, 7       // t7 = row counter for this character
    
FPH_DrawFontChar_RowIncr:
    addiu t6, zero, 7       // t6 = pixel counter for this row
    lbu t1, 0(t0)           // t1 = character byte for this row
    addiu t0, t0, 1         // increment pointer for font data
    
FPH_DrawFontChar_RowLoop:
    and t2, t1, t9
    beq t2, zero, FPH_PixelDone
    nop
    
    sw a3, 0(t3)        // draw pixel using the color stored in a3
    
FPH_PixelDone:
    addiu t3, BYTES_PER_PIXEL   // increment pixel cursor
    sll t1, t1, 1               // shift font character data left by 1
    
    
    bne t6, zero, FPH_DrawFontChar_RowLoop  // if pixel counter != 0, then loop again
    addi t6, t6, -1                         // and decrement pixel counter
//--  
    
    addiu t3, -(BYTES_PER_PIXEL * 8) + (BYTES_PER_PIXEL * SCREEN_WIDTH)     // row completed, move pixel cursor back to the left, and down 1 row
    
    bne t7, zero, FPH_DrawFontChar_RowIncr  // if row counter != 0, then loop again
    addi t7, t7, -1                         // and decrement row counter
//--
    
    addiu t3, -( (BYTES_PER_PIXEL * (8 + FONT_SPACING)) + (BYTES_PER_PIXEL * SCREEN_WIDTH * 8) )     // character completed, move pixel cursor to the top-left corner of the next more-significant nibble
    
    bne t5, zero, FPH_LoadNextNibble        // if nibble counter != 0, then loop again
    addi t5, t5, -1                         // and decrement nibble counter
    
    jr ra
    nop
    
    
    
FUNCTIONS_END:
nop