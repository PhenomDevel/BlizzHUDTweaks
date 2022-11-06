local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local aceOptions = {
  name = "BlizzHUDTweaks",
  handler = addon,
  type = "group",
  args = {}
}

function addon:GetSliderValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1) * 100
end

function addon:SetSliderValue(info, value)
  self.db.profile[info.arg][info[#info]] = (value or 1) / 100
  addon:RefreshFrames()
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

local function addFrameOptions(order, t, frameName, withUseGlobal)
  local subOptions = {}
  t[frameName] = {
    name = frameName,
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
    desc = "When activated you can mouseover action bars and frames while within combat.",
    width = "full",
    type = "toggle",
    get = "GetValue",
    set = "SetValue",
    disabled = "GetUseGlobalOptions",
    arg = frameName
  }
  order = order + 0.1
  subOptions["FadeDuration"] = {
    order = order,
    name = "Fade Duration",
    desc = "The duration how long the fade should take (fade in and out).",
    width = "full",
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
    get = "GetSliderValue",
    set = "SetSliderValue",
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
    get = "GetSliderValue",
    set = "SetSliderValue",
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
    get = "GetSliderValue",
    set = "SetSliderValue",
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

  for frameName, _ in pairs(self.db.profile) do
    if frameName ~= "*Global*" then
      withUseGlobal = true
    else
      withUseGlobal = false
    end
    addFrameOptions(order, options.args, frameName, withUseGlobal)
    order = order + 1
  end

  return options
end

function BlizzHUDTweaks.GetAceOptions()
  aceOptions.args["mouseoverFadeFrames"] = addon:getFadeFrameOptions()
  return aceOptions
end
