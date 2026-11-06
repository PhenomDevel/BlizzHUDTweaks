local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Tooltip = addon:GetModule("Tooltip")
local Info = Options.Info

-------------------------------------------------------------------------------
-- Helper

local function getToggleRow(key, label, desc, apply)
  return {
    type = "checkbox",
    label = label,
    tooltip = desc,
    get = function()
      return Options:GetValue(Info(key))
    end,
    set = function(value)
      Options:SetValue(Info(key), value)
      apply(value)
    end
  }
end

-- Only matters while the tooltip follows the mouse, so it sits below that
-- switch and is read-only while the switch is off.
local function getAnchorInCombatRow()
  local row = getToggleRow(
    "TooltipAnchorInCombat",
    "Also in Combat and Instances",
    "By default the tooltip goes back to its normal position in combat and in instances, " ..
      "because moving it there can cause errors with Blizzard's tooltips. " ..
      "If enabled, it follows the mouse there too, using a lighter method that does not touch the tooltip's content.",
    function()
    end
  )
  row.indent = 26
  row.disabled = not Options:GetValue(Info("TooltipAnchorToMouse"))
  return row
end

local function getCards()
  local moduleCard = Options:GetModuleCard("tooltip")
  local notice = Options:GetModuleOffNotice("tooltip")
  if notice then
    moduleCard.rows = {notice}
  end

  return {
    moduleCard,
    {
      title = "Tooltip",
      rows = {
        getToggleRow(
          "TooltipAnchorToMouse",
          "Anchor Tooltip to Mouse",
          "If enabled, tooltips will be anchored to the mouse cursor.",
          function(value)
            if not value then
              Tooltip:ResetTooltipAnchor()
            else
              Tooltip:AnchorTooltipToMouse()
            end
            -- the combat row below is read-only while this is off
            Options:Refresh()
          end
        ),
        getAnchorInCombatRow(),
        getToggleRow(
          "TooltipShowSpellID",
          "Show Spell ID in Tooltip",
          "If enabled, tooltips will show the spell ID.",
          function(value)
            if not value then
              Tooltip:HideSpellID()
            else
              Tooltip:ShowSpellID()
            end
          end
        )
      }
    }
  }
end

Options:RegisterPage(
  {
    id = "tooltip",
    label = "Tooltip",
    order = 40,
    status = function()
      return Options:IsModuleOn("tooltip")
    end,
    searchable = true,
    build = function()
      return "Tooltip", "Tooltip position and extra information", getCards()
    end
  }
)

-------------------------------------------------------------------------------
-- Public API

function Tooltip:GetValue(info)
  return Options:GetValue(info)
end

function Tooltip:SetValue(info, value)
  Options:SetValue(info, value)
end
