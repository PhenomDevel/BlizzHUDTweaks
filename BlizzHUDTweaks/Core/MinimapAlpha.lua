-- luacheck: read globals C_Texture GetMinimapShape IsLoggedIn
local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

--[[
  Alpha of the minimap (MinimapCluster).

  Indoors (and in some cities on Forever), the game draws the map art black
  when it redraws it while the Minimap frame is less than fully opaque. So
  instead of setting the cluster's alpha, the cluster stays at 1 and:
  - the map itself fades through its mask texture: one mask per alpha step,
    white with the step's alpha (Media/MinimapMasks, made by
    tools/make_minimap_masks.py),
  - every other part (zone text, buttons, border, addon buttons and pins)
    gets its own alpha times the fade.
  The game's map icons (player arrow, blips, quest areas' edges) can't be
  faded this way, so at alpha 0 the whole cluster is set to 0 as before.

  This only works for a round or square minimap whose mask nobody else
  fades. Otherwise (other shapes, Mappy) the cluster's alpha is set and the
  map is redrawn after each fade (MouseoverFrameFading:RedrawIndoorMinimap).
]]

local STEPS = 20
local MASK_PATH = "Interface\\AddOns\\BlizzHUDTweaks\\Media\\MinimapMasks\\%s%d"
local BLIZZARD_MASK_ATLAS = "ui-hud-minimap-frame-generic-mask"
local SQUARE_FALLBACK_MASK = "Interface\\Buttons\\WHITE8X8"

-- Addons that fade the minimap through its mask themselves.
local CONFLICTING_ADDONS = {"Mappy"}

local currentAlpha = 1
-- "mask" while the cluster stays at 1 and the parts are faded, else "plain".
local mode = "plain"
local maskStep -- step of our mask on the minimap, nil while the original one is on
local maskShape
local settingOwnMask = false
local foreignMask -- the last mask another addon or the game set
local partBase = {} -- part -> its own alpha (before the fade)
local partSet = {} -- part -> the alpha we gave it

local function minimapShape()
  if type(GetMinimapShape) == "function" then
    local ok, shape = pcall(GetMinimapShape)
    if ok and type(shape) == "string" then
      return shape
    end
  end
  return "ROUND"
end

local conflictChecked, hasConflict = false, false
local function conflictingAddonLoaded()
  if not conflictChecked and C_AddOns and C_AddOns.IsAddOnLoaded then
    for _, name in ipairs(CONFLICTING_ADDONS) do
      if C_AddOns.IsAddOnLoaded(name) then
        hasConflict = true
      end
    end
    -- Addons load before PLAYER_LOGIN; checking before that may miss one.
    conflictChecked = IsLoggedIn and IsLoggedIn() or false
  end
  return hasConflict
end

local function canUseMask()
  if not (Minimap and MinimapCluster and Minimap.SetMaskTexture) then
    return false
  end
  if conflictingAddonLoaded() then
    return false
  end
  local shape = minimapShape()
  return shape == "ROUND" or shape == "SQUARE"
end

local function setOwnMask(texture)
  settingOwnMask = true
  local ok = pcall(Minimap.SetMaskTexture, Minimap, texture)
  settingOwnMask = false
  return ok
end

local function originalMask(shape)
  if foreignMask then
    return foreignMask
  end
  if shape == "SQUARE" then
    return SQUARE_FALLBACK_MASK
  end
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(BLIZZARD_MASK_ATLAS) then
    return BLIZZARD_MASK_ATLAS
  end
  return string.format(MASK_PATH, "round", STEPS)
end

local function applyMask(step)
  local shape = minimapShape()
  if step == nil then
    if maskStep ~= nil then
      maskStep, maskShape = nil, nil
      setOwnMask(originalMask(shape))
    end
    return
  end
  if step ~= maskStep or shape ~= maskShape then
    maskStep, maskShape = step, shape
    setOwnMask(string.format(MASK_PATH, shape == "SQUARE" and "square" or "round", step))
  end
end

-- Some parts change their alpha themselves (e.g. LibDBIcon buttons shown on
-- mouseover). A value that differs from ours is taken as the part's own.
local function fadePart(part, factor)
  local alpha = part:GetAlpha()
  if issecretvalue and issecretvalue(alpha) then
    return
  end
  if partBase[part] == nil or (partSet[part] and math.abs(alpha - partSet[part]) > 0.005) then
    partBase[part] = alpha
  end
  local target = partBase[part] * factor
  partSet[part] = target
  part:SetAlpha(target)
