-- luacheck: read globals PlaySound SOUNDKIT InCombatLockdown OKAY
local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local Widgets = BlizzHUDTweaks.Widgets
local colors, fonts = Widgets.colors, Widgets.fonts
local Markup = Widgets.Markup

--[[
  "What's new" window, shown once after an update to a version with notes
  (WhatsNewNotes.lua); every entry newer than the last version seen is
  listed. Fresh installs, dev builds and test releases ("-beta") show nothing.
  The switch at the bottom and the General page turn it off for later
  updates (global setting `whatsNew`).

  WhatsNew:Show(since)   notes newer than `since`, or the newest notes
]]

local WhatsNew = {}
BlizzHUDTweaks.WhatsNew = WhatsNew

local LOGO = "Interface\\AddOns\\BlizzHUDTweaks\\Media\\Logo.blp"
local WIDTH, MAX_HEIGHT = 500, 480
local PADDING = 16
local HEADER_HEIGHT = 48
local FOOTER_HEIGHT = 50
local LOGIN_DELAY = 5
local SCROLL_STEP = 40

local frame, scroll, content, showToggle
local lines = {}

-- "3.2.1" / "v3.3.0-beta1" -> { 3, 2, 1 }, isPrerelease
local function ParseVersion(version)
  version = tostring(version or "")
  local major, minor, patch = version:match("^v?(%d+)%.(%d+)%.?(%d*)")
  if not major then
    return nil
  end
  return {tonumber(major), tonumber(minor), tonumber(patch) or 0}, version:find("-", 1, true) ~= nil
end

local function IsNewer(a, b)
  for i = 1, 3 do
    if a[i] ~= b[i] then
      return a[i] > b[i]
    end
  end
  return false
end

local function GetVersion()
  return C_AddOns.GetAddOnMetadata("BlizzHUDTweaks", "Version")
end

