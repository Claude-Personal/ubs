# Optimization and obfuscation reference

Use this matrix when explaining `./build.sh audit` results.

| Stack/output | Optimization coverage | Obfuscation coverage | Important caveat |
|---|---|---|---|
| Flutter AAB/APK/IPA | Release AOT, icon tree shaking | Adapter enforces `--obfuscate` and split debug info | Preserve symbol directories for crash analysis |
| Flutter Web | Release compiler and tree shaking | Not supported by the native Dart obfuscation option | Minified web code is not proof of obfuscation |
| Tauri Rust | Cargo release compilation; project may configure LTO/strip | Compiled native code, not guaranteed obfuscation | LTO and strip are reported separately |
| Tauri frontend | Framework production build when recognized | Optional lockfile-installed JS obfuscator only when configured | Keep `javascript-obfuscator` pinned locally; JS obfuscation can increase size or break runtime behavior |
| Android | R8/minify and resource shrinking when configured in release build type | R8 renaming when minify and rules are configured | Keep mapping files and test reflection/serialization |
| Kotlin/JVM/KMP/Gradle | Project-specific Gradle release tasks | Not automatic | Inspect each target and packaging plugin |
| React/Next/Node | Framework production minification/tree shaking when recognized | Not automatic | Minification and obfuscation are different guarantees |

## Status meanings

- `enforced`: the Universal Build adapter supplies the relevant option.
- `configured`: a recognizable project configuration was found.
- `framework-default`: delegated to a known production framework; verify its version and configuration.
- `compiled`: native release compilation was found, without an obfuscation guarantee.
- `recommended`: an optional hardening or size optimization is absent.
- `optional-off`: supported by the adapter but disabled by default.
- `not-configured`: the expected configuration was not detected.
- `not-supported`: the output does not support that mechanism.
- `unknown` or `project-specific`: static inspection cannot make a reliable claim.

The audit reads configuration files and adapter policy. It does not decompile, benchmark, sign-verify, malware-scan, reproduce, or execute the generated artifact. Describe it as advisory evidence rather than release certification.
