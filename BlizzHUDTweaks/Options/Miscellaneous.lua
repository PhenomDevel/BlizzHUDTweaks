local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Miscellaneous = addon:GetModule("Miscellaneous")

Miscellaneous.showHideToggableOptions = {
  [1] = {
    optionName = "MiscellaneousHidePlayerName",
    displayName = "Hide Player Name",
    frame = PlayerName,
    description = ""
  },
  [2] = {
    optionName = "MiscellaneousHidePlayerlevel",
    displayName = "Hide Player Level",
    frame = PlayerLevelText,
    description = ""
  },
  [3] = {
    optionName = "MiscellaneousHideTargetName",
    displayName = "Hide Target Name",
    frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.Name,
    description = ""
  },
  [4] = {
    optionName = "MiscellaneousHideTargetlevel",
    displayName = "Hide Target Level",
    frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText,
    description = ""
  }
}

Miscellaneous.textOptions = {
  [1] = {
    optionName = "MiscellaneousOverwritePlayerName",
    displayName = "Overwrite Player Name",
    frame = PlayerName,
    description = ""
  }
}

local function addTextOptions(t)
  local order = 2

  for _, v in ipairs(Miscellaneous.textOptions) do
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      width = "normal",
      desc = v.description or "",
      type = "input",
      get = "GetValue",
      set = function(info, value)
        Options:SetValue(info, value)
        if value then
          v.frame:SetText(value)
        end
      end
    }
    order = order + 0.1
  end
end

local function addShowHideToggableOptions(t)
  local order = 1

  for _, v in ipairs(Miscellaneous.showHideToggableOptions) do
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      width = "normal",
      desc = v.description or "",
      type = "toggle",
      get = "GetValue",
      set = function(info, value)
        Options:SetValue(info, value)
        if value then
          v.frame:Hide()
        else
          v.frame:Show()
        end
      end
    }
    order = order + 0.1
  end
end

-------------------------------------------------------------------------------
-- Public API

function Miscellaneous:GetValue(info)
  return Options:GetValue(info)
end

function Miscellaneous:SetValue(info, value)
  Options:SetValue(info, value)
end

function Miscellaneous:GetOptionsTable(profile)
  local args = {}
  addShowHideToggableOptions(args)
  addTextOptions(args)
  return {
    name = "Miscellaneous",
    type = "group",
    handler = Miscellaneous,
    args = args
  }
end
