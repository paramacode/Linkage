--!strict
local types = require(script.Parent.Parent.types)

local allocate = {}

allocate.size = 1024
allocate.cursor = 0
allocate.currentBuffer = buffer.create(allocate.size)

function allocate.expand(bytes: number, dynamic: boolean): buffer?
	if allocate.cursor + bytes < allocate.size then return allocate.currentBuffer end
	if not dynamic then return allocate.currentBuffer end

	repeat
		allocate.size = math.floor(allocate.size * 1.5)
	until allocate.cursor + bytes < allocate.size

	local newBuffer = buffer.create(allocate.size)
	buffer.copy(newBuffer, 0, allocate.currentBuffer)
	allocate.currentBuffer = newBuffer

	return allocate.currentBuffer
end

function allocate.create(): types.streamTypes
	return {
		size = 256,
		cursor = 0,
		references = {},
		currentBuffer = buffer.create(256),
	}
end

function allocate.dump(stream: types.streamTypes): (buffer, {unknown}?)
	local cursor = stream.cursor
	local dumpBuffer = buffer.create(cursor)

	buffer.copy(dumpBuffer, 0, stream.currentBuffer, 0, cursor)

	local references = next(stream.references) and stream.references or nil
	return dumpBuffer, references
end

return allocate
