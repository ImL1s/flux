# Security Guide

[漢文文檔](security_ZH.md)

## Script Signing

Flux supports Ed25519 digital signatures to ensure script integrity.

### Why Sign Scripts?

- **Integrity**: Detect if scripts have been modified
- **Authentication**: Verify scripts come from trusted source
- **Production Safety**: Prevent execution of unauthorized code

## Setup

### Generate Key Pair

```bash
flux keygen --output ./keys
```

This creates:
- `keys/private.pem` - Keep secret, used for signing
- `keys/public.pem` - Distribute with app, used for verification

### Sign a Script

```bash
flux sign script.flux --key keys/private.pem --output script.signed.flux
```

### Verify Signature

```bash
flux verify script.signed.flux --key keys/public.pem
```

## Flutter Integration

### Embed Public Key

```dart
const publicKey = '''
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEA...
-----END PUBLIC KEY-----
''';
```

### Verify Before Execution

```dart
import 'package:flux_vm/flux_vm.dart';

final verifier = FluxScriptVerifier(publicKey: publicKey);

void runSignedScript(String signedContent) {
  if (!verifier.verify(signedContent)) {
    throw SecurityException('Script signature invalid');
  }
  
  // Extract script content (before signature)
  final script = verifier.extractContent(signedContent);
  
  final vm = VM();
  vm.interpret(script);
}
```

## Signed Script Format

```
// Original script content
var x = 1;
print(x);

// --- FLUX SIGNATURE ---
// ed25519:ABC123...XYZ789
```

## Best Practices

### Key Management

1. **Never commit private keys** to version control
2. **Use environment variables** or secrets manager
3. **Rotate keys periodically**
4. **Use separate keys** for development and production

### Runtime Security

```dart
// Create a sandboxed VM
final vm = VM();

// Don't register sensitive modules
// vm.registerModule(fileSystemModule);  // DON'T

// Limit what scripts can access
vm.registerModule(safeModule);
```

### Input Validation

```dart
// Validate any values returned from Flux
final result = vm.getGlobal('userInput');

if (result is! String || result.length > 100) {
  throw ValidationException('Invalid input');
}
```

## Threat Model

| Threat | Mitigation |
|--------|------------|
| Malicious script execution | Signature verification |
| Script tampering | Ed25519 signatures |
| Resource exhaustion | Execution timeouts (planned) |
| Sensitive data access | Module sandboxing |

## Debugging vs Production

| Feature | Debug | Production |
|---------|-------|------------|
| Signature check | Optional | Required |
| Source maps | Included | Stripped |
| Debug symbols | Included | Stripped |
| .flx format | Optional | Recommended |
