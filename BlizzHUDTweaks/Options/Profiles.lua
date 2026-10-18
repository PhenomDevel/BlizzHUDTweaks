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

-------------------------------------------------------------------------------
-- Options window

local function toEntries(names)
  local entries = {}
  for value, label in pairs(names) do
    entries[#entries + 1] = {value = value, label = label}
  end
  table.sort(
    entries,
    function(a, b)
      return a.label:lower() < b.label:lower()
    end
  )
  return entries
end

-- Existing profiles; with `withCommon` also the usual new ones (character,
-- realm, class, Default), without `withCurrent` the active one is left out.
local function getProfileEntries(withCommon, withCurrent)
  local db = addon.db
  local names = {}
  if withCommon then
    names["Default"] = "Default"
    names[db.keys.char] = db.keys.char
    names[db.keys.realm] = db.keys.realm
    names[db.keys.class] = UnitClass("player")
  end
  for _, name in ipairs(db:GetProfiles()) do
    names[name] = name
  end
  if not withCurrent then
    names[db:GetCurrentProfile()] = nil
  end
  return toEntries(names)
end

local function getProfileCard()
  local db = addon.db
  return {
    title = "Profiles",
    note = "Active profile: |cffffffff" .. db:GetCurrentProfile() .. "|r",
    tooltip = "Every profile has its own set of settings. Characters can share a profile or use their own.",
    rows = {
      {
        type = "dropdown",
        label = "Active Profile",
        tooltip = "Switches to an existing profile or to a new one for this character, realm or class.",
        layout = true,
        values = function()
          return getProfileEntries(true, true)
        end,
        get = function()
          return db:GetCurrentProfile()
        end,
        set = function(value)
          db:SetProfile(value)
        end
      },
      {
        type = "text",
        label = "New Profile",
        tooltip = "Creates a new profile with default settings and switches to it.",
        placeholder = "Name",
        layout = true,
        get = function()
          return ""
        end,
        set = function(value)
          if value ~= "" then
            db:SetProfile(value)
          end
        end
      },
      {
        type = "dropdown",
        label = "Copy From",
        tooltip = "Copies the settings of another profile into the active profile.",
        placeholder = "Select a profile",
        layout = true,
        values = function()
          return getProfileEntries(false, false)
        end,
        get = function()
          return nil
        end,
        set = function(value)
          db:CopyProfile(value)
        end
      },
      {
        type = "dropdown",
        label = "Delete a Profile",
        tooltip = "Deletes a profile that is not active.",
        placeholder = "Select a profile",
        values = function()
          return getProfileEntries(false, false)
        end,
        get = function()
          return nil
        end,
        set = function(value)
          Options:Confirm(
            ('Delete the profile "%s"?'):format(value),
            "Delete",
            function()
              db:DeleteProfile(value)
              Options:Refresh()
            end
          )
        end
      },
      {
        type = "button",
        label = "Reset Profile",
        tooltip = "Resets the active profile to the default settings.",
        buttonText = "Reset",
        layout = true,
        onClick = function()
          db:ResetProfile()
        end
      }
    }
  }
end

local function getImportCard()
  return {
    title = "Import",
    note = "Adds a profile from an export string and switches to it.",
    rows = {
      {
        type = "text",
        label = "Profile Name (Optional)",
        tooltip = "Name for the imported profile. Leave empty for auto-generated name.",
        get = function()
          return importProfileName or ""
        end,
        set = function(value)
          importProfileName = value
        end
      },
      {
        type = "textarea",
        label = "Import String",
        tooltip = "Paste the export string here",
        placeholder = "Paste the export string here",
        height = 90,
        get = function()
          return importString or ""
        end,
        set = function(value)
          importString = value
        end
      },
      {
        type = "button",
        label = "Import Profile",
        tooltip = "Click to import the profile from the string above",
        buttonText = "Import",
        layout = true,
        onClick = function()
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
  }
end

local function getExportCard()
  return {
    title = "Export",
    note = "Turns the active profile into a string you can share.",
    rows = {
      {
        type = "button",
        label = "Generate Export String",
        tooltip = "Click to generate an export string for your current profile",
        buttonText = "Generate",
        onClick = function()
          exportString = Profiles:ExportProfile()
        end
      },
      {
        type = "textarea",
        label = "Export String",
        tooltip = "Copy this string to share your profile",
        placeholder = "Click 'Generate' above to create an export string",
        height = 90,
        readOnly = true,
        get = function()
          return exportString or ""
        end,
        set = function()
        end
      }
    }
  }
end

Options:RegisterPage(
  {
    id = "profiles",
    label = "Profiles",
    order = 50,
    searchable = true,
    build = function()
      return "Profiles", "Manage, share and import settings", {getProfileCard(), getImportCard(), getExportCard()}
    end
  }
)
