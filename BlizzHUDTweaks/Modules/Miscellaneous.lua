local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Miscellaneous = addon:GetModule("Miscellaneous")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")

local function isActionbarInitialized(actionbar)
  if actionbar:GetWidth() > 5 and actionbar:GetHeight() > 5 then
    return true
  end
end

local function getButtonSizeForActionbar(actionbar)
  if actionbar == PetActionBar then
    return PetActionButton1:GetWidth()
  elseif actionbar == StanceBar then
    return StanceButton1:GetWidth()
  else
    return ActionButton1:GetWidth()
  end
end

-- Length of `count` buttons in a line, including the padding between them.
local function lineLength(actionbar, count, padding)
  local buttonScale = actionbar.settingMap[3].displayValue / 100
  return (count * getButtonSizeForActionbar(actionbar) + (count - 1) * padding) * buttonScale
end

local function setActionbarWidth(actionbar, padding)
  if actionbar.settingMap and isActionbarInitialized(actionbar) then
    padding = padding or actionbar.buttonPadding or actionbar.minButtonPadding or 0
    local buttonsPerLine = actionbar.isHorizontal and actionbar.numButtonsShowable / actionbar.numRows or actionbar.numRows
    actionbar:SetWidth(lineLength(actionbar, buttonsPerLine, padding))
  end
end

-- Single-row bars keep their height.
local function setActionbarHeight(actionbar, padding)
  if actionbar.settingMap and isActionbarInitialized(actionbar) and actionbar.numRows ~= 1 then
    padding = padding or actionbar.buttonPadding or actionbar.minButtonPadding or 0
    local buttonsPerLine = actionbar.isHorizontal and actionbar.numRows or actionbar.numButtonsShowable / actionbar.numRows
    actionbar:SetHeight(lineLength(actionbar, buttonsPerLine, padding))
  end
end

-- Re-anchors the buttons of a bar with `padding` between them. Horizontal
-- bars grow right and up from the bottom-left button, vertical bars grow down
-- and right from the top-left button.
local function restoreActionbarButtons(options, actionbar, padding)
  if not isActionbarInitialized(actionbar) then
    return
  end

  local horizontal = actionbar.isHorizontal
  local point = horizontal and "BOTTOMLEFT" or "TOPLEFT"
  local numCols = actionbar.numButtonsShowable / actionbar.numRows

  local veryFirstButton = _G[options.actionButtonName .. 1]
  veryFirstButton:SetParent(actionbar)
  veryFirstButton:SetPoint(point, actionbar, point, 0, 0)

  for i = 2, actionbar.numButtonsShowable, 1 do
    local currentButton = _G[options.actionButtonName .. i]
    if math.fmod(i - 1, numCols) == 0 then
      local firstButtonPreviousRow = _G[options.actionButtonName .. (i - numCols)]
      if horizontal then
        currentButton:SetPoint(point, firstButtonPreviousRow, "TOPLEFT", 0, padding)
      else
        currentButton:SetPoint(point, firstButtonPreviousRow, "TOPRIGHT", padding, 0)
      end
    else
      local previousButton = _G[options.actionButtonName .. i - 1]
      if horizontal then
        currentButton:SetPoint(point, previousButton, "BOTTOMRIGHT", padding, 0)
      else
        currentButton:SetPoint(point, previousButton, "BOTTOMLEFT", 0, -padding)
      end
    end
  end
end

local function overwritePaddingEnabled(profile, options)
  local enabled = profile[options.optionName .. "Enabled"]
  return enabled
end

-------------------------------------------------------------------------------
-- Public API

function Miscellaneous:UpdateFontSize(frame, fontSize)
  if frame and fontSize then
    local font, _, fontFlags = frame:GetFont()
    frame:SetFont(font, fontSize, fontFlags)
  end
end

function Miscellaneous:SetFrameText(frame, value, getOriginalValueFn)
  if frame then
    if value ~= "" then
      frame:SetText(value)
    else
      frame:SetText(getOriginalValueFn())
    end
  end
end

function Miscellaneous:RestoreActionbarSize(profile, options, padding, forced)
  local actionbar = options.frame
  local enabled = overwritePaddingEnabled(profile, options)

  if isActionbarInitialized(actionbar) then
    if actionbar and (enabled or forced) and not InCombatLockdown() then
      padding = padding or actionbar.buttonPadding or actionbar.minButtonPadding or 0
      setActionbarWidth(actionbar, padding)
      setActionbarHeight(actionbar, padding)
    end
  end
end

function Miscellaneous:RestoreActionbarPadding(profile, options, padding, forced)
  local actionbar = options.frame
  local enabled = overwritePaddingEnabled(profile, options)

  if isActionbarInitialized(actionbar) then
    if actionbar and (enabled or forced) and not InCombatLockdown() then
      padding = padding or actionbar.buttonPadding or actionbar.minButtonPadding or 0
      restoreActionbarButtons(options, actionbar, padding)
    end
  end
end

