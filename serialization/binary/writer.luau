--!strict
local internal = script.Parent.Parent.Parent.internal

local allocate = require(internal.allocate)

local function getBufferAndCursor()
	local stream = allocate.getActive()
	return stream.currentBuffer, stream.cursor, stream
end

local write = {}

write['string'] = function(value: string)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	local length = #value

	allocate.expand(length + 2, true)
	buffer.writeu16(currentBuffer, cursor, length)
	cursor += 2

	buffer.writestring(currentBuffer, cursor, value)
	stream.cursor = cursor + length
end

write['boolean'] = function(value: boolean)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(1, true)

	buffer.writeu8(currentBuffer, cursor, if value then 1 else 0)
	stream.cursor = cursor + 1
end

write['cframe16'] = function(value: CFrame)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(16, true)

	local position = value.Position
	local _, angle = value:ToAxisAngle()

	buffer.writef32(currentBuffer, cursor, position.X)
	buffer.writef32(currentBuffer, cursor + 4, position.Y)
	buffer.writef32(currentBuffer, cursor + 8, position.Z)

	buffer.writef32(currentBuffer, cursor + 12, angle)

	stream.cursor = cursor + 16
end

write['cframe24'] = function(value: CFrame)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(24, true)

	local position = value.Position
	local axis, angle = value:ToAxisAngle()
	axis = axis * angle

	buffer.writef32(currentBuffer, cursor, position.X)
	buffer.writef32(currentBuffer, cursor + 4, position.Y)
	buffer.writef32(currentBuffer, cursor + 8, position.Z)

	buffer.writef32(currentBuffer, cursor + 12, axis.X)
	buffer.writef32(currentBuffer, cursor + 16, axis.Y)
	buffer.writef32(currentBuffer, cursor + 20, axis.Z)

	stream.cursor = cursor + 24
end

write['cframe48'] = function(value: CFrame)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(48, true)

	local position = value.Position
	local right, up, look = value.RightVector, value.UpVector, value.LookVector

	buffer.writef32(currentBuffer, cursor, position.X)
	buffer.writef32(currentBuffer, cursor + 4, position.Y)
	buffer.writef32(currentBuffer, cursor + 8, position.Z)

	buffer.writef32(currentBuffer, cursor + 12, right.X)
	buffer.writef32(currentBuffer, cursor + 16, right.Y)
	buffer.writef32(currentBuffer, cursor + 20, right.Z)

	buffer.writef32(currentBuffer, cursor + 24, up.X)
	buffer.writef32(currentBuffer, cursor + 28, up.Y)
	buffer.writef32(currentBuffer, cursor + 32, up.Z)

	buffer.writef32(currentBuffer, cursor + 36, look.X)
	buffer.writef32(currentBuffer, cursor + 40, look.Y)
	buffer.writef32(currentBuffer, cursor + 44, look.Z)

	stream.cursor = cursor + 48
end

write['vector3'] = function(value: Vector3)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(12, true)
	buffer.writef32(currentBuffer, cursor, value.X)
	buffer.writef32(currentBuffer, cursor + 4, value.Y)
	buffer.writef32(currentBuffer, cursor + 8, value.Z)
	stream.cursor = cursor + 12
end

write['vector2'] = function(value: Vector2)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(8, true)

	buffer.writef32(currentBuffer, cursor, value.X)
	buffer.writef32(currentBuffer, cursor + 4, value.Y)
	stream.cursor = cursor + 8
end

write['array'] = function(array: {any}, elementWriter: (value: any) -> ())
	local length = #array
	allocate.expand(2, true)

	local _, _, stream = getBufferAndCursor()
	buffer.writeu16(stream.currentBuffer, stream.cursor, length)
	stream.cursor = stream.cursor + 2

	for _, value in ipairs(array) do
		elementWriter(value)
	end
end

write['map'] = function(dictionary: {[any]: any}, keyWriter: (key: any) -> (), valueWriter: (value: any) -> ())
	local count = 0
	for _ in dictionary do 
		count += 1 
	end

	allocate.expand(2, true)

	local _, _, stream = getBufferAndCursor()
	buffer.writeu16(stream.currentBuffer, stream.cursor, count)
	stream.cursor = stream.cursor + 2

	for key, value in dictionary do
		keyWriter(key)
		valueWriter(value)
	end
end

write['i8'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(1, true)

	buffer.writei8(currentBuffer, cursor, value)
	stream.cursor = cursor + 1
end

write['i16'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(2, true)

	buffer.writei16(currentBuffer, cursor, value)
	stream.cursor = cursor + 2
end

write['i32'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(4, true)

	buffer.writei32(currentBuffer, cursor, value)
	stream.cursor = cursor + 4
end

write['u8'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(1, true)

	buffer.writeu8(currentBuffer, cursor, value)
	stream.cursor = cursor + 1
end

write['u16'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(2, true)

	buffer.writeu16(currentBuffer, cursor, value)
	stream.cursor = cursor + 2
end

write['u32'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(4, true)

	buffer.writeu32(currentBuffer, cursor, value)
	stream.cursor = cursor + 4
end

write['f32'] = function(value: number)
	local currentBuffer, cursor, stream = getBufferAndCursor()
	allocate.expand(4, true)

	buffer.writef32(currentBuffer, cursor, value)
	stream.cursor = cursor + 4
end

write['f64'] = function(value: number)
	local currentBuffer: buffer, cursor: number, stream = getBufferAndCursor()
	allocate.expand(8, true)
	
	buffer.writef64(currentBuffer, cursor, value)
	stream.cursor = cursor + 8
end

write['buffer'] = function(value: buffer)
	local currentBuffer: buffer, cursor: number, stream = getBufferAndCursor()
	local length: number = (value :: any).Size

	allocate.expand(2 + length, true)

	buffer.writeu16(currentBuffer, cursor, length)
	buffer.copy(value, 0, currentBuffer, stream.cursor, length)
	stream.cursor = stream.cursor + length
end

write['instance'] = function(value: Instance?)
	local currentBuffer, cursor, stream = getBufferAndCursor()

	if not value then
		allocate.expand(2, true)
		buffer.writeu16(currentBuffer, cursor, 0)
		stream.cursor = cursor + 2
		return
	end

	local references = stream.references
	local index = references[value]
	if not index then
		index = #references + 1
		references[index] = value
		references[value] = index 
	end

	allocate.expand(2, true)
	buffer.writeu16(currentBuffer, cursor, index)
	stream.cursor = cursor + 2
end

return write
