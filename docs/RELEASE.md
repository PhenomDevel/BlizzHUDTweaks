# Release

All PhenomDevel addons (PhenomRaidTools, BlizzHUDTweaks, Quality of Life
Forever, Guild Finder Forever) are released the same way. This file,
`.github/workflows/release.yml` and `.github/workflows/ci.yml` are kept
identical across the repositories; only the last section of this file and the
`env` block of `release.yml` differ. Change them in all four at once.

## Versions

- Tags are `vMAJOR.MINOR.PATCH`; test releases add `-alphaN` or `-betaN`
  (`v1.4.0-beta1`). Nothing else is accepted.
- Patch: fixes only. Minor: new or changed features. Major: breaking changes
  (removed features, SavedVariables migrations users have to know about).
- The packager writes the tag into `## Version: @project-version@` and marks
  `-alpha`/`-beta` uploads as alpha/beta on CurseForge and Wago.

## Changelog

- `CHANGELOG.md`, newest version first, written for players (no commit hashes,
  no internal refactors). `###` headings per area where it helps.
- Every user-facing PR adds its line under `## Unreleased` (create the section
  if it is missing).
- On release, `## Unreleased` becomes `## vX.Y.Z (YYYY-MM-DD)`. The workflow
  refuses to run without that section and uploads only it as release notes.

## Steps

1. Release PR against the default branch:
   - `CHANGELOG.md`: rename `## Unreleased` to `## vX.Y.Z (YYYY-MM-DD)`.
   - "What's new" entry for the version, if the addon has one and the release
     is worth it (see below).
   - `## Interface` in the `.toc`, if a client build changed.
2. Merge it.
3. *Actions → Release → Run workflow* on the default branch with the version
   (`vX.Y.Z`). The workflow checks the version format, the branch, that the
   tag is new and that `CHANGELOG.md` has the section, lints, creates the tag
   and runs the [BigWigs packager](https://github.com/BigWigsMods/packager),
   which uploads to CurseForge, Wago and GitHub releases.
4. Check the release on CurseForge, Wago and GitHub, then install it in-game.

Pushing a `v*` tag manually starts the same workflow (same checks except
branch and tag). If a run fails after it created the tag, delete the tag
(`git push origin :refs/tags/vX.Y.Z`), fix the cause and run it again.

A failed run is reported to Discord when the repository has the secret
`DISCORD_WEBHOOK_URL`.

## Setup

- `.toc`: `## X-Curse-Project-ID: …` and `## X-Wago-ID: …`.
- Repository secrets `CF_API_KEY` and `WAGO_API_TOKEN` (optional:
  `DISCORD_WEBHOOK_URL`).
- An upload is skipped for a site without ID or secret.

Local test build without upload (zip in `.release/`):

```bash
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -d
```

## This repository

- Default branch: `main`. No prerelease branches.
- [CurseForge](https://www.curseforge.com/projects/698104) 698104,
  [Wago](https://addons.wago.io/addons/rkGrWlNy) `rkGrWlNy`.
- What's new: `BlizzHUDTweaks/UI/WhatsNewNotes.lua`, newest first,
  `version = "X.Y.Z"`, English only. The window shows every entry newer than
  the last version the player saw; test releases show nothing.
