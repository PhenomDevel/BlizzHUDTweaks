local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local aceOptions = {
  name = "BlizzHUDTweaks",
  handler = addon,
  type = "group",
  args = {}
}

local function generateFrameOptionDescription(frameOptions, frameName)
  local desc = "Frame: " .. frameName

  if frameOptions.description then
    desc = desc .. "\n" .. frameOptions.description
  end

  if frameOptions.UseGlobalOptions then
    desc = desc .. "\n\n|cFFa0a832*|r Uses the global settings."
  end

  return desc
end

local function generateFrameOptionName(frameOptions, frameName)
  local name = frameOptions.displayName or frameName

  if frameOptions.UseGlobalOptions then
    name = name .. " (|cFFa0a832*|r)"
  end

  if not frameOptions.Enabled then
    name = "|cFFba3504" .. name .. "|r"
  end

  return name
end

local function addFrameOptions(order, t, frameName, frameOptions, withUseGlobal)
  local subOptions = {}

  t[frameName] = {
    name = generateFrameOptionName(frameOptions, frameName),
    desc = generateFrameOptionDescription(frameOptions, frameName),
    type = "group",
    args = subOptions
  }

  if withUseGlobal then
    order = order + 0.1
    subOptions["Enabled"] = {
      order = order,
      name = "Enabled",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = function(info, value)
        addon:SetValue(info, value)
        addon:RefreshOptions()
      end,
      arg = frameName
    }
    order = order + 0.1
    subOptions["CopyFrom"] = {
      order = order,
      name = "Copy from",
      desc = "Copies all settings of the selected frame to the current frame. This can be used to quickly change many frames to a specific behavior.",
      width = "full",
      type = "select",
      set = "CopyFrom",
      values = addon:GetFrameTable(),
      arg = frameName
    }
    order = order + 0.1
    subOptions["UseGlobalOptions"] = {
      order = order,
      name = "Use global options",
      desc = "Disables all options for this frame and instead uses the globally set options.",
      width = "full",
      type = "toggle",
      get = "GetValue",
      set = function(info, value)
        addon:SetValue(info, value)
        addon:RefreshOptions()
      end,
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
      desc = "The interval in which the add-on should check for necessary alpha changes." ..
        "If you don't need mouseovers to be instantaneously, a value of 0.1 should be fine for you." ..
          addon:ColoredString("\n\nNOTE: ", "eb4034") ..
            "Setting a value below 0.1 puts some stress on the CPU, since the add-on will check" ..
              "for mouseovers far more often. It shouldn't be a real problem, but if " .. "you have any FPS issues, try increasing the value again.",
      width = 0.8,
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
    width = 0.8,
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
    width = 0.6,
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
    width = 0.8,
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
    width = 0.6,
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
    width = 0.8,
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
  subOptions["OutOfCombatFadeDelay"] = {
    order = order,
    name = "Fade Delay",
    desc = "Set a delay for how long the in combat alpha should be maintained before fading to the out of combat alpha." ..
      "The default is 0 and means that the alpha values will change immediately. Setting a higher value can help with reducing `flashing`" ..
        " action bars or frames when entering/leaving combat fast, e.g. while questing." ..
          addon:ColoredString("\n\nNOTE: ", "eb4034") .. "Mouseover a frame will interrupt the delay and use the normal alpha values instead.",
    width = 0.8,
    type = "range",
    get = "GetSliderValue",
    set = "SetSliderValue",
    min = 0,
    max = 60,
    step = 0.5,
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
    width = 0.6,
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
    width = 0.8,
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

-------------------------------------------------------------------------------
-- Public API

function addon:CopyFrom(info, value)
  local fromFrameOptions = self.db.profile[value]

  if fromFrameOptions then
    local copy = addon:tClone(fromFrameOptions)
    copy.displayName = self.db.profile[info.arg].displayName
    self.db.profile[info.arg] = copy
    addon:RefreshFrameAlphas()
  end
end

function addon:GetSliderValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1)
end

function addon:SetSliderValue(info, value)
  self.db.profile[info.arg][info[#info]] = (value or 1)
  addon:RefreshFrameAlphas()
end

function addon:GetFadeSliderValue(info)
  return (self.db.profile[info.arg][info[#info]] or 1) * 100
end

function addon:SetFadeSliderValue(info, value)
  self.db.profile[info.arg][info[#info]] = (value or 1) / 100
  addon:RefreshFrameAlphas()
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
  addon:RefreshFrameAlphas()
end

function addon:GetUseGlobalOptions(info)
  if self.db.profile[info.arg] then
    return self.db.profile[info.arg]["UseGlobalOptions"] or false
  end
end

function addon:getFadeFrameOptions()
  local options = {
    name = "Mouseover Frame Fading",
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

      if not frameOptions.Hidden then
        addFrameOptions(order, options.args, frameName, frameOptions, withUseGlobal)
        order = order + 1
      end
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

function addon:GetAceOptions()
  aceOptions.args["enabled"] = addon:getGlobalOptions()
  aceOptions.args["mouseoverFadeFrames"] = addon:getFadeFrameOptions()
  return aceOptions
end
