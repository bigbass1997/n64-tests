// This header code written by PeterLemon https://github.com/PeterLemon/N64
//
// N64 Header

db $80
db $37
db $12
db $40

// Clock Rate
dw $0000000F

dw Start
dw $1444
db "CRC1"
db "CRC2"

dd 0

db   "Timing-ReadsWrites-Test    "
//   "123456789012345678901234567"

db $00 // Dev Id
db $00 // Cart Id
db $00 
db $00
db $00