local _, BlizzHUDTweaks = ...

-- Notes for the "What's new" window (WhatsNew.lua), newest first. Add an
-- entry for every release users should hear about; small fixes need none.
-- Keep them short, the full list is the changelog. Lines starting with "# "
-- are section headings.
BlizzHUDTweaks.whatsNew = {
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
