local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local aceOptions = {
  name = "BlizzHUDTweaks",
  handler = addon,
  type = "group",
  args = {}
}

function addon:GetSliderValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1)
end

function addon:SetSliderValue(info, value)
  self.db.profile[info.arg][info[#info]] = (value or 1)
  addon:RefreshFrames()
end

function addon:GetFadeSliderValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1) * 100
end

function addon:SetFadeSliderValue(info, value)
  self.db.profile[info.arg][info[#info]] = (value or 1) / 100
  addon:RefreshFrames()
end

function addon:GetUpdateTickerValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1)
end

function addon:SetUpdateTickerValue(info, value)
  local interval = (value or 0.1)
  self.db.profile[info.arg][info[#info]] = interval
  addon:RefreshUpdateTicker(interval)
end

function addon:GetValue(info)
  return self.db.profile[info.arg][info[#info]]
end

function addon:SetValue(info, value)
  self.db.profile[info.arg][info[#info]] = value
  addon:RefreshFrames()
end

function addon:GetUseGlobalOptions(info)
  if self.db.profile[info.arg] then
    return self.db.profile[info.arg]["UseGlobalOptions"] or false
  end
end

local function addFrameOptions(order, t, frameName, frameOptions, withUseGlobal)
  local subOptions = {}
  t[frameName] = {
    name = frameOptions.displayName or frameName,
    type = "group",
    args = subOptions
  }

  if withUseGlobal then
    order = order + 0.1
    subOptions["UseGlobalOptions"] = {
      order = order,
      name = "Use global options",
      desc = "Disables all options for this frame and instead uses the globally set options.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = "SetValue",
      arg = frameName
    }
  end
  order = order + 0.1
  subOptions["MouseOverInCombat"] = {
    order = order,
    name = "Allow mouseover in combat",
    desc = "When activated you can mouseover action bars and frames while within combat to show the frame with full alpha.",
    width = "full",
    type = "toggle",
    get = "GetValue",
    set = "SetValue",
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  if not withUseGlobal then
    order = order + 0.1
    subOptions["TreatTargetLikeInCombat"] = {
      order = order,
      name = "Treat target as in combat",
      desc = "When active the fade will change to the in combat fade when you have a target.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = "SetValue",
      arg = frameName
    }
    order = order + 0.1
    subOptions["UpdateInterval"] = {
      order = order,
      name = "Update Interval",
      desc = "The interval in which the add-on should check for necessary alpha changes. If you don't need mouseovers to be instantaneously, a value of 0.1 should be fine for you.",
      width = "normal",
      type = "range",
      get = "GetUpdateTickerValue",
      set = "SetUpdateTickerValue",
      min = 0.01,
      max = 1,
      step = 0.01,
      arg = frameName
    }
  end

  order = order + 0.1
  subOptions["FadeDuration"] = {
    order = order,
    name = "Fade Duration",
    desc = "The duration how long the fade should take (fade in and out).",
    width = "normal",
    type = "range",
    get = "GetSliderValue",
    set = "SetSliderValue",
    min = 0.05,
    max = 2,
    step = 0.05,
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["InCombatFade"] = {
    order = order,
    name = "In Combat Fade",
    width = "full",
    type = "header"
  }
  order = order + 0.1
  subOptions["FadeInCombat"] = {
    order = order,
    name = "Enabled",
    width = "normal",
    type = "toggle",
    get = "GetValue",
    set = "SetValue",
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["InCombatAlpha"] = {
    order = order,
    name = "Alpha",
    desc = "Set the alpha value of the frame when within combat.",
    width = "normal",
    type = "range",
    get = "GetFadeSliderValue",
    set = "SetFadeSliderValue",
    min = 0,
    max = 100,
    step = 1,
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["OutOfCombatFade"] = {
    order = order,
    name = "Out of Combat Fade",
    width = "full",
    type = "header"
  }
  order = order + 0.1
  subOptions["FadeOutOfCombat"] = {
    order = order,
    name = "Enabled",
    width = "normal",
    type = "toggle",
    get = "GetValue",
    set = "SetValue",
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["OutOfCombatAlpha"] = {
    order = order,
    name = "Alpha",
    desc = "Set the alpha value of the frame when not in combat.",
    width = "normal",
    type = "range",
    get = "GetFadeSliderValue",
    set = "SetFadeSliderValue",
    min = 0,
    max = 100,
    step = 1,
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["RestedAreaFade"] = {
    order = order,
    name = "Rested Area Fade",
    width = "full",
    type = "header"
  }
  order = order + 0.1
  subOptions["FadeInRestedArea"] = {
    order = order,
    name = "Enabled",
    width = "normal",
    type = "toggle",
    get = "GetValue",
    set = "SetValue",
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["RestedAreaAlpha"] = {
    order = order,
    name = "Alpha",
    desc = "Set the alpha value of the frame while in a rested area.",
    width = "normal",
    type = "range",
    get = "GetFadeSliderValue",
    set = "SetFadeSliderValue",
    min = 0,
    max = 100,
    step = 1,
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
end

function addon:getFadeFrameOptions()
  local options = {
    name = "Fade Frame Options",
    type = "group",
    args = {}
  }

  local order = 1
  local withUseGlobal

  for frameName, frameOptions in pairs(self.db.profile) do
    if type(frameOptions) == "table" then
      if frameName ~= "*Global*" then
        withUseGlobal = true
      else
        withUseGlobal = false
      end
      addFrameOptions(order, options.args, frameName, frameOptions, withUseGlobal)
      order = order + 1
    end
  end

  return options
end
function addon:getGlobalOptions()
  return {
    order = 0,
    name = "Enabled",
    width = "full",
    type = "toggle",
    get = function(info)
      return self.db.profile[info[#info]]
    end,
    set = function(info, value)
      self.db.profile[info[#info]] = value
      if not value then
        addon:DisableAll()
      else
        addon:EnableAll()
      end
    end
  }
end

function BlizzHUDTweaks.GetAceOptions()
  aceOptions.args["enabled"] = addon:getGlobalOptions()
  aceOptions.args["mouseoverFadeFrames"] = addon:getFadeFrameOptions()
  return aceOptions
end
