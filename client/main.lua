ESX = nil
vehicleList = {}
clientState = {}
 
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	for _, route in ipairs(Config.Routes) do
		for i, pos in ipairs(route) do
			local blip = AddBlipForCoord(pos)

			SetBlipSprite (blip, 513)
			SetBlipColour (blip, route.info.color)
			SetBlipScale(blip, 0.5)
			SetBlipAsShortRange(blip, true)
		
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName("Bus stop")
			EndTextCommandSetBlipName(blip)
		end
	end
end)

--[[
TODO:
	DONE
 - Missing all the part about blips for each client that means share the bus entity with serevr to send to everyone the right entity for creating the rght blip
 - Only spawn the bu if player near or in some rare random cases
 - Blips if client connect (WHY??? this resource starts and esx_publictransports:getBusEntity doesnt work?)
 - Entity owner set to -1 when client disconnect. Is this a problem??
]]



RegisterCommand("drop", function()
	--[[local ped = NetworkGetEntityFromNetworkId(state.pedId)
	ClearPedTasksImmediately(ped)
	Wait(5000)
	TriggerEvent("esx_publictransports:setUpClient", state)]]
	TriggerServerEvent("esx_publictransports:clientQuit", clientState)
end)

-- The client has been choosed
RegisterNetEvent("esx_publictransports:setUpClient")
AddEventHandler("esx_publictransports:setUpClient", function(state)
	print("Client recived orders")
	ManageService(Config.Routes, state)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.TriggerServerCallback("esx_publictransports:getBusEntity", function(vehicle)
		TriggerEvent("esx_publictransports:createBusBlip", vehicle)
	end)
end)

RegisterNetEvent("esx_publictransports:createBusBlip")
AddEventHandler("esx_publictransports:createBusBlip", function(vehicle)
	print(GetEntityCoords(NetworkGetEntityFromNetworkId(vehicle)))
	local busBlip = AddBlipForEntity(NetworkGetEntityFromNetworkId(vehicle))
	SetBlipSprite (1, 463)
	SetBlipColour (busBlip, 38)
	SetBlipScale(busBlip, 0.5)
	SetBlipAsShortRange(busBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName('Bus')
	EndTextCommandSetBlipName(busBlip)
end)

--Manage player disconnection
AddEventHandler('playerDropped', function (reason)
	TriggerServerEvent("esx_publictransports:clientQuit", clientState)
end)

function ManageService(route, state)
	clientState = state
	for i, routeState in ipairs(state) do
		local vehicle = NetworkGetEntityFromNetworkId(routeState.busId)
		local ped = NetworkGetEntityFromNetworkId(routeState.pedId)
		--Maybe its useless need to test online
		if routeState.seats ~= nil then
			-- restore player seats
			print("Need to restore players seats")
		end

		local isDriving = false

		--TO REMOVE
		--SetPedIntoVehicle(GetPlayerPed(-1), vehicle, -2)

		--MAYBE USELESS
		--[[
		Citizen.CreateThread(function()
			while true do 
				if GetVehicleNumberOfPassengers(vehicle) ~= 0 then
					routeState.seats = {}
					for i=0, GetVehicleModelNumberOfSeats(Config.BusHash), 1 do
						if IsPedAPlayer(GetPedInVehicleSeat(vehicle, i)) then
							table.insert(routeState.seats, {seatId = i, playerId = NetworkGetNetworkIdFromEntity(GetPedInVehicleSeat(vehicle, i))})
						end
					end
				end
				Wait(4000)
			end
		end)
		]]

		if routeState.firstTime then
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

			SetNetworkIdAlwaysExistsForPlayer(routeState.busId, PlayerId(), true)

			routeState.firstTime = false
		end
		-- START ROUTE
		Citizen.CreateThread(function()
			while true do
				Wait(0)
				if not isDriving then
					TaskVehicleDriveToCoordLongrange(ped, vehicle, route[i][routeState.nextStop], 15.0, 524603, 3.0) -- 443 -> respect traffic lights; 319\
					isDriving = true
				end

				if Vdist(GetEntityCoords(vehicle), route[i][routeState.nextStop]) <= 8.0 then
					Wait(8000)
					isDriving = false
					if routeState.nextStop == #route[i] then routeState.nextStop = 1 else routeState.nextStop = routeState.nextStop + 1 end
				else
					Wait(500)
				end
			end
		end)

	end
end


















--[[
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
	ActiveService(Config.Routes.Route436)
end)

function ActiveService(route)
	local startPos = route.start.pos
	local heading = route.start.heading

	ESX.Game.SpawnLocalVehicle("RentalBus", startPos, heading, function(vehicle)
		-- Vehicle
		while vehicle == nil do
			Wait(1)
		end
		print("Vehicle done")
		table.insert(vehicleList, vehicle)
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
		local ped = CreatePed(0, hash, startPos.x, startPos.y, startPos.z, 0.0, false, true)
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
				TaskVehicleDriveToCoord(ped, vehicle, route[i], 20.0, 319, 1.0) -- 443 -> respect traffic lights;
				--TaskVehicleDriveToCoordLongrange
				--SetPedKeepTask(ped, true)
				isDriving = true
			end

			
			if Vdist(GetEntityCoords(vehicle), route[i]) <= 8.0 then
				isDriving = false
				Wait(8000)
				if i == #route then i = 1 else i = i + 1 end
			else
				Wait(250)
			end
		end
	end)
end

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	for _, vehicle in ipairs(vehicleList) do
		DeleteEntity(vehicle)
	end
end)
]]
