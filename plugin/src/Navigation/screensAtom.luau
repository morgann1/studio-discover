--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local types = require(script.Parent.types)

local screensAtom = Charm.atom({} :: { types.Screen })

return screensAtom
