local grp = {}

local files = require("/lib/YL/files")

grp.GROUP_DIR = "/groups/"
grp.SUCCESS = "Done"

local function isOwner(group, user)
	return grp.owner == user
end

local function isAdmin(group, user)
	for admin in grp.admin do
		if admin == user then return true end
	end
	return false
end

local function isMember(group, user)
	for member in grp.member do
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

function grp.getUserLevel(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return -1, "Group doesn't exist" end
	return getLevel(group, user)
end

function grp.create(initiator, group)
	local group_path = grp.GROUP_DIR..group
	if fs.exists(group_path) then return false, "Group already exists" end
	local group = {
		owner = initiator,
		admin = {},
		member = {}
	}
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.delete(initiator, group)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	if grp.owner ~= initiator then return false, "Not allowed" end
	fs.delete(group_path)
	return true, grp.SUCCESS
end

function grp.add(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(grp.member, user)
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.remove(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	grp.member[user] = nil
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.promote(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(grp.admin, user)
	grp.member[user] = nil
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end


function grp.demote(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	if not isAdmin(group, user) then return false, "Not an admin" end
	table.insert(grp.member, user)
	grp.admin[user] = nil
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end


return group