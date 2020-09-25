import 'dart:convert';
import 'dart:io';

const lut = {
  'svc': 0x00, //sets the interrupt vector
  'ldr': 0x01, //sets the r register
  'ldg': 0x02, //sets the g register
  'ldb': 0x03, //sets the b register
  'ldx': 0x04, //sets the x register
  'ldy': 0x05, //sets the y register
  'zrr': 0x06, //zeros the r register
  'zrg': 0x07, //zeros the g register
  'zrb': 0x08, //zeros the b register
  'zrx': 0x09, //zeros the x register
  'zry': 0x0a, //zeros the y register
  'str': 0x0b, //stores the r register
  'stg': 0x0c, //stores the g register
  'stb': 0x0d, //stores the b register
  'stx': 0x0e, //stores the x register
  'sty': 0x0f, //stores the y register
  'xor': 0x10, //x ^= y
  'orx': 0x11, //x |= y
  'and': 0x12, //x &= y
  'phr': 0x13, //pushes the r register onto the stack
  'phg': 0x14, //pushes the g register onto the stack
  'phb': 0x15, //pushes the b register onto the stack
  'phx': 0x16, //pushes the x register onto the stack
  'phy': 0x17, //pushes the y register onto the stack
  'ppr': 0x18, //pops the r register from the stack
  'ppg': 0x19, //pops the g register from the stack
  'ppb': 0x1a, //pops the b register from the stack
  'ppx': 0x1b, //pops the x register from the stack
  'ppy': 0x1c, //pops the y register from the stack
  'slr': 0x1d, //shifts the r register one bit left
  'slg': 0x1e, //shifts the g register one bit left
  'slb': 0x1f, //shifts the b register one bit left
  'slx': 0x20, //shifts the x register one bit left
  'sly': 0x21, //shifts the y register one bit left
  'srr': 0x22, //shifts the r register one bit right
  'srg': 0x23, //shifts the g register one bit right
  'srb': 0x24, //shifts the b register one bit right
  'srx': 0x25, //shifts the x register one bit right
  'sry': 0x26, //shifts the y register one bit right
  'add': 0x27, //x += y
  'sub': 0x28, //x -= y
  'inx': 0x29, //x++
  'jmp': 0x2a, //sets the pc
  'jsr': 0x2b, //pushes the return address and sets the pc
  'ret': 0x2c, //pops the return address into pc
  'beq': 0x2d, //branches if the zero flag is set
  'bne': 0x2e, //branches if the zero flag is not set
  'cmp': 0x2f, //compares x and y
  'bof': 0x30, //branches if the carry flag is set
  'bno': 0x31, //branches if the carry flag is not set
  'bmi': 0x32, //branches if the negative flag is set
  'bpl': 0x33, //branches if the negative flag is not set
  'nop': 0xea, //does nothing
  'rst': 0xfc, //"rest", hints that the program is currently spinning
  'ver': 0xfd, //sets the x register to the version of the vm
  'pxl': 0xff, //sets pixel at (x, y) to (r, g, b)
};

class Token {
  bool isLabel;
  int opcodeOrData;
  String label;
  Token(this.isLabel, this.opcodeOrData, this.label);
}

write32(RandomAccessFile output, int i) {
  output.writeByteSync(i >> 24);
  output.writeByteSync(i >> 16);
  output.writeByteSync(i >> 8);
  output.writeByteSync(i);
}

main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart assembler.dart [input] [output]');
    return;
  }
  var tokens = <Token>[];
  var labels = <String, int>{};
  var pc = 0;
  final output = File(args[1]).openSync(mode: FileMode.write);
  final input = await File(args[0])
      .openRead()
      .map(utf8.decode)
      .transform(LineSplitter())
      .toList();

  input.forEach((line) {
    if (line.length == 0) return;
    var i = 0;
    while (i < line.length && (line[i] == '\t' || line[i] == ' ')) i++;
    final j = i;
    while (i < line.length &&
        line[i] != '\t' &&
        line[i] != ' ' &&
        line[i] != ':') i++;
    final instruction = line.substring(j, i);
    while (i < line.length && (line[i] == '\t' || line[i] == ' ')) i++;
    if (i < line.length && line[i] == ':') {
      labels[instruction] = pc;
    } else {
      for (final insn in lut.keys) {
        if (insn == instruction) {
          tokens.add(Token(false, lut[insn], null));
          pc++;
        }
      }
      if ([
        'svc',
        'ldr',
        'ldg',
        'ldb',
        'ldx',
        'ldy',
        'str',
        'stg',
        'stb',
        'stx',
        'sty',
        'jmp',
        'jsr',
        'beq',
        'bne',
        'bof',
        'bno',
        'bmi',
        'bpl',
      ].contains(instruction)) {
        if (!['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
            .contains(line[i])) {
          write32(tokens, labels[line.substring(i)]);
          pc += 4;
        } else {
          write32(output, int.parse(line.substring(i)));
          pc += 4;
        }
      }
    }
  });
}
