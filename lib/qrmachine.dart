import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lzma/lzma.dart';

class QRRegisters {
  int r = 0, g = 0, b = 0, x = 0, y = 0, pc = 0;
  bool n = false, z = false, c = false;
  Rect get xyToRect =>
      Rect.fromLTRB(x as double, y as double, x as double, y as double);
  Color get rgbToColor => Color.fromRGBO(r, g, b, 1);
}

class QRStack {
  List<int> _list = [];
  void push(int i) => _list.add(i);
  int pop() => _list.removeLast();
}

class QRMemory {
  Uint8List rom, heap = Uint8List(8 * 1024 * 1024);

  QRMemory(this.rom);

  operator [](int i) {
    if (i < 1024 * 1024)
      return rom[i];
    else if (i < 9 * 1024 * 1024)
      return heap[i - 1024 * 1024];
    else
      return -1;
  }

  operator []=(int i, int val) {
    if (i < 1024 * 1024)
      rom[i] = val;
    else if (i < 9 * 1024 * 1024) heap[i - 1024 * 1024] = val;
  }
}

class QRMachine {
  QRMemory mem;
  QRRegisters regs = QRRegisters();
  QRStack stack = QRStack();
  Canvas framebuffer;
  int interruptVector = 0;

  QRMachine(Uint8List rom) : mem = QRMemory(lzma.decode(rom));

  int _decodefrompc() =>
      mem[regs.pc++] << 24 |
      mem[regs.pc++] << 16 |
      mem[regs.pc++] << 8 |
      mem[regs.pc++];

  void _store32(int addr, int val) {
    mem[addr++] = val >> 24;
    mem[addr++] = val >> 16;
    mem[addr++] = val >> 8;
    mem[addr] = val;
  }

  void interrupt(int id) {
    regs.r = id;
    regs.pc = interruptVector;
  }

