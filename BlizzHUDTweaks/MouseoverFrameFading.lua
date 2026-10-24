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

-- Returns the alpha and the key of the condition that set it (nil when no
-- condition applies and the frame is shown at full alpha).
local function determineTargetAlpha(globalOptions, frameOptions)
  local inCombat = BlizzHUDTweaks.inCombat
  local isResting = BlizzHUDTweaks.isResting
  local inNeighborhood = BlizzHUDTweaks.inNeighborhood
  local hasTarget = BlizzHUDTweaks.hasTarget
  local hasBonusActionBar = addon:IsMounted() and HasBonusActionBar()

  local alpha, condition

  if hasBonusActionBar and vehicleFadeActive(globalOptions, frameOptions) then
    alpha, condition = vehicleAlphaValue(globalOptions, frameOptions), "FadeVehicle"
  elseif inCombat and inCombatFadeActive(globalOptions, frameOptions) then
    alpha, condition = inCombatAlphaValue(globalOptions, frameOptions), "FadeInCombat"
  elseif hasTarget and inCombatFadeActive(globalOptions, frameOptions) and treatTargetFadeActive(globalOptions, frameOptions) then
    alpha, condition = treatTargetAsCombatAlphaValue(globalOptions, frameOptions), "TreatTargetLikeInCombat"
  elseif inNeighborhood and neighborhoodFadeActive(globalOptions, frameOptions) then
    alpha, condition = neighborhoodAlphaValue(globalOptions, frameOptions), "FadeInNeighborhood"
  elseif select(2, EventHandler:GetInstanceInfo()) ~= "none" and instancedAreaFadeActive(globalOptions, frameOptions) then
    alpha, condition = instancedAreaAlphaValue(globalOptions, frameOptions), "FadeInInstancedArea"
  elseif isResting and restedAreaFadeActive(globalOptions, frameOptions) then
    alpha, condition = restedAreaAlphaValue(globalOptions, frameOptions), "FadeInRestedArea"
  else
    alpha = outOfCombatAlphaValue(globalOptions, frameOptions)
    if alpha then
      condition = "FadeOutOfCombat"
    end
  end

  if not alpha then
    -- Always fallback to 1 if nothing else did match
    alpha, condition = 1, nil
  end

  return alpha, condition
end

-- For the options: the condition that currently sets the alpha of a frame
-- (or of the global settings) and that alpha, ignoring mouseover.
function MouseoverFrameFading:GetActiveCondition(frameName)
  local profile = addon:GetProfileDB()
  local globalOptions = profile["*Global*"]
  local frameOptions = profile[frameName]
  if not globalOptions or not frameOptions then
    return nil, 1
  end
  local alpha, condition = determineTargetAlpha(globalOptions, frameOptions)
  return condition, alpha
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

-- Returns nil if the alpha is a secret value (Midnight restrictions), in
-- which case the frame is left alone.
local function getNormalizedFrameAlpha(frame)
  local a = frame:GetAlpha()
  if issecretvalue and issecretvalue(a) then
    return nil
  end
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

-- Profile keys of the frame links, built once per frame name instead of on
-- every update tick.
local linkedFramesKeys = setmetatable({}, {
  __index = function(t, frameName)
    local key = frameName .. "LinkedFrames"
    t[frameName] = key
    return key
  end
})

-- Cache entries are reused, so the update ticker does not create garbage.
local function setMouseoverCache(frameName, value, now)
  local entry = mouseoverCache[frameName]
  if entry then
    entry.value, entry.ts = value, now
  else
    mouseoverCache[frameName] = { value = value, ts = now }
  end
  return value
end

local function determineMouseOver(profile, frameName, frameOptions)
  local now = GetTime()
  local entry = mouseoverCache[frameName]
  if entry and now - entry.ts < MOUSEOVER_CACHE_TTL then
    return entry.value
  end

  local mapping = addon:GetFrameMapping()
  local linkedFrames = profile[linkedFramesKeys[frameName]]
  local mainFrame = frameOptions.mainFrame
  local fallback = mainFrame.__BlizzHUDTweaksForceMouseover or mainFrame:IsMouseOver()

  if fallback then
    return setMouseoverCache(frameName, true, now)
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

  return setMouseoverCache(frameName, hasMouseover, now)
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


local activeFades = {}

-- Blizzard's UIFrameFade unconditionally calls frame:Show(), which is now a
-- protected call on frames like MainActionBar. We only ever fade frames that
-- are already shown, so a self-contained fade avoids the taint entirely.
--
-- All fades run on one OnUpdate driver that is only shown while something
-- fades. It uses the real elapsed time (a fade takes as long as set at any
-- frame rate), and a pending fade delay is cancelled together with the fade.
-- Entries are reused per frame: fades[frame] = { from, to, startTime, duration, onFinished, running }
local fades = {}
local runningFades = 0
local fadeDriver = CreateFrame("Frame")
fadeDriver:Hide()

