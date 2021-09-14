ESX = nil

isServiceActive = false
vehicleList = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("pos", function(source, args)
    print(GetEntityCoords(GetPlayerPed(source)))
end)

RegisterCommand("posbegin", function(source, args)
    print("pos = " .. GetEntityCoords(GetPlayerPed(source)) .. ", heading = " .. GetEntityHeading(GetPlayerPed(source)))
end)

RegisterCommand("test", function(source, args)
    local ped = CreatePed(0, GetHashKey("ig_bankman"), GetEntityCoords(GetPlayerPed(source)), 0.0, true, true, true)
    local vehicle = CreateVehicle(GetHashKey("Bus"), vector3(252.9626, -1223.683, 28.82495), 272.1259765625, true, true)
    SetPedIntoVehicle(ped, vehicle, -1)
    --TaskDriveBy(ped, ped, vehicle, vector3(240.9363, -831.5077, 29.27991), 1.0, 1.0, false)
    -- while true do
    --     Wait(1000)
    --     print(DoesEntityExist(ped))
    --     print(DoesEntityExist(vehicle))
    --     print("---")
    -- end
end)

ESX.RegisterServerCallback("esx_publictransports:serviceStatus", function(playerId, cb)
    cb(isServiceActive)
end)

ESX.RegisterServerCallback("esx_publictransports:getVehicle", function(plaeyrId, cb)
    while not isServiceActive do
        Wait(500)
    end
    cb(vehicleList[1])
end)

RegisterNetEvent("esx_publictransports:setStatus")
AddEventHandler("esx_publictransports:setStatus", function(status)
    isServiceActive = status
end)

RegisterNetEvent("esx_publictransports:registerVehicle")
AddEventHandler("esx_publictransports:registerVehicle", function(id)
    table.insert(vehicleList, tonumber(id))
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
    end
    for _, vehicle in ipairs(vehicleList) do
        DeleteEntity(NetworkGetEntityFromNetworkId(vehicle))
    end
end)
