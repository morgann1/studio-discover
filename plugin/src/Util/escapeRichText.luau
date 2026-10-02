--!strict

const ESCAPES = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
}

-- Escapes text the user typed so it shows as typed inside a RichText label.
const function escapeRichText(text: string): string
	return (string.gsub(text, "[&<>\"']", ESCAPES))
end

return escapeRichText
