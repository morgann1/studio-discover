--!strict

export type Buffer = {
	write: (self: Buffer, template: string, ...any) -> (),
	writeLine: (self: Buffer, template: string, ...any) -> (),
	writeRaw: (self: Buffer, value: string) -> (),
	writeLineRaw: (self: Buffer, value: string) -> (),
	nextLine: (self: Buffer) -> (),
	indent: (self: Buffer) -> (),
	unindent: (self: Buffer) -> (),
	finish: (self: Buffer) -> string,
}

export type FmtDebug<T> = (value: T, buffer: Buffer, extended: boolean) -> ()

type FmtDebugMeta = { __fmtDebug: FmtDebug<any>? }?

local function defaultTableDebug(buffer: Buffer, input: { [any]: any })
	buffer:writeRaw("{")

	for key, value in input do
		buffer:write("[{:?}] = {:?}", key, value)

		if next(input, key) ~= nil then
			buffer:writeRaw(", ")
		end
	end

	buffer:writeRaw("}")
end

local function defaultTableDebugExtended(buffer: Buffer, input: { [any]: any })
	if next(input) == nil then
		buffer:writeRaw("{}")
		return
	end

	buffer:writeLineRaw("{")
	buffer:indent()

	for key, value in input do
		buffer:writeLine("[{:?}] = {:#?},", key, value)
	end

	buffer:unindent()
	buffer:writeRaw("}")
end

local function debugImpl(buffer: Buffer, value: any, extendedForm: boolean)
	local valueType = typeof(value)

	if valueType == "string" then
		buffer:writeRaw(string.format("%q", value :: string))
	elseif valueType == "table" then
		local valueMeta = getmetatable(value) :: FmtDebugMeta

		if valueMeta ~= nil and valueMeta.__fmtDebug ~= nil then
			valueMeta.__fmtDebug(value, buffer, extendedForm)
		elseif extendedForm then
			defaultTableDebugExtended(buffer, value)
		else
			defaultTableDebug(buffer, value)
		end
	elseif valueType == "Instance" then
		buffer:writeRaw((value :: Instance):GetFullName())
	else
		buffer:writeRaw(tostring(value))
	end
end

local function writeFmt(buffer: Buffer, template: string, ...: any)
	local currentArg = 0
	local i = 1
	local len = #template

	while i <= len do
		local openBrace = template:find("{", i)

		if openBrace == nil then
			buffer:writeRaw(template:sub(i))
			break
		end

		local charAfterBrace = template:sub(openBrace + 1, openBrace + 1)
		if charAfterBrace == "{" then
			buffer:writeRaw(template:sub(i, openBrace))
			i = openBrace + 2
		else
			if openBrace - i > 0 then
				buffer:writeRaw(template:sub(i, openBrace - 1))
			end

			local closeBrace = template:find("}", openBrace + 1)
			assert(closeBrace ~= nil, "Unclosed formatting specifier. Use '{{' to write an open brace.")

			local formatSpecifier = template:sub(openBrace + 1, closeBrace - 1)
			currentArg += 1
			local arg: any = select(currentArg, ...)

			if formatSpecifier == "" then
				buffer:writeRaw(tostring(arg))
			elseif formatSpecifier == ":?" then
				debugImpl(buffer, arg, false)
			elseif formatSpecifier == ":#?" then
				debugImpl(buffer, arg, true)
			else
				error(`unsupported format specifier {formatSpecifier}`, 2)
			end

			i = closeBrace + 1
		end
	end
end

local function debugOutputBuffer(): Buffer
	local segments: { string } = {}
	local startOfLine = true
	local indentLevel = 0
	local indentation = ""

	local function writeRaw(_: Buffer, value: string)
		if #value > 0 then
			if startOfLine and #indentation > 0 then
				table.insert(segments, indentation)
			end

			table.insert(segments, value)
			startOfLine = false
		end
	end

	local function nextLine(_: Buffer)
		table.insert(segments, "\n")
		startOfLine = true
	end

	local function write(self: Buffer, template: string, ...: any)
		writeFmt(self, template, ...)
	end

	local function writeLine(self: Buffer, template: string, ...: any)
		writeFmt(self, template, ...)
		nextLine(self)
	end

	local function writeLineRaw(self: Buffer, value: string)
		writeRaw(self, value)
		nextLine(self)
	end

	local function indent(_: Buffer)
		indentLevel += 1
		indentation = string.rep("    ", indentLevel)
	end

	local function unindent(_: Buffer)
		indentLevel = math.max(0, indentLevel - 1)
		indentation = string.rep("    ", indentLevel)
	end

	local function finish(_: Buffer): string
		return table.concat(segments, "")
	end

	return table.freeze({
		write = write,
		writeLine = writeLine,
		writeRaw = writeRaw,
		writeLineRaw = writeLineRaw,
		nextLine = nextLine,
		indent = indent,
		unindent = unindent,
		finish = finish,
	})
end

local function fmt(template: string, ...: any): string
	local buffer = debugOutputBuffer()
	writeFmt(buffer, template, ...)
	return buffer:finish()
end

return table.freeze({
	fmt = fmt,
})
