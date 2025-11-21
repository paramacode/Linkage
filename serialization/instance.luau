--!strict
local HttpService = game:GetService('HttpService')

local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local instanceRegistry: {[string]: Instance} = setmetatable({}, {__mode = 'v'})

local function assignIdentifier(obj: Instance): string
    local id = obj:GetAttribute('_sid')
    if id == nil then
        id = HttpService:GenerateGUID(false)
        obj:SetAttribute('_sid', id)
        return id
    end

    local existing = instanceRegistry[id]
    if existing and existing ~= obj then
        id = HttpService:GenerateGUID(false)
        obj:SetAttribute('_sid', id)
    end

    return id
end

local function register(obj: Instance)
    local id = assignIdentifier(obj)
    instanceRegistry[id] = obj
end

local function unregister(obj: Instance)
    local id = obj:GetAttribute('_sid')
    if id then
        instanceRegistry[id] = nil
    end
end

for _, obj in ipairs(game:GetDescendants()) do
    register(obj)
end

game.DescendantAdded:Connect(register)
game.DescendantRemoving:Connect(unregister)

local function deserialize(currentBuffer: buffer, cursor: number): (Instance?, number)
    local id, newCursor = reader['string'](currentBuffer, cursor)
    if id == '' then
        return nil, newCursor
    end

    return instanceRegistry[id], newCursor
end

local module = {
    serialize = writer['instance'],
    deserialize = deserialize,
} :: types.dataTypes<Instance>

return module
