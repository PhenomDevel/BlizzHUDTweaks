# BlizzHUDTweaks

<img src="https://raw.githubusercontent.com/PhenomDevel/BlizzHUDTweaks/main/docs/logo/logo.png" alt="BlizzHUDTweaks logo" width="96" align="right">

[![Version](https://img.shields.io/github/v/release/PhenomDevel/BlizzHUDTweaks?label=version)](https://github.com/PhenomDevel/BlizzHUDTweaks/releases/latest)
[![CurseForge](https://img.shields.io/curseforge/dt/698104?label=CurseForge)](https://www.curseforge.com/projects/698104)
[![License](https://img.shields.io/github/license/PhenomDevel/BlizzHUDTweaks)](https://github.com/PhenomDevel/BlizzHUDTweaks/blob/main/LICENSE)

**Fade and tweak the default Blizzard HUD, without replacing it.**

Fade the default frames by situation (combat, mouseover, target, rested area
and more), fade frames of other addons too, and tweak small parts of the
default HUD.

## Supported versions

| Client | Interface |
| --- | --- |
| WoW: Forever | 16001 |
| Retail | 120105 (12.1.5) and 120107 (12.1.7 PTR) |

Classic Era, Cataclysm/Mists Classic and other clients are not supported.

## Installation

1. Install it with the [CurseForge](https://www.curseforge.com/projects/698104)
   or [Wago](https://addons.wago.io/addons/rkGrWlNy) app, or download the zip
   from [GitHub releases](https://github.com/PhenomDevel/BlizzHUDTweaks/releases/latest).
2. Manual install: extract `BlizzHUDTweaks` into
   `World of Warcraft/<client>/Interface/AddOns/`.
3. Log in and type `/bht`.

What changed: [CHANGELOG.md](https://github.com/PhenomDevel/BlizzHUDTweaks/blob/main/CHANGELOG.md)

## Features

- **Frame fading:** an alpha value per situation for action bars, unit
  frames, auras, status bars, the minimap, the objective tracker, the
  cooldown manager and more. Situations: In Combat, Has Target, Vehicle,
  Neighborhood (Retail), Instanced Area, Rested Area, Out of Combat; the first
  that applies wins.
- **Mouseover** shows a faded frame at full alpha, optionally also in combat.
  Fade duration and out-of-combat delay are adjustable.
- **Global or per-frame settings**, and **frame links**: hovering one frame
  also shows its linked frames (e.g. all action bars at once).
- **Custom frames:** fade any named frame, also of other addons. Pick it with
  the mouse or enter its name.
- **Swing timer** frames (WoW: Forever).
- **Miscellaneous:** action bar button padding (also below Blizzard's minimum
  of 2), hide name, level or group indicator on unit frames, overwrite the
  player name, font size of health and mana texts, flash the objective
  tracker and experience bar after an update.
- **Tooltip:** anchor to the mouse, show spell IDs.
- **Profiles** with import/export strings (custom frames included).
- Options window with search, also under *Options → AddOns*.

### Commands

| Command | |
| --- | --- |
| `/bht` | Open/close the options (also `/blizzhudtweaks`) |
| `/bht minimap` | Show/hide the minimap icon |
| `/bht news` | Show what's new |

## Support

- A frame does not show: set *Bar Visible* in Blizzard's Edit Mode to
  *Always visible*, otherwise Edit Mode wins.
- Questions: [Discord](https://discord.gg/4fSVKCVJWy)
- Bugs and ideas: [GitHub issues](https://github.com/PhenomDevel/BlizzHUDTweaks/issues)
- If you like the addon, star it on GitHub or leave a tip on
  [Streamlabs](https://streamlabs.com/phenombutbetter/tip).

---

Developed with the help of AI ([Claude](https://claude.ai) by Anthropic).
Every change is reviewed by a professional software developer before it is
merged.
