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
    displayName = "Player Health Font Size",
    frames = {PlayerFrameHealthBarText, PlayerFrameHealthBarTextLeft, PlayerFrameHealthBarTextRight},
    description = ""
  },
  [2] = {
    optionName = "MiscellaneousFontSizeOverwritePlayerManaBarFontSize",
    displayName = "Player Mana Font Size",
    frames = {PlayerFrameManaBarText, PlayerFrameManaBarTextLeft, PlayerFrameManaBarTextRight},
    description = ""
  },
  [3] = {
    optionName = "MiscellaneousFontSizeOverwriteTargetHealthBarFontSize",
    displayName = "Target Health Font Size",
    frames = {TargetFrame.healthbar.HealthBarText, TargetFrame.healthbar.LeftText, TargetFrame.healthbar.RightText},
    description = ""
  },
  [4] = {
    optionName = "MiscellaneousFontSizeOverwriteTargetManaBarFontSize",
    displayName = "Target Mana Font Size",
    frames = {TargetFrame.manabar.ManaBarText, TargetFrame.manabar.LeftText, TargetFrame.manabar.RightText},
    description = ""
  }
}

Miscellaneous.advancedOptions = {
  [1] = {
    optionName = "MiscellaneousAlwaysCollapseBuffFrameOnLogin",
    displayName = "Always collapse buff frame on login",
    frame = BuffFrame,
    description = "",
    type = "toggle",
    customFunction = function()
      BuffFrame:SetBuffsExpandedState(false)
      BuffFrame.CollapseAndExpandButton:UpdateOrientation()
    end,
    width = "full"
  }
}

local function addTextOverwriteOptions(t)
  local order = 1

  t["TextOverwriteOptionsHeader"] = {
    order = order,
    type = "header",
    name = "Overwrite texts"
  }

  for _, v in ipairs(Miscellaneous.textOverwriteOptions) do
    order = order + 0.1
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      desc = v.description or "",
      type = "input",
      set = function(info, value)
        Options:SetValue(info, value)
        if value then
          v.frame:SetText(value)
        end
      end
    }
  end
end

local function addShowHideOptions(t)
  local order = 2

  t["ShowHideOptionsHeader"] = {
    order = order,
    type = "header",
    name = "Show/Hide"
  }

  for _, v in ipairs(Miscellaneous.showHideOptions) do
    order = order + 0.1
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      desc = v.description or "",
      type = "toggle",
      set = function(info, value)
        Options:SetValue(info, value)
        if value then
          v.frame:Hide()
        else
          v.frame:Show()
        end
      end
    }
  end
end

local function addFontSizeOverwriteOptions(t)
  local order = 3

  t["FontSizeOverwriteOptionsHeader"] = {
    order = order,
    type = "header",
    name = "Overwrite font sizes"
  }

  for _, v in ipairs(Miscellaneous.fontSizeOverwriteOptions) do
    order = order + 0.1
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      desc = v.description or "",
      type = "range",
      min = 6,
      max = 36,
      step = 1,
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
  end
end

local function addAdvancedOptions(t)
  local order = 4

  t["AdvancedOptionsHeader"] = {
    order = order,
    type = "header",
    name = "Advanced options"
  }

  for _, v in ipairs(Miscellaneous.advancedOptions) do
    order = order + 0.1
    t[v.optionName] = {
      order = order,
      name = v.displayName or v.optionName,
      width = v.width or "normal",
      desc = v.description or "",
      type = v.type or "toggle",
      set = function(info, value)
        Options:SetValue(info, value)
        v.customFunction()
      end
    }
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
  addShowHideOptions(args)
  addTextOverwriteOptions(args)
  addFontSizeOverwriteOptions(args)
  addAdvancedOptions(args)
  return {
    name = "Miscellaneous",
    type = "group",
    handler = Miscellaneous,
    get = function(info)
      return Options:GetValue(info)
    end,
    set = function(info, value)
      Options:SetValue(info, value)
    end,
    args = args
  }
end
