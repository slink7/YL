local files = {}

function files.readTable(path)
	local file = fs.open(path, "r")
	if not file then return nil end
	local content = file.readAll()
	file.close()
	return textutils.unserialize(content)
end

function files.writeTable(path, table)
	local file = fs.open(path, "w")
	if not file then return nil end
	file.write(textutils.serialize(table))
	file.close()
end

return files