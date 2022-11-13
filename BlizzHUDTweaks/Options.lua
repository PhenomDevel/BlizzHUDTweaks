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
    ["enabled"] = {
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
