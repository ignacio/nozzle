local discount = require "discount"

local input_file = select(1, ...) or "manual.md"
local output_file = select(2, ...) or "manual.html"


local f = io.open(input_file, "rb")
local code = f:read("*a")
f:close()

local html = ([[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head>
<meta http-equiv="Content-type" content="text/xhtml; charset=UTF-8" />
<link type="text/css" href="manual.css" rel="stylesheet"/>
<title>Nozzle</title>
</head>
<body>
%s
</body>
</html>
]]):format(discount(code))

f = io.open(output_file, "wb")
f:write(html)
f:close()