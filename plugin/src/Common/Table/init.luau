--!strict

const Header = require(script.Header)
const Row = require(script.Row)
const types = require(script.types)

export type Column = types.Column

-- A header and rows that share one set of columns. Screens put the header above their scrolling rows.
const Table = table.freeze({
	Header = Header,
	Row = Row,
})

return Table
