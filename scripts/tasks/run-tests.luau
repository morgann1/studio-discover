--!strict

--[[
	Runs inside the test place, through run-in-roblox or pasted into Studio's command
		bar. Errors when any spec fails, which is what fails `scripts/test.luau`.
]]

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const DevPackages = ReplicatedStorage:WaitForChild("DevPackages") :: Folder
const StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
const Tests = StudioDiscover:WaitForChild("Tests") :: Folder

-- Analysis uses the plugin's sourcemap, which has no DevPackages, and Jest ships untyped anyway.
const Jest = (require :: any)(DevPackages:WaitForChild("Jest"))

const ok, err = pcall(function()
	const status, payload = Jest.runCLI(Tests, {
		verbose = true,
		ci = false,
	}, { Tests }):awaitStatus()

	if status ~= "Resolved" then
		error(`Jest promise rejected: {payload}`, 0)
	end

	const results = payload.results
	if results == nil then
		error(`Jest returned no results payload: {payload}`, 0)
	end

	if results.numFailedTestSuites > 0 or results.numFailedTests > 0 then
		error(`Jest: {results.numFailedTests} test(s) failed`, 0)
	end
end)

if not ok then
	warn(`[Tests] {err}`)
	error(tostring(err), 0)
end
