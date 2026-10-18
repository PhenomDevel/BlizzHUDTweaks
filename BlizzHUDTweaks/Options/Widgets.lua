-- luacheck: read globals CreateColorFromHexString CreateFont STANDARD_TEXT_FONT MenuUtil PlaySound SOUNDKIT strtrim geterrorhandler
local _, BlizzHUDTweaks = ...

--[[
  Flat building blocks for the options window (Options/Window.lua): colors,
  fonts, backgrounds, borders and the controls (toggle switch, slider,
  dropdown, button, text input, keybind). No Blizzard or AceGUI templates, so
  the look is fully ours.
]]

local Widgets = {}
BlizzHUDTweaks.Widgets = Widgets

-- Accent for fills, borders and markers; the lighter brand color is for text.
Widgets.ACCENT_HEX = "2f9bd6"
Widgets.BRAND_HEX = "69ccf0"

local accent = CreateColorFromHexString("ff" .. Widgets.ACCENT_HEX)
local ACCENT = {accent:GetRGB()}

-- All surfaces are opaque; text colors keep at least ~4.5:1 contrast on the
-- card background (dim text is for hints and placeholders only).
local colors = {
  accent = ACCENT,
  window = {0.07, 0.07, 0.08, 1},
  sidebar = {0.09, 0.09, 0.10, 1},
  card = {0.12, 0.12, 0.13, 1},
  control = {0.22, 0.22, 0.24, 1},
  controlHover = {0.28, 0.28, 0.30, 1},
  knobOff = {0.75, 0.75, 0.77, 1},
  border = {1, 1, 1, 0.12},
  hover = {1, 1, 1, 0.05},
  selected = {1, 1, 1, 0.09},
  tooltip = {0.05, 0.05, 0.06, 1},
  tooltipBorder = {1, 1, 1, 0.22},
  text = {0.95, 0.95, 0.95, 1},
  muted = {0.72, 0.72, 0.74, 1},
  dim = {0.56, 0.56, 0.58, 1}
}
Widgets.colors = colors

local function NewFont(name, size, color)
  local font = CreateFont("BlizzHUDTweaksFont" .. name)
  font:SetFont(STANDARD_TEXT_FONT, size, "")
  font:SetShadowOffset(1, -1)
  font:SetShadowColor(0, 0, 0, 0.8)
  font:SetTextColor(unpack(color))
  return font
end

Widgets.fonts = {
  title = NewFont("Title", 18, colors.text),
  heading = NewFont("Heading", 14, colors.text),
  body = NewFont("Body", 12, colors.text),
  small = NewFont("Small", 11, colors.muted),
  dim = NewFont("Dim", 11, colors.dim),
  -- Text stays light; the darker accent is for fills, borders and markers.
  section = NewFont("Section", 11, colors.text),
  tooltip = NewFont("Tooltip", 12, {0.88, 0.88, 0.90, 1}),
  value = NewFont("Value", 12, colors.text)
}
local fonts = Widgets.fonts

-- Text markup ------------------------------------------------------------------
-- Inline markup for texts shown to the user (notes, notices, tooltips), so
-- references stand out from the prose:
--   `name`   technical name (frame, setting)
--   {Label}  an option of this addon

local SETTING_COLOR = "|cff8fe3a8"
local OPTION_COLOR = "|cff8cc4ff"

function Widgets.Markup(text)
  if type(text) ~= "string" then
    return text
  end
  text = text:gsub("`([^`]+)`", SETTING_COLOR .. "%1|r")
  return (text:gsub("{([^{}]+)}", OPTION_COLOR .. "%1|r"))
end
local Markup = Widgets.Markup

-- Calls `func` and routes errors to the default error handler instead of
-- breaking the options window.
function Widgets.SafeCall(func, ...)
  local args = {...}
  local count = select("#", ...)
  return xpcall(
    function()
      return func(unpack(args, 1, count))
    end,
    geterrorhandler()
  )
end

-- Basics ----------------------------------------------------------------------

