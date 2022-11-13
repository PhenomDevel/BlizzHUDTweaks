local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local ClassResource = addon:GetModule("ClassResource")

local anchorInverse = {
  ["TOP"] = "BOTTOM",
  ["BOTTOM"] = "TOP",
  ["LEFT"] = "RIGHT",
  ["RIGHT"] = "LEFT"
}

local classResourceFrame = PlayerFrameBottomManagedFramesContainer
local totemFrame = TotemFrame

local function restoreOriginalTotemFramePosition(profile)
  local tfAnchor, _, _, tfXOffset, tfYOffset = totemFrame:GetPoint()
  local tfOriginalPoint = profile["TotemFrameOriginalPoint"]
  if tfAnchor ~= tfOriginalPoint["Anchor"] or tfXOffset ~= tfOriginalPoint["XOffset"] or tfYOffset ~= tfOriginalPoint["YOffset"] then
    totemFrame:ClearAllPoints()
    totemFrame:SetParent(classResourceFrame.BottomManagedLayoutContainer)
    totemFrame:SetPoint(
      tfOriginalPoint["Anchor"],
      classResourceFrame.BottomManagedLayoutContainer,
      tfOriginalPoint["RelativeAnchor"],
      tfOriginalPoint["XOffset"],
      tfOriginalPoint["YOffset"]
    )
  end
end

-------------------------------------------------------------------------------
-- Public API

function ClassResource:SetPoint(anchor, xOffset, yOffset, frame)
  if anchor and (xOffset or yOffset) then
    local frameToUse = classResourceFrame
    if frame then
      frameToUse = frame
    end

    frameToUse:ClearAllPoints()
    frameToUse:SetParent(PlayerFrame)
    frameToUse:SetPoint(anchorInverse[anchor], PlayerFrame, anchor, xOffset or 0, yOffset or -1)
  end
end

function ClassResource:RestoreTotemFrame(profile)
  if profile["TotemFrameDetached"] then
    local anchor = profile["TotemFramePositionAnchor"]
    local xOffset = profile["TotemFramePositionXOffset"]
    local yOffset = profile["TotemFramePositionYOffset"]
    local scale = profile["TotemFramePositionScale"]
    local hide = profile["TotemFramePositionHide"]

    if hide then
      TotemFrame:Hide()
    else
      TotemFrame:Show()
    end

    if TotemFrame:IsShown() then
      ClassResource:SetPoint(anchor, xOffset, yOffset, totemFrame)
      if scale then
        TotemFrame:SetScale(scale)
      end
    end
  else
    restoreOriginalTotemFramePosition(profile)
  end
end

function ClassResource:Restore(profile)
  local class = UnitClassBase("player")

  local currentSpec = GetSpecialization()
  local currentSpecName = ""

  if currentSpec then
    currentSpecName = select(2, GetSpecializationInfo(currentSpec))
  end

  local anchor = profile["ClassResourcePositionAnchor_" .. class .. "_" .. currentSpecName]
  local xOffset = profile["ClassResourcePositionXOffset_" .. class .. "_" .. currentSpecName]
  local yOffset = profile["ClassResourcePositionYOffset_" .. class .. "_" .. currentSpecName]
  local scale = profile["ClassResourcePositionScale_" .. class .. "_" .. currentSpecName]
  local hide = profile["ClassResourcePositionHide_" .. class .. "_" .. currentSpecName]

  if hide then
    PlayerFrameBottomManagedFramesContainer:Hide()
  else
    PlayerFrameBottomManagedFramesContainer:Show()
  end

  if PlayerFrameBottomManagedFramesContainer:IsShown() then
    ClassResource:SetPoint(anchor, xOffset, yOffset)
    if scale then
      PlayerFrameBottomManagedFramesContainer:SetScale(scale)
    end
  end
end
