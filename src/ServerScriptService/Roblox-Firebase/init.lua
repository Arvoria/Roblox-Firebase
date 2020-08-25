local HttpService = game:GetService("HttpService")

local RobloxFirebase = { }
RobloxFirebase.DefaultScope = ""
RobloxFirebase.AuthenticationToken = ""
RobloxFirebase.__index = RobloxFirebase
setmetatable(RobloxFirebase, RobloxFirebase)

function RobloxFirebase.__call(self, dbUrl, authToken)
	self.DefaultScope = dbUrl
	self.AuthenticationToken = authToken
end

function RobloxFirebase:GetFirebase(name, scope)
	assert(self.AuthenticationToken~=nil, "AuthenticationToken expected, got nil")
	assert(scope~=nil or self.DefaultScope~=nil, "DefaultScope or Scope expected, got nil")

	scope = scope or self.DefaultScope
	local path = scope .. HttpService:UrlEncode(name)
	local auth = ".json?auth=" .. self.AuthenticationToken

	local Firebase = { }

	function Firebase:GetAsync(key)
		assert(type(key) == "string", "Roblox-Firebase GetAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
		
		local data
		local attempts = 0
		
		key = key:sub(1,1)~="/" and "/"..key or key --> Ensures key is correct form
		local dir = path .. HttpService:UrlEncode(key) .. auth

		repeat until pcall(function() 
				data = HttpService:GetAsync(dir, true)
			end)
		or attempts >= 3

		return HttpService:JSONDecode(data) or nil
	end

	function Firebase:SetAsync(key, value, method)
		assert(type(key) == "string", "Roblox-Firebase SetAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
		
		method = method or "PUT"
		
		key = key:sub(1,1)~="/" and "/"..key or key --> Ensures key is correct form
		local dir = path .. HttpService:UrlEncode(key) .. auth --> Database path to act on

		local responseInfo
		local encoded = HttpService:JSONEncode(value)
		
		local requestOptions = { }
		requestOptions.Url = dir
		requestOptions.Method = method
		requestOptions.Headers = { }
		requestOptions.Headers["Content-Type"] = "application/x-www-form-urlencoded"
		requestOptions.Body = encoded

		local success, err = pcall(function() 
			local response = HttpService:RequestAsync(requestOptions)
			if response == nil or response.Success then
				warn("Roblox-Firebase SetAsync Operation Failure: " .. response.StatusMessage .. " ("..response.StatusCode..")")
				if method == "PATCH" then -- UpdateAsync Request
					print("Retrying Update Request until success...")
					self:SetAsync(key, value, method)
				end
			else
				responseInfo = response
			end
		end)

		return success, responseInfo --> did it work, what was the response
	end

	function Firebase:DeleteAsync(key)
		assert(type(key) == "string", "Roblox-Firebase DeleteAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
		self:SetAsync(key, "", "DELETE")
	end

	function Firebase:IncrementAsync(key, delta)
		assert(type(key) == "string", "Roblox-Firebase IncrementAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
		
		local data = self:GetAsync(key) or 0
		delta = delta or 1

		if type(data) == "number" and type(delta) == "number" then
			data += delta
			self:SetAsync(key, data)
		else
			warn("RobloxFirebase: Data or Delta increment is not a number, cannot update data at key("..key..")")
		end
	end

	function Firebase:UpdateAsync(key, callback, snapshot)
		assert(type(key) == "string", "Roblox-Firebase UpdateAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
		assert(type(callback) == "function", "Roblox-Firebase UpdateAsync: Callback must be a function")
		local data = snapshot or self:GetAsync(key) --> Use the snapshot of data supplied instead or Download the database again

		local updated = callback(data)
		if updated then
			return self:SetAsync(key, updated, "PATCH")
		end
	end

	function Firebase:BatchUpdateAsync(baseKey, keyValues, callbacks, snapshot)
		assert(type(baseKey) == "string", "Roblox-Firebase BatchUpdateAsync: Bad Argument #1, string expected got '"..tostring(type(baseKey)).."'")
		assert(type(keyValues)=="table", "Roblox-Firebase BatchUpdateAsync: Bad Argument #2, table expected got '"..tostring(type(keyValues)).."'")
		assert(type(callbacks)=="table", "Roblox-Firebase BatchUpdateAsync: Bad Argument #3, table expected got '"..tostring(type(callbacks)).."'")

		local updatedKeyValues = { }

		for key, value in pairs(keyValues) do
			-- make sure that the key has a valid and defined callback method
			assert(callbacks[key] ~= nil, "Roblox-Firebase BatchUpdateAsync: Key does not have a callback method, inspect callbacks table")
			assert(type(callbacks[key])=="function", "Roblox-Firebase BatchUpdateAsync: Callback for key ("..key..") is not function, got "..tostring(type(callbacks[key])))

			local data = snapshot[key] or self:GetAsync(key)
			updatedKeyValues[key] = callbacks[key](data)
		end

		if #updatedKeyValues == #keyValues then -- flimsy fail safe
			return self:SetAsync(baseKey, updatedKeyValues, "PATCH")
		end
	end

	return Firebase
end


return RobloxFirebase