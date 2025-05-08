local group = {}

local files = require("/lib/YL/files")

group.GROUP_DIR = "/groups/"

local function isOwner(group, user)
	return group.owner == user
end

local function isAdmin(group, user)
	for admin in group.admin do
		if admin == user then return true end
	end
	return false
end

local function isMember(group, user)
	for member in group.member do
		if member == user then return true end
	end
	return false
end

local function getLevel(group, user)
	if isOwner(group, user) then return 3, "owner" end
	if isAdmin(group, user) then return 2, "admin" end
	if isMember(group, user) then return 1, "member" end
	return 0, "extern"
end

function group.getUserLevel(initiator, group, user)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return -1, "Group doesn't exist" end
	return getLevel(group, user)
end

function group.create(initiator, group)
	local group_path = group.GROUP_DIR..group
	if fs.exists(group_path) then return false, "Group already exists" end
	local group = {
		owner = initiator,
		admin = {},
		member = {}
	}
	files.writeTable(group_path, group)
	return true, "Done"
end

function group.delete(initiator, group)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	if group.owner ~= initiator then return false, "Not allowed" end
	fs.delete(group_path)
	return true, "Done"
end

function group.add(initiator, group, user)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(group.member, user)
	files.writeTable(group_path, group)
	return true, "Done"
end

function group.remove(initiator, group, user)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	group.member[user] = nil
	files.writeTable(group_path, group)
	return true, "Done"
end

function group.promote(initiator, group, user)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(group.admin, user)
	group.member[user] = nil
	files.writeTable(group_path, group)
	return true, "Done"
end


function group.demote(initiator, group, user)
	local group_path = group.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	if not isAdmin(group, user) then return false, "Not an admin" end
	table.insert(group.member, user)
	group.admin[user] = nil
	files.writeTable(group_path, group)
	return true, "Done"
end


return group