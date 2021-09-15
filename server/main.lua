ESX = nil

isServiceActive = false
vehicleList = {}
state = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("esx_publictransports:serviceStatus", function(playerId, cb)
	cb(isServiceActive)
end)

RegisterCommand("test",function(source, args)
	print("Ped task " .. GetPedSpecificTaskType(NetworkGetEntityFromNetworkId(state.pedId), 0))
end)

RegisterServerEvent("esx_publictransports:clientQuit")
AddEventHandler("esx_publictransports:clientQuit", function(state)

	--[[
	PROBLEM :
		NEED TO CREATE PED AND VEHICLE SERVER SIDE, THEN SEND THEM TO A CLIENT AND MAKE THEM DO STUFF UNITL THEY DISCONNECT THEN SEARCH ANOTHER CLIENT AND REPEAT

		LOOK esx_publictransport/server/main.lua - line: 16
	-------

	while true do
		print("Bus exists?")
		print(DoesEntityExist(NetworkGetEntityFromNetworkId(state.busId)))

		print("Ped exists?")
		print(DoesEntityExist(NetworkGetEntityFromNetworkId(state.pedId)))
		Wait(5000)
		print("\n")
	end
	]]
	print("CLIENT DISCONNECTED") -- NON STAMPA
	local client = findClient()
	TriggerClientEvent("esx_publictransports:setUpClient", client, state)
end)

AddEventHandler("onServerResourceStart", function(resName)
	if resName ~= GetCurrentResourceName() then
		return
	end
	-- Find a client to run the code
	local client = findClient()	
	local vehicle = CreateVehicle(GetHashKey(Config.BusHash), Config.Routes[1].start.pos, Config.Routes[1].start.heading, true, true)
	local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("ig_bankman"), -1, true, true)
	while not DoesEntityExist(ped) or not DoesEntityExist(vehicle) do
		if not DoesEntityExist(ped) then
			ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("ig_bankman"), -1, true, true)
		end
		if not DoesEntityExist(vehicle) then
			vehicle = CreateVehicle(GetHashKey(Config.BusHash), Config.Routes[1].start.pos, Config.Routes[1].start.heading, true, true)
		end
		Wait(500)
	end
	state.pedId = NetworkGetNetworkIdFromEntity(ped)
	state.busId = NetworkGetNetworkIdFromEntity(vehicle)
	state.seats = nil
	state.firstTime = true
	-- Solve the problem of out of scope management of entities
	SetEntityDistanceCullingRadius(vehicle, 999999999.0)
	SetEntityDistanceCullingRadius(ped, 999999999.0) -- onesync_distanceCullVehicles true
	-- DOESNT ALWAYS WORKS NEED TO FIX IT!! (Fix with WAIT. The problem is maybe this event starts too early for triggering a client event?)
	Wait(1000)
	TriggerClientEvent("esx_publictransports:setUpClient", client, state)
	-- Trigger event to everyone for the blips
	TriggerClientEvent("esx_publictransports:createBusBlip", -1, state.busId)
	

	while true do
		Wait(5000)
		print(DoesEntityExist(ped))
		print(DoesEntityExist(vehicle))
		print(GetEntityCoords(vehicle))
		print("owner " .. NetworkGetEntityOwner(vehicle))
		print("---")
	end
end)

ESX.RegisterServerCallback("esx_publictransports:getBusEntity", function(playerId, cb)
	while not DoesEntityExist(NetworkGetEntityFromNetworkId(state.busId)) do
		Wait(500)
	end
	cb(state.busId)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	DeleteEntity(NetworkGetEntityFromNetworkId(state.pedId))
	DeleteEntity(NetworkGetEntityFromNetworkId(state.busId))
end)

function findClient()
	xPlayers = ESX.GetPlayers()

	while #xPlayers == 0 do
		Wait(60000)
		xPlayers = ESX.GetPlayers()
	end

	return xPlayers[1]
end