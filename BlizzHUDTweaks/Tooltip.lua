local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Tooltip = addon:GetModule("Tooltip")

local Original_GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor

local function anchorTooltipToMouse()
    GameTooltip_SetDefaultAnchor = function(tooltip, parent)
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end


-------------------------------------------------------------------------------
-- Public API

function Tooltip:AnchorTooltipToMouse()
    if Tooltip:IsEnabled() then
        local profile = addon:GetProfileDB()
        if profile["TooltipAnchorToMouse"] then
            anchorTooltipToMouse()
        end
    end
end

function Tooltip:ResetTooltipAnchor()
    if Tooltip:IsEnabled() then
        GameTooltip_SetDefaultAnchor = Original_GameTooltip_SetDefaultAnchor
    end
end

function Tooltip:InstallHooks()
    if Tooltip:IsEnabled() then
        Tooltip:AnchorTooltipToMouse()
    end
end

function Tooltip:Disable()
    --@debug@
    addon:Print("Disabled Module", addon:ColoredString("Tooltip", "fcba03"))
    --@end-debug@
    Tooltip:ResetTooltipAnchor()
end

function Tooltip:Enable()
    Tooltip:AnchorTooltipToMouse()
    --@debug@
    addon:Print("Enabled Module", addon:ColoredString("Tooltip", "fcba03"))
    --@end-debug@
end

function Tooltip:IsEnabled()
  local enabled = addon:GetProfileDB()["GlobalOptionsTooltipEnabled"] or false
  return enabled
end
