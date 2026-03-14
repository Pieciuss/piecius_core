local blockedVehicles = {}
for _, model in ipairs(Config.BlockedVehicles) do
    blockedVehicles[GetHashKey(model)] = true
end

function ForceDeleteVehicle(vehicle, ped)
    if not DoesEntityExist(vehicle) then return end

    if ped and GetVehiclePedIsIn(ped, false) == vehicle then
        TaskLeaveVehicle(ped, vehicle, 16)
        FW.Notify('~r~Ten pojazd jest zablokowany na tym serwerze!')
        Wait(1500)
    end

    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local seatPed = GetPedInVehicleSeat(vehicle, seat)
        if seatPed ~= 0 and IsPedAPlayer(seatPed) and seatPed ~= PlayerPedId() then
            return
        end
    end

    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local seatPed = GetPedInVehicleSeat(vehicle, seat)
        if seatPed ~= 0 and not IsPedAPlayer(seatPed) then
            DeleteEntity(seatPed)
        end
    end

    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        Wait(100)
    end
    if NetworkHasControlOfEntity(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
    end
end

CreateThread(function()
    while true do
        Wait(3000)
        local ped = PlayerPedId()
        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local model = GetEntityModel(vehicle)
                if blockedVehicles[model] then
                    ForceDeleteVehicle(vehicle, ped)
                end
            end
        end
    end
end)

if Config.MilitaryBaseCleanup then
    CreateThread(function()
        local zone = Config.MilitaryBaseZone
        while true do
            Wait(5000)
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)

            if #(playerCoords - zone.center) < zone.radius + 200.0 then
                local vehicles = GetGamePool('CVehicle')
                for _, vehicle in ipairs(vehicles) do
                    if DoesEntityExist(vehicle) then
                        local vehCoords = GetEntityCoords(vehicle)
                        if #(vehCoords - zone.center) <= zone.radius then
                            local hasPlayer = false
                            for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                                local seatPed = GetPedInVehicleSeat(vehicle, seat)
                                if seatPed ~= 0 and IsPedAPlayer(seatPed) then
                                    hasPlayer = true
                                    break
                                end
                            end

                            if not hasPlayer then
                                ForceDeleteVehicle(vehicle, ped)
                            end
                        end
                    end
                end
            end
        end
    end)
end

if Config.DisableWantedLevel then
    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            if GetPlayerWantedLevel(PlayerId()) > 0 then
                SetPlayerWantedLevel(PlayerId(), 0, false)
                SetPlayerWantedLevelNow(PlayerId(), false)
            end
            SetMaxWantedLevel(0)
        end
    end)
end

if Config.DisableDispatch then
    CreateThread(function()
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end

        SetScenarioGroupEnabled('DVLA_FREEMODE_TRAINS', false)

        while true do
            Wait(5000)
            for i = 1, 15 do
                EnableDispatchService(i, false)
            end
        end
    end)
end

if Config.DisableEmergencySpawns then
    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            SetCreateRandomCops(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetCreateRandomCopsOnScenarios(false)

            SetGarbageTrucks(false)
            SetRandomBoats(false)
            SetRandomTrains(false)
        end
    end)

    CreateThread(function()
        local emergencyModels = {
            'police', 'police2', 'police3', 'police4', 'policeb',
            'policeold1', 'policeold2', 'policet', 'pranger',
            'sheriff', 'sheriff2', 'riot', 'riot2', 'fbi', 'fbi2',
            'ambulance', 'firetruk', 'lguard', 'polmav',
            'predator', 'pbus', 'policeb'
        }

        local emergencyHashes = {}
        for _, model in ipairs(emergencyModels) do
            emergencyHashes[GetHashKey(model)] = true
        end

        while true do
            Wait(5000)
            local vehicles = GetGamePool('CVehicle')
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) then
                    local model = GetEntityModel(vehicle)
                    if emergencyHashes[model] then
                        local driver = GetPedInVehicleSeat(vehicle, -1)
                        if driver ~= 0 and not IsPedAPlayer(driver) then
                            DeleteEntity(driver)
                            DeleteEntity(vehicle)
                        elseif driver == 0 then
                            local hasPlayerNearby = false
                            for _, playerId in ipairs(GetActivePlayers()) do
                                local playerPed = GetPlayerPed(playerId)
                                if GetVehiclePedIsIn(playerPed, false) == vehicle then
                                    hasPlayerNearby = true
                                    break
                                end
                            end
                            if not hasPlayerNearby then
                                DeleteEntity(vehicle)
                            end
                        end
                    end
                end
            end
        end
    end)

    CreateThread(function()
        while true do
            Wait(5000)
            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                    local pedType = GetPedType(ped)
                    if pedType == 6 or pedType == 15 or pedType == 21 or pedType == 20 then
                        DeleteEntity(ped)
                    end
                end
            end
        end
    end)
