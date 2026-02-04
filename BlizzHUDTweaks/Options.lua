local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local Miscellaneous = addon:GetModule("Miscellaneous")
local EventHandler = addon:GetModule("EventHandler")

local eventsToRegister = {
  "PLAYER_LOGIN",
  "PLAYER_REGEN_ENABLED",
  "PLAYER_REGEN_DISABLED",
  "PLAYER_UPDATE_RESTING",
  "PLAYER_TARGET_CHANGED",
  "PLAYER_ENTERING_WORLD",
  "PLAYER_TOTEM_UPDATE",
  "PLAYER_SPECIALIZATION_CHANGED",
  "ACTIONBAR_SLOT_CHANGED",
  "UNIT_PET",
  "ACTIONBAR_SHOWGRID"
}

local function getGlobalOptions()
  return {
    ["Enabled"] = {
      order = 1,
      name = "Enabled",
      desc = "Enables or disables the whole addon and all of it's sub modules.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = function(info, value)
        Options:SetValue(info, value)
        if not value then
          Options:DisableAll()
        else
          Options:EnableAll()
        end
      end
    },
    ["Description"] = {
      order = 2,
      name = addon:ColoredString("\n\nNOTE: ", "eb4034") .. "The actual settings are in sub categories. Please make sure you have expanded BlizzHUDTweaks's options.",
      width = "full",
      type = "description",
      fontSize = "medium"
    },
    ["GlobalOptionsMouseoverFrameFading"] = {
      name = "Actionbar/Frame Fading",
      order = 3,
      type = "group",
      guiInline = true,
      args = {
        ["GlobalOptionsMouseoverFrameFadingEnabled"] = {
          order = 0,
          name = "Enabled",
          desc = "Enable/Disable this sub module",
          width = "double",
          type = "toggle",
          get = "GetValue",
          set = function(info, value)
            Options:SetValue(info, value)
            if not value then
              MouseoverFrameFading:Disable()
            else
              MouseoverFrameFading:Enable()
            end
          end
        },
        ["GlobalOptionsMouseoverFrameFadingToggleKeybind"] = {
          order = 0,
          name = "Toggle Keybind",
          width = "normal",
          type = "keybinding",
          get = "GetValue",
          set = "SetValue"
        }
      }
    },
    ["GlobalOptionsMiscellaneous"] = {
      name = "Miscellaneous",
      order = 5,
      type = "group",
      guiInline = true,
      args = {
        ["GlobalOptionsMiscellaneousEnabled"] = {
          order = 0,
          name = "Enabled",
          desc = "Enable/Disable this sub module",
          width = "double",
          type = "toggle",
          get = "GetValue",
          set = function(info, value)
            Options:SetValue(info, value)
            if not value then
              Miscellaneous:Disable()
            else
              Miscellaneous:Enable()
            end
          end
        }
      }
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
    handler = Options,
    args = getGlobalOptions()
  }
  return options
end

function Options:DisableAll()
  MouseoverFrameFading:Disable()
  Miscellaneous:Disable()

  addon:ClearUpdateTicker()

  addon:Print("Disabled. To make sure everything is loaded correctly please /reload the UI")
end

function Options:EnableAll()
  EventHandler:RegisterEvents(eventsToRegister)

  addon:InitializeUpdateTicker()

  Miscellaneous:Enable()
  MouseoverFrameFading:Enable()

  addon:Print("Enabled")
end