function Widgets.Fill(frame, color, layer, sublevel)
  local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
  texture:SetAllPoints()
  texture:SetColorTexture(unpack(color))
  return texture
end

-- 1 px border inside the frame's edges.
function Widgets.Border(frame, color)
  color = color or colors.border
  local edges = {}
  for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(unpack(color))
    if side == "TOP" or side == "BOTTOM" then
      line:SetPoint(side .. "LEFT")
      line:SetPoint(side .. "RIGHT")
      line:SetHeight(1)
    else
      line:SetPoint("TOP" .. side)
      line:SetPoint("BOTTOM" .. side)
      line:SetWidth(1)
    end
    edges[#edges + 1] = line
  end
  return edges
end

function Widgets.SetBorderColor(edges, color)
  for _, edge in ipairs(edges) do
    edge:SetColorTexture(unpack(color))
  end
end

function Widgets.Text(parent, font, justify)
  local text = parent:CreateFontString(nil, "OVERLAY")
  text:SetFontObject(font)
  text:SetJustifyH(justify or "LEFT")
  text:SetJustifyV("TOP")
  text:SetWordWrap(false)
  return text
end

-- A line drawn between two points relative to `anchor` (icons without textures).
function Widgets.Line(parent, anchor, point, x1, y1, x2, y2, color)
  local line = parent:CreateLine(nil, "OVERLAY")
  line:SetThickness(1.5)
  line:SetColorTexture(unpack(color or colors.muted))
  line:SetStartPoint(point, anchor, x1, y1)
  line:SetEndPoint(point, anchor, x2, y2)
  return line
end

-- Tooltips --------------------------------------------------------------------
-- Own opaque tooltip instead of GameTooltip, whose background follows the
-- player's (or a tooltip addon's) transparency. Frames carry
-- tooltipTitle/tooltipText; children forward their hover to the row so the
-- tooltip stays while the cursor is on a control.

local TOOLTIP_MAX_WIDTH = 300
local TOOLTIP_PADDING = 10
local tooltip

local function GetTooltip()
  if tooltip then
    return tooltip
  end
  tooltip = CreateFrame("Frame", "BlizzHUDTweaksOptionsTooltip", UIParent)
  tooltip:SetFrameStrata("TOOLTIP")
  tooltip:SetClampedToScreen(true)
  tooltip:Hide()
  Widgets.Fill(tooltip, colors.tooltip)
  Widgets.Border(tooltip, colors.tooltipBorder)
  local marker = tooltip:CreateTexture(nil, "ARTWORK")
  marker:SetColorTexture(unpack(ACCENT))
  marker:SetPoint("TOPLEFT", 1, -1)
  marker:SetPoint("TOPRIGHT", -1, -1)
  marker:SetHeight(2)
  tooltip.Title = Widgets.Text(tooltip, fonts.heading)
  tooltip.Title:SetPoint("TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING - 2)
  tooltip.Body = Widgets.Text(tooltip, fonts.tooltip)
  tooltip.Body:SetWordWrap(true)
  tooltip.Body:SetSpacing(2)
  return tooltip
end

local function FitText(text, value)
  text:SetWidth(TOOLTIP_MAX_WIDTH)
  text:SetText(value)
  local width = math.min(TOOLTIP_MAX_WIDTH, text:GetUnboundedStringWidth())
  text:SetWidth(width + 1)
  return width, text:GetStringHeight()
end

-- Shows title + body (lines joined with "\n") with the tooltip's `point`
-- attached to `relativePoint` of `owner`.
function Widgets.ShowTooltipAt(owner, point, relativePoint, x, y, title, body)
  local frame = GetTooltip()
  local titleWidth, titleHeight = FitText(frame.Title, title or "")
  local height = TOOLTIP_PADDING * 2 + 2 + titleHeight
  local bodyWidth = 0
  if body and body ~= "" then
    frame.Body:Show()
    frame.Body:ClearAllPoints()
    frame.Body:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -6)
    local bodyHeight
    bodyWidth, bodyHeight = FitText(frame.Body, Markup(body))
    height = height + 6 + bodyHeight
  else
    frame.Body:Hide()
  end
  frame:SetSize(math.max(titleWidth, bodyWidth) + TOOLTIP_PADDING * 2, height)
  frame:ClearAllPoints()
  frame:SetPoint(point, owner, relativePoint, x, y)
  frame:Show()
