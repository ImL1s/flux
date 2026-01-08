# Flux CLI (flux_lang_cli)

[漢文文檔](README_ZH.md)

[![pub package](https://img.shields.io/pub/v/flux_lang_cli.svg)](https://pub.dev/packages/flux_lang_cli)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Command-line interface for the Flux scripting language.

## Installation

### Global Activation (Recommended)

```bash
# From the flux_cli package directory
cd packages/flux_cli
dart pub global activate --source path .

# Now you can use 'flux' globally
flux --help
```

### Local Execution

```bash
# From the flux_cli directory
dart run flux_cli:flux <command>
```

## Commands

### `flux create` - Project Scaffolding

Create a new Flux project from a template.

```bash
flux create <project-name> [options]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `-t, --template` | Template to use: `basic`, `flutter`, `server` | `basic` |
| `-f, --force` | Overwrite existing directory | `false` |

**Examples:**
```bash
# Create a basic Flux project
flux create my_app

# Create a Flutter UI project
flux create my_flutter_app --template flutter

# Create a server-side project
flux create my_server --template server

# Overwrite existing directory
flux create my_app --force
```

**Generated Files:**
- `main.flux` - Entry point script
- `flux.yaml` - Project configuration
- `README.md` - Project documentation

---

### `flux run` - Script Execution

Run a Flux script with optional hot-reload.

```bash
flux run <file.flux> [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-w, --watch` | Watch for file changes and re-run automatically |
| `-v, --verbose` | Show verbose output |

**Examples:**
```bash
# Run a script once
flux run main.flux

# Run with hot-reload (re-runs on file change)
flux run main.flux --watch

# Run with verbose output
flux run main.flux --verbose
```

---

### `flux analyze` - Static Analysis

Analyze Flux scripts for errors and warnings.

```bash
flux analyze <file-or-directory> [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-v, --verbose` | Show info messages |
| `--fatal-warnings` | Treat warnings as errors |

**Examples:**
```bash
# Analyze a single file
flux analyze main.flux

# Analyze all .flux files in a directory
flux analyze ./src/

# Strict mode (warnings = errors)
flux analyze . --fatal-warnings
```

---

### `flux build` - Compile to Bytecode

Compile a Flux script to bytecode (.flx).

```bash
flux build <file.flux> [options]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-o, --output` | Output file path |

**Examples:**
```bash
flux build main.flux
flux build main.flux -o dist/app.flx
```

---

### `flux serve` - Development Server

Serve a Flux script for Flutter clients.

```bash
flux serve <file.flux> [options]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `-p, --port` | Server port | `8765` |
| `-w, --watch` | Watch for changes | `false` |

**Examples:**
```bash
flux serve app.flux
flux serve app.flux --port 3000 --watch
```

---

### `flux dev` - Development Mode

Run a development server with file watching.

```bash
flux dev [directory] [port]
```

**Examples:**
```bash
flux dev
flux dev ./scripts 8080
```

---

### Security Commands

#### `flux keygen` - Generate Key Pair
Generate an Ed25519 key pair for script signing.

```bash
flux keygen
```

#### `flux sign` - Sign Script
Sign a Flux script with a private key.

```bash
flux sign <file.flux> --key <private.pem>
```

#### `flux verify` - Verify Signature
Verify a signed Flux script.

```bash
flux verify <file.flux> --key <public.pem>
```

---

## Project Templates

### Basic Template
Simple console application:
```
my_app/
├── main.flux      # Entry point
├── flux.yaml      # Configuration
└── README.md
```

### Flutter Template
Flutter UI application with FluxUI components:
```
my_flutter_app/
├── main.flux      # UI with FluxButton, FluxColumn, etc.
├── flux.yaml      # type: flutter
└── README.md
```

### Server Template
Server-side request handler:
```
my_server/
├── main.flux      # HTTP request handler
├── flux.yaml      # type: server, port: 8080
└── README.md
```

---

## Configuration (flux.yaml)

```yaml
name: my_project
version: 1.0.0
description: A Flux project

entry: main.flux
type: basic  # basic, flutter, or server

# Server-only options
port: 8080
```

---

## Version

```bash
flux --version
# Flux CLI v2.0.0
```
