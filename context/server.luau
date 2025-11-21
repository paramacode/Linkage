--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local internal = script.Parent.Parent.internal

local schema = require(internal.schema)

local server = {}

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

local function reliable(player: Player, schemaIdentifier: string, currentBuffer: buffer)
    if type(schemaIdentifier) ~= 'string' then return end

    local packet = schema.requestSchema(schemaIdentifier)
    if not packet then
        warn(`'{script.Name}': unknown packet '{schemaIdentifier}' received`)
        return
    end

    local success, decoded = safeDecode(packet, currentBuffer)
    if not success then
        warn(`'{script.Name}': failed to decode '{schemaIdentifier}': {decoded}`)
        return
    end

    print(`'{script.Name}': received (reliable) '{schemaIdentifier}'`)

    schema.dispatch(schemaIdentifier, decoded, player)
end

local function unreliable(player: Player, schemaIdentifier: string, currentBuffer: buffer)
    if type(schemaIdentifier) ~= 'string' then return end

    local packet = schema.requestSchema(schemaIdentifier)
    if not packet then return end

    local success, decoded = safeDecode(packet, currentBuffer)
    if not success then return end

    print(`'{script.Name}': received (unreliable) '{schemaIdentifier}'`)

    schema.dispatch(schemaIdentifier, decoded, player)
end

function server.initiate()
    local reliableRemote = Instance.new('RemoteEvent')
    reliableRemote.Name = 'LinkageReliable'
    reliableRemote.Parent = ReplicatedStorage

    local unreliableRemote = Instance.new('UnreliableRemoteEvent')
    unreliableRemote.Name = 'LinkageUnreliable'
    unreliableRemote.Parent = ReplicatedStorage

    reliableRemote.OnServerEvent:Connect(reliable)
    unreliableRemote.OnServerEvent:Connect(unreliable)

    local function onHeartbeat()
        -- TODO
    end

    RunService.Heartbeat:Connect(onHeartbeat)
end

return server