# animeko-woa64

WOA64 workspace for coordinating changes across the Animeko fork stack.

This repository intentionally tracks only submodule pointers and coordination
files. The actual source trees are separate Git repositories:

- `animeko` -> `git@github.com:NihilDigit/animeko.git`, branch `woa`
- `mediamp` -> `git@github.com:NihilDigit/mediamp.git`, branch `woa`
- `anitorrent` -> `git@github.com:NihilDigit/anitorrent.git`, branch `woa`

Each submodule should stay on its own `woa` branch. Code changes made inside a
submodule are committed and pushed from that submodule repository, not from this
meta repository. This repository records the exact commit combination that is
known to work.

## Layout

```text
animeko-woa64/
  animeko      # submodule: NihilDigit/animeko, branch woa
  mediamp      # submodule: NihilDigit/mediamp, branch woa
  anitorrent   # submodule: NihilDigit/anitorrent, branch woa
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

To move every submodule to the latest commit on its configured `woa` branch:

```powershell
git submodule update --remote --merge
git status
```

Commit the resulting submodule pointer changes in this repository when the new
combination should be recorded.
