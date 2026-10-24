-- luacheck: read globals GetCursorPosition PlaySound SOUNDKIT SettingsPanel HideUIPanel GameFontHighlightHuge GameFontHighlight
local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Profiles = addon:GetModule("Profiles")

local Widgets = BlizzHUDTweaks.Widgets
local colors, fonts = Widgets.colors, Widgets.fonts
local Markup = Widgets.Markup

--[[
  Standalone options window (/bht, minimap icon, Blizzard settings entry).

  ┌ header: logo, title, search, close ──────────────────────────────┐
  │ sidebar: pages, grouped │ (back) page title + subtitle            │
  │ into sections           │ cards in 1–3 columns (scrolls)          │
  └─────────────────────────┴───────────────────────────── resize grip ┘

  The option files register pages (Options:RegisterPage). A page builds its
  cards on every render from the current profile, so nothing has to be kept
  in sync. Pages can have detail views (e.g. one frame of Frame Fading),
  opened with Options:Navigate(pageId, detail) and left with the back button.

  The window is resizable; the number of columns follows its width. Each
  card goes to the currently shortest column, so a card never moves when its
  own height changes (only the cards after it). Pages are rebuilt from pooled
  frames whenever the layout changes; plain value changes only refresh the
  visible controls.

  Card spec: { title, note, tooltip, toggle = { get, set }, rows = { rowSpec }, hint }
  Row spec:  { type, label, note, tooltip, get, set, layout, ... } where
             `layout = true` rebuilds the page after `set` (the row shows or
             hides other rows). Types: see rowTypes below.
]]

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1040, 640
local MIN_WIDTH, MIN_HEIGHT = 640, 420
local MAX_WIDTH, MAX_HEIGHT = 1700, 1200
local HEADER_HEIGHT = 56
local SIDEBAR_WIDTH = 210
local PADDING = 16
local SCROLLBAR_WIDTH = 10
local CARD_PADDING = 14
local CARD_GAP = 10
local MIN_COLUMN_WIDTH = 340
local MAX_COLUMNS = 3
local ROW_HEIGHT = 30
local SLIDER_EXTRA = 22
local INPUT_WIDTH = 170
local TEXTAREA_HEIGHT = 64
local SCROLL_STEP = 48

local LOGO = "Interface\\AddOns\\BlizzHUDTweaks\\Media\\Icons\\BlizzHUDTweaks.blp"
local TITLE = ("Blizz|cff%sHUD|rTweaks"):format(Widgets.BRAND_HEX)

-- Derived from the window width by UpdateLayout() before every render.
local columnCount, columnWidth, rowWidth

local frame, scroll, content, sidebar, searchBox, profileButton, backButton, pageTitle, pageSubtitle
local pages = {}
local state = {page = nil, detail = nil, search = ""}

local Render, RefreshValues

-- After a control changed a value: rebuild the page or refresh the controls.
local function Commit(spec, value)
  Widgets.SafeCall(spec.set, value)
  if spec.layout then
    Render()
  else
    RefreshValues()
  end
end

local function Resolve(value)
  if type(value) == "function" then
    return value()
  end
  return value
end

--------------------------------------------------------------------------------
-- Rows
--------------------------------------------------------------------------------
-- A row = label (+ gray note) on the left, a control on the right. Each row
-- type has its own pool and an Update() that reads the bound value.

local function CreateRowBase(parent)
  local row = CreateFrame("Button", nil, parent)
  -- Search hit ({ highlight }).
  row.Highlight = row:CreateTexture(nil, "BACKGROUND")
  row.Highlight:SetPoint("TOPLEFT", -6, 0)
  row.Highlight:SetPoint("BOTTOMRIGHT", 6, 0)
  row.Highlight:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 0.12)
  row.Highlight:Hide()
  row.Label = Widgets.Text(row, fonts.body)
  row.Label:SetPoint("TOPLEFT", 0, -9)
  row.Note = Widgets.Text(row, fonts.small)
  row.Note:SetPoint("TOPLEFT", row.Label, "BOTTOMLEFT", 0, -3)
  row.Note:SetWordWrap(true)
  row:SetScript("OnEnter", Widgets.ShowTooltip)
  row:SetScript("OnLeave", Widgets.HideTooltip)
  return row
end

-- Sets label, note and tooltip; returns the row height.
local function SetupRow(row, spec, controlWidth, baseHeight)
  row:SetWidth(rowWidth)
  row.Label:SetWidth(rowWidth - controlWidth - 16)
  row.Label:SetText(spec.label)
  row.tooltipTitle, row.tooltipText = spec.label, spec.tooltip
  local height = baseHeight
  if spec.note then
    row.Note:SetWidth(rowWidth - controlWidth - 16)
    row.Note:SetText(Markup(spec.note))
    row.Note:Show()
    height = height + row.Note:GetStringHeight() + 2
  else
    row.Note:Hide()
  end
  row:SetHeight(height)
  return height
end

local rowTypes = {}

-- Rows that show live state update themselves twice a second.
local LIVE_INTERVAL = 0.5

local function OnLiveUpdate(row, elapsed)
  row.sinceUpdate = (row.sinceUpdate or 0) + elapsed
  if row.sinceUpdate >= LIVE_INTERVAL then
    row.sinceUpdate = 0
    row:Update()
  end
end


-- On/off switch.
rowTypes.checkbox = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateToggle(row)
    row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Control, row)
    row:SetScript(
      "OnClick",
      function(self)
        if not self.spec.disabled then
          self.Control:Click()
        end
      end
    )
    row.Update = function(self)
      self.Control:SetChecked(not not self.spec.get())
    end
    return row
  end,
  setup = function(row, spec)
    row.Control.onToggle = function(value)
      Commit(spec, value)
    end
    return SetupRow(row, spec, 32, ROW_HEIGHT)
  end
}

local function FormatSliderValue(spec, value)
  if spec.format then
    return spec.format(value)
  end
  if value == math.floor(value) then
    return tostring(value)
  end
  return ("%.2f"):format(value)
end

-- Slider below the label, value on the right ({ min, max, step, format, default }).
rowTypes.slider = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Value = Widgets.Text(row, fonts.value, "RIGHT")
    row.Value:SetPoint("TOPRIGHT", 0, -9)
    row.Control = Widgets.CreateSlider(row)
    Widgets.ForwardHover(row.Control, row)
    row.Update = function(self)
      local value = self.spec.get()
      if value == nil then
        -- Never set: show what applies instead ({ default }).
        value = self.spec.default or self.spec.min
      end
      self.Value:SetText(FormatSliderValue(self.spec, value))
      if not self.Control:IsDraggingThumb() then
        self.Control:SetValue(value)
      end
    end
    return row
  end,
  setup = function(row, spec)
    local slider = row.Control
    slider:SetMinMaxValues(spec.min, spec.max)
    slider:SetValueStep(spec.step or 1)
    slider.onChange = function(value)
      Commit(spec, value)
      row.Value:SetText(FormatSliderValue(spec, value))
    end
    local height = SetupRow(row, spec, 60, ROW_HEIGHT + SLIDER_EXTRA)
    -- The note sits between label and slider.
    slider:ClearAllPoints()
    slider:SetPoint("TOPLEFT", 0, -(height - SLIDER_EXTRA + 2))
    slider:SetPoint("TOPRIGHT", 0, -(height - SLIDER_EXTRA + 2))
    return height
  end
}

