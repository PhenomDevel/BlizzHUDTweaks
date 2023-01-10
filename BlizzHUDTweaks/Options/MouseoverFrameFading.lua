local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")

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

local fadeOrderDescription = addon:ColoredString("\n\nFading Order", "fcba03") .. ": InCombat > HasTarget > Health% > InstancedArea > RestedArea > OutOfCombat"

local function doNothing()
  return
end

local function addFrameOptions(order, t, frameName, frameOptions, withUseGlobal)
  local subOptions = {}

  t[frameName] = {
    name = generateFrameOptionName(frameOptions, frameName),
    desc = generateFrameOptionDescription(frameOptions, frameName),
    type = "group",
    disabled = "GetDisabledFrameOptions",
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
        Options:SetValue(info, value)
        addon:RefreshOptionTables()
        addon:ResetFrameByMappingOptions(addon:GetFrameMapping()[frameName])
        MouseoverFrameFading:RefreshFrameAlphas()
      end,
      arg = frameName,
      disabled = doNothing
    }
    local frameValues = addon:GetFrameTable()
    frameValues["Global"] = "*Global*"

    order = order + 0.1
    subOptions["CopyFrom"] = {
      order = order,
      name = "Copy from",
      desc = "Copies all settings of the selected frame to the current frame. This can be used to quickly change many frames to a specific behavior.",
      width = "full",
      type = "select",
      set = "CopyFrom",
      values = frameValues,
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
        Options:SetValue(info, value)
        addon:RefreshOptionTables()
        MouseoverFrameFading:RefreshFrameAlphas()
      end,
      arg = frameName,
      disabled = doNothing
    }
  end

  order = order + 0.1
  subOptions["MouseOverInCombat"] = {
    order = order,
    name = "Allow mouseover fade in combat",
    desc = "When activated you can mouseover action bars and frames while within combat to show the frame with full alpha.",
    width = "full",
    type = "toggle",
    arg = frameName
  }
  order = order + 0.1
  subOptions["FadeDuration"] = {
    order = order,
    name = "Fade Duration",
    desc = "The duration how long the fade should take (fade in and out).",
    width = 0.8,
    type = "range",
    min = 0.05,
    max = 2,
    step = 0.05,
    arg = frameName
  }
  if not withUseGlobal then
    order = order + 0.1
    subOptions["UpdateInterval"] = {
      order = order,
      name = "Update Interval" .. addon:ColoredString(" (!)", "eb4034"),
      desc = "The interval in which the add-on should check for necessary alpha changes." ..
        "If you don't need mouseovers to be instantaneously, a value of 0.2 should be fine for you." ..
          addon:ColoredString("\n\nCaution: ", "eb4034") ..
            "If the value is decreased, the CPU load increases exponentially. Recommended value is 0.2." ..
              " If you decrease this value and experience any FPS drops, please consider increasing the value again.",
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
  subOptions["FadeOrderDescription"] = {
    order = order,
    name = addon:ColoredString("\n\nNOTE: ", "eb4034") ..
      "The fade settings will be applied in the following order:\n" ..
        addon:ColoredString("In Combat", "5cdb4f") ..
          " > " ..
            addon:ColoredString("Has Target", "9ac113") ..
              " > " ..
                addon:ColoredString("Health %", "bea500") ..
                  " > " ..
                    addon:ColoredString("Instanced Area", "d3870f") ..
                      " > " .. addon:ColoredString("Rested Area", "dc6933") .. " > " .. addon:ColoredString("Out Of Combat", "d64f4f") .. "\n\n",
    width = "full",
    type = "description",
    fontSize = "medium"
  }

  order = order + 0.1
  subOptions["VehicleGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Vehicle Fade",
    args = {
      ["FadeVehicle"] = {
        order = 1,
        name = "Enabled",
        desc = "When active the fade value will be applied when you're in an vehicle." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["VehicleAlpha"] = {
        order = 2,
        name = "Alpha",
        desc = "Set the alpha value of the frame when on an vehicle.",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      }
    }
  }

  order = order + 0.1
  subOptions["InCombatGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "In Combat Fade",
    args = {
      ["FadeInCombat"] = {
        order = 1,
        name = "Enabled",
        desc = "When active the fade value will be applied when you're in combat." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["InCombatAlpha"] = {
        order = 2,
        name = "Alpha",
        desc = "Set the alpha value of the frame when within combat.",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      }
    }
  }

  order = order + 0.1
  subOptions["TreatTargetAsInCombatGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Treat target as in combat",
    args = {
      ["TreatTargetLikeInCombat"] = {
        order = 1,
        name = "Enabled",
        desc = "When active the fade wll change to the in combat fade when you have a target of the corresponding target type (friendly, hostile, or both)." .. fadeOrderDescription,
        width = "normal",
        type = "toggle",
        arg = frameName
      },
      ["TreatTargetLikeInCombatTargetType"] = {
        order = 2,
        name = "Target type",
        desc = "Choose the target type for which `Treat target as in combat` should be applied.",
        width = "normal",
        type = "select",
        set = "SetValue",
        get = "GetValue",
        values = {["friendly"] = "Friendly", ["hostile"] = "Hostile", ["both"] = "Both"},
        arg = frameName
      }
    }
  }

  order = order + 0.1
  subOptions["ByHealthGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Health Fade",
    args = {
      ["FadeByHealth"] = {
        order = 1,
        name = "Enabled",
        desc = "When active the fade value will be applied when your health drops below the defined percentage." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["ByHealthThreshold"] = {
        order = 2,
        name = "Health threshold",
        desc = "If the current HP % of the player drops below the threshold the fade will be applied.",
        width = 0.8,
        type = "range",
        get = "GetValue",
        set = "SetValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 1,
        arg = frameName
      },
      ["ByHealthAlpha"] = {
        order = 3,
        name = "Alpha",
        desc = "Set the alpha value of the frame when HP % of the player is below the defined threshold.",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      }
    }
  }

  order = order + 0.1
  subOptions["InstancedAreaFadeGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Instanced Area Fade",
    args = {
      ["FadeInInstancedArea"] = {
        order = 1,
        name = "Enabled",
        desc = "When active this fade will be applied if you're in an instanced area and *not* in combat." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["InstancedAreaAlpha"] = {
        order = 2,
        name = "Alpha",
        desc = "Set the alpha value of the frame when in an instanced area (e.g. dungeons or raids).",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      }
    }
  }

  order = order + 0.1
  subOptions["RestedAreaGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Rested Area Fade",
    args = {
      ["FadeInRestedArea"] = {
        order = 1,
        name = "Enabled",
        desc = "When active this fade will be applied when you're in a rested area." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["RestedAreaAlpha"] = {
        order = 2,
        name = "Alpha",
        desc = "Set the alpha value of the frame while in a rested area.",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      }
    }
  }
  order = order + 0.1
  subOptions["OutOfCombatGroup"] = {
    order = order,
    type = "group",
    guiInline = true,
    name = "Out of Combat Fade",
    args = {
      ["FadeOutOfCombat"] = {
        order = 1,
        name = "Enabled",
        desc = "When active the fade value will be applied when you're not in combat." .. fadeOrderDescription,
        width = 0.6,
        type = "toggle",
        arg = frameName
      },
      ["OutOfCombatAlpha"] = {
        order = 2,
        name = "Alpha",
        desc = "Set the alpha value of the frame when not in combat.",
        width = 0.8,
        type = "range",
        get = "GetFadeSliderValue",
        set = "SetFadeSliderValue",
        min = 0,
        max = 100,
        softMin = 0,
        softMax = 100,
        step = 5,
        arg = frameName
      },
      ["OutOfCombatFadeDelay"] = {
        order = 3,
        name = "Fade Delay",
        desc = "Set a delay for how long the in combat alpha should be maintained before fading to the out of combat alpha." ..
          "The default is 0 and means that the alpha values will change immediately. Setting a higher value can help with reducing `flashing`" ..
            " action bars or frames when entering/leaving combat fast, e.g. while questing." ..
              addon:ColoredString("\n\nNOTE: ", "eb4034") .. "Mouseover a frame will interrupt the delay and use the normal alpha values instead.",
        width = 0.8,
        type = "range",
        min = 0,
        max = 60,
        step = 0.5,
        arg = frameName
      }
    }
  }
end

local function resetAllFrameLinks(profile, frameTable)
  for frameName, _ in pairs(frameTable) do
    if profile[frameName .. "LinkedFrames"] then
      profile[frameName .. "LinkedFrames"] = {}
    end
  end
end

local function addMouseoverFrameLinkOptions(t, profile)
  local args = {}
  local selectValues = addon:GetFrameTable()

  args["FrameLinksResetAll"] = {
    order = 0,
    type = "execute",
    name = "Reset all links",
    func = function()
      resetAllFrameLinks(profile, selectValues)
    end
  }
  args["FrameLinksDescription"] = {
    order = 1,
    name = addon:ColoredString("\n\nNOTE: ", "eb4034") ..
      "You can specify if frames should be faded together if you mouseover one of them. Each link will act like you mouseover all of the frames at the same time.\n\n" ..
        "The linked frames will only be faded if those frames are enabled. Each link is automatically synchronized with all other frames.\n\n",
    width = "full",
    type = "description",
    fontSize = "medium"
  }

  for frameName, frameOptions in pairs(profile) do
    if type(frameOptions) == "table" and frameOptions.displayName then
      if not frameOptions.Hidden and frameName ~= "*Global*" then
        local selectValuesForFrame = addon:tClone(selectValues)
        selectValuesForFrame["*Global*"] = nil
        selectValuesForFrame["Global"] = nil
        selectValuesForFrame[frameName] = nil
        args[frameName .. "LinkedFramesOptions"] = {
          type = "group",
          order = 3,
          name = frameOptions.displayName or frameName,
          args = {
            [frameName .. "ResetLinkedFrames"] = {
              order = 1,
              type = "execute",
              name = "Reset " .. (frameOptions.displayName or frameName) .. " links",
              func = function()
                local currentFrameLinks = profile[frameName .. "LinkedFrames"]
                for k, _ in pairs(currentFrameLinks) do
                  profile[k .. "LinkedFrames"] = {}
                end
                profile[frameName .. "LinkedFrames"] = {}
              end
            },
            [frameName .. "LinkedFrames"] = {
              order = 2,
              name = frameName .. " Links",
              type = "multiselect",
              values = selectValuesForFrame,
              set = "SetMultiselectValue",
              get = "GetMultiselectValue",
              arg = frameName
            }
          }
        }
      end
    end
  end

  t["FrameLinks"] = {
    type = "group",
    childGroups = "select",
    name = "! |T517160:16:16:0:0:64:64:6:58:6:58|t|cFFa0a832 Frame Links|r",
    args = args
  }
end

local function getMouseoverFrameFadingOptions(profile)
  local options = {}

  local order = 1
  local withUseGlobal

  for frameName, frameOptions in pairs(profile) do
    if type(frameOptions) == "table" and frameOptions.displayName then
      if frameName ~= "*Global*" then
        withUseGlobal = true
      else
        withUseGlobal = false
      end

      if not frameOptions.Hidden then
        addFrameOptions(order, options, frameName, frameOptions, withUseGlobal)
        order = order + 1
      end
    end
  end

  return options
end

-------------------------------------------------------------------------------
-- Public API

function MouseoverFrameFading:CopyFrom(info, value)
  local fromFrameOptions = addon:GetProfileDB()[value]

  if value == "Global" then
    fromFrameOptions = addon:GetProfileDB()["*Global*"]
  end

  if fromFrameOptions then
    local copy = addon:tClone(fromFrameOptions)
    copy.displayName = addon:GetProfileDB()[info.arg].displayName
    copy.UseGlobalOptions = false
    addon:GetProfileDB()[info.arg] = copy
    MouseoverFrameFading:RefreshFrameAlphas()
  end
end

function MouseoverFrameFading:GetFadeSliderValue(info)
  return (Options:GetValue(info) or 1) * 100
end

function MouseoverFrameFading:SetFadeSliderValue(info, value)
  local normalizedValue = (value or 1) / 100
  Options:SetValue(info, normalizedValue)
  MouseoverFrameFading:RefreshFrameAlphas()
end

function MouseoverFrameFading:SetMultiselectValue(info, selectedValue, value)
  if not addon:GetProfileDB()[info[#info]] then
    addon:GetProfileDB()[info[#info]] = {}
  end

  if not addon:GetProfileDB()[selectedValue .. "LinkedFrames"] then
    addon:GetProfileDB()[selectedValue .. "LinkedFrames"] = {}
  end

  addon:GetProfileDB()[info[#info]][selectedValue] = value

  local currentLinkedFrames = addon:GetProfileDB()[info.arg .. "LinkedFrames"]

  -- sync options to selected frames
  for k, _ in pairs(currentLinkedFrames) do
    addon:GetProfileDB()[k .. "LinkedFrames"] = currentLinkedFrames
    addon:GetProfileDB()[k .. "LinkedFrames"][info.arg] = true
  end
end

function MouseoverFrameFading:GetMultiselectValue(info, value)
  if addon:GetProfileDB()[info[#info]] then
    return addon:GetProfileDB()[info[#info]][value]
  end
end

function MouseoverFrameFading:GetUpdateTickerValue(info)
  return Options:GetValue(info) or 1
end

function MouseoverFrameFading:SetUpdateTickerValue(info, value)
  local interval = (value or 0.1)
  Options:SetValue(info, interval)
  addon:RefreshUpdateTicker(interval)
end

function MouseoverFrameFading:GetDisabledFrameOptions(info)
  if info then
    if addon:GetProfileDB()[info.arg] then
      return (addon:GetProfileDB()[info.arg]["UseGlobalOptions"] or not addon:GetProfileDB()[info.arg]["Enabled"]) or false
    end
  end
end

function MouseoverFrameFading:GetValue(info)
  return Options:GetValue(info)
end

function MouseoverFrameFading:SetValue(info, value)
  Options:SetValue(info, value)

  MouseoverFrameFading:RefreshFrameAlphas()
end

function MouseoverFrameFading:GetOptionsTable(profile)
  local args = getMouseoverFrameFadingOptions(profile)
  addMouseoverFrameLinkOptions(args, profile)

  return {
    name = "Mouseover Fading",
    type = "group",
    set = "SetValue",
    get = "GetValue",
    handler = MouseoverFrameFading,
    args = args
  }
end
