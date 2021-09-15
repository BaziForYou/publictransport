ESX = nil
vehicleList = {}
clientState = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

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

--[[
TODO:
	DONE
 - Missing all the part about blips for each client that means share the bus entity with serevr to send to everyone the right entity for creating the rght blip
 - Only spawn the bu if player near or in some rare random cases
- Blips if client connect (WHY??? this resource starts and esx_publictransports:getBusEntity doesnt work?)
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
	ManageService(Config.Routes[1], state)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.TriggerServerCallback("esx_publictransports:getBusEntity", function(vehicle)
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

--Manage player disconnection
AddEventHandler('playerDropped', function (reason)
	TriggerServerEvent("esx_publictransports:clientQuit", clientState)
end)

function ActiveService(route)
	local startPos = route.start.pos
	local heading = route.start.heading

	ESX.Game.SpawnVehicle(Config.BusHash, startPos, heading, function(vehicle)
		-- Vehicle
		while vehicle == nil do
			Wait(1)
		end
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
		local ped = CreatePed(0, hash, startPos.x, startPos.y, startPos.z, 0.0, true, true)
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
		SetDriverAbility(ped, 0.5)

		--TO REMOVE
		--SetPedIntoVehicle(GetPlayerPed(-1), vehicle, -2)

		state.busId = NetworkGetNetworkIdFromEntity(vehicle)
		state.pedId = NetworkGetNetworkIdFromEntity(ped)
		state.seats = {}

		--Fast stuff IS THIS NEEDED????
		Citizen.CreateThread(function()
			while true do 
				state.coords = GetEntityCoords(vehicle)
				state.heading = GetEntityHeading(vehicle)
				Wait(500)
			end
		end)
		--Slow stuff
		Citizen.CreateThread(function()
			while true do 
				if GetVehicleNumberOfPassengers(vehicle) ~= 0 then
					state.seats = {}
					for i=0, GetVehicleModelNumberOfSeats(Config.BusHash), 1 do
						if IsPedAPlayer(GetPedInVehicleSeat(vehicle, i)) then
							table.insert(state.seats, {seatId = i, playerId = NetworkGetNetworkIdFromEntity(GetPedInVehicleSeat(vehicle, i))})
						end
					end
				end
				state.nextStop = i
				Wait(4000)
			end
		end)

		-- START ROUTE
		local i = 2
		local isDriving = false
		while true do
			Wait(0)

			if not isDriving then
				TaskVehicleDriveToCoordLongrange(ped, vehicle, route[i], 15.0, 319, 1.0) -- 443 -> respect traffic lights;
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

function RestoreService(route, state)
	local vehicle = NetworkGetEntityFromNetworkId(state.busId)
	local ped = NetworkGetEntityFromNetworkId(state.pedId)
	SetPedIntoVehicle(ped, vehicle, -1)
	-- DOES THEY KEEP ALL THE PROPERTIES SETTED FROM OTHER CLIENTS?? NEED TO TEST WITH 2 CLIENTS

	-- Restore players in bus state.seats[1].playerId
	local i = 2
	local isDriving = false
	while true do
		Wait(0)

		if not isDriving then
			TaskVehicleDriveToCoordLongrange(ped, vehicle, route[i], 15.0, 319, 1.0) -- 443 -> respect traffic lights;
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
end

function ManageService(route, state)
	local vehicle = NetworkGetEntityFromNetworkId(state.busId)
	local ped = NetworkGetEntityFromNetworkId(state.pedId)
	clientState = state
	if state.seats ~= nil then
		-- restore player seats
		print("Need to restore players seats")
	end

	local nextStop = 2
	local isDriving = false

	--TO REMOVE
	--SetPedIntoVehicle(GetPlayerPed(-1), vehicle, -2)

	Citizen.CreateThread(function()
		while true do 
			if GetVehicleNumberOfPassengers(vehicle) ~= 0 then
				state.seats = {}
				for i=0, GetVehicleModelNumberOfSeats(Config.BusHash), 1 do
					if IsPedAPlayer(GetPedInVehicleSeat(vehicle, i)) then
						table.insert(state.seats, {seatId = i, playerId = NetworkGetNetworkIdFromEntity(GetPedInVehicleSeat(vehicle, i))})
					end
				end
			end
			state.nextStop = nextStop
			Wait(4000)
		end
	end)
	print("Is first time? ")
	print(state.firstTime)
	if state.firstTime then
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


		state.firstTime = false

		-- START ROUTE
		while true do
			Wait(0)
			if not isDriving then
				TaskVehicleDriveToCoordLongrange(ped, vehicle, route[nextStop], 15.0, 319, 1.0) -- 443 -> respect traffic lights;
				isDriving = true
			end

			if Vdist(GetEntityCoords(vehicle), route[nextStop]) <= 8.0 then
				isDriving = false
				Wait(8000)
				if nextStop == #route then nextStop = 1 else nextStop = nextStop + 1 end
			else
				Wait(500)
			end
		end

		
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
