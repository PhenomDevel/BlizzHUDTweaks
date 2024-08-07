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

local function setActionbarWidth(actionbar, padding)
  if actionbar.settingMap and isActionbarInitialized(actionbar) then
    local buttonSize = getButtonSizeForActionbar(actionbar)
    local buttonScale = (actionbar.settingMap[3].displayValue / 100)
    local newWidth

    if actionbar.isHorizontal then
      local numberOfButtonsPerRow

      if actionbar.numRows == 1 then
        numberOfButtonsPerRow = actionbar.numButtonsShowable
      else
        numberOfButtonsPerRow = actionbar.numButtonsShowable / actionbar.numRows
      end

      newWidth = ((numberOfButtonsPerRow * buttonSize) + ((numberOfButtonsPerRow - 1) * padding)) * buttonScale
    else
      local numberOfButtonsPerRow

      if actionbar.numRows == 1 then
        numberOfButtonsPerRow = 1
      else
        numberOfButtonsPerRow = actionbar.numRows
      end

      newWidth = ((numberOfButtonsPerRow * buttonSize) + ((numberOfButtonsPerRow - 1) * padding)) * buttonScale
    end

    actionbar:SetWidth(newWidth)
  end
end

local function setActionbarHeight(actionbar, padding)
  if actionbar.settingMap and isActionbarInitialized(actionbar) then
    local buttonSize = getButtonSizeForActionbar(actionbar)
    local buttonScale = (actionbar.settingMap[3].displayValue / 100)
    local newHeight

    if actionbar.isHorizontal then
      local numberOfButtonsPerRow

      if actionbar.numRows == 1 then
        return
      else
        numberOfButtonsPerRow = actionbar.numRows
      end

      newHeight = ((numberOfButtonsPerRow * buttonSize) + ((numberOfButtonsPerRow - 1) * padding)) * buttonScale
    else
      local numberOfButtonsPerRow

      if actionbar.numRows == 1 then
        return
      else
        numberOfButtonsPerRow = actionbar.numButtonsShowable / actionbar.numRows
      end

      newHeight = ((numberOfButtonsPerRow * buttonSize) + ((numberOfButtonsPerRow - 1) * padding)) * buttonScale
    end

    actionbar:SetHeight(newHeight)
  end
end

local function restoreActionbarButtonHorizontal(options, actionbar, padding)
  if isActionbarInitialized(actionbar) then
    local numCols = actionbar.numButtonsShowable / actionbar.numRows

    local veryFirstButton = _G[options.actionButtonName .. 1]
    veryFirstButton:SetParent(actionbar)
    veryFirstButton:SetPoint("BOTTOMLEFT", actionbar, "BOTTOMLEFT", 0, -0)

    for i = 2, actionbar.numButtonsShowable, 1 do
      local firstOfRow = math.fmod(i - 1, numCols) == 0
      local currentButton = _G[options.actionButtonName .. i]
      local previousButton = _G[options.actionButtonName .. i - 1]
      if firstOfRow then
        local firstButtonPreviousRow = _G[options.actionButtonName .. (i - numCols)]
        currentButton:SetPoint("BOTTOMLEFT", firstButtonPreviousRow, "TOPLEFT", 0, padding)
      else
        currentButton:SetPoint("BOTTOMLEFT", previousButton, "BOTTOMRIGHT", padding, 0)
      end
    end
  end
end

local function restoreActionbarButtonVertical(options, actionbar, padding)
  if isActionbarInitialized(actionbar) then
    local numCols = actionbar.numButtonsShowable / actionbar.numRows

    local veryFirstButton = _G[options.actionButtonName .. 1]
    veryFirstButton:SetParent(actionbar)
    veryFirstButton:SetPoint("TOPLEFT", actionbar, "TOPLEFT", 0, -0)

    for i = 2, actionbar.numButtonsShowable, 1 do
      local firstOfRow = math.fmod(i - 1, numCols) == 0
      local currentButton = _G[options.actionButtonName .. i]
      local previousButton = _G[options.actionButtonName .. i - 1]

      if firstOfRow then
        local firstButtonPreviousRow = _G[options.actionButtonName .. (i - numCols)]
        currentButton:SetPoint("TOPLEFT", firstButtonPreviousRow, "TOPRIGHT", padding, 0)
      else
        currentButton:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -padding)
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
      if actionbar.isHorizontal then
        restoreActionbarButtonHorizontal(options, actionbar, padding)
      else
        restoreActionbarButtonVertical(options, actionbar, padding)
      end
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

function Miscellaneous:RestoreActionbarOriginal(profile)
  for _, v in ipairs(Miscellaneous.actionbarPaddingOverwriteOptions) do
    local actionbar = v.frame
    if actionbar:IsShown() and isActionbarInitialized(actionbar) then
      local padding = actionbar.buttonPadding
      Miscellaneous:RestoreActionbarPadding(profile, v, padding, true)
      Miscellaneous:RestoreActionbarSize(profile, v, padding, true)
    end
  end
end

function Miscellaneous:FlashObjectiveTracker(profile)
  if ObjectiveTrackerFrame:IsShown() then
    if profile["MiscellaneousShowHideObjectiveTrackerUpdateFlash"] and profile["ObjectiveTrackerFrame"].Enabled then
      local globalOptions = profile["*Global*"]
      local frameOptions = profile["ObjectiveTrackerFrame"]
      local fadeDuration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)

      MouseoverFrameFading:Fade(ObjectiveTrackerFrame, 0, 1, fadeDuration, 0, 0)
      ObjectiveTrackerFrame.__BlizzHUDTweaksForceFaded = true

      C_Timer.After(
        profile["MiscellaneousShowHideObjectiveTrackerUpdateFlashDuration"] or 5,
        function()
          ObjectiveTrackerFrame.__BlizzHUDTweaksForceFaded = false
          MouseoverFrameFading:RefreshFrameAlphas()
        end
      )
    end
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
