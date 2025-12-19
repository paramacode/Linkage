--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local types = require(script.Parent.Parent.types)

local buildSerializer = require(script.builder)

local schema = {
	schemas = {} :: {[string]: {[string]: types.schemaPacket}},
	listeners = {} :: {[string]: {(decoded: any, player: Player?) -> ()}},
}

local function verifyArray(object)
	if type(object) ~= 'table' then return false end
	
	local count = 0
	for _ in object do
		count += 1
		if object[count] == nil then
			return false
		end
	end
	return count > 0
end

local function extractReliableConfig(definition: any): boolean
	if type(definition) == 'table' then
		if type(definition.reliable) == 'boolean' then
			return definition.reliable
		elseif type(definition.transport) == 'table' and type(definition.transport.reliable) == 'boolean' then
			return definition.transport.reliable
		end
	end
	return true 
end

local function normalizeFieldSpec(definition: any): any
	if type(definition) == 'string' then
		return definition
	end

	if type(definition) ~= 'table' then
		return definition
	end

	local normalizedSpec

	if definition.type and type(definition.type) == 'string' then
		local typeName = definition.type

		if typeName == 'array' then
			if definition.schema == nil then
				error('array type requires schema element type')
			end

			local elementType = verifyArray(definition.schema) and definition.schema[1] or definition.schema
			normalizedSpec = {normalizeFieldSpec(elementType)}
		elseif typeName == 'map' then
			if definition.schema == nil then
				error('map type requires schema')
			end

			if verifyArray(definition.schema) then
				normalizedSpec = {
					normalizeFieldSpec(definition.schema[1]),
					normalizeFieldSpec(definition.schema[2])
				}
			elseif type(definition.schema) == 'table' then
				local normalized = {}
				for key, value in definition.schema do
					normalized[key] = normalizeFieldSpec(value)
				end
				normalizedSpec = normalized
			else
				normalizedSpec = {'string', normalizeFieldSpec(definition.schema)}
			end
		else
			normalizedSpec = typeName
		end
	elseif definition.fields then
		local normalizedFields = {}
		for key, value in definition.fields do
			normalizedFields[key] = normalizeFieldSpec(value)
		end
		normalizedSpec = normalizedFields
	else
		local normalized = {}
		for key, value in definition do
			normalized[key] = normalizeFieldSpec(value)
		end
		normalizedSpec = normalized
	end

	if type(definition.modifiers) == 'table' and definition.modifiers.optional then
		return {__OPTIONAL__ = true, spec = normalizedSpec}
	end

	return normalizedSpec
end

local function normalizeFields(fields: {[string]: any}): {[string]: any}
	local normalized = {}
	for key, value in fields do
		if type(value) == 'table' and value.fields then
			local fieldSpec = {}
			for fieldKey, fieldValue in value.fields do
				fieldSpec[fieldKey] = normalizeFieldSpec(fieldValue)
			end
			normalized[key] = fieldSpec
		else
			normalized[key] = normalizeFieldSpec(value)
		end
	end
	return normalized
end

local function verifySinglePacket(definitions: {[string]: any}): boolean
	for identifier, definition in definitions do
		if identifier == 'reliable' or identifier == 'transport' then 
			continue 
		end
		
		local definitionType = type(definition)
		if definitionType == 'string' then
			continue
		elseif definitionType == 'table' then
			if definition.fields then
				continue
			end
			return false
		else
			return false
		end
	end
	return true
end

function schema.registerSchema(registerName: string, definitions: {[string]: any})
	local group = {} :: {[string]: types.schemaPacket}
	local defaultReliable = extractReliableConfig(definitions)
	
	if type(definitions) == 'table' and definitions.fields then
		local fieldsSpec = normalizeFields(definitions.fields)
		local object = buildSerializer(fieldsSpec)
		
		group[registerName] = {
			encode = object.encode,
			decode = object.decode,
			reliable = defaultReliable,
		}
		schema.schemas[registerName] = group
		return group
	end
	
	if verifySinglePacket(definitions) then
		local fieldsSpec = {}
		
		for identifier, definition in definitions do
			if identifier == 'reliable' or identifier == 'transport' then
				continue
			end
			fieldsSpec[identifier] = normalizeFieldSpec(definition)
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
		if identifier == 'reliable' or identifier == 'transport' then
			continue
		end
		
		local fieldsSpec: {[string]: any}
		local entryReliable = defaultReliable

		local definitionType = type(definition)
		if definitionType == 'string' then
			fieldsSpec = {[identifier] = definition}
		elseif definitionType == 'table' then
			if definition.fields then
				fieldsSpec = normalizeFields(definition.fields)
				entryReliable = extractReliableConfig(definition)
			elseif definition.type then
				fieldsSpec = {[identifier] = normalizeFieldSpec(definition)}
				entryReliable = extractReliableConfig(definition)
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
			reliable = entryReliable,
		}
	end
	
	schema.schemas[registerName] = group
	return group
end

function schema.requestSchema(identifier: string, registerName: string?): types.schemaPacket?
	if registerName then
		local group = schema.schemas[registerName]
		return group and group[identifier]
	end
	
	for _, group in schema.schemas do
		local packet = group[identifier]
		if packet then 
			return packet 
		end
	end
	
	return nil
end

local function sendData(schemaPacket: {[string]: types.schemaPacket}, identifier: string, data: any, targetPlayer: Player?)
	local packet = schemaPacket[identifier]
	if not packet then return end
	
	local currentBuffer = packet.encode(data)

	local remoteName = packet.reliable and 'LinkageReliable' or 'LinkageUnreliable'
	local remote = ReplicatedStorage:FindFirstChild(remoteName)
	if not remote then return end
	
	if packet.reliable then
		if not remote:IsA('RemoteEvent') then
			warn(`Expected RemoteEvent but found {remote.ClassName} for reliable transmission`)
			return
		end
		
		local remoteEvent = remote :: RemoteEvent
		if targetPlayer then
			remoteEvent:FireClient(targetPlayer, identifier, currentBuffer)
		elseif RunService:IsClient() then
			remoteEvent:FireServer(identifier, currentBuffer)
		end
	else
		if not remote:IsA('UnreliableRemoteEvent') then
			warn(`Expected UnreliableRemoteEvent but found {remote.ClassName} for unreliable transmission`)
			return
		end
		
		local unreliableRemoteEvent = remote :: UnreliableRemoteEvent
		if targetPlayer then
			unreliableRemoteEvent:FireClient(targetPlayer, identifier, currentBuffer)
		elseif RunService:IsClient() then
			unreliableRemoteEvent:FireServer(identifier, currentBuffer)
		end
	end
end

function schema.sendClient(player: Player, schemaPacket: {[string]: types.schemaPacket}, identifier: string, data: any)
	if RunService:IsServer() then
		sendData(schemaPacket, identifier, data, player)
	end
end

function schema.sendServer(schemaPacket: {[string]: types.schemaPacket}, identifier: string, data: any)
	if RunService:IsClient() then
		sendData(schemaPacket, identifier, data)
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