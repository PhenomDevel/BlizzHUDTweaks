local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Debug = addon:GetModule("Debug")

local debugInfo = {
  ticker = nil,
  fnCalls = nil
}

-------------------------------------------------------------------------------
-- Public API

function Debug:Init()
  --@debug@
  debugInfo["ticker"] =
    C_Timer.NewTicker(
    5,
    function()
      if Debug:IsEnabled() then
        for fnName, count in pairs(debugInfo.fnCalls or {}) do
          addon:Print(fnName, ":", count)
        end
      end
    end
  )
  --@end-debug@
end

function Debug:IncrementFnCall(name)
  if not debugInfo.fnCalls then
    debugInfo.fnCalls = {}
  end

  if not debugInfo.fnCalls[name] then
    debugInfo.fnCalls[name] = 0
  end

  debugInfo.fnCalls[name] = debugInfo.fnCalls[name] + 1
end

function Debug:Disable()
  local profile = addon:GetProfileDB()
  profile.debug = false

  if debugInfo.ticker then
    debugInfo.ticker:Cancel()
  end

  --@debug@
  addon:Print("Disabled Module", addon:ColoredString("Debug", "fcba03"))
  --@end-debug@
end

function Debug:Enable()
  local profile = addon:GetProfileDB()
  profile.debug = true
  Debug:Init()

  --@debug@
  addon:Print("Enabled Module", addon:ColoredString("Debug", "fcba03"))
  --@end-debug@
end

function Debug:IsEnabled()
  local enabled = addon:GetProfileDB()["debug"] or false
  return enabled
end
