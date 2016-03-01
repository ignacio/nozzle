package.path = [[../src/?.lua;]]..package.path

local mock = require "wsapi.mock"
local lunit = require "lunit"

local nozzle = require "nozzle"
local generic = require "nozzle.generic"
local json = require "cjson"

-- luacheck: module

_G.webHandler = {
	CollectTraceback = debug.traceback,
	LogError = function(...) io.stderr:write(...); io.stderr:write("\n") end
}


if _VERSION >= "Lua 5.2" then
	_ENV = lunit.module("simple","seeall")
else
	module(..., package.seeall, lunit.testcase)
end


---
-- Tests using an actual Orbit application in the backend.
-- This application uses normal filters.
--
if _VERSION == "Lua 5.1" then

function test_orbit_application()
	local test_app = require "test_app"
	local app = mock.make_handler(test_app.run)

	local response, request = app:get("/", {hello = "world"})
	assert_equal("200 Ok", response.code)
	assert_equal("GET", request.request_method)
	assert_equal("hello=world", request.query_string)
	assert_equal("text/html", response.headers["Content-Type"])
	assert_equal("success", response.body)


	-- '/test_json' needs a valid json to be posted
	-- First we check that an invalid json is rejected
	local response, request = app:post("/test_json", "hello, how are you?", { ["Content-Type"] = "application/json"})
	--print("Response:", json.encode(response, true))
	assert_equal(400, response.code)

	-- Now we send a proper json. However, we don't send a required field.
	local response, request = app:post("/test_json", json.encode({}), { ["Content-Type"] = "application/json"})
	assert_equal(response.code, 400)
	assert_equal(response.body, "Requests must have an 'id' field")

	-- Now we send a proper json, with the required field.
	local response, request = app:post("/test_json", json.encode({ id = 1234 }), { ["Content-Type"] = "application/json"})
	assert_equal("200 Ok", response.code)
	assert_equal("Replied request with id = 1234", response.body)

	-- Now we send a proper json, with the required field, but we'll use the stock json validator
	local response, request = app:post("/test_json_custom", json.encode({ id = 1234 }), { ["Content-Type"] = "application/json"})
	assert_equal("200 Ok", response.code)
	assert_equal("Replied request with id = 1234", response.body)

	-- Now we send a proper json, without the required field, but we'll use the stock json validator
	local response, request = app:post("/test_json_custom", json.encode({ foo = 1234 }), { ["Content-Type"] = "application/json"})
	--print("Response:", json.encode(response, true))
	assert_equal(400, response.code)
	assert_equal("Requests must have an 'id' field", response.body)

	-- Check the stock json replier
	local response, request = app:get("/test_json_encode")
	assert_equal("200 Ok", response.code)
	assert_equal([[{"some":"value"}]], response.body)

	--print("Response:", json.encode(response, true))
	--print("Issued request:", json.encode(request, true))
end


---
-- Tests using an actual Orbit application in the backend.
-- This application uses generic filters.
--
function test_orbit_application_generics()
	local test_app = require "test_app_generics"
	local app = mock.make_handler(test_app.run)

	local response, request = app:get("/", {hello = "world"})
	assert_equal("200 Ok", response.code)
	assert_equal("GET", request.request_method)
	assert_equal("hello=world", request.query_string)
	assert_equal("text/html", response.headers["Content-Type"])
	assert_equal("success", response.body)


	-- '/test_json' needs a valid json to be posted
	-- First we check that an invalid json is rejected
	local response, request = app:post("/test_json", "how are you", { ["Content-Type"] = "application/json"})
	--print("Response:", json.encode(response, true))
	assert_equal(400, response.code)

	-- Now we send a proper json. However, we don't send a required field.
	local response, request = app:post("/test_json", json.encode({}), { ["Content-Type"] = "application/json"})
	assert_equal(400, response.code)
	assert_equal("Requests must have an 'id' field", response.body)

	-- Now we send a proper json, with the required field.
	local response, request = app:post("/test_json", json.encode({ id = 1234}), { ["Content-Type"] = "application/json"})
	assert_equal("200 Ok", response.code)
	assert_equal("Replied request with id = 1234", response.body)

	--print("Response:", json.encode(response, true))
	--print("Issued request:", json.encode(request, true))
