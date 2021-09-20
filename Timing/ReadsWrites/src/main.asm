arch n64.cpu
endian msb
output "../Timing-ReadsWrites-Test.z64", create
fill 0x00101000 // Set ROM Size // 1024 KB + 4 KB = 1028 KB = 0x00101000 bytes

origin 0x00000000
base 0x80000000

constant fp(s8) // frame pointer (being used as framebuffer pointer)
constant BUF_BASE_A(0xA0140000)
constant BUF_BASE_B(0xA0200000)
constant BUF_FLAGS(0xA03FFFFC)

constant SP_STORAGE(0xA03FFF00)

constant UNCACHED_WRITE_STORAGE(0xA03FFA00)
constant   CACHED_WRITE_STORAGE(0x803FFB00)
constant DOUBLE_WRITE_STORAGE(0xA03FFC00)

constant SCREEN_WIDTH(320)
constant SCREEN_HEIGHT(240)
constant BYTES_PER_PIXEL(4)
constant FONT_SPACING(1)
constant COL1X(6)
constant COL2X(84)
constant COL3X(162)
constant COL4X(240)

// RDRAM Addresses for printable values
constant PRINT_ADDR(0xA03FFE00)

include "lib/n64/header.asm"
include "lib/n64/constants.inc"
include "lib/graphics/colors.inc"
include "lib/graphics/visetup.inc"
insert "lib/bin/n64_bootcode.bin"

macro ALIGN(size) { // Align Byte Amount
  while (pc() % {size}) {
    db 0
  }
}

// This will first clear any VI interrupt just in case.
// Then it copies the two instructions located at label "ISR_Jump", to the Interrupt Vectors.
// It will set the MI_INTERRUPT register mask.
// And finally will enable the global interrupt bit and IM[2] in the Status register
macro SetupISR() {
    la s7, 0xA4400010
    lw s6, 0(s7)
    sw s6, 0(s7)

    la t1, 0xA0000000 // Destination Base
	la t0, ISR_Jump // Label for jumping to ISR
    
    lw t2, 0x0(t0)
    lw t3, 0x4(t0)
    nop
    
    sw t2, 0x0(t1)
    sw t3, 0x4(t1)
    
    sw t2, 0x80(t1)
    sw t3, 0x84(t1)
    
    sw t2, 0x100(t1)
    sw t3, 0x104(t1)
    
    sw t2, 0x180(t1)
    sw t3, 0x184(t1)
    nop
    
    cache 0x10, 0x0(t1)
    cache 0x10, 0x80(t1)
    cache 0x10, 0x100(t1)
    cache 0x10, 0x180(t1)
    
    //la t0, 0x00000080 // Use this to only set VI mask
    la t0, 0x00000595 // Use this to set VI mask and clear all other masks
    la t2, 0xA430000C
    sw t0, 0(t2)
    
    //nop                //
    //mfc0 t0, Status    //
    //nop                //
    //ori t0, t0, 0x0401 // Use this to bitwise OR only the necessary bits
    
    la t0, 0x34000401 // Or use this to set the entire register to expected values
    nop
    mtc0 t0, Status
    nop
}

macro ClearStorage(addr) {
    la s0, {addr}
    la t0, 0x00000000
    sw t0, 0x00(s0)
    la t0, 0x11111111
    sw t0, 0x10(s0)
    la t0, 0x22222222
    sw t0, 0x20(s0)
    la t0, 0x33333333
    sw t0, 0x30(s0)
    la t0, 0x44444444
    sw t0, 0x40(s0)
    la t0, 0x55555555
    sw t0, 0x50(s0)
    la t0, 0x66666666
    sw t0, 0x60(s0)
    la t0, 0x77777777
    sw t0, 0x70(s0)
    la t0, 0x88888888
    sw t0, 0x80(s0)
    la t0, 0x99999999
    sw t0, 0x90(s0)
    la t0, 0xAAAAAAAA
    sw t0, 0xA0(s0)
    la t0, 0xBBBBBBBB
    sw t0, 0xB0(s0)
    la t0, 0xCCCCCCCC
    sw t0, 0xC0(s0)
    la t0, 0xDDDDDDDD
    sw t0, 0xD0(s0)
    la t0, 0xEEEEEEEE
    sw t0, 0xE0(s0)
    la t0, 0xFFFFFFFF
    sw t0, 0xF0(s0)
}

macro TestStorage(addr) {
    la s0, {addr}
    lw t0, 0x00(s0)
    sw t0, 0x10(s0)
    lw t0, 0x20(s0)
    sw t0, 0x30(s0)
    lw t0, 0x40(s0)
    sw t0, 0x50(s0)
    lw t0, 0x60(s0)
    sw t0, 0x70(s0)
    lw t0, 0x80(s0)
    sw t0, 0x90(s0)
    lw t0, 0xA0(s0)
    sw t0, 0xB0(s0)
    lw t0, 0xC0(s0)
    sw t0, 0xD0(s0)
    lw t0, 0xE0(s0)
    sw t0, 0xF0(s0)
}


