currentClient = nil
serviceStarted = false
entitiesList = {}
blips = {}
-- players[i]: true -> player online but created no ped; {1, 3, 5} -> player online and created a ped
players = {}

RegisterCommand("busstop", function(source, args)
	local ped = GetPlayerPed(source)
	print("{ pos = " .. GetEntityCoords(ped) .. ", heading = " .. GetEntityHeading(ped) .. ", stop = true },")
end)

  

Citizen.CreateThread(function()
	-- TODO: remove --> uncommnet next line and set as your id in the server
	-- if you want to test by restarting the resource
<<<<<<< Updated upstream
	players[1] = true
=======
	players[3] = true
	players[5] = true
	players[7] = true
	players[8] = true
	SetPlayerCullingRadius(3, 999999999.0)
	SetPlayerCullingRadius(6, 999999999.0)
	SetPlayerCullingRadius(7, 999999999.0)
	SetPlayerCullingRadius(8, 999999999.0)
	--players[{1, 2, 3}] = true
	print(json.encode(players))
>>>>>>> Stashed changes
	while true do
		if GetPlayerNum() == 0 then
			-- Waiting for first spawn
			Wait(30000)
		elseif serviceStarted == false then
			print("Starting service")
			serviceStarted = true
			StartService()
		else
			-- Everything is working. Waiting.
			Wait(10000)
		end
		Wait(0)
	end
end)

RegisterNetEvent("playerJoining")
AddEventHandler("playerJoining", function(oldId)
	local src = source
	while GetPlayerPed(src) == 0 do Wait(0) end

	-- TODO: Find better solution to wait the player to be spawned
	Wait(10000)
	while IsEntityVisible(GetPlayerPed(src)) == false do
		Wait(10000)
	end
	
	players[src] = true

	-- TODO: find a better solution
	if serviceStarted == false then
		SetPlayerCullingRadius(src, 999999999.0)
	end
end)

AddEventHandler('playerDropped', function (reason)
	local src = source
	print("Dropped " .. src)
	if players[src] ~= nil and players[src] ~= false then
		print("Player " .. src .. " had " .. #players[src] .. " peds")
	end

	local busInfo = players[src]
	players[src] = nil
	if GetPlayerNum() == 0 then --GetNumPlayerIndices()
		print("No clients connected. Cleaning up.")
		CleanUp()
	else
		-- restore the service of the dropped player
		local player = GetFirstFreePlayer()
		if player ~= nil then
			SetPlayerCullingRadius(player, 999999999.0)
			for k,v in pairs(busInfo) do
				TriggerClientEvent("publictransport:restoreService", player, v)
			end
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	CleanUp()
	-- TODO: Reset SetPlayerCullingRadius ??
end)

RegisterNetEvent("publictransport:updateService")
AddEventHandler("publictransport:updateService", function(pedId, nextStop, timer)
	local src = source
	if players[src] == nil then print("ERROR TABLE EMPTY") end

	local currentRouteNumebr
	local currentBusNumber

	for k,v in pairs(players[src]) do
		if v.pedId == pedId then
			currentRouteNumebr = v.routeNumebr
			currentBusNumber = v.busNumebr
			v.nextStop = nextStop
		end
	end

	-- TODO: Pass an array already ready to be read for the client -> create it all server side
	TriggerClientEvent("publictransport:updateTimers", -1, currentRouteNumebr, nextStop, timer)
end)

function CleanUp()
	for _, entity in ipairs(entitiesList) do
		if DoesEntityExist(entity) then
			DeleteEntity(entity)
		end
	end
	currentClient = nil
	serviceStarted = false
	entitiesList = {}
	blipsInfo = {}
	players = {}
end

function StartService()
	for i, route in ipairs(Config.Routes) do
		Citizen.CreateThread(function()
			local numOfBus = 0
			while numOfBus < route.info.busNum do
				local position = route[1].pos
				local heading = route[1].heading
				local blipColor = route.info.color
				local hash = route.info.hash
				
				local vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, true)
				local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("s_m_m_gentransport"), -1, true, false)

				while not DoesEntityExist(vehicle) or not DoesEntityExist(ped) do
					Wait(100)
				end

				local pedOwner = NetworkGetEntityOwner(ped)
				
				if players[pedOwner] == nil then
					print("ERROR PLAYER NIL")
				end
				if players[pedOwner] == true then
					players[pedOwner] = {}
				end
				table.insert(players[pedOwner], {pedNetId = NetworkGetNetworkIdFromEntity(ped), routeNumebr = i, busNumebr = numOfBus, nextStop = -1})
				print(json.encode(players[pedOwner]))
				-- Solve the problem of out of scope management of entities
				SetEntityDistanceCullingRadius(vehicle, 999999999.0)
				SetEntityDistanceCullingRadius(ped, 999999999.0)
				-- Added to table for cleanUp()
				table.insert(entitiesList, ped)
				table.insert(entitiesList, vehicle)
				print(json.encode(entitiesList))

				local clientInfoPed = {
					routeNumber = i,
					routeBusNumber = numOfBus,
					pedNetId = NetworkGetNetworkIdFromEntity(ped),
					nextStop = 2
				}
				
				TriggerClientEvent("publictransport:setUpClient", pedOwner, clientInfoPed)

				local blipsInfo = {busNetId = NetworkGetNetworkIdFromEntity(vehicle), color = blipColor}
				TriggerClientEvent("publictransport:registerBusBlip", -1, blipsInfo)
				table.insert(blips, blipsInfo)

				numOfBus = numOfBus + 1
				if route.info.busNum > 1 then
					Wait(route.info.timeBetweenBus*1000)
				end
			end
		end)
	end
end

function GetPlayerNum()
	local cont = 0
	for k,v in pairs(players) do
		cont = cont + 1
	end
	return cont
end

function GetFirstFreePlayer()
	for k, v in pairs(players) do
		if v == true then
			return k
		end
	end
	return nil
end



