# FlyingBroom

## Input Controls

The controls can be found in the [Context Actions](/src/Flying%20Broom/ToolScripts/ContextActions.client.luau) script.<br>
They are also listed here below:
| Input | Name | Function |
| :--- | :--- | :--- |
| MouseClick | Thrust | When holding the broom, move toward the mouse with an initial velocity.<br>When riding the broom, move toward the mouse with a maximum velocity of 2 × (max ride velocity) for 0.3 seconds. |
| R | Ride / Mount | Mount or unmount the broom. |
| E | Ascend | When mounted, fly upwards. |
| Q | Descend | When mounted, fly downwards. |
| F | Fly / Antigravity | When mounted, switches antigravity on or off. |
| X | Store | Store or unstore the broom. |

Touch buttons for some of the controls are generated on mobile devices.

## Configurations

You can configure various settings in the Tool's attributes.<br>
They are set in the Tool's [meta file](/src/Flying%20Broom/init.meta.json).

## Other features

Activate Shift Lock to rotate the character while riding the broom.<br>
This allows some variations in sitting poses without the use of animations.

## Credits

Original Broom gear [here](https://www.roblox.com/catalog/36913601/Broom).<br>
Original Raven Witch Hat [here](https://www.roblox.com/catalog/1117736987/Raven-Witch-Hat).<br>
Sound effects from Roblox.<br>
Some features and designs inspired by [Wandering Witch: The Journey of Elaina](https://ga.sbcr.jp/sp/tabitabi/).<br>
Some coding help from [cozywitchcraft](https://github.com/cozywitchcraft) and [heksi](https://github.com/Heksii) for CFrame Utility.

# Rojo

The following contents are generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.4.1.

## Getting Started

To build the place from scratch, use:

```bash
rojo build -o "FlyingBroom.rbxlx"
```

Next, open `FlyingBroom.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).
