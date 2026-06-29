# animeko-woa64

WOA64 workspace for coordinating temporary Windows ARM64 Animeko builds.

This repository intentionally tracks only submodule pointers and coordination
files. The actual source trees are separate Git repositories:

- `animeko` -> `git@github.com:NihilDigit/animeko.git`, branch `woa`
- `anitorrent` -> `git@github.com:NihilDigit/anitorrent.git`, branch `pr/windows-arm64-native-runtime`

Each submodule should stay on its configured branch. Code changes made inside a
submodule are committed and pushed from that submodule repository, not from this
meta repository. This repository records the exact commit combination that is
known to work.

## Layout

```text
animeko-woa64/
  animeko      # submodule: NihilDigit/animeko, branch woa
  anitorrent   # submodule: NihilDigit/anitorrent, branch pr/windows-arm64-native-runtime
```

## Clone

```powershell
git clone --recurse-submodules git@github.com:NihilDigit/animeko-woa64.git
```

If the repository was cloned without submodules:

```powershell
git submodule update --init --recursive
```

## Update Submodules

To move every submodule to the latest commit on its configured branch:

```powershell
git submodule update --remote --merge
git status
```

Commit the resulting submodule pointer changes in this repository when the new
combination should be recorded.
