--!strict

--[[
	Whether a Wally answer outside 2xx means the package doesn't exist. Wally answers
		a package that isn't in its index with a 500 whose message says it "could not
		open package", rather than a 404.
]]
const function isMissing(statusCode: number, body: string?): boolean
	if statusCode == 404 then
		return true
	end

	return statusCode == 500 and body ~= nil and string.find(body, "could not open package", 1, true) ~= nil
end

return isMissing
