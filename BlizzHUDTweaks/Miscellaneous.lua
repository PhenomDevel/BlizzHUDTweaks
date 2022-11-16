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

function Miscellaneous:RestoreOriginal()
  Miscellaneous:RestoreShowHideOriginal()
  Miscellaneous:RestoreTextOverwriteOriginal()
  Miscellaneous:RestoreFontSizeOriginal()
end

function Miscellaneous:RestoreAll(profile)
  Miscellaneous:RestoreFontSizeOptions(profile)
  Miscellaneous:RestoreTextOverwriteOptions(profile)
  Miscellaneous:RestoreShowHideOptions(profile)
end
