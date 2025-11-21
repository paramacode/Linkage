--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)

local types = require(script.Parent.Parent.types)

local function array<T>(elementType: types.dataTypes<T>): types.dataTypes<{T}>
	return {
		serialize = function(packedArray: {T})
			writer['array'](packedArray, elementType.serialize)
		end,
		
		deserialize = function(currentBuffer: buffer, cursor: number): ({T}, number)
			local length = buffer.readu16(currentBuffer, cursor)
			cursor += 2

			local result: {T} = {}
			for _ = 1, length do
				local value
				value, cursor = elementType.deserialize(currentBuffer, cursor)
				table.insert(result, value)
			end

			return result, cursor
		end,
	}
end

return array