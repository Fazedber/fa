# Reproducible Build Matrix for NexusVPN

Source of truth for CI/CD environments and local toolchains to prevent version drift.

## Toolchain Requirements
| Tool / Component | Version Restriction | Platform Target |
|---|---|---|
| **Golang** | `1.22.0` (Strict) | All Core modules |
| **Gomobile Builder** | `v0.0.0-20231127183840-76ac6878022f` | Android/macOS bindings (`CGO_ENABLED=1`) |
| **JDK/Java** | `temurin:17` | Android Studio & CI Runtime |
| **Android AGP** | `8.2.0` | Android App Shell |
| **.NET SDK**| `8.0` (VS 2022 v17.9+) | Windows App Shell (`net8.0-windows10.0.19041.0`) |
| **macOS SDK** | `Xcode 15.2` (macOS 14.2+) | macOS NetworkExtension App Target |

## Checksum Enforcement
In CI pipelines, module downloads must strictly adhere to `go.sum`. Unpinned (`@latest`) fetches during pipeline triggers are completely restricted. `go mod verify` is enforced.

## Deterministic Output Command
Standard production builds enforce `-trimpath` and `-buildvcs=false`. This ensures that two builds triggered on identical checkouts across separate Linux/macOS runners result in perfectly matching SHA-256 byte outputs.
