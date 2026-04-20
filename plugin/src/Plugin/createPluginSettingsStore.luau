--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("settings")

export type PluginSettingsStore<T> = {
	getStorage: () -> T,
	setStorage: (T | ((T) -> T)) -> (),

	isSettingDefault: (settingName: string) -> boolean,

	getIsLoading: () -> boolean,
	getErr: () -> string?,

	dispose: () -> (),
}

export type FieldValidator = (value: any) -> (boolean, string?)

local function createPluginSettingsStore<T>(
	storageKey: string,
	defaultValue: T,
	validators: { [string]: FieldValidator }
): PluginSettingsStore<T>
	local storageAtom = Charm.atom(defaultValue)
	local isLoadingAtom = Charm.atom(true)
	local errAtom = Charm.atom(nil :: string?)

	local function readPluginSettingsAsync(plugin: Plugin): T?
		logger.info(`reading plugin settings for {storageKey} from disk...`)

		local data = plugin:GetSetting(storageKey)

		logger.debug(`read raw plugin settings for {storageKey}:`, data)

		if typeof(data) ~= "string" then
			logger.info("no plugin settings to read")
			return nil
		end

		logger.info(`deserializing plugin settings for {storageKey} to object...`)

		local success, result = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if not success then
			logger.warn(`failed to decode plugin settings for {storageKey}:`, result)
			errAtom(result)
			return nil
		end

		if typeof(defaultValue) ~= "table" or typeof(result) ~= "table" then
			return result :: T
		end

		local merged: any = table.clone(defaultValue :: any)
		for key in (defaultValue :: any) :: { [string]: any } do
			local storedValue = (result :: any)[key]
			if storedValue == nil then
				continue
			end

			local validator = validators[key]
			if validator == nil then
				merged[key] = storedValue
			else
				local isValid = validator(storedValue)
				if isValid then
					merged[key] = storedValue
				else
					logger.info(`settings field {storageKey}.{key} failed validation, using default`)
				end
			end
		end

		logger.info(`got plugin settings for {storageKey}`)
		return merged
	end

	local function writePluginSettingsAsync(plugin: Plugin, storage: T)
		logger.info("writing plugin settings to disk...")
		local data = HttpService:JSONEncode(storage)

		local success, err = pcall(function()
			plugin:SetSetting(storageKey, data)
		end)

		if not success then
			logger.warn(`failed to write plugin settings to disk: {err}`)
		end
	end

	local disposeLoad = Charm.effect(function()
		local isLoading = isLoadingAtom()
		local plugin = PluginStore.get().getPlugin()

		if plugin and isLoading then
			task.spawn(function()
				local data = readPluginSettingsAsync(plugin)
				if data then
					storageAtom(data)
				end
				isLoadingAtom(false)
			end)
		end
	end)

	local prevStorage: T? = defaultValue
	local disposeWrite = Charm.effect(function()
		local storage = storageAtom()
		local isLoading = isLoadingAtom()
		local plugin = PluginStore.get().getPlugin()

		if plugin and not isLoading and storage ~= prevStorage then
			task.spawn(function()
				writePluginSettingsAsync(plugin, storage)
			end)
		end

		prevStorage = storage
	end)

	local function dispose()
		disposeLoad()
		disposeWrite()
	end

	local function isSettingDefault(settingName: string): boolean
		local storage = storageAtom()
		if typeof(defaultValue) ~= "table" or typeof(storage) ~= "table" then
			return true
		end

		local settingDefaultValue = (defaultValue :: any)[settingName]
		local storedValue = (storage :: any)[settingName]

		return storedValue == nil or storedValue == settingDefaultValue
	end

	return {
		getIsLoading = function(): boolean
			return isLoadingAtom()
		end,
		getErr = function(): string?
			return errAtom()
		end,
		getStorage = function(): T
			return storageAtom()
		end,
		setStorage = function(value)
			storageAtom(value :: any)
		end,
		isSettingDefault = isSettingDefault,
		dispose = dispose,
	}
end

return createPluginSettingsStore
