ESX = nil

vehicleList = {}
state = {}
currentClient = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("pos", function(source, args)
	local pos = GetEntityCoords(GetPlayerPed(source))
    --print(pos)
    local x, y, z = pos.x, pos.y, pos.z
    print("{ x = ".. x .. ", y = " .. y .. ", z = " .. z ..", h = " .. GetEntityHeading(GetPlayerPed(source)) .." },")
end)

RegisterCommand("posbegin", function(source, args)
    print("pos = " .. GetEntityCoords(GetPlayerPed(source)) .. ", heading = " .. GetEntityHeading(GetPlayerPed(source)))
end)

RegisterCommand("test",function(source, args)

end)

--[[
AddEventHandler("playerConnecting", function()
	Wait(0)
	for _, data in ipairs(state) do
		TriggerClientEvent("esx_publictransports:createBusBlip", -1, data.busId, 4)
	end
end)
]]
ESX.RegisterServerCallback("esx_publictransports:playerConnecting", function(playerId, cb)
	if currentClient ~= nil then
		local busIds = {}
		for _, data in ipairs(state) do
			table.insert(busIds, data.busId)
		end
		cb(busIds)
	end
end)

AddEventHandler('playerDropped', function (reason)
	if source == currentClient then
		print("CLIENT DISCONNECTED")
		local client = findClient()
		TriggerClientEvent("esx_publictransports:setUpClient", client, state)
	end
end)

AddEventHandler("onServerResourceStart", function(resName)
	if resName ~= GetCurrentResourceName() then
		return
	end

	-- Find a client to run the code
	local client = findClient()

	local numOfBus = 0
	while numOfBus < Config.BusPerRoute do
		for i, route in ipairs(Config.Routes) do
			local position = route.info.pos
			local heading = route.info.heading
			local blipColor = route.info.color
			local hash = route.info.hash

			state[i] = {}

			local vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, true)
			local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("ig_bankman"), -1, true, false)
			Wait(500)
			while DoesEntityExist(vehicle) == false do 
				vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, true)
				Wait(500)
			end
			while DoesEntityExist(ped) == false do 
				ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("ig_bankman"), -1, true, false)
				Wait(500)
			end
			state[i].pedId = NetworkGetNetworkIdFromEntity(ped)
			state[i].busId = NetworkGetNetworkIdFromEntity(vehicle)
			state[i].seats = nil
			state[i].nextStop = 2	
			-- Solve the problem of out of scope management of entities
			SetEntityDistanceCullingRadius(vehicle, 999999999.0)
			SetEntityDistanceCullingRadius(ped, 999999999.0) -- onesync_distanceCullVehicles true
			SetPlayerCullingRadius(currentClient, 999999999.0)
			-- Trigger event to everyone for the blips
			TriggerClientEvent("esx_publictransports:createBusBlip", -1, state[i].busId, blipColor)
		end
		print("Server ready")
		-- DOESNT ALWAYS WORKS NEED TO FIX IT!! (Fix with WAIT)
		Wait(1000)
		TriggerClientEvent("esx_publictransports:setUpClient", client, state)

		numOfBus = numOfBus + 1
		if Config.BusPerRoute > 1 then
			Wait(Config.TimeBetweenBus*1000)
		end
	end
--[[	
	while true do
		Wait(5000)
		print(DoesEntityExist(NetworkGetEntityFromNetworkId(state[1].pedId)))
		print(DoesEntityExist(NetworkGetEntityFromNetworkId(state[1].busId)))
		print("Speed: " .. GetEntitySpeed(NetworkGetEntityFromNetworkId(state[1].busId)))
		print("owner " .. NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(state[1].busId)))
		print("Task state: " .. GetPedScriptTaskCommand(NetworkGetEntityFromNetworkId(state[1].pedId)))
		print("---")
	end
]]
end)

ESX.RegisterServerCallback("esx_publictransports:getBusEntity", function(playerId, cb)
	Ids = {}
	for _, data in ipairs(state) do
		while not DoesEntityExist(NetworkGetEntityFromNetworkId(data.busId)) do
			Wait(500)
		end
		table.insert(Ids, data.busId)
	end

	cb(Ids)
end)

RegisterNetEvent("esx_publictransports:updateNextStop")
AddEventHandler("esx_publictransports:updateNextStop", function(busId, nextStop)
	for _, routeState in ipairs(state) do
		if routeState.busId == busId then
			routeState.nextStop = nextStop
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	for _, routeState in ipairs(state) do
		DeleteEntity(NetworkGetEntityFromNetworkId(routeState.pedId))
		DeleteEntity(NetworkGetEntityFromNetworkId(routeState.busId))
	end
end)

function findClient()
	currentClient = nil
	Wait(2000)
	xPlayers = ESX.GetPlayers()
	print("Number of client connected: " .. #xPlayers)
	while #xPlayers == 0 do 
		print("Waiting for players")
		Wait(60000)
		xPlayers = ESX.GetPlayers()
	end
	currentClient = xPlayers[1]
	return xPlayers[1]
end
