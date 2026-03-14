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

function FW.Notify(msg, nType)
    if isESX then
        FW.Core.ShowNotification(msg)
    elseif isQB then
        FW.Core.Functions.Notify(msg, nType or 'primary')
    end
end

function FW.ShowHelpNotification(msg)
    if isESX then
        FW.Core.ShowHelpNotification(msg)
    elseif isQB then
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end

function FW.TriggerCallback(name, cb, ...)
    if isESX then
        FW.Core.TriggerServerCallback(name, cb, ...)
    elseif isQB then
        FW.Core.Functions.TriggerCallback(name, cb, ...)
    end
end

function FW.GetPlayerData()
    if isESX then
        return FW.Core.GetPlayerData()
    elseif isQB then
        local pd = FW.Core.Functions.GetPlayerData()
        if not pd then return {} end
        return {
            money = pd.money and pd.money.cash or 0,
            accounts = {
                { name = 'money', money = pd.money and pd.money.cash or 0 },
                { name = 'bank', money = pd.money and pd.money.bank or 0 },
            },
            job = pd.job,
            identifier = pd.citizenid,
            firstName = pd.charinfo and pd.charinfo.firstname or '',
            lastName = pd.charinfo and pd.charinfo.lastname or '',
        }
    end
    return {}
end

function FW.OnPlayerLoaded(cb)
    if isESX then
        RegisterNetEvent('esx:playerLoaded', function(xPlayer) cb(xPlayer) end)
    elseif isQB then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() cb(FW.GetPlayerData()) end)
    end
end

function FW.OnPlayerLogout(cb)
    if isESX then
        RegisterNetEvent('esx:onPlayerLogout', function() cb() end)
    elseif isQB then
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() cb() end)
    end
end

function FW.SetPlayerData(key, val)
    if isESX then
        FW.Core.SetPlayerData(key, val)
    elseif isQB then
        local pd = FW.Core.Functions.GetPlayerData()
        if pd then pd[key] = val end
    end
end

FW.PlayerLoaded = false
FW.PlayerData = {}

FW.OnPlayerLoaded(function(playerData)
    FW.PlayerLoaded = true
    FW.PlayerData = playerData or FW.GetPlayerData()
end)

FW.OnPlayerLogout(function()
    FW.PlayerLoaded = false
    FW.PlayerData = {}
end)

FW.playerId = PlayerId()
FW.PlayerId = PlayerId()

FW.Game = {}

function FW.Game.SetVehicleProperties(vehicle, props)
    if isESX then
        FW.Core.Game.SetVehicleProperties(vehicle, props)
    elseif isQB then
        FW.Core.Functions.SetVehicleProperties(vehicle, props)
    end
end

function FW.Game.GetVehicleProperties(vehicle)
    if isESX then
        return FW.Core.Game.GetVehicleProperties(vehicle)
    elseif isQB then
        return FW.Core.Functions.GetVehicleProperties(vehicle)
    end
end

FW.Streaming = {}

function FW.Streaming.RequestModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    return hash
end

FW.Math = {}

function FW.Math.Random(min, max)
    return math.random(min, max)
end

function FW.DisableSpawnManager()
    if isESX and FW.Core.DisableSpawnManager then
        FW.Core.DisableSpawnManager()
    end
end

function FW.Await(fn)
    if isESX and FW.Core.Await then
        FW.Core.Await(fn)
    else
        while not fn() do Wait(100) end
    end
end

function FW.SetTimeout(ms, cb)
    SetTimeout(ms, cb)
end

function FW.SpawnPlayer(skin, coords, cb)
    if isESX and FW.Core.SpawnPlayer then
        FW.Core.SpawnPlayer(skin, coords, cb)
    else
        local ped = PlayerPedId()
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
        if coords.w then SetEntityHeading(ped, coords.w) end
        if cb then cb() end
    end
end

function FW.GetConfig(key)
    if isESX then
        if key then
            local cfg = FW.Core.GetConfig()
            return cfg and cfg[key]
        end
        return FW.Core.GetConfig()
    else
        if key == 'Identifier' then return 'license' end
        return {}
    end
end
