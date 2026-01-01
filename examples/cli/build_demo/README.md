# Build & Distribution Demo

This directory demonstrates compiling Flux source code into binary `.flx` files for distribution.

## Compiling

```bash
flux build app.flux -o app.flx
```

## Why Build?

1. **Performance**: Parsing `.flx` is faster than parsing source text.
2. **Obfuscation**: Source code is not directly exposed.
3. **Optimizations**: The compiler performs constant folding and dead code elimination.
4. **Source Maps**: Generates `.map` files for debugging compiled code.

## Running

The Flux VM can execute `.flx` files directly (when using the embedding API).
