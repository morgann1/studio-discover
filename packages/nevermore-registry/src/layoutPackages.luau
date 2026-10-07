--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const types = require(StudioDiscover.Libraries.NevermoreRegistry.types)

type Placement = types.Placement

-- A conflict this deep means a dependency cycle between versions that never settles.
const MAX_DEPTH = 32

--[[
	Lays a resolved graph out the way npm installs it, and the way the Nevermore
		loader looks packages up: from a package's own `node_modules`, then from each
		`node_modules` above it.

	Roots sit at the top. A dependency already visible from the package that needs
		it, at the version it needs, is shared. One nobody above has goes to the top.
		One that conflicts with a version above nests in the needing package's own
		`node_modules`, which nothing else looks through yet, so no package that
		already found its dependency loses it.

	Returns the top of `node_modules` keyed by npm name, and the edges it couldn't
		place.
]]
const function layoutPackages(
	resolved: { [string]: types.NevermoreResolvedPackage },
	rootIds: { string }
): ({ [string]: Placement }, { string })
	const top: { [string]: Placement } = {}
	const parents: { [Placement]: Placement? } = {}
	const failures: { string } = {}
	const queue: { Placement } = {}

	const function lookup(placement: Placement, name: string): Placement?
		local current = placement
		local found = current.children[name]

		while found == nil do
			const parent = parents[current]
			const level = if parent ~= nil then parent.children else top
			found = level[name]

			if parent == nil then
				break
			end
			current = parent
		end

		return found
	end

	const function depth(placement: Placement): number
		local count = 0
		local current = parents[placement]
		while current ~= nil do
			count += 1
			current = parents[current]
		end

		return count
	end

	const sortedRootIds = table.clone(rootIds)
	table.sort(sortedRootIds)
	for _, rootId in sortedRootIds do
		const pkg = resolved[rootId]
		if pkg == nil then
			continue
		end

		const placement: Placement = { packageId = rootId, name = pkg.name, children = {} }
		top[pkg.name] = placement
		table.insert(queue, placement)
	end

	local head = 1
	while head <= #queue do
		const placement = queue[head]
		head += 1

		const pkg = resolved[placement.packageId]
		const dependencies = table.clone(pkg.dependencies)
		table.sort(dependencies, function(a: coreTypes.Dependency, b: coreTypes.Dependency)
			return a.alias < b.alias
		end)

		for _, dependency in dependencies do
			if resolved[dependency.packageId] == nil then
				continue
			end

			const found = lookup(placement, dependency.alias)
			if found ~= nil and found.packageId == dependency.packageId then
				continue
			elseif found ~= nil and depth(placement) >= MAX_DEPTH then
				table.insert(failures, `{placement.packageId}: {dependency.packageId} conflicts too deep to place`)
				continue
			end

			const child: Placement = { packageId = dependency.packageId, name = dependency.alias, children = {} }
			if found == nil then
				top[dependency.alias] = child
			else
				placement.children[dependency.alias] = child
				parents[child] = placement
			end

			table.insert(queue, child)
		end
	end

	return top, failures
end

return layoutPackages
