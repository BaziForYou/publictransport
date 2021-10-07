-- TOREMOVE
Citizen.CreateThread(function()
	while true do 
		SetPedDensityMultiplierThisFrame(0.0)
		SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)

		-- Traffic Intensity
		SetRandomVehicleDensityMultiplierThisFrame(0.0)
		SetParkedVehicleDensityMultiplierThisFrame(0.0)
		-- Vehicles on streets 0.0 - 1.0
		SetVehicleDensityMultiplierThisFrame(0.0)
		Wait(1)
	end
end)

local textData = {}

-- for debug
state = {'Driving to bus stop', 'Parking', 'Waiting'}
Citizen.CreateThread(function()
	for _, route in ipairs(Config.Routes) do
		for _, curr in ipairs(route) do
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
	-- Oh cool
	RegisterCommand('test', function()
		local pid = PlayerPedId()
		local pidpos = GetEntityCoords(pid)
		local hashstreet = GetStreetNameAtCoord(pidpos.x, pidpos.y, pidpos.z)
		local stringstreet = GetStreetNameFromHashKey(hashstreet)
		print(stringstreet)
	end)

	for i=1, #Config.Routes do
		textData[i] = {}
	end
	
	-- We can iterate here all the bus stops and check for distances
	Citizen.CreateThread(function()
		while true do
			local player = PlayerPedId()
			local i = 1
			local j = 1
			for _, route in ipairs(Config.Routes) do
				for _, curr in ipairs(route) do
					if Vdist2(GetEntityCoords(player), curr.pos) < 25*25 then
						if curr.stop == true then
							Create3D(curr.pos, 2.0, "Test") --textData[i][j].timer
						end
					end
					j = j + 1
				end
				i = i + 1
			end
			Wait(0)
		end
	end)
end)

RegisterNetEvent("publictransport:setUpClient")
AddEventHandler("publictransport:setUpClient", function(info)
	ManageService(info)
end)

RegisterNetEvent("publictransport:restoreService")
AddEventHandler("publictransport:restoreService", function(info)
	ManageService(info)
end)

