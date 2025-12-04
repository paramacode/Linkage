--!strict
local resolver = require(script.Parent.resolver)

local allocate = require(script.Parent.Parent.allocate)

local types = require(script.Parent.Parent.Parent.types)

local function buildSchemaSerializer(definition: {[string]: any})
    local fieldOrder = {} :: {string}
    local fieldSerializers: {[string]: types.normalizedSerializer} = {}

    for key, _ in pairs(definition) do
        table.insert(fieldOrder, key)
    end
    table.sort(fieldOrder)

    for _, key in fieldOrder do
        local resolved = resolver.resolveNormalizedSerializer(definition[key])
        if not resolved then
            error(`Invalid type for field '{key}'`)
        end

        fieldSerializers[key] = resolved
    end

    local function encodePacket(payload: {[string]: any}): buffer
        allocate.cursor = 0
        allocate.expand(0, true)

        for _, key in fieldOrder do
            fieldSerializers[key].encode(payload[key])
        end

        local size = allocate.cursor
        local outBuffer = buffer.create(size)

        if size > 0 then
            buffer.copy(outBuffer, 0, allocate.currentBuffer, 0, size)
        end

        return outBuffer
    end

    local function decodePacket(currentBuffer: buffer): {[string]: any}
        local result = {}
        local cursor = 0

        for _, key in fieldOrder do
            local value
            value, cursor = fieldSerializers[key].decode(currentBuffer, cursor)
            result[key] = value
        end

        return result
    end

    return {encode = encodePacket, decode = decodePacket}
end

return buildSchemaSerializer
