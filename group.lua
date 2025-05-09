local grp = {}

local files = require("/lib/YL/files")

grp.GROUP_DIR = "/groups/"
grp.SUCCESS = "Done"

local function isOwner(group, user)
	return group.owner == user
end

local function isAdmin(group, user)
	for _, admin in pairs(group.admin) do
		if admin == user then return true end
	end
	return false
end

local function isMember(group, user)
	for _, member in pairs(group.member) do
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
	user = user or initiator
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return -1, "Group doesn't exist" end
	return getLevel(group, user)
end

function grp.create(initiator, group)
	local group_path = grp.GROUP_DIR..group
	if fs.exists(group_path) then return false, "Group already exists" end
	local towrite = {
		owner = initiator,
		admin = {},
		member = {}
	}
	files.writeTable(group_path, towrite)
	return true, grp.SUCCESS
end

function grp.delete(initiator, group)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	if group.owner ~= initiator then return false, "Not allowed" end
	fs.delete(group_path)
	return true, grp.SUCCESS
end

function grp.add(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(group.member, user)
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.remove(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	if isAdmin(group, user) then
		for i, admin in ipairs(group.admin) do
			if admin == user then
				table.remove(group.admin, i)
				break
			end
		end
	elseif isMember(group, user) then
		for i, member in ipairs(group.member) do
			if member == user then
				table.remove(group.member, i)
				break
			end
		end
	else
		return false, "User is not part of the group"
	end
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.promote(initiator, group, user)
	local group_path = grp.GROUP_DIR..group
	local group = files.readTable(group_path)
	if not group then return false, "Group doesn't exist" end
	local level = getLevel(group, initiator)
	if level <= 1 then return false, "Not allowed" end
	table.insert(group.admin, user)
	group.member[user] = nil
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
	table.insert(group.member, user)
	group.admin[user] = nil
	files.writeTable(group_path, group)
	return true, grp.SUCCESS
end

function grp.list(initiator, group)
	if not group then
		local groups = fs.list(grp.GROUP_DIR)
		return true, textutils.serialize(groups)
	end
	
	local group_path = grp.GROUP_DIR..group
	local group_data = files.readTable(group_path)
	if not group_data then return false, "Group doesn't exist" end

	local members = {
		owner = group_data.owner,
		admins = group_data.admin,
		members = group_data.member
	}
	return true, textutils.serialize(members)
end

return grp