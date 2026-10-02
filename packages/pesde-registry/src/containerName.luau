--!strict

-- The name of a package's folder in the `.pesde` index, which holds one folder per installed version.
const function containerName(scope: string, name: string): string
	return `{scope}+{name}`
end

return containerName
