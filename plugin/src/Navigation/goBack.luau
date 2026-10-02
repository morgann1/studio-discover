--!strict

const goBackTo = require(script.Parent.goBackTo)
const historyAtom = require(script.Parent.historyAtom)

-- Returns to the screen under the current one, if there is one.
const function goBack()
	const stack = historyAtom().stack
	if #stack > 1 then
		goBackTo(stack[#stack - 1].id)
	end
end

return goBack
