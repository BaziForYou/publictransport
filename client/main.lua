timeBetweenStops = {}
busesStatus = {}

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
	
	local task = OpenSequenceTask()
	for k, v in pairs(Config.Routes[route].busStops) do
		TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 50.0, Config.DriveStyle, 40.0) -- speed 20.0
		
		if v.stop == true then
			TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 9.0, 60, 6.0)
			TaskPause(0, Config.WaitTimeAtBusStop*1000)
		elseif v.stop == false then
			TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 50.0, Config.DriveStyle, 15.0)
			TaskPause(0, 1)
		end
	end
	SetSequenceToRepeat(task, true)
	CloseSequenceTask(task)
	TaskPerformSequence(busDriver, task)

	while GetSequenceProgress(busDriver) == -1 do Wait(0) end
	
	local oldStatus = -1
	local nextStop = 1
	while true do
		local status = (GetSequenceProgress(busDriver)%3) + 1

		if oldStatus ~= status then
			if status == 2 and Config.Routes[route].busStops[nextStop].stop == true then -- Vehicle parking
				Citizen.CreateThread(function()
					
					Wait(Config.WaitTimeAtBusStop*1000 * 1.5)
					local st = (GetSequenceProgress(busDriver)%3) + 1
					if st == 2 then -- Task stucked
						SetVehicleOnGroundProperly(bus)
						local sequence = GetSequenceProgress(busDriver)
						ClearPedTasks(busDriver)
						TaskPerformSequenceFromProgress(busDriver, task, sequence+2, sequence+3)
					end
				end)
			elseif status == 1 then
				nextStop = (nextStop%#Config.Routes[route].busStops) + 1
				TriggerServerEvent("publictransport:updateService", pedNetId, nextStop)
			end
			-- Debug stuff
			-- print(state[status])	
		end
		oldStatus = status
		Wait(1000)
	end
	
end)

AddEventHandler("playerSpawned", function(spawnInfo)
	TriggerServerEvent("publictransport:onPlayerSpawn")
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