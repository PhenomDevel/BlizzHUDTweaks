local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")

-------------------------------------------------------------------------------
-- About page: who made the addon, version and links. The same page (content
-- and layout) exists in all addons by Phenom.

local DISCORD = "https://discord.gg/4fSVKCVJWy"

local links = {
  {label = "Discord", url = DISCORD},
  {label = "CurseForge", url = "https://www.curseforge.com/projects/698104"},
  {label = "Wago", url = "https://addons.wago.io/addons/rkGrWlNy"},
  {label = "GitHub", url = "https://github.com/PhenomDevel/BlizzHUDTweaks"},
  {label = "Report a bug", url = "https://github.com/PhenomDevel/BlizzHUDTweaks/issues"},
  {label = "Support Phenom", url = "https://streamlabs.com/phenombutbetter/tip"}
}

local otherAddons = {
  {name = "AskAzeroth", note = "Ask questions in game, experienced players answer in threads."},
  {name = "PhenomRaidTools", note = "Plan per boss which player sees which message when."},
  {name = "Guild Finder Forever", note = "In-game marketplace for guilds and players looking for a guild."},
  {name = "Quality of Life Forever", note = "Many small quality-of-life improvements, each switchable on its own."}
}

local function getVersion()
  local version = C_AddOns.GetAddOnMetadata("BlizzHUDTweaks", "Version")
  if not version or version:find("@project%-version@") then
    return "Development version"
  end
  return version
end

local function getCards()
  local linkRows = {}
  for _, link in ipairs(links) do
    linkRows[#linkRows + 1] = {
      type = "text",
      label = link.label,
      tooltip = "Click the field, then press Ctrl+C to copy the link.",
      readOnly = true,
      width = 190,
      get = function()
        return link.url
      end
    }
  end

  local addonLines = {}
  for _, other in ipairs(otherAddons) do
    addonLines[#addonLines + 1] = ("{%s}: %s"):format(other.name, other.note)
  end

  return {
    {
      title = "BlizzHUDTweaks",
      note = "Made by Phenom",
      rows = {
        {type = "description", label = "Fade and tweak the default Blizzard HUD, without replacing it."},
        {type = "description", label = ("Version: {%s}\nAuthor: {Phenom}\nLicense: {MIT} (free and open source)"):format(getVersion())},
        {type = "notice", label = "Questions, ideas or problems? Join Phenom's Discord: " .. DISCORD}
      }
    },
    {
      title = "Links",
      note = "Click a field, then press Ctrl+C to copy the link.",
      rows = linkRows
    },
    {
      title = "More addons by Phenom",
      rows = {
        {type = "description", label = table.concat(addonLines, "\n")}
      }
    }
  }
end

Options:RegisterPage(
  {
    id = "about",
    label = "About",
    order = 90,
    searchable = true,
    build = function()
      return "About", "BlizzHUDTweaks by Phenom", getCards()
    end
  }
)
