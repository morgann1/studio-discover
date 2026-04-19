--!strict

local HttpService = game:GetService("HttpService")

local function createScreenId(): string
	return HttpService:GenerateGUID(false)
end

return createScreenId