Start:
    la t0, 0xBFC007FC   //
    la t1, 0x00000008   //
    sw t1, 0(t0)        // Enables PIF operation

    include "lib/graphics/print.inc" // Contains functions and macros
    
    // Set Compare register to avoid accidental interrupt flag (though this interrupt shouldn't be enabled at any point)
    la t0, 0xFFFFFFFF
    nop
    mtc0 t0, Compare
    nop
    
    SetupVI()
    SetupISR()
    
    
    ClearStorage(UNCACHED_WRITE_STORAGE)
    ClearStorage(CACHED_WRITE_STORAGE)
    
    TestStorage(UNCACHED_WRITE_STORAGE)
    TestStorage(CACHED_WRITE_STORAGE)
    
    
    // Clear counter data
    la t0, PRINT_ADDR
    sw zero, 0(t0)
    sw zero, 4(t0)
    
    
    // Start of main loop
Refresh:
    
    ClearBuffer()   // Clear fp framebuffer for new drawing
    
    
    //-------------------- Start printing stuff --------------------\\
    la t0, PRINT_ADDR     ////
    lw t1, 0(t0)            //
    addiu t1, t1, 8         //
    sw t1, 0(t0)          //// Increment value at PRINT_ADDR
    
    la t0, PRINT_ADDR
    PrintHexRegW(fp, COL1X, 10, t0, GoodFont, COLOR_WHITE)
    
    
    // UNCACHED_WRITE_STORAGE (in RDRAM)
    la s0, UNCACHED_WRITE_STORAGE
    PrepareHexRegW(fp, COL2X, 10, s0, GoodFont, COLOR_RED)
    addiu s1, zero, 15
UncachedWriteStoreLoop:
    jal Func_HexW
    nop
    addiu a1, a1, 0x10
    addiu a0, a0, 9 * SCREEN_WIDTH * BYTES_PER_PIXEL
    la t0, 0x000A0A00
    addu a3, a3, t0
    
    bne s1, zero, UncachedWriteStoreLoop
    addi s1, s1, -1
    
    
    // CACHED_WRITE_STORAGE (in RDRAM)
    la s0, CACHED_WRITE_STORAGE
    PrepareHexRegW(fp, COL3X, 10, s0, GoodFont, 0xFFAA00FF)
    addiu s1, zero, 15
CachedWriteStoreLoop:
    jal Func_HexW
    nop
    addiu a1, a1, 0x10
    addiu a0, a0, 9 * SCREEN_WIDTH * BYTES_PER_PIXEL
    la t0, 0x00040900
    addu a3, a3, t0
    
    bne s1, zero, CachedWriteStoreLoop
    addi s1, s1, -1
    //-------------------- Finished printing stuff --------------------//
    
    
    // Set BUF_FLAGS[0] and wait until next VI Interrupt (which will clear this bit flag).
    // Idea here is that the ISR will only clear the framebuffer if this loop has finished.
    SetReadyForSwap()
    WaitForVII()
    
    j Refresh
    nop
    
    
    
    
    
ALIGN(32)
    
ISR_Jump: // these two instructions are loaded into ISR Vector using SetupISR()
    j ISR_Exceptions
    nop
    
    

ISR_Exceptions: // ISR Handler // This will check BUF_FLAGS[0] to see if the screen finished rendering, and swap buffers if set.
    
    // Clear Cause register (should cover any exceptions that may have been raised)
    //addu s6, zero, zero
    //nop
    //mtc0 s6, Cause
    //nop
    
    
    la s6, BUF_FLAGS
    lw s6, 0(s6)
    la s7, 0x00000001
    and s5, s6, s7      // Get bit-0 and isolate it
    
    beq s5, zero, ISRE_BufferNotReady
    nop
    
//BufferIsReady
    SwapBuffer()
    
    la s7, 0xFFFFFFFE
    and s5, s6, s7
    la s7, BUF_FLAGS
    sw s5, 0(s7)        // Clear bit-0
    
ISRE_BufferNotReady:
    // Clear SI interrupt (though it shouldn't ever cause a jump to this ISR)
    la s7, 0xA4800018
    sw s7, 0(s7)
    
    // Clear PI interrupt (ditto)
    la s7, 0xA4600010
    la s6, 0x00000002
    sw s6, 0(s7)
    
    // Clear DP interrupt (ditto)
    la s7, 0xA4300000
    la s6, 0x00000800
    sw s6, 0(s7)
    
    // Clear SP interrupt (ditto)
    la s7, 0xA4040010
    la s6, 0x00000008
    sw s6, 0(s7)
    
    // Clear AI interrupt (ditto)
    la s7, 0xA450000C
    sw s7, 0(s7)
    
    // Clear VI interrupt
    la s7, 0xA4400010
    lw s6, 0(s7)
    nop
    sw s6, 0(s7)
    
    // Clear Cause register (should cover any exceptions that may have been raised)
    addu s6, zero, zero
    nop
    mtc0 s6, Cause
    nop
    
    
    eret
    nop
    
    
ALIGN(32)

insert GoodFont, "goodfont.bin"