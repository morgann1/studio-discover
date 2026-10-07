--!strict

-- The registry path of a package's document, such as "/@quenty%2fmaid", with the scope's slash escaped as npm expects.
const function packagePath(name: string): string
	const escaped = string.gsub(name, "/", "%%2f")
	return `/{escaped}`
end

return packagePath
