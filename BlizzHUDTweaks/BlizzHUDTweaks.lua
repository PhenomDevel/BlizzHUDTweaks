local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):NewAddon("BlizzHUDTweaks", "AceEvent-3.0", "AceConsole-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local defaultConfig = {
  ["profile"] = {
    ["*Global*"] = {
      displayName = "* |T134063:16:16:0:0:64:64:6:58:6:58|t|cFFa0a832 Global Settings|r",
      description = "You can set global values which can be activated for each frame."
    },
    ["PlayerFrame"] = {
      displayName = "Player Frame"
    },
    ["TargetFrame"] = {
      displayName = "Target Frame"
    },
    ["FocusFrame"] = {
      displayName = "Focus Frame"
    },
    ["ActionBar1"] = {
      displayName = "Action Bar 1"
    },
    ["ActionBar2"] = {
      displayName = "Action Bar 2"
    },
    ["ActionBar3"] = {
      displayName = "Action Bar 3"
    },
    ["ActionBar4"] = {
      displayName = "Action Bar 4"
    },
    ["ActionBar5"] = {
      displayName = "Action Bar 5"
    },
    ["ActionBar6"] = {
      displayName = "Action Bar 6"
    },
    ["ActionBar7"] = {
      displayName = "Action Bar 7"
    },
    ["ActionBar8"] = {
      displayName = "Action Bar 8"
    },
    ["PetActionBar"] = {
      displayName = "Pet Action Bar"
    },
    ["StanceBar"] = {
      displayName = "Stance Bar"
    },
    ["MicroButtonAndBagsBar"] = {
      displayName = "System and Bags Bar"
    },
    ["ObjectiveTrackerFrame"] = {
      displayName = "Objective Tracker"
    },
    ["BuffFrame"] = {
      displayName = "Buff Frame"
    },
    ["DebuffFrame"] = {
      displayName = "Debuff Frame"
    },
    ["ZoneAbilityFrame"] = {
      displayName = "Zone Ability Frame"
    },
    ["MinimapCluster"] = {
      displayName = "Minimap"
    },
    ["StatusTrackingBarManager"] = {
      displayName = "Reputation and Experience Bar"
    },
    ["PlayerCastingBarFrame"] = {
      displayName = "Player Cast Bar"
    },
    ["ExtraActionButtonFrame"] = {
      displayName = "Extra Action Button"
    },
    ["PetFrame"] = {
      displayName = "Pet Frame"
    },
    ["QueueStatusButton"] = {
      displayName = "Queue Status Eye"
    }
  }
}

local frameMapping = {
  ["PlayerFrame"] = PlayerFrame,
  ["TargetFrame"] = TargetFrame,
  ["FocusFrame"] = FocusFrame,
  ["ActionBar1"] = MainMenuBar,
  ["ActionBar2"] = MultiBarBottomLeft,
  ["ActionBar3"] = MultiBarBottomRight,
  ["ActionBar4"] = MultiBarRight,
  ["ActionBar5"] = MultiBarLeft,
  ["ActionBar6"] = MultiBar5,
  ["ActionBar7"] = MultiBar6,
  ["ActionBar8"] = MultiBar7,
  ["PetActionBar"] = PetActionBar,
  ["StanceBar"] = StanceBar,
  ["MicroButtonAndBagsBar"] = MicroButtonAndBagsBar,
  ["ObjectiveTrackerFrame"] = ObjectiveTrackerFrame,
  ["BuffFrame"] = BuffFrame,
  ["DebuffFrame"] = DebuffFrame,
  ["ZoneAbilityFrame"] = ZoneAbilityFrame,
  ["MinimapCluster"] = MinimapCluster,
  ["StatusTrackingBarManager"] = StatusTrackingBarManager,
  ["PlayerCastingBarFrame"] = PlayerCastingBarFrame,
  ["ExtraActionButtonFrame"] = ExtraActionButtonFrame,
  ["PetFrame"] = PetFrame,
  ["QueueStatusButton"] = QueueStatusButton
}

do
  defaultConfig.profile["enabled"] = true

  for frameName, v in pairs(defaultConfig.profile) do
    if type(v) == "table" then
      if frameName ~= "*Global*" then
        v["UseGlobalOptions"] = true
      else
        v["UpdateInterval"] = 0.1
        v["TreatTargetLikeInCombat"] = true
      end

      if tContains({"Minimap", "BuffFrame", "DebuffFrame", "ObjectiveTrackerFrame"}, frameName) then
        v["UseGlobalOptions"] = false
        v["FadeOutOfCombat"] = false
      else
        v["FadeOutOfCombat"] = true
      end

      v["MouseOverInCombat"] = true
      v["FadeDuration"] = 0.25
      v["InCombatAlpha"] = 1
      v["OutOfCombatAlpha"] = 0.6
      v["RestedAreaAlpha"] = 0.3
      v["FadeInCombat"] = true
      v["OutOfCombatFadeDelay"] = 0

      v["FadeInRestedArea"] = false
    end
  end
