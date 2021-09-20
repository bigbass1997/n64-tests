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
