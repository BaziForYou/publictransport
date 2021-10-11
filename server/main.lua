local serviceStarted = false
players = {}
entities = {}
blips = {}

RegisterCommand("busstop", function(source, args)
	local ped = GetPlayerPed(source)
	print("{ pos = " .. GetEntityCoords(ped) .. ", stop = true },")
end)
RegisterCommand("heading", function(source, args)
	local ped = GetPlayerPed(source)
	print(GetEntityHeading(ped))
end)

Citizen.CreateThread(function()
	while true do
		while GetPlayerNum() == 0 do
			Wait(2000)
		end
		if serviceStarted == false then 
			for route = 1, #Config.Routes do
				Citizen.CreateThread(function()
					local busNum = 1
					local curr = Config.Routes[route]
					while busNum <= curr.info.busNum do
						local curr = curr
						local position = curr.busStops[1].pos
						local heading = curr.info.startHeading
						local blipColor = curr.info.color
						local hash = curr.info.hash

						-- creating vehicle 
						local vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, true)
						
						Wait(100)
						while not DoesEntityExist(vehicle) do
							local pos = GetEntityCoords(vehicle)
							local errorPos = vector3(math.ceil(pos.x), math.ceil(pos.y), math.ceil(pos.z))
							if errorPos == vector3(0, 0, 1) then
								vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, true)
							end
							Wait(300)
						end	
						SetEntityDistanceCullingRadius(vehicle, 999999999.0)
						
						-- creating ped 
						local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("s_m_m_gentransport"), -1, true, false)
						Wait(100)
						while not DoesEntityExist(ped) do
							local pos = GetEntityCoords(ped)
							local errorPos = vector3(math.ceil(pos.x), math.ceil(pos.y), math.ceil(pos.z))
							if errorPos == vector3(0, 0, 1) then
								ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("s_m_m_gentransport"), -1, true, false)
							end
							Wait(300)
						end
						SetEntityDistanceCullingRadius(ped, 999999999.0)
						table.insert(entities, vehicle)
						table.insert(entities, ped)
						
						local pedOwner = NetworkGetEntityOwner(ped)
						local pedNetId = NetworkGetNetworkIdFromEntity(ped)
						local busNetId = NetworkGetNetworkIdFromEntity(vehicle)

						-- Added for first time entering server (need to test)
						while players[pedOwner] == nil do Wait(1) end
						
						table.insert(players[pedOwner], {pedNetId = pedNetId, routeNumber = route, busNumber = busNum, nextStop = 2})

						table.insert(blips, {busNetId = busNetId, color = blipColor})

						TriggerClientEvent("publictransport:startBus", pedOwner, pedNetId, route)
						TriggerClientEvent("publictransport:registerBusBlip", -1, busNetId, blipColor)

						busNum = busNum + 1
						if curr.info.busNum > 1 then
							Wait(curr.info.timeBetweenBus*1000)
						end
					end
				end)
			end
			serviceStarted = true
		end
		Wait(1000)
	end
end)

RegisterNetEvent("publictransport:updateService")
AddEventHandler("publictransport:updateService", function(pedId, nextStop)
	local src = source
	if players[src] == nil then print("ERROR TABLE EMPTY") end

	local currentRouteNumebr
	local currentBusNumber

	for k,v in pairs(players[src]) do
		if v.pedNetId == pedId then
			currentRouteNumebr = v.routeNumber
			currentBusNumber = v.busNumber
			v.nextStop = nextStop
			break
		end
	end
end)

RegisterNetEvent("publictransport:onPlayerSpawn")
AddEventHandler("publictransport:onPlayerSpawn", function()
	local src = source
	while not IsEntityVisible(GetPlayerPed(src)) do Wait(1) end
	print("Player " .. src .. " is visible")
	if players[src] == nil then
		players[src] = {}
		if #entities > 0 then
			TriggerClientEvent("publictransport:registerBlips", src, blips)
		end
	end
end)

AddEventHandler('playerDropped', function (reason)
	local src = source
	if players[src] ~= nil and players[src] ~= false then
		print("Player " .. src .. " had " .. #players[src] .. " peds")
	end
	
	players[src] = nil
	if GetPlayerNum() == 0 then
		print("No clients connected. Cleaning up.")
		CleanUp()
	else
		-- TODO: restore the service of the dropped player
	end
end)

-- Added so you can restart the resource for test
AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	for i=1, 1000 do
		if GetPlayerPed(i) ~= 0 then
			players[i] = {}
			SetPlayerCullingRadius(i, 999999999.0)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	CleanUp()
end)

-- ===========================
-- 			FUNCTIONS
-- ===========================

function CleanUp()
	for _, entity in ipairs(entities) do
		if DoesEntityExist(entity) then
			DeleteEntity(entity)
		end
	end
	for k,v in pairs(players) do
		SetPlayerCullingRadius(k, 0.0)
	end
	players = {}
	entities = {}
	blips = {}
	serviceStarted = false
end

function GetPlayerNum()
	local cont = 0
	if players == nil then
		print("players nil")
		return 0
	end
	for k,v in pairs(players) do
		if v ~= nil then
			cont = cont + 1
		end
	end
	return cont
end