  void cycle() {
    //instruction set:
    //opcode name desc
    //00     svc  sets the interrupt vector
    //01     ldr  sets the r register
    //02     ldg  sets the g register
    //03     ldb  sets the b register
    //04     ldx  sets the x register
    //05     ldy  sets the y register
    //06     zrr  zeros the r register
    //07     zrg  zeros the g register
    //08     zrb  zeros the b register
    //09     zrx  zeros the x register
    //0a     zry  zeros the y register
    //0b     str  stores the r register
    //0c     stg  stores the g register
    //0d     stb  stores the b register
    //0e     stx  stores the x register
    //0f     sty  stores the y register
    //10     xor  x ^= y
    //11     orx  x |= y
    //12     and  x &= y
    //13     phr  pushes the r register onto the stack
    //14     phg  pushes the g register onto the stack
    //15     phb  pushes the b register onto the stack
    //16     phx  pushes the x register onto the stack
    //17     phy  pushes the y register onto the stack
    //18     ppr  pops the r register from the stack
    //19     ppg  pops the g register from the stack
    //1a     ppb  pops the b register from the stack
    //1b     ppx  pops the x register from the stack
    //1c     ppy  pops the y register from the stack
    //1d     slr  shifts the r register one bit left
    //1e     slg  shifts the g register one bit left
    //1f     slb  shifts the b register one bit left
    //20     slx  shifts the x register one bit left
    //21     sly  shifts the y register one bit left
    //22     srr  shifts the r register one bit right
    //23     srg  shifts the g register one bit right
    //24     srb  shifts the b register one bit right
    //25     srx  shifts the x register one bit right
    //26     sry  shifts the y register one bit right
    //27     add  x += y
    //28     sub  x -= y
    //29     inx  x++
    //2a     jmp  sets the pc
    //2b     jsr  pushes the return address and sets the pc
    //2c     ret  pops the return address into pc
    //2d     beq  branches if the zero flag is set
    //2e     bne  branches if the zero flag is not set
    //2f     cmp  compares x and y
    //30     bof  branches if the carry flag is set
    //31     bno  branches if the carry flag is not set
    //32     bmi  branches if the negative flag is set
    //33     bpl  branches if the negative flag is not set
    //ea     nop  does nothing
    //fc     rst  "rest", hints that the program is currently spinning
    //fd     ver  sets the x register to the version of the vm
    //TODO: fe - native draw (framebuffer.drawRect(custom width and height), etc.)
    //ff     pxl  sets pixel at (x, y) to (r, g, b)
    switch (mem[regs.pc++]) {
      case 0x00:
        interruptVector = _decodefrompc();
        break;
      case 0x01:
        regs.r = _decodefrompc();
        break;
      case 0x02:
        regs.g = _decodefrompc();
        break;
      case 0x03:
        regs.b = _decodefrompc();
        break;
      case 0x04:
        regs.b = _decodefrompc();
        break;
      case 0x05:
        regs.b = _decodefrompc();
        break;
      case 0x06:
        regs.r = 0;
        break;
      case 0x07:
        regs.g = 0;
        break;
      case 0x08:
        regs.b = 0;
        break;
      case 0x09:
        regs.x = 0;
        break;
      case 0x0a:
        regs.y = 0;
        break;
      case 0x0b:
        _store32(_decodefrompc(), regs.r);
        break;
      case 0x0c:
        _store32(_decodefrompc(), regs.g);
        break;
      case 0x0d:
        _store32(_decodefrompc(), regs.b);
        break;
      case 0x0e:
        _store32(_decodefrompc(), regs.x);
        break;
      case 0x0f:
        _store32(_decodefrompc(), regs.y);
        break;
      case 0x10:
        regs.x ^= regs.y;
        break;
      case 0x11:
        regs.x |= regs.y;
        break;
      case 0x12:
        regs.x &= regs.y;
        break;
      case 0x13:
        stack.push(regs.r);
        break;
      case 0x14:
        stack.push(regs.g);
        break;
      case 0x15:
        stack.push(regs.b);
        break;
      case 0x16:
        stack.push(regs.x);
        break;
      case 0x17:
        stack.push(regs.y);
        break;
      case 0x18:
        regs.r = stack.pop();
        break;
      case 0x19:
        regs.g = stack.pop();
        break;
      case 0x1a:
        regs.b = stack.pop();
        break;
      case 0x1b:
        regs.x = stack.pop();
        break;
      case 0x1c:
        regs.y = stack.pop();
        break;
      case 0x1d:
        regs.r <<= 1;
        break;
      case 0x1e:
        regs.g <<= 1;
        break;
      case 0x1f:
        regs.b <<= 1;
        break;
      case 0x20:
        regs.x <<= 1;
        break;
      case 0x21:
        regs.y <<= 1;
        break;
      case 0x22:
        regs.r >>= 1;
        break;
      case 0x23:
        regs.g >>= 1;
        break;
      case 0x24:
        regs.b >>= 1;
        break;
      case 0x25:
        regs.x >>= 1;
        break;
      case 0x26:
        regs.y >>= 1;
        break;
      case 0x27:
        regs.x += regs.y;
        break;
      case 0x28:
        regs.x -= regs.y;
        break;
      case 0x29:
        regs.x++;
        break;
      case 0x2a:
        regs.pc = _decodefrompc();
        break;
      case 0x2b:
        var dst = _decodefrompc();
        stack.push(regs.pc);
        regs.pc = dst;
        break;
      case 0x2c:
        regs.pc = stack.pop();
        break;
      case 0x2d:
        if (regs.z) regs.pc = _decodefrompc();
        break;
      case 0x2e:
        if (!regs.z) regs.pc = _decodefrompc();
        break;
      case 0x2f:
        regs.n = regs.x < regs.y;
        regs.z = regs.x == regs.y;
        break;
      case 0x30:
        if (regs.c) regs.pc = _decodefrompc();
        break;
      case 0x31:
        if (!regs.c) regs.pc = _decodefrompc();
        break;
      case 0x32:
        if (regs.n) regs.pc = _decodefrompc();
        break;
      case 0x33:
        if (!regs.n) regs.pc = _decodefrompc();
        break;
      case 0xea:
        //yes, this is the nop
        break;
      case 0xfc:
        sleep(Duration(milliseconds: 1));
        break;
      case 0xfd:
        regs.x = -1;
        break;
      case 0xff:
        var p = Paint()
          ..color = regs.rgbToColor
          ..isAntiAlias = false;
        framebuffer.drawRect(regs.xyToRect, p);
        break;
    }
  }
}
