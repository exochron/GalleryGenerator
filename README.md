# Gallery Generator

This library is designed for addon authors who wish to generate consistent screenshots for their image gallery.

## Installation

- Requires [LibStub](https://www.curseforge.com/wow/addons/libstub)

Just install this as a standalone addon from [CurseForge](https://www.curseforge.com/wow/addons/gallery-generator)
or [Wago](https://addons.wago.io/addons/gallerygenerator). You don't need to embedded or package it into your project.
A dependency link as a [used tool](https://legacy.curseforge.com/wow/addons/gallery-generator/relations/dependents) is appreciated though. :)

## Example

```LUA
local gg = LibStub("GalleryGenerator")
gg:TakeScreenshots(
    {
        -- First screenshot with open character frame
        function(api)
            api:BackScreen() -- hide game world with black screen

            ToggleCharacter("PaperDollFrame") -- show character frame
        end,
        -- second screenshot with reputation frame
        function(api)
            api:BackScreen(0, 1, 0) -- green screen

            api:PointAndClick(CharacterFrameTab2)
        end,
        -- third screenshot toggles and traverses player menu
        function(api)
            api:Click(CharacterFrameTab1) -- back to tab 1

            -- open player menu
            UnitPopup_OpenMenu("SELF", { fromPlayerFrame = true, unit = "player", })

            -- wait for menu and point to raid markers
            api:WaitAndPointOnMenuElement(1, 2, function()
                --wait again and point to skull marker
                api:WaitAndPointOnMenuElement(2, 1)
            end)
        end,
    },
    -- cleanup and revert previous states
    function(api)
        ToggleCharacter("PaperDollFrame") -- hide character frame
    end
)
```
More practical examples can be found here:
- [Favorite Contacts](https://github.com/exochron/Favorite-Contacts/blob/master/DevZone/Screenshot.lua)
- [Mount Journal Enhanced](https://github.com/exochron/MountJournalEnhanced/blob/master/DevZone/Screenshot.lua)
- [Toy Box Enhanced](https://github.com/exochron/ToyBoxEnhanced/blob/master/DevZone/Screenshot.lua)

## API

The library itself has only one external method called `TakeScreenshots`.

1. The first argument is a list of your preparation functions. A screenshot is triggered 1 Second after the end of each
   function.
2. With a further optional function as second argument, you can revert your UI back into the initial state.

Each function is provided with an internal API as first argument.

### `api:Point(targetFrame[, offsetX[, offsetY]])`

This places a virtual pointer icon central on the given frame.
It also triggers script handlers for OnEnter and all parent frames. Subsequently, it also triggers OnLeave.

- `targetFrame table|Frame` A frame to place the pointer onto
- `offsetX nil|number` Optional offset right of the center (negative for left)
- `offsetY nil|number` Optional offset up of the center (negative for down)

Returns:

- `table|TextureBase` Texture instance of pointer icon for own further customization

### `api:Click(targetFrame[, button])`

This triggers all cLick handlers on the given frame. (In
order: `OnMouseDown`, `OnMouseUp`, `PreClick`, `OnClick`, `PostClick`)

- `targetFrame table|Frame` Frame to trigger a click on
- `button nil|string` Optional mouse button identifier. Defaults to "LeftButton"

### `api:PointAndClick(targetFrame)`

A simple function to subsequently call `Point()` and `Click()`

- `targetFrame table|Frame` Frame to place the pointer on and trigger a LeftClick

Returns:

- `table|TextureBase` Texture instance of pointer icon for own further customization

### `api:Wait()`

This interrupts the internal Screenshot timer, so you can wait longer for your UI to finish loading.
You **HAVE TO** call `Continue()` on your own to process further!

### `api:Continue()`

This continues processing after a `Wait()` interruption.

### `api:BackScreen([red, green, blue])`

This shows a back screen to hide the game world.

- `red nil|number` Optional red component [0.0 - 1.0]
- `green nil|number` Optional green component [0.0 - 1.0]
- `blue nil|number` Optional blue component [0.0 - 1.0]

### `api:GetOpenMenuElement(menuIndex, elementIndex)`

This returns the n-th element frame of an open menu.

- `menuIndex number` Index number of open Menu (1=start menu, 2=first submenu, 3=second submenu...)
- `elementIndex number` Index number of element from the top. Spacer and divider do count as well.

### `api:WaitAndPointOnMenuElement(menuIndex, elementIndex, onDone, xOffset, yOffset)`

This interrupts the execution and waits for a menu element to be rendered. It also points onto the element.
You can chain `WaitAndPointOnMenuElement` in your `onDone` handler to traverse multiple submenus.
You need to `Continue()` in your own `onDone` function. If you don't provide a function, it continues automatically.

- `menuIndex number` Index number of open Menu (1=start menu, 2=first submenu, 3=second submenu...)
- `elementIndex number` Index number of element from the top. Spacer and divider do count as well.
- `onDone nil|function` Optional custom handling gets element frame as first parameter.
- `offsetX nil|number` Optional offset right of the element center (negative for left)
- `offsetY nil|number` Optional offset up of the element center (negative for down)

## Tips & Tricks

- You should use the english game client to take screenshots. So they are readable by probably the most users. (You can
  use a PTR client for that. ;))
- Use the `:BackScreen()` to hide the game world and to provide a nice background color for further processing.
- You can add your script and images into your project repository, but you should ignore them in your .pkgmeta file. So
  it doesn't bloat the final zip unnecessarily.
- After you have taken some nice shots. You can automate copying and cropping the files a bit as
  well. [Read further in the project wiki.](https://github.com/exochron/GalleryGenerator/wiki/Further-Processing)
