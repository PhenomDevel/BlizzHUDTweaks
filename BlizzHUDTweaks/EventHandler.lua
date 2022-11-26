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

            local normalizedKeybind = keybind:gsub("SHIFT", ""):gsub("ALT", ""):gsub("CTRL", ""):gsub("-", "")
            if string.len(normalizedKeybind) == string.len(pressedKey) then
              MouseoverFrameFading:Toggle()
            end
          end
        end
      end
    )
  end
end

local function restoreMouseoverFade()
  if MouseoverFrameFading:IsEnabled() then
    if BlizzHUDTweaks.hasTarget then
      MouseoverFrameFading:RefreshFrameAlphas(true)
    else
      MouseoverFrameFading:RefreshFrameAlphas(true, true)
    end
  end
end

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
  "ACTIONBAR_SHOWGRID",
  "ACTIONBAR_HIDEGRID",
  "GROUP_ROSTER_UPDATE",
  "GROUP_LEFT",
  "UNIT_QUEST_LOG_CHANGED",
  "UPDATE_SHAPESHIFT_COOLDOWN"
}

local registeredEvents = {}

-------------------------------------------------------------------------------
-- Public API

function EventHandler:RegisterEvents(forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(eventsToRegister) do
      if not registeredEvents[event] then
        EventHandler:RegisterEvent(event)
        registeredEvents[event] = true
      end
    end
  end
end

function EventHandler:UnregisterEvents(forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(eventsToRegister) do
      if registeredEvents[event] then
        EventHandler:UnregisterEvent(event)
        registeredEvents[event] = false
      end
    end
  end
end

function EventHandler:PLAYER_REGEN_ENABLED()
  BlizzHUDTweaks.inCombat = false

  if addon:IsEnabled() then
    if MouseoverFrameFading:IsEnabled() then
      MouseoverFrameFading:RefreshFrameAlphas(true, true)
    end
  end
end

function EventHandler:PLAYER_REGEN_DISABLED()
  BlizzHUDTweaks.inCombat = true

  if addon:IsEnabled() then
    if MouseoverFrameFading:IsEnabled() then
      MouseoverFrameFading:RefreshFrameAlphas()
    end
  end
end

function EventHandler:PLAYER_UPDATE_RESTING()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() and not BlizzHUDTweaks.inCombat then
    if MouseoverFrameFading:IsEnabled() then
      MouseoverFrameFading:RefreshFrameAlphas()
    end
  end
end

function EventHandler:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")

  if addon:IsEnabled() and not BlizzHUDTweaks.inCombat then
    restoreMouseoverFade()
  end
end

function EventHandler:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    local profile = addon:GetProfileDB()

    if ClassResource:IsEnabled() then
      ClassResource:Restore(profile)
      ClassResource:RestoreTotemFrame(profile)
    end

    if Miscellaneous:IsEnabled() then
      Miscellaneous:RestoreAll(profile)
    end
    Miscellaneous:UpdateActionbar1UnusedButtons()
    restoreMouseoverFade()

    installKeyDownHandler()
  end
end

function EventHandler:PLAYER_TOTEM_UPDATE()
  local profile = addon:GetProfileDB()

  if not profile["TotemFrameOriginalPoint"] then
    local orgAnchor, _, orgRelativeAnchor, orgXOffset, orgYOffset = TotemFrame:GetPoint()
    profile["TotemFrameOriginalPoint"] = {
      ["Anchor"] = orgAnchor,
      ["RelativeAnchor"] = orgRelativeAnchor,
      ["XOffset"] = orgXOffset,
      ["YOffset"] = orgYOffset
    }
  end

  if addon:IsEnabled() then
    if ClassResource:IsEnabled() then
      ClassResource:Restore(profile)
      ClassResource:RestoreTotemFrame(profile)
    end
  end
end

function EventHandler:PLAYER_LOGIN()
  if addon:IsEnabled() then
    addon:InitializePartyAndRaidSubFrames()
    addon:RefreshOptionTables()

    if Miscellaneous:IsEnabled() then
      Miscellaneous:InstallHooks()
    end
  end
end

function EventHandler:PLAYER_SPECIALIZATION_CHANGED()
  if addon:IsEnabled() then
    if ClassResource:IsEnabled() then
      local profile = addon:GetProfileDB()

      ClassResource:Restore(profile)
      ClassResource:RestoreTotemFrame(profile)
    end
  end
end

function EventHandler:ACTIONBAR_SLOT_CHANGED()
  if addon:IsEnabled() then
    if Miscellaneous:IsEnabled() then
      local profile = addon:GetProfileDB()

      Miscellaneous:RestoreActionbarPaddings(profile, true, true)
    end
  end
end

function EventHandler:ACTIONBAR_SHOWGRID()
  if addon:IsEnabled() then
    if Miscellaneous:IsEnabled() then
      local profile = addon:GetProfileDB()

      Miscellaneous:RestoreActionbarPaddings(profile, true, true)
    end
  end
end

function EventHandler:ACTIONBAR_HIDEGRID()
  if addon:IsEnabled() then
    if Miscellaneous:IsEnabled() then
      local profile = addon:GetProfileDB()

      Miscellaneous:RestoreActionbarPaddings(profile, true, true)
    end
  end
end

function EventHandler:UNIT_PET(_, unit)
  if unit == "player" then
    if addon:IsEnabled() then
      local profile = addon:GetProfileDB()

      restoreMouseoverFade()
      Miscellaneous:RestoreActionbarPaddings(profile, true, true)
    end
  end
end

function EventHandler:GROUP_ROSTER_UPDATE()
  if addon:IsEnabled() then
    if IsInGroup() then
      local frameMapping = addon:GetFrameMapping()
      if frameMapping["PartyFrame"].Enabled or frameMapping["CompactRaidFrameContainer"].Enabled then
        addon:InitializePartyAndRaidSubFrames(true)
        restoreMouseoverFade()
      end
    end
  end
end

function EventHandler:GROUP_LEFT()
  if addon:IsEnabled() then
    addon:ClearPartyAndRaidSubFrames()
  end
end

function EventHandler:UNIT_QUEST_LOG_CHANGED()
  if addon:IsEnabled() then
    local profile = addon:GetProfileDB()
    Miscellaneous:FlashObjectiveTracker(profile)
  end
end

function EventHandler:UPDATE_SHAPESHIFT_COOLDOWN()
  Miscellaneous:UpdateActionbar1UnusedButtons()
end
