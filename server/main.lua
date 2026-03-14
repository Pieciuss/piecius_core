local function NormalizePlate(plate)
    if not plate then return '' end
    return plate:gsub('%s+', ''):upper()
end

local function PlayerHasKey(source, plate)
    local normalizedPlate = NormalizePlate(plate)
    local success, items = pcall(function()
        return exports.ox_inventory:Search(source, 'slots', Config.KeyItem)
    end)

    if success and items then
        for _, item in pairs(items) do
            if item and item.metadata and item.metadata.plate then
                if NormalizePlate(item.metadata.plate) == normalizedPlate then
                    return true
                end
            end
        end
    end

    return false
end

local function GiveKey(source, plate, vehicleLabel)
    local normalizedPlate = NormalizePlate(plate)
    local label = vehicleLabel or 'Pojazd'
    local metadata = {
        plate = normalizedPlate,
        description = 'Rejestracja: **' .. normalizedPlate .. '**\nPojazd: ' .. label,
        label = 'Kluczyk [' .. normalizedPlate .. ']'
    }

    local success, result = pcall(function()
        return exports.ox_inventory:AddItem(source, Config.KeyItem, 1, metadata)
    end)

    if not success then
        local xPlayer = FW.GetPlayer(source)
        if xPlayer then
            xPlayer.addInventoryItem(Config.KeyItem, 1, metadata)
        end
    end

    return success
end

FW.RegisterCallback('Piecius_core:hasKey', function(source, cb, plate)
    local xPlayer = FW.GetPlayer(source)
    if not xPlayer then
        print('[Piecius_core] hasKey: brak xPlayer dla source=' .. tostring(source))
        return cb(false)
    end

    local normalizedPlate = NormalizePlate(plate)
    print('[Piecius_core] hasKey: sprawdzam plate="' .. tostring(plate) .. '" normalized="' .. normalizedPlate .. '" dla gracza ' .. xPlayer.getName())

    local hasKeyItem = false
    local searchOk, searchResult = pcall(function()
        return exports.ox_inventory:Search(source, 'slots', Config.KeyItem)
    end)

    print('[Piecius_core] hasKey: ox_inventory Search ok=' .. tostring(searchOk) .. ' result=' .. tostring(searchResult ~= nil))

    if searchOk and searchResult then
        if type(searchResult) == 'table' then
            for _, item in pairs(searchResult) do
                if item and item.metadata and item.metadata.plate then
                    local keyPlate = NormalizePlate(item.metadata.plate)
                    print('[Piecius_core] hasKey: porownuje kluczyk plate="' .. keyPlate .. '" z "' .. normalizedPlate .. '"')
                    if keyPlate == normalizedPlate then
                        hasKeyItem = true
                        break
                    end
                else
                    print('[Piecius_core] hasKey: kluczyk bez metadata.plate: ' .. tostring(item and item.metadata and type(item.metadata)))
                end
            end
        end
    end

    if hasKeyItem then
        print('[Piecius_core] hasKey: ZNALEZIONO kluczyk w inventory -> true')
        return cb(true)
    end

    local dbOk, dbResult = pcall(function()
        return MySQL.scalar.await("SELECT COUNT(*) FROM owned_vehicles WHERE owner = ? AND UPPER(REPLACE(TRIM(plate), ' ', '')) = ?", {
            xPlayer.getIdentifier(), normalizedPlate
        })
    end)

    print('[Piecius_core] hasKey: DB check ok=' .. tostring(dbOk) .. ' result=' .. tostring(dbResult))

    if dbOk and dbResult and tonumber(dbResult) > 0 then
        print('[Piecius_core] hasKey: WLASCICIEL w bazie -> true')
        return cb(true)
    end

    print('[Piecius_core] hasKey: BRAK kluczyka i nie wlasciciel -> false')
    cb(false)
end)

