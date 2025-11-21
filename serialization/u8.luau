--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local u8 = {
	serialize = writer['u8'],
	deserialize = reader['u8'],
} :: types.dataTypes<number>

return u8
