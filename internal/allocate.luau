--!strict
local types = require(script.Parent.Parent.types)

local allocate = {}
local activeStreams = {}

function allocate.getActive()
	local runningThread = coroutine.running()
	local stream = runningThread and activeStreams[runningThread]
	assert(stream, 'No active stream bound to this coroutine')
	return stream
end

function allocate.bind(stream)
	local runningThread = coroutine.running()
	assert(runningThread, `{script.Name}: allocate.bind must be called from within a running coroutine`)
	activeStreams[runningThread] = stream
end

function allocate.unbind()
	local runningThread = coroutine.running()
	assert(runningThread, `{script.Name}: allocate.unbind must be called from within a running coroutine`)
	activeStreams[runningThread] = nil
end

function allocate.withStream(stream, call)
	assert(type(call) == 'function', 'withStream requires a function')
	local runningThread = coroutine.running()
	assert(runningThread, 'allocate.withStream must be called from within a running coroutine')
	activeStreams[runningThread] = stream

	local results = table.pack(xpcall(call, debug.traceback))
	local success = results[1]

	activeStreams[runningThread] = nil

	if not success then
		error(results[2])
	end

	return table.unpack(results, 2, results.n)
end

function allocate.expand(bytes: number, dynamic: boolean): buffer?
	local stream = allocate.getActive()
	if stream.cursor + bytes < stream.size then 
		return stream.currentBuffer 
	end

	if not dynamic then 
		return stream.currentBuffer 
	end

	repeat
		stream.size = math.floor(stream.size * 1.5)
	until stream.cursor + bytes < stream.size

	local newBuffer = buffer.create(stream.size)
	buffer.copy(newBuffer, 0, stream.currentBuffer)
	stream.currentBuffer = newBuffer

	return stream.currentBuffer
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
