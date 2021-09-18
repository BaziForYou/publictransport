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
	ESX.TriggerServerCallback("esx_publictransports:playerConnecting", function(busIds)
		print("RECIVING BUS IDS")
		for i=1, #busIds do
			TriggerEvent("esx_publictransports:createBusBlip", busIds[i], 4)
		end
	end)
end)

--[[ 
TODO:
	DONE
 - Missing all the part about blips for each client that means share the bus entity with serevr to send to everyone the right entity for creating the rght blip
 - Only spawn the bu if player near or in some rare random cases
 - Blips if client connect (WHY??? this resource starts and esx_publictransports:getBusEntity doesnt work?)
 - Entity owner set to -1 when client disconnect. Is this a problem??
]]

-- fix test

Citizen.CreateThread(function()
	while true do
		Wait(0)
		local veh = GetVehiclePedIsTryingToEnter(PlayerPedId())
		if not IsVehicleSeatFree(veh, GetSeatPedIsTryingToEnter(PlayerPedId())) then
			for i=1, GetVehicleModelNumberOfSeats(GetEntityModel(veh))-1 do
				if IsVehicleSeatFree(veh, i) then
					TaskEnterVehicle(PlayerPedId(), veh, 1.0, i, 2.0)
					break
				end
			end	
		end
	end
end)


RegisterCommand("drop", function()
	--[[local ped = NetworkGetEntityFromNetworkId(state.pedId)
	ClearPedTasksImmediately(ped)
	Wait(5000)
	TriggerEvent("esx_publictransports:setUpClient", state)]]
--[[	RequestModel("Coach")
	while not HasModelLoaded("Coach") do Wait(1) end
	local vehicle = CreateVehicle(GetHashKey("Coach"), GetEntityCoords(PlayerPedId()), 0.0, true, true)
	local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("ig_bankman"), -1, true, true)
	SetPedRelationshipGroupHash(ped, "PLAYER")
]]
end)

-- The client has been choosed
RegisterNetEvent("esx_publictransports:setUpClient")
AddEventHandler("esx_publictransports:setUpClient", function(state)
	print("Client recived orders")
	ManageService(Config.Routes, state)
end)

--[[
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.TriggerServerCallback("esx_publictransports:getBusEntity", function(vehicles)
		for i, id in ipairs(vehicles) do
			TriggerEvent("esx_publictransports:createBusBlip", id, Config.Routes[i].info.color)
		end
	end)
end)
]]
RegisterNetEvent("esx_publictransports:createBusBlip")
AddEventHandler("esx_publictransports:createBusBlip", function(vehicle, color)
	local busBlip = AddBlipForEntity(NetworkGetEntityFromNetworkId(vehicle))
	SetBlipSprite (1, 463)
	SetBlipColour (busBlip, color)
	SetBlipScale(busBlip, 0.5)
	SetBlipAsShortRange(busBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName('Bus ' .. color)
	EndTextCommandSetBlipName(busBlip)
	--print("Done setting blip for " .. vehicle)
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

		SetPedHearingRange(ped, 0.0)
		SetPedSeeingRange(ped, 0.0)
		SetPedAlertness(ped, 0.0)
		SetPedFleeAttributes(ped, 0, 0)
		SetBlockingOfNonTemporaryEvents(ped, true)
		TaskSetBlockingOfNonTemporaryEvents(ped, true)
		SetEntityCanBeDamaged(ped, false)
		SetPedCanBeTargetted(ped, false)
		SetEntityAsMissionEntity(ped, true,true)
		SetDriverAbility(ped, 1.0)
		SetPedRelationshipGroupHash(ped, GetHashKey("PLAYER"))
		SetEntityAsMissionEntity(vehicle, true,true)
		
		-- START ROUTE
		Citizen.CreateThread(function()
			local isDriving = false
			while true do
				Wait(0)
				if not isDriving then
					TaskVehicleDriveToCoordLongrange(ped, vehicle, route[i][routeState.nextStop], 16.0, 524603, 5.0) -- 443 -> respect traffic lights; 319\
					isDriving = true				
				elseif Vdist(GetEntityCoords(vehicle), route[i][routeState.nextStop]) <= 8.0 then					
					isDriving = false
					if routeState.nextStop == #route[i] then routeState.nextStop = 1 else routeState.nextStop = routeState.nextStop + 1 end
					TriggerServerEvent("esx_publictransports:updateNextStop", routeState.busId, routeState.nextStop)
					Wait(8000)
				else
					Wait(500)
				end
			end
		end)
		
	end
end