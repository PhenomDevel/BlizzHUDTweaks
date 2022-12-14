[![Build](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml/badge.svg)](https://github.com/PhenomDevel/BlizzHUDTweaks/actions/workflows/build.yml) [![Discord General](https://img.shields.io/discord/596662921753526275?label=discord)](https://discord.gg/4fSVKCVJWy)

# BlizzHUDTweaks
Provides tweaks to the newly introduced Blizzard HUD in Dragonflight:

- Out of combat fading for action bars / frames
- Rested area fading for action bars / frames
- In combat fading for action bars / frames
- Action bar padding below blizzard minimum of 2
- Hide unused actionbar 1 buttons
- Repositioning / Scaling of class resources and totem bar (For example combo points, arcane charges etc.)
- Small quality of life improvements

For more details see `Features`.

# Usage
Open the options via the in game options menu or by typing `/bht` or `/blizzhudtweaks` and navigate through the options. Make sure you expand the options, since each "module" is in its own sub category.

## Chat commands
- Toggle minimap icon: `/bht minimap`

# Features
## Mouseover Fade (action bars, frames)
You can fade out most of the actions bars and frames for different scenarios. You can set different alpha values for `In Combat`, `Out of Combat`, and `In Resting Area`. You also can set the options globally and use them for each action bar/frame.

### Configuration options
- Allow mouseover in combat
- Fade Duration
- In Combat Fade
- Out of Combat Fade
- Fade based on health percentage
- Instanced Area fade
- Rested Area Fade
- Set options globally or for each frame
- Treat targeting as in combat fade
- Be able to link frames together for fading

#### The priority of the checks is as follows
1. In Combat Fade
2. Has Target Fade (which uses the `In Combat Fade` values)
3. Health percentage
4. Instanced Area fade
5. Rested Area Fade
6. Out Of Combat Fade

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
- Durability Frame
- Vehicle Seat Frame

## Miscellaneous
- Overwrite your characters name
- Hide Player level
- Hide Target level
- Hide Player name
- Hide Target name
- Overwrite Player/Target Health/Mana font size
- Overwrite actionbar padding (-4 to +16)
- Hide Actionbar1 unused buttons

## Class Resource
You can

- Scale the class resources
- Change position based on Player Frame (Left, Right, Top, Bottom)
- Hide the class resource

You also can change the settings for the Totem Frame.

# Performance
Even though the add-on has to check more or less in a set interval, it is very performant. It only uses memory if there are fades being performed and checks in a smart way if there is something to render. If you have any trouble, you can manually set the interval which is used for the fading checks.

# Help
## Discord
If you have any question and want fast answers, please check the [Discord](https://discord.gg/4fSVKCVJWy). I made it for another add-on, but there is a sub category to ask your questions. The link should already point to the corresponding channel.

## FAQ
### Frame not showing even though it should
Please ensure you have enabled the wanted option for the given action bar or frame. Also, make sure you haven't set the `Bar Visible` option in the Blizzard Edit Mode to something else than `Always visible`
- If set to `Out of Combat` you might be missing the frame or can't mouseover it since the blizzard option overwrites everything else

### Frame fading out when fade delay is set
Usually this only happens when you mouseover a frame. Mouseover overwrites the fade animation, which has a set delay and will not maintain the delay after you leave the frame.

### Fading is setup but nothing happens
Make sure you have `Enabled` the fading for the given frame

### I have setup the position of class resources but it won't move
Make sure you have set atleast the `anchor` and either `xOffset` or `yOffset` since any combination is needed to actually move the resource frame.

## Known Issues
- When reloading the UI while having a target the alpha will only applied once the target changes
- When using `Minimap` fading the textures do not get loaded by blizzard for indoors maps
- When moving an ability when in combat, the actionbar padding will *not* be applied since it would use protected functions while in combat

# Support
If you'd like to support me just leave a star on Github :)