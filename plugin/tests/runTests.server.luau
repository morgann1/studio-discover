--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DevPackages = ReplicatedStorage:WaitForChild("DevPackages") :: Folder
local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local Tests = StudioDiscover:WaitForChild("Tests") :: Folder

local Jest = require(DevPackages:WaitForChild("Jest"))

local ok, err = pcall(function()
	local status, payload = Jest.runCLI(Tests, {
		verbose = true,
		ci = false,
	}, { Tests }):awaitStatus()

	if status ~= "Resolved" then
		error(`Jest promise rejected: {tostring(payload)}`, 0)
	end

	local results = (payload :: any).results
	if results == nil then
		error(`Jest returned no results payload: {tostring(payload)}`, 0)
	end

	if results.numFailedTestSuites > 0 or results.numFailedTests > 0 then
		error(`Jest: {results.numFailedTests} test(s) failed`, 0)
	end
end)

if not ok then
	warn(`[Tests] {tostring(err)}`)
	error(tostring(err), 0)
end
