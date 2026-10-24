local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local Miscellaneous = addon:GetModule("Miscellaneous")
local Tooltip = addon:GetModule("Tooltip")
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

-------------------------------------------------------------------------------
-- Options window: General page and the module cards shared with the module pages

-- The handlers below were written for AceConfig and read the option key from
-- an `info` table; the window passes the same shape.
function Options.Info(key, arg)
  return {key, arg = arg}
end
local Info = Options.Info

local function getVersion()
  local version = C_AddOns.GetAddOnMetadata("BlizzHUDTweaks", "Version")
  if not version or version:find("@project%-version@") then
    return "Development version"
  end
  return "Version " .. version
end

local moduleCards = {
  fading = {
    title = "Actionbar/Frame Fading",
    note = "Fades action bars and frames depending on combat, target, area and mouseover.",
    key = "GlobalOptionsMouseoverFrameFadingEnabled",
    module = MouseoverFrameFading,
    rows = {
      {
        type = "keybind",
        label = "Toggle Keybind",
        tooltip = "Turns frame fading on or off. Click to set a key, press Esc while setting to clear it.",
        get = function()
          return Options:GetValue(Info("GlobalOptionsMouseoverFrameFadingToggleKeybind"))
        end,
        set = function(value)
          Options:SetValue(Info("GlobalOptionsMouseoverFrameFadingToggleKeybind"), value)
        end
      }
    }
  },
  miscellaneous = {
    title = "Miscellaneous",
    note = "Hides names and levels, changes font sizes and action bar padding.",
    key = "GlobalOptionsMiscellaneousEnabled",
    module = Miscellaneous
  },
  tooltip = {
    title = "Tooltip",
    note = "Anchors tooltips to the mouse and shows spell IDs.",
    key = "GlobalOptionsTooltipEnabled",
    module = Tooltip
  }
}

-- Card with the module's on/off switch (and its general options).
function Options:GetModuleCard(id)
  local spec = moduleCards[id]
  return {
    title = spec.title,
    note = spec.note,
    tooltip = "Enable/Disable this sub module",
    toggle = {
      get = function()
        return Options:GetValue(Info(spec.key))
      end,
      set = function(value)
        Options:SetValue(Info(spec.key), value)
        if not value then
          spec.module:Disable()
        else
          spec.module:Enable()
        end
      end
    },
    rows = spec.rows
  }
end

-- Notice for module pages while the module is turned off.
function Options:GetModuleOffNotice(id)
  local spec = moduleCards[id]
  if not Options:GetValue(Info(spec.key)) then
    return {type = "notice", label = "This module is turned off. Changes are saved and take effect once it is on again."}
  end
end

local function getAddonCard()
  return {
    title = "BlizzHUDTweaks",
    note = "Turns the whole addon and all of its modules on or off.",
    tooltip = "Enables or disables the whole addon and all of its sub modules.",
    toggle = {
      get = function()
        return Options:GetValue(Info("Enabled"))
      end,
      set = function(value)
        Options:SetValue(Info("Enabled"), value)
        if not value then
          Options:DisableAll()
        else
          Options:EnableAll()
        end
      end
    },
    rows = {
      {
        type = "checkbox",
        label = "Minimap Icon",
        tooltip = "Shows the addon icon at the minimap. Same as `/bht minimap`.",
        get = function()
          return not addon:GetGlobalProfileDB().minimap.hide
        end,
        set = function(value)
          if value == addon:GetGlobalProfileDB().minimap.hide then
            addon:ToggleMinimapIcon()
          end
        end
      },
      {
        type = "description",
        label = "`/bht` opens this window, `/bht minimap` shows or hides the minimap icon."
      }
    }
  }
end

Options:RegisterPage(
  {
    id = "general",
    label = "General",
    order = 10,
    searchable = true,
    build = function()
      return "General", getVersion(), {
        getAddonCard(),
        Options:GetModuleCard("fading"),
        Options:GetModuleCard("miscellaneous"),
        Options:GetModuleCard("tooltip")
      }
    end
  }
)

-- The toggle keybind switches fading while the window may be open.
hooksecurefunc(
  MouseoverFrameFading,
  "Toggle",
  function()
    Options:RefreshValues()
  end
)

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
