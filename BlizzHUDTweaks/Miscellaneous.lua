local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Miscellaneous = addon:GetModule("Miscellaneous")

-------------------------------------------------------------------------------
-- Public API

function Miscellaneous:UpdateFontSize(frame, fontSize)
  if frame and fontSize then
    local font, _, fontFlags = frame:GetFont()
    frame:SetFont(font, fontSize, fontFlags)
  end
end

function Miscellaneous:RestoreFontSizeOptions(profile)
  for _, v in ipairs(Miscellaneous.fontSizeOverwriteOptions) do
    if profile[v.optionName] then
      if profile[v.optionName] ~= "" then
        local value = profile[v.optionName]

        if v.frames then
          for _, frame in pairs(v.frames) do
            if frame:IsShown() then
              Miscellaneous:UpdateFontSize(frame, value)
            end
          end
        end
      end
    end
  end
end

function Miscellaneous:RestoreFontSizeOriginal()
  for _, v in ipairs(Miscellaneous.fontSizeOverwriteOptions) do
    for _, frame in ipairs(v.frames) do
      if frame:IsShown() then
        Miscellaneous:UpdateFontSize(frame, 10)
      end
    end
  end
end

function Miscellaneous:SetFrameText(frame, value, getOriginalValueFn)
  if frame then
    if frame:IsShown() and value ~= "" then
      frame:SetText(value)
    else
      frame:SetText(getOriginalValueFn())
    end
  end
end

function Miscellaneous:RestoreTextOverwriteOptions(profile)
  for _, v in ipairs(Miscellaneous.textOverwriteOptions) do
    if profile[v.optionName] then
      Miscellaneous:SetFrameText(v.frame, profile[v.optionName], v.getOriginalValueFn)
    end
  end
end

function Miscellaneous:RestoreTextOverwriteOriginal()
  PlayerName:SetText(UnitName("player"))
end

function Miscellaneous:RestoreShowHideOptions(profile)
  for _, v in ipairs(Miscellaneous.showHideOptions) do
    if profile[v.optionName] then
      if v.frame then
        if v.frame:IsShown() then
          v.frame:Hide()
        end
      end
    end
  end
end

function Miscellaneous:RestoreShowHideOriginal()
  for _, v in ipairs(Miscellaneous.showHideOptions) do
    if not v.frame:IsShown() then
      v.frame:Show()
    end
  end
end

local function getButtonSizeForActionbar(actionbar)
  if actionbar == PetActionBar then
    return PetActionButton1:GetWidth()
  else
    return ActionButton1:GetWidth()
  end
end

local function setActionbarWidth(actionbar, padding)
  if actionbar.settingMap then
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
  if actionbar.settingMap then
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

local function restoreActionbarButtonVertical(options, actionbar, padding)
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

local function overwritePaddingEnabled(profile, options)
  local enabled = profile[options.optionName .. "Enabled"]
  return enabled
end

function Miscellaneous:RestoreActionbarSize(profile, options, padding, forced)
  local actionbar = options.frame
  local enabled = overwritePaddingEnabled(profile, options)

  if actionbar and (enabled or forced) and not InCombatLockdown() then
    setActionbarWidth(actionbar, padding)
    setActionbarHeight(actionbar, padding)
  end
end

function Miscellaneous:RestoreActionbarPadding(profile, options, padding, forced)
  local actionbar = options.frame
  local enabled = overwritePaddingEnabled(profile, options)

  if actionbar and (enabled or forced) and not InCombatLockdown() then
    if actionbar.isHorizontal then
      restoreActionbarButtonHorizontal(options, actionbar, padding)
    else
      restoreActionbarButtonVertical(options, actionbar, padding)
    end
  end
end

function Miscellaneous:RestoreActionbarPaddings(profile, forcePadding, forceSize)
  for _, v in ipairs(Miscellaneous.actionbarPaddingOverwriteOptions) do
    if profile[v.optionName] then
      local enabled = overwritePaddingEnabled(profile, v)
      local padding = profile[v.optionName]
      local actionbar = v.frame

      if actionbar and padding ~= actionbar.buttonPadding and enabled then
        if not actionbar.BlizzHUDTweaksRestoredPadding or forcePadding then
          if actionbar:IsShown() then
            if not actionbar.BlizzHUDTweaksRestoredSize or forceSize then
              Miscellaneous:RestoreActionbarSize(profile, v, padding)
              actionbar.BlizzHUDTweaksRestoredSize = true
            end

            Miscellaneous:RestoreActionbarPadding(profile, v, padding)
            actionbar.BlizzHUDTweaksRestoredPadding = true
            actionbar.BlizzHUDTweaksOverwritePadding = padding
          end
        end
      end
    end
  end
end

function Miscellaneous:RestoreActionbarOriginal(profile)
  for _, v in ipairs(Miscellaneous.actionbarPaddingOverwriteOptions) do
    local actionbar = v.frame
    if actionbar:IsShown() then
      local padding = actionbar.buttonPadding
      Miscellaneous:RestoreActionbarPadding(profile, v, padding, true)
      Miscellaneous:RestoreActionbarSize(profile, v, padding, true)
    end
  end
end

function Miscellaneous:RestoreOriginal(profile)
  Miscellaneous:RestoreShowHideOriginal()
  Miscellaneous:RestoreTextOverwriteOriginal()
  Miscellaneous:RestoreFontSizeOriginal()
  Miscellaneous:RestoreActionbarOriginal(profile)
end

function Miscellaneous:RestoreAll(profile)
  Miscellaneous:RestoreFontSizeOptions(profile)
  Miscellaneous:RestoreTextOverwriteOptions(profile)
  Miscellaneous:RestoreShowHideOptions(profile)
  Miscellaneous:RestoreActionbarPaddings(profile, true, true)
end

function Miscellaneous:InstallHooks()
  local restore = function()
    Miscellaneous:RestoreActionbarPaddings(addon:GetProfileDB(), true, true)
  end

  EditModeManagerFrame:HookScript("OnShow", restore)
  EditModeManagerFrame:HookScript("OnHide", restore)
  QuickKeybindFrame:HookScript("OnShow", restore)
  QuickKeybindFrame:HookScript("OnHide", restore)
  SpellBookFrame:HookScript("OnShow", restore)
  SpellBookFrame:HookScript("OnHide", restore)
end