-- Choice from a list ({ values = { { value, label } } or a function returning it, placeholder }).
rowTypes.dropdown = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateDropdown(row)
    row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Control, row)
    row.Update = function(self)
      self.Control:Update()
    end
    return row
  end,
  setup = function(row, spec)
    row.Control:SetEntries(
      Resolve(spec.values) or {},
      spec.get,
      function(value)
        Commit(spec, value)
      end,
      spec.placeholder
    )
    return SetupRow(row, spec, row.Control:GetWidth(), ROW_HEIGHT)
  end
}

-- Key capture ("SHIFT-F" etc.).
rowTypes.keybind = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateKeybind(row)
    row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Control, row)
    row.Update = function(self)
      self.Control:Update()
    end
    return row
  end,
  setup = function(row, spec)
    row.Control:SetBinding(
      spec.get,
      function(value)
        Commit(spec, value)
      end
    )
    return SetupRow(row, spec, row.Control:GetWidth(), ROW_HEIGHT)
  end
}

-- Action ({ onClick, buttonText }).
rowTypes.button = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateButton(row)
    row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Control, row)
    row.Control:SetScript(
      "OnClick",
      function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        Widgets.SafeCall(row.spec.onClick)
        if row.spec.layout then
          Render()
        else
          RefreshValues()
        end
      end
    )
    row.Update = function()
    end
    return row
  end,
  setup = function(row, spec)
    row.Control:SetLabel(spec.buttonText or spec.label)
    row.Control:SetDanger(spec.danger)
    return SetupRow(row, spec, row.Control:GetWidth(), ROW_HEIGHT)
  end
}

-- Single-line text ({ placeholder, maxLetters }).
rowTypes.text = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateInput(row, false)
    row.Control:SetWidth(INPUT_WIDTH)
    row.Control:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Control.EditBox, row)
    row.Update = function(self)
      self.Control:Update()
    end
    return row
  end,
  setup = function(row, spec)
    row.Control:SetBinding(
      spec.get,
      function(value)
        Commit(spec, value)
      end,
      spec.placeholder,
      spec.maxLetters
    )
    return SetupRow(row, spec, INPUT_WIDTH, ROW_HEIGHT)
  end
}

-- Multi-line text below the label ({ placeholder, maxLetters, height, readOnly }).
rowTypes.textarea = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Control = Widgets.CreateInput(row, true)
    Widgets.ForwardHover(row.Control.EditBox, row)
    row.Update = function(self)
      self.Control:Update()
    end
    return row
  end,
  setup = function(row, spec)
    local areaHeight = spec.height or TEXTAREA_HEIGHT
    row.Control:SetHeight(areaHeight)
    row.Control:SetBinding(
      spec.get,
      function(value)
        Commit(spec, value)
      end,
      spec.placeholder,
      spec.maxLetters,
      spec.readOnly
    )
    local height = SetupRow(row, spec, 0, ROW_HEIGHT + areaHeight + 6)
    -- The note sits between label and text field.
    local top = height - areaHeight - 4
    row.Control:ClearAllPoints()
    row.Control:SetPoint("TOPLEFT", 0, -top)
    row.Control:SetPoint("TOPRIGHT", 0, -top)
    return height
  end
}

-- Link to another page or a detail view ({ onClick, value, toggle = { get, set },
-- pill, meter, dim }): label, optional status text, optional switch and a
-- chevron. The whole row is clickable; the switch keeps its own click.
--   pill()  -> text, color      small tag, e.g. "Own" / "Global"
--   meter() -> 0..1 or nil      alpha bar with percent, updated live
--   dim()   -> true             gray label, e.g. for a disabled frame
local NAV_CHEVRON = 12
local PILL_WIDTH = 50
local METER_WIDTH = 74

rowTypes.nav = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Hover = row:CreateTexture(nil, "BACKGROUND")
    row.Hover:SetPoint("TOPLEFT", -6, 0)
    row.Hover:SetPoint("BOTTOMRIGHT", 6, 0)
    row.Hover:SetColorTexture(unpack(colors.hover))
    row.Hover:Hide()
    row.OnHoverChanged = function(self, hovered)
      self.Hover:SetShown(hovered)
    end
    row.Chevron = {
      Widgets.Line(row, row, "TOPRIGHT", -6, -(ROW_HEIGHT / 2 - 4), -2, -ROW_HEIGHT / 2),
      Widgets.Line(row, row, "TOPRIGHT", -2, -ROW_HEIGHT / 2, -6, -(ROW_HEIGHT / 2 + 4))
    }
    row.Value = Widgets.Text(row, fonts.small, "RIGHT")
    row.Toggle = Widgets.CreateToggle(row)
    row.Toggle:SetPoint("RIGHT", row, "TOPRIGHT", -(NAV_CHEVRON + 8), -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Toggle, row)

    row.Pill = CreateFrame("Frame", nil, row)
    row.Pill:SetSize(PILL_WIDTH, 16)
    row.Pill.Background = Widgets.Fill(row.Pill, colors.hover)
    row.Pill.Edges = Widgets.Border(row.Pill)
    row.Pill.Text = Widgets.Text(row.Pill, fonts.small, "CENTER")
    row.Pill.Text:SetAllPoints()
    row.Pill.Text:SetJustifyV("MIDDLE")

    row.Meter = CreateFrame("Frame", nil, row)
    row.Meter:SetSize(METER_WIDTH, 16)
    row.Meter.Text = Widgets.Text(row.Meter, fonts.small, "RIGHT")
    row.Meter.Text:SetPoint("RIGHT")
    row.Meter.Text:SetWidth(32)
    row.Meter.Text:SetJustifyV("MIDDLE")
    row.Meter.Track = row.Meter:CreateTexture(nil, "ARTWORK")
    row.Meter.Track:SetColorTexture(unpack(colors.control))
    row.Meter.Track:SetPoint("LEFT")
    row.Meter.Track:SetPoint("RIGHT", row.Meter.Text, "LEFT", -6, 0)
    row.Meter.Track:SetHeight(5)
    row.Meter.Fill = row.Meter:CreateTexture(nil, "OVERLAY")
    row.Meter.Fill:SetColorTexture(Widgets.brand[1], Widgets.brand[2], Widgets.brand[3], 0.85)
    row.Meter.Fill:SetPoint("LEFT", row.Meter.Track)
    row.Meter.Fill:SetHeight(5)

    row:SetScript(
      "OnClick",
      function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        Widgets.HideTooltip(self)
        self.spec.onClick()
      end
    )
    row.Update = function(self)
      local spec = self.spec
      self.Value:SetText(Markup(Resolve(spec.value) or ""))
      if spec.toggle then
        self.Toggle:SetChecked(not not spec.toggle.get())
      end
      self.Label:SetTextColor(unpack(Resolve(spec.dim) and colors.dim or colors.text))

      local pillText, pillColor
      if spec.pill then
        pillText, pillColor = spec.pill()
      end
      self.Pill:SetShown(pillText ~= nil)
      if pillText then
        self.Pill.Text:SetText(pillText)
        self.Pill.Text:SetTextColor(unpack(pillColor))
        Widgets.SetBorderColor(self.Pill.Edges, {pillColor[1], pillColor[2], pillColor[3], 0.5})
        self.Pill.Background:SetColorTexture(pillColor[1], pillColor[2], pillColor[3], 0.08)
      end

      local meter = spec.meter and spec.meter()
      self.Meter:SetShown(meter ~= nil)
      if meter then
        local trackWidth = METER_WIDTH - 32 - 6
        self.Meter.Fill:SetWidth(math.max(1, trackWidth * meter))
        self.Meter.Text:SetText(("%d%%"):format(math.floor(meter * 100 + 0.5)))
      end
    end
    return row
  end,
  setup = function(row, spec)
    local controlWidth = NAV_CHEVRON + 70
    row.Value:ClearAllPoints()
    row.Pill:ClearAllPoints()
    row.Meter:ClearAllPoints()
    -- Right to left: chevron, switch, pill, meter (or the status text).
    local anchor, anchorPoint, offset = row, "TOPRIGHT", -(NAV_CHEVRON + 4)
    if spec.toggle then
      row.Toggle:Show()
      row.Toggle.onToggle = function(value)
        Widgets.SafeCall(spec.toggle.set, value)
        Render()
      end
      anchor, anchorPoint, offset = row.Toggle, "LEFT", -8
      controlWidth = controlWidth + 40
    else
      row.Toggle:Hide()
    end
    if spec.pill then
      row.Pill:SetPoint("RIGHT", anchor, anchorPoint, offset, anchor == row and -ROW_HEIGHT / 2 or 0)
      anchor, anchorPoint, offset = row.Pill, "LEFT", -10
      controlWidth = controlWidth + PILL_WIDTH + 10
    end
    if spec.meter then
      row.Meter:SetPoint("RIGHT", anchor, anchorPoint, offset, anchor == row and -ROW_HEIGHT / 2 or 0)
      controlWidth = controlWidth + METER_WIDTH + 10
    end
    row.Value:SetPoint("RIGHT", anchor, anchorPoint, offset, anchor == row and -ROW_HEIGHT / 2 or 0)
    row:SetScript("OnUpdate", spec.meter and OnLiveUpdate or nil)
    return SetupRow(row, spec, controlWidth, ROW_HEIGHT)
  end
}

