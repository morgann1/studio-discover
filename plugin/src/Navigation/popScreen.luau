--!strict

const screensAtom = require(script.Parent.screensAtom)

const function popScreen()
	screensAtom(function(stack)
		const nextStack = table.clone(stack)
		table.remove(nextStack)

		return nextStack
	end)
end

return popScreen
