--!strict

-- Counts the entries in a dictionary, which `#` does not.
const function countKeys<K, V>(dictionary: { [K]: V }): number
	local count = 0
	for _ in dictionary do
		count += 1
	end

	return count
end

return countKeys
