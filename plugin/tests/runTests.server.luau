--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DevPackages = ReplicatedStorage:WaitForChild("DevPackages") :: Folder
local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local Tests = StudioDiscover:WaitForChild("Tests") :: Folder

local Jest = require(DevPackages:WaitForChild("Jest"))

local status, result = Jest.runCLI(Tests, {
	verbose = false,
	ci = false,
}, { Tests }):awaitStatus()

if status == "Rejected" then
	error(result)
end

if result.results.numFailedTestSuites > 0 or result.results.numFailedTests > 0 then
	error(`Jest: {result.results.numFailedTests} test(s) failed`)
end
