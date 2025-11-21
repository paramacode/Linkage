--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local u32 = {
	serialize = writer['u32'],
	deserialize = reader['u32'],
} :: types.dataTypes<number>

return u32
