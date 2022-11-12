local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

-------------------------------------------------------------------------------
-- Public API

local registeredEvents = {}

function addon:RegisterEvents(events)
  for _, event in ipairs(events) do
    addon:Print("Register event", event)
    addon:RegisterEvent(event)
    registeredEvents[event] = true
  end
end

function addon:UnregisterEvent(event)
  if registeredEvents[event] then
    addon:UnregisterEvent(event)
    registeredEvents[event] = false
  end
end

function addon:UnregisterEvents(events)
  for _, event in ipairs(events) do
    addon:UnregisterEvent(event)
  end
end

function addon:UnregisterAllEvents()
  for event, _ in pairs(registeredEvents) do
    addon:UnregisterEvent(event)
  end
end

function addon:PLAYER_REGEN_ENABLED()
  BlizzHUDTweaks.inCombat = false

  if addon:IsEnabled() then
    addon:RefreshFrameAlphas(true)
  end
end

function addon:PLAYER_REGEN_DISABLED()
  BlizzHUDTweaks.inCombat = true

  if addon:IsEnabled() then
    addon:RefreshFrameAlphas()
  end
end

function addon:PLAYER_UPDATE_RESTING()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    addon:RefreshFrameAlphas()
  end
end

function addon:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")

  if addon:IsEnabled() then
    if BlizzHUDTweaks.hasTarget then
      addon:RefreshFrameAlphas()
    else
      addon:RefreshFrameAlphas(true)
    end
  end
end

function addon:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    addon:RefreshFrameAlphas()
  end

  addon:RestorePosition(self.db.profile)
end
function addon:PLAYER_LOGIN()
  AC:RegisterOptionsTable("BlizzHUDTweaks_options", addon:GetAceOptions(self.db))
  self.optionsFrame = ACD:AddToBlizOptions("BlizzHUDTweaks_options", "BlizzHUDTweaks")

  local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  AC:RegisterOptionsTable("BlizzHUDTweaks_Profiles", profiles)
  ACD:AddToBlizOptions("BlizzHUDTweaks_Profiles", "Profiles", "BlizzHUDTweaks")
end
