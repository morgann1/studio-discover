--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const installerTypes = require(StudioDiscover.Source.Installer.types)

export type Operation = {
	read isRunning: boolean,
	read error: string?,
	read run: (operation: () -> installerTypes.OperationResult) -> (),
	read clearError: () -> (),
}

--[[
	Runs an installer operation from a component, such as an update or a removal,
		and tracks whether it is running and why it failed. A component that unmounts
		mid-run drops the outcome. A success needs no handling, since the installer
		refreshes what the component lists.
]]
const function useOperation(): Operation
	const isRunning, setIsRunning = React.useState(false)
	const errorText, setErrorText = React.useState<<string?>>(nil)
	const mountedRef = React.useRef(true)

	React.useEffect(function()
		return function()
			mountedRef.current = false
		end
	end, {})

	const run = React.useCallback(function(operation: () -> installerTypes.OperationResult)
		setIsRunning(true)
		setErrorText(nil)

		task.spawn(function()
			const result = operation()
			if not mountedRef.current then
				return
			end

			setIsRunning(false)
			if not result.ok then
				setErrorText(result.error)
			end
		end)
	end, {})

	const clearError = React.useCallback(function()
		setErrorText(nil)
	end, {})

	return {
		isRunning = isRunning,
		error = errorText,
		run = run,
		clearError = clearError,
	}
end

return useOperation