-- Segmented filter ({ values = { { value, label } }, get, set }): one
-- button per value, the current one highlighted. Always rebuilds the page.
local CHIP_HEIGHT = 22
local CHIP_GAP = 6

local function CreateChip(row)
  local chip = CreateFrame("Button", nil, row)
  chip:SetHeight(CHIP_HEIGHT)
  chip.Background = Widgets.Fill(chip, colors.control)
  chip.Edges = Widgets.Border(chip)
  chip.Text = Widgets.Text(chip, fonts.small, "CENTER")
  chip.Text:SetPoint("LEFT", 10, 0)
  chip.Text:SetPoint("RIGHT", -10, 0)
  chip.Text:SetJustifyV("MIDDLE")
  chip:SetScript(
    "OnClick",
    function(self)
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
      Widgets.SafeCall(row.spec.set, self.value)
      Render()
    end
  )
  return chip
end

rowTypes.chips = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.Chips = {}
    row.Update = function(self)
      local current = self.spec.get()
      for _, chip in ipairs(self.Chips) do
        local selected = chip:IsShown() and chip.value == current
        chip.Background:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], selected and 0.3 or 0)
        Widgets.SetBorderColor(chip.Edges, selected and colors.accent or colors.border)
        chip.Text:SetTextColor(unpack(selected and colors.text or colors.muted))
      end
    end
    return row
  end,
  setup = function(row, spec)
    local values = Resolve(spec.values) or {}
    local x = 0
    for index, entry in ipairs(values) do
      local chip = row.Chips[index] or CreateChip(row)
      row.Chips[index] = chip
      chip.value = entry.value
      chip.Text:SetText(entry.label)
      chip:SetWidth(chip.Text:GetUnboundedStringWidth() + 20)
      chip:ClearAllPoints()
      chip:SetPoint("LEFT", x, 0)
      chip:Show()
      x = x + chip:GetWidth() + CHIP_GAP
    end
    for index = #values + 1, #row.Chips do
      row.Chips[index]:Hide()
    end
    row:SetSize(rowWidth, CHIP_HEIGHT + 12)
    return CHIP_HEIGHT + 12
  end
}

-- Section title inside a card ({ danger } marks actions that overwrite settings).
rowTypes.header = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.Marker = row:CreateTexture(nil, "ARTWORK")
    row.Marker:SetSize(2, 12)
    row.Marker:SetPoint("BOTTOMLEFT", 0, 4)
    row.Label = Widgets.Text(row, fonts.section)
    row.Label:SetPoint("BOTTOMLEFT", row.Marker, "BOTTOMRIGHT", 6, 0)
    row.Update = function()
    end
    return row
  end,
  setup = function(row, spec)
    row:SetSize(rowWidth, 28)
    row.Marker:SetColorTexture(unpack(spec.danger and colors.danger or colors.accent))
    row.Label:SetText(spec.label)
    return 28
  end
}

-- Highlighted, wrapping hint (e.g. "needs a /reload", "module is off");
-- { tone = "ok" | "danger" } for results like a checked import string.
local NOTICE_BAR = 2
local NOTICE_INDENT = NOTICE_BAR + 8

rowTypes.notice = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.Bar = row:CreateTexture(nil, "ARTWORK")
    row.Bar:SetWidth(NOTICE_BAR)
    row.Label = Widgets.Text(row, fonts.small)
    row.Label:SetPoint("TOPLEFT", NOTICE_INDENT, -8)
    row.Label:SetWordWrap(true)
    row.Bar:SetPoint("TOPLEFT", 0, -6)
    row.Bar:SetPoint("BOTTOMLEFT", 0, 4)
    row.Update = function()
    end
    return row
  end,
  setup = function(row, spec)
    local color = colors[spec.tone or "notice"]
    row.Bar:SetColorTexture(unpack(color))
    row.Label:SetTextColor(unpack(color))
    row.Label:SetWidth(rowWidth - NOTICE_INDENT)
    row.Label:SetText(Markup(spec.label))
    local height = row.Label:GetStringHeight() + 14
    row:SetSize(rowWidth, height)
    return height
  end
}

