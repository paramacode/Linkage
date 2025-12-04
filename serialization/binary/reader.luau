--!strict
local read = {}

read['string'] = function(currentBuffer: buffer, cursor: number): (string, number)
    local length = buffer.readu16(currentBuffer, cursor)
    local value = buffer.readstring(currentBuffer, cursor + 2, length)
    return value, cursor + 2 + length
end

read['boolean'] = function(currentBuffer: buffer, cursor: number): (boolean, number)
    local byteValue = buffer.readu8(currentBuffer, cursor)
    local boolValue = byteValue ~= 0
    return boolValue, cursor + 1
end

read["cframe16"] = function(currentBuffer: buffer, cursor: number): (CFrame, number)
	local x = buffer.readf32(currentBuffer, cursor)
	local y = buffer.readf32(currentBuffer, cursor + 4)
	local z = buffer.readf32(currentBuffer, cursor + 8)

	local angle = buffer.readf32(currentBuffer, cursor + 12)

	return CFrame.fromAxisAngle(Vector3.yAxis, angle) + Vector3.new(x, y, z), cursor + 16
end

read['cframe24'] = function(currentBuffer: buffer, cursor: number): (CFrame, number)
    local x = buffer.readf32(currentBuffer, cursor)
	local y = buffer.readf32(currentBuffer, cursor + 4)
	local z = buffer.readf32(currentBuffer, cursor + 8)

	local rx = buffer.readf32(currentBuffer, cursor + 12)
	local ry = buffer.readf32(currentBuffer, cursor + 16)
	local rz = buffer.readf32(currentBuffer, cursor + 20)

	local axis = Vector3.new(rx, ry, rz)
	local angle = axis.Magnitude
	if angle ~= 0 then
		axis = axis / angle
	end

	return CFrame.fromAxisAngle(axis, angle) + Vector3.new(x, y, z), cursor + 24
end

read['cframe48'] = function(currentBuffer: buffer, cursor: number): (CFrame, number)
    local px = buffer.readf32(currentBuffer, cursor)
	local py = buffer.readf32(currentBuffer, cursor + 4)
	local pz = buffer.readf32(currentBuffer, cursor + 8)
	local pos = Vector3.new(px, py, pz)

	local rx = buffer.readf32(currentBuffer, cursor + 12)
	local ry = buffer.readf32(currentBuffer, cursor + 16)
	local rz = buffer.readf32(currentBuffer, cursor + 20)
	local right = Vector3.new(rx, ry, rz)

	local ux = buffer.readf32(currentBuffer, cursor + 24)
	local uy = buffer.readf32(currentBuffer, cursor + 28)
	local uz = buffer.readf32(currentBuffer, cursor + 32)
	local up = Vector3.new(ux, uy, uz)

	local lx = buffer.readf32(currentBuffer, cursor + 36)
	local ly = buffer.readf32(currentBuffer, cursor + 40)
	local lz = buffer.readf32(currentBuffer, cursor + 44)
	local look = Vector3.new(lx, ly, lz)

	local cf = CFrame.fromMatrix(pos, right, up, look)
	return cf, cursor + 48
end

read['vector3'] = function(currentBuffer: buffer, cursor: number): (Vector3, number)
    local x = buffer.readf32(currentBuffer, cursor)
    local y = buffer.readf32(currentBuffer, cursor + 4)
    local z = buffer.readf32(currentBuffer, cursor + 8)
    return Vector3.new(x, y, z), cursor + 12
end

read['vector2'] = function(currentBuffer: buffer, cursor: number): (Vector2, number)
    local x = buffer.readf32(currentBuffer, cursor)
    local y = buffer.readf32(currentBuffer, cursor + 4)
    return Vector2.new(x, y), cursor + 8
end

read['i8'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readi8(currentBuffer, cursor)
    return value, cursor + 1
end

read['i16'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readi16(currentBuffer, cursor)
    return value, cursor + 2
end

read['i32'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readi32(currentBuffer, cursor)
    return value, cursor + 4
end

read['u8'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readu8(currentBuffer, cursor)
    return value, cursor + 1
end

read['u16'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readu16(currentBuffer, cursor)
    return value, cursor + 2
end

read['u32'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readu32(currentBuffer, cursor)
    return value, cursor + 4
end

read['f32'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readf32(currentBuffer, cursor)
    return value, cursor + 4
end

read['f64'] = function(currentBuffer: buffer, cursor: number): (number, number)
    local value = buffer.readf64(currentBuffer, cursor)
    return value, cursor + 8
end

read['buffer'] = function(currentBuffer: buffer, cursor: number): (buffer, number)
    local length = buffer.readu16(currentBuffer, cursor)
	cursor += 2

	local newBuffer = buffer.create(length)
	buffer.copy(currentBuffer, cursor, newBuffer, 0, length)
	return newBuffer, cursor + length
end

return read