end

local function fadeChildren(frame, factor, skip)
  for _, child in ipairs({frame:GetChildren()}) do
    if child ~= skip then
      fadePart(child, factor)
    end
  end
  for _, region in ipairs({frame:GetRegions()}) do
    fadePart(region, factor)
  end
end

-- Everything around the map: the cluster's parts except the container the
-- map is in, the container's other parts, and everything inside the map.
local function fadeParts(factor)
  local container = Minimap:GetParent()
  if container and container ~= MinimapCluster and container:GetParent() == MinimapCluster then
    fadeChildren(MinimapCluster, factor, container)
    fadeChildren(container, factor, Minimap)
  else
    fadeChildren(MinimapCluster, factor, Minimap)
  end
  fadeChildren(Minimap, factor)
end

local function restoreParts()
  for part, base in pairs(partBase) do
    local alpha = part:GetAlpha()
    local changed = partSet[part] and not (issecretvalue and issecretvalue(alpha)) and math.abs(alpha - partSet[part]) > 0.005
    if not changed then
      part:SetAlpha(base)
    end
  end
  wipe(partBase)
  wipe(partSet)
end

local function leaveMaskMode()
  restoreParts()
  applyMask(nil)
  mode = "plain"
end

local function toStep(alpha)
  local step = math.floor(alpha * STEPS + 0.5)
  if alpha > 0 and step == 0 then
    step = 1
  end
  return step
end

-- Zooming one step and straight back makes the game redraw the map art
-- (net zoom unchanged).
local function redrawMap()
  if not Minimap then
    return
  end
  local zoom = Minimap:GetZoom()
  local levels = Minimap:GetZoomLevels()
  if not zoom or not levels or levels < 2 then
    return
  end
  Minimap:SetZoom(zoom < levels - 1 and zoom + 1 or zoom - 1)
  Minimap:SetZoom(zoom)
end

local function setMinimapAlpha(alpha)
  local previous = currentAlpha
  currentAlpha = alpha

  if alpha <= 0 or alpha >= 1 or not canUseMask() then
    if mode == "mask" then
      leaveMaskMode()
    end
    MinimapCluster:SetAlpha(alpha)
    if previous <= 0 and alpha >= 1 then
      -- While hidden at 0 the map may have been redrawn black.
      redrawMap()
    end
    return
  end

  local step = toStep(alpha)
  if mode ~= "mask" then
    mode = "mask"
    MinimapCluster:SetAlpha(1)
    applyMask(step)
    fadeParts(step / STEPS)
    if previous <= 0 then
      -- While hidden at 0 the map may have been redrawn black.
      redrawMap()
    end
  elseif step ~= maskStep or minimapShape() ~= maskShape then
    applyMask(step)
    fadeParts(step / STEPS)
  end
end

-- Another addon or the game set its own mask (e.g. a new shape, or Forever's
-- rotating minimap). Remember it, and put ours back while faded.
if Minimap and Minimap.SetMaskTexture then
  hooksecurefunc(
    Minimap,
    "SetMaskTexture",
    function(_, texture)
      if settingOwnMask then
        return
      end
      foreignMask = texture
      if maskStep ~= nil then
        local step = maskStep
        maskStep = nil
        applyMask(step)
      end
    end
  )
end

-- Alpha of a faded frame. Frames with their own handling (the minimap) keep
-- their alpha here; all others use the frame's alpha.
function addon:SetFrameAlpha(frame, alpha)
  if frame == MinimapCluster and MinimapCluster then
    setMinimapAlpha(alpha)
  else
    frame:SetAlpha(alpha)
  end
end

function addon:GetFrameAlpha(frame)
  if frame == MinimapCluster and MinimapCluster then
    if mode == "mask" then
      return currentAlpha
    end
    return MinimapCluster:GetAlpha()
  end
  return frame:GetAlpha()
end

-- True if the minimap fades through its mask. Otherwise (fallback) the map
-- has to be redrawn after a fade, see RedrawMinimap.
function addon:MinimapUsesMask()
  return canUseMask()
end

function addon:RedrawMinimap()
  redrawMap()
end
