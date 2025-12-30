import 'package:test/test.dart';
import 'package:flux_compiler/src/bytecode.dart';

void main() {
  test('print opcode length', () {
    print('OpCode length: ${OpCode.values.length}');
    print('OpCode.lessEqual index: ${OpCode.lessEqual.index}');
  });
}