end

function Widgets.ShowTooltip(frame)
  if frame.OnHoverChanged then
    frame:OnHoverChanged(true)
  end
  if not frame.tooltipText or frame.tooltipText == "" then
    return
  end
  Widgets.ShowTooltipAt(frame, "BOTTOMLEFT", "TOPLEFT", 0, 4, frame.tooltipTitle, frame.tooltipText)
end

function Widgets.HideTooltip(frame)
  if frame and frame.OnHoverChanged then
    frame:OnHoverChanged(false)
  end
  if tooltip then
    tooltip:Hide()
  end
end

function Widgets.ForwardHover(child, owner)
  child:HookScript(
    "OnEnter",
    function()
      Widgets.ShowTooltip(owner)
    end
  )
  child:HookScript(
    "OnLeave",
    function()
      Widgets.HideTooltip(owner)
    end
  )
end

-- Pools -----------------------------------------------------------------------

function Widgets.NewPool(create)
  return {free = {}, used = {}, create = create}
end

function Widgets.Acquire(pool, parent)
  local frame = table.remove(pool.free) or pool.create(parent)
  frame:SetParent(parent)
  frame:Show()
  pool.used[#pool.used + 1] = frame
  return frame
end

function Widgets.ReleaseAll(pool)
  for _, frame in ipairs(pool.used) do
    frame:Hide()
    frame:ClearAllPoints()
    pool.free[#pool.free + 1] = frame
  end
  wipe(pool.used)
end

-- Toggle switch ---------------------------------------------------------------

local TOGGLE_WIDTH, TOGGLE_HEIGHT, KNOB_SIZE = 32, 16, 12

local function SetToggleChecked(toggle, checked)
  toggle.checked = checked
  toggle.Track:SetColorTexture(unpack(checked and colors.accent or colors.control))
  toggle.Knob:SetColorTexture(unpack(checked and colors.text or colors.knobOff))
  toggle.Knob:ClearAllPoints()
  toggle.Knob:SetPoint(checked and "RIGHT" or "LEFT", checked and -2 or 2, 0)
end

-- toggle.onToggle(newValue) is called on click; the caller sets the new state.
function Widgets.CreateToggle(parent)
  local toggle = CreateFrame("Button", nil, parent)
  toggle:SetSize(TOGGLE_WIDTH, TOGGLE_HEIGHT)
  toggle.Track = Widgets.Fill(toggle, colors.control, "ARTWORK")
  toggle.Knob = toggle:CreateTexture(nil, "OVERLAY")
  toggle.Knob:SetSize(KNOB_SIZE, KNOB_SIZE)
  toggle.SetChecked = SetToggleChecked
  toggle:SetScript(
    "OnClick",
    function(self)
      local checked = not self.checked
      PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
      if self.onToggle then
        self.onToggle(checked)
      end
    end
  )
  toggle:SetChecked(false)
  return toggle
end

-- Slider ----------------------------------------------------------------------

-- slider.onChange(value) is called for user input only.
function Widgets.CreateSlider(parent)
  local slider = CreateFrame("Slider", nil, parent)
  slider:SetOrientation("HORIZONTAL")
  slider:SetHeight(14)
  slider:SetObeyStepOnDrag(true)
  slider:SetHitRectInsets(0, 0, -4, -4)

  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(unpack(colors.control))
  track:SetHeight(4)
  track:SetPoint("LEFT")
  track:SetPoint("RIGHT")

  local thumb = slider:CreateTexture(nil, "OVERLAY")
  thumb:SetSize(8, 14)
  thumb:SetColorTexture(unpack(colors.text))
  slider:SetThumbTexture(thumb)

  local fill = slider:CreateTexture(nil, "ARTWORK")
  fill:SetColorTexture(unpack(colors.accent))
  fill:SetHeight(4)
  fill:SetPoint("LEFT", track)
  fill:SetPoint("RIGHT", thumb, "CENTER")

  slider:SetScript(
    "OnValueChanged",
    function(self, value, userInput)
      if userInput and self.onChange then
        self.onChange(value)
      end
    end
  )
  return slider
end

-- Dropdown --------------------------------------------------------------------

-- dropdown:SetEntries(entries, getValue, setValue, placeholder);
-- entries = { { value = ..., label = ... }, ... }
local DROPDOWN_SCROLL_AFTER = 20
local DROPDOWN_SCROLL_HEIGHT = 400

local function UpdateDropdownText(dropdown)
  local current = dropdown.getValue and dropdown.getValue()
  local text
  for _, entry in ipairs(dropdown.entries or {}) do
    if entry.value == current then
      text = entry.label
    end
  end
  if text then
    dropdown.Text:SetFontObject(fonts.body)
    dropdown.Text:SetText(text)
  else
    dropdown.Text:SetFontObject(fonts.dim)
    dropdown.Text:SetText(dropdown.placeholder or "")
  end
end

function Widgets.CreateDropdown(parent)
  local dropdown = CreateFrame("Button", nil, parent)
  dropdown:SetSize(170, 22)
  dropdown.Background = Widgets.Fill(dropdown, colors.control)
  Widgets.Border(dropdown)
  dropdown.Text = Widgets.Text(dropdown, fonts.body)
  dropdown.Text:SetPoint("LEFT", 8, 0)
  dropdown.Text:SetPoint("RIGHT", -24, 0)
  dropdown.Text:SetJustifyV("MIDDLE")
  -- Chevron
  Widgets.Line(dropdown, dropdown, "RIGHT", -15, 2, -11, -2)
  Widgets.Line(dropdown, dropdown, "RIGHT", -11, -2, -7, 2)

  dropdown.SetEntries = function(self, entries, getValue, setValue, placeholder)
    self.entries, self.getValue, self.setValue, self.placeholder = entries, getValue, setValue, placeholder
    UpdateDropdownText(self)
  end
  dropdown.Update = UpdateDropdownText

  dropdown:SetScript(
    "OnEnter",
    function(self)
      self.Background:SetColorTexture(unpack(colors.controlHover))
    end
  )
  dropdown:SetScript(
    "OnLeave",
    function(self)
      self.Background:SetColorTexture(unpack(colors.control))
    end
  )
  dropdown:SetScript(
    "OnClick",
    function(self)
      MenuUtil.CreateContextMenu(
        self,
        function(_, root)
          -- Long lists (e.g. all frames) scroll instead of filling the screen.
          if #(self.entries or {}) > DROPDOWN_SCROLL_AFTER and root.SetScrollMode then
            root:SetScrollMode(DROPDOWN_SCROLL_HEIGHT)
          end
          for _, entry in ipairs(self.entries or {}) do
            root:CreateRadio(
              entry.label,
              function()
                return self.getValue() == entry.value
              end,
              function()
                self.setValue(entry.value)
                UpdateDropdownText(self)
              end
            )
          end
        end
      )
    end
  )
  return dropdown
end

-- Button ----------------------------------------------------------------------

local function SetButtonHovered(button, hovered)
  button.Background:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], hovered and 0.4 or 0.22)
