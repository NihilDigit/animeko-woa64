# Repository Guidelines

## Project Structure & Module Organization

This root repository is the WOA64 coordination workspace. Keep product code in the forked submodules and use the root for documentation, meta CI, helper scripts, release artifacts, and submodule pointers only.

- `anitorrent/`: native torrent/JNI runtime. Clean upstream PR branch: `pr/windows-arm64-native-runtime`.
- `animeko/`: final desktop integration and temporary WOA64 application build. Active workaround branch: `woa`.
- `.github/workflows/`: meta orchestration and release workflows for temporary WOA64 builds.
- `artifacts/`: ignored local downloads, unpacked builds, and release assets.

Do not copy upstream source trees into this repo. Commit code changes in the owning submodule, then update the root gitlink only when the root must pin that revision.

## Current Progress

Latest usable WOA64 release:

- Release: `woa64-25848780226`
- Asset: `Ani-woa64-25848780226-windows-aarch64-portable.zip`
- SHA256: `0447ff411e85bdbf88c9d4b2522fbfecaa8155582cda312428914ef546f5c581`

Clean PR branches:

- `anitorrent@pr/windows-arm64-native-runtime`: `f7ee4413`, single commit adding Windows ARM64 native runtime build and release publishing.
- `mediamp` Windows ARM64 FFmpeg runtime support is upstream in `open-ani/mediamp@v0.1.12`; this meta repo no longer tracks a mediamp submodule.

Temporary application branch:

- `animeko@woa`: based on upstream `v5.7.0`, with Windows ARM64 desktop build support, anitorrent mock Maven consumption, SQLite workaround, and final package verification.

The clean PR branches must not contain meta-only `workflow_dispatch`, mock Maven, or `animeko-woa64` orchestration comments.

## Build, Test, and Development Commands

Refresh submodules:

```powershell
git submodule update --init --recursive
```

Regenerate workflow YAML after editing `src.main.kts`:

```powershell
cd anitorrent; kotlin .github\workflows\src.main.kts
cd animeko; kotlin .github\workflows\src.main.kts
```

Validate generated YAML:

```powershell
uvx --with pyyaml python -c "import yaml, pathlib; [yaml.safe_load(pathlib.Path(p).read_text()) for p in ['.github/workflows/build.yml','.github/workflows/release.yml'] if pathlib.Path(p).exists()]"
```

Useful checks:

```powershell
git diff --check
gh run list --repo NihilDigit/anitorrent --branch pr/windows-arm64-native-runtime
```

## Coding Style & Constraints

Minimize upstream diff. Do not upgrade dependency versions, Gradle plugins, toolchain helpers, or generated code unless WOA64 strictly requires it. Avoid opportunistic cleanup, hardening, or style churn.

Keep code comments sparse. Put only durable maintenance facts in code, such as why a Windows ARM64 CI job skips full `check`. Put broader context, validation notes, OpenSSL/MSYS2 details, and known limitations in PR descriptions.

For temporary meta orchestration only, annotate removable CI plumbing with:

```text
WOA64 orchestration harness
```

Do not add that marker to clean upstream PR branches.

## Testing Guidelines

Run `git diff --check` in each touched submodule. Regenerate workflow YAML and parse it before pushing. Prefer narrow native/runtime tasks locally, then verify with GitHub-hosted Windows ARM64 runners.

Validated local tasks:

- anitorrent: `buildAnitorrent copyNativeJarForCurrentPlatform`

Animeko packaged verify currently covers anitorrent load/session smoke tests, mediamp FFmpeg smoke test, and SQLite bundled load test.

## Commit & PR Guidelines

Keep one logical commit per upstream PR branch and amend with `--force-with-lease` while preparing. PR descriptions should explain why Windows ARM64 jobs build runtime artifacts only, and call out runner/toolchain assumptions: vcpkg/OpenSSL for anitorrent and JBR/JCEF/SQLite/VLC risks for Animeko.