end

end

---
-- Tests the flow of data using a pipeline of filters.
--
function test_normal_pipeline()
	-- no-op pipeline
	local pipeline = nozzle() .. nozzle() .. function() return "hello" end
	assert_equal("hello", pipeline())

	-- no-op filter + a filter that adds " world" to the output
	local pipeline = nozzle() ..
					 nozzle({ output = function(_, env, response) return response .. " world" end }) ..
					 function() return "hello" end
	assert_equal("hello world", pipeline())

	-- a filter that upercases its input + a filter that adds " world" to the output
	local pipeline = nozzle({ input = function(self, env)
						env[1] = env[1]:upper()
					end}) ..
					nozzle{ output = function(_, env, response)
						return response .. " world"
					end } ..
					function(data)
						return data[1]
					end
	assert_equal("HELLO world", pipeline({"hello"}))

	-- calling filter constructor with a function is equivalent to use { input = fn }
	local pipeline = nozzle(function(self, env)
						env[1] = env[1]:upper()
					end) ..
					function(data)
						return data[1]
					end
	assert_equal("HELLO", pipeline({"hello"}))
end

---
-- Tests the flow of data using a pipeline of generic filters.
--
function test_generic_pipeline()
	-- a no-op pipeline
	local pipeline = generic() .. generic() .. function() return "hello" end
	assert_equal("hello", pipeline())

	-- no-op filter + a filter that adds " world" to the output
	local pipeline = generic() ..
					 generic({ output = function(_, response) return response .. " world" end }) ..
					 function() return "hello" end
	assert_equal("hello world", pipeline())

	-- a filter that upercases its input + a filter that adds " world" to the output
	local pipeline = generic({ input = function(self, input)
						return input:upper()
					end}) ..
					generic{ output = function(_, response)
						return response .. " world"
					end } ..
					function(data)
						return data
					end
	assert_equal("HELLO world", pipeline("hello"))

	-- a filter that upercases its input + a filter that adds " world" to the output
	local pipeline = generic({ input = function(self, input)
						if not input then
							return "HELLO"
						end
						return generic.stop, "stopped"
					end}) ..
					generic{ output = function(_, response)
						return response .. " world"
					end } ..
					function(data)
						return data
					end
	assert_equal("HELLO world", pipeline())

	assert_equal("stopped", pipeline("won't work"))

	-- calling filter constructor with a function is equivalent to use { input = fn }
	local pipeline = generic(function(self, data)
						return data:upper()
					end) ..
					function(data)
						return data
					end
	assert_equal("HELLO", pipeline("hello"))
end


---
-- Tests that common and generic filters can be combined (being really, REALLY, careful).
--
function test_combining_filters()
	-- a generic filter that upercases its input + a normal filter that if input is "HELLO" stops the pipeline
	--  + a normal filter that adds " world" to the output
	local pipeline = generic({ input = function(self, input)
						return input:upper()
					end}) ..
					nozzle{ input = function(self, input)
						if input == "HELLO" then
							return "stop"
						end
					end} ..
					nozzle{ output = function(_, response)
						return response .. " world"
					end } ..
					function(data)
						return data
					end
	assert_equal("stop", pipeline("hello"))
	assert_equal("HI! world", pipeline("hi!"))
end

---
-- Checks that filters can be printed
--
function test_filters_tostring()
	local filter1 = nozzle()
	local filter2 = nozzle{name = "my filter"}

	assert_equal( "Unnamed filter", tostring(filter1) )
	assert_equal( "Filter 'my filter'", tostring(filter2) )

	local filter3 = generic()
	local filter4 = generic{name = "my filter"}

	assert_equal( "Unnamed filter", tostring(filter3) )
	assert_equal( "Filter 'my filter'", tostring(filter4) )
end


