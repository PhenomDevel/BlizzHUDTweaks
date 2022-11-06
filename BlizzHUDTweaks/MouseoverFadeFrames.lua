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

local globalOptions
local frameOptions
local alpha
local fadeDuration
local currentAlpha

function addon:RefreshFrames()
  globalOptions = globalOptions or self.db.profile["*Global*"]

  for frameName, frame in pairs(addon:GetFrameMapping()) do
    frameOptions = self.db.profile[frameName]
    alpha = getNextFrameAlpha(frame, UnitAffectingCombat("player"), globalOptions, frameOptions)
    fadeDuration = getFadeDuration(globalOptions, frameOptions)
    currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))

    if alpha and alpha ~= currentAlpha and not frame.fading then
      setFadingState(frame, fadeDuration)
      addon:Fade(frame, alpha, fadeDuration)
    end
  end
end