-- Plain, wrapping explanation.
rowTypes.description = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.Label = Widgets.Text(row, fonts.small)
    row.Label:SetPoint("TOPLEFT", 0, -8)
    row.Label:SetWordWrap(true)
    row.Label:SetSpacing(2)
    row.Update = function()
    end
    return row
  end,
  setup = function(row, spec)
    row.Label:SetWidth(rowWidth)
    row.Label:SetText(Markup(spec.label))
    local height = row.Label:GetStringHeight() + 14
    row:SetSize(rowWidth, height)
    return height
  end
}

-- Gray single line, e.g. "More options appear when enabled."
rowTypes.hint = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.Label = Widgets.Text(row, fonts.dim)
    row.Label:SetPoint("TOPLEFT", 0, -2)
    row.Label:SetWordWrap(true)
    row.Update = function()
    end
    return row
  end,
  setup = function(row, spec)
    row.Label:SetWidth(rowWidth)
    row.Label:SetText(Markup(spec.label))
    local height = math.max(18, row.Label:GetStringHeight() + 6)
    row:SetSize(rowWidth, height)
    return height
  end
}

-- One fade condition in a single line ({ index, label, detail, value, toggle,
-- active, expanded, onClick }): priority, name, gray detail, alpha, switch.
-- `active()` marks the condition that applies right now; a click on the row
-- shows or hides its values (rows below with { indent }).
rowTypes.condition = {
  create = function(parent)
    local row = CreateRowBase(parent)
    row.Active = row:CreateTexture(nil, "BACKGROUND")
    row.Active:SetPoint("TOPLEFT", -6, 0)
    row.Active:SetPoint("BOTTOMRIGHT", 6, 0)
    row.Active:SetColorTexture(colors.ok[1], colors.ok[2], colors.ok[3], 0.08)
    row.ActiveBar = row:CreateTexture(nil, "ARTWORK")
    row.ActiveBar:SetPoint("TOPLEFT", -6, 0)
    row.ActiveBar:SetPoint("BOTTOMLEFT", -6, 0)
    row.ActiveBar:SetWidth(2)
    row.ActiveBar:SetColorTexture(unpack(colors.ok))

    row.Number = CreateFrame("Frame", nil, row)
    row.Number:SetSize(18, 18)
    row.Number:SetPoint("LEFT", row, "TOPLEFT", 0, -ROW_HEIGHT / 2)
    Widgets.Border(row.Number)
    row.Number.Text = Widgets.Text(row.Number, fonts.dim, "CENTER")
    row.Number.Text:SetAllPoints()
    row.Number.Text:SetJustifyV("MIDDLE")

    row.Label:ClearAllPoints()
    row.Label:SetPoint("LEFT", row.Number, "RIGHT", 8, 0)
    row.Label:SetJustifyV("MIDDLE")

    row.Toggle = Widgets.CreateToggle(row)
    row.Toggle:SetPoint("RIGHT", row, "TOPRIGHT", 0, -ROW_HEIGHT / 2)
    Widgets.ForwardHover(row.Toggle, row)
    row.Value = Widgets.Text(row, fonts.value, "RIGHT")
    row.Value:SetPoint("RIGHT", row.Toggle, "LEFT", -10, 0)
    row.Value:SetJustifyV("MIDDLE")

    row.Hover = row:CreateTexture(nil, "BACKGROUND")
    row.Hover:SetPoint("TOPLEFT", -6, 0)
    row.Hover:SetPoint("BOTTOMRIGHT", 6, 0)
    row.Hover:SetColorTexture(unpack(colors.hover))
    row.Hover:Hide()
    row.OnHoverChanged = function(self, hovered)
      self.Hover:SetShown(hovered and self.spec.onClick ~= nil and not self.spec.disabled)
    end

    row:SetScript(
      "OnClick",
      function(self)
        if self.spec.onClick and not self.spec.disabled then
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
          self.spec.onClick()
        end
      end
    )
    row:SetScript("OnUpdate", OnLiveUpdate)
    row.Update = function(self)
      local spec = self.spec
      local on = not not spec.toggle.get()
      self.Toggle:SetChecked(on)
      local label = spec.label
      local detail = on and Resolve(spec.detail)
      if detail and detail ~= "" then
        label = ("%s  |cff8f8f94· %s|r"):format(label, detail)
      end
      self.Label:SetText(label)
      self.Label:SetTextColor(unpack(on and colors.text or colors.dim))
      self.Value:SetText(on and Resolve(spec.value) or "")
      local active = spec.active and spec.active() or false
      self.Active:SetShown(active)
      self.ActiveBar:SetShown(active)
    end
    return row
  end,
  setup = function(row, spec)
    row.Number.Text:SetText(spec.index)
    row.Toggle.onToggle = function(value)
      Widgets.SafeCall(spec.toggle.set, value)
      Render()
    end
    local height = SetupRow(row, spec, 32 + 50, ROW_HEIGHT)
    row.Label:SetWidth(rowWidth - 26 - 32 - 50 - 16)
    return height
  end
}

-- What applies right now ({ get = function() return text end }), in a green box.
rowTypes.live = {
  create = function(parent)
    local row = CreateFrame("Frame", nil, parent)
    Widgets.Fill(row, {colors.ok[1], colors.ok[2], colors.ok[3], 0.06})
    Widgets.Border(row, {colors.ok[1], colors.ok[2], colors.ok[3], 0.3})
    row.Dot = row:CreateTexture(nil, "ARTWORK")
    row.Dot:SetSize(6, 6)
    row.Dot:SetPoint("LEFT", 10, 0)
    row.Dot:SetColorTexture(unpack(colors.ok))
    row.Label = Widgets.Text(row, fonts.small)
    row.Label:SetPoint("LEFT", row.Dot, "RIGHT", 8, 0)
    row.Label:SetPoint("RIGHT", -10, 0)
    row.Label:SetJustifyV("MIDDLE")
    row:SetScript("OnUpdate", OnLiveUpdate)
    row.Update = function(self)
      self.Label:SetText(Markup(self.spec.get() or ""))
    end
    return row
  end,
  setup = function(row)
    row:SetSize(rowWidth, 26)
    -- Gap above and below inside the card.
    return 34
  end
}

for _, rowType in pairs(rowTypes) do
  rowType.pool = Widgets.NewPool(rowType.create)
end

--------------------------------------------------------------------------------
-- Cards
--------------------------------------------------------------------------------

local cardPool =
  Widgets.NewPool(
  function(parent)
    local card = CreateFrame("Frame", nil, parent)
    Widgets.Fill(card, colors.card)
    Widgets.Border(card)

    -- Hover area over title and note for the description tooltip.
    card.Header = CreateFrame("Button", nil, card)
    card.Header:SetPoint("TOPLEFT")
    card.Header:SetPoint("TOPRIGHT")
    card.Header:SetScript("OnEnter", Widgets.ShowTooltip)
    card.Header:SetScript("OnLeave", Widgets.HideTooltip)

    card.Title = Widgets.Text(card.Header, fonts.heading)
    card.Title:SetPoint("TOPLEFT", CARD_PADDING, -CARD_PADDING)
    card.Note = Widgets.Text(card.Header, fonts.small)
    card.Note:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -4)
    card.Note:SetWordWrap(true)

    card.Toggle = Widgets.CreateToggle(card.Header)
    card.Toggle:SetPoint("TOPRIGHT", -CARD_PADDING, -CARD_PADDING)
    Widgets.ForwardHover(card.Toggle, card.Header)

    card.Divider = card:CreateTexture(nil, "ARTWORK")
    card.Divider:SetColorTexture(unpack(colors.border))
    card.Divider:SetHeight(1)
    return card
  end
)

