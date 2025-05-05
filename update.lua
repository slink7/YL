local function downloadFile(config, file)
	local response = http.get(config.repo..file)
	local dest = config.basePath .. file
	if response then
		local content = response.readAll()
		response.close()
		local file = fs.open(dest, "w")
		file.write(content)
		file.close()
		print("Updated: " .. dest)
	else
		print("Failed to download: " .. dest)
	end
end

local config = require("yl.config") or {
	repo = "https://raw.githubusercontent.com/slink7/YL/master/",
	basePath = "/lib/YL/",
}

downloadFile(config, "config.lua")

config = require("yl.config")

for _, mod in ipairs(config.modules) do
	downloadFile(config, mod .. ".lua")
end

downloadFile(config, "init.lua")
downloadFile(config, "update.lua")

print("YL library updated to version: " .. config.version)