end

-------------------------------------------------------------------------------
-- Public API

function addon:GetFrameMapping()
  return frameMapping
end

function addon:LoadProfile()
  addon:RefreshFrameAlphas()
  addon:InitializeUpdateTicker()
end

function addon:ClearUpdateTicker()
  if BlizzHUDTweaks.updateTicker then
    BlizzHUDTweaks.updateTicker:Cancel()
  end
end

function addon:StartUpdateTicker(interval)
  BlizzHUDTweaks.updateTicker =
    C_Timer.NewTicker(
    math.min(interval, 1),
    function()
      addon:RefreshMouseoverFrameAlphas()
    end
  )
end

function addon:RefreshUpdateTicker(interval)
  addon:ClearUpdateTicker()

  if not BlizzHUDTweaks.updateTicker or BlizzHUDTweaks.updateTicker:IsCancelled() then
    if interval and interval < 0.01 then
      interval = 0.01
    end

    addon:StartUpdateTicker(interval)
  end
end
function addon:InitializeUpdateTicker()
  if self.db.profile["enabled"] then
    addon:RefreshUpdateTicker(self.db.profile["*Global*"].UpdateInterval or 0.1)
  end
end

function addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("BlizzHUDTweaksDB", defaultConfig, false)

  self.db.RegisterCallback(self, "OnProfileChanged", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileCopied", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileReset", "LoadProfile")

  AC:RegisterOptionsTable("BlizzHUDTweaks_options", addon:GetAceOptions(self.db))
  self.optionsFrame = ACD:AddToBlizOptions("BlizzHUDTweaks_options", "BlizzHUDTweaks")

  local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  AC:RegisterOptionsTable("BlizzHUDTweaks_Profiles", profiles)
  ACD:AddToBlizOptions("BlizzHUDTweaks_Profiles", "Profiles", "BlizzHUDTweaks")

  self:RegisterChatCommand("blizzhudtweaks", "OpenOptions")
  self:RegisterChatCommand("bht", "OpenOptions")

  addon:HideGCDFlash()
  addon:RegisterEvent("PLAYER_REGEN_ENABLED")
  addon:RegisterEvent("PLAYER_REGEN_DISABLED")
  addon:RegisterEvent("PLAYER_UPDATE_RESTING")
  addon:RegisterEvent("PLAYER_TARGET_CHANGED")
  addon:RegisterEvent("PLAYER_ENTERING_WORLD")

  QueueStatusButton:SetParent(UIParent)

  -- TODO: Maybe let the user decide how often it should be updated
  -- NOTE: HookScript would be the better option with OnEnter and OnLeave but it does not trigger for
  -- action bars when the action buttons are mouseovered directly
  addon:InitializeUpdateTicker()
end

function addon:OpenOptions()
  InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function addon:DisableAll()
  addon:Print("Disabled fading for all action bars and frames.")
  addon:ClearUpdateTicker()
  for _, frame in pairs(addon:GetFrameMapping()) do
    frame:SetAlpha(1)
  end
end

function addon:EnableAll()
  addon:Print("Enabled fading of action bars and frames.")
  addon:InitializeUpdateTicker()
  addon:RefreshFrameAlphas()
end

function addon:PLAYER_REGEN_ENABLED()
  BlizzHUDTweaks.inCombat = false
  addon:RefreshFrameAlphas(true)
end

function addon:PLAYER_REGEN_DISABLED()
  BlizzHUDTweaks.inCombat = true
  addon:RefreshFrameAlphas()
end

function addon:PLAYER_UPDATE_RESTING()
  BlizzHUDTweaks.isResting = IsResting("player")
  addon:RefreshFrameAlphas()
end

function addon:PLAYER_TARGET_CHANGED()
  BlizzHUDTweaks.hasTarget = UnitExists("target")

  if BlizzHUDTweaks.hasTarget then
    addon:RefreshFrameAlphas()
  else
    addon:RefreshFrameAlphas(true)
  end
end

function addon:PLAYER_ENTERING_WORLD()
  BlizzHUDTweaks.isResting = IsResting("player")
  addon:RefreshFrameAlphas()
end
