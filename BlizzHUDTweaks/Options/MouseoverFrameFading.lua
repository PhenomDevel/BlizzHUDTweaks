-- luacheck: read globals InCombatLockdown
local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local Info = Options.Info
local FramePicker = BlizzHUDTweaks.FramePicker

local GLOBAL = "*Global*"
local SECTION = "Frame Fading"

-- Groups for the frame lists (presentation only). Custom frames get their own
-- group; frames that are not listed here, e.g. the ones added for other
-- addons, end up in "Other".
local frameGroups = {
  {
    name = "Unit Frames",
    frames = {"PlayerFrame", "PetFrame", "TargetFrame", "TargetFrameToT", "FocusFrame", "FocusFrameToT", "PartyFrame", "CompactRaidFrameContainer"}
  },
  {
    name = "Action Bars",
    frames = {
      "ActionBar1",
      "ActionBar2",
      "ActionBar3",
      "ActionBar4",
      "ActionBar5",
      "ActionBar6",
      "ActionBar7",
      "ActionBar8",
      "PetActionBar",
      "StanceBar",
      "ExtraActionButtonFrame",
      "ZoneAbilityFrame",
      "MainMenuBarVehicleLeaveButton"
    }
  },
  {
    name = "Cooldown Manager",
    frames = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer"}
  },
  {
    name = "Auras & Resources",
    frames = {"BuffFrame", "BuffFrame.CollapseAndExpandButton", "DebuffFrame", "PersonalResourceDisplayFrame", "ExternalDefensivesFrame"}
  },
  {
    name = "Status Bars",
    frames = {"MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer", "PlayerCastingBarFrame", "UIWidgetPowerBarContainerFrame"}
  },
  {
    name = "Swing Timer",
    frames = {"SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame"}
  },
  {
    name = "Interface",
    frames = {
      "MinimapCluster",
      "ObjectiveTrackerFrame",
      "MicroMenu",
      "BagsBar",
      "MicroButtonAndBagsBar",
      "QueueStatusButton",
      "DurabilityFrame",
      "VehicleSeatIndicator",
      "DamageMeterSessionWindow1",
      "DamageMeterSessionWindow2",
      "DamageMeterSessionWindow3"
    }
  }
}

local GLOBAL_COLOR = "|cffa0a832"
local CUSTOM_COLOR = "|cff8cc4ff"
local OFF_COLOR = "|cff8f8f94"

local function getDisplayName(frameName)
  if frameName == GLOBAL then
    return "Global Settings"
  end
  local frameOptions = addon:GetProfileDB()[frameName]
  return frameOptions and frameOptions.displayName or frameName
end

local function sortByDisplayName(frameNames)
  table.sort(
    frameNames,
    function(a, b)
      return getDisplayName(a) < getDisplayName(b)
    end
  )
end

