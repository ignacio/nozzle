local orbit = require "orbit"
local json = require "cjson"

-- luacheck: no unused args

---
-- Create a new Orbit application
--
local app = orbit.new({})

local Filter = require "nozzle.generic"


local JsonValidator = Filter{
	name = "JsonValidator",
	input = function(self, web, ...)
		local postData = web.input["post_data"]
		local res, request = pcall(json.decode, postData)
		if not res or not request then
			web.status = 400
			return Filter.stop, "Invalid json input"
		end
		return web, request, ...
	end
}

local FieldValidator = Filter{
	name = "FieldValidator",
	input = function(self, web, request, ...)
		if not request.id then
			web.status = 400
			return Filter.stop, "Requests must have an 'id' field"
		end
		return web, request, ...
	end
}



local function hello (web)
	return "success"
end

local function receive_json (web, request)
	return "Replied request with id = " .. request.id
end


app:dispatch_get(hello, "/")

app:dispatch_post( JsonValidator .. FieldValidator .. receive_json, "/test_json")

return app
