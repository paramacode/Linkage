--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
    serialize = writer['cframe24'],
    deserialize = reader['cframe24'],
} :: types.dataTypes<CFrame>

return module