end

local vehicleLockStates = {}
local lockCooldown = false

function GetClosestVehicle(coords, maxDist)
    local vehicles = GetGamePool('CVehicle')
    local closestDist = maxDist
    local closestVeh = nil

    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehCoords)
        if dist < closestDist then
            closestDist = dist
            closestVeh = vehicle
        end
    end

    return closestVeh, closestDist
end

function GetVehiclePlateText(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        return plate:gsub('^%s+', ''):gsub('%s+$', '')
    end
    return nil
end

function PlayKeyFobAnim(ped)
    local dict = 'anim@mp_player_intmenu@key_fob@'
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    TaskPlayAnim(ped, dict, 'fob_click', 8.0, -8.0, 1000, 48, 0, false, false, false)
end

function PlayLockSound(vehicle, locking)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    if locking then
        PlaySoundFromEntity(-1, 'Remote_Control_Close', vehicle, 'PI_Menu_Sounds', false, 0)
    else
        PlaySoundFromEntity(-1, 'Remote_Control_Open', vehicle, 'PI_Menu_Sounds', false, 0)
    end
    CreateThread(function()
        if DoesEntityExist(vehicle) then
            SetVehicleLights(vehicle, 2)
            Wait(200)
            SetVehicleLights(vehicle, 0)
            Wait(200)
            if DoesEntityExist(vehicle) then
                SetVehicleLights(vehicle, 2)
                Wait(200)
                SetVehicleLights(vehicle, 0)
            end
        end
    end)
end

RegisterNetEvent('Piecius_core:clientSyncLock')
AddEventHandler('Piecius_core:clientSyncLock', function(netId, locked)
    local vehicle = NetToVeh(netId)
    if vehicle and DoesEntityExist(vehicle) then
        if locked then
            SetVehicleDoorsLocked(vehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        else
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        end
    end
end)

local authorizedVehicles = {}
local hotwireCooldown = false
local isHotwiring = false
local lastVehicle = nil

function HasVehicleAuth(plate)
    if not plate then return false end
    local normalized = plate:gsub('%s+', ''):upper()
    return authorizedVehicles[normalized] == true
end

function SetVehicleAuth(plate, auth)
    if not plate then return end
    local normalized = plate:gsub('%s+', ''):upper()
    authorizedVehicles[normalized] = auth
end

if Config.RequireKeyForEngine then
    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()

            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)

                if GetPedInVehicleSeat(vehicle, -1) == ped then
                    local plate = GetVehiclePlateText(vehicle)

                    if vehicle ~= lastVehicle then
                        lastVehicle = vehicle

                        if plate and not HasVehicleAuth(plate) then
                            FW.TriggerCallback('Piecius_core:hasKey', function(hasKey)
                                if hasKey then
                                    SetVehicleAuth(plate, true)
                                    SetVehicleEngineOn(vehicle, true, false, true)
                                else
                                    SetVehicleEngineOn(vehicle, false, false, true)
                                    SetVehicleUndriveable(vehicle, true)
                                    FW.Notify('~r~Nie masz kluczyka! ~w~Nacisnij ~y~U~w~ aby sprobowac odpaliczyc.')
                                end
                            end, plate)

                            SetVehicleEngineOn(vehicle, false, false, true)
                        end
                    end

                    if plate and not HasVehicleAuth(plate) then
                        SetVehicleEngineOn(vehicle, false, false, true)
                        SetVehicleUndriveable(vehicle, true)

                        DisableControlAction(0, 71, true)
                        DisableControlAction(0, 72, true)
                    else
                        SetVehicleUndriveable(vehicle, false)
                    end
                end
            else
                lastVehicle = nil
            end
        end
    end)
