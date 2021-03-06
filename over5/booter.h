/*************************************************************************
**
** booter.h (the object code of '6502/booter.asm')
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/
u_int8_t booter[]=
{
    0x78,0xA9,0xFF,0x85,0xAC,0xA9,0x60,0x8D,0x10,0x01,0x20,0x10,0x01,0xBA,0xCA,0xCA,
    0xBD,0x01,0x01,0x18,0x69,0x49,0x85,0xFB,0xBD,0x02,0x01,0x85,0xFC,0x90,0x02,0xE6,
    0xFC,0x38,0x20,0x99,0xFF,0x8A,0x38,0xE9,0x20,0x85,0xAE,0x8D,0x10,0x01,0x98,0xE9,
    0x04,0x85,0xAF,0x8D,0x11,0x01,0xA2,0x02,0xA0,0x01,0x88,0xB1,0xFB,0xC5,0xAC,0xD0,
    0x03,0x38,0xE5,0xAC,0x91,0xAE,0xC8,0xD0,0xF2,0xE6,0xFC,0xE6,0xAF,0xCA,0x10,0xEB,
    0x6C,0x10,0x01,0xEA,0xEA,0xAD,0x10,0x01,0x85,0xFD,0xAD,0x11,0x01,0x85,0xFE,0xA0,
    0x3F,0xA2,0x01,0xB1,0xFD,0x18,0x65,0xFD,0x85,0xFB,0xC8,0xB1,0xFD,0x10,0x02,0xA2,
    0x02,0x29,0x7F,0x65,0xFE,0x85,0xFC,0xC8,0x84,0xAC,0xA0,0x00,0xB1,0xFB,0x18,0x65,
    0xFD,0x91,0xFB,0x8A,0xA8,0xB1,0xFB,0x65,0xFE,0x91,0xFB,0xA4,0xAC,0xC0,0x61,0xD0,
    0xD0,0x4C,0x61,0x00,0x3D,0x00,0x63,0x80,0x67,0x00,0x7B,0x80,0x8A,0x00,0x91,0x00,
    0xB2,0x00,0xB9,0x00,0xC8,0x00,0xE9,0x00,0xEC,0x00,0xF3,0x80,0xF7,0x00,0x0D,0x81,
    0x11,0x01,0x14,0x01,0x28,0x01,0x58,0xA2,0x43,0xA0,0x01,0x20,0x16,0x01,0x20,0xCC,
    0xFF,0x20,0xE7,0xFF,0xA9,0x02,0xA2,0x02,0xA0,0x03,0x20,0xBA,0xFF,0xA9,0x02,0xA2,
    0x41,0xA0,0x01,0x20,0xBD,0xFF,0x20,0xC0,0xFF,0xA2,0x02,0x20,0xC6,0xFF,0x20,0x39,
    0x01,0xC9,0x53,0xD0,0xF9,0x20,0x39,0x01,0xC9,0x53,0xF0,0xF9,0x20,0xB7,0xFF,0xA9,
    0x00,0x85,0xAD,0x38,0x20,0x9C,0xFF,0x8A,0x18,0x69,0x01,0x85,0xAE,0x98,0x69,0x00,
    0x85,0xAF,0xA2,0x20,0xA0,0x00,0x20,0x27,0x01,0xC9,0x11,0xD0,0x14,0x20,0x27,0x01,
    0xC9,0x80,0xF0,0x0B,0xC9,0x11,0xF0,0x09,0xC9,0x01,0xF0,0x19,0x4C,0x0C,0x01,0xA9,
    0x00,0x91,0xAE,0xE6,0xAE,0xD0,0x02,0xE6,0xAF,0xCA,0xD0,0xDA,0xA9,0x23,0x20,0xD2,
    0xFF,0xA2,0x20,0xD0,0xD1,0xA5,0xAE,0x85,0x2D,0xA5,0xAF,0x85,0x2E,0x20,0x27,0x01,
    0x20,0x27,0x01,0xA5,0xAD,0xD0,0x1A,0xA2,0x6C,0xA0,0x01,0x20,0x16,0x01,0x20,0xCC,
    0xFF,0xA9,0x02,0x20,0xC3,0xFF,0xA9,0x80,0x20,0x90,0xFF,0xA2,0xFA,0x9A,0x6C,0x02,
    0x03,0xA2,0x52,0xA0,0x01,0x20,0x16,0x01,0x4C,0xF9,0x00,0x86,0xFB,0x84,0xFC,0xA0,
    0x00,0xB1,0xFB,0xF0,0x06,0x20,0xD2,0xFF,0xC8,0xD0,0xF6,0x60,0x20,0x39,0x01,0x48,
    0x18,0x65,0xAD,0x85,0xAD,0x20,0xB7,0xFF,0x29,0xF7,0xD0,0xD5,0x68,0x60,0x20,0xE4,
    0xFF,0xC9,0x00,0xF0,0xF9,0x60,0x07,0x00,0x0D,0x0D,0x2A,0x20,0x53,0x54,0x41,0x47,
    0x45,0x20,0x32,0x20,0x2A,0x0D,0x00,0x0D,0x3F,0x54,0x52,0x41,0x4E,0x53,0x46,0x45,
    0x52,0x20,0x20,0x45,0x52,0x52,0x4F,0x52,0x0D,0x52,0x45,0x41,0x44,0x59,0x2E,0x0D,
    0x00,0x0D,0x4F,0x4B,0x2C,0x20,0x4E,0x4F,0x57,0x20,0x53,0x41,0x56,0x45,0x20,0x54,
    0x4F,0x20,0x44,0x49,0x53,0x4B,0x21,0x0D,0x0D,0x52,0x45,0x41,0x44,0x59,0x2E,0x0D,
    0x00,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,
    0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA
};
/* eof */

