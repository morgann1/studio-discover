--!strict

const historyAtom = require(script.Parent.historyAtom)

-- Returns to the screen the last step back left, if there is one.
const function goForward()
	historyAtom(function(history)
		const forward = table.clone(history.forward)
		const screen = table.remove(forward)
		if screen == nil then
			return history
		end

		const stack = table.clone(history.stack)
		table.insert(stack, screen)

		return { stack = stack, forward = forward }
	end)
end

return goForward
