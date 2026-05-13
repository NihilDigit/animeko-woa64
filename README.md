# animeko-woa64

WOA64 workspace for coordinating changes across the Animeko fork stack.

This repository intentionally tracks only links and coordination files. The
actual source trees live under `.worktrees/` and are separate Git repositories:

- `animeko` -> `.worktrees/animeko`
- `mediamp` -> `.worktrees/mediamp`
- `anitorrent` -> `.worktrees/anitorrent`

Each linked repository should stay on its own `woa` branch. Code changes made
through the links are committed and pushed from the corresponding repository,
not from this meta repository.

## Layout

```text
animeko-woa64/
  animeko      -> .worktrees/animeko
  mediamp      -> .worktrees/mediamp
  anitorrent   -> .worktrees/anitorrent
  .worktrees/  # ignored, contains real clones
```

## Recreate Links

On Windows PowerShell:

```powershell
New-Item -ItemType SymbolicLink -Path animeko -Target .worktrees\animeko
New-Item -ItemType SymbolicLink -Path mediamp -Target .worktrees\mediamp
New-Item -ItemType SymbolicLink -Path anitorrent -Target .worktrees\anitorrent
```