end

local hotwiredPlates = {}

RegisterCommand('+lockVehicle', function()
    if lockCooldown then return end
    lockCooldown = true

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local plate = GetVehiclePlateText(vehicle)

        if plate and GetPedInVehicleSeat(vehicle, -1) == ped then
            local veh = vehicle

            FW.TriggerCallback('Piecius_core:hasKey', function(hasKey)
                if hasKey or HasVehicleAuth(plate) then
                    lockCooldown = false
                    ToggleVehicleLock(veh, plate)
                else
                    lockCooldown = false
                    if Config.HotwireEnabled and not isHotwiring and not hotwireCooldown then
                        AttemptHotwire(veh, plate)
                    elseif hotwireCooldown then
                        FW.Notify('~r~Musisz poczekac przed kolejna proba!')
                    elseif isHotwiring then
                        FW.Notify('~r~Juz proboujesz!')
                    else
                        FW.Notify('~r~Nie masz kluczyka do tego pojazdu!')
                    end
                end
            end, plate)

            SetTimeout(5000, function() lockCooldown = false end)
            return
        end
    end

    local vehicle = GetClosestVehicle(coords, Config.LockDistance)

    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehiclePlateText(vehicle)
        if plate then
            local veh = vehicle

            FW.TriggerCallback('Piecius_core:hasKey', function(hasKey)
                lockCooldown = false
                if hasKey then
                    ToggleVehicleLock(veh, plate)
                else
                    FW.Notify('~r~Nie masz kluczyka do tego pojazdu!')
                end
            end, plate)

            SetTimeout(5000, function() lockCooldown = false end)
        else
            lockCooldown = false
        end
    else
        FW.Notify('~r~Brak pojazdu w poblizu!')
        lockCooldown = false
    end
end, false)

RegisterCommand('-lockVehicle', function() end, false)
RegisterKeyMapping('+lockVehicle', 'Zamknij/Otworz pojazd', 'keyboard', 'U')

function ToggleVehicleLock(veh, plate)
    if not DoesEntityExist(veh) then return end

    if not NetworkHasControlOfEntity(veh) then
        NetworkRequestControlOfEntity(veh)
        local timeout = 0
        while not NetworkHasControlOfEntity(veh) and timeout < 3000 do
            Wait(10)
            timeout = timeout + 10
        end
    end

    if not NetworkHasControlOfEntity(veh) then
        FW.Notify('~r~Nie mozna uzyskac kontroli nad pojazdem!')
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(veh)
    local isLocked = (lockStatus == 2 or lockStatus == 10)

    if isLocked then
        SetVehicleDoorsLocked(veh, 1)
        SetVehicleDoorsLockedForAllPlayers(veh, false)
        vehicleLockStates[plate] = false
        PlayLockSound(veh, false)
        FW.Notify('~g~Pojazd odblokowany!')
    else
        SetVehicleDoorsLocked(veh, 2)
        SetVehicleDoorsLockedForAllPlayers(veh, true)
        vehicleLockStates[plate] = true
        PlayLockSound(veh, true)
        FW.Notify('~r~Pojazd zablokowany!')
    end

    PlayKeyFobAnim(PlayerPedId())

    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent('Piecius_core:syncLock', VehToNet(veh), not isLocked)
    end
end

