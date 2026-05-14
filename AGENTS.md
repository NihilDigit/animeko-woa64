# Repository Guidelines

## Project Structure & Module Organization

This root repository is the WOA64 coordination workspace. It should contain documentation, meta CI, helper scripts, and submodule pointers only. Product code belongs in the three forked submodules, all on `woa`:

- `anitorrent/`: native torrent/JNI runtime and Windows ARM64 native jar.
- `mediamp/`: FFmpeg runtime packaging and Windows ARM64 runtime jar.
- `animeko/`: desktop integration, JCEF/JBR wiring, and final app build.

Commit code in the owning submodule first, push its `woa` branch, then update the root submodule pointer. Do not copy upstream source trees into this repo.

## Current Progress

MVP WOA64 desktop release is available as a prerelease:

- Release: `woa64-20260514-25834606829`
- Meta orchestrator run: `25834599212`
- Animeko build run: `25834606829`
- Validated: build, desktop package upload, Anitorrent load check, and local launch smoke test.

The three upstream PR branches are single squashed commits and have been force-pushed:

- `anitorrent@woa`: Windows ARM64 native runtime support plus minimal CI dispatch/artifact harness.
- `mediamp@woa`: Windows ARM64 FFmpeg runtime target plus minimal CI dispatch/artifact harness.
- `animeko@woa`: Windows ARM64 desktop build support plus temporary mock Maven consumption for orchestrated CI.

The root meta repo uses `WOA64 CI Orchestrator` as the active path. It can run the full chain or reuse existing run ids, and can publish a prerelease when `publish_release=true`.

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

Temporary CI plumbing must be annotated with:

```text
WOA64 orchestration harness
```

This marks dispatch/mock/artifact code that should be removed or reshaped before final upstream PRs if it is not generally useful.

Keep release artifacts out of git. Local downloads and zips belong under ignored `artifacts/`.

## Testing Guidelines

Run `git diff --check` in each touched submodule. Prefer narrow Gradle tasks first, then use the meta orchestrator to exercise real GitHub runners. When a CI failure reveals a true PR issue, amend the relevant submodule’s single `woa` commit and force-push with `--force-with-lease`.

## Commit & PR Guidelines

Keep one logical commit per upstream PR branch. Root commits should only update docs, meta workflows, scripts, or submodule gitlinks. PR descriptions should call out runtime risks: JCEF/JBR, VLC, FFmpeg, SQLite JNI, OpenSSL/vcpkg, MSYS2, and Windows ARM64 runner assumptions.
