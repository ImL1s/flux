# Flux CLI Guide

The **Flux CLI** is the primary tool for developing, compiling, and running Flux applications.

## Installation

Assuming you have the Flux SDK installed:

```bash
# Add flux to your path or run via dart
dart pub global activate flux_cli
```

## Common Commands

### 1. Run a Script
Execute a Flux script directly from source:

```bash
flux run script.flux
```

### 2. Build to Bytecode
Compile a script into an optimized binary `.flx` file with Source Maps:

```bash
flux build script.flux -o output.flx
```
This generates:
- `output.flx`: The executable bytecode
- `output.flx.map`: Source map for debugging

### 3. Script Signing (Security)
Secure your scripts with Ed25519 signatures:

```bash
# Generate a new keypair
flux keygen

# Sign a script (creates signature footer)
flux sign script.flux --private-key private.key

# Verify a script's integrity
flux verify script.flux --public-key public.key
```

### 4. Development Server
Start a hot-reload capable development server:

```bash
flux serve main.flux
```

## Directory Structure
- `signing_demo/`: Examples for cryptographic signing
- `build_demo/`: Examples for compiling and optimizing