function ManageService(info)
	while not NetworkDoesEntityExistWithNetworkId(info.pedNetId) do
		Wait(10)
	end

	local busDriver = NetToPed(info.pedNetId)
	local bus = GetVehiclePedIsIn(busDriver, false)
	while bus == 0 do
		Wait(10)
		bus = GetVehiclePedIsIn(busDriver, false)
	end

	if bus == 0 or not IsVehicleDriveable(bus, false) then
		print("SOMETHING IS WRONG WITH BUS ", info.routeNumber, info.routeBusNumber)
	end

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
	SetPedConfigFlag(busDriver, 64, true) -- CPED_CONFIG_FLAG_AttachedToVehicle 
	SetPedStayInVehicleWhenJacked(busDriver, true)

	local path = {}
	local firstStop = info.nextStop
	for i=firstStop, #Config.Routes[info.routeNumber], 1 do
		local curr = Config.Routes[info.routeNumber][i]
		table.insert(path, {pos = curr.pos, heading = curr.heading, stop = curr.stop})
	end
	for i=(firstStop-1), 1, -1 do
		local curr = Config.Routes[info.routeNumber][i]
		table.insert(path, {pos = curr.pos, heading = curr.heading, stop = curr.stop})
	end

	local task = OpenSequenceTask()
	for i=1, #path do
		TaskVehicleDriveToCoordLongrange(0, bus, path[i].pos, 50.0, 1076369724, 40.0) -- speed 20.0
		
		if path[i].stop == true then
			TaskVehicleDriveToCoordLongrange(0, bus, path[i].pos, 9.0, 60, 6.0)
			TaskPause(0, Config.WaitTimeAtBusStop*1000)
		elseif path[i].stop == false then
			TaskVehicleDriveToCoordLongrange(0, bus, path[i].pos, 50.0, 1076369724, 15.0)
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
			if status == 2 and Config.Routes[info.routeNumber][nextStop].stop == true then -- Vehicle parking
				Citizen.CreateThread(function()
					Wait(Config.WaitTimeAtBusStop*1000 * 1.5)
					local st = (GetSequenceProgress(busDriver)%3) + 1
					if st == 2 then -- Task stucked
						SetVehicleOnGroundProperly(bus)
						--print("GO TO NEXT PROGRESS", "sequence: ", GetSequenceProgress(busDriver))
						local sequence = GetSequenceProgress(busDriver)
						ClearPedTasks(busDriver)
						TaskPerformSequenceFromProgress(busDriver, task, sequence+2, sequence+3)
					end
				end)
			elseif status == 1 then
				local distance = 0.0
				nextStop = (nextStop%#Config.Routes[info.routeNumber]) + 1

				
				if (Config.Routes[info.routeNumber][nextStop].stop == false) then
					local virtualStop = nextStop
					distance = 0
					while Config.Routes[info.routeNumber][virtualStop].stop == false do
						virtualStop = (virtualStop%#Config.Routes[info.routeNumber]) + 1
						local prev = virtualStop - 1
						if prev == 0 then prev = #Config.Routes[info.routeNumber] end
						
						local x, y, z = table.unpack(Config.Routes[info.routeNumber][prev].pos)
						local x1, y1, z1 = table.unpack(Config.Routes[info.routeNumber][virtualStop].pos)
						distance = distance + CalculateTravelDistanceBetweenPoints(x, y, z, x1, y1, z1)
						Wait(0)
					end
				else
					local p = nextStop-1
					if p == 0 then p = #Config.Routes[info.routeNumber] end
					local x, y, z = table.unpack(Config.Routes[info.routeNumber][p].pos)
					local x1, y1, z1 = table.unpack(Config.Routes[info.routeNumber][nextStop].pos)
					distance = CalculateTravelDistanceBetweenPoints(x, y, z, x1, y1, z1)
				end				

				
				local timer = distance/50.0*3.6
				--print("Time to next stop: ", timer)
				
				TriggerServerEvent("publictransport:updateService", info.pedNetId, nextStop, timer)
			end
			-- Debug print
			--print(state[status])	
		end
		oldStatus = status
		Wait(1000)
	end
end

RegisterNetEvent("publictransport:updateTimers")
AddEventHandler("publictransport:updateTimers", function(currentRouteNumebr, nextBusStop, timer)
	-- textData[currentRouteNumebr] = {}
	-- textData[currentRouteNumebr][nextBusStop] = timer
	print(timer)
end)

RegisterNetEvent("publictransport:registerBusBlip")
AddEventHandler("publictransport:registerBusBlip", function(info)
	--print("Ped exist on blip register", DoesEntityExist(NetworkGetEntityFromNetworkId(info.busNetId)))
	local busBlip = AddBlipForEntity(NetworkGetEntityFromNetworkId(info.busNetId))
	SetBlipSprite (1, 463)
	SetBlipColour (busBlip, info.color)
	SetBlipScale(busBlip, 0.5)
	SetBlipAsShortRange(busBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName("Bus " .. info.color)
	EndTextCommandSetBlipName(busBlip)
end)

RegisterNetEvent("publictransport:updateBusBlips")
AddEventHandler("publictransport:updateBusBlips", function(blipsInfo)
	print("Updating " .. #blipsInfo .. " blips")
	for _, curr in pairs(blipsInfo) do
		local busBlip = AddBlipForEntity(NetworkGetEntityFromNetworkId(curr.busNetId))
		SetBlipSprite (1, 463)
		SetBlipColour (busBlip, curr.color)
		SetBlipScale(busBlip, 0.5)
		SetBlipAsShortRange(busBlip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName("Bus " .. curr.color)
		EndTextCommandSetBlipName(busBlip)
	end
end)

-- PED s_m_m_gentransport

-- Add Markers to bus stops, tells you missing time to next bus

-- What if i want to have the scale as a param
Create3D = function(coords, multi, texto)
    local x, y, z = table.unpack(coords)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
	local multip = multi
    if onScreen then
        SetTextScale(0.0*multip, 0.25*multip)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(5)
        AddTextComponentString(texto)
        DrawText(_x,_y)
    end
end