end

function Widgets.CreateButton(parent)
  local button = CreateFrame("Button", nil, parent)
  button:SetHeight(22)
  button.Background = Widgets.Fill(button, colors.control)
  Widgets.Border(button, {ACCENT[1], ACCENT[2], ACCENT[3], 0.9})
  button.Text = Widgets.Text(button, fonts.value, "CENTER")
  button.Text:SetPoint("LEFT", 10, 0)
  button.Text:SetPoint("RIGHT", -10, 0)
  button.Text:SetJustifyV("MIDDLE")
  button.SetLabel = function(self, text)
    self.Text:SetText(text)
    self:SetWidth(math.max(90, self.Text:GetUnboundedStringWidth() + 24))
  end
  button:SetScript(
    "OnEnter",
    function(self)
      SetButtonHovered(self, true)
    end
  )
  button:SetScript(
    "OnLeave",
    function(self)
      SetButtonHovered(self, false)
    end
  )
  SetButtonHovered(button, false)
  return button
end

-- Text input -------------------------------------------------------------------
-- input:SetBinding(getValue, setValue, placeholder, maxLetters, readOnly). The
-- value is committed on Enter and when the field loses focus; Esc restores it.
-- Multi-line inputs wrap and scroll; line breaks are not kept. Read-only
-- inputs select their whole text on focus, ready to be copied.

