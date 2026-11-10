# Changelog

## Unreleased

- Miscellaneous: the settings are now split into pages in the sidebar, like categories: "Unit Frames", "Chat", "Interface" and "Action Bars".
- Frame Fading: new option "Delay after mouseover" (in "Mouseover", global and per frame). The frame stays at full alpha for the set time after the mouse has left it before it fades back. Default 0 s, as before.
- Miscellaneous: new "Chat Flash" on the "Chat" page (off by default), like the Objective Tracker and Experience Bar flash. When a new message arrives, the faded chat is shown at full alpha for a while. Choose the channels (whispers, party and instance, raid, guild, and the general channels like /1 General and /2 Trade, which are off by default) and the flash duration.
- Miscellaneous: the Objective Tracker and Experience Bar flash now start at the frame's current alpha instead of 0, so a half visible frame no longer blinks out first.
- Frame Fading: new condition "Recovering" (off by default). While your health or power (mana, energy, rage, ...) is not full, e.g. after combat or fall damage, frames use its alpha instead of fading out. Set it to 100% to keep your bars visible until you are back at full.

## v3.6.0 (2026-11-07)

- Frame Fading: new frame "Chat Frame" (in "Interface"). It fades all chat windows, the docked chat tabs and the chat buttons together. Hovering any chat window or typing in the chat shows it at full alpha.
- Frame Fading: new frame "Gamepad Action Bars" (WoW: Forever only, group "Gamepad") for the gamepad HUD with its four action bars.

## v3.5.0 (2026-11-06)

- Tooltip: new option "Also in Combat and Instances" (below "Anchor Tooltip to Mouse", off by default). When on, the tooltip stays at the mouse cursor in combat and in instances too. It only changes the anchor type there, so the tooltip keeps its owner and content.
- Tooltip: turning the Tooltip module off now really stops the tooltip from following the mouse.

## v3.4.0 (2026-11-06)

- Frame Fading: the most important fade settings of a frame (on/off, global or own settings, out of combat and in combat alpha, mouseover) are now also shown in Blizzard's Edit Mode, below the settings of the selected frame. "All settings" opens that frame in the options window. Can be turned off with "Settings in Edit Mode" in the Frame Fading settings.
- Frame Fading: the frame lists in the options window give frame names and the alpha percent more room, so they are no longer cut off.

## v3.3.1 (2026-10-25)

- Maintenance release: internal cleanup (code structure, unused code removed). No functional changes.
