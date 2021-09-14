ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end
end)
-- Blips
Citizen.CreateThread(function()
    for _, route in pairs(Config.Routes) do
        for i, pos in ipairs(route) do
            local blip = AddBlipForCoord(pos)

            SetBlipSprite (blip, 1)
            SetBlipColour (blip, 44)
            SetBlipScale(blip, 0.4)
            SetBlipAsShortRange(blip, true)
        
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName("Bus stop")
            EndTextCommandSetBlipName(blip)
        end
    end
end)

Citizen.CreateThread(function()
    ESX.TriggerServerCallback("esx_publictransports:serviceStatus", function(serviceStatus) 
        if(serviceStatus == false) then
            TriggerServerEvent("esx_publictransports:setStatus", true)

            ActiveService(Config.Routes.Route436)
        end
    end)

    while currentVehicle == nil do
        Wait(1000)
    end

end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    print("Player loaded")
    ESX.TriggerServerCallback("esx_publictransports:getVehicle", function(vehicle)
        if vehicle == nil then return end
        print("vehicle : " .. vehicle .. " ")
        print(DoesEntityExist(NetworkGetEntityFromNetworkId(vehicle)))
        local busBlip = AddBlipForEntity(NetworkGetEntityFromNetworkId(vehicle))
        SetBlipSprite (1, 463)
        SetBlipColour (busBlip, 38)
        SetBlipScale(busBlip, 0.5)
        SetBlipAsShortRange(busBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Bus')
        EndTextCommandSetBlipName(busBlip)
    end)
end)

function ActiveService(route)
    local startPos = route.start.pos
    local heading = route.start.heading
    local currentVehicle = nil
    ESX.Game.SpawnVehicle(-713569950, startPos, heading, function(vehicle)
        -- Vehicle
        while vehicle == nil do
            Wait(1)
        end
        currentVehicle = vehicle
        print("Vehicle done")
        while not NetworkGetEntityIsNetworked(vehicle) do
            Wait(1)
        end
        print("Network done")
        TriggerServerEvent("esx_publictransports:registerVehicle", NetworkGetNetworkIdFromEntity(vehicle))

        local busBlip = AddBlipForEntity(vehicle)
        SetBlipSprite (1, 463)
        SetBlipColour (busBlip, 38)
        SetBlipScale(busBlip, 0.5)
        SetBlipAsShortRange(busBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('BUS')
        EndTextCommandSetBlipName(busBlip)

        SetEntityAsMissionEntity(vehicle, true,true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)

        -- Ped
        local hash = GetHashKey("ig_bankman")
        while not HasModelLoaded(hash) do
            RequestModel(hash)
            Wait(50)
        end
        print("Ped done")
        local ped = CreatePed(0, hash, startPos.x+math.random(-4.0, 4.0), startPos.y+math.random(-4.0, 4.0), startPos.z, math.random(0, 360), true, true)
        SetPedIntoVehicle(ped, vehicle, -1)
        SetPedRelationshipGroupHash(ped, "PLAYER")
        SetPedHearingRange(ped, 0.0)
        SetPedSeeingRange(ped, 0.0)
        SetPedAlertness(ped, 0.0)
        SetPedFleeAttributes(ped, 0, 0)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityCanBeDamaged(ped, false)
        SetPedCanBeTargetted(ped, false)
        SetEntityAsMissionEntity(ped, true,true)
        SetDriverAbility(ped, 1.0)
        -- START ROUTE
        local i = 2
        local isDriving = false
        while true do
            Wait(0)

            if not isDriving then
                TaskVehicleDriveToCoordLongrange(ped, vehicle, route[i], 20.0, 319, 1.0) -- 443 -> respect traffic lights
                SetPedKeepTask(ped, true)
                isDriving = true
            end

            
            if Vdist(GetEntityCoords(vehicle), route[i]) <= 8.0 then
                isDriving = false
                Wait(8000)
                if i == #route then i = 1 else i = i + 1 end
            else
                Wait(1000)
            end
        end
    end)
end