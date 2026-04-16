# React Patterns

Adapted from [Kampfkarren — Things I learned using React on Roblox](https://blog.boyned.com/articles/things-i-learned-using-react/). Full source is the canonical reference — this is a working summary.

For general Luau/Roblox style see [coding-style.md](coding-style.md).

## `e = React.createElement`

`React.createElement` is extremely common and extremely noisy. The Roblox community has standardized on:

```lua
local e = React.createElement
```

Put it at the top of every React component file. It keeps focus on the structure that matters, and other experienced developers will know what you mean.

## Use strict mode

Add `--!strict` to every new React file, or configure `.luaurc` with `{ "languageMode": "strict" }`. Strict mode catches a lot of React-specific bugs — e.g. it will flag this typo:

```lua
local function HealthBar(props: {
    health: number,
})
    -- code
end

e(HealthBar, {
    helath = 1, -- ERROR: typo caught statically
})
```

Strict mode has some caveats you need to know.

### `useState` and optionals

Luau can't infer optional state types well. Trivial cases work:

```lua
local amount, setAmount = React.useState(0) -- amount: number
```

For `number?`, the naive attempts all fail:

```lua
local amount, setAmount = React.useState(nil)             -- both typed for nil
local amount: number?, setAmount = React.useState(nil)    -- setAmount still only takes nil
local amount, setAmount = React.useState(nil :: number?)  -- anonymous, unusable
```

The full incantation:

```lua
local amount: number?, setAmount = React.useState(nil :: number?)
```

Same pattern for unions:

```lua
type MenuState = "open" | "closed"
local menuState: MenuState, setMenuState = React.useState("open" :: MenuState)
```

### Intersections don't type check as props

Intersection types (`A & B`) currently fail when used as a prop type. Workaround — assign to a locally typed variable first so the error surfaces at the assignment site:

```lua
local value: Value = {
    x = 1,
    y = 2,
}

e(Component, {
    value = value,
})
```

### Invalid property names don't error

This silently passes with `maxHealth` completely unused:

```lua
e(HealthBar, {
    health = 100,
    maxHealth = 100, -- no error, no effect
})
```

Be aware that strict mode won't save you from this one.

## Return `React.ReactNode?` for conditional renders

Strict mode requires consistent return arity. A component that sometimes returns `nil` and sometimes returns an element will error unless you annotate the return:

```lua
local function ContextualHealthBar(props: {
    health: number,
    maxHealth: number,
}): React.ReactNode?
    if props.health == props.maxHealth then
        return nil
    end

    return e(HealthBar, { ... })
end
```

## Don't type layout orders by hand

Hard-coded `LayoutOrder = 1, 2, 3` values become a nightmare when you reorder or add elements. Use a `createNextOrder` helper:

```lua
local function createNextOrder(): () -> number
    local layoutOrder = 0

    return function()
        layoutOrder += 1
        return layoutOrder
    end
end

return createNextOrder
```

Usage:

```lua
local function TitleButtons()
    local nextOrder = createNextOrder()

    return e("Frame", {}, {
        UIListLayout = e("UIListLayout", { ... }),

        Minimize = e("TextButton", { LayoutOrder = nextOrder(), ... }),
        Maximize = e("TextButton", { LayoutOrder = nextOrder(), ... }),
        Close = e("TextButton", { LayoutOrder = nextOrder(), ... }),
    })
end
```

## Use `and` to conditionally render

`x and y` returns `x` if falsy, `y` otherwise. `false` is a valid (non-rendering) React node. Combine them:

```lua
Store = storeOpen and e(Store),
```

Prefer `if`-expressions only when `and` doesn't fit, or when you have a real value for both branches.

## `useToggleState`

Opening/closing menus and hover states come up constantly. Package them:

```lua
local function useToggleState(default: boolean): {
    on: boolean,
    enable: () -> (),
    disable: () -> (),
    toggle: () -> (),
}
    local toggled, setToggled = React.useState(default)

    local enable = React.useCallback(function()
        setToggled(true)
    end, {})

    local disable = React.useCallback(function()
        setToggled(false)
    end, {})

    local toggle = React.useCallback(function()
        setToggled(function(currentToggled)
            return not currentToggled
        end)
    end, {})

    return {
        on = toggled,
        enable = enable,
        disable = disable,
        toggle = toggle,
    }
end
```

Usage:

```lua
local storeOpen = useToggleState(false)
local storeButtonHovered = useToggleState(false)

e("TextButton", {
    BackgroundColor3 = if storeButtonHovered.on then Colors.white else Colors.gray,
    [React.Event.Activated] = storeOpen.enable,
    [React.Event.MouseEnter] = storeButtonHovered.enable,
    [React.Event.MouseLeave] = storeButtonHovered.disable,
})
```

Bonus: memoized callbacks mean React doesn't disconnect/reconnect events every render.

## `createUniqueKey`

Every React child needs a key. Array-index children will thrash mount/unmount cycles when the list changes. Use named keys:

```lua
return e("Frame", {}, {
    Minimize = showMinimize and e(Button, { ... }),
    Maximize = showMaximize and e(Button, { ... }),
    Close = showClose and e(Button, { ... }),
})
```

For dynamic lists where entries may collide, use `createUniqueKey`:

```lua
local function createUniqueKey(): (string) -> string
    local names = {}

    return function(name)
        if names[name] == nil then
            names[name] = 1
            return name
        else
            while true do
                names[name] += 1
                local finalName = `{name}_{names[name]}`

                if names[finalName] == nil then
                    return finalName
                end
            end
        end
    end
end
```

Behavior:

```lua
local uniqueKey = createUniqueKey()
uniqueKey("Dog") -- "Dog"
uniqueKey("Cat") -- "Cat"
uniqueKey("Dog") -- "Dog_2"
```

## `useClock`

For frame-by-frame animations, combine `TweenService:GetValue` with a clock binding:

```lua
local function useClock(): React.Binding<number>
    local clockBinding, setClockBinding = React.useBinding(0)

    React.useEffect(function()
        local stepConnection = RunService.PostSimulation:Connect(function(delta)
            setClockBinding(clockBinding:getValue() + delta)
        end)

        return function()
            stepConnection:Disconnect()
        end
    end, {})

    return clockBinding
end
```

Usage:

```lua
local function Flash()
    local clockBinding = useClock()

    return e("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromScale(1, 1),

        -- Type the mapped parameter explicitly in strict mode.
        BackgroundTransparency = clockBinding:map(function(clock: number)
            return math.clamp(clock / FADE_IN_TIME, 0, 1)
        end)
    })
end
```

## `useEventConnection`

```lua
local function useEventConnection<T...>(
    event: RBXScriptSignal<T...>,
    callback: (T...) -> (),
    dependencies: { any }
)
    local cachedCallback = React.useMemo(function()
        return callback
    end, dependencies)

    React.useEffect(function()
        local connection = event:Connect(cachedCallback)

        return function()
            connection:Disconnect()
        end
    end, { event, cachedCallback } :: { unknown })
end
```

Usage:

```lua
useEventConnection(humanoid.Died, function()
    print(`You died! You did {damage} damage before you did.`)
end, { damage })
```

## Turn on DEV mode in Studio

`_G.__DEV__` catches bugs Luau can't — e.g. calling state setters during render — and provides better stack traces. It has a perf cost, so gate it on Studio:

```lua
_G.__DEV__ = game:GetService("RunService"):IsStudio()
```

Put this at the top of your React Wally package source (or re-apply it after every `wally install`).

## Expose native properties through a `native` table

Don't spread arbitrary props onto a wrapper component. Accept a `native` prop instead:

```lua
local function Pane(props: {
    native: { [any]: any }?,
    children: React.ReactNode,
})
    return e("Frame", join({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
    }, props.native), props.children)
end
```

Used as:

```lua
e(Pane, {
    native = {
        Position = UDim2.fromScale(0.5, 0.5),
    }
})
```

Reasons over prop-spreading:
- No list of omitted fields to maintain as you add component-specific props.
- Invalid Roblox properties still get through Luau — `native` keeps the typed surface clean.
- No collisions if Roblox adds a property with the same name as yours.

## Split components into presentational + connected

A component that fetches its own data can't be rendered in a Hoarcekat story. Split:

```lua
-- Pure: takes data, renders it.
local function Leaderboard(props: {
    entries: { [number]: number },
})
    local children = {}

    for userId, score in props.entries do
        children[`Player_{userId}`] = e(LeaderboardEntry, {
            userId = userId,
            score = score,
        })
    end

    return e("Frame", { ... }, children)
end

-- Connected: fetches data, renders the pure one.
local function LeaderboardConnected()
    local entries, setEntries = React.useState({})

    React.useEffect(function()
        task.spawn(function()
            setEntries(ReplicatedStorage.Remotes.GetLeaderboardEntries:InvokeServer())
        end)
    end, {})

    return e(Leaderboard, { entries = entries })
end
```

Export both. Stories and tests use the pure one with mock data.

## Use Context, not Rodux

React Context covers the same ground Rodux/Redux used to, with less boilerplate and colocated feature ownership. Create one context per feature — see the [context template](#context-template-2026) below for the exact shape.

Put the state logic in a provider component. Follow the same presentational/connected split for providers when you want easy mocking.

Consumers:

```lua
local function CoinsCount()
    local coinsContext = React.useContext(CoinsContext)

    return e("TextLabel", {
        Text = coinsContext.coins,
    })
end
```

## `ContextStack`

Nested providers become unreadable fast. Flatten with:

```lua
local function ContextStack(props: {
    providers: {
        React.ComponentType<{
            children: React.ReactNode,
        }>
    },

    children: React.ReactNode,
})
    local mostRecent = e(props.providers[#props.providers], {}, props.children)

    for providerIndex = #props.providers - 1, 1, -1 do
        mostRecent = e(props.providers[providerIndex], {}, mostRecent)
    end

    return mostRecent
end
```

Usage:

```lua
e(ContextStack, {
    providers = {
        ThemesContext.Provider,
        CoinsContext.Provider,
        SoundContext.Provider,
    }
})
```

## Context template (2026)

`Context.Provider`'s `value` does not type-check reliably, and React compares context by reference — not shallow equality — so an un-memoized value will re-render every consumer below it. Use this template:

```lua
export type ContextType = {
    coins: number,
}

local Context = React.createContext<<ContextType>>({
    coins = 0,
})

local function Provider(props: {
    children: React.Node,
})
    local coins, setCoins = React.useState(0)

    useEventConnection(Remotes.UpdateCoins.OnClientEvent, setCoins, {})

    local value = React.useMemo(function(): ContextType
        return {
            coins = coins,
        }
    end, { coins })

    return e(Context.Provider, {
        value = value,
    }, props.children)
end

return {
    Context = Context,
    Provider = Provider,
}
```

Two things to note:

**Explicit type instantiation.** `React.createContext<<ContextType>>({ ... })` replaces the older `local default: ContextType = { ... }` workaround. Same safety, less noise. Don't reach for `:: ContextType` casts — `::` performs only narrow validation and regularly hurts soundness (e.g. `:: number` silently strips `?`, and casting `{}` to an `Object` type is allowed). Avoid `::` wherever you can.

**Memoize the value.** React checks context equality by reference, not shallow. In a stack like `ContextA > ContextB > ContextC > View`, an update in `ContextA` will re-render everything below it — and if `ContextB`/`ContextC` rebuild their value tables inline, every consumer of those contexts re-renders too, even through `React.memo`. Wrapping `value` in `useMemo` with the right dependency list prevents this. In practice this can drop editor frame times from 16ms to 2–4ms.

## `createElement` takes variadic children

The signature is actually:

```lua
createElement(component, props, children...)
```

You can pass multiple children tables and React will merge them. This keeps static and dynamic children together cleanly:

```lua
e("Frame", {}, {
    UIListLayout = e("UIListLayout"),
}, entries)
```

Beats `join({ UIListLayout = ... }, entries)` or shoehorning `entries.UIListLayout = ...`.

## TextBoxes are weird — use a wrapper

The web-style controlled input pattern (`Text = value` + `onChange` setting state) performs badly on low-end devices and breaks max-length clamping. When React sees the Text prop unchanged, it skips the update, even though Roblox already applied the user's keystroke.

Use a wrapper that tracks the value in a ref and only forces the instance text when clamping:

```lua
local function TextBox(
    props: {
        initialText: string?,
        onTextChange: ((string) -> ())?,
        maxLength: number?,

        native: { [string]: any }?,
        children: React.ReactNode?,
    }
)
    local currentTextRef = React.useRef(props.initialText)

    React.useEffect(function()
        currentTextRef.current = props.initialText
    end, { props.initialText })

    local onTextChange = React.useCallback(function(textBox: TextBox)
        local text = textBox.Text

        if text == currentTextRef.current then
            return
        end

        if props.maxLength ~= nil and #text > props.maxLength then
            textBox.Text = text:sub(1, props.maxLength)
            return
        end

        currentTextRef.current = text

        if props.onTextChange ~= nil then
            props.onTextChange(text)
        end
    end, { props.onTextChange, props.maxLength or 0 } :: { unknown })

    return e(
        "TextBox",
        join({
            Text = props.initialText or "",
            [React.Change.Text] = onTextChange,
        }, props.native),
        props.children
    )
end
```

## You probably don't need bindings

Bindings are a Roact carryover. Rule of thumb: if the value doesn't change roughly every frame, use state. The perf win over state in `react-lua` is much smaller than it was in legacy Roact, and bindings are more limited — you can't conditionally render from them or easily react to changes.

Default to no bindings. Reach for them only when you measure a real problem (e.g. `useClock` makes sense because it updates every frame).

## Mount to a dummy, portal to the real target

Don't do this:

```lua
local tree = ReactRoblox.createTree(PlayerGui)
tree:render(e(App))
```

React takes full ownership of `PlayerGui` and can wipe things it doesn't own — mobile controls, `TouchTransmitter` objects, etc. Once an instance is in the data model, treat it as forever taintable.

Instead, mount to a dummy and portal in:

```lua
local tree = ReactRoblox.createTree(Instance.new("Folder"))
tree:render(ReactRoblox.createPortal(e(App), PlayerGui))
```
