# Changelog

## Unreleased

- Frame Fading: new option "Disable fading when HP below" for unit frames (Player, Pet, Target, Target of Target, Focus, Focus Target), in the Edit Mode settings of the selected frame. While the unit is below max health the frame stays visible, so you can see that you need to heal. Once it is back at full health it fades out as usual.
- Frame Fading: the alpha shown while "Disable fading when HP below" applies is now a slider from 0% to 100% (default 90%), in the Edit Mode settings and the options window.
- Frame Fading: new frame "Player Power Bar" (off by default) with the option "Disable fading when power below", so the mana, energy or rage bar stays visible while it is below max. Its alpha is set with a slider from 0% to 100%.

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