-- Entries newer than `since` (nil: only the newest) up to the running version.
local function CollectEntries(since)
  local current = ParseVersion(GetVersion())
  local sinceVersion = ParseVersion(since)
  local entries = {}
  for _, entry in ipairs(BlizzHUDTweaks.whatsNew) do
    local version = ParseVersion(entry.version)
    local released = not current or not IsNewer(version, current)
    if released and (not sinceVersion or IsNewer(version, sinceVersion)) then
      entries[#entries + 1] = entry
      if not sinceVersion then
        break
      end
    end
  end
  return entries
end

local function AcquireLine(index)
  local line = lines[index]
  if not line then
    line = Widgets.Text(content, fonts.body)
    line:SetWordWrap(true)
    lines[index] = line
  end
  line:Show()
  return line
end

local function Render(entries)
  local width = WIDTH - 2 * PADDING
  local y, count = 0, 0
  local function Add(font, text, gap, indent)
    count = count + 1
    local line = AcquireLine(count)
    line:SetFontObject(font)
    line:SetWidth(width - (indent or 0))
    line:SetText(text)
    y = y + gap
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", indent or 0, -y)
    y = y + line:GetStringHeight()
  end
  for i, entry in ipairs(entries) do
    Add(fonts.title, "Version " .. entry.version, i == 1 and 0 or 20)
    for _, text in ipairs(entry.notes) do
      local heading = text:match("^# (.+)")
      if heading then
        Add(fonts.heading, ("|cff%s%s|r"):format(Widgets.BRAND_HEX, heading), 14)
      else
        Add(fonts.body, "•  " .. Markup(text), 6, 4)
      end
    end
  end
  for i = count + 1, #lines do
    lines[i]:Hide()
  end
  content:SetSize(width, y)
  frame:SetHeight(math.min(MAX_HEIGHT, HEADER_HEIGHT + PADDING + y + PADDING + FOOTER_HEIGHT))
  scroll:SetVerticalScroll(0)
end

local function UpdateToggle()
  showToggle:SetChecked(addon:GetGlobalProfileDB().whatsNew ~= false)
end

local function CreateWindow()
  frame = CreateFrame("Frame", "BlizzHUDTweaksWhatsNewFrame", UIParent)
  frame:SetWidth(WIDTH)
  frame:SetPoint("CENTER", 0, 60)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()
  Widgets.Fill(frame, colors.window)
  Widgets.Border(frame)
  tinsert(UISpecialFrames, frame:GetName())

  local logo = frame:CreateTexture(nil, "ARTWORK")
  logo:SetSize(24, 24)
  logo:SetPoint("TOPLEFT", PADDING, -12)
  logo:SetTexture(LOGO)

  local title = Widgets.Text(frame, fonts.heading)
  title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
  title:SetText(("Blizz|cff%sHUD|rTweaks  What's new"):format(Widgets.BRAND_HEX))

  local headerEdge = frame:CreateTexture(nil, "BORDER")
  headerEdge:SetColorTexture(unpack(colors.border))
  headerEdge:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
  headerEdge:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
  headerEdge:SetHeight(1)

  scroll = CreateFrame("ScrollFrame", nil, frame)
  scroll:SetPoint("TOPLEFT", PADDING, -(HEADER_HEIGHT + PADDING))
  scroll:SetPoint("BOTTOMRIGHT", -PADDING, FOOTER_HEIGHT + PADDING)
  scroll:EnableMouseWheel(true)
  scroll:SetScript(
    "OnMouseWheel",
    function(self, delta)
      local offset = self:GetVerticalScroll() - delta * SCROLL_STEP
      self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), offset)))
    end
  )
  content = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(content)

  local footerEdge = frame:CreateTexture(nil, "BORDER")
  footerEdge:SetColorTexture(unpack(colors.border))
  footerEdge:SetPoint("BOTTOMLEFT", 0, FOOTER_HEIGHT)
  footerEdge:SetPoint("BOTTOMRIGHT", 0, FOOTER_HEIGHT)
  footerEdge:SetHeight(1)

  -- The choice for later updates, right here (also on the General page).
  local toggleRow = CreateFrame("Button", nil, frame)
  toggleRow:SetPoint("BOTTOMLEFT", PADDING, 0)
  toggleRow:SetSize(WIDTH - 2 * PADDING - 110, FOOTER_HEIGHT)
  showToggle = Widgets.CreateToggle(toggleRow)
  showToggle:SetPoint("LEFT")
  showToggle.onToggle = function(value)
    addon:GetGlobalProfileDB().whatsNew = value
    UpdateToggle()
    addon:GetModule("Options"):RefreshValues()
  end
  local toggleLabel = Widgets.Text(toggleRow, fonts.body)
  toggleLabel:SetPoint("LEFT", showToggle, "RIGHT", 10, 0)
  toggleLabel:SetJustifyV("MIDDLE")
  toggleLabel:SetText("Show this window after updates")
  toggleRow:SetScript(
    "OnClick",
    function()
      showToggle:Click()
    end
  )

  local close = Widgets.CreateButton(frame)
  close:SetLabel(OKAY)
  close:SetPoint("BOTTOMRIGHT", -PADDING, (FOOTER_HEIGHT - 22) / 2)
  close:SetScript(
    "OnClick",
    function()
      frame:Hide()
    end
  )

  frame:SetScript(
    "OnShow",
    function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    end
  )
  frame:SetScript(
    "OnHide",
    function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end
  )
end

-- Returns false if there is nothing to show.
function WhatsNew:Show(since)
  local entries = CollectEntries(since)
  if #entries == 0 then
    return false
  end
  if not frame then
    CreateWindow()
  end
  UpdateToggle()
  Render(entries)
  frame:Show()
  frame:Raise()
  return true
end

-- The login can happen in combat (e.g. a /reload); wait until it ends.
local function ShowOutOfCombat(since)
  if not InCombatLockdown() then
    WhatsNew:Show(since)
    return
  end
  local waiter = CreateFrame("Frame")
  waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
  waiter:SetScript(
    "OnEvent",
    function(self)
      self:UnregisterAllEvents()
      WhatsNew:Show(since)
    end
  )
end

-- Called once after the saved variables are loaded; `isNewInstall` when
-- there were none.
function WhatsNew:Initialize(isNewInstall)
  local global = addon:GetGlobalProfileDB()
  local version = GetVersion()
  local current, prerelease = ParseVersion(version)
  if not current or prerelease then
    return
  end
  local last = global.lastVersion
  global.lastVersion = version
  if global.whatsNew == false then
    return
  end
  -- Installs from before this window have no lastVersion and get the newest
  -- notes; fresh installs have nothing to catch up on.
  if not last and isNewInstall then
    return
  end
  local lastVersion = ParseVersion(last)
  if lastVersion and not IsNewer(current, lastVersion) then
    return
  end
  local loader = CreateFrame("Frame")
  loader:RegisterEvent("PLAYER_ENTERING_WORLD")
  loader:SetScript(
    "OnEvent",
    function(self)
      self:UnregisterAllEvents()
      C_Timer.After(
        LOGIN_DELAY,
        function()
          ShowOutOfCombat(last)
        end
      )
    end
  )
end
