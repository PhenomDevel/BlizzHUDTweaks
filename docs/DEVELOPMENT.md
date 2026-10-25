# Development

## Layout

```
BlizzHUDTweaks/              addon folder (the only thing that gets installed)
  BlizzHUDTweaks.toc         load order, interface version, SavedVariables
  BlizzHUDTweaks.lua         AceAddon setup, profile defaults, frame mapping
  Options/                   options window, one file per page
  Libs/                      libraries (git-ignored except LibDeflate, see below)
  Media/                     icons
media-src/                   logo sources
docs/                        release process
.pkgmeta                     packaging config (BigWigs packager)
```

Settings are stored in `BlizzHUDTweaksDB` (AceDB profiles). Code layout and
conventions: [`CLAUDE.md`](../CLAUDE.md).

## Libraries

Release builds get Ace3, LibDataBroker and LibDBIcon from the `.pkgmeta`
externals; LibDeflate is committed. The others are git-ignored: for a git
checkout, copy them from `BlizzHUDTweaks/Libs/` of the latest release zip.

## Local setup

Link the addon folder into the client so `git pull` + `/reload` is enough. The
folder name must match the `.toc` name.

```powershell
# Windows – directory junction, no admin rights required
New-Item -ItemType Junction `
  -Path "D:\Games\World of Warcraft\_retail_\Interface\AddOns\BlizzHUDTweaks" `
  -Target "D:\Dev\BlizzHUDTweaks\BlizzHUDTweaks"
```

```bash
# macOS / Linux
ln -s "$PWD/BlizzHUDTweaks" "/Applications/World of Warcraft/_retail_/Interface/AddOns/BlizzHUDTweaks"
```

New files or `.toc` changes require a client restart instead of `/reload`.

## Checks

Lint: `luacheck .` (also runs in CI on every push). Functionality is verified
in-game; there are no automated tests.

## Release

Rename `## Unreleased` in `CHANGELOG.md` to `## vX.Y.Z (YYYY-MM-DD)`, merge
it, then run *Actions → Release → Run workflow* on `main` with the version
(`v3.4.0`, or `v3.4.0-beta1` / `-alpha1` for test releases). The workflow
tags the commit and uploads to CurseForge, Wago and GitHub. Details, including
the "What's new" notes and the local test build: [`RELEASE.md`](RELEASE.md)
(same process in all PhenomDevel addons).

## Interface version

The `.toc` lists `16001` (WoW: Forever) and the retail builds (`120105`,
`120107`). If a client shows the addon as out of date, read its value via
`/dump select(4, GetBuildInfo())` and add it to the comma-separated list.
