--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local internal = script.Parent.Parent.internal

local schema = require(internal.schema)

local client = {}

local function safeDecode(packet: any, currentBuffer: buffer): (boolean, any)
    return pcall(function()
        return packet.decode(currentBuffer)
    end)
end

local function safeEncode(packet: any, data: any): (boolean, any)
    return pcall(function()
        return packet.encode(data)
    end)
end

local function reliable(schemaIdentifier: string, currentBuffer: buffer)
	if type(schemaIdentifier) ~= 'string' then return end

	local packet = schema.requestSchema(schemaIdentifier)
	if not packet then return end

	local success, decoded = safeDecode(packet, currentBuffer)
	if not success then return end

	print(`'{script.Name}': Client received '{schemaIdentifier}' from server`)

	schema.dispatch(schemaIdentifier, decoded)
end

local function unreliable(schemaIdentifier: string, currentBuffer: buffer)
	if type(schemaIdentifier) ~= 'string' then return end
	
	local packet = schema.requestSchema(schemaIdentifier)
	if not packet then return end

	local success, decoded = safeDecode(packet, currentBuffer)
	if not success then return end

	print(`'{script.Name}': Client received '{schemaIdentifier}' from server`)

	schema.dispatch(schemaIdentifier, decoded)
end

function client.initiate()
	local reliableRemote = ReplicatedStorage:WaitForChild('LinkageReliable') :: RemoteEvent
	local unreliableRemote = ReplicatedStorage:WaitForChild('LinkageUnreliable') :: UnreliableRemoteEvent

	reliableRemote.OnClientEvent:Connect(reliable)
	unreliableRemote.OnClientEvent:Connect(unreliable)

	local function onHeartbeat()
		-- TODO
	end

	RunService.Heartbeat:Connect(onHeartbeat)
end

return client