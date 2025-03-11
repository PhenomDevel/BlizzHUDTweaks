local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local ClassResource = addon:GetModule("ClassResource")

local anchors = {
  ["TOP"] = "BOTTOM",
  ["BOTTOM"] = "TOP",
  ["LEFT"] = "RIGHT",
  ["RIGHT"] = "LEFT",
  ["TOPLEFT"] = "TOPLEFT",
  ["CENTER"] = "CENTER",
  ["TOPRIGHT"] = "TOPRIGHT",
  ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
  ["BOTTOMLEFT"] = "BOTTOMLEFT"
}

local function getFramePositionOptions(profile, prefix, name, frame)
  local t = {}
  local anchorName = prefix .. "Anchor" .. name
  local xOffsetName = prefix .. "XOffset" .. name
  local yOffsetName = prefix .. "YOffset" .. name
  local scaleName = prefix .. "Scale" .. name
  local hideName = prefix .. "Hide" .. name
  local enabledName = prefix .. "Enabled" .. name
  local descriptionName = prefix .. "Description" .. name

  t[enabledName] = {
    order = 1,
    name = "Enabled",
    width = "full",
    type = "toggle",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreOriginalTotemFramePosition(profile)
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:RestorePosition()
        ClassResource:Restore(profile)
      end
    end
  }

  t[descriptionName] = {
    order = 1.1,
    name = addon:ColoredString("\n\nNOTE: ", "eb4034") .. "If enabled please make sure you have set all settings below to make the feature work correctly.",
    width = "full",
    type = "description",
    fontSize = "medium"
  }

  t[hideName] = {
    order = 1.2,
    name = "Hide",
    width = "full",
    type = "toggle",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:Restore(profile)
      end
    end
  }

  t[anchorName] = {
    order = 1.3,
    name = "AnchorTo",
    width = "normal",
    type = "select",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:Restore(profile)
      end
    end,
    get = "GetValue",
    values = anchors
  }
  t[xOffsetName] = {
    order = 1.4,
    name = "X Offset",
    desc = "",
    width = "full",
    type = "range",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:Restore(profile)
      end
    end,
    softMin = -100,
    softMax = 100,
    step = 1
  }
  t[yOffsetName] = {
    order = 1.5,
    name = "Y Offset",
    desc = "",
    width = "full",
    type = "range",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:Restore(profile)
      end
    end,
    softMin = -100,
    softMax = 100,
    step = 1
  }
  t[scaleName] = {
    order = 1.6,
    name = "Scale",
    desc = "",
    width = "full",
    type = "range",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      if frame == TotemFrame then
        ClassResource:RestoreTotemFrame(profile)
      else
        ClassResource:Restore(profile)
      end
    end,
    softMin = 0.2,
    softMax = 2,
    step = 0.05
  }

  return t
end

function ClassResource:GetClassResourceOptions(profile)
  local options = {}
  local className, normalizedClassName = UnitClass("player")

  for specIndex = 1, GetNumSpecializations() do
    local specName = select(2, GetSpecializationInfo(specIndex)) or ""

    options["ClassResource_" .. normalizedClassName .. "_" .. specName] = {
      name = className .. " " .. specName,
      type = "group",
      args = getFramePositionOptions(profile, "ClassResourcePosition", "_" .. normalizedClassName .. "_" .. specName)
    }
  end
  local totemFrameArgs = getFramePositionOptions(profile, "TotemFramePosition", "", TotemFrame)
  totemFrameArgs["TotemFrameDetached"] = {
    order = 0,
    name = "Detach from resource",
    width = "full",
    type = "toggle",
    get = "GetValue",
    set = function(info, value)
      ClassResource:SetValue(info, value)
      ClassResource:RestoreTotemFrame(profile)
    end
  }

  options["TotemFrame"] = {
    name = "Totem Frame",
    type = "group",
    args = totemFrameArgs
  }

  return options
end

-------------------------------------------------------------------------------
-- Public API

function ClassResource:GetValue(info)
  return Options:GetValue(info)
end

function ClassResource:SetValue(info, value)
  Options:SetValue(info, value)
end

function ClassResource:GetOptionsTable(profile)
  return {
    name = "Class Resource",
    type = "group",
    handler = ClassResource,
    args = ClassResource:GetClassResourceOptions(profile)
  }
end
