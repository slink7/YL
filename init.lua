local YL = {}
local config = require("yl.config")

for m in modules do
	YL[m] = require("yl."..m)
end

return YL