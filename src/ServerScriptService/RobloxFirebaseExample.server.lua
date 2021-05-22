local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

--> Storing your credentials in a DataStore is a sure fire way to secure them
--> The client has absolutely no access to the DSS and thus cannot retrieve this information
--> Your Data-Handling should all happen within ServerScriptService too for further security.
local DATABASE_CREDENTIALS = DataStoreService:GetDataStore("DATABASE_CREDENTIALS")
local DB_URL, DB_AUTH = DATABASE_CREDENTIALS:GetAsync("URL"), DATABASE_CREDENTIALS:GetAsync("AUTH")

local RobloxFirebase = require(ServerScriptService["Roblox-Firebase"])(DB_URL, DB_AUTH)
--> local RobloxFirebase = require(5618676786)(DB_URL, DB_AUTH) --> Is an alternative method of requiring the module.

local Database = RobloxFirebase:GetFirebase("") --> Empty name allows access to the full scope of the database unless otherwise specified in DB_URL
--> It is recommended that your DB_URL is the start point of the database so that you can do this.
local PlayerDataFirebase = RobloxFirebase:GetFirebase("PlayerData")

local PlayerData = {
	["Level"] = 1,
	["Gold"] = 100,	
	["Stats"] = {
		["Speech"] = 10,
		["Mining"] = 1
	}
} --> !!YOUR KEYS _MUST_ BE STRINGS!!

game.Players.PlayerAdded:Connect(function(player)
	local key = tostring(player.UserId).."_Data"
	local foundData = PlayerDataFirebase:GetAsync(key) --> Checks "PlayerData"/"PlayerId_Data" for any data
	if foundData == nil then
		PlayerDataFirebase:SetAsync(key, PlayerData) --> Simple initialisation for their data within the Firebase
		foundData = PlayerDataFirebase:GetAsync(key)
	end

	for key, value in pairs(foundData) do
		print(key, value)
	end

	coroutine.wrap(function()
		while wait(60*1) do --> Increment Player Gold by 25 every 5 minutes
			PlayerDataFirebase:IncrementAsync(key.."/Gold", 25)
		end
	end)()
end)

game.Players.PlayerRemoving:Connect(function(player)
	local key = tostring(player.UserId).."_Data"
	local foundData = PlayerDataFirebase:GetAsync(key) --> This would ideally come from wherever you are storing their data, 
	--> preferably in a Cache and not as stats within their Player instance, but it is your choice.
	
	foundData.Gold += 200
	foundData.Stats.Mining += 2
	print("Updating...")
	PlayerDataFirebase:UpdateAsync(key, function(oldData) --> Literally UpdateAsync() is exactly the same as the DataStoreService
		--> The key difference would be the third optional paramater of 'snapshot' which can be used to prevent Roblox-Firebase from perfoming
		--> A GetAsync() operation for your 'oldData' and will instead use whatever is supplied.
		--> Note: If providing a Snapshot in this method, it must match whatever would be acquired from :GetAsync(key), in this case: "PlayerData/PlayerId_Data"
		for newKey, newValue in pairs(foundData) do
			oldData[newKey] = newValue
		end
		return oldData
	end) --> You can drop the optional snapshot paramater if not needed/used.
	print("Updated.")
end)

--[[
	BatchUpdateAsync Example:

	Lets take our previous set of data and modify it slightly:

	local PlayerData = {
		["Level"] = 4,
		["Gold"] = 12345,
		["Stats"] = {
			["Speech"] = 15,
			["Mining"] = 25
		}
	}


	Now lets set some callback methods:

	local Callbacks = {
		Level = function(oldData)
		end,

		Gold = function(oldData)
		end,

		Stats = function(oldData)
		end,
	}

	You COULD update each key individually writing each callback method, or...
	you could call BatchUpdateAsync("PlayerData", PlayerData, Callbacks)

	The callback function is exactly the same as one you would write for either:
		Firebase:UpdateAsync()
	or
		DataStore:UpdateAsync()
]]