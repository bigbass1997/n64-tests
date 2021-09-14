arch n64.cpu
endian msb
output "../SI-Test.z64", create
fill 0x00101000 // Set ROM Size // 1024 KB + 4 KB = 1028 KB = 0x00101000 bytes

origin 0x00000000
base 0x80000000

constant fp(s8) // frame pointer (being used as framebuffer pointer)
constant BUF_BASE_A(0xA0140000)
constant BUF_BASE_B(0xA0200000)
constant BUF_FLAGS(0xA03FFFFC)

constant SP_STORAGE(0xA03FFF00)

constant SCREEN_WIDTH(320)
constant SCREEN_HEIGHT(240)
constant BYTES_PER_PIXEL(4)
constant FONT_SPACING(1)

// RDRAM Addresses for printable values
constant PRINT_ADDR(0xA03FFE00)

include "lib/n64/header.asm"
include "lib/n64/n64.inc"
include "lib/n64/gfx.inc"
include "lib/graphics/colors.inc"
insert "lib/bin/n64_bootcode.bin"

macro ClearBuffer() {
    addu s4, zero, fp
    la s3, (BYTES_PER_PIXEL * SCREEN_WIDTH * SCREEN_HEIGHT)
    addu s4, s4, s3
    
    addu s3, zero, fp
    la s2, 0x222222FF
Clear:
    sw s2, 0(s3)
    bne s4, s3, Clear
    addi s3, s3, 4
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

// Set BUF_FLAGS[0] indicating main loop is done
macro SetReadyForSwap() {
    la t0, BUF_FLAGS
    lw t1, 0(t0)
    la t2, 0x00000001
    or t1, t1, t2
    sw t1, 0(t0)
}

// Wait for VI Interrupt to clear BUF_FLAGS[0]
macro WaitForVII() {
    la t0, BUF_FLAGS
WFVII_Loop:
    lw t1, 0(t0)
    andi t1, t1, 0x0001
    bne t1, zero, WFVII_Loop
    nop
}

macro SwapBuffer() {
    la sp, SP_STORAGE
    sd t0, 0(sp)
    sd t1, 8(sp)
    sd t2, 16(sp)

    la t0, 0xA4400004 // VI_ORIGIN
    sw fp, 0(t0)

    la t0, BUF_BASE_A
    beq t0, fp, SwapB_CurrentIs1
    nop

//CurrentIs2
    la fp, BUF_BASE_A

    j SwapB_End
    nop

SwapB_CurrentIs1:
    la fp, BUF_BASE_B


SwapB_End:
    ld t0, 0(sp)
    ld t1, 8(sp)
    ld t2, 16(sp)
}


macro SWOffset(value, temp_reg, offset, base_reg) {
    la {temp_reg}, {value}
    sw {temp_reg}, {offset}({base_reg})
}

macro SetupVI() {
    la fp, BUF_BASE_A // Sets framepointer CPU register
    
    la t0, 0xA4400000 // VI_BASE
    SWOffset(0x00003303, t1, VI_CTRL, t0)
    SWOffset(BUF_BASE_B, t1, VI_ORIGIN, t0)
    SWOffset(0x00000140, t1, VI_WIDTH, t0)
    SWOffset(0x00000208, t1, VI_V_INTR, t0)
    SWOffset(0x03E52239, t1, VI_TIMING, t0)
    SWOffset(0x0000020D, t1, VI_V_SYNC, t0)
    SWOffset(0x00000C15, t1, VI_H_SYNC, t0)
    SWOffset(0x0C150C15, t1, VI_H_SYNC_LEAP, t0)
    SWOffset(0x006C02EC, t1, VI_H_VIDEO, t0)
    SWOffset(0x002501FF, t1, VI_V_VIDEO, t0)
    SWOffset(0x000E0204, t1, VI_V_BURST, t0)
    SWOffset(0x00000200, t1, VI_X_SCALE, t0)
    SWOffset(0x00000400, t1, VI_Y_SCALE, t0)
    
    // Clear BUF_FLAGS
    la t0, BUF_FLAGS
    addu t1, zero, zero
    sw t1, 0(t0)
}


Start:
    // Set Compare register to avoid accidental interrupt flag (though this interrupt shouldn't be enabled at any point)
    la t0, 0xFFFFFFFF
    nop
    mtc0 t0, Compare
    nop
    
    SetupVI()
    SetupISR()
    
    
    // Clear counter data
    la t0, PRINT_ADDR
    sw zero, 0(t0)
    sw zero, 4(t0)
    
    include "lib/graphics/print.inc" // Contains functions and macros
    
    // Start of main loop
Refresh:
    
    // Clear fp framebuffer for new drawing
    ClearBuffer()
    
    
    //-------------------- Start printing stuff --------------------\\
    la t0, PRINT_ADDR     ////
    lw t1, 0(t0)            //
    addiu t1, t1, 8         //
    sw t1, 0(t0)          //// Increment value at PRINT_ADDR
    
    la t0, PRINT_ADDR
    PrintHexRegW(fp, 10, 10, t0, GoodFont, COLOR_WHITE)
    
    
    // PIF RAM
    la s0, 0xBFC007C0
    PrepareHexRegW(fp, 236, 10, s0, GoodFont, COLOR_RED)
    addiu s1, zero, 15
PIFLoop:
    jal Func_HexW
    nop
    addiu a1, a1, 4
    addiu a0, a0, 9 * SCREEN_WIDTH * BYTES_PER_PIXEL
    la t0, 0x00000F00
    addu a3, a3, t0
    
    bne s1, zero, PIFLoop
    addi s1, s1, -1
    
    
    // SI Registers
    la s0, 0xA4800000
    PrepareHexRegW(fp, 236, 160, s0, GoodFont, COLOR_DARKGREEN)
    addiu s1, zero, 5
SIRegLoop:
    jal Func_HexW
    nop
    addiu a1, a1, 4
    addiu a0, a0, 9 * SCREEN_WIDTH * BYTES_PER_PIXEL
    la t0, 0x2F0F1F00
    addu a3, a3, t0
    
    bne s1, zero, SIRegLoop
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