RegisterNetEvent('Piecius_core:syncLock')
AddEventHandler('Piecius_core:syncLock', function(netId, locked)
    local src = source
    local players = FW.GetPlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= src then
            TriggerClientEvent('Piecius_core:clientSyncLock', playerId, netId, locked)
        end
    end
end)

local function GenerateSSN(identifier)
    if not identifier then return '000-00-0000' end
    local hash = 0
    for i = 1, #identifier do
        hash = (hash * 31 + string.byte(identifier, i)) % 999999999
    end
    local ssn = string.format('%09d', hash)
    return ssn:sub(1,3) .. '-' .. ssn:sub(4,5) .. '-' .. ssn:sub(6,9)
end

local function GetPlayerDowodData(source, cb)
    local xPlayer = FW.GetPlayer(source)
    if not xPlayer then return cb(nil) end

    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result and #result > 0 then
            local user = result[1]

            local data = {
                imie = user.firstname or 'Nieznane',
                nazwisko = user.lastname or 'Nieznane',
                data_urodzenia = user.dateofbirth or 'Nieznana',
                plec = user.sex or 'Nieznana',
                wzrost = user.height or 'Nieznany',
                numer_telefonu = user.phone_number or 'Brak',
                ssn = GenerateSSN(identifier),
                praca = xPlayer.getJob().label or 'Bezrobotny',
            }

            if data.plec == 'm' or data.plec == 'male' or data.plec == '0' then
                data.plec = 'Mezczyzna'
            elseif data.plec == 'f' or data.plec == 'female' or data.plec == '1' then
                data.plec = 'Kobieta'
            end

            cb(data)
        else
            cb(nil)
        end
    end)
end

FW.RegisterCallback('Piecius_core:getDowodData', function(source, cb)
    GetPlayerDowodData(source, cb)
end)

RegisterNetEvent('Piecius_core:showDowodToPlayer')
AddEventHandler('Piecius_core:showDowodToPlayer', function(targetId)
    local src = source
    local targetPlayer = FW.GetPlayer(targetId)
    if not targetPlayer then return end

    GetPlayerDowodData(src, function(data)
        if data then
            TriggerClientEvent('Piecius_core:receiveDowod', targetId, data, Config.DowodShowTime)
            TriggerClientEvent('Piecius_core:receiveDowod', src, data, Config.DowodShowTime)
        end
    end)
end)

RegisterNetEvent('Piecius_core:showDowodToAll')
AddEventHandler('Piecius_core:showDowodToAll', function(targetIds)
    local src = source
    if not targetIds or type(targetIds) ~= 'table' then return end

    GetPlayerDowodData(src, function(data)
        if data then
            for _, targetId in ipairs(targetIds) do
                local targetPlayer = FW.GetPlayer(targetId)
                if targetPlayer then
                    TriggerClientEvent('Piecius_core:receiveDowod', targetId, data, Config.DowodShowTime)
                end
            end
            TriggerClientEvent('Piecius_core:receiveDowod', src, data, Config.DowodShowTime)
        end
    end)
end)

RegisterCommand('dajkluczyk', function(source, args, rawCommand)
    local xPlayer = FW.GetPlayer(source)

    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        FW.NotifyClient(source, '~r~Brak uprawnien!')
        return
    end

    local targetId = tonumber(args[1])
    local plate = args[2]

    if not targetId or not plate then
        FW.NotifyClient(source, '~r~Uzycie: /dajkluczyk [id] [tablica]')
        return
    end

    local targetPlayer = FW.GetPlayer(targetId)
    if not targetPlayer then
        FW.NotifyClient(source, '~r~Nie znaleziono gracza!')
        return
    end

    local normalizedPlate = NormalizePlate(plate)

    MySQL.Async.fetchAll("SELECT vehicle FROM owned_vehicles WHERE UPPER(REPLACE(TRIM(plate), ' ', '')) = @plate LIMIT 1", {
        ['@plate'] = normalizedPlate
    }, function(result)
        local vehicleLabel = 'Pojazd'
        if result and #result > 0 and result[1].vehicle then
            local vehData = result[1].vehicle
            if type(vehData) == 'string' then
                local model = vehData:match('"model"%s*:%s*(%d+)')
                if model then
                    vehicleLabel = 'Pojazd #' .. normalizedPlate
                end
            end
        end

        GiveKey(targetId, normalizedPlate, vehicleLabel)
        FW.NotifyClient(source, '~g~Dano kluczyk z tablica: ' .. normalizedPlate)
        FW.NotifyClient(targetId, '~g~Otrzymales kluczyk do pojazdu: ' .. normalizedPlate)
    end)
end, true)

