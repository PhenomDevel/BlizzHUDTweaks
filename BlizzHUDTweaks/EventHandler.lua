local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local ClassResource = addon:GetModule("ClassResource")
local Miscellaneous = addon:GetModule("Miscellaneous")

-------------------------------------------------------------------------------
-- Public API

local registeredEvents = {}

function addon:RegisterEvents(events, forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(events) do
      if not registeredEvents[event] then
        addon:RegisterEvent(event)
        registeredEvents[event] = true
      end
    end
  end
end

function addon:UnregisterEvents(events, forced)
  if addon:IsEnabled() or forced then
    for _, event in ipairs(events) do
      if registeredEvents[event] then
        addon:UnregisterEvent(event)
        registeredEvents[event] = false
      end
    end
  end
end

function addon:UnregisterAllEvents()
  for event, registered in pairs(registeredEvents) do
    if registered then
      addon:UnregisterEvent(event)
      registeredEvents[event] = false
    end
  end
end

function addon:PLAYER_REGEN_ENABLED()
  BlizzHUDTweaks.inCombat = false

  if addon:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas(true)
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

function addon:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")

  if addon:IsEnabled() then
    if BlizzHUDTweaks.hasTarget then
      MouseoverFrameFading:RefreshFrameAlphas()
    else
      MouseoverFrameFading:RefreshFrameAlphas(true)
    end

    Miscellaneous:RestoreShowHideOptions(self.db.profile)
    Miscellaneous:RestoreFontSizeOptions(self.db.profile)
  end
end

function addon:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    if BlizzHUDTweaks.hasTarget then
      MouseoverFrameFading:RefreshFrameAlphas()
    else
      MouseoverFrameFading:RefreshFrameAlphas(true)
    end

    ClassResource:Restore(self.db.profile)
    ClassResource:RestoreTotemFrame(self.db.profile)
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
    Miscellaneous:RestoreAll(self.db.profile)
  end
end

function addon:PLAYER_SPECIALIZATION_CHANGED()
  if addon:IsEnabled() then
    ClassResource:Restore(self.db.profile)
    ClassResource:RestoreTotemFrame(self.db.profile)
  end
end
