import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flux_compiler/flux_compiler.dart';

class BuildCommand extends Command {
  @override
  final String name = 'build';

  @override
  final String description =
      'Compiles a Flux script to bytecode (.flx) and generates source maps.';

  BuildCommand() {
    argParser.addOption('output',
        abbr: 'o', help: 'Output file path (default: <input>.flx)');
    argParser.addFlag('map',
        defaultsTo: true, help: 'Generate source map file');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      print('Usage: flux build <script.flux>');
      exit(64);
    }

    final inputPath = argResults!.rest.first;
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      print('Error: Input file could not be found: $inputPath');
      exit(1);
    }

    // Determine output path
    String outputPath = argResults!['output'] ?? '';
    if (outputPath.isEmpty) {
      outputPath = inputPath.replaceAll(RegExp(r'\.flux$'), '') + '.flx';
      if (outputPath == inputPath) outputPath += '.flx';
    }

    final generateMap = argResults!['map'] as bool;

    try {
      print('Compiling $inputPath...');
      final source = await inputFile.readAsString();

      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final unit = parser.parse();

      final compiler = Compiler(
          unit: unit, moduleName: inputPath, generateSourceMap: generateMap);

      // Retrieve compiled function
      // Note: Compiler(unit: unit) constructor triggers compilation of statements.
      // We call endCompiler() to finalize and get the function object.
      final function = compiler.endCompiler();

      // Serialize
      final serializer = BytecodeSerializer();
      final bytes = serializer.serialize(function);

      // Write binary
      File(outputPath).writeAsBytesSync(bytes);
      print('Built $outputPath (${bytes.length} bytes)');

      // Write Map
      if (generateMap && function.sourceMap != null) {
        final mapPath = '$outputPath.map';
        File(mapPath).writeAsStringSync(function.sourceMap!);
        print('Generated source map: $mapPath');
      }
    } catch (e) {
      print('Build error: $e');
      exit(1);
    }
  }
}
