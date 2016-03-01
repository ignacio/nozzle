package.path = "./src/?.lua;./unittest/?.lua;"..package.path
local lunit = require "lunit"

require "test"


local stats = lunit.main()
if stats.failed > 0 or stats.errors > 0 then
	os.exit(1)
end