function AttemptHotwire(vehicle, plate)
    if not DoesEntityExist(vehicle) then return end
    isHotwiring = true

    FW.Notify('~y~Proboujesz odpaliczyc pojazd...')

    exports.Piecius_hud:Progressbar('Odpalanie pojazdu...', Config.HotwireTime)

    local dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 2000 do
        Wait(10)
        timeout = timeout + 10
    end

    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, 'machinic_loop_mechandler', 2.0, -2.0, Config.HotwireTime, 49, 0, false, false, false)

    local startTime = GetGameTimer()
    local hotwireTime = Config.HotwireTime

    CreateThread(function()
        while isHotwiring and (GetGameTimer() - startTime) < hotwireTime do
            Wait(100)
            if not IsPedInAnyVehicle(ped, false) then
                isHotwiring = false
                ClearPedTasks(ped)
                FW.Notify('~r~Przerwano - wyszedles z pojazdu!')
                return
            end
        end

        if not isHotwiring then return end
        isHotwiring = false

        ClearPedTasks(PlayerPedId())

        local roll = math.random(1, 100)
        if roll <= Config.HotwireChance then
            SetVehicleAuth(plate, true)
            hotwiredPlates[plate:gsub('%s+', ''):upper()] = true

            if DoesEntityExist(vehicle) then
                SetVehicleEngineOn(vehicle, true, false, true)
                SetVehicleUndriveable(vehicle, false)
            end

            TriggerServerEvent('Piecius_core:hotwireSuccess', plate)

            FW.Notify('~g~Udalo sie! Znalazles kluczyk w schowku!')

            PlaySoundFrontend(-1, 'PICKING_UP_WEAPON', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            FW.Notify('~r~Nie udalo sie znalezc kluczyka...')

            PlaySoundFrontend(-1, 'CANCEL', 'HUD_FREEMODE_SOUNDSET', true)
        end

        hotwireCooldown = true
        SetTimeout(Config.HotwireCooldown, function()
            hotwireCooldown = false
        end)
    end)
end

local dowodMenuOpen = false

function GetNearbyPlayers(radius)
    local players = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist <= radius then
                table.insert(players, {
                    id = GetPlayerServerId(playerId),
                    name = GetPlayerName(playerId),
                    dist = math.floor(dist * 10) / 10
                })
            end
        end
    end

    return players
end

RegisterCommand(Config.DowodCommand, function()
    if dowodMenuOpen then
        CloseDowodMenu()
        return
    end

    local nearbyPlayers = GetNearbyPlayers(Config.DowodRadius)

    if #nearbyPlayers == 0 then
        FW.Notify('~r~Brak graczy w poblizu!')
        return
    end

    dowodMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showPlayerSelect',
        players = nearbyPlayers
    })
end, false)

function CloseDowodMenu()
    dowodMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'hidePlayerSelect'
    })
end

RegisterNUICallback('selectPlayer', function(data, cb)
    CloseDowodMenu()
    local targetId = tonumber(data.targetId)
    if targetId then
        TriggerServerEvent('Piecius_core:showDowodToPlayer', targetId)
    end
    cb('ok')
end)

RegisterNUICallback('showToAll', function(data, cb)
    CloseDowodMenu()
    local nearbyPlayers = GetNearbyPlayers(Config.DowodRadius)
    local targetIds = {}
    for _, p in ipairs(nearbyPlayers) do
        table.insert(targetIds, p.id)
    end
    TriggerServerEvent('Piecius_core:showDowodToAll', targetIds)
    cb('ok')
end)

RegisterNUICallback('closeDowodMenu', function(data, cb)
    CloseDowodMenu()
    cb('ok')
end)

RegisterNUICallback('closeDowod', function(data, cb)
    SendNUIMessage({ action = 'hideDowod' })
    cb('ok')
end)

RegisterNetEvent('Piecius_core:receiveDowod')
AddEventHandler('Piecius_core:receiveDowod', function(data, showTime)
    SendNUIMessage({
        action = 'showDowod',
        data = data,
        showTime = showTime or Config.DowodShowTime
    })
end)