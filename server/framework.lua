--[[
    Framework adapter.

    Normalizes qb-core / qbx_core / es_extended / standalone into one shape
    so the rest of the resource never has to care which one you run:

        Framework.GetPlayer(src) -> { cid, name, job = { name, grade, onDuty } }
        Framework.Notify(src, msg, kind)

    The core object goes STALE when the framework restarts: qb-core's
    GetCoreObject() hands back function references into its own script
    host, and a restart kills every one of them. So every call into the
    core is pcall'd and retried once against a fresh object.
]]

Framework = { name = 'standalone', core = nil }

local function resourceUp(res)
    return GetResourceState(res) == 'started'
end

local function fetchCore()
    local ok, core = false, nil
    if Framework.name == 'qb' then
        ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    elseif Framework.name == 'esx' then
        ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
    end
    if ok and core then Framework.core = core return true end
    return false
end

CreateThread(function()
    if resourceUp('qbx_core') then
        Framework.name = 'qbx'
    elseif resourceUp('qb-core') then
        Framework.name = 'qb'
        fetchCore()
    elseif resourceUp('es_extended') then
        Framework.name = 'esx'
        fetchCore()
    end
end)

local function coreCall(fn)
    if not Framework.core and not fetchCore() then return nil end
    local ok, res = pcall(fn, Framework.core)
    if ok then return res end
    if fetchCore() then
        ok, res = pcall(fn, Framework.core)
        if ok then return res end
    end
    return nil
end

local function corePlayer(src)
    if Framework.name == 'qb' then
        return coreCall(function(core) return core.Functions.GetPlayer(src) end)
    elseif Framework.name == 'esx' then
        return coreCall(function(core) return core.GetPlayerFromId(src) end)
    end
    return nil
end

--- Normalized player snapshot, or nil if the source has no character loaded.
function Framework.GetPlayer(src)
    src = tonumber(src)
    if not src then return nil end

    if Framework.name == 'qbx' then
        local ok, p = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if not ok or not p or not p.PlayerData then return nil end
        local d = p.PlayerData
        return {
            cid  = d.citizenid,
            name = GetPlayerName(src),
            job  = {
                name   = d.job and d.job.name or 'unemployed',
                grade  = d.job and d.job.grade and d.job.grade.level or 0,
                onDuty = d.job and d.job.onduty or false,
            },
        }
    end

    if Framework.name == 'qb' then
        local p = corePlayer(src)
        if type(p) ~= 'table' or type(p.PlayerData) ~= 'table' then return nil end
        local d = p.PlayerData
        return {
            cid  = d.citizenid,
            name = GetPlayerName(src),
            job  = {
                name   = d.job and d.job.name or 'unemployed',
                grade  = d.job and d.job.grade and d.job.grade.level or 0,
                onDuty = d.job and d.job.onduty or false,
            },
        }
    end

    if Framework.name == 'esx' then
        local p = corePlayer(src)
        if type(p) ~= 'table' then return nil end
        return {
            cid  = p.identifier,
            name = GetPlayerName(src),
            job  = {
                name   = p.job and p.job.name or 'unemployed',
                grade  = p.job and p.job.grade or 0,
                onDuty = true,
            },
        }
    end

    -- Standalone: a license identifier and a civilian job.
    return {
        cid  = tostring(GetPlayerIdentifierByType(src, 'license') or src),
        name = GetPlayerName(src),
        job  = { name = 'unemployed', grade = 0, onDuty = true },
    }
end

--- A stable identity for "who placed this": the character id where the
--- framework has one, else the license. Falls back to the source only
--- when nothing else is known, which is a session-long identity at best.
function Framework.Identity(src)
    local p = Framework.GetPlayer(src)
    if p and p.cid then return tostring(p.cid) end
    return tostring(GetPlayerIdentifierByType(src, 'license') or src)
end

--- Is this player an admin BY THE FRAMEWORK'S OWN RECKONING: qb-core's
--- 'admin' or 'god' permission, qbx's the same, an ESX 'admin' or
--- 'superadmin' group. Lets a qb server's admins use the Settings tab
--- without an ACE line; an ACE still works everywhere.
function Framework.IsFrameworkAdmin(src)
    if Framework.name == 'qb' then
        local ok, has = pcall(function()
            return coreCall(function(core)
                return core.Functions.HasPermission(src, 'admin') or core.Functions.HasPermission(src, 'god')
            end)
        end)
        return ok and has == true
    end
    if Framework.name == 'qbx' then
        local ok, has = pcall(function()
            return exports.qbx_core:HasPermission(src, 'admin') or exports.qbx_core:HasPermission(src, 'god')
        end)
        return ok and has == true
    end
    if Framework.name == 'esx' then
        local p = corePlayer(src)
        if type(p) == 'table' and type(p.getGroup) == 'function' then
            local ok, g = pcall(p.getGroup)
            return ok and (g == 'admin' or g == 'superadmin')
        end
    end
    return false
end

function Framework.Notify(src, msg, kind)
    TriggerClientEvent('sals_kewlholidays:notify', src, msg, kind or 'primary')
end
