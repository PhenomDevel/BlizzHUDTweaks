-- luacheck: read globals EditModeManagerFrame EditModeSystemSettingsDialog InCombatLockdown
local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local Info = Options.Info

local Widgets = BlizzHUDTweaks.Widgets
local colors, fonts = Widgets.colors, Widgets.fonts

--[[
  Quick fade settings in Blizzard's Edit Mode. When a frame that this addon
  fades is selected, a small panel of our own is shown below Blizzard's
  settings dialog: on/off, global or own settings, the two main conditions
  and mouseover, plus a button to the full settings of that frame.

  Only an addition to the options window: same profile values, same setters.
  Blizzard's Edit Mode frames are never changed (that taints Edit Mode); the
  panel is parented to UIParent, only anchored to the dialog, and the dialog
  is followed with hooksecurefunc/HookScript.

  Can be turned off with {Settings in Edit Mode} (account-wide,
  global.editModePanel).
]]

local EditModePanel = {}
BlizzHUDTweaks.EditModePanel = EditModePanel

local LOGO = "Interface\\AddOns\\BlizzHUDTweaks\\Media\\Logo.blp"
local GLOBAL = "*Global*"
local WIDTH = 270
local PADDING = 12
local ROW_HEIGHT = 24
local SLIDER_HEIGHT = 20

local panel, rows, currentFrameName

function EditModePanel:IsEnabled()
  return addon:GetGlobalProfileDB().editModePanel ~= false
end

-- Profile key of the frame selected in Edit Mode, if this addon fades it.
local function findFrameName(systemFrame)
  if not systemFrame then
    return nil
  end
  local profile = addon:GetProfileDB()
  for frameName, mappingOptions in pairs(addon:GetFrameMapping()) do
    if (mappingOptions.mainFrame == systemFrame or mappingOptions.editModeFrame == systemFrame) and type(profile[frameName]) == "table" and not profile[frameName].Hidden then
      return frameName
    end
  end
end

local function getDisplayName(frameName)
  return addon:GetFrameTable()[frameName] or frameName
end

local function getValue(frameName, key)
  return MouseoverFrameFading:GetValue(Info(key, frameName))
end

-- Same setters as the options window, which is refreshed if it is open.
local function setValue(frameName, key, value, layout)
  MouseoverFrameFading:SetValue(Info(key, frameName), value)
  if layout then
    addon:RefreshOptionTables()
  else
    Options:RefreshValues()
  end
end

-------------------------------------------------------------------------------
-- Rows

local function createToggleRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_HEIGHT)
  row:EnableMouse(true)
  row.Label = Widgets.Text(row, fonts.body)
  row.Label:SetPoint("LEFT")
  row.Label:SetPoint("RIGHT", -44, 0)
  row.Label:SetJustifyV("MIDDLE")
  row.Toggle = Widgets.CreateToggle(row)
  row.Toggle:SetPoint("RIGHT")
  row:SetScript("OnEnter", Widgets.ShowTooltip)
  row:SetScript("OnLeave", Widgets.HideTooltip)
  Widgets.ForwardHover(row.Toggle, row)
  return row
end

-- Toggle for a condition and, while it is on, a slider for its alpha.
local function createConditionRow(parent)
  local row = createToggleRow(parent)
  row.Slider = Widgets.CreateSlider(row)
  row.Slider:SetPoint("BOTTOMLEFT", 0, 4)
  row.Slider:SetPoint("BOTTOMRIGHT", -44, 4)
  row.Slider:SetMinMaxValues(0, 100)
  row.Slider:SetValueStep(5)
  row.Value = Widgets.Text(row, fonts.value, "RIGHT")
  row.Value:SetPoint("RIGHT", row, "BOTTOMRIGHT", 0, 11)
  Widgets.ForwardHover(row.Slider, row)
  -- Label and toggle stay in the top line.
  row.Label:ClearAllPoints()
  row.Label:SetPoint("TOPLEFT", 0, -5)
  row.Label:SetPoint("TOPRIGHT", -44, -5)
  row.Toggle:ClearAllPoints()
  row.Toggle:SetPoint("TOPRIGHT", 0, -4)
  return row
end

local function bindToggle(row, label, tooltip, get, set)
  row.Label:SetText(label)
  row.tooltipTitle, row.tooltipText = label, tooltip
  row.Toggle:SetChecked(get() and true or false)
  row.Toggle.onToggle = function(value)
    set(value)
    EditModePanel:Render()
  end
