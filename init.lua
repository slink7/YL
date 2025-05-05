local YL = {}
YL.config = require("lib.yl.config")

for key, mod in ipairs(YL.config.modules) do
	YL[mod] = require("lib.yl."..mod)
end

return YL