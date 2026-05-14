# Repository Guidelines

## Project Structure & Module Organization

This root repository is the WOA64 coordination workspace. It should contain documentation, meta CI, helper scripts, and submodule pointers only. Product code belongs in the three forked submodules, all on `woa`:

- `anitorrent/`: native torrent/JNI runtime and Windows ARM64 native jar.
- `mediamp/`: FFmpeg runtime packaging and Windows ARM64 runtime jar.
- `animeko/`: desktop integration, JCEF/JBR wiring, and final app build.

Commit code in the owning submodule first, push its `woa` branch, then update the root submodule pointer. Do not copy upstream source trees into this repo.

## Current Progress

An earlier MVP WOA64 desktop prerelease exists, but it is superseded for
current work because the SQLite runtime workaround has been redesigned:

- Old prerelease: `woa64-20260514-25836218728`
- Old Animeko build run: `25836218728`
- Do not treat that release as PR-ready.

The three upstream PR branches are single squashed commits and have been force-pushed:

- `anitorrent@woa`: `f5cadfeb` Windows ARM64 native runtime support plus minimal CI dispatch/artifact harness.
- `mediamp@woa`: `138d6247` Windows ARM64 FFmpeg runtime target plus minimal CI dispatch/artifact harness.
- `animeko@woa`: `af56ffa5` Windows ARM64 desktop build support plus temporary mock Maven consumption for orchestrated CI.

The root meta repo uses `WOA64 CI Orchestrator` as the active path. It can run the full chain or reuse existing run ids, and can publish a prerelease when `publish_release=true`.

Current active validation:

- Meta orchestrator run: `25842367994`
- Triggered anitorrent run: `25842375087`
- Reuses mediamp run: `25830726716`
- The previous Animeko run `25841397983` failed in the SQLite patch step because Windows PowerShell did not load `System.IO.Compression`. `animeko@woa` now adds `Add-Type -AssemblyName System.IO.Compression` and should be revalidated by the active orchestrator.

## Build, Test, and Development Commands

Refresh submodules:

```powershell
git submodule update --init --recursive
git submodule foreach git checkout woa
git submodule foreach git pull --ff-only
```

Regenerate CI after editing workflow Kotlin scripts:

```powershell
cd anitorrent; kotlin .github\workflows\src.main.kts
cd mediamp; kotlin .github\workflows\src.main.kts
cd animeko; kotlin .github\workflows\src.main.kts
```

Validate YAML with:

```powershell
uvx --with pyyaml python -c "import yaml, pathlib; yaml.safe_load(pathlib.Path('.github/workflows/build.yml').read_text())"
```

Run the meta release path without rebuilding upstream repos:

```powershell
gh workflow run orchestrate-upstream-ci.yml --repo NihilDigit/animeko-woa64 `
  -f run_anitorrent=false -f run_mediamp=false -f run_animeko=true `
  -f animeko_run_id=<successful-animeko-run-id> -f publish_release=true
```

## Coding Style & Constraints

Minimize upstream diff. Do not upgrade dependency versions, Gradle plugins, toolchain helpers, or generated code unless WOA64 strictly requires it. Avoid opportunistic cleanup, hardening, or style churn.

Do not harden temporary orchestration workarounds unless they block the active CI path. The `workflow_dispatch`, mock Maven, and dispatch-only gating code is expected to be deleted or reshaped before final upstream PRs, so avoid coupling new behavior to it.

Temporary CI plumbing must be annotated with:

```text
WOA64 orchestration harness
```

This marks dispatch/mock/artifact code that should be removed or reshaped before final upstream PRs if it is not generally useful.

Keep release artifacts out of git. Local downloads and zips belong under ignored `artifacts/`.

## Testing Guidelines

Run `git diff --check` in each touched submodule. Prefer narrow Gradle tasks first, then use the meta orchestrator to exercise real GitHub runners. When a CI failure reveals a true PR issue, amend the relevant submodule’s single `woa` commit and force-push with `--force-with-lease`.

Packaged Animeko verify currently includes Windows ARM64 smoke tests for:

- `anitorrent-load-test`
- `anitorrent-session-smoke-test`
- `mediamp-ffmpeg-smoke-test`
- `sqlite-bundled-load-test`

SQLite source of truth is now Animeko CI only: `ci-helper/sqlite-woa64/patch-sqlite-bundled-windows-arm64.ps1` downloads pinned SQLite amalgamation plus AndroidX `sqlite_bindings.cpp`, verifies SHA256, compiles `sqliteJni.dll`, and injects `natives/windows_arm64/sqliteJni.dll`. The meta repo no longer carries or applies a prebuilt SQLite DLL.

## Commit & PR Guidelines

Keep one logical commit per upstream PR branch. Root commits should only update docs, meta workflows, scripts, or submodule gitlinks. PR descriptions should call out runtime risks: JCEF/JBR, VLC, FFmpeg, SQLite JNI, OpenSSL/vcpkg, MSYS2, and Windows ARM64 runner assumptions.
