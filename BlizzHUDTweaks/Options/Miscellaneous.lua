local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Miscellaneous = addon:GetModule("Miscellaneous")

Miscellaneous.showHideOptions = {
  [1] = {
    optionName = "MiscellaneousShowHidePlayerName",
    displayName = "Hide Player Name",
    frame = PlayerName,
    description = ""
  },
  [2] = {
    optionName = "MiscellaneousShowHidePlayerlevel",
    displayName = "Hide Player Level",
    frame = PlayerLevelText,
    description = ""
  },
  [3] = {
    optionName = "MiscellaneousShowHideTargetName",
    displayName = "Hide Target Name",
    frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.Name,
    description = ""
  },
  [4] = {
    optionName = "MiscellaneousShowHideTargetlevel",
    displayName = "Hide Target Level",
    frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText,
    description = ""
  }
}

Miscellaneous.textOverwriteOptions = {
  [1] = {
    optionName = "MiscellaneousTextOverwritePlayerName",
    displayName = "Overwrite Player Name",
    frame = PlayerName,
    description = ""
  }
}

Miscellaneous.fontSizeOverwriteOptions = {
  [1] = {
    optionName = "MiscellaneousFontSizeOverwritePlayerHealthBarFontSize",
    displayName = "Overwrite Player Health Font Size",
    frames = {PlayerFrameHealthBarText, PlayerFrameHealthBarTextLeft, PlayerFrameHealthBarTextRight},
    description = ""
  },
  [2] = {
    optionName = "MiscellaneousFontSizeOverwritePlayerManaBarFontSize",
    displayName = "Overwrite Player Mana Font Size",
    frames = {PlayerFrameManaBarText, PlayerFrameManaBarTextLeft, PlayerFrameManaBarTextRight},
    description = ""
  },
  [3] = {
    optionName = "MiscellaneousFontSizeOverwriteTargetHealthBarFontSize",
    displayName = "Overwrite Target Health Font Size",
    frames = {TargetFrame.healthbar.HealthBarText, TargetFrame.healthbar.LeftText, TargetFrame.healthbar.RightText},
    description = ""
  },
  [4] = {
    optionName = "MiscellaneousFontSizeOverwriteTargetManaBarFontSize",
    displayName = "Overwrite Target Mana Font Size",
    frames = {TargetFrame.manabar.ManaBarText, TargetFrame.manabar.LeftText, TargetFrame.manabar.RightText},
    description = ""
  }
}

local function addSliderOptions(t)
  local order = 3

  for _, v in ipairs(Miscellaneous.fontSizeOverwriteOptions) do
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      width = "double",
      desc = v.description or "",
      type = "range",
      min = 6,
      max = 36,
      step = 1,
      get = "GetValue",
      set = function(info, value)
        Options:SetValue(info, value)
        if value then
          if v.frames then
            for _, frame in ipairs(v.frames) do
              Miscellaneous:UpdateFontSize(frame, value)
            end
          end
        end
      end
    }
    order = order + 0.1
  end
end

local function addTextOptions(t)
  local order = 1

  for _, v in ipairs(Miscellaneous.textOverwriteOptions) do
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
  local order = 2

  for _, v in ipairs(Miscellaneous.showHideOptions) do
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      width = "full",
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

function Miscellaneous:GetOptionsTable()
  local args = {}
  addShowHideToggableOptions(args)
  addTextOptions(args)
  addSliderOptions(args)
  return {
    name = "Miscellaneous",
    type = "group",
    handler = Miscellaneous,
    args = args
  }
end
