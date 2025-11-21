--!strict
local RunService = game:GetService('RunService')

local serialization = script.serialization
local internal = script.internal
local context = script.context

local schema = require(internal.schema)

local server = require(context.server)
local client = require(context.client)

local serializationTypes = {}

for _, import in serialization:GetChildren() do
	if not import:IsA('ModuleScript') then continue end

	local success, result = pcall(function()
		return require(import :: ModuleScript) :: {[string]: any}
	end)
	if success then
		serializationTypes[import.Name] = result
	else
		warn(`Error at loading serialization data type '{import.Name}': {result}`)
	end
end

if RunService:IsServer() then
    server.initiate()    
else
    client.initiate()
end

return table.freeze({
	client = client,
	server = server,

	schema = schema,
	registerSchema = schema.registerSchema,

	serialization = serializationTypes,
})
