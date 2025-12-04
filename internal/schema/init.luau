--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local types = require(script.Parent.Parent.types)

local schema = {
	schemas = {} :: {[string]: {[string]: types.schemaPacket}},
	listeners = {} :: {[string]: {(decoded: any, player: Player?) -> ()}},
}

local buildSerializer = require(script.builder)

function schema.registerSchema(registerName: string, definitions: {[string]: any})
	local group = {} :: {[string]: types.schemaPacket}

	local defaultReliable = false

	local function looksLikeSinglePacket(defs: {[string]: any})
		for id, def in defs do
			if id == 'reliable' then continue end
			local t = type(def)
			if t == 'string' then
				continue
			elseif t == 'table' then
				if def.fields then
					continue
				end
				return false
			else
				return false
			end
		end
		return true
	end

	local singlePacket = looksLikeSinglePacket(definitions)

	if singlePacket then
		local fieldsSpec = {}
		for id, def in definitions do
			if id == 'reliable' then
				defaultReliable = def
			else
				if type(def) == 'table' and def.fields then
					fieldsSpec[id] = def.fields
				else
					fieldsSpec[id] = def
				end
			end
		end

		local object = buildSerializer(fieldsSpec)
		group[registerName] = {
			encode = object.encode,
			decode = object.decode,
			reliable = defaultReliable,
		}
		schema.schemas[registerName] = group
		return group
	end

	for identifier, definition in definitions do
		if identifier == 'reliable' and type(definition) == 'boolean' then
			defaultReliable = definition
		else
			local definitionType = type(definition)
			local fieldsSpec: {[string]: any}
			local entryReliable: boolean?

			if definitionType == 'string' then
				fieldsSpec = { [identifier] = definition }
			elseif definitionType == 'table' then
				if definition.fields then
					fieldsSpec = definition.fields
					if type(definition.reliable) == 'boolean' then
						entryReliable = definition.reliable
					end
				else
					fieldsSpec = definition
				end
			else
				error(`Invalid schema definition for '{identifier}': expected string or table`) 
			end

			local object = buildSerializer(fieldsSpec)
			group[identifier] = {
				encode = object.encode,
				decode = object.decode,
				reliable = entryReliable or defaultReliable,
			}
		end
	end

	schema.schemas[registerName] = group
	return group
end

function schema.requestSchema(identifier: string, registerName: string?): types.schemaPacket?
	if registerName then
		return schema.schemas[registerName] and schema.schemas[registerName][identifier]
	end

	for _, group in schema.schemas do
		if group[identifier] then 
			return group[identifier] 
		end
	end

	return nil
end

function schema.sendClient(player: Player, schemaPacket: {[string]: types.schemaPacket}, identifier: string, data: any)
	local packet = schemaPacket[identifier]
	if not packet then return end

	if RunService:IsServer() then
		local currentBuffer = packet.encode(data)

		local remote = ReplicatedStorage:FindFirstChild(packet.reliable and 'LinkageReliable' or 'LinkageUnreliable')
		if remote then
			(remote :: RemoteEvent):FireClient(player, identifier, currentBuffer)
		end
	end
end

function schema.sendServer(schemaPacket: {[string]: types.schemaPacket}, identifier: string, data: any)
	local packet = schemaPacket[identifier]
	if not packet then return end

	if RunService:IsClient() then
		local currentBuffer = packet.encode(data)

		local remote = ReplicatedStorage:FindFirstChild(packet.reliable and 'LinkageReliable' or 'LinkageUnreliable')
		if remote then
			(remote :: RemoteEvent):FireServer(identifier, currentBuffer)
		end
	end
end

function schema.listen(identifier: string, callback: (decoded: any, player: Player?) -> ())
	local list = schema.listeners[identifier]
	if not list then
		list = {}
		schema.listeners[identifier] = list
	end
	table.insert(list, callback)
end

function schema.dispatch(identifier: string, decoded: any, player: Player?)
	local list = schema.listeners[identifier]
	if not list then return end

	for _, callback in ipairs(list) do
		task.spawn(callback, decoded, player)
	end
end

return schema
