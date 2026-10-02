--!strict

const historyAtom = require(script.Parent.historyAtom)

--[[
	Pops every screen above the one with `id`, keeping them so going forward walks
		back up. Does nothing when no screen on the stack has that id.
]]
const function goBackTo(id: string)
	historyAtom(function(history)
		const stack = table.clone(history.stack)
		const forward = table.clone(history.forward)

		local index: number? = nil
		for i, screen in stack do
			if screen.id == id then
				index = i
			end
		end

		if index == nil then
			return history
		end

		while #stack > index do
			const screen = table.remove(stack)
			if screen ~= nil then
				table.insert(forward, screen)
			end
		end

		return { stack = stack, forward = forward }
	end)
end

return goBackTo
