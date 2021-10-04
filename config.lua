Config = {}
Config.WaitTimeAtBusStop = 10 -- In seconds

Config.Routes = {
	{ -- First spawn point - Vechileshop - Central Garage
		info = { 
			color = 84, 
			hash = "bus",
			busNum = 4, -- >= 1
			timeBetweenBus = 40, -- In second 
		},
		{ pos = vector3(234.9626, -829.2527, 29.98755), heading = 68.031, stop = true },
		--{ pos = vector3(-239.7231, -1146.936, 22.62415), heading = 272.125, stop = false }, -- IF UNCOMMENTED THE GAME WILL CRASH
		{ pos = vector3(-232.1934, -983.7758, 28.60583), heading = 158.740, stop = true },
		{ pos = vector3(-68.75604, -1078.668, 26.97144), heading = 340.15, stop = true },
		{ pos = vector3(176.8747, -1030.365, 29.3136), heading = 0.0, stop = false }, -- stop = false, bus won't stop but will force it to pass this point
		{ pos = vector3(270.3956, -848.2022, 29.33044), heading = 70.866142272949, stop = false },
	},
	--Example of new route use /busstop to get a bus stop ready to be pasted here 
	-- {
	-- 	info = { color = 1, hash = "coach", busNum = 3, timeBetweenBus = 180 }, -- 3, 180
	--  { pos = vector3(194.4528, -789.2308, 31.21753), heading = 342.99212646484, stop = true },
	-- 	{ pos = vector3(2504.439, 5096.044, 44.1582), heading = 65.196853637695, stop = true },
	-- 	{ pos = vector3(2190.475, 4886.809, 41.66443), heading = 218.2677154541, stop = false },
	-- 	{ pos = vector3(2180.782, 4762.628, 40.73767), heading = 164.4094543457, stop = false },
	-- 	{ pos = vector3(309.244, -780.7121, 28.69006), heading = 161.57479858398, stop = false },
	-- },
}