local _, BlizzHUDTweaks = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local MouseoverFrameFading = addon:GetModule("MouseoverFrameFading")
local EventHandler = addon:GetModule("EventHandler")

local function vehicleAlphaValue(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeVehicle then
      return globalOptions.VehicleAlpha
    end
  elseif frameOptions.FadeVehicle then
    return frameOptions.VehicleAlpha
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
  return inCombatAlphaValue(globalOptions, frameOptions)
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
  local alpha

  if frameOptions.UseGlobalOptions then
    if globalOptions.FadeInInstancedArea then
      alpha = globalOptions.InstancedAreaAlpha
    end
  elseif frameOptions.FadeInInstancedArea then
    alpha = frameOptions.InstancedAreaAlpha
  end

  return alpha
end

local function restedAreaAlphaValue(globalOptions, frameOptions)
  local alpha

  if BlizzHUDTweaks.isResting then
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

local function neighborhoodAlphaValue(globalOptions, frameOptions)
  local alpha

  if BlizzHUDTweaks.inNeighborhood then
    if frameOptions.UseGlobalOptions then
      if globalOptions.FadeInNeighborhood then
        alpha = globalOptions.NeighborhoodAlpha
      end
    elseif frameOptions.FadeInNeighborhood then
      alpha = frameOptions.NeighborhoodAlpha
    end
  end

  return alpha
end

local function vehicleFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.FadeVehicle
  else
    return frameOptions.FadeVehicle
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

local function neighborhoodFadeActive(globalOptions, frameOptions)
  if frameOptions.UseGlobalOptions then
    return globalOptions.FadeInNeighborhood
  else
    return frameOptions.FadeInNeighborhood
  end
end

local function determineTargetAlpha(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local isResting = BlizzHUDTweaks.isResting
  local inNeighborhood = BlizzHUDTweaks.inNeighborhood
  local hasTarget = BlizzHUDTweaks.hasTarget
  local hasBonusActionBar = IsMounted() and HasBonusActionBar()

  local alpha

  if hasBonusActionBar and vehicleFadeActive(globalOptions, frameOptions) then
    alpha = vehicleAlphaValue(globalOptions, frameOptions)
  elseif inCombat and inCombatFadeActive(globalOptions, frameOptions) then
    alpha = inCombatAlphaValue(globalOptions, frameOptions)
  elseif hasTarget and inCombatFadeActive(globalOptions, frameOptions) and treatTargetFadeActive(globalOptions, frameOptions) then
    alpha = treatTargetAsCombatAlphaValue(globalOptions, frameOptions)
  elseif inNeighborhood and neighborhoodFadeActive(globalOptions, frameOptions) then
    alpha = neighborhoodAlphaValue(globalOptions, frameOptions)
  elseif select(2, EventHandler:GetInstanceInfo()) ~= "none" and instancedAreaFadeActive(globalOptions, frameOptions) then
    alpha = instancedAreaAlphaValue(globalOptions, frameOptions)
  elseif isResting and restedAreaFadeActive(globalOptions, frameOptions) then
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
  local a = frame:GetAlpha()
  return math.floor(a * 100 + 0.5) / 100
end

local MOUSEOVER_CACHE_TTL = 0.05
local mouseoverCache = {}

local function fadeSubFrames(subFrames, currentAlpha, targetAlpha, fadeDuration)
  if subFrames then
    for _, frame in ipairs(subFrames) do
      MouseoverFrameFading:Fade(frame, currentAlpha, targetAlpha, fadeDuration)
    end
  end
end

local function determineMouseOver(profile, frameName, frameOptions)
  local now = GetTime()
  local entry = mouseoverCache[frameName]
  if entry and now - entry.ts < MOUSEOVER_CACHE_TTL then
    return entry.value
  end

  local mapping = addon:GetFrameMapping()
  local linkedFrames = profile[frameName .. "LinkedFrames"]
  local mainFrame = frameOptions.mainFrame
  local fallback = mainFrame.__BlizzHUDTweaksForceMouseover or mainFrame:IsMouseOver()

  if fallback then
    mouseoverCache[frameName] = { value = true, ts = now }
    return true
  end

  local hasMouseover = false

  if SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:IsMouseOver() then
    local button = SpellFlyout:GetParent()
    if button and button.bar then
      local spellFlyoutButtonBarName = button.bar:GetName()
      local mainFrameName = mainFrame:GetName()

      if spellFlyoutButtonBarName == mainFrameName then
        hasMouseover = true
      else
        if linkedFrames then
          for linkedFrameName, _ in pairs(linkedFrames) do
            local frameProfile = profile[linkedFrameName]
            if frameProfile and frameProfile.Enabled then
              local linkedFrame = mapping[linkedFrameName]
              if linkedFrame and linkedFrame.mainFrame then
                if spellFlyoutButtonBarName == linkedFrame.mainFrame:GetName() then
                  hasMouseover = true
                  break
                end
              end
            end
          end
        end
      end
    end
  end

  if not hasMouseover and linkedFrames then
    for linkedFrameName, _ in pairs(linkedFrames) do
      local frameProfile = profile[linkedFrameName]
      if frameProfile and frameProfile.Enabled then
        local linkedFrame = mapping[linkedFrameName]
        if linkedFrame and linkedFrame.mainFrame and linkedFrame.mainFrame:IsMouseOver() then
          hasMouseover = true
          break
        end
      end
    end
  end

  mouseoverCache[frameName] = { value = hasMouseover, ts = now }
  return hasMouseover
end

local function SpellFlyoutOnLeave()
  local parent = SpellFlyout:GetParent():GetParent()
  parent.__BlizzHUDTweaksForceMouseover = false
end

local function SpellFlyoutOnEnter()
  local parent = SpellFlyout:GetParent():GetParent()
  parent.__BlizzHUDTweaksForceMouseover = true
end

local function SpellFlyoutOnShow()
  local parent = SpellFlyout:GetParent():GetParent()

  if not parent.__BlizzHUDTweaksHooked then
    SpellFlyout:HookScript("OnEnter", SpellFlyoutOnEnter)
    SpellFlyout:HookScript("OnLeave", SpellFlyoutOnLeave)
    parent.__BlizzHUDTweaksHooked = true
  end

  for i = 1, 12 do
    local button = _G["SpellFlyoutButton" .. i]
    if not button then
      break
    end

    if not button.__BlizzHUDTweaksHooked then
      button:HookScript("OnEnter", SpellFlyoutOnEnter)
      button:HookScript("OnLeave", SpellFlyoutOnLeave)
      button.__BlizzHUDTweaksHooked = true
    end
  end
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
    if not frame.__BlizzHUDTweaksForceFaded then
      if (currentAlpha ~= targetAlpha) or forced then
        if not frame.__BlizzHUDTweaksAnimationGroup then
          local animationGroup = frame:CreateAnimationGroup()
          animationGroup:SetToFinalAlpha(true)

          frame.__BlizzHUDTweaksAnimationGroup = animationGroup
          frame.__BlizzHUDTweaksFadeAnimation = animationGroup:CreateAnimation("Alpha")
          frame.__BlizzHUDTweaksFadeAnimation:SetToAlpha(5)

        end

        if (not forced) and targetAlpha == frame.__BlizzHUDTweaksFadeAnimation:GetToAlpha() then
          return
        end

        frame.__BlizzHUDTweaksFadeAnimation:Stop()
        frame.__BlizzHUDTweaksAnimationGroup:Stop()
        frame.__BlizzHUDTweaksFadeAnimation:SetFromAlpha(currentAlpha or 1)
        frame.__BlizzHUDTweaksFadeAnimation:SetToAlpha(targetAlpha or 1)
        frame.__BlizzHUDTweaksFadeAnimation:SetDuration(math.min(duration, 2))
        frame.__BlizzHUDTweaksFadeAnimation:SetStartDelay(delay or 0)
        frame.__BlizzHUDTweaksAnimationGroup:Restart()
      end
    end
  end
end

function MouseoverFrameFading:MouseoverFadingEnabled(frameOptions)
  if frameOptions.UseGlobalOptions then
    local profile = addon:GetProfileDB()
    local globalOptions = profile["*Global*"]
    return globalOptions.MouseOverFadingEnabled
  else
    return frameOptions.MouseOverFadingEnabled
  end
end

local mouseoverFrames = {}

function MouseoverFrameFading:RefreshMouseoverFrameAlphas()
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local inCombat = BlizzHUDTweaks.inCombat
    local globalOptions = profile["*Global*"]

    local mapping = addon:GetFrameMapping()

    -- Prune cache entries for frames no longer present
    for k, _ in pairs(mouseoverCache) do
      if not mapping[k] then
        mouseoverCache[k] = nil
      end
    end

    for frameName, frameMappingOptions in pairs(mapping) do
      local frameOptions = profile[frameName]
      if frameOptions then
        if frameOptions.Enabled and frameMappingOptions.mainFrame and MouseoverFrameFading:MouseoverFadingEnabled(frameOptions) then
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

local function shouldFade(frame, globalOptions, frameOptions)
  if frame then
    if frame.__BlizzHUDTweaksAnimationGroup then
      local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)

      if not frame.__BlizzHUDTweaksAnimationGroup:IsPlaying() or targetAlpha ~= frame.__BlizzHUDTweaksFadeAnimation:GetToAlpha() then
        return true
      end
    else
      return true
    end
  end
end

function MouseoverFrameFading:PauseAnimations()
  local mapping = addon:GetFrameMapping()
  for _, frameMappingOptions in pairs(mapping) do
    local frame = frameMappingOptions.mainFrame
    if frame then
      if frame.__BlizzHUDTweaksAnimationGroup then
        frame.__BlizzHUDTweaksAnimationGroup:Pause()
      end
    end
  end
end

function MouseoverFrameFading:RefreshFrameAlphas(forced, useFadeDelay)
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local globalOptions = profile["*Global*"]

    local mapping = addon:GetFrameMapping()
    for frameName, frameMappingOptions in pairs(mapping) do
      if shouldFade(frameMappingOptions.mainFrame, globalOptions, profile[frameName]) then
        local frameOptions = profile[frameName]

        if frameOptions.Enabled and frameMappingOptions.mainFrame then
          local isMouseover = determineMouseOver(profile, frameName, frameMappingOptions)

          local fadeDuration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)
          local currentAlpha = getNormalizedFrameAlpha(frameMappingOptions.mainFrame)
          local targetAlpha

          if isMouseover then
            targetAlpha = 1
          else
            targetAlpha = determineTargetAlpha(globalOptions, frameOptions)
          end

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
end

function MouseoverFrameFading:InstallHooks()
  SpellFlyout:HookScript("OnShow", SpellFlyoutOnShow)
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