-- Frames that have options and are not hidden, in groups:
-- { { name = "Unit Frames", frames = { "PlayerFrame", ... } }, ... }
local function getFrameGroups(exclude)
  local visible = {}
  for frameName, frameOptions in pairs(addon:GetProfileDB()) do
    if type(frameOptions) == "table" and frameOptions.displayName and not frameOptions.Hidden and frameName ~= GLOBAL and frameName ~= exclude then
      visible[frameName] = true
    end
  end

  local groups = {}
  for _, group in ipairs(frameGroups) do
    local frames = {}
    for _, frameName in ipairs(group.frames) do
      if visible[frameName] then
        frames[#frames + 1] = frameName
        visible[frameName] = nil
      end
    end
    if #frames > 0 then
      groups[#groups + 1] = {name = group.name, frames = frames}
    end
  end

  local custom, others = {}, {}
  for frameName in pairs(visible) do
    if addon:IsCustomFrame(frameName) then
      custom[#custom + 1] = frameName
    else
      others[#others + 1] = frameName
    end
  end
  if #custom > 0 then
    sortByDisplayName(custom)
    groups[#groups + 1] = {name = "Custom Frames", frames = custom, custom = true}
  end
  if #others > 0 then
    sortByDisplayName(others)
    groups[#groups + 1] = {name = "Other", frames = others}
  end
  return groups
end

local function getFrameDescription(frameName)
  local frameOptions = addon:GetProfileDB()[frameName]
  local desc = "Frame: `" .. frameName .. "`"
  if frameOptions.description then
    desc = desc .. "\n" .. frameOptions.description
  end
  if frameOptions.Custom then
    local frameMappingOptions = addon:GetFrameMapping()[frameName]
    if not (frameMappingOptions and frameMappingOptions.mainFrame) then
      desc = desc .. "\nThe frame does not exist right now. It is faded as soon as it does."
    end
  end
  return desc
end

local function getFrameStatus(frameName)
  local frameOptions = addon:GetProfileDB()[frameName]
  if not frameOptions.Enabled then
    return OFF_COLOR .. "Off|r"
  elseif frameOptions.UseGlobalOptions then
    return GLOBAL_COLOR .. "Global|r"
  end
  return CUSTOM_COLOR .. "Own|r"
end

local function getModuleCards()
  local cards = {Options:GetModuleCard("fading")}
  local notice = Options:GetModuleOffNotice("fading")
  if notice then
    cards[1].rows = {notice, unpack(cards[1].rows or {})}
  end
  return cards
end

-------------------------------------------------------------------------------
-- Rows bound to the handlers below (same keys and side effects as before)

local function valueRow(rowType, frameName, key, label, desc)
  return {
    type = rowType,
    label = label,
    tooltip = desc,
    get = function()
      return MouseoverFrameFading:GetValue(Info(key, frameName))
    end,
    set = function(value)
      MouseoverFrameFading:SetValue(Info(key, frameName), value)
    end
  }
end

local function alphaRow(frameName, key, desc)
  return {
    type = "slider",
    label = "Alpha",
    tooltip = desc,
    min = 0,
    max = 100,
    step = 5,
    format = function(value)
      return ("%d%%"):format(value)
    end,
    get = function()
      return MouseoverFrameFading:GetFadeSliderValue(Info(key, frameName))
    end,
    set = function(value)
      MouseoverFrameFading:SetFadeSliderValue(Info(key, frameName), value)
    end
  }
end

local function secondsFormat(decimals)
  return function(value)
    return ("%." .. decimals .. "f s"):format(value)
  end
end

local function setFrameEnabled(frameName, value)
  Options:SetValue(Info("Enabled", frameName), value)
  addon:RefreshOptionTables()
  addon:ResetFrameByMappingOptions(addon:GetFrameMapping()[frameName])
  MouseoverFrameFading:RefreshFrameAlphas()
end

local function getCopyFromValues(frameName)
  local frameNames = {}
  for name in pairs(addon:GetFrameTable()) do
    if name ~= GLOBAL and name ~= "Global" and name ~= frameName then
      frameNames[#frameNames + 1] = name
    end
  end
  sortByDisplayName(frameNames)
  local values = {{value = "Global", label = "Global Settings"}}
  for _, name in ipairs(frameNames) do
    values[#values + 1] = {value = name, label = getDisplayName(name)}
  end
  return values
end

-------------------------------------------------------------------------------
-- Frame settings (one frame or the global settings)

-- Fade conditions in the order they are checked.
local conditions = {
  {
    label = "Vehicle",
    key = "FadeVehicle",
    alphaKey = "VehicleAlpha",
    desc = "When active the fade value will be applied when you're in a vehicle.",
    alphaDesc = "Set the alpha value of the frame when in a vehicle."
  },
  {
    label = "In Combat",
    key = "FadeInCombat",
    alphaKey = "InCombatAlpha",
    desc = "When active the fade value will be applied when you're in combat.",
    alphaDesc = "Set the alpha value of the frame when within combat."
  },
  {
    label = "Has Target",
    key = "TreatTargetLikeInCombat",
    toggleLabel = "Treat target as in combat",
    desc = "When active the fade will change to the in combat fade when you have a target of the corresponding target type (friendly, hostile, or both)." ..
      "\n\nUses the {In Combat} alpha and only works while {In Combat} is enabled.",
    targetType = true
  },
  {
    label = "Neighborhood",
    key = "FadeInNeighborhood",
    alphaKey = "NeighborhoodAlpha",
    retailOnly = true,
    desc = "When active this fade will be applied when you're in a neighborhood area.",
    alphaDesc = "Set the alpha value of the frame while in a neighborhood area."
  },
  {
    label = "Instanced Area",
    key = "FadeInInstancedArea",
    alphaKey = "InstancedAreaAlpha",
    desc = "When active this fade will be applied if you're in an instanced area and *not* in combat.",
    alphaDesc = "Set the alpha value of the frame when in an instanced area (e.g. dungeons or raids)."
  },
  {
    label = "Rested Area",
    key = "FadeInRestedArea",
    alphaKey = "RestedAreaAlpha",
    desc = "When active this fade will be applied when you're in a rested area.",
    alphaDesc = "Set the alpha value of the frame while in a rested area."
  },
  {
    label = "Out of Combat",
    key = "FadeOutOfCombat",
    alphaKey = "OutOfCombatAlpha",
    desc = "When active the fade value will be applied when you're not in combat.",
    alphaDesc = "Set the alpha value of the frame when not in combat.",
    fadeDelay = true
  }
}

-- General card of a frame: on/off, global settings, copy.
local function getFrameCard(frameName)
  local frameOptions = addon:GetProfileDB()[frameName]
  local rows = {
    {
      type = "checkbox",
      label = "Enabled",
      tooltip = "Fades this frame. When off, the frame is always shown at full alpha.",
      layout = true,
      get = function()
        return Options:GetValue(Info("Enabled", frameName))
      end,
      set = function(value)
        setFrameEnabled(frameName, value)
      end
    }
  }
  local card = {title = getDisplayName(frameName), note = getFrameDescription(frameName), rows = rows}

  if frameOptions.Custom then
    rows[#rows + 1] = {
      type = "text",
      label = "Display name",
      tooltip = "The name shown in the frame lists.",
      layout = true,
      get = function()
        return getDisplayName(frameName)
      end,
      set = function(value)
        value = value and strtrim(value) or ""
        addon:GetProfileDB()[frameName].displayName = value ~= "" and value or frameName
        addon:RefreshOptionTables()
      end
    }
    rows[#rows + 1] = {
      type = "button",
      label = "Remove custom frame",
      tooltip = "Removes the frame from the list and shows it at full alpha again.",
      buttonText = "Remove",
      onClick = function()
        Options:Confirm(
          "Remove the custom frame " .. getDisplayName(frameName) .. "?",
          "Remove",
          function()
            addon:RemoveCustomFrame(frameName)
            Options:Navigate("fading-frames")
          end
        )
      end
    }
  end

  if not frameOptions.Enabled then
    card.hint = "Turn on {Enabled} to set up fading for this frame."
    return card
  end

  rows[#rows + 1] = {
    type = "checkbox",
    label = "Use global options",
    tooltip = "Disables all options for this frame and instead uses the globally set options.",
    layout = true,
    get = function()
      return Options:GetValue(Info("UseGlobalOptions", frameName))
    end,
    set = function(value)
      Options:SetValue(Info("UseGlobalOptions", frameName), value)
      addon:RefreshOptionTables()
      MouseoverFrameFading:RefreshFrameAlphas()
    end
  }

  if frameOptions.UseGlobalOptions then
    rows[#rows + 1] = {
      type = "nav",
      label = "Edit Global Settings",
      tooltip = "The values below come from the global settings while {Use global options} is on.",
      onClick = function()
        Options:Navigate("fading-global")
      end
    }
  else
    rows[#rows + 1] = {
      type = "dropdown",
      label = "Copy from",
      tooltip = "Copies all settings of the selected frame to the current frame. This can be used to quickly change many frames to a specific behavior.",
      placeholder = "Select a frame",
      layout = true,
      values = function()
        return getCopyFromValues(frameName)
      end,
      get = function()
        return Options:GetValue(Info("CopyFrom", frameName))
      end,
      set = function(value)
        local source = value == "Global" and "Global Settings" or getDisplayName(value)
        Options:Confirm(
          ("Copy all fade settings of %s to %s?\nThe current settings of %s are lost."):format(source, getDisplayName(frameName), getDisplayName(frameName)),
          "Copy",
          function()
            MouseoverFrameFading:CopyFrom(Info("CopyFrom", frameName), value)
            Options:Refresh()
          end
        )
      end
    }
  end
  return card
end

local function getMouseoverCard(frameName)
  local rows = {
    valueRow("checkbox", frameName, "MouseOverFadeEnabled", "Fade on mouseover", "When activated you can mouseover action bars and frames to show the frame with full alpha."),
    valueRow(
      "checkbox",
      frameName,
      "MouseOverInCombat",
      "Allow mouseover fade in combat",
      "When activated you can mouseover action bars and frames while within combat to show the frame with full alpha."
    )
  }
  local duration = valueRow("slider", frameName, "FadeDuration", "Fade Duration", "The duration how long the fade should take (fade in and out).")
  duration.min, duration.max, duration.step, duration.format = 0.05, 2, 0.05, secondsFormat(2)
  rows[#rows + 1] = duration

  return {title = "Mouseover", note = "Shows the frame at full alpha while the mouse is over it.", rows = rows}
end

local function getPerformanceCard(frameName)
  return {
    title = "Performance",
    rows = {
      {
        type = "slider",
        label = "Update Interval",
        tooltip = "The interval in which the add-on should check for necessary alpha changes. " ..
          "If you don't need mouseovers to be instantaneously, a value of 0.2 should be fine for you.",
        min = 0.01,
        max = 1,
        step = 0.01,
        format = secondsFormat(2),
        get = function()
          return MouseoverFrameFading:GetUpdateTickerValue(Info("UpdateInterval", frameName))
        end,
        set = function(value)
          MouseoverFrameFading:SetUpdateTickerValue(Info("UpdateInterval", frameName), value)
        end
      },
      {
        type = "notice",
        label = "Caution: If the value is decreased, the CPU load increases exponentially. Recommended value is 0.2. " ..
          "If you decrease this value and experience any FPS drops, please consider increasing the value again."
      }
    }
  }
end

local function getConditionsCard(frameName)
  local frameOptions = addon:GetProfileDB()[frameName]
  local rows = {}
  local index = 0
  for _, condition in ipairs(conditions) do
    -- Housing conditions are skipped in WoW: Forever, which has no housing.
    local available = not condition.retailOnly or addon:HasHousing()
    if available then
      index = index + 1
      rows[#rows + 1] = {type = "header", label = index .. "  ·  " .. condition.label}
      local toggle = valueRow("checkbox", frameName, condition.key, condition.toggleLabel or "Enabled", condition.desc)
      toggle.layout = true
      rows[#rows + 1] = toggle
    end

    -- Values of a condition only matter while it is on.
    if available and frameOptions[condition.key] then
      if condition.alphaKey then
        rows[#rows + 1] = alphaRow(frameName, condition.alphaKey, condition.alphaDesc)
      end
      if condition.targetType then
        local targetType =
          valueRow("dropdown", frameName, "TreatTargetLikeInCombatTargetType", "Target type", "Choose the target type for which {Treat target as in combat} should be applied.")
        targetType.values = {{value = "friendly", label = "Friendly"}, {value = "hostile", label = "Hostile"}, {value = "both", label = "Both"}}
        rows[#rows + 1] = targetType
      end
      if condition.fadeDelay then
        local delay =
          valueRow(
          "slider",
          frameName,
          "OutOfCombatFadeDelay",
          "Fade Delay",
          "Set a delay for how long the in combat alpha should be maintained before fading to the out of combat alpha. " ..
            "The default is 0 and means that the alpha values will change immediately. Setting a higher value can help with reducing `flashing` " ..
              "action bars or frames when entering/leaving combat fast, e.g. while questing.\n\nNOTE: Mouseover a frame will interrupt the delay and use the normal alpha values instead."
        )
        delay.min, delay.max, delay.step, delay.format = 0, 60, 0.5, secondsFormat(1)
        rows[#rows + 1] = delay
      end
    end
  end

  return {
    title = "Fade Conditions",
    note = "Mouseover always comes first. Otherwise the first enabled condition that applies, from top to bottom, sets the alpha.",
    rows = rows
  }
end

local function getFrameSettingsCards(frameName)
  local cards = {}
  local isGlobal = frameName == GLOBAL

  if not isGlobal then
    cards[1] = getFrameCard(frameName)
    if MouseoverFrameFading:GetDisabledFrameOptions(Info(nil, frameName)) then
      return cards
    end
  end

  cards[#cards + 1] = getMouseoverCard(frameName)
  if isGlobal then
    cards[#cards + 1] = getPerformanceCard(frameName)
  end
  cards[#cards + 1] = getConditionsCard(frameName)
  return cards
end

-------------------------------------------------------------------------------
-- Custom frames

-- Last reason why a frame could not be added, shown in the Custom Frames card.
local customFrameError

local function addCustomFrame(frameName)
  local added, reason = addon:AddCustomFrame(frameName)
  if added then
    customFrameError = nil
    Options:Navigate("fading-frames", strtrim(frameName))
  else
    customFrameError = reason
    Options:Navigate("fading-frames")
  end
end

local function startFramePicker()
  if InCombatLockdown() then
    customFrameError = "The frame picker is not available in combat."
    return
  end
  customFrameError = nil
  -- The window would cover the frames; it opens again afterwards.
  Options:Toggle()
  FramePicker:Start(
    function(frameName)
      local frame, reason = addon:ValidateCustomFrame(frameName)
      return frame ~= nil, reason
    end,
    addCustomFrame,
    function()
      Options:Navigate("fading-frames")
    end
  )
end

local function getCustomFramesCard()
  local rows = {
    {
      type = "button",
      label = "Pick a frame",
      tooltip = "Hides this window and lets you click the frame you want to fade. " ..
        "The mouse wheel switches between the frames under the cursor, right click or Esc cancels.",
      buttonText = "Pick",
      layout = true,
      onClick = startFramePicker
    },
    {
      type = "text",
      label = "Add by name",
      tooltip = "The global name of a frame, e.g. `MyAddonMainFrame`, or a path to a child frame like `BuffFrame.CollapseAndExpandButton`. " ..
        "Press Enter to add it.",
      placeholder = "Frame name",
      layout = true,
      get = function()
        return ""
      end,
      set = function(value)
        if value and strtrim(value) ~= "" then
          addCustomFrame(value)
        end
      end
    }
  }
  if customFrameError then
    rows[#rows + 1] = {type = "notice", label = customFrameError}
  end

  return {
    title = "Custom Frames",
    note = "Fade any other frame, e.g. one of another addon. Custom frames are saved in the profile.",
    rows = rows
  }
end

-------------------------------------------------------------------------------
-- Frame overview

-- Listed frames: total, enabled, enabled with the global settings.
local function countFrames()
  local total, enabled, global = 0, 0, 0
  for _, group in ipairs(getFrameGroups()) do
    for _, frameName in ipairs(group.frames) do
      local frameOptions = addon:GetProfileDB()[frameName]
      total = total + 1
      if frameOptions.Enabled then
        enabled = enabled + 1
        if frameOptions.UseGlobalOptions then
          global = global + 1
        end
      end
    end
  end
  return total, enabled, global
end

local function getFramesOverview()
  local cards = getModuleCards()
  local total, enabled, global = 0, 0, 0
  local customCard = getCustomFramesCard()
  cards[#cards + 1] = customCard

  for _, group in ipairs(getFrameGroups()) do
    local rows = {}
    for _, frameName in ipairs(group.frames) do
      local frameOptions = addon:GetProfileDB()[frameName]
      total = total + 1
      if frameOptions.Enabled then
        enabled = enabled + 1
        if frameOptions.UseGlobalOptions then
          global = global + 1
        end
      end
      rows[#rows + 1] = {
        type = "nav",
        label = getDisplayName(frameName),
        tooltip = getFrameDescription(frameName),
        value = function()
          return getFrameStatus(frameName)
        end,
        toggle = {
          get = function()
            return Options:GetValue(Info("Enabled", frameName))
          end,
          set = function(value)
            setFrameEnabled(frameName, value)
          end
        },
        onClick = function()
          Options:Navigate("fading-frames", frameName)
        end
      }
    end
    if group.custom then
      for _, row in ipairs(rows) do
        customCard.rows[#customCard.rows + 1] = row
      end
    else
      cards[#cards + 1] = {title = group.name, rows = rows}
    end
  end

  local subtitle = ("%d of %d frames enabled, %d of them use the global settings"):format(enabled, total, global)
  return "Frames", subtitle, cards
end

-------------------------------------------------------------------------------
-- Frame links

local function resetAllFrameLinks(profile, frameTable)
  for frameName, _ in pairs(frameTable) do
    if profile[frameName .. "LinkedFrames"] then
      profile[frameName .. "LinkedFrames"] = {}
    end
  end
end

local function getLinkCount(frameName)
  local count = 0
  for _, linked in pairs(addon:GetProfileDB()[frameName .. "LinkedFrames"] or {}) do
    if linked then
      count = count + 1
    end
  end
  return count
end

local linksDescription =
  "You can specify if frames should be faded together if you mouseover one of them. Each link will act like you mouseover all of the frames at the same time.\n\n" ..
  "The linked frames will only be faded if those frames are enabled. Each link is automatically synchronized with all other frames."

local function getLinksOverview()
  local cards = getModuleCards()
  cards[#cards + 1] = {
    title = "Frame Links",
    rows = {
      {type = "description", label = linksDescription},
      {
        type = "button",
        label = "Reset all links",
        buttonText = "Reset",
        layout = true,
        onClick = function()
          resetAllFrameLinks(addon:GetProfileDB(), addon:GetFrameTable())
        end
      }
    }
  }

  for _, group in ipairs(getFrameGroups()) do
    local rows = {}
    for _, frameName in ipairs(group.frames) do
      rows[#rows + 1] = {
        type = "nav",
        label = getDisplayName(frameName),
        tooltip = getFrameDescription(frameName),
        value = function()
          local count = getLinkCount(frameName)
          if count == 0 then
            return OFF_COLOR .. "None|r"
          end
          return CUSTOM_COLOR .. count .. (count == 1 and " link" or " links") .. "|r"
        end,
        onClick = function()
          Options:Navigate("fading-links", frameName)
        end
      }
    end
    cards[#cards + 1] = {title = group.name, rows = rows}
  end
  return "Frame Links", "Frames that fade in together on mouseover", cards
end

local function getLinkDetail(frameName)
  local displayName = getDisplayName(frameName)
  local info = Info(frameName .. "LinkedFrames", frameName)
  local cards = {
    {
      title = displayName,
      note = getFrameDescription(frameName),
      rows = {
        {type = "description", label = "Mouseover on this frame also shows the frames checked here, and the other way round."},
        {
          type = "button",
          label = "Reset " .. displayName .. " links",
          buttonText = "Reset",
          layout = true,
          onClick = function()
            local profile = addon:GetProfileDB()
            local currentFrameLinks = profile[frameName .. "LinkedFrames"] or {}
            for k, _ in pairs(currentFrameLinks) do
              profile[k .. "LinkedFrames"] = {}
            end
            profile[frameName .. "LinkedFrames"] = {}
          end
        }
      }
    }
  }

  for _, group in ipairs(getFrameGroups(frameName)) do
    local rows = {}
    for _, otherFrameName in ipairs(group.frames) do
      rows[#rows + 1] = {
        type = "checkbox",
        label = getDisplayName(otherFrameName),
        get = function()
          return MouseoverFrameFading:GetMultiselectValue(info, otherFrameName)
        end,
        set = function(value)
          MouseoverFrameFading:SetMultiselectValue(info, otherFrameName, value)
        end
      }
    end
    cards[#cards + 1] = {title = group.name, rows = rows}
  end
  return displayName, "Frame Links  ·  `" .. frameName .. "`", cards
end

-------------------------------------------------------------------------------
-- Pages

Options:RegisterPage(
  {
    id = "fading-global",
    section = SECTION,
    label = "Global Settings",
    order = 20,
    searchable = true,
    status = function()
      return Options:IsModuleOn("fading")
    end,
    build = function()
      local cards = getModuleCards()
      for _, card in ipairs(getFrameSettingsCards(GLOBAL)) do
        cards[#cards + 1] = card
      end
      return "Global Settings", "Used by every frame with {Use global options} turned on", cards
    end
  }
)

Options:RegisterPage(
  {
    id = "fading-frames",
    section = SECTION,
    label = "Frames",
    order = 21,
    searchable = true,
    badge = function()
      local total, enabled = countFrames()
      return enabled .. "/" .. total
    end,
    build = function(frameName)
      local profile = addon:GetProfileDB()
      if frameName and type(profile[frameName]) == "table" then
        return getDisplayName(frameName), "Frame Fading  ·  `" .. frameName .. "`", getFrameSettingsCards(frameName)
      end
      return getFramesOverview()
    end
  }
)

Options:RegisterPage(
  {
    id = "fading-links",
    section = SECTION,
    label = "Frame Links",
    order = 22,
    searchable = true,
    build = function(frameName)
      local profile = addon:GetProfileDB()
      if frameName and type(profile[frameName]) == "table" then
        return getLinkDetail(frameName)
      end
      return getLinksOverview()
    end
  }
)

-------------------------------------------------------------------------------
-- Public API

function MouseoverFrameFading:CopyFrom(info, value)
  local fromFrameOptions = addon:GetProfileDB()[value]

  if value == "Global" then
    fromFrameOptions = addon:GetProfileDB()["*Global*"]
  end

  if fromFrameOptions then
    local toFrameOptions = addon:GetProfileDB()[info.arg]
    local copy = addon:tClone(fromFrameOptions)
    -- Only the fade settings are copied, not what the frame is.
    copy.displayName = toFrameOptions.displayName
    copy.description = toFrameOptions.description
    copy.Custom = toFrameOptions.Custom
    copy.Hidden = toFrameOptions.Hidden
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

