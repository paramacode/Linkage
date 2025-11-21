--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)

local types = require(script.Parent.Parent.types)

local function dictionary<K, V>(keyType: types.dataTypes<K>,valueType: types.dataTypes<V>): types.dataTypes<{[K]: V}>
	return {
		serialize = function(getDictionary: {[K]: V})
			writer['dictionary'](getDictionary, keyType.serialize, valueType.serialize)
		end,

		deserialize = function(currentBuffer: buffer, cursor: number): ({[K]: V}, number)
			local length = buffer.readu16(currentBuffer, cursor)
			cursor += 2

			local result: {[K]: V} = {}
			for _ = 1, length do
				local key, value
				key, cursor = keyType.deserialize(currentBuffer, cursor)
				value, cursor = valueType.deserialize(currentBuffer, cursor)
				result[key] = value
			end

			return result, cursor
		end,
	}
end

return dictionary
