local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")

local function byHealthAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeByHealth then
      return globalOptions.ByHealthAlpha
    end
  elseif frameOptions.FadeByHealth then
    return frameOptions.ByHealthAlpha
  end
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

local function instancedAreaAlphaValue(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local alpha

  if not inCombat then
    if frameOptions.UseGlobalOptions then
      if globalOptions.FadeInInstancedArea then
        alpha = globalOptions.InstancedAreaAlpha
      end
    elseif frameOptions.FadeInInstancedArea then
      alpha = frameOptions.InstancedAreaAlpha
    end
  end

  return alpha
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

local function byHealthFadeActive(globalOptions, frameOptions)
  local maxHP = UnitHealthMax("player")
  local currentHP = UnitHealth("player")
  local currentPercent = (currentHP / maxHP) * 100

  if frameOptions.UseGlobalOptions then
    if currentPercent <= (globalOptions.ByHealthThreshold or 0) then
      return globalOptions.FadeByHealth
    end
  else
    if currentPercent <= (frameOptions.ByHealthThreshold or 0) then
      return frameOptions.FadeByHealth
    end
  end
end

local function inCombatFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.FadeInCombat
  else
    return frameOptions.FadeInCombat
  end
end

local function treatTargetTypeMatches(options)
  if options.TreatTargetLikeInCombatTargetType == "friendly" then
    if UnitExists("target") and not UnitCanAttack("player", "target") then
      return true
    end
  elseif options.TreatTargetLikeInCombatTargetType == "hostile" then
    if UnitExists("target") and UnitCanAttack("player", "target") then
      return true
    end
  else
    return true
  end
end

local function treatTargetFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.TreatTargetLikeInCombat and treatTargetTypeMatches(globalOptions)
  else
    return frameOptions.TreatTargetLikeInCombat and treatTargetTypeMatches(frameOptions)
  end
end

local function instancedAreaFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.FadeInInstancedArea
  else
    return frameOptions.FadeInInstancedArea
  end
end

local function restedAreaFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.FadeInRestedArea
  else
    return frameOptions.FadeInRestedArea
  end
end

local function determineTargetAlpha(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local isResting = BlizzHUDTweaks.isResting
  local hasTarget = BlizzHUDTweaks.hasTarget

  local alpha

  if inCombat and inCombatFadeActive(globalOptions, frameOptions) then
    alpha = inCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and hasTarget and inCombatFadeActive(globalOptions, frameOptions) and treatTargetFadeActive(globalOptions, frameOptions) then
    alpha = treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and byHealthFadeActive(globalOptions, frameOptions) then
    alpha = byHealthAlphaValue(globalOptions, frameOptions)
  elseif not inCombat and select(2, GetInstanceInfo()) ~= "none" and instancedAreaFadeActive(globalOptions, frameOptions) then
    alpha = instancedAreaAlphaValue(globalOptions, frameOptions)
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

  return delay or 0
end

local function getNormalizedFrameAlpha(frame)
  return tonumber(string.format("%.2f", frame:GetAlpha()))
end

local function fadeSubFrames(subFrames, currentAlpha, targetAlpha, fadeDuration)
  if subFrames then
    for _, frame in ipairs(subFrames) do
      MouseoverFrameFading:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
    end
  end
end

local function determineMouseOver(profile, frameName, frameOptions)
  local linkedFrames = profile[frameName .. "LinkedFrames"]
  local linkedFrameMouseover

  if linkedFrames then
    for linkedFrameName, _ in pairs(linkedFrames) do
      if profile[linkedFrameName].Enabled then
        if linkedFrames[linkedFrameName] and addon:GetFrameMapping()[linkedFrameName].mainFrame then
          if addon:GetFrameMapping()[linkedFrameName].mainFrame:IsMouseOver() then
            linkedFrameMouseover = true
            return linkedFrameMouseover or frameOptions.mainFrame:IsMouseOver()
          end
        end
      end
    end
  end

  return frameOptions.mainFrame:IsMouseOver()
end

-------------------------------------------------------------------------------
-- Public API

function MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)
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

function MouseoverFrameFading:Fade(frame, currentAlpha, targetAlpha, duration, delay, forced)
  if currentAlpha and targetAlpha and frame:IsShown() then
    if not frame.BlizzHUDTweaksForceFaded then
      if (currentAlpha ~= targetAlpha) or forced then
        if not frame.BlizzHUDTweaksAnimationGroup then
          local animationGroup = frame:CreateAnimationGroup()
          animationGroup:SetToFinalAlpha(true)

          frame.BlizzHUDTweaksAnimationGroup = animationGroup
          frame.BlizzHUDTweaksFadeAnimation = animationGroup:CreateAnimation("Alpha")
        end
        frame.BlizzHUDTweaksFadeAnimation:Stop()
        frame.BlizzHUDTweaksAnimationGroup:Stop()

        frame.BlizzHUDTweaksFadeAnimation:SetFromAlpha(currentAlpha or 1)
        frame.BlizzHUDTweaksFadeAnimation:SetToAlpha(targetAlpha or 1)
        frame.BlizzHUDTweaksFadeAnimation:SetDuration(math.min(duration, 2))
        frame.BlizzHUDTweaksFadeAnimation:SetStartDelay(delay or 0)

        frame.BlizzHUDTweaksAnimationGroup:Restart()
      end
    end
  end
end

local mouseoverFrames = {}

function MouseoverFrameFading:RefreshMouseoverFrameAlphas()
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local inCombat = BlizzHUDTweaks.inCombat
    local globalOptions = profile["*Global*"]

    for frameName, frameMappingOptions in pairs(addon:GetFrameMapping()) do
      local frameOptions = profile[frameName]
      if frameOptions then
        if frameOptions.Enabled and frameMappingOptions.mainFrame then
          local isMouseover = determineMouseOver(profile, frameName, frameMappingOptions)
          local currentAlpha = getNormalizedFrameAlpha(frameMappingOptions.mainFrame)
          local fadeDuration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)

          if isMouseover and not mouseoverFrames[frameMappingOptions.mainFrame] then
            if not inCombat then
              self:Fade(frameMappingOptions.mainFrame, currentAlpha, 1, fadeDuration)
              fadeSubFrames(frameMappingOptions.subFrames, currentAlpha, 1, fadeDuration)
            elseif (frameOptions.UseGlobalOptions and globalOptions.MouseOverInCombat) or (not frameOptions.UseGlobalOptions and frameOptions.MouseOverInCombat) then
              self:Fade(frameMappingOptions.mainFrame, currentAlpha, 1, fadeDuration)
              fadeSubFrames(frameMappingOptions.subFrames, currentAlpha, 1, fadeDuration)
            end
          elseif not isMouseover and mouseoverFrames[frameMappingOptions.mainFrame] then
            local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)
            self:Fade(frameMappingOptions.mainFrame, currentAlpha, targetAlpha, fadeDuration)
            fadeSubFrames(frameMappingOptions.subFrames, currentAlpha, targetAlpha, fadeDuration)
          end
          mouseoverFrames[frameMappingOptions.mainFrame] = isMouseover
        end
      end
    end
  end
