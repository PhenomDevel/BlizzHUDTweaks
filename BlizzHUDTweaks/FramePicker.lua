-- luacheck: read globals EnumerateFrames GetCursorPosition InCombatLockdown WorldFrame PlaySound SOUNDKIT
local _, BlizzHUDTweaks = ...

local Widgets = BlizzHUDTweaks.Widgets
local colors, fonts = Widgets.colors, Widgets.fonts
local Markup = Widgets.Markup

--[[
  Frame picker for custom frames: covers the screen, highlights the named
  frame under the cursor and returns its name on a left click.

  Several frames are usually under the cursor (a button, its bar, the bar's
  container). They are sorted from the smallest to the largest; the mouse
  wheel steps through them. Right click or Esc cancels.

  Only frames with a global name can be picked, because the name is what gets
  saved. Picking does not start in combat and is cancelled when combat starts.

  FramePicker:Start(validate, onPick, onCancel)
    validate(frameName) -> ok, reason   shown while hovering
    onPick(frameName)                   after a left click on a valid frame
    onCancel()                          after Esc, right click or combat
]]

local FramePicker = {}
BlizzHUDTweaks.FramePicker = FramePicker

local SCAN_INTERVAL = 0.15
local INVALID_COLOR = {1, 0.35, 0.3, 1}
local INFO_WIDTH = 460

local overlay, box, boxFill, boxBorder, boxLabel, info
local candidates = {}
local selected = 1
local sinceScan = 0
local lastCursorX, lastCursorY
local callbacks = {}

local function isSecret(value)
  return issecretvalue and issecretvalue(value)
end

-- Returns the area of the frame on screen, nil if it can not be picked.
local function pickableArea(frame, screenArea)
  if frame.IsForbidden and frame:IsForbidden() then
    return nil
  end
  if frame == UIParent or frame == WorldFrame or not frame:IsVisible() then
    return nil
  end

  local name = frame:GetName()
  if not name or isSecret(name) or _G[name] ~= frame or name:find("^BlizzHUDTweaks") then
    return nil
  end

  local over = frame:IsMouseOver()
  if isSecret(over) or not over then
    return nil
  end

  local width, height = frame:GetSize()
  local scale = frame:GetEffectiveScale()
  if isSecret(width) or isSecret(height) or isSecret(scale) then
    return nil
  end
  local area = width * height * scale * scale
  -- Containers that span the whole screen are never what the user wants.
  if area <= 0 or area >= screenArea * 0.9 then
    return nil
  end
  return area
end

local function sortByArea(a, b)
  return a.area < b.area
end