---
-- Checks that a pipeline can be pretty printed
--
function test_pipeline_tostring()
	local filter1 = nozzle()
	local filter2 = nozzle{ name = "my filter" }

	local pipeline = filter1 .. filter2
	assert_equal("Pipeline: [Unnamed filter, Filter 'my filter']", tostring(pipeline))

	local filter3 = generic()
	local filter4 = generic{ name = "my filter" }

	local pipeline2 = filter3 .. filter4
	assert_equal("Pipeline: [Unnamed filter, Filter 'my filter']", tostring(pipeline2))
end


---
-- Check that building invalid chains gives an error, both when appending or prepending.
--
function test_pipeline_invalid_chain()
	assert_error(function()
		local _ = nozzle() .. {}
	end)

	assert_error(function()
		local _ = generic() .. {}
	end)

	assert_error(function()
		local _ = nozzle() .. 12
	end)

	assert_error(function()
		local _ = {} .. nozzle{ name = "my filter" }
	end)

	assert_error(function()
		local _ = 12 .. generic{ name = "my filter" }
	end)
end


---
-- Calling an unfinished pipeline (a pipeline with no sink) gives an error.
--
function test_call_unfinished_pipeline()
	local pipeline = nozzle() .. nozzle() .. nozzle()
	
	assert_error(function() pipeline() end)

	local pipeline2 = generic() .. generic() .. generic()
	
	assert_error(function() pipeline2() end)
end

---
-- This test makes sure that two or more filters can be chained together, and that chain can
-- subsequently be chained with more chains, filters or sinks.
--
function test_filters_composition()

	local visited = {}

	local input = function(self, env)
		visited[#visited + 1] = self.name
	end

	local f1 = nozzle({ name="f1", input = input})
	local f2 = nozzle({ name="f2", input = input})

	-- f3 is made of f1 and f2 chained together
	local f3 = f1 .. f2
	
	local f4 = nozzle({ name="f4", input = input})

	-- chain everything together
	local pipeline = f4 .. f3 .. function(data)
		return data[1]
	end
	assert_equal("hello", pipeline({"hello"}))

	-- check that the filters were called in order
	assert_equal("f4", visited[1])
	assert_equal("f1", visited[2])
	assert_equal("f2", visited[3])

	-- now create new chains, and in turn chain those together
	visited = {}
	local f5 = nozzle({ name="f5", input = input})

	local f6 = f5 .. f4
	local F = f6 .. f3

	local pipeline = F .. function(data)
		return data[1]
	end

	assert_equal("hello", pipeline({"hello"}))

	-- check that the filters were called in order
	assert_equal("f5", visited[1])
	assert_equal("f4", visited[2])
	assert_equal("f1", visited[3])
	assert_equal("f2", visited[4])
end

---
-- This test makes sure that two or more generic filters can be chained together, and that chain can
-- subsequently be chained with more chains, filters or sinks.
--
function test_generic_filters_composition()

	local visited = {}

	local input = function(self, env)
		visited[#visited + 1] = self.name
		return env
	end
	
	local f1 = generic({ name="f1", input = input})
	local f2 = generic({ name="f2", input = input})

	-- f3 is made of f1 and f2 chained together
	local f3 = f1 .. f2
	
	local f4 = generic({ name="f4", input = input})

	-- chain everything together
	local pipeline = f4 .. f3 .. function(data)
		return data[1]
	end
	assert_equal("hello", pipeline({"hello"}))

	-- check that the filters were called in order
	assert_equal("f4", visited[1])
	assert_equal("f1", visited[2])
	assert_equal("f2", visited[3])

	-- now create new chains, and in turn chain those together
	visited = {}
	local f5 = generic({ name="f5", input = input})

	local f6 = f5 .. f4
	local F = f6 .. f3

	local pipeline = F .. function(data)
		return data[1]
	end

	assert_equal("hello", pipeline({"hello"}))

	-- check that the filters were called in order
	assert_equal("f5", visited[1])
	assert_equal("f4", visited[2])
	assert_equal("f1", visited[3])
	assert_equal("f2", visited[4])
end
