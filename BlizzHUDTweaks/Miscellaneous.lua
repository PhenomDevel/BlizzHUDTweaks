local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Miscellaneous = addon:GetModule("Miscellaneous")

-------------------------------------------------------------------------------
-- Public API

function Miscellaneous:Restore(profile)
  for _, v in ipairs(Miscellaneous.showHideToggableOptions) do
    if profile[v.optionName] and v.frame and v.frame:IsShown() then
      v.frame:Hide()
    end
  end

  for _, v in ipairs(Miscellaneous.textOptions) do
    if profile[v.optionName] and v.frame and v.frame:IsShown() then
      if profile[v.optionName] ~= "" then
        v.frame:SetText(profile[v.optionName])
      end
    end
  end
end
