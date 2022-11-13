local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local ClassResource = addon:GetModule("ClassResource")

local aceOptions = {
  name = "BlizzHUDTweaks",
  handler = addon,
  type = "group",
  args = {}
}

local function getGlobalOptions(profile)
  return {
    ["Enabled"] = {
      order = 0,
      name = "Enabled",
      width = "full",
      type = "toggle",
      get = function(info)
        return profile[info[#info]]
      end,
      set = function(info, value)
        profile[info[#info]] = value
        if not value then
          addon:DisableAll()
        else
          addon:EnableAll()
        end
      end
    },
    ["Description"] = {
      order = 1.1,
      name = addon:ColoredString("\n\nNOTE: ", "eb4034") .. "The actual settings are in sub categories. Please make sure you have expanded BlizzHUDTweaks's options.",
      width = "full",
      type = "description",
      fontSize = "medium"
    }
  }
end

-------------------------------------------------------------------------------
-- Public API

function Options:GetValue(info)
  if info.arg then
    return addon:GetProfileDB()[info.arg][info[#info]]
  else
    return addon:GetProfileDB()[info[#info]]
  end
end

function Options:SetValue(info, value)
  if info.arg then
    addon:GetProfileDB()[info.arg][info[#info]] = value
  else
    addon:GetProfileDB()[info[#info]] = value
  end
end

function Options:GetOptionsTable()
  local options = {
    name = "BlizzHUDTweaks",
    type = "group",
    args = getGlobalOptions(addon:GetProfileDB())
  }
  return options
end
