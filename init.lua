local YL = {}
local config = require("lib.yl.config")

for key, mod in ipairs(config.modules) do
	YL[mod] = require("lib.yl."..mod)
end

return YL