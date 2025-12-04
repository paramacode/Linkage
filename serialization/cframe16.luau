--!strict
local binary = script.Parent.binary

local writer = require(binary.writer)
local reader = require(binary.reader)

local types = require(script.Parent.Parent.types)

local module = {
    serialize = writer['cframe16'],
    deserialize = reader['cframe16'],
} :: types.dataTypes<CFrame>

return module
