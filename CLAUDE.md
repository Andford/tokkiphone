# Tokkip Phone — guide for AI coding agents

Andy's (LoperStack) Tokkip Phone: his Android phone and his PC working as one
(notifications, messages, calls, clipboard, files, photos, mirroring, phone
apps in windows). Part of the Tokkip family (Andford/tokkip). Spanish first
(Mexican, de tú), English too. For Andy's own use; not published.

It is a fork of NectarLink (thtbee/nectarlink): **its engine, our face**. The
Rust core (`core/`), the protocol, mirroring, the virtual camera and the
platform code stay NectarLink's; what people see is Tokkip's: name, design
(Material 3 Expressive like Tokkip PC: Tokkip's colours, Fredoka and Roboto
Flex, the shapes), Tokkip himself, and Spanish. We maintain it ourselves; fixes
from NectarLink are brought over by hand when they matter.

## Where things are
- `core/` — the shared Rust engine (MPL-2.0): `nectarlink-core`, `-protocol`, `-adb`, `-ffi` (UniFFI for Android), `-cli`.
- `desktop/app/` — the PC app: Qt Quick (QML in `qml/`) + Rust (`src/`, bridged with cxx-qt). Theme in `qml/Theme.qml` and `qml/Tokens.qml` (generated from `docs/design/tokens.json` by `cargo xtask tokens`). Icon drawn by `src/mark.rs` from `assets/brand/tokkip-256.rgba`.
- `desktop/installer/` — the NSIS installer. `desktop/vcam/` — the virtual camera.
- `android/app/` — the Android app: Kotlin + Compose + Material 3 Expressive (`ui/theme/`).
- Translations: desktop `desktop/app/i18n/*.ts` (Qt Linguist; `cargo xtask strings` regenerates `rust_strings.h` from Rust `tr!`), Android `res/values-*/strings.xml`.

## Rules
- Licenses stay: apps GPL-3.0-or-later, `core/` MPL-2.0, SPDX header on every source file (`scripts/check-headers.ps1`). Credit NectarLink in About and README.
- Never "NectarLink" or Bee's mark in what users see. Internal names (`nectarlink_core`, `app.nectarlink.android` packages, the QML module `app.nectarlink`, kernel object names) stay unless renaming them is the task.
- App identifiers: Android `mx.loperstack.tokkiphone`. Updates come from Andford/tokkiphone releases only.
- Generated files must stay current: `cargo xtask tokens --check`, `cargo xtask strings --check`.
- Commits as Andy (`soportemacrobit001@gmail.com`).

## Check
CI (`.github/workflows/ci.yml`, on push to main) runs the core tests, the Windows app (clippy, tests, QML tests, installer) and the Android build.
