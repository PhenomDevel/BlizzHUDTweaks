local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local ClassResource = addon:GetModule("ClassResource")

-------------------------------------------------------------------------------
-- Public API

local registeredEvents = {}

function addon:RegisterEvents(events)
  for _, event in ipairs(events) do
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
  end
end

function addon:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")

  if addon:IsEnabled() then
    MouseoverFrameFading:RefreshFrameAlphas()
  end

  ClassResource:Restore(self.db.profile)
  ClassResource:RestoreTotemFrame(self.db.profile)
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

  if self.db.profile["TotemFrameDetached"] then
    PlayerFrameBottomManagedFramesContainer:SetHeight(PlayerFrameBottomManagedFramesContainer:GetHeight() - TotemFrame:GetHeight())
  end

  ClassResource:Restore(self.db.profile)
  ClassResource:RestoreTotemFrame(self.db.profile)
end

function addon:PLAYER_LOGIN()
  addon:RefreshOptionTables()
end
