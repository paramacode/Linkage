--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
	serialize = writer['i8'],	
	deserialize = reader['i8'],
} :: types.dataTypes<number>

return module
