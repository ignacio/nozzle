# nozzle

Nozzle is a Lua library that allows to write _filters_ and chain them together into _pipelines_. When data passes through the pipeline, each filter can inspect, modify or reject it.

What does that mean?

Say you're writing a web application, and you have three different functions to add, update or remove a user to your application.

```lua
function add_user (data)
	-- do your thing here
end

function update_user (data)
	-- lookup the user and update
end

function delete_user (data)
	-- delete the user
end
````

You expect that the data needed for each function is _POSTed_ as a _json_, so on each function you have to decode the incoming data. Since the data can be invalid, you have to test for that and act accordingly. 

```lua
function add_user (raw_data)
	local ok, data = pcall(json.decode, raw_data)
	if not ok then
		-- return a status code or something
		return
	end
	-- do your thing here
end
````

Do you add that code to every function? What if you also need to validate that the posted data has a certain structure? Each function would start to grow a lot of boilerplate code _before_ you can do the actual work (ie. add a new user).

What __nozzle__ provides is a way to build those validations as separate functions and later compose them as you see fit. If the data does not pass a given stage in validations, subsequent stages won't be executed.

```lua
local function add_user (data)
	-- just deal with adding the user. data has been already validated.
end

new_add_user_function = do_some_logging .. assert_json .. assert_structure .. add_user
````

You are not restricted to just do validations. Each stage can validate, transform, do some logging, whatever. You can mix and match other libraries and plug them together, like building a pipeline consisting of a couple of validations using [valua](https://github.com/sailorproject/valua/) and then a structure validation using [Tamale](https://github.com/perusio/tamale).

More detailed information can be found [in the manual](https://github.com/ignacio/nozzle/blob/master/docs/manual.md).


# Installing

Install it with [LuaRocks](https://luarocks.org):

    luarocks install nozzle

# Author

Ignacio Burgueño - [@iburgueno](https://twitter.com/iburgueno) - https://uy.linkedin.com/in/ignacioburgueno

# License

MIT/X11
