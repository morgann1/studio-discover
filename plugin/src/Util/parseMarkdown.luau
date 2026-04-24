--!strict

-- Narrow markdown parser for CHANGELOG.md.
-- Handles: H1/H2/H3, bullet lists (`- `), paragraphs, and inline
-- `**bold**`, `*italic*`, `` `code` ``, `[text](url)`.
-- Inline segments are emitted as Roblox RichText.

export type Block = {
	kind: "heading" | "bullet" | "paragraph" | "blank",
	level: number?,
	richText: string,
}

local function escapeRich(text: string): string
	local result = text
	result = result:gsub("&", "&amp;")
	result = result:gsub("<", "&lt;")
	result = result:gsub(">", "&gt;")
	result = result:gsub('"', "&quot;")
	return result
end

-- Applied to non-code text after HTML escaping. Order matters: bold before
-- italic (both use `*`), links last to keep their label text untouched by the
-- emphasis passes.
local function applyEmphasis(text: string): string
	local out = text
	out = out:gsub("%*%*([^*]+)%*%*", "<b>%1</b>")
	out = out:gsub("%*([^*]+)%*", "<i>%1</i>")
	-- RichText has no click affordance; render links as underlined text.
	out = out:gsub("%[([^%]]+)%]%b()", "<u>%1</u>")
	return out
end

local function formatInline(line: string): string
	local pieces: { string } = {}
	local cursor = 1

	while cursor <= #line do
		local tick = line:find("`", cursor, true)
		if tick == nil then
			table.insert(pieces, applyEmphasis(escapeRich(line:sub(cursor))))
			break
		end

		local closing = line:find("`", tick + 1, true)
		if closing == nil then
			table.insert(pieces, applyEmphasis(escapeRich(line:sub(cursor))))
			break
		end

		if tick > cursor then
			table.insert(pieces, applyEmphasis(escapeRich(line:sub(cursor, tick - 1))))
		end
		local codeText = line:sub(tick + 1, closing - 1)
		table.insert(pieces, `<font face="Code">{escapeRich(codeText)}</font>`)
		cursor = closing + 1
	end

	return table.concat(pieces)
end

local function parseMarkdown(source: string): { Block }
	local blocks: { Block } = {}
	local paragraph: { string } = {}

	local function flushParagraph()
		if #paragraph == 0 then
			return
		end
		table.insert(blocks, {
			kind = "paragraph",
			richText = formatInline(table.concat(paragraph, " ")),
		})
		table.clear(paragraph)
	end

	for rawLine in (source .. "\n"):gmatch("([^\n]*)\n") do
		local line = rawLine:gsub("\r$", "")

		if line:match("^%s*$") ~= nil then
			flushParagraph()
			table.insert(blocks, { kind = "blank", richText = "" })
			continue
		end

		local headingHashes, headingText = line:match("^(#+)%s+(.+)$")
		if headingHashes ~= nil and headingText ~= nil and #headingHashes <= 3 then
			flushParagraph()
			table.insert(blocks, {
				kind = "heading",
				level = #headingHashes,
				richText = formatInline(headingText :: string),
			})
			continue
		end

		local bulletText = line:match("^%s*[%-%*]%s+(.+)$")
		if bulletText ~= nil then
			flushParagraph()
			table.insert(blocks, {
				kind = "bullet",
				richText = formatInline(bulletText :: string),
			})
			continue
		end

		table.insert(paragraph, line)
	end

	flushParagraph()
	return blocks
end

return parseMarkdown