local function scan()
  local previous = candidates[selected] and candidates[selected].frame
  local screenScale = UIParent:GetEffectiveScale()
  local screenArea = UIParent:GetWidth() * UIParent:GetHeight() * screenScale * screenScale

  wipe(candidates)
  local frame = EnumerateFrames()
  while frame do
    local ok, area = pcall(pickableArea, frame, screenArea)
    if ok and area then
      candidates[#candidates + 1] = {frame = frame, name = frame:GetName(), area = area}
    end
    frame = EnumerateFrames(frame)
  end
  table.sort(candidates, sortByArea)

  -- Keep the frame chosen with the mouse wheel while it is under the cursor.
  selected = 1
  for index, candidate in ipairs(candidates) do
    if candidate.frame == previous then
      selected = index
      break
    end
  end
end

local function update()
  local candidate = candidates[selected]
  if not candidate then
    box:Hide()
    info.Status:SetText("No named frame under the cursor.")
    return
  end

  local frame = candidate.frame
  local left, bottom, width, height = frame:GetRect()
  if not left or isSecret(left) or isSecret(width) then
    box:Hide()
    return
  end
  local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
  box:ClearAllPoints()
  box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scale, bottom * scale)
  box:SetSize(math.max(width * scale, 2), math.max(height * scale, 2))

  local valid, reason = true, nil
  if callbacks.validate then
    valid, reason = callbacks.validate(candidate.name)
  end
  candidate.valid = valid

  local color = valid and colors.accent or INVALID_COLOR
  boxFill:SetColorTexture(color[1], color[2], color[3], 0.2)
  Widgets.SetBorderColor(boxBorder, color)
  boxLabel:SetText(candidate.name)
  box:Show()

  local status = ("`%s`  (%d of %d)"):format(candidate.name, selected, #candidates)
  if not valid and reason then
    status = status .. "\n|cffff6b5e" .. reason .. "|r"
  end
  info.Status:SetText(Markup(status))
  info:SetHeight(info.Status:GetStringHeight() + info.Help:GetStringHeight() + 30)
end

local function finish(pickedName)
  local onPick, onCancel = callbacks.onPick, callbacks.onCancel
  wipe(callbacks)
  overlay:Hide()
  wipe(candidates)

  if pickedName then
    if onPick then
      Widgets.SafeCall(onPick, pickedName)
    end
  elseif onCancel then
    Widgets.SafeCall(onCancel)
  end
end

local function create()
  overlay = CreateFrame("Frame", nil, UIParent)
  overlay:SetAllPoints(UIParent)
  overlay:SetFrameStrata("FULLSCREEN_DIALOG")
  overlay:EnableMouse(true)
  overlay:EnableMouseWheel(true)
  overlay:EnableKeyboard(true)
  overlay:Hide()

  box = CreateFrame("Frame", nil, overlay)
  boxFill = Widgets.Fill(box, {0, 0, 0, 0})
  boxBorder = Widgets.Border(box, colors.accent)
  boxLabel = Widgets.Text(box, fonts.value, "LEFT")
  boxLabel:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 0, 4)

  info = CreateFrame("Frame", nil, overlay)
  info:SetWidth(INFO_WIDTH)
  info:SetPoint("TOP", 0, -60)
  Widgets.Fill(info, colors.card)
  Widgets.Border(info, colors.tooltipBorder)
  info.Status = Widgets.Text(info, fonts.body, "CENTER")
  info.Status:SetPoint("TOPLEFT", 12, -12)
  info.Status:SetPoint("TOPRIGHT", -12, -12)
  info.Status:SetWordWrap(true)
  info.Help = Widgets.Text(info, fonts.small, "CENTER")
  info.Help:SetPoint("TOPLEFT", info.Status, "BOTTOMLEFT", 0, -6)
  info.Help:SetPoint("TOPRIGHT", info.Status, "BOTTOMRIGHT", 0, -6)
  info.Help:SetText("Left click: add frame   ·   Mouse wheel: smaller / larger frame   ·   Right click or Esc: cancel")

  overlay:SetScript(
    "OnUpdate",
    function(_, elapsed)
      sinceScan = sinceScan + elapsed
      local x, y = GetCursorPosition()
      if sinceScan >= SCAN_INTERVAL and (x ~= lastCursorX or y ~= lastCursorY) then
        sinceScan = 0
        lastCursorX, lastCursorY = x, y
        scan()
        update()
      end
    end
  )
  overlay:SetScript(
    "OnMouseWheel",
    function(_, delta)
      if #candidates > 0 then
        selected = math.max(1, math.min(#candidates, selected + (delta > 0 and 1 or -1)))
        update()
      end
    end
  )
  overlay:SetScript(
    "OnMouseDown",
    function(_, button)
      if button == "LeftButton" then
        local candidate = candidates[selected]
        if candidate and candidate.valid then
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
          finish(candidate.name)
        end
      elseif button == "RightButton" then
        finish()
      end
    end
  )
  -- Keys are not passed on while picking (SetPropagateKeyboardInput is
  -- blocked in combat), Esc cancels.
  overlay:SetScript(
    "OnKeyDown",
    function(_, key)
      if key == "ESCAPE" then
        finish()
      end
    end
  )
  overlay:SetScript(
    "OnEvent",
    function()
      finish()
    end
  )
  overlay:SetScript(
    "OnShow",
    function(self)
      self:RegisterEvent("PLAYER_REGEN_DISABLED")
    end
  )
  overlay:SetScript(
    "OnHide",
    function(self)
      self:UnregisterEvent("PLAYER_REGEN_DISABLED")
      -- Hidden from outside (e.g. UI hidden with Alt+Z): treat as cancel.
      if callbacks.onCancel or callbacks.onPick then
        finish()
      end
    end
  )
end

-------------------------------------------------------------------------------
-- Public API

-- Returns false if picking is not possible right now (combat).
function FramePicker:Start(validate, onPick, onCancel)
  if InCombatLockdown() then
    return false
  end
  if not overlay then
    create()
  end

  callbacks.validate, callbacks.onPick, callbacks.onCancel = validate, onPick, onCancel
  wipe(candidates)
  selected = 1
  sinceScan = SCAN_INTERVAL
  lastCursorX, lastCursorY = nil, nil
  box:Hide()
  info.Status:SetText("Move the mouse over the frame you want to fade.")
  info:SetHeight(info.Status:GetStringHeight() + info.Help:GetStringHeight() + 30)
  overlay:Show()
  return true
end

function FramePicker:IsPicking()
  return overlay ~= nil and overlay:IsShown()
end
