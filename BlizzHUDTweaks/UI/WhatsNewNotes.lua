local _, BlizzHUDTweaks = ...

-- Notes for the "What's new" window (WhatsNew.lua), newest first. Add an
-- entry for every release users should hear about; small fixes need none.
-- Keep them short, the full list is the changelog. Lines starting with "# "
-- are section headings.
BlizzHUDTweaks.whatsNew = {
  {
    version = "3.8.0",
    notes = {
      "# Options",
      "New {About} page: who made the addon, version, and links to Discord, CurseForge, Wago and GitHub, ready to copy"
    }
  },
  {
    version = "3.7.0",
    notes = {
      "# Frame Fading",
      "New condition {Recovering}: while your health or power is not full, frames use its alpha instead of fading out (off by default)",
      "New option {Delay after mouseover}: the frame stays visible for the set time after the mouse has left it",
      "# Miscellaneous",
      "The settings are now split into pages in the sidebar: {Unit Frames}, {Chat}, {Interface} and {Action Bars}",
      "New {Chat Flash} on the {Chat} page: the faded chat is shown for a while when a new message arrives, per channel (off by default)",
      "The Objective Tracker and Experience Bar flash now start at the frame's current alpha"
    }
  },
  {
    version = "3.6.0",
    notes = {
      "# Frame Fading",
      "New frame {Chat Frame}: fades all chat windows, the docked tabs and the chat buttons together; hovering the chat or typing shows it",
      "New frame {Gamepad Action Bars} (WoW: Forever): fades the gamepad HUD with its four action bars"
    }
  },
  {
    version = "3.5.0",
    notes = {
      "# Tooltip",
      "New option {Also in Combat and Instances}: the tooltip stays at the mouse cursor in combat and in instances too (off by default, below {Anchor Tooltip to Mouse})"
    }
  },
  {
    version = "3.4.0",
    notes = {
      "# Edit Mode",
      "The most important fade settings of the selected frame are shown below Blizzard's Edit Mode settings",
      "{All settings} opens that frame in the options window; turn it off with {Settings in Edit Mode} under Frame Fading",
      "# Options window",
      "Frame names and the alpha percent in the frame lists are no longer cut off"
    }
  },
  {
    version = "3.3.0",
    notes = {
      "# Options window",
      "Fade conditions take one line each, and a green line shows which condition applies right now",
      "Frames that use the global settings show them read-only; {Override} gives the frame its own copy",
      "The frame list has filters, Own/Global tags, the current alpha of each frame and a switch per group",
      "Search shows the matching settings and links to their page",
      "The sidebar shows which modules are on, the header shows the active profile",
      "Miscellaneous: shorter labels and reset buttons for single options and whole cards",
      "Profiles: copying and resetting ask first, import strings are checked as soon as they are pasted",
      "The window opens on the page you used last",
      "# In game",
      "The toggle keybind shows a short message: Frame Fading on or off",
      "Minimap icon: right click toggles frame fading, Shift-right click the whole addon",
      "This window: shows what's new after updates. Turn it off below or under General, open it again with `/bht news`"
    }
  }
}
