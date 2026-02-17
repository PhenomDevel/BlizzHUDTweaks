local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Profiles = addon:GetModule("Profiles")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local importString = ""
local importProfileName = ""
local exportString = ""

-------------------------------------------------------------------------------
-- Public API

function Profiles:GetValue(info)
  return Options:GetValue(info)
end

function Profiles:SetValue(info, value)
  Options:SetValue(info, value)
end

-------------------------------------------------------------------------------
-- Profile Import/Export

local function serialize(t)
  local serialized = AceSerializer:Serialize(t)
  local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })

  return LibDeflate:EncodeForPrint(compressed)
end

local function deserialize(s)
  if s and s ~= "" then
    local decoded = LibDeflate:DecodeForPrint(s)
    if decoded then
      local decompressed = LibDeflate:DecompressDeflate(decoded)

      if decompressed then
        local worked, t = AceSerializer:Deserialize(decompressed)

        return worked, t
      else
        addon:Print("String could not be decompressed. Aborting import.")
      end
    else
      addon:Print("String could not be decoded. Aborting import.")
    end
  end

  return nil
end

function Profiles:ExportProfile()
  local profile = addon:GetProfileDB()
  return serialize(profile)
end

function Profiles:ImportProfile(s, profileName)
  if not s or s == "" then
    addon:Print("Import string is empty")
    return false
  end

  local _, profileData = deserialize(s)

  if not profileName or profileName == "" then
    profileName = "Imported - " .. date("%Y-%m-%d %H:%M:%S")
  end

  addon.db:SetProfile(profileName)
  for key, value in pairs(profileData) do
    addon.db.profile[key] = value
  end

  addon:Print("Successfully imported profile as '" .. profileName .. "'")
  addon:LoadProfile()
end

function Profiles:ClearInputs()
  importString = ""
  exportString = ""
  importProfileName = ""
end

local options = {
  name = "",
  handler = addon,
  type = "group",
  childGroups = "tab",
  args = {
    importGroup = {
      type = "group",
      name = "Import",
      order = 100,
      args = {
        profileName = {
          type = "input",
          name = "Profile Name (Optional)",
          desc = "Name for the imported profile. Leave empty for auto-generated name.",
          order = 101,
          width = "full",
          confirm = false,
          get = function()
            return importProfileName or ""
          end,
          set = function(_, value)
            importProfileName = value
          end
        },
        importString = {
          type = "input",
          name = "Import String",
          desc = "Paste the export string here",
          order = 103,
          width = "full",
          multiline = 5,
          get = function()
            return importString or ""
          end,
          set = function(_, value)
            importString = value
          end
        },
        importButton = {
          type = "execute",
          name = "Import Profile",
          desc = "Click to import the profile from the string above",
          order = 104,
          width = "full",
          func = function()
            if importString and importString ~= "" then
              local success = Profiles:ImportProfile(importString, importProfileName)
              if success then
                importString = ""
                exportString = ""
                importProfileName = ""
              end
            else
              addon:Print("Please paste an import string first")
            end
          end
        }
      }
    },
    exportGroup = {
      type = "group",
      name = "Export",
      order = 201,
      args = {
        exportButton = {
          type = "execute",
          name = "Generate Export String",
          desc = "Click to generate an export string for your current profile",
          order = 202,
          width = "full",
          func = function()
            exportString = Profiles:ExportProfile()
          end
        },
        exportString = {
          type = "input",
          name = "Export String",
          desc = "Copy this string to share your profile",
          order = 203,
          multiline = 5,
          width = "full",
          get = function()
            return exportString or "Click 'Generate Export String' button above to create an export string"
          end,
          set = function() end
        }
      }
    }
  }
}

function addon:GetOptionsTable()
  local profile_options = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  profile_options.order = 1
  options.args.profiles = profile_options
  return options
end
