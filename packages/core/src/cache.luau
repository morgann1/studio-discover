--!strict

local TTL_SECONDS = 300

type Entry = {
	data: any,
	expiresAt: number,
}

local entries: { [string]: Entry } = {}

local function get(key: string): any?
	local entry = entries[key]
	if entry == nil or os.clock() >= entry.expiresAt then
		return nil
	end
	return entry.data
end

local function set(key: string, data: any)
	entries[key] = {
		data = data,
		expiresAt = os.clock() + TTL_SECONDS,
	}
end

return table.freeze({
	get = get,
	set = set,
})
