local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Miscellaneous = addon:GetModule("Miscellaneous")

local function toggleFrame(option, _, value)
  if option.frame then
    if value then
      option.frame:Hide()
    else
      option.frame:Show()
    end
  end
end

local function toggleFrames(option, _, value)
  if option.frames then
    for _, frame in ipairs(option.frames) do
      toggleFrame({frame = frame}, nil, value)
    end
  end
end

local function overwriteText(option, _, value)
  Miscellaneous:SetFrameText(option.frame, value, option.getOriginalValueFn)
end

local function overwriteFontSize(option, _, value)
  if value then
    if option.frames then
      for _, frame in pairs(option.frames) do
        Miscellaneous:UpdateFontSize(frame, value)
      end
    end
  end
end

local function doNothing()
end

local function hideFrame(option)
  if option.frame then
    option.frame:Hide()
  end
end

local function showFrame(option)
  if option.frame then
    option.frame:Show()
  end
end

local function showFrames(option)
  if option.frames then
    for _, frame in ipairs(option.frames) do
      showFrame({frame = frame})
    end
  end
end

local function resetFontSize(option)
  overwriteFontSize(option, nil, 10)
end

local function resetActionbarPadding(option)
  local profile = addon:GetProfileDB()
  local actionbar = option.frame
  local padding = actionbar.buttonPadding

  Miscellaneous:RestoreActionbarPadding(profile, option, padding, true)
  Miscellaneous:RestoreActionbarSize(profile, option, padding, true)
end

