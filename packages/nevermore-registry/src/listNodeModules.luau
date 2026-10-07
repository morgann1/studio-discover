--!strict

--[[
	The packages in one `node_modules` folder, keyed by npm name. A scoped package
		sits in its scope's folder, so "@quenty/maid" is the `maid` inside `@quenty`.
]]
const function listNodeModules(folder: Instance): { [string]: Instance }
	const packages: { [string]: Instance } = {}

	for _, child in folder:GetChildren() do
		if string.sub(child.Name, 1, 1) ~= "@" or not child:IsA("Folder") then
			packages[child.Name] = child
			continue
		end

		for _, scoped in child:GetChildren() do
			packages[`{child.Name}/{scoped.Name}`] = scoped
		end
	end

	return packages
end

return listNodeModules
