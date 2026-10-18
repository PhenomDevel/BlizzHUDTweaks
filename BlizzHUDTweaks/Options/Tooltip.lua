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
          end
        ),
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
