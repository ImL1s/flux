import 'package:flux_vm/flux_vm.dart';

void main() async {
  final vm = VM();
  vm.onPrint = (msg) => print('>>> $msg');

  const source = '''
    print("Direct call to http.get...");
    var resp = await http.get("https://jsonip.com");
    print("Status: " + toString(resp["status"]));
  ''';

  try {
    final result = await vm.interpret_async(source);
    print('DEBUG SCRIPT: Result=$result');
  } catch (e) {
    print('DEBUG SCRIPT: CAUGHT FATAL: $e');
  }
}
