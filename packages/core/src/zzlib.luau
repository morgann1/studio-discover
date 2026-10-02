--!strict

--[[
	zzlib with its real signatures, for both registries.

	zzlib ships without annotations, and the new solver infers types for it that
		it cannot check, which can crash luau-lsp outright. It is required untyped
		here, once, and every caller sees only these signatures.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

export type Zzlib = {
	-- Returns a stateless iterator over the file names in a zip archive, which yields the next position and name.
	read files: (zipData: string) -> ((zipData: string, position: number) -> (number?, string?), string, number),
	-- Returns one file's contents from a zip archive. Throws when the file is missing or the archive is malformed.
	read unzip: (zipData: string, fileName: string) -> string,
	-- Decompresses gzip data. Throws when the data is malformed.
	read gunzip: (data: string) -> string,
}

const zzlib: Zzlib = (require :: any)(StudioDiscover.Packages.zzlib)

return zzlib
