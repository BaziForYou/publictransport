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
	SetDriverAbility(busDriver, 0.8)
	SetBlockingOfNonTemporaryEvents(busDriver, true)
	SetPedConfigFlag(busDriver, 251, true)
	SetPedConfigFlag(busDriver, 64, true)
	SetPedStayInVehicleWhenJacked(busDriver, true)
	SetPedCanBeDraggedOut(busDriver, false)
	
	local task = OpenSequenceTask()
	for k, v in pairs(Config.Routes[route].busStops) do
		TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 50.0, 1076369724, 40.0) -- speed 20.0
		
		if v.stop == true then
			TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 9.0, 60, 6.0)
			TaskPause(0, Config.WaitTimeAtBusStop*1000)
		elseif v.stop == false then
			TaskVehicleDriveToCoordLongrange(0, bus, v.pos, 50.0, 1076369724, 15.0)
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
			-- Debug print
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

function Create3D(coords, scale, text)
	local x, y, z = table.unpack(coords)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

	local fov = (1/GetGameplayCamFov())*100
	if onScreen then
		SetTextScale(0.0*scale, 0.25*scale)
		SetTextFont(0)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 255)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextEdge(2, 0, 0, 0, 150)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		SetTextCentre(5)
		AddTextComponentString(text)
		DrawText(_x,_y)
	end
end