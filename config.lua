Config = {}
Config.WaitTimeAtBusStop = 10 -- In seconds
Config.DriveStyle = 1076369727--264235 -- old 1076369724 If you want to change this go here https://www.vespura.com/fivem/drivingstyle/

Config.Routes = {
	{ 	-- First spawn point - Vechileshop - Central Garage
		info = { 
			color = 84, 
			hash = "bus",
			busNum = 4, -- number of buses per route (>= 1)
			timeBetweenBus = 40, -- In second,
			startHeading = 68.031
		},
		busStops = {
			{ pos = vector3(234.9626, -829.2527, 29.98755), stop = true },
			{ pos = vector3(-232.1934, -983.7758, 28.60583), stop = true },
			{ pos = vector3(-68.75604, -1078.668, 26.97144), stop = true },
			{ pos = vector3(176.8747, -1030.365, 29.3136), stop = false },
			{ pos = vector3(270.3956, -848.2022, 29.33044), stop = false },
		}
	},
	{
		info = { 
			color = 24, 
			hash = "bus",
			busNum = 1, -- number of buses per route (>= 1)
			timeBetweenBus = 40, -- In second,
			startHeading = 215.433
		},
		busStops = {
			{ pos = vector3(-1167.943, -1471.187, 3.634399), stop = true },
			{ pos = vector3(-1107.257, -1467.336, 4.342163), stop = false },
			{ pos = vector3(-808.1934, -1029.653, 12.48059), stop = true },
			{ pos = vector3(-560.1099, -843.8505, 26.75244), stop = true },
			{ pos = vector3(-248.822, -881.9077, 29.95386), stop = true },
			{ pos = vector3(194.5978, -789.3494, 30.96484), stop = true },
			{ pos = vector3(131.578, -578.3077, 43.07983), stop = false },
			{ pos = vector3(-757.6219, -936.4088, 17.33337), stop = true },
		}
	},
	--Example of new route use /busstop to get a bus stop ready to be pasted here 
	-- {
	-- 	info = { 
	-- 		color = 78, 
	-- 		hash = "coach", 
	-- 		busNum = 2, 
	-- 		timeBetweenBus = 180,
	-- 		startHeading = 342.992
	-- 	},
	-- 	busStops = {
	-- 		{ pos = vector3(194.4528, -789.2308, 31.21753),  stop = true },
	-- 		{ pos = vector3(2504.439, 5096.044, 44.1582), stop = true },
	-- 		{ pos = vector3(2190.475, 4886.809, 41.66443), stop = false },
	-- 		{ pos = vector3(2180.782, 4762.628, 40.73767), stop = false },
	-- 		{ pos = vector3(309.244, -780.7121, 28.69006), stop = false },
	-- 	}
	-- },
}