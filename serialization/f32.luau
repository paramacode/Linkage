--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local f32 = {
	serialize = writer['f32'],
	deserialize = reader['f32'],
} :: types.dataTypes<number>

return f32
