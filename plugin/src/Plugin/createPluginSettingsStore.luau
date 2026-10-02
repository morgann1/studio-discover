--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const createLogger = require(StudioDiscover.Core.createLogger)
const mergeSettings = require(StudioDiscover.Source.Plugin.mergeSettings)
const pluginAtom = require(StudioDiscover.Source.Plugin.pluginAtom)

const logger = createLogger.createLogger("settings")

export type PluginSettingsStore<T> = {
	read getStorage: () -> T,
	read setStorage: (value: T | (T) -> T) -> (),
	read getIsLoading: () -> boolean,
}

--[[
	Keeps settings in a Charm atom backed by the plugin's settings on disk. They load
		once the plugin handle is set, and every change after that is written back.
		Until the load finishes, the store holds `defaults`.
]]
const function createPluginSettingsStore<T>(
	storageKey: string,
	defaults: T,
	validators: { [string]: mergeSettings.FieldValidator }
): PluginSettingsStore<T>
	const storageAtom = Charm.atom(defaults)
	const isLoadingAtom = Charm.atom(true)

	const function readAsync(plugin: Plugin): T
		const data = plugin:GetSetting(storageKey)
		if typeof(data) ~= "string" then
			logger.info(`no saved settings for {storageKey}`)
			return defaults
		end

		const decoded, saved = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if not decoded then
			logger.warn(`failed to decode settings for {storageKey}:`, saved)
			return defaults
		end

		const merged, rejected = mergeSettings(defaults, saved, validators)
		for _, key in rejected do
			logger.info(`settings field {storageKey}.{key} failed validation, using default`)
		end

		return merged
	end

	const function writeAsync(plugin: Plugin, storage: T)
		const ok, err = pcall(function()
			plugin:SetSetting(storageKey, HttpService:JSONEncode(storage))
		end)

		if not ok then
			logger.warn(`failed to write settings for {storageKey}: {err}`)
		end
	end

	Charm.effect(function()
		const plugin = pluginAtom()

		if plugin ~= nil and isLoadingAtom() then
			task.spawn(function()
				storageAtom(readAsync(plugin))
				isLoadingAtom(false)
			end)
		end
	end)

	-- Only changes made after the load are written, so loading never writes the file straight back.
	local previous = defaults
	Charm.effect(function()
		const storage = storageAtom()
		const plugin = pluginAtom()
		const isLoading = isLoadingAtom()

		const changed = storage ~= previous
		previous = storage

		if changed and plugin ~= nil and not isLoading then
			task.spawn(writeAsync, plugin, storage)
		end
	end)

	return {
		getStorage = function()
			return storageAtom()
		end,
		setStorage = function(value)
			storageAtom(value)
		end,
		getIsLoading = function()
			return isLoadingAtom()
		end,
	}
end

return createPluginSettingsStore
