local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

function addon:Fade(frame, currentAlpha, targetAlpha, duration)
  if not frame.fadeAnimation then
    local animationGroup = frame:CreateAnimationGroup()
    animationGroup:SetToFinalAlpha(true)

    frame.animationGroup = animationGroup
    frame.fadeAnimation = animationGroup:CreateAnimation("Alpha")
  end

  if not frame.fadeAnimation:IsPlaying() then
    frame.fadeAnimation:SetFromAlpha(currentAlpha)
    frame.fadeAnimation:SetToAlpha(targetAlpha)
    frame.fadeAnimation:SetDuration(math.min(duration, 2))
    frame.fadeAnimation:SetStartDelay(0)

    frame.animationGroup:Restart()
  end
end

local function getNextFrameAlpha(frame, inCombat, globalOptions, frameOptions)
  local alpha = 1

  if frame:IsMouseOver() and not inCombat then
    alpha = 1
  elseif not inCombat and UnitExists("target") and globalOptions.TreatTargetLikeInCombat then
    if frameOptions.UseGlobalOptions and globalOptions.FadeInCombat then
      alpha = globalOptions.InCombatAlpha or 0.3
    elseif frameOptions.FadeInCombat then
      alpha = frameOptions.InCombatAlpha or 0.3
    end
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
    if frameOptions.UseGlobalOptions then
      if globalOptions.FadeInRestedArea then
        alpha = globalOptions.RestedAreaAlpha
      end
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

  return fadeDuration
end

local globalOptions
local frameOptions
local alpha
local fadeDuration
local currentAlpha
local targetAlpha

function addon:RefreshFrames()
  globalOptions = self.db.profile["*Global*"]

  for frameName, frame in pairs(addon:GetFrameMapping()) do
    frameOptions = self.db.profile[frameName]
    alpha = getNextFrameAlpha(frame, UnitAffectingCombat("player"), globalOptions, frameOptions)
    fadeDuration = getFadeDuration(globalOptions, frameOptions)
    currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    targetAlpha = tonumber(string.format("%.2f", alpha))

    if targetAlpha and targetAlpha ~= currentAlpha and not frame.fading then
      addon:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
    end
  end
end
