--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local f64 = {
	serialize = writer['f64'],
	deserialize = reader['f64'],
} :: types.dataTypes<number>

return f64
