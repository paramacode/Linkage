--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local cframe: {[string]: types.dataTypes<CFrame>} = {}

cframe.cframe24 = {
	serialize = writer['cframe24'],
	deserialize = reader['cframe24'],
} :: types.dataTypes<CFrame>

cframe.cframe48 = {
	serialize = writer['cframe48'],
	deserialize = reader['cframe48'],
} :: types.dataTypes<CFrame>

return cframe
