local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):NewAddon("BlizzHUDTweaks", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local defaultConfig = {
  ["profile"] = {
    ["*Global*"] = {},
    ["PlayerFrame"] = {},
    ["TargetFrame"] = {},
    ["ActionBar1"] = {},
    ["ActionBar2"] = {},
    ["ActionBar3"] = {},
    ["ActionBar4"] = {},
    ["ActionBar5"] = {},
    ["ActionBar6"] = {},
    ["ActionBar7"] = {},
    ["ActionBar8"] = {},
    ["PetActionBar"] = {},
    ["StanceBar"] = {},
    ["MicroButtonAndBagsBar"] = {},
    ["Minimap"] = {},
    ["ObjectiveTrackerFrame"] = {},
    ["BuffFrame"] = {},
    ["DebuffFrame"] = {},
    ["StatusTrackingBar"] = {}
  }
}

do
  for k, v in pairs(defaultConfig.profile) do
    v["UseGlobalOptions"] = false
    v["MouseOverInCombat"] = true
    v["FadeDuration"] = 0.0025
    v["FadeInCombat"] = true
    v["InCombatAlpha"] = 0.3
    v["FadeOutOfCombat"] = true
    v["OutOfCombatAlpha"] = 0.3
    v["FadeInRestedArea"] = true
    v["RestedAreaAlpha"] = 0.3
  end
end

function addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("BlizzHUDTweaksDB", defaultConfig, true)

  AC:RegisterOptionsTable("BlizzHUDTweaks_options", BlizzHUDTweaks.GetAceOptions(self.db))
  self.optionsFrame = ACD:AddToBlizOptions("BlizzHUDTweaks_options", "BlizzHUDTweaks")

  C_Timer.NewTicker(
    0.1,
    function()
      addon:RefreshFrames()
    end
  )
end
