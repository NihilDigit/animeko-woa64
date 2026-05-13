# Repository Guidelines

## Project Structure & Module Organization

This repository is a WOA64 coordination workspace. The root repository should contain only documentation, workspace metadata, and submodule pointers. Product code lives in three forked submodules, each on `woa`:

- `animeko/`: Animeko desktop app and integration layer.
- `anitorrent/`: torrent native/JNI runtime.
- `mediamp/`: media playback libraries, including VLC and FFmpeg modules.

Make source changes in the owning submodule, commit there first, then update the root submodule pointer only when that submodule commit is ready. Do not copy source trees into the root repository.

## Build, Test, and Development Commands

Initialize or refresh all submodules:

```powershell
git submodule update --init --recursive
git submodule foreach git checkout woa
git submodule foreach git pull --ff-only
```

Common checks:

```powershell
cd anitorrent; .\gradlew.bat test
cd anitorrent; .\gradlew.bat :anitorrent-native:buildAnitorrent --no-configuration-cache
cd animeko; .\gradlew.bat :torrent:anitorrent:desktopTest
cd animeko; .\gradlew.bat :app:shared:compileKotlinDesktop --no-configuration-cache
cd mediamp; .\gradlew.bat test
```

Local Windows ARM64 work expects JBR/JCEF 21, VS Build Tools ARM64, CMake, Ninja, MSYS2, Android SDK, and `C:\vcpkg`. Keep `JAVA_HOME` pointed at the ARM64 JBR/JCEF. Anitorrent should use SWIG 4.2.1 via `anitorrent/local.properties`, for example `swigPath=C\:\\Codes\\animeko-woa64\\.tools\\swigwin-4.2.1\\swig.exe`.

## Coding Style & Naming Conventions

Follow each upstream repository's existing Kotlin, Gradle, C, and C++ style. Keep changes small enough to upstream independently. Use platform triples consistently: `windows-arm64`, `windows-x64`, `macos-arm64`, and `linux-x64`.

Minimize review diff. Do not upgrade upstream dependency versions, Gradle plugins, toolchain helpers, or generated code unless the WOA64 change requires it. Avoid opportunistic cleanup or hardening when existing upstream code already works. Avoid committing generated SWIG output, built jars, DLLs, IDE files, or local configuration. `local.properties` is for machine-specific paths only.

## Testing Guidelines

Run the narrowest relevant Gradle task in the submodule you changed, then run an Animeko smoke check when touching `anitorrent` or `mediamp`. Native changes must verify both build output and runtime library loading on Windows ARM64. If Animeko uses a local Anitorrent checkout, set `ani.build.anitorrent.path` in `animeko/local.properties`.

SQLite on Windows ARM64 is currently handled as an MVP runtime patch: build a small jar containing only `natives/windows_arm64/sqliteJni.dll` and point Animeko at it with `ani.build.sqlite.windows.arm64.jar`. Do not bump AndroidX SQLite or Room just to solve this runtime gap.

## Commit & Pull Request Guidelines

Use short imperative commit messages, for example `Add Windows ARM64 native target` or `Harden native build configuration`. Split work by upstream repository: Anitorrent native support, MediaMP runtime support, and Animeko integration should be separate commits and PRs.

PRs should describe the WOA64 behavior, list tested commands, and call out native/runtime risks such as JCEF, VLC, FFmpeg, SQLite, OpenSSL, or Android variant resolution.

## Agent-Specific Instructions

Before editing, check `git status -sb` in the root and affected submodule. Use `git -c safe.directory=<path>` if Git reports dubious ownership. Never reset or overwrite unrelated work. Keep root changes limited to this guide, `.gitmodules`, ignore rules, and submodule revisions.