end

local function bindCondition(row, frameName, label, tooltip, toggleKey, alphaKey)
  bindToggle(
    row,
    label,
    tooltip,
    function()
      return getValue(frameName, toggleKey)
    end,
    function(value)
      setValue(frameName, toggleKey, value)
    end
  )
  local on = getValue(frameName, toggleKey) and true or false
  row:SetHeight(on and ROW_HEIGHT + SLIDER_HEIGHT or ROW_HEIGHT)
  row.Slider:SetShown(on)
  row.Value:SetShown(on)
  if on then
    local value = MouseoverFrameFading:GetFadeSliderValue(Info(alphaKey, frameName))
    row.Value:SetText(("%d%%"):format(value))
    row.Slider:SetValue(value)
    row.Slider.onChange = function(newValue)
      MouseoverFrameFading:SetFadeSliderValue(Info(alphaKey, frameName), newValue)
      row.Value:SetText(("%d%%"):format(newValue))
      Options:RefreshValues()
    end
  end
end

-------------------------------------------------------------------------------
-- Panel

local function createPanel()
  panel = CreateFrame("Frame", "BlizzHUDTweaksEditModePanel", UIParent)
  panel:SetWidth(WIDTH)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:EnableMouse(true)
  panel:Hide()
  Widgets.Fill(panel, colors.window)
  Widgets.Border(panel)

  panel.Logo = panel:CreateTexture(nil, "ARTWORK")
  panel.Logo:SetSize(18, 18)
  panel.Logo:SetPoint("TOPLEFT", PADDING, -PADDING)
  panel.Logo:SetTexture(LOGO)

  panel.Title = Widgets.Text(panel, fonts.heading)
  panel.Title:SetPoint("LEFT", panel.Logo, "RIGHT", 8, 0)
  panel.Title:SetText(("Frame Fading  |cff%s·|r  BlizzHUDTweaks"):format(Widgets.BRAND_HEX))

  panel.Subtitle = Widgets.Text(panel, fonts.small)
  panel.Subtitle:SetPoint("TOPLEFT", panel.Logo, "BOTTOMLEFT", 0, -6)
  panel.Subtitle:SetPoint("RIGHT", -PADDING, 0)

  panel.Notice = Widgets.Text(panel, fonts.small)
  panel.Notice:SetTextColor(unpack(colors.notice))
  panel.Notice:SetWordWrap(true)
  panel.Notice:SetWidth(WIDTH - PADDING * 2)

  rows = {
    enabled = createToggleRow(panel),
    useGlobal = createToggleRow(panel),
    outOfCombat = createConditionRow(panel),
    inCombat = createConditionRow(panel),
    mouseover = createToggleRow(panel)
  }

  panel.Info = Widgets.Text(panel, fonts.small)
  panel.Info:SetWordWrap(true)
  panel.Info:SetWidth(WIDTH - PADDING * 2)

  panel.AllSettings = Widgets.CreateButton(panel)
  panel.AllSettings:SetLabel("All settings")
  panel.AllSettings:SetScript(
    "OnClick",
    function()
      if currentFrameName then
        Options:Open("fading-frames", currentFrameName)
      end
    end
  )
end

-- Places the shown elements below each other and sizes the panel to them.
local function stack(elements)
  local y = -(PADDING + 18 + 6 + 14 + 8)
  for _, element in ipairs(elements) do
    element:ClearAllPoints()
    element:SetPoint("TOPLEFT", PADDING, y)
    if element.SetWidth and element ~= panel.AllSettings then
      element:SetPoint("RIGHT", -PADDING, 0)
    end
    element:Show()
    local height = element:GetHeight()
    if element.GetStringHeight then
      height = element:GetStringHeight()
    end
    y = y - height - 6
  end
  panel:SetHeight(-y + PADDING - 6)
end

