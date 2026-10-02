--!strict

const TTL_SECONDS = 300

export type Cache<T> = {
	read get: (key: string) -> T?,
	read set: (key: string, value: T) -> (),
}

type Entry<T> = {
	read value: T,
	read expiresAt: number,
}

-- Returns a cache whose entries expire five minutes after they are set. Each registry endpoint owns one.
const function createCache<T>(): Cache<T>
	const entries: { [string]: Entry<T>? } = {}

	const function get(key: string): T?
		const entry = entries[key]
		if entry == nil then
			return nil
		end

		if os.clock() >= entry.expiresAt then
			entries[key] = nil
			return nil
		end

		return entry.value
	end

	const function set(key: string, value: T)
		entries[key] = {
			value = value,
			expiresAt = os.clock() + TTL_SECONDS,
		}
	end

	return table.freeze({
		get = get,
		set = set,
	})
end

return createCache