local activeRows, activeCards = {}, {}

-- Rows can be indented ({ indent }, e.g. values below a condition) and
-- shown read-only ({ disabled }: dimmed, controls ignore the mouse).
local function AddRow(card, spec, y)
  local rowType = rowTypes[spec.type]
  local row = Widgets.Acquire(rowType.pool, card)
  row.spec = spec
  local indent = spec.indent or 0
  rowWidth = rowWidth - indent
  local height = rowType.setup(row, spec)
  rowWidth = rowWidth + indent
  row:SetPoint("TOPLEFT", CARD_PADDING + indent, -y)
  row:SetAlpha(spec.disabled and 0.45 or 1)
  if row.Control then
    row.Control:EnableMouse(not spec.disabled)
  end
  if row.Toggle then
    row.Toggle:EnableMouse(not spec.disabled)
  end
  if row.Highlight then
    row.Highlight:SetShown(spec.highlight and true or false)
  end
  row:Update()
  activeRows[#activeRows + 1] = row
  return height
end

-- Builds a card at (left, top) of the content frame; returns its height.
local function AddCard(spec, left, top, width)
  local card = Widgets.Acquire(cardPool, content)
  card.spec = spec
  card:SetWidth(width or columnWidth)
  card:SetPoint("TOPLEFT", left, -top)
  -- Room for the toggle switch on the right.
  card.Title:SetWidth(rowWidth - 48)
  card.Note:SetWidth(rowWidth - 48)

  local y
  if spec.title then
    card.Title:SetText(spec.title)
    card.Title:Show()
    y = CARD_PADDING + card.Title:GetStringHeight()
    if spec.note and spec.note ~= "" then
      card.Note:SetText(Markup(spec.note))
      card.Note:Show()
      y = y + 4 + card.Note:GetStringHeight()
    else
      card.Note:Hide()
    end
    y = y + CARD_PADDING
    card.Header:SetHeight(y)
    card.Header:Show()
    card.Header.tooltipTitle, card.Header.tooltipText = spec.title, spec.tooltip
  else
    card.Header:Hide()
    y = 4
  end

  if spec.toggle then
    card.Toggle:SetChecked(not not spec.toggle.get())
    card.Toggle.onToggle = function(value)
      Widgets.SafeCall(spec.toggle.set, value)
      Render()
    end
    card.Toggle:Show()
  else
    card.Toggle:Hide()
  end

  local rows = spec.rows or {}
  local hasRows = #rows > 0 or spec.hint
  if hasRows and spec.title then
    card.Divider:ClearAllPoints()
    card.Divider:SetPoint("TOPLEFT", CARD_PADDING, -y)
    card.Divider:SetPoint("TOPRIGHT", -CARD_PADDING, -y)
    card.Divider:Show()
    y = y + 4
  else
    card.Divider:Hide()
  end
  for _, rowSpec in ipairs(rows) do
    y = y + AddRow(card, rowSpec, y)
  end
  if spec.hint then
    y = y + AddRow(card, {type = "hint", label = spec.hint}, y)
  end
  if hasRows then
    y = y + CARD_PADDING - 4
  end

  card:SetHeight(y)
  activeCards[#activeCards + 1] = card
  return y
end

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

local function SortedPages()
  local list = {}
  for _, page in pairs(pages) do
    list[#list + 1] = page
  end
  table.sort(
    list,
    function(a, b)
      return a.order < b.order
    end
  )
  return list
end

local function Matches(card, query)
  local function Has(text)
    return type(text) == "string" and text:lower():find(query, 1, true)
  end
  if Has(card.title) or Has(card.note) or Has(card.tooltip) then
    return true
  end
  for _, row in ipairs(card.rows or {}) do
    if Has(row.label) or Has(row.tooltip) or Has(row.note) then
      return true
    end
  end
  return false
end

-- Cards of every searchable page that mention the query, tagged with the page.
local function SearchPage()
  local query = state.search:lower()
  local cards = {}
  for _, page in ipairs(SortedPages()) do
    if page.searchable then
      local _, _, pageCards = page.build()
      for _, card in ipairs(pageCards) do
        if Matches(card, query) then
          local label = page.section and (page.section .. " › " .. page.label) or page.label
          card.note = card.note and card.note ~= "" and (label .. "  ·  " .. card.note) or label
          card.title = card.title or page.label
          cards[#cards + 1] = card
        end
      end
    end
  end
  local subtitle = #cards > 0 and ("%d found"):format(#cards) or ('Nothing matches "%s".'):format(state.search)
  return "Search results", subtitle, cards
end

local function GetPage()
  if state.search ~= "" then
    return SearchPage()
  end
  local page = pages[state.page] or SortedPages()[1]
  state.page = page.id
  return page.build(state.detail)
end

--------------------------------------------------------------------------------
-- Scrolling
--------------------------------------------------------------------------------

local function UpdateScrollBar()
  local bar = scroll.Bar
  local range = scroll:GetVerticalScrollRange()
  if range <= 0 then
    bar:Hide()
    return
  end
  bar:Show()
  local visible = scroll:GetHeight()
  local thumbHeight = math.max(24, visible * visible / (visible + range))
  bar.Thumb:SetHeight(thumbHeight)
  bar.Thumb:ClearAllPoints()
  bar.Thumb:SetPoint("TOP", 0, -scroll:GetVerticalScroll() / range * (visible - thumbHeight))
end

local function SetScroll(offset)
  local range = scroll:GetVerticalScrollRange()
  scroll:SetVerticalScroll(math.max(0, math.min(range, offset)))
  UpdateScrollBar()
end

local function OnThumbDrag(thumb)
  local _, cursorY = GetCursorPosition()
  cursorY = cursorY / thumb:GetEffectiveScale()
  local visible = scroll:GetHeight()
  local track = visible - thumb:GetHeight()
  if track > 0 then
    local range = scroll:GetVerticalScrollRange()
    SetScroll(thumb.startScroll + (thumb.startY - cursorY) / track * range)
  end
end

local function CreateScrollArea(parent)
  scroll = CreateFrame("ScrollFrame", nil, parent)
  scroll:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING, -(HEADER_HEIGHT + 64))
  scroll:SetPoint("BOTTOMRIGHT", -(PADDING + SCROLLBAR_WIDTH), PADDING)
  scroll:EnableMouseWheel(true)
  scroll:SetScript(
    "OnMouseWheel",
    function(self, delta)
      SetScroll(self:GetVerticalScroll() - delta * SCROLL_STEP)
    end
  )

  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  local bar = CreateFrame("Frame", nil, parent)
  bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, 0)
  bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 0)
  bar:SetWidth(3)
  Widgets.Fill(bar, colors.hover)
  local thumb = CreateFrame("Frame", nil, bar)
  thumb:SetWidth(3)
  thumb:SetHitRectInsets(-4, -4, 0, 0)
  thumb:EnableMouse(true)
  thumb.Texture = Widgets.Fill(thumb, colors.control)
  thumb:SetScript(
    "OnMouseDown",
    function(self)
      local _, cursorY = GetCursorPosition()
      self.startY = cursorY / self:GetEffectiveScale()
      self.startScroll = scroll:GetVerticalScroll()
      self:SetScript("OnUpdate", OnThumbDrag)
    end
  )
  thumb:SetScript(
    "OnMouseUp",
    function(self)
      self:SetScript("OnUpdate", nil)
    end
  )
  thumb:SetScript(
    "OnEnter",
    function(self)
      self.Texture:SetColorTexture(unpack(colors.muted))
    end
  )
  thumb:SetScript(
    "OnLeave",
    function(self)
      self.Texture:SetColorTexture(unpack(colors.control))
    end
  )
  bar.Thumb = thumb
  scroll.Bar = bar
end

--------------------------------------------------------------------------------
-- Sidebar
--------------------------------------------------------------------------------
-- One entry per page; a page's `section` puts it under a small gray label.
-- `page.status()` (module on/off) adds a dot, on the section label for pages
-- in a section; `page.badge()` adds a small count on the right.

local SIDEBAR_BUTTON_HEIGHT = 28
local DOT_SIZE = 6
local sidebarButtons, sidebarSections = {}, {}

local function SetDot(dot, on)
  dot:SetColorTexture(unpack(on and colors.ok or colors.control))
end

local function UpdateSidebar()
  for _, button in ipairs(sidebarButtons) do
    local page = pages[button.page]
    local selected = state.search == "" and state.page == button.page
    button.Selected:SetShown(selected)
    button.Marker:SetShown(selected)
    button.Label:SetTextColor(unpack(selected and colors.text or colors.muted))

    local status
    if page.status and not page.section then
      status = page.status()
      button.Dot:Show()
      SetDot(button.Dot, status)
    else
      button.Dot:Hide()
    end
    local badge = page.badge and page.badge()
    if page.status and not page.section and not status then
      badge = "Off"
    end
    button.Badge:SetText(badge or "")
  end
  for _, section in ipairs(sidebarSections) do
    if section.page.status then
      section.Dot:Show()
      SetDot(section.Dot, section.page.status())
    else
      section.Dot:Hide()
    end
  end
end

local function SelectPage(page, detail)
  state.page, state.detail = page, detail
  if state.search ~= "" then
    state.search = ""
    searchBox:SetText("")
    searchBox:ClearFocus()
  end
  scroll:SetVerticalScroll(0)
  Render()
end

local function AddSidebarButton(page, y)
  local button = CreateFrame("Button", nil, sidebar)
  button:SetPoint("TOPLEFT", 8, -y)
  button:SetPoint("TOPRIGHT", -8, -y)
  button:SetHeight(SIDEBAR_BUTTON_HEIGHT)
  button.page = page.id

  button.Hover = Widgets.Fill(button, colors.hover)
  button.Hover:Hide()
  button.Selected = Widgets.Fill(button, colors.selected)
  button.Marker = button:CreateTexture(nil, "ARTWORK")
  button.Marker:SetColorTexture(unpack(colors.accent))
  button.Marker:SetPoint("TOPLEFT")
  button.Marker:SetPoint("BOTTOMLEFT")
  button.Marker:SetWidth(2)

  button.Dot = button:CreateTexture(nil, "ARTWORK")
  button.Dot:SetSize(DOT_SIZE, DOT_SIZE)
  button.Dot:SetPoint("LEFT", 12, 0)

  button.Badge = Widgets.Text(button, fonts.dim, "RIGHT")
  button.Badge:SetPoint("RIGHT", -8, 0)
  button.Badge:SetJustifyV("MIDDLE")

  button.Label = Widgets.Text(button, fonts.body)
  local left = page.section and 20 or 12
  if page.status and not page.section then
    left = left + DOT_SIZE + 6
  end
  button.Label:SetPoint("LEFT", left, 0)
  button.Label:SetPoint("RIGHT", button.Badge, "LEFT", -6, 0)
  button.Label:SetJustifyV("MIDDLE")
  button.Label:SetText(page.label)

  button:SetScript(
    "OnEnter",
    function(self)
      self.Hover:Show()
    end
  )
  button:SetScript(
    "OnLeave",
    function(self)
      self.Hover:Hide()
    end
  )
  button:SetScript(
    "OnClick",
    function(self)
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
      SelectPage(self.page)
    end
  )
  sidebarButtons[#sidebarButtons + 1] = button
end

-- The section's first page decides its dot.
local function AddSidebarSection(label, page, y)
  local section = {page = page}
  section.Dot = sidebar:CreateTexture(nil, "ARTWORK")
  section.Dot:SetSize(DOT_SIZE, DOT_SIZE)
  section.Dot:SetPoint("TOPLEFT", 20, -(y + 10))
  local text = Widgets.Text(sidebar, fonts.dim)
  text:SetPoint("TOPLEFT", page.status and 20 + DOT_SIZE + 6 or 20, -(y + 8))
  text:SetText(label:upper())
  sidebarSections[#sidebarSections + 1] = section
end

-- Returns the height the sidebar needs.
local function CreateSidebar(parent)
  sidebar = CreateFrame("Frame", nil, parent)
  sidebar:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
  sidebar:SetPoint("BOTTOMLEFT")
  sidebar:SetWidth(SIDEBAR_WIDTH)
  Widgets.Fill(sidebar, colors.sidebar)
  local edge = sidebar:CreateTexture(nil, "BORDER")
  edge:SetColorTexture(unpack(colors.border))
  edge:SetPoint("TOPRIGHT")
  edge:SetPoint("BOTTOMRIGHT")
  edge:SetWidth(1)

  local y = 10
  local section
  for index, page in ipairs(SortedPages()) do
    if page.section ~= section then
      section = page.section
      if index > 1 then
        y = y + 8
      end
      if section then
        AddSidebarSection(section, page, y)
        y = y + 24
      end
    end
    AddSidebarButton(page, y)
    y = y + SIDEBAR_BUTTON_HEIGHT
  end
  return y + 10
end

--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

local function CreateSearchBox(parent)
  searchBox = CreateFrame("EditBox", nil, parent)
  searchBox:SetSize(180, 26)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject(fonts.body)
  searchBox:SetTextInsets(10, 10, 0, 0)
  searchBox:SetMaxLetters(40)
  Widgets.Fill(searchBox, colors.control)
  Widgets.Border(searchBox)
  searchBox.Placeholder = Widgets.Text(searchBox, fonts.dim)
  searchBox.Placeholder:SetPoint("LEFT", 10, 0)
  searchBox.Placeholder:SetJustifyV("MIDDLE")
  searchBox.Placeholder:SetText("Search")

  local function UpdatePlaceholder(self)
    self.Placeholder:SetShown(self:GetText() == "" and not self:HasFocus())
  end
  searchBox:SetScript("OnEditFocusGained", UpdatePlaceholder)
  searchBox:SetScript("OnEditFocusLost", UpdatePlaceholder)
  searchBox:SetScript(
    "OnEscapePressed",
    function(self)
      self:SetText("")
      self:ClearFocus()
    end
  )
  searchBox:SetScript("OnEnterPressed", searchBox.ClearFocus)
  searchBox:SetScript(
    "OnTextChanged",
    function(self)
      UpdatePlaceholder(self)
      local text = strtrim(self:GetText())
      if text ~= state.search then
        state.search = text
        scroll:SetVerticalScroll(0)
        Render()
      end
    end
  )
  return searchBox
end

-- Square icon button drawn from lines (close, back).
local function CreateIconButton(parent, lineSpecs, onClick)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(26, 26)
  button.Hover = Widgets.Fill(button, colors.hover)
  button.Hover:Hide()
  local lines = {}
  for _, spec in ipairs(lineSpecs) do
    lines[#lines + 1] = Widgets.Line(button, button, "CENTER", unpack(spec))
  end
  local function SetHovered(hovered)
    button.Hover:SetShown(hovered)
    for _, line in ipairs(lines) do
      line:SetColorTexture(unpack(hovered and colors.text or colors.muted))
    end
  end
  button:SetScript(
    "OnEnter",
    function()
      SetHovered(true)
    end
  )
  button:SetScript(
    "OnLeave",
    function()
      SetHovered(false)
    end
  )
  button:SetScript("OnClick", onClick)
  return button
end

-- Every setting belongs to the active profile, so it is always in view; a
-- click opens the profile page.
local function CreateProfileButton(parent)
  profileButton = CreateFrame("Button", nil, parent)
  profileButton:SetHeight(26)
  profileButton.Background = Widgets.Fill(profileButton, colors.window)
  Widgets.Border(profileButton)
  profileButton.Text = Widgets.Text(profileButton, fonts.small)
  profileButton.Text:SetPoint("LEFT", 10, 0)
  profileButton.Text:SetJustifyV("MIDDLE")
  profileButton.Update = function(self)
    self.Text:SetText(("Profile: |cffffffff%s|r"):format(addon.db:GetCurrentProfile()))
    self:SetWidth(math.min(160, self.Text:GetUnboundedStringWidth() + 20))
    self.Text:SetWidth(self:GetWidth() - 20)
  end
  profileButton:SetScript(
    "OnClick",
    function()
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
      SelectPage("profiles")
    end
  )
  profileButton:SetScript(
    "OnEnter",
    function(self)
      self.Background:SetColorTexture(unpack(colors.controlHover))
    end
  )
  profileButton:SetScript(
    "OnLeave",
    function(self)
      self.Background:SetColorTexture(unpack(colors.window))
    end
  )
  return profileButton
end

local function CreateHeader(parent)
  local header = CreateFrame("Frame", nil, parent)
  header:SetPoint("TOPLEFT")
  header:SetPoint("TOPRIGHT")
  header:SetHeight(HEADER_HEIGHT)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript(
    "OnDragStart",
    function()
      frame:StartMoving()
    end
  )
  header:SetScript(
    "OnDragStop",
    function()
      frame:StopMovingOrSizing()
    end
  )

  local logo = header:CreateTexture(nil, "ARTWORK")
  logo:SetSize(28, 28)
  logo:SetPoint("LEFT", PADDING, 0)
  logo:SetTexture(LOGO)

  local title = Widgets.Text(header, fonts.heading)
  title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
  title:SetJustifyV("MIDDLE")
  title:SetText(TITLE)

  local byline = Widgets.Text(header, fonts.small)
  byline:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 1)
  byline:SetText("by Phenom")

  local close =
    CreateIconButton(
    header,
    {{-5, 5, 5, -5}, {-5, -5, 5, 5}},
    function()
      frame:Hide()
    end
  )
  close:SetPoint("RIGHT", -PADDING + 4, 0)
  CreateSearchBox(header):SetPoint("RIGHT", close, "LEFT", -10, 0)
  CreateProfileButton(header):SetPoint("RIGHT", searchBox, "LEFT", -10, 0)

  local edge = header:CreateTexture(nil, "BORDER")
  edge:SetColorTexture(unpack(colors.border))
  edge:SetPoint("BOTTOMLEFT")
  edge:SetPoint("BOTTOMRIGHT")
  edge:SetHeight(1)
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local function UpdateLayout()
  local contentWidth = frame:GetWidth() - SIDEBAR_WIDTH - 2 * PADDING - SCROLLBAR_WIDTH
  columnCount = math.floor((contentWidth + CARD_GAP) / (MIN_COLUMN_WIDTH + CARD_GAP))
  columnCount = math.max(1, math.min(MAX_COLUMNS, columnCount))
  columnWidth = math.floor((contentWidth - (columnCount - 1) * CARD_GAP) / columnCount)
  rowWidth = columnWidth - 2 * CARD_PADDING
  content:SetWidth(contentWidth)
end

-- The back button stands in front of the title on detail views.
local function UpdateTitle(title, subtitle)
  local hasBack = state.search == "" and state.detail ~= nil
  backButton:SetShown(hasBack)
  pageTitle:ClearAllPoints()
  pageTitle:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING + (hasBack and 32 or 0), -(HEADER_HEIGHT + 18))
  pageTitle:SetText(title)
  pageSubtitle:SetText(Markup(subtitle or ""))
end

Render = function()
  local offset = scroll:GetVerticalScroll()
  UpdateLayout()
  for _, rowType in pairs(rowTypes) do
    Widgets.ReleaseAll(rowType.pool)
  end
  Widgets.ReleaseAll(cardPool)
  wipe(activeRows)
  wipe(activeCards)

  local title, subtitle, cards = GetPage()
  UpdateTitle(title, subtitle)

  -- Cards with { fullWidth } (e.g. filters) span all columns above the others.
  local top = 0
  for _, card in ipairs(cards) do
    if card.fullWidth then
      local width = content:GetWidth()
      local columnRowWidth = rowWidth
      rowWidth = width - 2 * CARD_PADDING
      top = top + AddCard(card, 0, top, width) + CARD_GAP
      rowWidth = columnRowWidth
    end
  end

  local columns = {}
  for i = 1, columnCount do
    columns[i] = top
  end
  for _, card in ipairs(cards) do
    if not card.fullWidth then
      local column = 1
    for i = 2, columnCount do
      if columns[i] < columns[column] then
        column = i
      end
    end
      local left = (column - 1) * (columnWidth + CARD_GAP)
      columns[column] = columns[column] + AddCard(card, left, columns[column]) + CARD_GAP
    end
  end
  content:SetHeight(math.max(1, math.max(unpack(columns)) - CARD_GAP))
  scroll:UpdateScrollChildRect()
  SetScroll(offset)
  UpdateSidebar()
  profileButton:Update()
end

RefreshValues = function()
  UpdateSidebar()
  for _, row in ipairs(activeRows) do
    row:Update()
  end
  for _, card in ipairs(activeCards) do
    if card.spec.toggle then
      card.Toggle:SetChecked(not not card.spec.toggle.get())
    end
  end
end

-- Re-render at most every 0.05 s while the window is being resized.
local renderQueued
local function QueueRender()
  if renderQueued then
    return
  end
  renderQueued = true
  C_Timer.After(
    0.05,
    function()
      renderQueued = false
      if frame:IsShown() then
        Render()
      end
    end
  )
end

local function CreateResizeGrip(parent)
  local grip = CreateFrame("Button", nil, parent)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", -1, 1)
  grip:SetFrameLevel(parent:GetFrameLevel() + 20)
  local lines = {
    Widgets.Line(grip, grip, "BOTTOMRIGHT", -13, 3, -3, 13),
    Widgets.Line(grip, grip, "BOTTOMRIGHT", -9, 3, -3, 9),
    Widgets.Line(grip, grip, "BOTTOMRIGHT", -5, 3, -3, 5)
  }
  local function SetColor(color)
    for _, line in ipairs(lines) do
      line:SetColorTexture(unpack(color))
    end
  end
  grip:SetScript(
    "OnEnter",
    function()
      SetColor(colors.text)
    end
  )
  grip:SetScript(
    "OnLeave",
    function()
      SetColor(colors.muted)
    end
  )
  grip:SetScript(
    "OnMouseDown",
    function()
      parent:StartSizing("BOTTOMRIGHT")
    end
  )
  grip:SetScript(
    "OnMouseUp",
    function()
      parent:StopMovingOrSizing()
      local db = addon:GetGlobalProfileDB()
      db.optionsWidth, db.optionsHeight = parent:GetSize()
      Render()
    end
  )
end

local function Clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

local function CreateWindow()
  frame = CreateFrame("Frame", "BlizzHUDTweaksOptionsFrame", UIParent)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:Hide()
  Widgets.Fill(frame, colors.window)
  Widgets.Border(frame)
  tinsert(UISpecialFrames, frame:GetName())

  CreateHeader(frame)
  -- Never shorter than the sidebar's page list.
  local minHeight = math.max(MIN_HEIGHT, HEADER_HEIGHT + CreateSidebar(frame))
  local db = addon:GetGlobalProfileDB()
  frame:SetResizable(true)
  frame:SetResizeBounds(MIN_WIDTH, minHeight, MAX_WIDTH, MAX_HEIGHT)
  frame:SetSize(Clamp(db.optionsWidth or DEFAULT_WIDTH, MIN_WIDTH, MAX_WIDTH), Clamp(db.optionsHeight or DEFAULT_HEIGHT, minHeight, MAX_HEIGHT))
  CreateScrollArea(frame)
  CreateResizeGrip(frame)

  backButton =
    CreateIconButton(
    frame,
    {{2, 6, -3, 0}, {-3, 0, 2, -6}},
    function()
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
      SelectPage(state.page)
    end
  )
  backButton:SetPoint("TOPLEFT", SIDEBAR_WIDTH + PADDING - 4, -(HEADER_HEIGHT + 14))
  pageTitle = Widgets.Text(frame, fonts.title)
  pageSubtitle = Widgets.Text(frame, fonts.small)
  pageSubtitle:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -5)

  frame:SetScript("OnSizeChanged", QueueRender)
  frame:SetScript(
    "OnShow",
    function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
      Render()
    end
  )
  frame:SetScript(
    "OnHide",
    function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
      Widgets.HideTooltip()
      searchBox:ClearFocus()
    end
  )
end

--------------------------------------------------------------------------------
-- Blizzard settings entry
--------------------------------------------------------------------------------
-- Options > AddOns only points to our own window.

local function CreateSettingsPanel()
  local panel = CreateFrame("Frame")

  local logo = panel:CreateTexture(nil, "ARTWORK")
  logo:SetSize(48, 48)
  logo:SetPoint("TOPLEFT", 16, -16)
  logo:SetTexture(LOGO)

  local title = panel:CreateFontString(nil, "OVERLAY")
  title:SetFontObject(GameFontHighlightHuge)
  title:SetPoint("LEFT", logo, "RIGHT", 12, 0)
  title:SetText(TITLE)

  local text = panel:CreateFontString(nil, "OVERLAY")
  text:SetFontObject(GameFontHighlight)
  text:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -16)
  text:SetPoint("RIGHT", -16, 0)
  text:SetJustifyH("LEFT")
  text:SetText("The options have their own window. You can also open it with |cffffd100/bht|r or the minimap icon.")

  local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  button:SetSize(180, 26)
  button:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
  button:SetText("Open options")
  button:SetScript(
    "OnClick",
    function()
      Options:Open()
    end
  )
  return panel
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

