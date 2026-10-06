--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const installerTypes = require(StudioDiscover.Source.Installer.types)
const successNotice = require(StudioDiscover.Source.Util.successNotice)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const SHOWN_SECONDS = 5

export type Notice = {
	read id: number,
	read text: string,
}

-- The one notice at the bottom of the widget. A new notice replaces the last.
const noticeAtom = Charm.atom<<Notice?>>(nil)
local lastId = 0

const function useNotice(): Notice?
	return useAtom(function()
		return noticeAtom()
	end)
end

const function dismiss()
	noticeAtom(nil)
end

-- Shows `text` until the user closes it or `SHOWN_SECONDS` pass.
const function show(text: string)
	lastId += 1
	const id = lastId
	noticeAtom({ id = id, text = text })

	task.delay(SHOWN_SECONDS, function()
		const current = noticeAtom()
		if current ~= nil and current.id == id then
			dismiss()
		end
	end)
end

--[[
	Shows that an installer operation finished, from inside the operation, so it shows
		even when the row that started it is gone. A failure shows nothing here.
]]
const function showSuccess(result: installerTypes.OperationResult, done: string, hint: string?)
	const text = successNotice(result, done, hint)
	if text ~= nil then
		show(text)
	end
end

const NoticeStore = table.freeze({
	useNotice = useNotice,
	show = show,
	showSuccess = showSuccess,
	dismiss = dismiss,
})

return NoticeStore
