local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

function addon:IsTable(x)
  return type(x) == "table"
end

--credit https://www.mmo-champion.com/threads/2414999-How-do-I-disable-the-GCD-flash-on-my-bars
function addon:HideGCDFlash()
  for _, v in pairs(_G) do
    if type(v) == "table" and type(v.SetDrawBling) == "function" then
      v:SetDrawBling(false)
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

function addon:tKeys(t)
  local keyset = {}
  local n = 0

  for k, _ in pairs(t) do
    n = n + 1
    keyset[n] = k
  end

  return keyset
end
