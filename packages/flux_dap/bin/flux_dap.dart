import 'package:flux_dap/flux_dap.dart';

/// Entry point for the Flux Debug Adapter
///
/// Usage: dart run flux_dap
void main(List<String> args) async {
  final server = DapServer();
  await server.run();
}
