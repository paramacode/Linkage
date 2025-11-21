--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local u16 = {
	serialize = writer['u16'],
	deserialize = reader['u16'],
} :: types.dataTypes<number>

return u16