local finishedFades = {}

local function stopFade(frame)
  local fade = fades[frame]
  if fade and fade.running then
    fade.running = false
    fade.onFinished = nil
    runningFades = runningFades - 1
    if runningFades == 0 then
      fadeDriver:Hide()
    end
  end
end

fadeDriver:SetScript("OnUpdate", function()
  local now = GetTime()
  for frame, fade in pairs(fades) do
    if fade.running and now >= fade.startTime then
      if not fade.started then
        fade.started = true
        frame:SetAlpha(fade.from)
      end
      local progress = math.min((now - fade.startTime) / fade.duration, 1)
      frame:SetAlpha(fade.from + (fade.to - fade.from) * progress)
      if progress >= 1 then
        finishedFades[#finishedFades + 1] = frame
      end
    end
  end

  -- Finish after the loop, the callbacks may start new fades.
  for i = #finishedFades, 1, -1 do
    local frame = finishedFades[i]
    finishedFades[i] = nil
    local onFinished = fades[frame].onFinished
    stopFade(frame)
    if onFinished then
      onFinished()
    end
  end
end)

function MouseoverFrameFading:ClearActiveFade(frame)
  activeFades[frame] = nil
  stopFade(frame)
end

function MouseoverFrameFading:TrackActiveFade(frame)
  activeFades[frame] = true
end

local function StartFade(frame, startAlpha, endAlpha, duration, finishedFunc, delay)
  stopFade(frame)

  if (not delay or delay <= 0) and (not duration or duration <= 0 or startAlpha == endAlpha) then
    frame:SetAlpha(endAlpha)
    if finishedFunc then
      finishedFunc()
    end
    return
  end

  local fade = fades[frame]
  if not fade then
    fade = {}
    fades[frame] = fade
  end
  fade.from, fade.to = startAlpha, endAlpha
  fade.startTime = GetTime() + (delay or 0)
  fade.duration = (duration and duration > 0) and duration or 0.001
  fade.onFinished = finishedFunc
  fade.started = false
  fade.running = true
  runningFades = runningFades + 1
  fadeDriver:Show()
end

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
        -- Cancel any existing fade for this frame
        if activeFades[frame] then
          MouseoverFrameFading:ClearActiveFade(frame)
        end

        -- If target alpha is different, start new fade
        if currentAlpha ~= targetAlpha or forced then
          MouseoverFrameFading:TrackActiveFade(frame)
          StartFade(frame, currentAlpha, targetAlpha, duration, function()
            MouseoverFrameFading:ClearActiveFade(frame)
          end, delay)
        end
      end
    end
  end
end

function MouseoverFrameFading:MouseoverFadingEnabled(frameOptions)
  if frameOptions.UseGlobalOptions then
    local profile = addon:GetProfileDB()
    local globalOptions = profile["*Global*"]
    return globalOptions.MouseOverFadeEnabled
  else
    return frameOptions.MouseOverFadeEnabled
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
    local targetAlpha = determineTargetAlpha(globalOptions, frameOptions)
    local currentAlpha = getNormalizedFrameAlpha(frame)
    if currentAlpha ~= targetAlpha or activeFades[frame] then
      return true
    end
  end
end

function MouseoverFrameFading:PauseAnimations()
  local mapping = addon:GetFrameMapping()
  for _, frameMappingOptions in pairs(mapping) do
    local frame = frameMappingOptions.mainFrame
    if frame and activeFades[frame] then
      MouseoverFrameFading:ClearActiveFade(frame)
    end
  end
end

function MouseoverFrameFading:RefreshFrameAlphas(forced, useFadeDelay)
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local globalOptions = profile["*Global*"]

    local mapping = addon:GetFrameMapping()
    for frameName, frameMappingOptions in pairs(mapping) do
      local frameOptions = profile[frameName]
      -- Disabled frames are skipped before their target alpha is computed.
      if frameOptions and frameOptions.Enabled and shouldFade(frameMappingOptions.mainFrame, globalOptions, frameOptions) then
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
  -- The toggle (keybind, minimap icon) has no other visible feedback.
  local state = MouseoverFrameFading:IsEnabled() and "|cff8fe3a8on|r" or "|cff8f8f94off|r"
  BlizzHUDTweaks.Toast:Show("Frame Fading " .. state, profile["GlobalOptionsMouseoverFrameFadingToggleKeybind"])
  --@debug@
  addon:Print("Toggle Module", addon:ColoredString("MouseoverFrameFading", "fcba03"))
  --@end-debug@
end

function MouseoverFrameFading:IsEnabled()
  local profile = addon:GetProfileDB()
  local enabled = profile["GlobalOptionsMouseoverFrameFadingEnabled"] or false
  return enabled
end