end

function MouseoverFrameFading:RefreshFrameAlphas(forced, useFadeDelay)
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local globalOptions = addon:GetProfileDB()["*Global*"]

    for frameName, frameMappingOptions in pairs(addon:GetFrameMapping()) do
      local frameOptions = profile[frameName]

      if frameOptions.Enabled and frameMappingOptions.mainFrame then
        local fadeDuration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)
        local currentAlpha = getNormalizedFrameAlpha(frameMappingOptions.mainFrame)
        local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)

        if (targetAlpha and targetAlpha ~= currentAlpha) or forced then
          local fadeDelay = 0
          if useFadeDelay then
            fadeDelay = determineFadeDelay(globalOptions, frameOptions)
          end
          self:Fade(frameMappingOptions.mainFrame, currentAlpha, targetAlpha, fadeDuration, fadeDelay, forced)
          fadeSubFrames(frameMappingOptions.subFrames, currentAlpha, targetAlpha, fadeDuration)
        end
      end
    end
  end
end

function MouseoverFrameFading:Disable()
  for _, frameMappingOptions in pairs(addon:GetFrameMapping()) do
    addon:ResetFrameByMappingOptions(frameMappingOptions)
  end
  --@debug@
  addon:Print("Disabled Module", addon:ColoredString("MouseoverFrameFading", "fcba03"))
  --@end-debug@
end

function MouseoverFrameFading:Enable()
  MouseoverFrameFading:RefreshFrameAlphas(true, false)
  --@debug@
  addon:Print("Enabled Module", addon:ColoredString("MouseoverFrameFading", "fcba03"))
  --@end-debug@
end

function MouseoverFrameFading:Toggle()
  local profile = addon:GetProfileDB()

  if MouseoverFrameFading:IsEnabled() then
    MouseoverFrameFading:Disable()
    profile["GlobalOptionsMouseoverFrameFadingEnabled"] = false
  else
    profile["GlobalOptionsMouseoverFrameFadingEnabled"] = true
    MouseoverFrameFading:Enable()
  end
  --@debug@
  addon:Print("Toggle Module", addon:ColoredString("MouseoverFrameFading", "fcba03"))
  --@end-debug@
end

function MouseoverFrameFading:IsEnabled()
  local profile = addon:GetProfileDB()
  local enabled = profile["GlobalOptionsMouseoverFrameFadingEnabled"] or false
  return enabled
end