function Miscellaneous:RestoreActionbarPaddings(profile, forcePadding, forceSize)
  for _, v in ipairs(Miscellaneous.options["ActionBarOptions"].options) do
    if profile[v.optionName] then
      local enabled = overwritePaddingEnabled(profile, v)
      local padding = profile[v.optionName]
      local actionbar = v.frame

      if actionbar and padding ~= actionbar.buttonPadding and enabled and isActionbarInitialized(actionbar) then
        if not actionbar.__BlizzHUDTweaksRestoredPadding or forcePadding then
          if actionbar:IsShown() then
            if not actionbar.__BlizzHUDTweaksRestoredSize or forceSize then
              Miscellaneous:RestoreActionbarSize(profile, v, padding)
              actionbar.__BlizzHUDTweaksRestoredSize = true
            end

            Miscellaneous:RestoreActionbarPadding(profile, v, padding)
            actionbar.__BlizzHUDTweaksRestoredPadding = true
            actionbar.__BlizzHUDTweaksOverwritePadding = padding
          end
        end
      end
    end
  end
end

-- Shows a faded frame at full alpha for a while. Each flash restarts the
-- timer; only the latest one fades the frame back, so quick updates (quest
-- progress, XP from a pull) don't cut a running flash short.
local flashGeneration = {}

local function flashFrame(profile, frameName, enabledKey, durationKey)
  if profile[enabledKey] and profile[frameName].Enabled then
    local globalOptions = profile["*Global*"]
    local frameOptions = profile[frameName]
    local fadeDuration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)
    local frame = addon:GetFrameMapping()[frameName].mainFrame

    MouseoverFrameFading:Fade(frame, 0, 1, fadeDuration, 0, 0)
    frame.__BlizzHUDTweaksForceFaded = true

    local generation = (flashGeneration[frameName] or 0) + 1
    flashGeneration[frameName] = generation
    C_Timer.After(
      profile[durationKey] or 5,
      function()
        if flashGeneration[frameName] == generation then
          frame.__BlizzHUDTweaksForceFaded = false
          MouseoverFrameFading:RefreshFrameAlphas()
        end
      end
    )
  end
end

function Miscellaneous:FlashObjectiveTracker(profile)
  if ObjectiveTrackerFrame:IsShown() then
    flashFrame(profile, "ObjectiveTrackerFrame", "MiscellaneousShowHideObjectiveTrackerUpdateFlash", "MiscellaneousShowHideObjectiveTrackerUpdateFlashDuration")
  end
end

function Miscellaneous:FlashExperienceBar(profile)
  if MainStatusTrackingBarContainer:IsShown() then
    flashFrame(profile, "MainStatusTrackingBarContainer", "MiscellaneousShowHideExperienceBarUpdateFlash", "MiscellaneousShowHideExperienceBarUpdateFlashDuration")
  end
end

function Miscellaneous:RestoreOriginal()
  for _, groupOptions in pairs(Miscellaneous.options) do
    for _, option in ipairs(groupOptions.options) do
      if option.restoreOriginalValueFn then
        option.restoreOriginalValueFn(option)
      end
    end
  end
end

function Miscellaneous:RestoreAll(profile)
  if addon:IsEnabled() and Miscellaneous:IsEnabled() then
    for _, groupOptions in pairs(Miscellaneous.options) do
      for _, option in ipairs(groupOptions.options) do
        local value = profile[option.optionName]

        if option.type == "actionbarpaddinggroup" then
          Miscellaneous:RestoreActionbarPadding(addon:GetProfileDB(), option, value)
          Miscellaneous:RestoreActionbarSize(addon:GetProfileDB(), option, value)
        elseif value ~= nil then -- Only apply setfn if the value has been changed since profile creation
          if option.setFn then
            option.setFn(option, nil, value)
          end
        end
      end
    end
  end
end

function Miscellaneous:InstallHooks()
  local restore = function()
    Miscellaneous:RestoreActionbarPaddings(addon:GetProfileDB(), true, true)
  end

  EditModeManagerFrame:HookScript("OnShow", restore)
  EditModeManagerFrame:HookScript("OnHide", restore)
  QuickKeybindFrame:HookScript("OnShow", restore)
  QuickKeybindFrame:HookScript("OnHide", restore)

  if PlayerSpellsFrame then
    PlayerSpellsFrame:HookScript("OnShow", restore)
    PlayerSpellsFrame:HookScript("OnHide", restore)
  end

  for _, groupOptions in pairs(Miscellaneous.options) do
    for _, option in ipairs(groupOptions.options or {}) do
      for _, frameHook in ipairs(option.frameHooks or {}) do
        frameHook(option)
      end
    end
  end
end

function Miscellaneous:Disable()
  local profile = addon:GetProfileDB()
  Miscellaneous:RestoreOriginal(profile)
  --@debug@
  addon:Print("Disabled Module", addon:ColoredString("Miscellaneous", "fcba03"))
  --@end-debug@
end

function Miscellaneous:Enable()
  local profile = addon:GetProfileDB()
  Miscellaneous:RestoreAll(profile)
  --@debug@
  addon:Print("Enabled Module", addon:ColoredString("Miscellaneous", "fcba03"))
  --@end-debug@
end

function Miscellaneous:IsEnabled()
  local enabled = addon:GetProfileDB()["GlobalOptionsMiscellaneousEnabled"] or false
  return enabled
end
