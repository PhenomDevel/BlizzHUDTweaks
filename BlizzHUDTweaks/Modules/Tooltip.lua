local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Tooltip = addon:GetModule("Tooltip")

-- using a secure hook instead of replacing the global function prevents
-- Blizzard taint errors.  The hook is registered only once and checks the
-- profile option each time it runs.
local anchorHooked

local function ensureTooltipAnchorHook()
    if not anchorHooked then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            if not InCombatLockdown() and not IsInInstance() then
                local profile = addon:GetProfileDB()
                if profile["TooltipAnchorToMouse"] then
                    tooltip:SetOwner(parent, "ANCHOR_CURSOR")
                end
            end
        end)
        anchorHooked = true
    end
end

-- original override removed; ResetTooltipAnchor becomes a no-op below


-- https://warcraft.wiki.gg/wiki/Struct_TooltipData
-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
-- HUGE THANKS TO idTip where the initial idea came from and just simplified it to my usecase
-- For a much more advanced tooltip info processor, check out idTip: https://www.curseforge.com/wow/addons/idtip
-- Enum.TooltipDataType values whose data.id is a spell ID: Spell, UnitAura,
-- AzeriteEssence, PetAction, EnhancedConduit, RecipeRankInfo, Totem. A set,
-- so the lookup checks the type itself (as a list, types 1-7 matched, e.g.
-- currencies and objects).
local tooltipSpellTypeIds = {
    [1] = true, [7] = true, [8] = true, [11] = true, [13] = true, [17] = true, [18] = true
}

local function getTooltipName(tooltip)
  return tooltip:GetName() or nil
end

local function addSpellID(tooltip, spellID)
    if InCombatLockdown() or IsInInstance() then
        return
    end

    if not spellID then
        return
    end

    -- Abort when tooltip has no name or when :GetName throws
    local ok, name = pcall(getTooltipName, tooltip)
    if not ok or not name then return end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff00ff00Spell ID|r "..spellID)
    tooltip:Show()
end

local function isSecretValue(value)
  return issecretvalue(value) or issecrettable(value)
end

-- register the data processor hook only once to avoid duplicate lines. The
-- instance check happens per tooltip (addSpellID): checked here, logging in
-- inside an instance kept spell IDs off for the whole session.
local spellHooked
local function showSpellIDOnTooltip()
    if TooltipDataProcessor and not spellHooked then
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes,
            function(tooltip, data)
                if isSecretValue(data.type) or isSecretValue(data.guid) or isSecretValue(data.id) then
                    return
                end

                if tooltipSpellTypeIds[data.type] and Tooltip:IsEnabled() and addon:GetProfileDB()["TooltipShowSpellID"] then
                    addSpellID(tooltip, data.id)
                end
            end)
        spellHooked = true
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
    -- The data processor hook checks the option on every tooltip, so turning
    -- it off needs no /reload.
end

function Tooltip:AnchorTooltipToMouse()
    if Tooltip:IsEnabled() then
        local profile = addon:GetProfileDB()
        if profile["TooltipAnchorToMouse"] then
            ensureTooltipAnchorHook()
        end
    end
end

function Tooltip:ResetTooltipAnchor()
    -- secure hooks cannot be removed; the hook only repositions if the option
    -- is enabled so disabling the feature or the module causes it to stop
    -- without taint.  A UI reload is not needed.
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
