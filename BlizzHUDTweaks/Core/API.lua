local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")

local API = {
  LoadProfile = function(name)
    addon:LoadProfileByName(name)
  end
}

_G["BlizzHUDTweaks"] = API
