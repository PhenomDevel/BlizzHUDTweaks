# BlizzHUDTweaks

<img src="media-src/logo-512.png" alt="BlizzHUDTweaks logo" width="96" align="right">

[![CI](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/ci.yml/badge.svg)](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/ci.yml)
[![Release](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/release.yml/badge.svg)](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/release.yml)
[![Version](https://img.shields.io/github/v/release/PhenomDevel/BlizzHUDTweaks?label=version)](https://github.com/PhenomDevel/BlizzHUDTweaks/releases/latest)
[![CurseForge](https://img.shields.io/curseforge/dt/698104?label=CurseForge)](https://www.curseforge.com/projects/698104)
[![License](https://img.shields.io/github/license/PhenomDevel/BlizzHUDTweaks)](LICENSE)
[![Discord](https://img.shields.io/discord/596662921753526275?label=discord)](https://discord.gg/4fSVKCVJWy)

**Fade and tweak the default Blizzard HUD, without replacing it.**

Fade the Blizzard default frames by situation (combat, mouseover, target,
rested area and more), fade frames of other addons, and tweak small parts of
the default HUD.

## Installation

1. Install it with the CurseForge or Wago app, or download the zip from
   [GitHub releases](https://github.com/PhenomDevel/BlizzHUDTweaks/releases).
2. For a manual install, extract `BlizzHUDTweaks` into the game client's
   `Interface/AddOns/` folder (`_retail_` or your WoW: Forever installation).
3. Log in and type `/bht`.

Changes per version: [CHANGELOG.md](CHANGELOG.md).

## Supported clients

| Client | Interface |
| --- | --- |
| WoW: Forever | 16001 |
| Retail | 120105 (12.1.5) and 120107 (12.1.7 PTR) |

Classic Era, Cataclysm/Mists Classic and other clients are not supported.

## Usage

Open the options with `/bht` (or `/blizzhudtweaks`), the minimap icon or
`Options > AddOns > BlizzHUDTweaks`. The search box finds options on every
page.

### Commands

| Command | |
| --- | --- |
| `/bht` | Open/close the options (also `/blizzhudtweaks`) |
| `/bht minimap` | Show/hide the minimap icon |
| `/bht news` | Show what's new |

## Features

### Frame fading
Set an alpha value per situation for action bars, unit frames, auras, status bars, the minimap, the objective tracker, the cooldown manager and more:

- **Situations**: In Combat, Has Target (friendly, hostile or both), Vehicle, Neighborhood (Retail only), Instanced Area, Rested Area, Out of Combat
- **Mouseover**: shows a faded frame at full alpha, optionally also in combat
- **Fade duration** and **out of combat delay**
- **Global settings** for all frames, or own settings per frame (copy from another frame)
- **Frame links**: hovering one frame also shows its linked frames (e.g. all action bars at once)
- **Swing timer** frames (WoW: Forever only)

If several situations apply, the first one wins: Vehicle > In Combat > Has Target > Neighborhood > Instanced Area > Rested Area > Out of Combat.

### Custom frames (frame picker)
Fade any named frame, e.g. one of another addon, under `Frame Fading > Frames > Custom Frames`:

- **Pick a frame**: the frame under the cursor is highlighted. Mouse wheel switches between overlapping frames, left click adds it, right click or `Esc` cancels.
- **Add by name**: enter a global frame name (`MyAddonMainFrame`) or a path to a child frame (`BuffFrame.CollapseAndExpandButton`).

Custom frames have the same options as built-in ones, can be renamed and are saved in the profile. Frames created later by their addon are faded as soon as they exist.

### Miscellaneous
- Action bar button padding, also below Blizzard's minimum of 2
- Hide name, level or group indicator on player, target, focus, target of target and pet frames, overwrite the player name
- Font size of health and mana texts
- Flash the objective tracker and experience bar at full alpha after an update

### Tooltip
- Anchor tooltips to the mouse
- Show spell IDs

### Profiles
Create, copy, reset and delete profiles, and share them via import/export strings (custom frames included).

## FAQ

- **A frame does not fade**: check that fading is `Enabled` for that frame.
- **A frame does not show**: set `Bar Visible` in Blizzard's Edit Mode to `Always visible`, otherwise the Edit Mode setting wins.
- **Fade delay is ignored**: mouseover cancels the delay once you leave the frame.
- **Padding changes in combat**: they are applied after combat (protected functions).

## Feedback & support

- Questions: [Discord](https://discord.gg/4fSVKCVJWy).
- Bugs and ideas: [GitHub issues](https://github.com/PhenomDevel/BlizzHUDTweaks/issues).
- If you like the addon, star it on GitHub :)

## Development

- Libraries, local setup and checks: [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- Release (same process in all PhenomDevel addons): [`docs/RELEASE.md`](docs/RELEASE.md)

## License

[MIT](LICENSE)

---

Developed with the help of AI ([Claude](https://claude.ai) by Anthropic).
Every change is reviewed by a professional software developer before it is
merged.
