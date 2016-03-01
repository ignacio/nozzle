local nozzle = require "nozzle"


local function json_validator(callback)
	local json = require "cjson"
	callback = callback or function() end

	return nozzle.filter{
		name = "nozzle.stock.json_validator",
		input = function(_, web)
			local post_data = web.input["post_data"]
			local res, request = pcall(json.decode, post_data)
			if not res or not request then
				local body = callback(web, post_data)
				if body then
					return body
				end
				web.status = 400
				web:content_type("text/plain")
				return "Invalid json input"
			end

			web.request = request
		end
	}
end


local function json_reply()
	local json = require "cjson"
	return nozzle.filter{
		name = "nozzle.stock.json_reply",
		output = function(_, web, output)
			web.headers["Content-Type"] = "application/json"
			if type(output) == "table" then
				return json.encode(output)
			end
			return output
		end
	}
end

-- Returns a table with stock filters
return {
	json_validator = json_validator,
	json_reply = json_reply
}
