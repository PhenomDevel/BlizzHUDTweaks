local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local EventHandler = addon:GetModule("EventHandler")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local Miscellaneous = addon:GetModule("Miscellaneous")

local blizzHUDTweaksFrame = CreateFrame("Frame", "BlizzHUDTweaks", UIParent)

local parsedKeybind = nil
local parsedKey = nil
local parsedMods = { shift = false, ctrl = false, alt = false }
local cachedInstanceInfo = nil

local keyDownHandlerInstalled = false
local cachedIsResting = nil
local cachedInNeighborhood = nil

local _IsResting = IsResting
local _IsInInstance = IsInInstance
local _IsShiftKeyDown = IsShiftKeyDown
local _IsControlKeyDown = IsControlKeyDown
local _IsAltKeyDown = IsAltKeyDown

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeModifierToken(token)
  token = token:upper()
  if token == "CONTROL" or token == "LCTRL" or token == "RCTRL" or token == "LEFTCTRL" or token == "RIGHTCTRL" then
    return "CTRL"
  end
  if token == "ALTGR" then
    return "ALT"
  end
  return token
end

local function parseKeybind(keybind)
  if not keybind or keybind == "" then
    return nil, { shift = false, ctrl = false, alt = false }
  end

  keybind = trim(keybind)
  keybind = keybind:upper()

  local mods = { shift = false, ctrl = false, alt = false }
  local key = keybind
  local parts = {}

  for part in string.gmatch(keybind, "[^%-]+") do
    parts[#parts + 1] = trim(part)
  end

  if #parts > 1 then
    key = parts[#parts]
    for i = 1, #parts - 1 do
      local t = normalizeModifierToken(parts[i])
      if t == "SHIFT" then mods.shift = true end
      if t == "CTRL" then mods.ctrl = true end
      if t == "ALT" then mods.alt = true end
    end
  end

  return key, mods
end

local function installKeyDownHandler()
  if keyDownHandlerInstalled then
    return
  end

  blizzHUDTweaksFrame:SetPropagateKeyboardInput(true)
  blizzHUDTweaksFrame:SetScript("OnKeyDown", function(_, pressedKey)
    local profile = addon:GetProfileDB()
    local keybind = profile["GlobalOptionsMouseoverFrameFadingToggleKeybind"]

    if keybind ~= parsedKeybind then
      parsedKey, parsedMods = parseKeybind(keybind)
      parsedKeybind = keybind
    end

    if not parsedKey then
      return
    end

    local normPressed = tostring(pressedKey):upper()

    if normPressed ~= parsedKey then
      return
    end

    if (parsedMods.shift and not _IsShiftKeyDown()) or (parsedMods.ctrl and not _IsControlKeyDown()) or (parsedMods.alt and not _IsAltKeyDown()) then
      return
    end

    MouseoverFrameFading:Toggle()
  end)

  keyDownHandlerInstalled = true
end

local function updateNeighborhoodCache()
  local _, instanceType = _IsInInstance()
  cachedInNeighborhood = (instanceType == "neighborhood" or instanceType == "interior")
  return cachedInNeighborhood
end

local function restoreMouseoverFade()
  if MouseoverFrameFading:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas()
  end
end

local eventsToRegister = {
  "PLAYER_LOGIN",
  "PLAYER_REGEN_ENABLED",
  "PLAYER_REGEN_DISABLED",
  "PLAYER_UPDATE_RESTING",
  "PLAYER_ENTERING_WORLD",
  "PLAYER_TOTEM_UPDATE",
  "ACTIONBAR_SLOT_CHANGED",
  "UNIT_PET",
  "ACTIONBAR_SHOWGRID",
  "ACTIONBAR_HIDEGRID",
  "GROUP_LEFT",
  "UNIT_QUEST_LOG_CHANGED",
  "UNIT_HEALTH",
  "ZONE_CHANGED_NEW_AREA",
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "PLAYER_TARGET_CHANGED"
}

local registeredEvents = {}

-------------------------------------------------------------------------------
-- Public API

function EventHandler:GetInstanceInfo()
  if not cachedInstanceInfo then
    cachedInstanceInfo = { GetInstanceInfo() }
  end
  return unpack(cachedInstanceInfo)
end

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
  cachedIsResting = _IsResting("player")
  updateNeighborhoodCache()

  BlizzHUDTweaks.isResting = cachedIsResting
  BlizzHUDTweaks.inNeighborhood = cachedInNeighborhood

  if addon:IsEnabled() and not BlizzHUDTweaks.inCombat then
    if MouseoverFrameFading:IsEnabled() then
      MouseoverFrameFading:RefreshFrameAlphas()
    end
  end
end

function EventHandler:PLAYER_ENTERING_WORLD()
  cachedIsResting = _IsResting("player")
  updateNeighborhoodCache()

  BlizzHUDTweaks.isResting = cachedIsResting
  BlizzHUDTweaks.inNeighborhood = cachedInNeighborhood

  if addon:IsEnabled() then
    local profile = addon:GetProfileDB()
    addon:HideGCDFlash()

    if Miscellaneous:IsEnabled() then
      Miscellaneous:RestoreAll(profile)
    end

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
end

function EventHandler:PLAYER_LOGIN()
  if addon:IsEnabled() then
    local profile = addon:GetProfileDB()
    addon:RefreshOptionTables()

    if Miscellaneous:IsEnabled() then
      Miscellaneous:InstallHooks()
      C_Timer.After(
        1,
        function()
          Miscellaneous:RestoreAll(profile)
        end
      )
    end

    if MouseoverFrameFading:IsEnabled() then
      MouseoverFrameFading:InstallHooks()
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

      if Miscellaneous:IsEnabled() then
        Miscellaneous:RestoreActionbarPaddings(profile, true, true)
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

function EventHandler:UNIT_HEALTH(_, unit)
  if unit == "player" then
    MouseoverFrameFading:RefreshFrameAlphas()
  end
end

function EventHandler:ZONE_CHANGED_NEW_AREA()
  cachedInstanceInfo = nil
  cachedIsResting = nil
  cachedInNeighborhood = nil

  if addon:IsEnabled() then
    local profile = addon:GetProfileDB()

    if Miscellaneous:IsEnabled() then
      Miscellaneous:RestoreAll(profile)
    end
  end
end

function EventHandler:PLAYER_MOUNT_DISPLAY_CHANGED()
  cachedInNeighborhood = nil

  if addon:IsEnabled() then
    restoreMouseoverFade()
  end
end

function EventHandler:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")
  if addon:IsEnabled() and not BlizzHUDTweaks.inCombat then

    restoreMouseoverFade()
  end
end