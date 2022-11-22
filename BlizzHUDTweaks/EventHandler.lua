local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local EventHandler = addon:GetModule("EventHandler")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local ClassResource = addon:GetModule("ClassResource")
local Miscellaneous = addon:GetModule("Miscellaneous")

local blizzHUDTweaksFrame = CreateFrame("Frame", "BlizzHUDTweaks", UIParent)

local function installKeyDownHandler()
  if not blizzHUDTweaksFrame.OnKeyDown then
    blizzHUDTweaksFrame:SetPropagateKeyboardInput(true)
    blizzHUDTweaksFrame:SetScript(
      "OnKeyDown",
      function(_, pressedKey)
        local profile = addon:GetProfileDB()
        local keybind = profile["GlobalOptionsMouseoverFrameFadingToggleKeybind"]
        local shiftDown = IsShiftKeyDown()
        local ctrlDown = IsControlKeyDown()
        local altDown = IsAltKeyDown()

        if keybind and keybind ~= "" then
          if string.find(keybind, pressedKey) then
            if (string.find(keybind, "SHIFT") and not shiftDown) or (string.find(keybind, "CTRL") and not ctrlDown) or (string.find(keybind, "ALT") and not altDown) then
              return
            end
            MouseoverFrameFading:Toggle()
          end
        end
      end
    )
  end
end

-------------------------------------------------------------------------------
-- Public API

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

local registeredEvents = {}

function EventHandler:RegisterEvents(forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(eventsToRegister) do
      if not registeredEvents[event] then
        addon:RegisterEvent(event)
        registeredEvents[event] = true
      end
    end
  end
end

function EventHandler:UnregisterEvents(forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(eventsToRegister) do
      if registeredEvents[event] then
        addon:UnregisterEvent(event)
        registeredEvents[event] = false
      end
    end
  end
end

function addon:PLAYER_REGEN_ENABLED()
  BlizzHUDTweaks.inCombat = false

  if addon:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas(true, true)
  end
end

function addon:PLAYER_REGEN_DISABLED()
  BlizzHUDTweaks.inCombat = true

  if addon:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas()
  end
end

function addon:PLAYER_UPDATE_RESTING()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas()
  end
end

local function restoreMouseoverFade()
  if BlizzHUDTweaks.hasTarget then
    MouseoverFrameFading:RefreshFrameAlphas(true)
  else
    MouseoverFrameFading:RefreshFrameAlphas(true, true)
  end
end

function addon:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")

  if addon:IsEnabled() then
    restoreMouseoverFade()

    Miscellaneous:RestoreShowHideOptions(self.db.profile)
    Miscellaneous:RestoreFontSizeOptions(self.db.profile)
  end
end

function addon:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    restoreMouseoverFade()

    ClassResource:Restore(self.db.profile)
    ClassResource:RestoreTotemFrame(self.db.profile)

    Miscellaneous:RestoreAll(self.db.profile)
    installKeyDownHandler()
  end
end

function addon:PLAYER_TOTEM_UPDATE()
  if not self.db.profile["TotemFrameOriginalPoint"] then
    local orgAnchor, _, orgRelativeAnchor, orgXOffset, orgYOffset = TotemFrame:GetPoint()
    self.db.profile["TotemFrameOriginalPoint"] = {
      ["Anchor"] = orgAnchor,
      ["RelativeAnchor"] = orgRelativeAnchor,
      ["XOffset"] = orgXOffset,
      ["YOffset"] = orgYOffset
    }
  end

  if addon:IsEnabled() then
    ClassResource:Restore(self.db.profile)
    ClassResource:RestoreTotemFrame(self.db.profile)
  end
end

function addon:PLAYER_LOGIN()
  if addon:IsEnabled() then
    addon:RefreshOptionTables()
    Miscellaneous:InstallHooks()
  end
end

function addon:PLAYER_SPECIALIZATION_CHANGED()
  if addon:IsEnabled() then
    ClassResource:Restore(self.db.profile)
    ClassResource:RestoreTotemFrame(self.db.profile)
  end
end

function addon:ACTIONBAR_SLOT_CHANGED()
  Miscellaneous:RestoreActionbarPaddings(self.db.profile, true, true)
end

function addon:ACTIONBAR_SHOWGRID()
  Miscellaneous:RestoreActionbarPaddings(self.db.profile, true, true)
end

function addon:UNIT_PET(_, unit)
  if unit == "player" then
    if addon:IsEnabled() then
      restoreMouseoverFade()
      Miscellaneous:RestoreActionbarPaddings(self.db.profile, true, true)
    end
  end
end