Miscellaneous.options = {
  ["PlayerFrameOptions"] = {
    name = "Player",
    options = {
      {
        optionName = "MiscellaneousTextOverwritePlayerName",
        displayName = "Overwrite Player Name",
        frame = PlayerName,
        description = "",
        type = "input",
        setFn = overwriteText,
        restoreOriginalValueFn = function(option)
          overwriteText(option, nil, option.getOriginalValueFn())
        end,
        getOriginalValueFn = function()
          return UnitName("player")
        end
      },
      {
        optionName = "MiscellaneousShowHidePlayerName",
        displayName = "Hide Player Name",
        frame = PlayerName,
        description = "Hides the player name when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousShowHidePlayerLevel",
        displayName = "Hide Player Level",
        frame = PlayerLevelText,
        description = "Hides the player level when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousShowHidePlayerGroupIndicator",
        displayName = "Hide Player Group Indicator",
        frame = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GroupIndicator,
        description = "Hides the players group indicator",
        type = "toggle",
        setFn = function(option)
          if IsInRaid() then
            hideFrame(option)
          end
        end,
        restoreOriginalValueFn = function(option)
          if IsInRaid() then
            showFrame(option)
          end
        end,
        frameHooks = {
          function(option)
            local frame = option.frame
            if not frame.__BlizzHUDTweaksOnShowHooked then
              frame:HookScript(
                "OnShow",
                function()
                  hideFrame({frame = frame})
                end
              )
              frame.__BlizzHUDTweaksOnShowHooked = true
            end
          end
        }
      },
      {
        optionName = "MiscellaneousFontSizeOverwritePlayerHealthBarFontSize",
        displayName = "Player Health Font Size",
        frames = {
          PlayerFrameHealthBarText,
          PlayerFrameHealthBarTextLeft,
          PlayerFrameHealthBarTextRight,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.HealthBarText,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.TextString,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.LeftText,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.RightText
        },
        description = "",
        type = "range",
        min = 2,
        max = 36,
        setFn = overwriteFontSize,
        restoreOriginalValueFn = resetFontSize
      },
      {
        optionName = "MiscellaneousFontSizeOverwritePlayerManaBarFontSize",
        displayName = "Player Mana Font Size",
        frames = {
          PlayerFrameManaBarText,
          PlayerFrameManaBarTextLeft,
          PlayerFrameManaBarTextRight,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.ManaBarText,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.TextString,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.LeftText,
          PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.RightText
        },
        description = "",
        type = "range",
        min = 2,
        max = 36,
        setFn = overwriteFontSize,
        restoreOriginalValueFn = resetFontSize
      }
    }
  },
  ["TargetFrameOptions"] = {
    name = "Target",
    options = {
      {
        optionName = "MiscellaneousShowHideTargetName",
        displayName = "Hide Target Name",
        frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.Name,
        description = "Hides the target name when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousShowHideTargetLevel",
        displayName = "Hide Target Level",
        frame = TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText,
        description = "Hides the target level when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousFontSizeOverwriteTargetHealthBarFontSize",
        displayName = "Target Health Font Size",
        frames = {
          TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.LeftText,
          TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.RightText,
          TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.TextString},
        description = "",
        type = "range",
        min = 2,
        max = 36,
        setFn = overwriteFontSize,
        restoreOriginalValueFn = resetFontSize
      },
      {
        optionName = "MiscellaneousFontSizeOverwriteTargetManaBarFontSize",
        displayName = "Target Mana Font Size",
        frames = {TargetFrame.manabar.ManaBarText, TargetFrame.manabar.LeftText, TargetFrame.manabar.RightText},
        description = "",
        type = "range",
        min = 2,
        max = 36,
        setFn = overwriteFontSize,
        restoreOriginalValueFn = resetFontSize
      }
    }
  },
  ["FocusTargetOptions"] = {
    name = "Focus",
    options = {
      {
        optionName = "MiscellaneousShowHideFocusName",
        displayName = "Hide Focus Name",
        frame = FocusFrame.TargetFrameContent.TargetFrameContentMain.Name,
        description = "Hides the focus name when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousShowHideFocusLevel",
        displayName = "Hide Focus Level",
        frame = FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText,
        description = "Hides the focus level when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      }
    }
  },
  ["TargetOfTargetOptions"] = {
    name = "Target Of Target",
    options = {
      {
        optionName = "MiscellaneousShowHideTargetOfTargetName",
        displayName = "Hide Target of Target Name",
        frame = TargetFrameToT.Name,
        description = "Hides the target of target name when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      }
    }
  },
  ["PetFrameOptions"] = {
    name = "Pet",
    options = {
      {
        optionName = "MiscellaneousShowHidePetlevel",
        displayName = "Hide Pet Name",
        frame = PetName,
        description = "Hides the pet name when active",
        type = "toggle",
        setFn = toggleFrame,
        restoreOriginalValueFn = showFrame
      },
      {
        optionName = "MiscellaneousShowHidePetStatusText",
        displayName = "Hide Status Texts",
        frames = {
          PetFrameHealthBarTextLeft,
          PetFrameHealthBarTextRight,
          PetFrameHealthBarText,
          PetFrameManaBarTextLeft,
          PetFrameManaBarTextRight,
          PetFrameManaBarText
        },
        type = "toggle",
        setFn = toggleFrames,
        restoreOriginalValueFn = showFrames,
        frameHooks = {
          function(option)
            for _, frame in ipairs(option.frames) do
              if not frame.__BlizzHUDTweaksOnShowHooked then
                frame:HookScript(
                  "OnShow",
                  function()
                    hideFrame({frame = frame})
                  end
                )
                frame.__BlizzHUDTweaksOnShowHooked = true
              end
            end
          end
        }
      }
    }
  },
  ["ObjectiveTrackerOptions"] = {
    name = "Objective Tracker",
    options = {
      {
        optionName = "MiscellaneousShowHideObjectiveTrackerUpdateFlash",
        displayName = "Objective Tracker Flash",
        frame = ObjectiveTrackerFrame,
        description = "Shows the objective tracker in full alpha after an quest log update.",
        type = "toggle",
        setFn = doNothing
      },
      {
        optionName = "MiscellaneousShowHideObjectiveTrackerUpdateFlashDuration",
        displayName = "Flash Duration",
        frame = ObjectiveTrackerFrame,
        type = "range",
        setFn = doNothing
      }
    }
  },
  ["ActionBarOptions"] = {
    name = "Action Bars",
    options = {
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar1",
        displayName = "Action Bar 1",
        frame = MainMenuBar,
        actionButtonName = "MainMenuBarButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar2",
        displayName = "Action Bar 2",
        frame = MultiBarBottomLeft,
        actionButtonName = "MultiBarBottomLeftButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar3",
        displayName = "Action Bar 3",
        frame = MultiBarBottomRight,
        actionButtonName = "MultiBarBottomRightButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar4",
        displayName = "Action Bar 4",
        frame = MultiBarRight,
        actionButtonName = "MultiBarRightButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar5",
        displayName = "Action Bar 5",
        frame = MultiBarLeft,
        actionButtonName = "MultiBarLeftButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar6",
        displayName = "Action Bar 6",
        frame = MultiBar5,
        actionButtonName = "MultiBar5ButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar7",
        displayName = "Action Bar 7",
        frame = MultiBar6,
        actionButtonName = "MultiBar6ButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteActionbar8",
        displayName = "Action Bar 8",
        frame = MultiBar7,
        actionButtonName = "MultiBar7ButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwritePetActionBar",
        displayName = "Pet Action Bar",
        frame = PetActionBar,
        actionButtonName = "PetActionBarButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      },
      {
        optionName = "MiscellaneousActionbarPaddingOverwriteStanceBar",
        displayName = "Stance Bar",
        frame = StanceBar,
        actionButtonName = "StanceBarButtonContainer",
        type = "actionbarpaddinggroup",
        restoreOriginalValueFn = resetActionbarPadding
      }
    }
  }
}

local function addActionbarPaddingOption(profile, t, option, order)
  t[option.optionName .. "Group"] = {
    name = option.displayName or option.optionName,
    order = order,
    type = "group",
    inline = true,
    guiInline = true,
    args = {
      [option.optionName .. "Enabled"] = {
        order = order,
        name = "Enabled",
        desc = option.description or "",
        type = "toggle",
        set = function(info, value)
          Options:SetValue(info, value)
          local padding
          if value then
            padding = addon:GetProfileDB()[option.optionName] or 2
          else
            padding = option.frame.buttonPadding
          end

          if profile["GlobalOptionsMiscellaneousEnabled"] then
            Miscellaneous:RestoreActionbarPadding(addon:GetProfileDB(), option, padding, true)
            Miscellaneous:RestoreActionbarSize(addon:GetProfileDB(), option, padding, true)
          end
        end
      },
      [option.optionName] = {
        order = order,
        name = "Padding",
        desc = option.description or "",
        type = "range",
        min = -36,
        max = 80,
        step = 1,
        set = function(info, value)
          Options:SetValue(info, value)
          if profile["GlobalOptionsMiscellaneousEnabled"] then
            Miscellaneous:RestoreActionbarPadding(addon:GetProfileDB(), option, value)
            Miscellaneous:RestoreActionbarSize(addon:GetProfileDB(), option, value)
          end
        end
      }
    }
  }
end

local function addRangeOption(profile, t, option, order)
  t[option.optionName] = {
    name = option.displayName,
    order = order,
    desc = option.description or "",
    type = "range",
    min = option.min or 0,
    max = option.max or 100,
    step = option.step or 1,
    set = function(info, value)
      Options:SetValue(info, value)
      if profile["GlobalOptionsMiscellaneousEnabled"] then
        option.setFn(option, info, value)
      end
    end
  }
end

local function addToggleOption(profile, t, option, order)
  t[option.optionName] = {
    name = option.displayName or option.optionName,
    desc = option.description or "",
    order = order,
    type = "toggle",
    width = "full",
    set = function(info, value)
      Options:SetValue(info, value)
      if profile["GlobalOptionsMiscellaneousEnabled"] then
        option.setFn(option, info, value)
      end
    end
  }
end

local function addInputOption(profile, t, option, order)
  t[option.optionName] = {
    name = option.displayName or option.optionName,
    desc = option.description or "",
    order = order,
    type = "input",
    set = function(info, value)
      Options:SetValue(info, value)
      if profile["GlobalOptionsMiscellaneousEnabled"] then
        option.setFn(option, info, value)
      end
    end
  }
end

local function generateOptions(t)
  local profile = addon:GetProfileDB()

  for optionGroupName, groupOptions in pairs(Miscellaneous.options) do
    local args = {}
    t[optionGroupName] = {
      type = "group",
      name = groupOptions.name,
      args = args
    }

    local order = 1
    for _, option in ipairs(groupOptions.options) do
      if option.type == "toggle" then
        addToggleOption(profile, args, option, order)
      elseif option.type == "range" then
        addRangeOption(profile, args, option, order)
      elseif option.type == "input" then
        addInputOption(profile, args, option, order)
      elseif option.type == "actionbarpaddinggroup" then
        addActionbarPaddingOption(profile, args, option, order)
      end
      order = order + 1
    end
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
  generateOptions(args)

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
