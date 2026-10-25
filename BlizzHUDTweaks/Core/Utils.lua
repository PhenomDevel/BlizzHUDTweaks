local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

--credit https://www.mmo-champion.com/threads/2414999-How-do-I-disable-the-GCD-flash-on-my-bars
function addon:HideGCDFlash()
  -- Optimized: Only check specific actionbar frames instead of iterating all globals
  local actionbars = {
    MainActionBar, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight,
    MultiBarLeft, MultiBar5, MultiBar6, MultiBar7, PetActionBar, StanceBar
  }

  for _, bar in ipairs(actionbars) do
    if bar and type(bar.SetDrawBling) == "function" then
      bar:SetDrawBling(false)
    end
  end
end

function addon:ColoredString(s, color, hasAlpha)
  if color then
    local finalColor = color

    if not hasAlpha then
      finalColor = "FF" .. finalColor
    end

    return "|c" .. finalColor .. tostring(s) .. "|r"
  else
    return "|c" .. "FFFFFFFF" .. tostring(s) .. "|r"
  end
end

function addon:tClone(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    if copies[orig] then
      copy = copies[orig]
    else
      copy = {}
      copies[orig] = copy
      for orig_key, orig_value in next, orig, nil do
        copy[addon:tClone(orig_key, copies)] = addon:tClone(orig_value, copies)
      end
      setmetatable(copy, addon:tClone(getmetatable(orig), copies))
    end
  else
    copy = orig
  end
  return copy
end

function addon:IsMounted()
  return IsMounted() or ( GetShapeshiftForm() == 3 )
end
-- Player housing (neighborhoods) only exists in Retail. WoW: Forever runs on
-- the mainline client too, but with a 1.x interface version.
local hasHousing = select(4, GetBuildInfo()) >= 110000

function addon:HasHousing()
  return hasHousing
end
