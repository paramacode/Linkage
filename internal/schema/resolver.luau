--!strict
local serialization = script.Parent.Parent.Parent.serialization

local types = require(script.Parent.Parent.Parent.types)

local binaryWriter, binaryReader

do
    local binaryDirectory = serialization:FindFirstChild('binary')
    if binaryDirectory then
        local write = binaryDirectory:FindFirstChild('writer')
        local read = binaryDirectory:FindFirstChild('reader')
        if write then
            binaryWriter = require(write :: ModuleScript)
        end
        if read then
            binaryReader = require(read :: ModuleScript)
        end
    end
end

local serializerTypeCache: {[string]: {[string]: any}} = {}
local compositeSerializerCache: {[string]: types.normalizedSerializer} = {}

local function normalizeRawSerializer(raw: types.rawSerializer): types.normalizedSerializer
    return {
        encode = function(value: any)
            return (raw.serialize :: any)(value)
        end,

        decode = function(currentBuffer: buffer, cursor: number)
            return (raw.deserialize :: any)(currentBuffer, cursor)
        end,
    }
end

local function resolveRawSerializer(spec: any): types.rawSerializer
    local dispatch: {[string]: () -> any} = {
        ['string'] = function()
            local cached = serializerTypeCache[spec]
            if cached and cached.__RAW__ then
                return cached.__RAW__
            end

            local import = serialization:FindFirstChild(spec)
            if not import then
                error(`Serialization type '{spec}' not found`)
            end

            local raw = require(import :: ModuleScript) :: types.rawSerializer
            serializerTypeCache[spec] = {__RAW__ = raw}
            return raw
        end,

        ['table'] = function()
            return spec
        end,
    }

    if dispatch[type(spec)] then
        return dispatch[type(spec)]()
    end

    error(`Unsupported raw typeSpec: {spec}`)
end

local function resolveNormalizedSerializer(spec: any): types.normalizedSerializer?
    if type(spec) == 'table' and spec.__OPTIONAL__ then
        if not binaryWriter or not binaryReader then
            error("binary writer/reader required to support 'optional' modifier")
        end

        local inner = resolveNormalizedSerializer(spec.spec)
        if not inner then
            error('Invalid inner spec for optional field')
        end

        return {
            encode = function(value: any)
                if value == nil then
                    binaryWriter['u8'](0)
                    return
                end
                binaryWriter['u8'](1)
                inner.encode(value)
            end,

            decode = function(currentBuffer: buffer, cursor: number)
                local present, newCursor = binaryReader['u8'](currentBuffer, cursor)
                if present == 0 then
                    return nil, newCursor
                end
                return inner.decode(currentBuffer, newCursor)
            end,
        } :: types.normalizedSerializer
    end

    local dispatch: {[string]: () -> any} = {
        ['string'] = function()
            local cached = serializerTypeCache[spec]
            if cached and cached.__NORM__ then
                return cached.__NORM__
            end

            local raw = resolveRawSerializer(spec)
            local resolved = normalizeRawSerializer(raw)

            serializerTypeCache[spec].__NORM__ = resolved

            return resolved
        end,

        ['table'] = function()
            local cacheKey = tostring(spec)
            local cached = compositeSerializerCache[cacheKey]
            if cached then return cached end

            if #spec == 1 then
                local import = serialization:FindFirstChild('array')
                if not import then
                    error("Serialization type 'array' missing")
                end

                local raw = require(import)(resolveRawSerializer(spec[1])) :: types.rawSerializer
                local resolved = normalizeRawSerializer(raw)

                compositeSerializerCache[cacheKey] = resolved

                return resolved
            elseif #spec == 2 then
                local import = serialization:FindFirstChild('dictionary')
                if not import then
                    error("Serialization type 'dictionary' missing")
                end

                local raw = require(import)(resolveRawSerializer(spec[1]), resolveRawSerializer(spec[2])) :: types.rawSerializer
                local resolved = normalizeRawSerializer(raw)

                compositeSerializerCache[cacheKey] = resolved

                return resolved
            end

            local fieldOrder = {} :: {string}
            local nestedFieldSerializers: {[string]: types.normalizedSerializer} = {}

            for key, _ in spec do
                if key == 'reliable' then continue end
                table.insert(fieldOrder, key)
            end
            table.sort(fieldOrder)

            for _, key in fieldOrder do
                local nested = resolveNormalizedSerializer(spec[key])
                if not nested then
                    error(`Invalid nested type for field '{key}'`)
                end
                nestedFieldSerializers[key] = nested
            end

            local function encodeNested(value: any)
                for _, key in fieldOrder do
                    nestedFieldSerializers[key].encode(value[key])
                end
            end

            local function decodeNested(currentBuffer: buffer, cursor: number): (any, number)
                local result = {}
                local currentCursor = cursor

                for _, key in fieldOrder do
                    local currentValue
                    currentValue, currentCursor = nestedFieldSerializers[key].decode(currentBuffer, currentCursor)
                    result[key] = currentValue
                end

                return result, currentCursor
            end

            local nestedSerializer = {encode = encodeNested, decode = decodeNested} :: types.normalizedSerializer
            compositeSerializerCache[cacheKey] = nestedSerializer

            return nestedSerializer
        end,
    }

    if dispatch[type(spec)] then
        return dispatch[type(spec)]()
    end

    warn(`Unsupported typeSpec: {spec}`)

    return nil
end

return {
    resolveRawSerializer = resolveRawSerializer,
    resolveNormalizedSerializer = resolveNormalizedSerializer,
}