local INPUT_INSET = 8

local function SetInputFocused(input, focused)
  Widgets.SetBorderColor(input.Edges, focused and {ACCENT[1], ACCENT[2], ACCENT[3], 0.9} or colors.border)
end

local function UpdatePlaceholder(input)
  local editBox = input.EditBox
  input.Placeholder:SetShown(editBox:GetText() == "" and not editBox:HasFocus())
end

local function Commit(input)
  if input.readOnly then
    return
  end
  local editBox = input.EditBox
  local text = strtrim((editBox:GetText():gsub("[\r\n]+", " ")))
  if text ~= editBox:GetText() then
    editBox:SetText(text)
  end
  if input.setValue and text ~= (input.getValue() or "") then
    input.setValue(text)
  end
end

local function ResetInput(input)
  input.EditBox:SetText(input.getValue and input.getValue() or "")
  UpdatePlaceholder(input)
end

function Widgets.CreateInput(parent, multiline)
  local input = CreateFrame("Frame", nil, parent)
  input:SetHeight(22)
  Widgets.Fill(input, colors.control)
  input.Edges = Widgets.Border(input)

  local editBox = CreateFrame("EditBox", nil, input)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject(fonts.body)
  editBox:SetMultiLine(multiline)
  input.EditBox = editBox

  if multiline then
    -- The edit box grows with its text inside a scroll frame.
    local scroll = CreateFrame("ScrollFrame", nil, input)
    scroll:SetPoint("TOPLEFT", INPUT_INSET, -6)
    scroll:SetPoint("BOTTOMRIGHT", -INPUT_INSET, 6)
    scroll:SetScrollChild(editBox)
    scroll:EnableMouseWheel(true)
    scroll:SetScript(
      "OnMouseWheel",
      function(self, delta)
        local range = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 14)))
      end
    )
    scroll:SetScript(
      "OnSizeChanged",
      function(_, width)
        editBox:SetWidth(width)
      end
    )
    editBox:SetScript(
      "OnCursorChanged",
      function(_, _, y, _, height)
        local offset, visible = scroll:GetVerticalScroll(), scroll:GetHeight()
        y = -y
        if y < offset then
          scroll:SetVerticalScroll(y)
        elseif y + height > offset + visible then
          scroll:SetVerticalScroll(y + height - visible)
        end
      end
    )
    -- Clicks on the padding focus the text as well.
    input:EnableMouse(true)
    input:SetScript(
      "OnMouseDown",
      function()
        editBox:SetFocus()
      end
    )
    input.Scroll = scroll
  else
    editBox:SetAllPoints()
    editBox:SetTextInsets(INPUT_INSET, INPUT_INSET, 0, 0)
  end

  input.Placeholder = Widgets.Text(input, fonts.dim)
  input.Placeholder:SetPoint("TOPLEFT", INPUT_INSET, multiline and -6 or -5)

  editBox:SetScript(
    "OnEditFocusGained",
    function(self)
      SetInputFocused(input, true)
      UpdatePlaceholder(input)
      if input.readOnly then
        self:HighlightText()
      end
    end
  )
  editBox:SetScript(
    "OnEditFocusLost",
    function(self)
      self:HighlightText(0, 0)
      SetInputFocused(input, false)
      Commit(input)
      UpdatePlaceholder(input)
    end
  )
  editBox:SetScript("OnEnterPressed", editBox.ClearFocus)
  editBox:SetScript(
    "OnEscapePressed",
    function(self)
      ResetInput(input)
      self:ClearFocus()
    end
  )
  editBox:SetScript(
    "OnTextChanged",
    function(self, userInput)
      if userInput and input.readOnly then
        ResetInput(input)
        self:HighlightText()
        return
      end
      UpdatePlaceholder(input)
    end
  )

  input.SetBinding = function(self, getValue, setValue, placeholder, maxLetters, readOnly)
    self.getValue, self.setValue, self.readOnly = getValue, setValue, readOnly
    self.Placeholder:SetText(placeholder or "")
    self.EditBox:SetMaxLetters(maxLetters or 0)
    ResetInput(self)
  end
  -- Leaves the text alone while the user is typing in it.
  input.Update = function(self)
    if not self.EditBox:HasFocus() then
      ResetInput(self)
    end
  end
  return input
