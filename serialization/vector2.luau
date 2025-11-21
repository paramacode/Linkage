--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
	serialize = writer['vector2'],
	deserialize = reader['vector2'],
} :: types.dataTypes<Vector2>

return module
