--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

--[[
	Walks a lockfile's edges down from `rootId` and returns every package in its
		subtree, the root first. `dependenciesOf` reads a package's edges. Returns nil
		when the root, or any package an edge points at, is missing from the lock, so
		the caller resolves that root fresh.
]]
const function collectLockedSubtree<T>(
	locked: { [string]: T },
	rootId: string,
	dependenciesOf: (pkg: T) -> { types.Dependency }
): { T }?
	const root = locked[rootId]
	if root == nil then
		return nil
	end

	const subtree = { root }
	const seen: { [string]: true? } = { [rootId] = true }
	local head = 1
	while head <= #subtree do
		const pkg = subtree[head]
		head += 1

		for _, dependency in dependenciesOf(pkg) do
			if seen[dependency.packageId] then
				continue
			end

			const lockedDependency = locked[dependency.packageId]
			if lockedDependency == nil then
				return nil
			end

			seen[dependency.packageId] = true
			table.insert(subtree, lockedDependency)
		end
	end

	return subtree
end

return collectLockedSubtree
