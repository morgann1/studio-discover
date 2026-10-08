--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const nevermoreHttpClient = require(StudioDiscover.Libraries.NevermoreRegistry.Api.httpClient)
const pesdeHttpClient = require(StudioDiscover.Libraries.PesdeRegistry.Api.httpClient)
const wallyHttpClient = require(StudioDiscover.Libraries.WallyRegistry.Api.httpClient)

const SETTING_KEY = "DiscoverPermissionsRequested"

--[[
	Raises Studio's permission prompts the first time Discover loads, so a new user
		answers them up front instead of halfway through their first install.

	Studio asks for script injection the first time a plugin creates a script, and for
		HTTP access the first time a plugin sends a request to each domain. So this
		creates a throwaway script and sends a HEAD to each registry. Neither result
		matters. Studio remembers the answers, so this runs once per user.
]]
const function requestPermissionsAsync(plugin: Plugin)
	if plugin:GetSetting(SETTING_KEY) == true then
		return
	end

	pcall(function()
		Instance.new("ModuleScript"):Destroy()
	end)

	for _, httpClient in { wallyHttpClient, pesdeHttpClient, nevermoreHttpClient } do
		pcall(function()
			return HttpService:RequestAsync({
				Url = httpClient.baseUrl,
				Method = "HEAD",
			})
		end)
	end

	plugin:SetSetting(SETTING_KEY, true)
end

return requestPermissionsAsync
