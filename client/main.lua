timeBetweenStops = {}
busesStatus = {}
firstSpawn = true

state = {'Driving to bus stop', 'Parking', 'Waiting'}

Citizen.CreateThread(function()
	for _, route in ipairs(Config.Routes) do
		for _, curr in ipairs(route.busStops) do
			if curr.stop == true then  
				local blip = AddBlipForCoord(curr.pos)

				SetBlipSprite (blip, 513)
				SetBlipColour (blip, route.info.color)
				SetBlipScale(blip, 0.5)
				SetBlipAsShortRange(blip, true)
			
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName("Bus stop")
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)

RegisterNetEvent("publictransport:startBus")
AddEventHandler("publictransport:startBus", function(pedNetId, route)
	while not NetworkDoesNetworkIdExist(pedNetId) do
		Wait(0)
	end
	local busDriver = NetToPed(pedNetId)
	local bus = GetVehiclePedIsIn(busDriver, false)

	while bus == 0 do 
		bus = GetVehiclePedIsIn(busDriver, false)		
		Wait(0)
	end

	SetEntityAsMissionEntity(busDriver, true, true)
	SetEntityAsMissionEntity(bus, true, true)
	SetEntityCanBeDamaged(bus, false)
	SetVehicleDamageModifier(bus, 0.0)
	SetVehicleEngineCanDegrade(bus, false)
	SetEntityCanBeDamaged(busDriver, false)
	SetPedCanBeTargetted(busDriver, false)
	SetDriverAbility(busDriver, 1.0)
	SetDriverAggressiveness(busDriver, 0.0)
	SetBlockingOfNonTemporaryEvents(busDriver, true)
	SetPedConfigFlag(busDriver, 251, true)
	SetPedConfigFlag(busDriver, 64, true)
	SetPedStayInVehicleWhenJacked(busDriver, true)
	SetPedCanBeDraggedOut(busDriver, false)

	local busStop = 2
	while true do
		local data = Config.Routes[route].busStops[busStop]
		TaskVehicleDriveToCoordLongrange(busDriver, bus, data.pos, 40.0, Config.DriveStyle, 25.0)		
		WaitTaskToEnd(busDriver, 567490903)
		if GetScriptTaskStatus(busDriver, 567490903) == 7 then -- Parking
			if data.stop == true then
				--TaskVehicleDriveToCoord(busDriver, bus, data.pos, 7.0, 1.0, GetHashKey(Config.Routes[route].info.hash),1076369727, 2.5, true) 
				TaskVehicleDriveToCoordLongrange(busDriver, bus, data.pos, 8.0, Config.DriveStyle, 6.0)
				WaitTaskToEnd(busDriver, 567490903)
				if GetScriptTaskStatus(busDriver, 567490903) == 7 then --Waiting
					Wait(Config.WaitTimeAtBusStop*1000)
				end
			end
			if (busStop+1) > #Config.Routes[route].busStops then
				busStop = 1
			else
				busStop = busStop + 1
			end
		end
		Wait(0)
	end	
end)

function WaitTaskToEnd(ped, task)
	while GetScriptTaskStatus(ped, task) == 0 do
		Wait(250)
	end
	while GetScriptTaskStatus(ped, task) == 1 do
		Wait(250)
	end
end

AddEventHandler("playerSpawned", function(spawnInfo)
	if firstSpawn then
		TriggerServerEvent("publictransport:onPlayerSpawn")
		firstSpawn = false
	end
end)

RegisterNetEvent("publictransport:registerBusBlip")
AddEventHandler("publictransport:registerBusBlip", function(busNetId, color)
	while not NetworkDoesNetworkIdExist(busNetId) do Wait(0) end
	local bus = NetworkGetEntityFromNetworkId(busNetId)
	local busBlip = AddBlipForEntity(bus)
	SetBlipSprite (1, 463)
	SetBlipColour (busBlip, color)
	SetBlipScale(busBlip, 0.5)
	SetBlipAsShortRange(busBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName("Bus " .. color)
	EndTextCommandSetBlipName(busBlip)
end)

RegisterNetEvent("publictransport:registerBlips")
AddEventHandler("publictransport:registerBlips", function(blips)
	for i, blip in ipairs(blips) do
		while not NetworkDoesNetworkIdExist(blip.busNetId) do Wait(0) end
		local bus = NetworkGetEntityFromNetworkId(blip.busNetId)
		local busBlip = AddBlipForEntity(bus)
		SetBlipSprite (1, 463)
		SetBlipColour (busBlip, blip.color)
		SetBlipScale(busBlip, 0.5)
		SetBlipAsShortRange(busBlip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName("Bus " .. blip.color)
		EndTextCommandSetBlipName(busBlip)
	end
end)