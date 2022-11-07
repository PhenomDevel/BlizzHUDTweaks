local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local function determineFadeDuration(globalOptions, frameOptions)
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

local lastIsResting, lastInCombat, lastTargetExists
local function shouldUpdateFrames()
  local isResting, inCombat, targetExists = IsResting("player"), UnitAffectingCombat("player"), UnitExists("target")

  if lastIsResting ~= isResting or lastInCombat ~= inCombat or lastTargetExists ~= targetExists then
    lastIsResting = isResting
    lastInCombat = inCombat
    lastTargetExists = targetExists
    return true
  end
end

local function inCombatAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions and globalOptions.FadeInCombat then
    return globalOptions.InCombatAlpha or 0.25
  elseif frameOptions.FadeInCombat then
    return frameOptions.InCombatAlpha or 0.25
  end
end

local function treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  if globalOptions.TreatTargetLikeInCombat then
    return inCombatAlphaValue(globalOptions, frameOptions)
  end
end

local function outOfCombatAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions and globalOptions.FadeOutOfCombat then
    return globalOptions.OutOfCombatAlpha or 0.25
  elseif frameOptions.FadeOutOfCombat then
    return frameOptions.OutOfCombatAlpha or 0.25
  end
end

local function restedAreaAlphaValue(globalOptions, frameOptions)
  local inCombat = UnitAffectingCombat("player")
  local alpha = 1

  if IsResting("player") and not inCombat then
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

local function determineTargetAlpha(globalOptions, frameOptions)
  local inCombat = UnitAffectingCombat("player")
  local alpha = 1

  if inCombat then
    alpha = inCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and UnitExists("Target") then
    alpha = treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and not IsResting("player") then
    alpha = outOfCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and IsResting("player") then
    alpha = restedAreaAlphaValue(globalOptions, frameOptions)
  end

  return alpha
end

local function getNormalizedFrameAlpha(frame)
  return tonumber(string.format("%.2f", frame:GetAlpha()))
end

local mouseoverFrames = {}

function addon:RefreshMouseoverFrameAlphas()
  local inCombat = UnitAffectingCombat("player")
  local globalOptions = self.db.profile["*Global*"]

  for frameName, frame in pairs(addon:GetFrameMapping()) do
    local isMouseover = frame:IsMouseOver()

    local frameOptions = self.db.profile[frameName]
    local currentAlpha = getNormalizedFrameAlpha(frame)
    local fadeDuration = determineFadeDuration(globalOptions, frameOptions)

    if isMouseover and not mouseoverFrames[frameName] then
      if not inCombat then
        addon:Fade(frame, currentAlpha, 1, fadeDuration)
      elseif (frameOptions.UseGlobalOptions and globalOptions.MouseOverInCombat) or (not frameOptions.UseGlobalOptions and frameOptions.MouseOverInCombat) then
        addon:Fade(frame, currentAlpha, 1, fadeDuration)
      end
    elseif not isMouseover and mouseoverFrames[frameName] then
      local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)
      addon:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
    end

    mouseoverFrames[frameName] = isMouseover
  end
end

-------------------------------------------------------------------------------
-- Public API

function addon:Fade(frame, currentAlpha, targetAlpha, duration)
  if currentAlpha and targetAlpha then
    if not frame.fadeAnimation then
      local animationGroup = frame:CreateAnimationGroup()
      animationGroup:SetToFinalAlpha(true)

      frame.animationGroup = animationGroup
      frame.fadeAnimation = animationGroup:CreateAnimation("Alpha")
    end

    frame.fadeAnimation:SetFromAlpha(currentAlpha)
    frame.fadeAnimation:SetToAlpha(targetAlpha)
    frame.fadeAnimation:SetDuration(math.min(duration, 2))
    frame.fadeAnimation:SetStartDelay(0)

    frame.animationGroup:Restart()
  end
end

function addon:RefreshFrameAlphas(isForced)
  if shouldUpdateFrames() or isForced then
    local globalOptions = self.db.profile["*Global*"]

    for frameName, frame in pairs(addon:GetFrameMapping()) do
      local frameOptions = self.db.profile[frameName]
      local fadeDuration = determineFadeDuration(globalOptions, frameOptions)
      local currentAlpha = getNormalizedFrameAlpha(frame)
      local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)

      if targetAlpha and targetAlpha ~= currentAlpha then
        addon:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
      end
    end
  end
end
