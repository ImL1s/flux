# Script Signing Demo

This directory demonstrates ensuring code integrity using Flux's digital signature system.

## Steps

1. **Generate Keys**:
   ```bash
   flux keygen
   ```
   This creates `private.key` and `public.key`.

2. **Write a Script**:
   Create `secure.flux`:
   ```flux
   print("This is a trusted script.");
   ```

3. **Sign the Script**:
   ```bash
   flux sign secure.flux -k private.key
   ```
   This appends a secure footer to `secure.flux`.

4. **Verify**:
   ```bash
   flux verify secure.flux -p public.key
   ```
   Should output: `Verification SUCCESS`.

5. **Tamper Test**:
   Modify `secure.flux` manually, then run verify again to see it fail.
