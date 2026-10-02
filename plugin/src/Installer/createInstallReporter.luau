--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
const types = require(StudioDiscover.Source.Installer.types)

const logger = createLogger.createLogger("installer.install")

export type InstallReporter = {
	read progress: (message: string) -> (),
	read fail: (message: string, failures: { string }) -> types.OperationResult,
	read finish: (resolutionFailures: { string }, applyResult: types.OperationResult) -> types.OperationResult,
}

--[[
	Shows one install's progress and outcome on the package screen through
		`installerAtom`, and builds the result the install returns. Both registries'
		installs report through this, so they read the same to the user.

	Creating a reporter writes nothing, so a call rejected by the busy lock leaves the
		running install's state alone.
]]
const function createInstallReporter(target: types.InstallerTarget): InstallReporter
	const label = `{target.scope}/{target.name}@{target.version}`

	const function setState(status: types.InstallStatus, message: string, errors: { string })
		installerAtom({
			status = status,
			message = message,
			errors = errors,
			target = target,
		})
	end

	-- Errors only arrive with the outcome, so a running install never has any.
	const function progress(message: string)
		logger.debug(`progress: {message}`)
		setState("running", message, {})
	end

	const function fail(message: string, failures: { string }): types.OperationResult
		logger.warn(`install of {label} failed: {message}`)
		setState("error", message, failures)

		return {
			ok = false,
			error = message,
			failures = failures,
		}
	end

	const function finish(resolutionFailures: { string }, applyResult: types.OperationResult): types.OperationResult
		const failures = table.clone(resolutionFailures)
		table.move(applyResult.failures, 1, #applyResult.failures, #failures + 1, failures)

		if not applyResult.ok then
			return fail(`Install failed: {applyResult.error}`, failures)
		end

		logger.info(`install succeeded: {label}`)
		setState(
			"success",
			if #failures > 0 then `Installed with {#failures} warning(s)` else `Installed {label}`,
			failures
		)

		return {
			ok = true,
			failures = failures,
		}
	end

	return {
		progress = progress,
		fail = fail,
		finish = finish,
	}
end

return createInstallReporter
