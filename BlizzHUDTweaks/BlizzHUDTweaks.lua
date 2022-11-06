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
    ["DebuffFrame"] = {}
  }
}

do
  for frameName, v in pairs(defaultConfig.profile) do
    if frameName ~= "*Global*" then
      v["UseGlobalOptions"] = true
    end

    if tContains({"Minimap", "BuffFrame", "DebuffFrame", "ObjectiveTrackerFrame"}, frameName) then
      v["UseGlobalOptions"] = false
      v["FadeOutOfCombat"] = false
    else
      v["FadeOutOfCombat"] = true
    end

    v["MouseOverInCombat"] = true
    v["FadeDuration"] = 0.0025
    v["InCombatAlpha"] = 0.3
    v["OutOfCombatAlpha"] = 0.6
    v["RestedAreaAlpha"] = 0.3
    v["FadeInCombat"] = false

    v["FadeInRestedArea"] = false
  end
end

--credit https://www.mmo-champion.com/threads/2414999-How-do-I-disable-the-GCD-flash-on-my-bars
function addon:HideGCDFlash()
  for _, v in pairs(_G) do
    if type(v) == "table" and type(v.SetDrawBling) == "function" then
      v:SetDrawBling(false)
    end
  end
end

function addon:LoadProfile()
  -- Do nothing for now
end

function addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("BlizzHUDTweaksDB", defaultConfig, true)

  self.db.RegisterCallback(self, "OnProfileChanged", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileCopied", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileReset", "LoadProfile")

  AC:RegisterOptionsTable("BlizzHUDTweaks_options", BlizzHUDTweaks.GetAceOptions(self.db))
  self.optionsFrame = ACD:AddToBlizOptions("BlizzHUDTweaks_options", "BlizzHUDTweaks")

  local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  AC:RegisterOptionsTable("BlizzHUDTweaks_Profiles", profiles)
  ACD:AddToBlizOptions("BlizzHUDTweaks_Profiles", "Profiles", "BlizzHUDTweaks")

  addon:HideGCDFlash()

  -- TODO: Maybe let the user decide how often it should be updated
  C_Timer.NewTicker(
    0.1,
    function()
      addon:RefreshFrames()
    end
  )
end
