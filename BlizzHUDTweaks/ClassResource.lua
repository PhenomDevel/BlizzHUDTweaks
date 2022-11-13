local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local ClassResource = addon:GetModule("ClassResource")

local anchorInverse = {
  ["TOP"] = "BOTTOM",
  ["BOTTOM"] = "TOP",
  ["LEFT"] = "RIGHT",
  ["RIGHT"] = "LEFT"
}

-------------------------------------------------------------------------------
-- Public API

local classResourceFrame = PlayerFrameBottomManagedFramesContainer
local totemFrame = TotemFrame

function ClassResource:RestoreOriginalTotemFramePosition(profile)
  local tfAnchor, _, _, tfXOffset, tfYOffset = totemFrame:GetPoint()
  local tfOriginalPoint = profile["TotemFrameOriginalPoint"]

  if tfOriginalPoint then
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
      totemFrame:SetScale(1)
    end
  end
end

function ClassResource:RestorePosition()
  ClassResource:SetPoint("TOP", nil, "BOTTOM", 30, 25)

  PlayerFrameBottomManagedFramesContainer:SetScale(1)
end

function ClassResource:SetPoint(anchor, frame, frameAnchor, xOffset, yOffset)
  if anchor and (xOffset or yOffset) then
    local frameToUse = classResourceFrame
    if frame then
      frameToUse = frame
    end

    frameToUse:ClearAllPoints()
    frameToUse:SetParent(PlayerFrame)

    local actualAnchor = anchor
    if tContains({"LEFT", "RIGHT"}, anchor) then
      actualAnchor = anchorInverse[anchor]
    end

    frameToUse:SetPoint(actualAnchor, PlayerFrame, frameAnchor or anchor, xOffset or 0, yOffset or -1)
  end
end

function ClassResource:RestoreTotemFrame(profile)
  local enabled = profile["TotemFramePositionEnabled"]
  if addon:IsEnabled() and enabled then
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
        ClassResource:SetPoint(anchor, totemFrame, nil, xOffset, yOffset)
        if scale then
          TotemFrame:SetScale(scale)
        end
      end
    else
      ClassResource:RestoreOriginalTotemFramePosition(profile)
    end
  end
end

function ClassResource:Restore(profile)
  if addon:IsEnabled() then
    local class = UnitClassBase("player")

    local currentSpec = GetSpecialization()
    local currentSpecName = ""

    if currentSpec then
      currentSpecName = select(2, GetSpecializationInfo(currentSpec))
    end

    local enabled = profile["ClassResourcePositionEnabled_" .. class .. "_" .. currentSpecName]
    local anchor = profile["ClassResourcePositionAnchor_" .. class .. "_" .. currentSpecName]
    local xOffset = profile["ClassResourcePositionXOffset_" .. class .. "_" .. currentSpecName]
    local yOffset = profile["ClassResourcePositionYOffset_" .. class .. "_" .. currentSpecName]
    local scale = profile["ClassResourcePositionScale_" .. class .. "_" .. currentSpecName]
    local hide = profile["ClassResourcePositionHide_" .. class .. "_" .. currentSpecName]

    if enabled then
      if hide then
        PlayerFrameBottomManagedFramesContainer:Hide()
      else
        PlayerFrameBottomManagedFramesContainer:Show()
      end

      if PlayerFrameBottomManagedFramesContainer:IsShown() then
        ClassResource:SetPoint(anchor, nil, nil, xOffset, yOffset)
        if scale then
          PlayerFrameBottomManagedFramesContainer:SetScale(scale)
        end
      end
    end
  end
end
