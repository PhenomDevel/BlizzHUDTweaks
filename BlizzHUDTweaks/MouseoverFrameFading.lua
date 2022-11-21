local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")

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

local function inCombatAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeInCombat then
      return globalOptions.InCombatAlpha
    end
  elseif frameOptions.FadeInCombat then
    return frameOptions.InCombatAlpha
  end
end

local function treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  if globalOptions.TreatTargetLikeInCombat then
    return inCombatAlphaValue(globalOptions, frameOptions)
  end
end

local function outOfCombatAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeOutOfCombat then
      return globalOptions.OutOfCombatAlpha
    end
  elseif frameOptions.FadeOutOfCombat then
    return frameOptions.OutOfCombatAlpha
  end
end

local function restedAreaAlphaValue(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local alpha

  if BlizzHUDTweaks.isResting and not inCombat then
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

local function inCombatFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeInCombat then
      return true
    end
  elseif frameOptions.FadeInCombat then
    return true
  end
end

local function treatTargetFadeActive(globalOptions)
  if globalOptions.TreatTargetLikeInCombat then
    return true
  end
end

local function restedAreaFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeInRestedArea then
      return true
    end
  elseif frameOptions.FadeInRestedArea then
    return true
  end
end

local function determineTargetAlpha(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local isResting = BlizzHUDTweaks.isResting
  local hasTarget = BlizzHUDTweaks.hasTarget

  local alpha

  if inCombat and inCombatFadeActive(globalOptions, frameOptions) then
    alpha = inCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and hasTarget and inCombatFadeActive(globalOptions, frameOptions) and treatTargetFadeActive(globalOptions) then
    alpha = treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and isResting and restedAreaFadeActive(globalOptions, frameOptions) then
    alpha = restedAreaAlphaValue(globalOptions, frameOptions)
  else
    alpha = outOfCombatAlphaValue(globalOptions, frameOptions)
  end

  if not alpha then
    -- Always fallback to 1 if nothing else did match
    alpha = 1
  end

  return alpha
end

local function determineFadeDelay(globalOptions, frameOptions)
  local delay

  if frameOptions.UseGlobalOptions then
    delay = globalOptions.OutOfCombatFadeDelay
  else
    delay = frameOptions.OutOfCombatFadeDelay
  end

  return delay
end

local function getNormalizedFrameAlpha(frame)
  return tonumber(string.format("%.2f", frame:GetAlpha()))
end

-------------------------------------------------------------------------------
-- Public API

function MouseoverFrameFading:Fade(frame, currentAlpha, targetAlpha, duration, delay)
  if currentAlpha and targetAlpha and frame:IsShown() then
    if not frame.fadeAnimation then
      local animationGroup = frame:CreateAnimationGroup()
      animationGroup:SetToFinalAlpha(true)

      frame.animationGroup = animationGroup
      frame.fadeAnimation = animationGroup:CreateAnimation("Alpha")
    end

    frame.fadeAnimation:SetFromAlpha(currentAlpha or 1)
    frame.fadeAnimation:SetToAlpha(targetAlpha or 1)
    frame.fadeAnimation:SetDuration(math.min(duration, 2))
    frame.fadeAnimation:SetStartDelay(delay or 0)

    frame.animationGroup:Restart()
  end
end

local mouseoverFrames = {}

function MouseoverFrameFading:RefreshMouseoverFrameAlphas()
  local profile = addon:GetProfileDB()
  local inCombat = BlizzHUDTweaks.inCombat
  local globalOptions = profile["*Global*"]

  for frameName, frame in pairs(addon:GetFrameMapping()) do
    local frameOptions = profile[frameName]
    if frameOptions.Enabled then
      local isMouseover = frame:IsMouseOver()
      local currentAlpha = getNormalizedFrameAlpha(frame)
      local fadeDuration = determineFadeDuration(globalOptions, frameOptions)

      if isMouseover and not mouseoverFrames[frameName] then
        if not inCombat then
          self:Fade(frame, currentAlpha, 1, fadeDuration)
        elseif (frameOptions.UseGlobalOptions and globalOptions.MouseOverInCombat) or (not frameOptions.UseGlobalOptions and frameOptions.MouseOverInCombat) then
          self:Fade(frame, currentAlpha, 1, fadeDuration)
        end
      elseif not isMouseover and mouseoverFrames[frameName] then
        local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)
        self:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
      end

      mouseoverFrames[frameName] = isMouseover
    end
  end
end

function MouseoverFrameFading:RefreshFrameAlphas(useFadeDelay)
  local profile = addon:GetProfileDB()
  local globalOptions = addon:GetProfileDB()["*Global*"]

  for frameName, frame in pairs(addon:GetFrameMapping()) do
    local frameOptions = profile[frameName]
    if frameOptions.Enabled then
      local fadeDuration = determineFadeDuration(globalOptions, frameOptions)
      local currentAlpha = getNormalizedFrameAlpha(frame)
      local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)

      if targetAlpha and targetAlpha ~= currentAlpha then
        local fadeDelay = 0
        if useFadeDelay then
          fadeDelay = determineFadeDelay(globalOptions, frameOptions)
        end
        self:Fade(frame, currentAlpha, targetAlpha, fadeDuration, fadeDelay)
      end
    end
  end
end
