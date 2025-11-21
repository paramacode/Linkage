--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
	serialize = writer['vector3'],
	deserialize = reader['vector3'],
} :: types.dataTypes<Vector3>

return module
