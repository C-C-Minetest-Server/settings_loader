-- settings_loader/init.lua
-- Load or reload settings easily
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = minetest.get_translator("settings_loader")
local logger = logging.logger("settings_loader")
local settings = minetest.settings

---Load or reload settings easily
---@class settings_loader: table
local _p = {}

---Valid types that can be used as `type` arguments, including alias.
---@type { [string]: fun(value: string, default: any): any }
---@enum (key) SettingsLoaderTypes
_p.setting_types = {
    string = function(value, default) return value ~= "" and value or default end,
    float = function(value, default) return tonumber(value) or default or 0 end,
    integer = function(value, default) return math.floor(tonumber(value) or default or 0) end,
    v3f = function(value, default) return minetest.string_to_pos(value) or default end,
    boolean = function() end, -- Handled in get_setting_value
    np_group = function() end, -- Handled in get_setting_value
    flags = function() end, -- Handled in get_setting_value
}

---Get the value of a given key in a given type
---@param key string The setting key
---@param stype SettingsLoaderTypes The type of the setting
---@param default any The default value
function _p.get_setting_value(key, stype, default)
    if stype == "booolean" then
        return settings:get_bool(key, default)
    elseif stype == "np_group" then
        return settings:get_np_group(key)
    elseif stype == "flags" then
        return settings:get_flags(key)
    end

    local func = logger:assert(_p.setting_types[stype],
        ("Invalid setting type %s while loading %s"):format(stype, key))
    return func(settings:get(key), default)
end

---Entry in settings_loader.reload_list
---@class SettingsLoaderReloadEntry
---@see settings_loader.reload_list
---@field prefix string The prefix of the setting keys
---@field list_settings { [string]: SettingsLoaderEntry } List of settings to be loaded
---@param tb table The table to store the values.

---Entries to be reloaded on `/reload_settings`
---@type SettingsLoaderReloadEntry[]
_p.reload_list = {}

---Definition of an entry in settings table
---@class SettingsLoaderEntry
---@field stype SettingsLoaderTypes The type of the setting
---@param default? any The default value

---Get all settings listed in a table with optional prefix
---@param prefix string The prefix of the setting keys
---@param list_settings { [string]: SettingsLoaderEntry } List of settings to be loaded
---@param reload boolean Whether to reload settings when `/reload_settings` is executed. default: `true`
---@param tb? table The table to store the values. default: new table
---@return string[]
function _p.load_settings(prefix, list_settings, reload, tb)
    tb = tb or {}

    for key, def in pairs(list_settings) do
        tb[key] =  _p.get_setting_value(prefix .. key, def.stype, def.default)
    end

    reload = reload == nil and true or reload
    if reload then
        _p.reload_list[#_p.reload_list+1] = {
            prefix = prefix,
            list_settings = list_settings,
            tb = tb,
        }
    end

    return tb
end

---Reload all entries in settings_loader.reload_list
---@see settings_loader.load_settings
---@see settings_loader.reload_list
function _p.reload_all()
    for _, entries in ipairs(_p.reload_list) do
        _p.load_settings(entries.prefix, entries.list_settings, false, entries.tb)
    end
end

minetest.register_chatcommand("reload_settings", {
    description = S("Reload supported settings"),
    privs = { server = true },
    func = function()
        _p.reload_all()
        return true, S("All settings reloaded.")
    end,
})

settings_loader = _p
