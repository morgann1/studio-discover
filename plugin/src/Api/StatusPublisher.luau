--!strict

export type Status = {
	state: "idle" | "waiting",
	reason: "queue" | "rate-limited" | nil,
	untilClock: number,
}

local status: Status = { state = "idle", reason = nil, untilClock = 0 }
local subscribers: { (Status) -> () } = {}

local StatusPublisher = {}

function StatusPublisher.get(): Status
	return status
end

function StatusPublisher.set(newStatus: Status)
	status = newStatus
	for _, cb in subscribers do
		task.spawn(cb, status)
	end
end

function StatusPublisher.clearIfElapsed(untilClock: number)
	if untilClock <= os.clock() then
		StatusPublisher.set({ state = "idle", reason = nil, untilClock = 0 })
	end
end

function StatusPublisher.subscribe(callback: (Status) -> ()): () -> ()
	table.insert(subscribers, callback)
	task.spawn(callback, status)
	return function()
		for i, cb in subscribers do
			if cb == callback then
				table.remove(subscribers, i)
				break
			end
		end
	end
end

return StatusPublisher
