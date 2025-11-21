--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local serialization = script.Parent.Parent.serialization

local types = require(script.Parent.Parent.types)

local allocate = require(script.Parent.allocate)

local schema = {
	schemas = {} :: {[string]: {[string]: types.schemaPacket}},
	listeners = {} :: {[string]: {(decoded: any, player: Player?) -> ()}},
}

local typeCache: {[string]: {[string]: any}} = {}
local compositeCache: {[string]: types.normalizedSerializer} = {}

local function normalize(raw: types.rawSerializer): types.normalizedSerializer
	return {
		encode = raw.serialize,
		decode = raw.deserialize,
	}
end

local function resolveRawType(typeSpec: any): types.rawSerializer
	local dispatch: {[string]: () -> any} = {
		['string'] = function()
			local cached = typeCache[typeSpec]
			if cached and cached.__RAW__ then
				return cached.__RAW__
			end

			local import = serialization:FindFirstChild(typeSpec)
			if not import then
				error(`Serialization type '{typeSpec}' not found`)
			end

			local raw = require(import :: ModuleScript) :: types.rawSerializer
			typeCache[typeSpec] = { __RAW__ = raw }
			return raw
		end,

		['table'] = function()
			return typeSpec
		end,
	}

	if dispatch[type(typeSpec)] then
		return dispatch[type(typeSpec)]()
	end

	error(`Unsupported raw typeSpec: {typeSpec}`)
end

local function resolveType(typeSpec: any): types.normalizedSerializer?
	local dispatch: {[string]: () -> any} = {
		['string'] = function()
			local cached = typeCache[typeSpec]
			if cached and cached.__NORM__ then
				return cached.__NORM__
			end

			local raw = resolveRawType(typeSpec)
			local resolved = normalize(raw)

			typeCache[typeSpec].__NORM__ = resolved

			return resolved
		end,

		['table'] = function()
			local cacheKey = tostring(typeSpec)
			local cached = compositeCache[cacheKey]
			if cached then return cached end

			if #typeSpec == 1 then
				local import = serialization:FindFirstChild('array')
				if not import then error("Serialization type 'array' missing") end

				local raw = require(import)(resolveRawType(typeSpec[1])) :: types.rawSerializer
				local resolved = normalize(raw)

				compositeCache[cacheKey] = resolved

				return resolved
			elseif #typeSpec == 2 then
				local import = serialization:FindFirstChild('dictionary')
				if not import then error("Serialization type 'dictionary' missing") end

				local raw = require(import)(resolveRawType(typeSpec[1]), resolveRawType(typeSpec[2])) :: types.rawSerializer
				local resolved = normalize(raw) 

				compositeCache[cacheKey] = resolved

				return resolved
			end	

			return typeSpec
		end,
	}

	if dispatch[type(typeSpec)] then
		return dispatch[type(typeSpec)]()
	end

	warn(`Unsupported typeSpec: {typeSpec}`)

	return nil
end

local function new(definition: {[string]: any})
	local ordered = {} :: {string}
	local resolvedTypes: {[string]: types.normalizedSerializer} = {}

	for key, _ in pairs(definition) do
		table.insert(ordered, key)
	end
	table.sort(ordered)

	for _, key in ordered do
		local resolved = resolveType(definition[key])
		if not resolved then error(`Invalid type for field '{key}'`) end
		resolvedTypes[key] = resolved
	end

	local function encode(data: {[string]: any}): buffer
		allocate.cursor = 0
		allocate.expand(0, true)

		for _, key in ordered do
			resolvedTypes[key].encode(data[key])
		end

		local size = allocate.cursor
		local currentBuffer = buffer.create(size)

		if size > 0 then
			buffer.copy(currentBuffer, 0, allocate.currentBuffer, 0, size)
		end

		return currentBuffer
	end

	local function decode(currentBuffer: buffer): {[string]: any}
		local result = {}
		local cursor = 0

		for _, key in ordered do
			local value
			value, cursor = resolvedTypes[key].decode(currentBuffer, cursor)
			result[key] = value
		end

		return result
	end

	return {encode = encode, decode = decode}
end

function schema.registerSchema(registerName: string, definitions: {[string]: any})
	local group = {} :: {[string]: types.schemaPacket}

	for identifier, definition in definitions do
		local object = new(definition.fields)
		group[identifier] = {
			encode = object.encode,
			decode = object.decode,
			reliable = definition.reliable,
		}
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
