--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
    serialize = writer['string'],
    deserialize = reader['string'],
} :: types.dataTypes<string>

return module
