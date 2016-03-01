local orbit = require "orbit"
local json = require "cjson"

-- luacheck: no unused args

---
-- Create a new Orbit application
--
local app = orbit.new({})

local Filter = require "nozzle"


local JsonValidator = Filter{
	name = "JsonValidator",
	input = function(self, web, ...)
		local postData = web.input["post_data"]
		local res, request = pcall(json.decode, postData)
		if not res or not request then
			web.status = 400
			return "Invalid json input"
		end
		web.request = request
	end
}

local CustomJsonValidator = require "nozzle.stock".json_validator(function(web)
	web.status = 400
	return "No, no, no"
end)

local FieldValidator = Filter{
	name = "FieldValidator",
	input = function(self, web, ...)
		if not web.request.id then
			web.status = 400
			return "Requests must have an 'id' field"
		end
	end
}

local JsonReply = require "nozzle.stock".json_reply()


local function hello (web)
	return "success"
end

local function receive_json (web)
	return "Replied request with id = " .. web.request.id
end

local function encode_json (web)
	return { some = "value" }
end


app:dispatch_get(hello, "/")

app:dispatch_post( JsonValidator .. FieldValidator .. receive_json, "/test_json")
app:dispatch_post( CustomJsonValidator .. FieldValidator .. receive_json, "/test_json_custom")

app:dispatch_get( JsonReply .. encode_json, "/test_json_encode" )

return app