RegisterCommand('zrobkluczyk', function(source, args, rawCommand)
    local xPlayer = FW.GetPlayer(source)
    if not xPlayer then return end

    local plate = args[1]
    if not plate then
        FW.NotifyClient(source, '~r~Uzycie: /zrobkluczyk [tablica]')
        return
    end

    local normalizedPlate = NormalizePlate(plate)

    MySQL.Async.fetchAll("SELECT vehicle FROM owned_vehicles WHERE owner = @owner AND UPPER(REPLACE(TRIM(plate), ' ', '')) = @plate LIMIT 1", {
        ['@owner'] = xPlayer.getIdentifier(),
        ['@plate'] = normalizedPlate
    }, function(result)
        if result and #result > 0 then
            GiveKey(source, normalizedPlate, 'Pojazd #' .. normalizedPlate)
            FW.NotifyClient(source, '~g~Zrobiono kluczyk do pojazdu: ' .. normalizedPlate)
        else
            FW.NotifyClient(source, '~r~Nie jestes wlascicielem tego pojazdu!')
        end
    end)
end, false)

RegisterCommand('dajklucz', function(source, args, rawCommand)
    local xPlayer = FW.GetPlayer(source)
    if not xPlayer then return end

    local targetId = tonumber(args[1])
    if not targetId then
        FW.NotifyClient(source, '~r~Uzycie: /dajklucz [id_gracza]')
        return
    end

    local targetPlayer = FW.GetPlayer(targetId)
    if not targetPlayer then
        FW.NotifyClient(source, '~r~Nie znaleziono gracza!')
        return
    end

    local success, items = pcall(function()
        return exports.ox_inventory:Search(source, 'slots', Config.KeyItem)
    end)

    if success and items and #items > 0 then
        local keyItem = items[1]
        local metadata = keyItem.metadata or {}
        local plate = metadata.plate or 'UNKNOWN'

        exports.ox_inventory:RemoveItem(source, Config.KeyItem, 1, metadata, keyItem.slot)
        GiveKey(targetId, plate, 'Pojazd #' .. plate)

        FW.NotifyClient(source, '~g~Dales kluczyk [' .. plate .. '] graczowi ID: ' .. targetId)
        FW.NotifyClient(targetId, '~g~Otrzymales kluczyk do pojazdu: ' .. plate)
    else
        FW.NotifyClient(source, '~r~Nie masz zadnego kluczyka!')
    end
end, false)

RegisterNetEvent('Piecius_core:hotwireSuccess')
AddEventHandler('Piecius_core:hotwireSuccess', function(plate)
    local src = source
    if not plate or plate == '' then return end

    local normalizedPlate = NormalizePlate(plate)

    if PlayerHasKey(src, normalizedPlate) then
        print('[Piecius_core] Hotwire: gracz ' .. src .. ' juz ma kluczyk do ' .. normalizedPlate)
        return
    end

    print('[Piecius_core] Hotwire sukces: gracz ' .. src .. ' dostal kluczyk do ' .. normalizedPlate)
    GiveKey(src, normalizedPlate, 'Hotwire')
end)

print('[^2Piecius_core^0] Zaladowano pomyslnie!')