-- page = { id, label, order, section, searchable, build = function(detail) return title, subtitle, cards end }
function Options:RegisterPage(page)
  pages[page.id] = page
end

function Options:RegisterBlizzardSettings()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then
    return
  end
  local category = Settings.RegisterCanvasLayoutCategory(CreateSettingsPanel(), "BlizzHUDTweaks")
  Settings.RegisterAddOnCategory(category)
  BlizzHUDTweaks.optionsCategoryID = category:GetID()
end

function Options:Open(page, detail)
  Profiles:ClearInputs()
  if not frame then
    CreateWindow()
  end
  -- Coming from Esc > Options > AddOns: leave Blizzard's panel. Not in
  -- combat, where closing it from addon code could block its protected calls.
  if SettingsPanel and SettingsPanel:IsShown() and not InCombatLockdown() then
    HideUIPanel(SettingsPanel)
  end
  if page then
    state.page, state.detail = page, detail
  end
  if frame:IsShown() then
    Render()
  end
  frame:Show()
  frame:Raise()
end

function Options:Toggle()
  if frame and frame:IsShown() then
    frame:Hide()
  else
    Options:Open()
  end
end

-- Asks before a destructive action; the window must be open.
function Options:Confirm(text, acceptLabel, onAccept)
  if frame and frame:IsShown() then
    Widgets.Confirm(frame, text, acceptLabel, onAccept)
  end
end

-- Opens a page (or one of its detail views) in the open window.
function Options:Navigate(page, detail)
  if frame and frame:IsShown() then
    SelectPage(page, detail)
  else
    Options:Open(page, detail)
  end
end

-- Profile or layout changed elsewhere: rebuild the visible page.
function Options:Refresh()
  if frame and frame:IsShown() then
    Render()
  end
end

-- A value changed elsewhere: update the visible controls.
function Options:RefreshValues()
  if frame and frame:IsShown() then
    RefreshValues()
  end
end
