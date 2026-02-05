local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Tooltip = addon:GetModule("Tooltip")

local Original_GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor

local function anchorTooltipToMouse()
    GameTooltip_SetDefaultAnchor = function(tooltip, parent)
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end

-- https://warcraft.wiki.gg/wiki/Struct_TooltipData
-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
-- HUGE THANKS TO idTip where the initial idea came from and just simplified it to my usecase
-- For a much more advanced tooltip info processor, check out idTip: https://www.curseforge.com/wow/addons/idtip
local tooltipSpellTypeIds = {
    1, 7, 8, 11, 13, 17, 18
}

local function addSpellID(tooltip, spellID)
    if not spellID then
        return
    end

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("|cff00ff00Spell ID|r", spellID, nil, nil, nil, 255, 255, 255)
    tooltip:Show()
end

local function isSecretValue(value)
  return issecretvalue(value) or issecrettable(value)
end

local function showSpellIDOnTooltip()
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes,
            function(tooltip, data)
                if isSecretValue(data.type) or isSecretValue(data.guid) then
                    return
                end

                if tooltipSpellTypeIds[tonumber(data.type)] then
                    addSpellID(tooltip, data.id)
                end
            end)
    end
end

-------------------------------------------------------------------------------
-- Public API

function Tooltip:ShowSpellID()
    if Tooltip:IsEnabled() then
        local profile = addon:GetProfileDB()
        if profile["TooltipShowSpellID"] then
            showSpellIDOnTooltip()
        end
    end
end

function Tooltip:HideSpellID()
    if Tooltip:IsEnabled() then
        addon:Print("You have to /reload for this option to take effect.", addon:ColoredString("Tooltip", "fcba03"))
    end
end

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
        Tooltip:ShowSpellID()
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
