--!strict
export type dataTypes<T> = {
    deserialize: (currentBuffer: buffer, cursor: number) -> (T, number),
	serialize: (value: T) -> (),
}

export type bufferWriterTypes = {
	array: ({any}) -> (),
	boolean: (boolean) -> (),
	buffer: (buffer) -> (),
	cframe: (CFrame) -> (),
	dictionary: ({[string]: any}) -> (),
	f32: (number) -> (),
	f64: (number) -> (),
	i8: (number) -> (),
	i16: (number) -> (),
	i32: (number) -> (),
	u8: (number) -> (),
	u16: (number) -> (),
	u32: (number) -> (),
	string: (string) -> (),
	vector2: (Vector2) -> (),
	vector3: (Vector3) -> (),

	[string]: (any) -> (),
}

export type schemaTypeName = | "array" | "boolean" | "buffer" | "cframe" | "dictionary" | "f32" | "f64" | "i8" | "i16" | "i32" | "u8" | "u16" | "u32" | "string" | "vector2" | "vector3"
export type schemaDefinition = {[string]: schemaTypeName}
export type schemaData<D> = {[string]: any}

export type streamTypes = {
	size: number,
	cursor: number,
	references: {unknown},
	currentBuffer: buffer,
}

export type rawSerializer = {
	serialize: (buffer: buffer, cursor: number?) -> (any, number?),
    deserialize: (value: any) -> (),
}

export type normalizedSerializer = {
	encode: (any) -> (),
	decode: (buffer: buffer, cursor: number) -> (any, number),
}

export type schemaPacket = {
	encode: (any) -> buffer,
	decode: (buffer: buffer) -> any,
	reliable: boolean?,
}

return {}