[![Build](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml/badge.svg)](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml)

# BlizzHUDTweaks
A simple add-on which will provide some tweaks to the newly introduced Blizzard HUD (in Dragonflight).

# Usage
Openb the options via the ingame options menu or by typing `/bhudt` or `/blizzhudtweaks`.

# Features
## Mouseover Fade (action bars, frames)
You can fade out most of the actions bars and frames for different scenarios. You can set different alpha values for `In Combat`, `Out of Combat`, and `In Resting Area`. You also can set the options globally and use them for each action bar/frame.

### Configuration options
- Allow mouseover in combat
- Fade Duration
- In Combat Fade
- Out of Combat Fade
- Rested Area Fade

The priority is as follows:
Mouseover > In Combat Fade > Out of Combat Fade > Rested Area Fade.
The Add-ons determines the alpha which should be applied to the corresponding frames based on the settings you applied and the resting/combat state of the player character.

## More will eventually follow

# Performance
Even though the add-on has to check more or less in a set interval, it is very performant. It only uses memory if there are fades being performed and checks in a smart way if there is something to render. If you have any trouble, you can manually set the interval which is used for the fading checks.

# Credits
Initial impressions and ideas came from [Conceal](https://www.curseforge.com/wow/addons/conceal) but i had some things missing and wanted to optimize some stuff.