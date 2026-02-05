local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Tooltip = addon:GetModule("Tooltip")


-------------------------------------------------------------------------------
-- Helper

local function getGlobalOptions()
  return {
    ["TooltipAnchorToMouse"] = {
      order = 1,
      name = "Anchor Tooltip to Mouse",
      desc = "If enabled, tooltips will be anchored to the mouse cursor.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = function(option, value)
        Options:SetValue(option, value)
        if not value then
          Tooltip:ResetTooltipAnchor()
        else
          Tooltip:AnchorTooltipToMouse()
        end
      end
    },
    ["TooltipShowSpellID"] = {
      order = 1,
      name = "Show Spell ID in Tooltip",
      desc = "If enabled, tooltips will show the spell ID.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = function(option, value)
        Options:SetValue(option, value)
        if not value then
          Tooltip:HideSpellID()
        else
          Tooltip:ShowSpellID()
        end
      end
    }
  }
end


-------------------------------------------------------------------------------
-- Public API

function Tooltip:GetValue(info)
  return Options:GetValue(info)
end

function Tooltip:SetValue(info, value)
  Options:SetValue(info, value)
end

function Tooltip:GetOptionsTable()
  local options = {
    name = "Tooltip",
    type = "group",
    handler = Options,
    args = getGlobalOptions()
  }
  return options
end