end

-- Keybind ------------------------------------------------------------------------
-- keybind:SetBinding(getValue, setValue). Click to record the next key press
-- (with modifiers, e.g. "SHIFT-F"); Esc while recording clears the binding,
-- another click cancels. Not available in combat, where the keyboard focus of
-- addon frames may not change.

local MODIFIER_KEYS = {
  LSHIFT = true,
  RSHIFT = true,
  LCTRL = true,
  RCTRL = true,
  LALT = true,
  RALT = true,
  LMETA = true,
  RMETA = true
}

local function UpdateKeybindText(keybind)
  if keybind.recording then
    keybind.Text:SetFontObject(fonts.body)
    keybind.Text:SetText("Press a key...")
    return
  end
  local value = keybind.getValue and keybind.getValue()
  if value and value ~= "" then
    keybind.Text:SetFontObject(fonts.body)
    keybind.Text:SetText(value)
  else
    keybind.Text:SetFontObject(fonts.dim)
    keybind.Text:SetText("Not bound")
  end
end

local function SetRecording(keybind, recording)
  keybind.recording = recording
  keybind:EnableKeyboard(recording)
  keybind:SetPropagateKeyboardInput(not recording)
  Widgets.SetBorderColor(keybind.Edges, recording and {ACCENT[1], ACCENT[2], ACCENT[3], 0.9} or colors.border)
  UpdateKeybindText(keybind)
end

local function OnKeybindKeyDown(self, key)
  if MODIFIER_KEYS[key] then
    return
  end
  local value = ""
  if key ~= "ESCAPE" then
    value = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
  end
  SetRecording(self, false)
  if self.setValue then
    self.setValue(value)
  end
  UpdateKeybindText(self)
end

function Widgets.CreateKeybind(parent)
  local keybind = CreateFrame("Button", nil, parent)
  keybind:SetSize(170, 22)
  keybind.Background = Widgets.Fill(keybind, colors.control)
  keybind.Edges = Widgets.Border(keybind)
  keybind.Text = Widgets.Text(keybind, fonts.body, "CENTER")
  keybind.Text:SetPoint("LEFT", 8, 0)
  keybind.Text:SetPoint("RIGHT", -8, 0)
  keybind.Text:SetJustifyV("MIDDLE")

  keybind.SetBinding = function(self, getValue, setValue)
    self.getValue, self.setValue = getValue, setValue
    if self.recording then
      SetRecording(self, false)
    end
    UpdateKeybindText(self)
  end
  keybind.Update = UpdateKeybindText

  keybind:SetScript(
    "OnEnter",
    function(self)
      self.Background:SetColorTexture(unpack(colors.controlHover))
    end
  )
  keybind:SetScript(
    "OnLeave",
    function(self)
      self.Background:SetColorTexture(unpack(colors.control))
    end
  )
  keybind:SetScript(
    "OnClick",
    function(self)
      if InCombatLockdown() then
        return
      end
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
      SetRecording(self, not self.recording)
    end
  )
  keybind:SetScript("OnKeyDown", OnKeybindKeyDown)
  keybind:SetScript(
    "OnHide",
    function(self)
      if self.recording and not InCombatLockdown() then
        SetRecording(self, false)
      end
    end
  )
  return keybind
end
