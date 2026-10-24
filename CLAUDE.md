# BlizzHUDTweaks – notes for Claude

World of Warcraft addon that fades and tweaks the default Blizzard HUD. The
`.toc` targets **WoW: Forever** (Interface 16001) and **Retail** (120105 live,
120107 PTR). Both run on the modern mainline API (`C_*` namespaces, Settings API)
including the Midnight addon restrictions (secret values, more protected
calls). Do not assume the old Classic Era API. Features that only exist in one
client (e.g. the Forever swing timer) must be hidden or skipped in the other.

## Layout
- `BlizzHUDTweaks/` is the addon folder that gets installed; everything else
  stays in the repo only (see `.pkgmeta`).
- Load order is defined in `BlizzHUDTweaks.toc`.
- `BlizzHUDTweaks.lua`: AceAddon setup, profile defaults, `frameMapping`
  (profile key → frame), custom frames and the public addon API.
- Modules: `MouseoverFrameFading.lua`, `Miscellaneous.lua`, `Tooltip.lua`;
  events in `EventHandler.lua`.
- Options: own window, no AceConfig. `Options/Widgets.lua` (controls),
  `Options/Window.lua` (window, pages, row types), one file per page in
  `Options/`. Pages are rebuilt from the profile on every render.
- `FramePicker.lua`: overlay for picking custom frames.
- `Toast.lua`: short on-screen message (e.g. after the fading toggle keybind).
- `WhatsNew.lua` / `WhatsNewNotes.lua`: "What's new" window after updates.
  Add an entry to `WhatsNewNotes.lua` (newest first) for every release users
  should hear about; the version must match the release tag.

## Fading frames
- A built-in frame needs a profile default (`displayName`) and an entry in
  `frameMapping` in `BlizzHUDTweaks.lua`, plus a group in
  `Options/MouseoverFrameFading.lua` (otherwise it ends up in "Other").
- Frames that may not exist when the addon loads get `lookup = "GlobalName"`
  in `frameMapping`; they are resolved later.
- Profile keys are SavedVariables – never rename a released key without a
  migration.

## Original code only
- Write all code independently. Never copy, port or closely paraphrase code
  from other addons, regardless of their license. Other addons may only be
  named as feature inspiration ("what"), never as the source of the
  implementation ("how").
- Allowed references: the official WoW API and Blizzard's UI to learn which
  function or frame to use – do not copy Blizzard UI code either.
- Libraries: Ace3, LibDataBroker, LibDBIcon (via `.pkgmeta` externals) and the
  embedded LibDeflate. Ask Kevin before adding another one.

## Taint
- Never call protected functions or `Show`/`Hide`/`SetPoint` on protected
  frames from addon code in combat; queue such work until
  `PLAYER_REGEN_ENABLED`.
- Do not use Blizzard's shared helpers that write global state (`UIFrameFade`,
  `StaticPopup`, …); this addon has its own fade driver and confirm dialog.
- Guard values that can be secret with `issecretvalue`.

## Conventions
- Lua 5.1, 2 spaces indentation, English code comments and docs.
- In-game strings are English only.
- Commit messages: `[feature] …`, `[fix] …`, `[chore] …`.
- `.luacheckrc` holds the common WoW globals; declare others per file with
  `-- luacheck: read globals …`.

## Checks
- `luacheck BlizzHUDTweaks` must pass before committing
  (install with `apt-get install lua5.1 luarocks && luarocks install luacheck`).
- There are no automated tests: Kevin verifies every change in-game. Do not
  add a mocked WoW API to the repo. In the PR description, list what he should
  check in-game.
