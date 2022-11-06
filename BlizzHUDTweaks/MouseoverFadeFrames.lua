local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

function addon:Fade(frame, targetAlpha, duration)
  local currentAlpha = frame:GetAlpha()
  targetAlpha = tonumber(string.format("%.2f", targetAlpha))

  local animation = frame:CreateAnimationGroup()
  local fadeIn = animation:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(currentAlpha)
  fadeIn:SetToAlpha(targetAlpha)
  fadeIn:SetDuration(duration)
  fadeIn:SetStartDelay(0)
  animation:SetToFinalAlpha(true)

  animation:Play()
end

local frameMapping = {
  ["PlayerFrame"] = PlayerFrame,
  ["TargetFrame"] = TargetFrame,
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
  ["Minimap"] = Minimap,
  ["ObjectiveTrackerFrame"] = ObjectiveTrackerFrame,
  ["BuffFrame"] = BuffFrame,
  ["DebuffFrame"] = DebuffFrame
}

local function getNextFrameAlpha(frame, inCombat, globalOptions, frameOptions)
  local alpha = 1

  if frame:IsMouseOver() and not inCombat then
    alpha = 1
  elseif frameOptions.UseGlobalOptions then
    if frame:IsMouseOver() and globalOptions.MouseOverInCombat then
      alpha = 1
    elseif globalOptions.FadeOutOfCombat and not inCombat then
      alpha = globalOptions.OutOfCombatAlpha or 1
    elseif globalOptions.FadeInCombat and inCombat then
      alpha = globalOptions.InCombatAlpha or 0.3
    end
  elseif frame:IsMouseOver() and frameOptions.MouseOverInCombat and inCombat then
    alpha = 1
  elseif frameOptions.FadeOutOfCombat and not inCombat then
    alpha = frameOptions.OutOfCombatAlpha or 1
  elseif frameOptions.FadeInCombat and inCombat then
    alpha = frameOptions.InCombatAlpha or 0.3
  end

  -- Overwrite Alpha Settings if player is in resting area for some cases
  if IsResting("player") and not inCombat and not frame:IsMouseOver() then
    if frameOptions.UseGlobalOptions and globalOptions.FadeInRestedArea then
      alpha = globalOptions.RestedAreaAlpha
    elseif frameOptions.FadeInRestedArea then
      alpha = frameOptions.RestedAreaAlpha
    end
  end

  return alpha
end

local function getFadeDuration(globalOptions, frameOptions)
  local fadeDuration = 0.25

  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeDuration then
      fadeDuration = globalOptions.FadeDuration
    end
  else
    if frameOptions.FadeDuration then
      fadeDuration = frameOptions.FadeDuration
    end
  end

  return fadeDuration * 100
end

local function setFadingState(frame, duration)
  if frame then
    frame.fading = duration
    C_Timer.After(
      duration,
      function()
        frame.fading = false
      end
    )
  end
end

function addon:RefreshFrames()
  local globalOptions = self.db.profile["*Global*"]
  local inCombat = UnitAffectingCombat("player")

  for frameName, frame in pairs(frameMapping) do
    local frameOptions = self.db.profile[frameName]
    local alpha = getNextFrameAlpha(frame, inCombat, globalOptions, frameOptions)
    local fadeDuration = getFadeDuration(globalOptions, frameOptions)
    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))

    if alpha and alpha ~= currentAlpha and not frame.fading then
      setFadingState(frame, fadeDuration)
      addon:Fade(frame, alpha, fadeDuration)
    end
  end
end
