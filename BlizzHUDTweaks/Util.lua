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
