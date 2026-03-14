local _rn = GetCurrentResourceName()
if _rn:sub(1, 7) ~= ('\112\105\101\99\105\117\115') then
    print('^1[' .. _rn .. '] UNAUTHORIZED: Resource name mismatch. This resource is protected by piecius.^0')
    return
end

FW = {}

local isESX = GetResourceState('es_extended') ~= 'missing'
local isQB = GetResourceState('qb-core') ~= 'missing'

if isESX then
    FW.Core = exports['es_extended']:getSharedObject()
elseif isQB then
    FW.Core = exports['qb-core']:GetCoreObject()
end

FW.IsESX = isESX
FW.IsQB = isQB

local function WrapQBPlayer(Player)
    if not Player then return nil end
    local src = Player.PlayerData.source
    return {
        source = src,
        getIdentifier = function() return Player.PlayerData.citizenid end,
        getName = function()
            local ci = Player.PlayerData.charinfo
            return (ci.firstname or '') .. ' ' .. (ci.lastname or '')
        end,
        getJob = function()
            local j = Player.PlayerData.job
            return {
                name = j.name,
                label = j.label,
                grade = j.grade and j.grade.level or 0,
                grade_name = j.grade and j.grade.name or '',
                grade_label = j.grade and j.grade.name or '',
            }
        end,
        getGroup = function()
            if FW.Core.Functions.HasPermission(src, 'admin') then return 'admin' end
            if FW.Core.Functions.HasPermission(src, 'god') then return 'superadmin' end
            return 'user'
        end,
        getMoney = function() return Player.Functions.GetMoney('cash') end,
        getAccount = function(acc)
            return { money = Player.Functions.GetMoney(acc) }
        end,
        removeMoney = function(amount) Player.Functions.RemoveMoney('cash', amount) end,
        removeAccountMoney = function(acc, amount) Player.Functions.RemoveMoney(acc, amount) end,
        addMoney = function(amount) Player.Functions.AddMoney('cash', amount) end,
        addAccountMoney = function(acc, amount) Player.Functions.AddMoney(acc, amount) end,
        addInventoryItem = function(item, count, metadata)
            exports.ox_inventory:AddItem(src, item, count, metadata)
        end,
        get = function(key)
            if key == 'firstName' or key == 'firstname' then return Player.PlayerData.charinfo.firstname end
            if key == 'lastName' or key == 'lastname' then return Player.PlayerData.charinfo.lastname end
            if key == 'dateofbirth' then return Player.PlayerData.charinfo.birthdate end
            if key == 'sex' then return Player.PlayerData.charinfo.gender == 0 and 'm' or 'f' end
            if key == 'height' then return Player.PlayerData.metadata and Player.PlayerData.metadata.height or '180' end
            return Player.PlayerData[key]
        end,
        set = function(key, val)
            Player.Functions.SetPlayerData(key, val)
        end,
        triggerEvent = function(eventName, ...)
            TriggerClientEvent(eventName, src, ...)
        end,
    }
end

function FW.GetPlayer(source)
    if isESX then
        return FW.Core.GetPlayerFromId(source)
    elseif isQB then
        return WrapQBPlayer(FW.Core.Functions.GetPlayer(source))
    end
end

FW.Player = FW.GetPlayer

function FW.RegisterCallback(name, cb)
    if isESX then
        FW.Core.RegisterServerCallback(name, cb)
    elseif isQB then
        FW.Core.Functions.CreateCallback(name, cb)
    end
end

function FW.GetPlayers()
    if isESX then
        return FW.Core.GetPlayers()
    elseif isQB then
        return FW.Core.Functions.GetPlayers()
    end
end

function FW.NotifyClient(source, msg, nType)
    if isESX then
        TriggerClientEvent('esx:showNotification', source, msg)
    elseif isQB then
        TriggerClientEvent('QBCore:Notify', source, msg, nType or 'primary')
    end
end

function FW.RegisterCommand(name, group, cb, allowConsole, suggestion)
    RegisterCommand(name, function(source, args, rawCommand)
        if source == 0 then
            if allowConsole then cb(nil, args, rawCommand) end
            return
        end
        local xPlayer = FW.GetPlayer(source)
        if not xPlayer then return end
        if group == 'admin' or group == 'superadmin' then
            if xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin' then
                FW.NotifyClient(source, '~r~Brak uprawnien!')
                return
            end
        end
        cb(xPlayer, args, rawCommand)
    end, group == 'admin' or group == 'superadmin')
end

function FW.GetConfig()
    if isESX then
        return FW.Core.GetConfig()
    else
        return { MaxWeight = 24000, CustomInventory = true }
    end
end

function FW.OnPlayerLoaded(cb)
    if isESX then
        RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer, spot)
            cb(playerId, xPlayer)
        end)
    elseif isQB then
        RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
            cb(Player.PlayerData.source, WrapQBPlayer(Player))
        end)
    end
end

function FW.GetIdentifier(source)
    if isESX then
        return FW.Core.GetIdentifier(source)
    elseif isQB then
        local Player = FW.Core.Functions.GetPlayer(source)
        if Player then return Player.PlayerData.citizenid end
        return nil
    end
end

function FW.GetPlayerFromIdentifier(identifier)
    if isESX then
        return FW.Core.GetPlayerFromIdentifier(identifier)
    elseif isQB then
        local players = FW.Core.Functions.GetQBPlayers()
        for _, Player in pairs(players) do
            if Player.PlayerData.citizenid == identifier then
                return WrapQBPlayer(Player)
            end
        end
        return nil
    end
end

function FW.GetJobs()
    if isESX then
        return FW.Core.GetJobs()
    elseif isQB then
        return FW.Core.Shared.Jobs or {}
    end
end

function FW.IsValidLocaleString(str)
    if isESX then
        return FW.Core.IsValidLocaleString(str)
    else
        return str and #str > 0 and str:match("^[%a%s%-']+$") ~= nil
    end
end

function FW.ExtendedPlayers()
    if isESX then
        return FW.Core.ExtendedPlayers()
    elseif isQB then
        local result = {}
        local players = FW.Core.Functions.GetQBPlayers()
        for src, Player in pairs(players) do
            result[src] = WrapQBPlayer(Player)
        end
        return result
    end
end

FW.Players = {}
FW.Jobs = {}
