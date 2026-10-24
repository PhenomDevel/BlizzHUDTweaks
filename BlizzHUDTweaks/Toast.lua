local _, BlizzHUDTweaks = ...

local Widgets = BlizzHUDTweaks.Widgets
local colors, fonts = Widgets.colors, Widgets.fonts

--[[
  Short message at the top of the screen, e.g. after the toggle keybind
  ("Frame Fading off"). Plain frame on UIParent with its own fade, so it is
  safe in combat and does not touch Blizzard's shared fade helpers.

  Toast:Show(text, detail)   detail is shown smaller and gray (e.g. the key)
]]

local Toast = {}
BlizzHUDTweaks.Toast = Toast

local LOGO = "Interface\\AddOns\\BlizzHUDTweaks\\Media\\Icons\\BlizzHUDTweaks.blp"
local FADE_IN, HOLD, FADE_OUT = 0.15, 1.6, 0.4
local PADDING = 10

local frame

local function OnUpdate(self, elapsed)
  self.elapsed = self.elapsed + elapsed
  local t = self.elapsed
  if t < FADE_IN then
    self:SetAlpha(t / FADE_IN)
  elseif t < FADE_IN + HOLD then
    self:SetAlpha(1)
  elseif t < FADE_IN + HOLD + FADE_OUT then
    self:SetAlpha(1 - (t - FADE_IN - HOLD) / FADE_OUT)
  else
    self:Hide()
  end
end

local function Create()
  frame = CreateFrame("Frame", "BlizzHUDTweaksToast", UIParent)
  frame:SetPoint("TOP", 0, -140)
  frame:SetHeight(32)
  frame:SetFrameStrata("HIGH")
  frame:EnableMouse(false)
  frame:Hide()
  Widgets.Fill(frame, {colors.window[1], colors.window[2], colors.window[3], 0.94})
  Widgets.Border(frame)

  frame.Logo = frame:CreateTexture(nil, "ARTWORK")
  frame.Logo:SetSize(18, 18)
  frame.Logo:SetPoint("LEFT", PADDING, 0)
  frame.Logo:SetTexture(LOGO)

  frame.Text = Widgets.Text(frame, fonts.body)
  frame.Text:SetPoint("LEFT", frame.Logo, "RIGHT", 8, 0)
  frame.Text:SetJustifyV("MIDDLE")
  frame.Detail = Widgets.Text(frame, fonts.small)
  frame.Detail:SetPoint("LEFT", frame.Text, "RIGHT", 10, 0)
  frame.Detail:SetJustifyV("MIDDLE")

  frame:SetScript("OnUpdate", OnUpdate)
end

function Toast:Show(text, detail)
  if not frame then
    Create()
  end
  frame.Text:SetText(text)
  frame.Detail:SetText(detail or "")
  local width = PADDING + 18 + 8 + frame.Text:GetUnboundedStringWidth() + PADDING
  if detail and detail ~= "" then
    width = width + 10 + frame.Detail:GetUnboundedStringWidth()
  end
  frame:SetWidth(width)
  -- A second toast while one is shown restarts it without fading in again.
  frame.elapsed = frame:IsShown() and FADE_IN or 0
  frame:SetAlpha(frame:IsShown() and 1 or 0)
  frame:Show()
end
