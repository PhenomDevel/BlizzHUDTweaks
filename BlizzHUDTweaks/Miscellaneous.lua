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
    if profile[v.optionName] and v.frame and v.frame:IsShown() then
      if profile[v.optionName] ~= "" then
        local value = profile[v.optionName]
        if v.frames then
          for _, frame in ipairs(v.frames) do
            Miscellaneous:UpdateFontSize(frame, value)
          end
        else
          Miscellaneous:UpdateFontSize(v.frame, value)
        end
      end
    end
  end
end

function Miscellaneous:RestoreTextOverwriteOptions(profile)
  for _, v in ipairs(Miscellaneous.textOverwriteOptions) do
    if profile[v.optionName] and v.frame and v.frame:IsShown() then
      if profile[v.optionName] ~= "" then
        v.frame:SetText(profile[v.optionName])
      end
    end
  end
end

function Miscellaneous:RestoreShowHideOptions(profile)
  for _, v in ipairs(Miscellaneous.showHideOptions) do
    if profile[v.optionName] and v.frame and v.frame:IsShown() then
      v.frame:Hide()
    end
  end
end

function Miscellaneous:RestoreAll(profile)
  Miscellaneous:RestoreFontSizeOptions(profile)
  Miscellaneous:RestoreTextOverwriteOptions(profile)
  Miscellaneous:RestoreShowHideOptions(profile)
end
