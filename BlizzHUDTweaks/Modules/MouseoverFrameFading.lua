-- luacheck: read globals C_CurveUtil Enum UnitHealthPercent UnitPowerPercent UnitIsDeadOrGhost
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

-- Frames whose alpha follows a unit's health or power (frameName -> unit and kind).
-- The power bar is the player's mana, energy, rage, ... bar.
local valueFrames = {
  PlayerFrame = {unit = "player", kind = "health"},
  PetFrame = {unit = "pet", kind = "health"},
  TargetFrame = {unit = "target", kind = "health"},
  TargetFrameToT = {unit = "targettarget", kind = "health"},
  FocusFrame = {unit = "focus", kind = "health"},
  FocusFrameToT = {unit = "focustarget", kind = "health"},
  PlayerPowerBar = {unit = "player", kind = "power"}
}

-- Profile keys and texts of the "not full" option per kind.
local valueOptions = {
  health = {
    title = "Not at full health",
    toggle = "DisableFadeWhenNotFullHP",
    alpha = "NotFullHPAlpha",
    label = "Disable fading when HP below",
    desc = "While the unit is below max health the frame is shown at the alpha below instead of fading.",
    alphaDesc = "Alpha of the frame while the unit is below max health."
  },
  power = {
    title = "Not at full power",
    toggle = "DisableFadeWhenNotFullPower",
    alpha = "NotFullPowerAlpha",
    label = "Disable fading when power below",
    desc = "While the bar is below max power the frame is shown at the alpha below instead of fading.",
    alphaDesc = "Alpha of the frame while the bar is below max power."
  }
}

-- Option texts and profile keys for a frame, nil if the frame has no such option.
function MouseoverFrameFading:GetValueOption(frameName)
  local frame = valueFrames[frameName]
  return frame and valueOptions[frame.kind]
end

-- Health and power are secret in this client, so addon code can neither read nor compare
-- them. The game evaluates a curve on the percent and sets the alpha natively: the "not full"
-- alpha below full, and the alpha of the frame at full. The alpha at full is driven by addon
-- code: it jumps to 1 whenever the value changes, and fades to the normal alpha once the value
-- has been unchanged for HEALTH_HOLD seconds. Fading up (hover, full value) is immediate.
-- ponytail: HEALTH_HOLD assumes regeneration ticks come more often than this.
-- ponytail: a 1e-6 gap below full; pools above ~1M blend near full.
local HEALTH_HURT_GAP = 1e-6
local HEALTH_HOLD = 2
local nativeFrames = {} -- frame -> true while the game owns its alpha
local healthStates = {} -- frameName -> { frame, unit, kind, alpha, target, hurtAlpha, duration, changed, hovered, curve, curveAlpha, curveHurt }
local frameByUnit = {health = {}, power = {}}
for frameName, frameInfo in pairs(valueFrames) do
  frameByUnit[frameInfo.kind][frameInfo.unit] = frameName
end

local function wantsHealthAlpha(frameName, frameOptions)
  local options = MouseoverFrameFading:GetValueOption(frameName)
  return options ~= nil and frameOptions.Enabled and frameOptions[options.toggle] and true or false
end

local function healthAlphaCurve(state)
  local hurt = state.hovered and 1 or state.hurtAlpha
  if state.curveAlpha ~= state.alpha or state.curveHurt ~= hurt then
    local curve = C_CurveUtil.CreateCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0, hurt)
    curve:AddPoint(1 - HEALTH_HURT_GAP, hurt)
    curve:AddPoint(1, state.alpha)
    state.curve, state.curveAlpha, state.curveHurt = curve, state.alpha, hurt
  end
  return state.curve
end

-- Gives the alpha back to the addon as a plain value, which fades can work with again.
local function releaseHealthAlpha(frame, alpha)
  if nativeFrames[frame] then
    nativeFrames[frame] = nil
    frame:SetAlpha(alpha)
  end
end

local function readValue(state, curve)
  if state.kind == "power" then
    return UnitPowerPercent(state.unit, nil, false, curve)
  end
  return UnitHealthPercent(state.unit, true, curve)
end

local function setHealthAlpha(state)
  MouseoverFrameFading:ClearActiveFade(state.frame)
  state.frame:SetAlpha(readValue(state, healthAlphaCurve(state)))
  nativeFrames[state.frame] = true
end

