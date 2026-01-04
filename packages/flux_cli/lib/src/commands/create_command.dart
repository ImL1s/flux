import 'dart:io';
import 'package:args/command_runner.dart';

/// Command to create a new Flux project from templates
class CreateCommand extends Command<void> {
  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Flux project from a template';

  CreateCommand() {
    argParser
      ..addOption(
        'template',
        abbr: 't',
        help: 'Project template to use',
        allowed: ['basic', 'flutter', 'server'],
        defaultsTo: 'basic',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing directory',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final args = argResults!;
    
    if (args.rest.isEmpty) {
      usageException('Please provide a project name');
    }
    
    final projectName = args.rest.first;
    final template = args['template'] as String;
    final force = args['force'] as bool;
    
    final projectDir = Directory(projectName);
    
    if (projectDir.existsSync() && !force) {
      stderr.writeln('Error: Directory "$projectName" already exists.');
      stderr.writeln('Use --force to overwrite.');
      exit(1);
    }
    
    print('Creating Flux project "$projectName" with template "$template"...');
    
    // Create project directory
    if (!projectDir.existsSync()) {
      projectDir.createSync(recursive: true);
    }
    
    // Generate files based on template
    switch (template) {
      case 'basic':
        await _createBasicTemplate(projectDir, projectName);
        break;
      case 'flutter':
        await _createFlutterTemplate(projectDir, projectName);
        break;
      case 'server':
        await _createServerTemplate(projectDir, projectName);
        break;
    }
    
    print('');
    print('✅ Project created successfully!');
    print('');
    print('Next steps:');
    print('  cd $projectName');
    print('  flux run main.flux');
  }

  Future<void> _createBasicTemplate(Directory dir, String name) async {
    // Create main.flux
    final mainFlux = File('${dir.path}/main.flux');
    await mainFlux.writeAsString('''
// $name - A Flux Project
// Created with: flux create $name --template basic

fn main() {
  print("Hello from $name!");
}

main();
''');

    // Create flux.yaml config
    final config = File('${dir.path}/flux.yaml');
    await config.writeAsString('''
name: $name
version: 1.0.0
description: A Flux project

entry: main.flux
''');

    // Create README
    final readme = File('${dir.path}/README.md');
    await readme.writeAsString('''
# $name

A Flux project.

## Getting Started

```bash
flux run main.flux
```

## Project Structure

- `main.flux` - Main entry point
- `flux.yaml` - Project configuration
''');

    print('  Created: main.flux');
    print('  Created: flux.yaml');
    print('  Created: README.md');
  }

  Future<void> _createFlutterTemplate(Directory dir, String name) async {
    // Create main.flux with UI components
    final mainFlux = File('${dir.path}/main.flux');
    await mainFlux.writeAsString('''
// $name - A Flux Flutter Project
// Created with: flux create $name --template flutter

// Counter state
var counter = 0;

fn increment() {
  counter = counter + 1;
  rebuild();
}

fn render() {
  return Column(
    mainAxisAlignment: "center",
    children: [
      Text("Counter: " + counter.toString()),
      SizedBox(height: 16),
      FluxButton(
        label: "Increment",
        onTap: increment
      )
    ]
  );
}

render();
''');

    // Create flux.yaml config
    final config = File('${dir.path}/flux.yaml');
    await config.writeAsString('''
name: $name
version: 1.0.0
description: A Flux Flutter project

entry: main.flux
type: flutter
''');

    // Create README
    final readme = File('${dir.path}/README.md');
    await readme.writeAsString('''
# $name

A Flux Flutter project with UI components.

## Getting Started

1. Start the dev server:
   ```bash
   flux serve main.flux
   ```

2. In your Flutter app, connect to the Flux server.

## Project Structure

- `main.flux` - Main UI entry point
- `flux.yaml` - Project configuration
''');

    print('  Created: main.flux');
    print('  Created: flux.yaml');
    print('  Created: README.md');
  }

  Future<void> _createServerTemplate(Directory dir, String name) async {
    // Create main.flux for server-side logic
    final mainFlux = File('${dir.path}/main.flux');
    await mainFlux.writeAsString('''
// $name - A Flux Server Project
// Created with: flux create $name --template server

import "http";

fn handleRequest(request) {
  var path = request.path;
  
  if (path == "/") {
    return {
      "status": 200,
      "body": "Welcome to $name!"
    };
  }
  
  if (path == "/api/hello") {
    return {
      "status": 200,
      "contentType": "application/json",
      "body": { "message": "Hello from Flux!" }
    };
  }
  
  return {
    "status": 404,
    "body": "Not Found"
  };
}

// Export handler
handleRequest;
''');

    // Create flux.yaml config
    final config = File('${dir.path}/flux.yaml');
    await config.writeAsString('''
name: $name
version: 1.0.0
description: A Flux server project

entry: main.flux
type: server
port: 8080
''');

    // Create README
    final readme = File('${dir.path}/README.md');
    await readme.writeAsString('''
# $name

A Flux server project.

## Getting Started

```bash
flux serve main.flux --port 8080
```

## API Endpoints

- `GET /` - Welcome message
- `GET /api/hello` - JSON response

## Project Structure

- `main.flux` - Request handler
- `flux.yaml` - Project configuration
''');

    print('  Created: main.flux');
    print('  Created: flux.yaml');
    print('  Created: README.md');
  }
}
