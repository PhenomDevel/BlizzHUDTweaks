[![Build](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml/badge.svg)](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml)

# BlizzHUDTweaks
A simple add-on which will provide some tweaks to the newly introduced Blizzard HUD (in Dragonflight).

# Usage
Open the options via the ingame options menu or by typing `/bht` or `/blizzhudtweaks`.

# Features
## Mouseover Fade (action bars, frames)
You can fade out most of the actions bars and frames for different scenarios. You can set different alpha values for `In Combat`, `Out of Combat`, and `In Resting Area`. You also can set the options globally and use them for each action bar/frame.

### Configuration options
- Allow mouseover in combat
- Fade Duration
- In Combat Fade
- Out of Combat Fade
- Rested Area Fade
- Set options globally or for each frame
- Treat targeting as in combat fade

The priority of the checks is as follows
1. In Combat Face
2. Has Target Fade (which uses the `In Combat Fade` values)
3. Out Of Combat Fade
4. Rested Area Fade

### Supported action bars and frames
- Action Bar 1-8
- Player Frame
- Target Frame
- Focus Frame
- Buff Frame
- Debuff Frame
- Pet Frame
- Pet Action Bar
- Stance Bar
- Micro Button and Bags Bar
- Objective Tracker Frame
- Extra Action Button / Zone Ability Frame
- Minimap
- Status Tracking Bar (Rep. & Exp.)
- Player Casting Bar Frame
- LFG Eye

### Additional Frames
#### [EditModeExpanded](https://www.curseforge.com/wow/addons/edit-mode-expanded)
- Micro Button Bar
- Bags Bar
- Durability Frame
- Vehicle Seat Frame

## More will eventually follow
# Performance
Even though the add-on has to check more or less in a set interval, it is very performant. It only uses memory if there are fades being performed and checks in a smart way if there is something to render. If you have any trouble, you can manually set the interval which is used for the fading checks.

# FAQ
## Frame not showing even though it should
- Please ensure you have enabled the wanted option for the given action bar or frame
- Also, make sure you haven't set the `Bar Visible` option in the Blizzard Edit Mode to something else than `Always visible`
  - If set to `Out of Combat` you might be missing the frame or can't mouseover it since the blizzard option overwrites everything else
## Frame fading out when fade delay is set
- Usually this only happens when you mouseover a frame. Mouseover overwrites the fade animation, which has a set delay and will not maintain the delay after you leave the frame.

# Credits
The initial impressions came from [Conceal](https://www.curseforge.com/wow/addons/conceal). However, I disliked the design approach and wanted to add missing features. Therefore, I wrote my personal add-on which extends the feature set.

The code is 99% rewritten with the only exception being the [HideGCDFlash](https://www.mmo-champion.com/threads/2414999-How-do-I-disable-the-GCD-flash-on-my-bars) function which initially already came from the linked mmo-champion post.