local function stepHealthState(state, elapsed, now)
  -- Fading down waits until the value has settled; fading up (hover, full value) is immediate.
  local diff = state.target - state.alpha
  if diff < 0 and now - state.changed < HEALTH_HOLD then
    return
  end
  local step = state.duration > 0 and elapsed / state.duration or 1
  if math.abs(diff) <= step then
    state.alpha = state.target
  else
    state.alpha = state.alpha + (diff > 0 and step or -step)
  end
end

local healthDriver = CreateFrame("Frame")
healthDriver:Hide()
healthDriver:SetScript(
  "OnUpdate",
  function(_, elapsed)
    local now = GetTime()
    for _, state in pairs(healthStates) do
      stepHealthState(state, elapsed, now)
      setHealthAlpha(state)
    end
  end
)

local healthEvents = CreateFrame("Frame")
healthEvents:RegisterEvent("UNIT_HEALTH")
healthEvents:RegisterEvent("UNIT_POWER_UPDATE")
healthEvents:RegisterEvent("UNIT_MAXPOWER")
healthEvents:SetScript(
  "OnEvent",
  function(_, event, unit)
    local kind = event == "UNIT_HEALTH" and "health" or "power"
    local state = healthStates[frameByUnit[kind][unit]]
    if state then
      state.alpha, state.changed = 1, GetTime()
    end
  end
)

local function clearHealthStates()
  for frameName, state in pairs(healthStates) do
    releaseHealthAlpha(state.frame, state.target)
    healthStates[frameName] = nil
  end
  healthDriver:Hide()
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
    or (frameOptions.isMouseover and frameOptions.isMouseover(frameOptions))

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

function MouseoverFrameFading:RefreshFrameAlphas(forced, useFadeDelay)
  if addon:IsEnabled() and MouseoverFrameFading:IsEnabled() then
    local profile = addon:GetProfileDB()
    local globalOptions = profile["*Global*"]

    local mapping = addon:GetFrameMapping()
    for frameName, frameMappingOptions in pairs(mapping) do
      local frameOptions = profile[frameName]
      if frameOptions and nativeFrames[frameMappingOptions.mainFrame] and not wantsHealthAlpha(frameName, frameOptions) then
        releaseHealthAlpha(frameMappingOptions.mainFrame, determineTargetAlpha(globalOptions, frameOptions))
      end
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

-- Runs on the update ticker. Keeps the set of frames in health or power mode current and
-- records their target alpha, "not full" alpha, fade duration and hover state for the driver.
function MouseoverFrameFading:RefreshHealthFrames()
  if not (addon:IsEnabled() and MouseoverFrameFading:IsEnabled()) then
    clearHealthStates()
    return
  end
  local profile = addon:GetProfileDB()
  local globalOptions = profile["*Global*"]
  local mapping = addon:GetFrameMapping()
  for frameName, frameInfo in pairs(valueFrames) do
    local frameOptions = profile[frameName]
    local frameMappingOptions = mapping[frameName]
    local frame = frameMappingOptions and frameMappingOptions.mainFrame
    local state = healthStates[frameName]
    local dead = UnitIsDeadOrGhost(frameInfo.unit)
    if frame and frameOptions and not dead and wantsHealthAlpha(frameName, frameOptions) and frame:IsShown() then
      local keys = MouseoverFrameFading:GetValueOption(frameName)
      local target = determineTargetAlpha(globalOptions, frameOptions)
      if not state then
        state = {frame = frame, unit = frameInfo.unit, kind = frameInfo.kind, alpha = target, changed = 0}
        healthStates[frameName] = state
      end
      state.hurtAlpha = frameOptions[keys.alpha] or 1
      state.duration = MouseoverFrameFading:DetermineFadeDuration(globalOptions, frameOptions)
      local inCombatHover = not BlizzHUDTweaks.inCombat or (frameOptions.UseGlobalOptions and globalOptions.MouseOverInCombat) or (not frameOptions.UseGlobalOptions and frameOptions.MouseOverInCombat)
      state.hovered = MouseoverFrameFading:MouseoverFadingEnabled(frameOptions) and inCombatHover and determineMouseOver(profile, frameName, frameMappingOptions) and true or false
      state.target = state.hovered and 1 or target
    elseif state then
      releaseHealthAlpha(state.frame, state.target)
      healthStates[frameName] = nil
    end
  end
  healthDriver:SetShown(next(healthStates) ~= nil)
end

function MouseoverFrameFading:InstallHooks()
  SpellFlyout:HookScript("OnShow", SpellFlyoutOnShow)
end

function MouseoverFrameFading:Disable()
  for _, frameMappingOptions in pairs(addon:GetFrameMapping()) do
    addon:ResetFrameByMappingOptions(frameMappingOptions)
  end
  clearHealthStates()
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