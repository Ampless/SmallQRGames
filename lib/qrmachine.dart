import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lzma/lzma.dart';

class QRRegisters {
  int r = 0, g = 0, b = 0, x = 0, y = 0, pc = 0, s = 0;
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
    //ea     nop  does nothing
    //TODO: fd - native draw (framebuffer.drawRect(custom width and height), etc.)
    //fe     ver  sets the r register to the version of the vm
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
      case 0xea:
        //yes, this is the nop
        break;
      case 0xfe:
        regs.r = -1;
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
