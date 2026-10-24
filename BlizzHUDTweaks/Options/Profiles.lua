local addon = LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks")
local Options = addon:GetModule("Options")
local Profiles = addon:GetModule("Profiles")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local importString = ""
local importProfileName = ""
local exportString = ""
-- Result of the last import attempt, shown below the import string.
local importError

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

-- Returns the profile table, or nil and the reason the string is not usable.
local function deserialize(s)
  s = s and strtrim(s) or ""
  if s == "" then
    return nil, "Paste an export string first."
  end
  local decoded = LibDeflate:DecodeForPrint(s)
  if not decoded then
    return nil, "This is not an export string of BlizzHUDTweaks."
  end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then
    return nil, "The string is incomplete. Copy the whole export string again."
  end
  local worked, t = AceSerializer:Deserialize(decompressed)
  if not worked or type(t) ~= "table" then
    return nil, "The string could not be read. Copy the whole export string again."
  end
  return t
end

-- Checks an import string without importing it. Returns the profile table
-- and the number of frames with settings, or nil and the reason.
function Profiles:CheckImportString(s)
  local profileData, reason = deserialize(s)
  if not profileData then
    return nil, reason
  end
  local frames = 0
  for _, value in pairs(profileData) do
    if type(value) == "table" and value.displayName then
      frames = frames + 1
    end
  end
  return profileData, frames
end

function Profiles:ExportProfile()
  local profile = addon:GetProfileDB()
  return serialize(profile)
end

-- Returns true and the profile name, or false and the reason.
function Profiles:ImportProfile(s, profileName)
  local profileData, reason = deserialize(s)
  if not profileData then
    return false, reason
  end

  profileName = profileName and strtrim(profileName) or ""
  if profileName == "" then
    profileName = "Imported - " .. date("%Y-%m-%d %H:%M:%S")
  end

  addon.db:SetProfile(profileName)
  for key, value in pairs(profileData) do
    addon.db.profile[key] = value
  end

  addon:Print("Successfully imported profile as '" .. profileName .. "'")
  addon:LoadProfile()
  return true, profileName
end

function Profiles:ClearInputs()
  importString = ""
  exportString = ""
  importProfileName = ""
  importError = nil
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
  local current = db:GetCurrentProfile()
  return {
    title = "Profiles",
    note = "All settings in this window belong to the active profile.",
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
      {type = "header", label = ('Overwrites "%s"'):format(current), danger = true},
      {
        type = "dropdown",
        label = "Copy From",
        tooltip = "Copies the settings of another profile into the active profile. The current settings of the active profile are lost.",
        placeholder = "Select a profile",
        values = function()
          return getProfileEntries(false, false)
        end,
        get = function()
          return nil
        end,
        set = function(value)
          Options:Confirm(
            ('Copy all settings of "%s" into "%s"?\nThe current settings of "%s" are lost.'):format(value, current, current),
            "Copy",
            function()
              db:CopyProfile(value)
              Options:Refresh()
            end
          )
        end
      },
      {
        type = "button",
        label = "Reset to defaults",
        tooltip = "Resets the active profile to the default settings.",
        buttonText = "Reset",
        danger = true,
        onClick = function()
          Options:Confirm(
            ('Reset "%s" to the default settings?\nCustom frames, links and all other settings of this profile are lost.'):format(current),
            "Reset",
            function()
              db:ResetProfile()
              Options:Refresh()
            end
          )
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
      }
    }
  }
end

-- What the pasted string contains, or why it can not be imported.
local function getImportStatusRow()
  if importError then
    return {type = "notice", tone = "danger", label = importError}
  end
  if not importString or strtrim(importString) == "" then
    return nil
  end
  local profileData, result = Profiles:CheckImportString(importString)
  if not profileData then
    return {type = "notice", tone = "danger", label = result}
  end
  return {type = "notice", tone = "ok", label = ("Valid export string with settings for %d frames."):format(result)}
end

local function getImportCard()
  local rows = {
    {
      type = "textarea",
      label = "Import String",
      tooltip = "Paste an export string here. It is checked right away.",
      placeholder = "Paste the export string here",
      height = 90,
      layout = true,
      get = function()
        return importString or ""
      end,
      set = function(value)
        importString = value
        importError = nil
      end
    }
  }
  rows[#rows + 1] = getImportStatusRow()
  rows[#rows + 1] = {
    type = "text",
    label = "Profile Name",
    note = "Optional. Leave empty for a name with the current date.",
    tooltip = "Name for the imported profile. An existing profile with this name is overwritten.",
    placeholder = "Imported - date",
    get = function()
      return importProfileName or ""
    end,
    set = function(value)
      importProfileName = value
    end
  }
  rows[#rows + 1] = {
    type = "button",
    label = "Import Profile",
    tooltip = "Creates the profile from the string above and switches to it.",
    buttonText = "Import",
    layout = true,
    onClick = function()
      local success, result = Profiles:ImportProfile(importString, importProfileName)
      if success then
        importString, importProfileName, importError = "", "", nil
        exportString = ""
      else
        importError = result
      end
    end
  }
  return {
    title = "Import",
    note = "Adds a profile from an export string and switches to it.",
    rows = rows
  }
end

local function getExportCard()
  return {
    title = "Export",
    note = "The active profile as a string you can share.",
    rows = {
      {
        type = "textarea",
        label = "Export String",
        note = "Click the text to select it, then press Ctrl+C to copy.",
        tooltip = "Copy this string to share your profile. It always shows the current settings.",
        height = 90,
        readOnly = true,
        get = function()
          -- Built on demand: the page clears it on every build, so it never
          -- shows settings from before a change.
          if exportString == "" then
            exportString = Profiles:ExportProfile()
          end
          return exportString
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
      exportString = ""
      return "Profiles", "Manage, share and import settings", {getProfileCard(), getImportCard(), getExportCard()}
    end
  }
)
