--!strict

-- One entry in a screen's "…" menu.
export type MenuAction = {
	read id: string,
	read text: string,
	read onActivated: () -> (),
}

return nil
