--!strict

export type FieldValidator = (value: unknown) -> boolean

--[[
	Overlays the settings saved on disk onto `defaults`. Only keys with a validator are
		read, and a saved value that fails its validator falls back to the default, so a
		corrupt or outdated file never reaches the plugin.

	Returns the merged settings and the keys that fell back.
]]
const function mergeSettings<T>(defaults: T, saved: unknown, validators: { [string]: FieldValidator }): (T, { string })
	const rejected: { string } = {}

	if typeof(saved) ~= "table" then
		return defaults, rejected
	end

	const savedFields = saved :: { [unknown]: unknown }
	const merged = table.clone(defaults :: { [string]: unknown })

	for key, validate in validators do
		const value = savedFields[key]
		if value == nil then
			continue
		end

		if validate(value) then
			merged[key] = value
		else
			table.insert(rejected, key)
		end
	end

	return merged :: T, rejected
end

return mergeSettings
