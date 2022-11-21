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
    description = "",
    getOriginalValueFn = function()
      return UnitName("player")
    end
  }
}

Miscellaneous.fontSizeOverwriteOptions = {
  [1] = {
    optionName = "MiscellaneousFontSizeOverwritePlayerHealthBarFontSize",
    displayName = "Player Health Font Size",
    frames = {
      PlayerFrameHealthBarText,
      PlayerFrameHealthBarTextLeft,
      PlayerFrameHealthBarTextRight,
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar.HealthBarText,
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar.TextString,
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar.LeftText,
      PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar.RightText
    },
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

Miscellaneous.actionbarPaddingOverwriteOptions = {
  [1] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar1",
    displayName = "Action Bar 1",
    frame = MainMenuBar,
    description = "",
    actionButtonName = "ActionButton"
  },
  [2] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar2",
    displayName = "Action Bar 2",
    frame = MultiBarBottomLeft,
    description = "",
    actionButtonName = "MultiBarBottomLeftButton"
  },
  [3] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar3",
    displayName = "Action Bar 3",
    frame = MultiBarBottomRight,
    description = "",
    actionButtonName = "MultiBarBottomRightButton"
  },
  [4] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar4",
    displayName = "Action Bar 4",
    frame = MultiBarRight,
    description = "",
    actionButtonName = "MultiBarRightButton"
  },
  [5] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar5",
    displayName = "Action Bar 5",
    frame = MultiBarLeft,
    description = "",
    actionButtonName = "MultiBarLeftButton"
  },
  [6] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar6",
    displayName = "Action Bar 6",
    frame = MultiBar5,
    description = "",
    actionButtonName = "MultiBar5Button"
  },
  [7] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar7",
    displayName = "Action Bar 7",
    frame = MultiBar6,
    description = "",
    actionButtonName = "MultiBar6Button"
  },
  [8] = {
    optionName = "MiscellaneousActionbarPaddingOverwriteActionbar8",
    displayName = "Action Bar 8",
    frame = MultiBar7,
    description = "",
    actionButtonName = "MultiBar7Button"
  },
  [9] = {
    optionName = "MiscellaneousActionbarPaddingOverwritePetActionBar",
    displayName = "Pet Action Bar",
    frame = PetActionBar,
    description = "",
    actionButtonName = "PetActionButton"
  }
}

Miscellaneous.advancedOptions = {}

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
          Miscellaneous:SetFrameText(v.frame, value, v.getOriginalValueFn)
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
            for _, frame in pairs(v.frames) do
              Miscellaneous:UpdateFontSize(frame, value)
            end
          end
        end
      end
    }
  end
end

local function addActionbarPaddingOverwriteOptions(t)
  local order = 4

  t["ActionbarPaddingOverwriteOptionsHeader"] = {
    order = order,
    type = "header",
    name = "Overwrite actionbar padding"
  }

  for _, v in ipairs(Miscellaneous.actionbarPaddingOverwriteOptions) do
    order = order + 0.1
    t[v.optionName .. "Group"] = {
      name = v.displayName or v.optionName,
      order = order,
      type = "group",
      inline = true,
      guiInline = true,
      args = {
        [v.optionName .. "Enabled"] = {
          order = order,
          name = "Enabled",
          desc = v.description or "",
          type = "toggle",
          set = function(info, value)
            Options:SetValue(info, value)
            local padding
            if value then
              padding = addon:GetProfileDB()[v.optionName] or 2
            else
              padding = v.frame.buttonPadding
            end
            Miscellaneous:RestoreActionbarPadding(addon:GetProfileDB(), v, padding, true)
            Miscellaneous:RestoreActionbarSize(addon:GetProfileDB(), v, padding, true)
          end
        },
        [v.optionName] = {
          order = order,
          name = "Padding",
          desc = v.description or "",
          type = "range",
          min = -4,
          max = 18,
          step = 1,
          set = function(info, value)
            Options:SetValue(info, value)
            Miscellaneous:RestoreActionbarPadding(addon:GetProfileDB(), v, value)
            Miscellaneous:RestoreActionbarSize(addon:GetProfileDB(), v, value)
          end
        }
      }
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
  addActionbarPaddingOverwriteOptions(args)
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
