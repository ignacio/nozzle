---
-- helper functions
--
local function tail (head, ...)
	return ...
end

local function compose (f, g)
	return function(...)
		return f(g(...))
	end
end

local function split (head, ...)
	return head, {...}
end

local function is_callable (v)
	return type(v) == 'function' or getmetatable(v) and getmetatable(v).__call
end


---
-- tostring metamethod, allows printing the filter name if available
--
local function tostring_filter (filter)
	if filter.name then
		return "Filter '" .. tostring(filter.name) .. "'"
	else
		return "Unnamed filter"
	end
end

---
-- Pipeline's metatable
local Pipeline_mt = {}

function Pipeline_mt.new ()
	return setmetatable({}, Pipeline_mt)
end

function Pipeline_mt:clone ()
	local new = self.new()
	for _, v in ipairs(self) do
		new[#new + 1] = v
	end
	return new
end

function Pipeline_mt:append (v)
	local new = self:clone()
	new[#new + 1] = v
	return new
end

function Pipeline_mt:prepend (v)
	local new = self:clone()
	table.insert(new, 1, v)
	return new
end

function Pipeline_mt:union (pipeline)
	local new = self:clone()
	for _, v in ipairs(pipeline) do
		new[#new + 1] = v
	end
	return new
end

Pipeline_mt.__tostring = function(self)
	local msg = {}
	for _, f in ipairs(self) do
		msg[#msg + 1] = tostring(f)
	end
	return "Pipeline: [" .. table.concat(msg, ", ") .. "]"
end

return {
	tail = tail,
	compose = compose,
	tostring_filter = tostring_filter,
	split = split,
	is_callable = is_callable,
	Pipeline_mt = Pipeline_mt
}