function EditModePanel:Render()
  if not panel or not currentFrameName then
    return
  end
  local frameName = currentFrameName
  local frameOptions = addon:GetProfileDB()[frameName]
  if not frameOptions then
    EditModePanel:Hide()
    return
  end

  panel.Subtitle:SetText(getDisplayName(frameName))
  for _, row in pairs(rows) do
    row:Hide()
  end
  panel.Notice:Hide()
  panel.Info:Hide()

  local elements = {}
  if not Options:IsModuleOn("fading") then
    panel.Notice:SetText("Frame fading is turned off. Changes are saved and take effect once it is on again.")
    elements[#elements + 1] = panel.Notice
  end

  bindToggle(
    rows.enabled,
    "Fade this frame",
    "Fades this frame. When off, the frame is always shown at full alpha.",
    function()
      return frameOptions.Enabled
    end,
    function(value)
      Options:SetValue(Info("Enabled", frameName), value)
      addon:RefreshOptionTables()
      addon:ResetFrameByMappingOptions(addon:GetFrameMapping()[frameName])
      MouseoverFrameFading:RefreshFrameAlphas()
    end
  )
  elements[#elements + 1] = rows.enabled

  if frameOptions.Enabled then
    bindToggle(
      rows.useGlobal,
      "Use global options",
      "Uses the {Global Settings} instead of own values for this frame.",
      function()
        return frameOptions.UseGlobalOptions
      end,
      function(value)
        setValue(frameName, "UseGlobalOptions", value, true)
      end
    )
    elements[#elements + 1] = rows.useGlobal

    if frameOptions.UseGlobalOptions then
      local global = addon:GetProfileDB()[GLOBAL]
      local function describe(toggleKey, alphaKey)
        if not global[toggleKey] then
          return "off"
        end
        return ("%d%%"):format(MouseoverFrameFading:GetFadeSliderValue(Info(alphaKey, GLOBAL)))
      end
      local text =
        ("Global Settings: out of combat %s, in combat %s.\nTurn off {Use global options} to set own values here."):format(
        describe("FadeOutOfCombat", "OutOfCombatAlpha"),
        describe("FadeInCombat", "InCombatAlpha")
      )
      panel.Info:SetText(Widgets.Markup(text))
      elements[#elements + 1] = panel.Info
    else
      bindCondition(rows.outOfCombat, frameName, "Out of combat", "Alpha while you are not in combat.", "FadeOutOfCombat", "OutOfCombatAlpha")
      bindCondition(rows.inCombat, frameName, "In combat", "Alpha while you are in combat.", "FadeInCombat", "InCombatAlpha")
      bindToggle(
        rows.mouseover,
        "Fade on mouseover",
        "Shows the frame at full alpha while the mouse is over it.",
        function()
          return getValue(frameName, "MouseOverFadeEnabled")
        end,
        function(value)
          setValue(frameName, "MouseOverFadeEnabled", value)
        end
      )
      elements[#elements + 1] = rows.outOfCombat
      elements[#elements + 1] = rows.inCombat
      elements[#elements + 1] = rows.mouseover
    end
  end

  panel.AllSettings.tooltipTitle = "All settings"
  panel.AllSettings.tooltipText = "Opens this frame in the options window: all conditions, frame links and more."
  elements[#elements + 1] = panel.AllSettings
  stack(elements)
end

function EditModePanel:Show(frameName)
  if not panel then
    createPanel()
  end
  currentFrameName = frameName
  panel:ClearAllPoints()
  panel:SetPoint("TOP", EditModeSystemSettingsDialog, "BOTTOM", 0, -6)
  EditModePanel:Render()
  panel:Show()
end

function EditModePanel:Hide()
  currentFrameName = nil
  if panel then
    panel:Hide()
  end
end

-- Blizzard's dialog was attached to a newly selected Edit Mode frame.
local function onAttach(_, systemFrame)
  if not addon:IsEnabled() or not EditModePanel:IsEnabled() then
    EditModePanel:Hide()
    return
  end
  local frameName = findFrameName(systemFrame)
  if frameName then
    EditModePanel:Show(frameName)
  else
    EditModePanel:Hide()
  end
end

function EditModePanel:InstallHooks()
  -- Edit Mode is part of the mainline client (Retail and WoW: Forever); the
  -- guard only keeps a client without it from erroring.
  local dialog = EditModeSystemSettingsDialog
  if self.hooked or not (dialog and dialog.AttachToSystemFrame) then
    return
  end
  self.hooked = true
  hooksecurefunc(dialog, "AttachToSystemFrame", onAttach)
  dialog:HookScript(
    "OnHide",
    function()
      EditModePanel:Hide()
    end
  )
  if EditModeManagerFrame then
    EditModeManagerFrame:HookScript(
      "OnHide",
      function()
        EditModePanel:Hide()
      end
    )
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript(
  "OnEvent",
  function(self)
    self:UnregisterAllEvents()
    EditModePanel:InstallHooks()
  end
)
