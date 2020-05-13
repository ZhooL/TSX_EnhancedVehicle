# TSX_EnhancedVehicle
This is a Mod for Farming Simulator 19. It adds shuttle shift, differential locks, wheel drive modes and improved hydraulics controls to your vehicle. It also shows more vehicle details on the HUD.

**NOTE: The only source of truth is: https://github.com/ZhooL/TSX_EnhancedVehicle. The second valid download location is: https://www.modhoster.de/mods/enhancedvehicle. All other download locations are not validated by me - so handle with care.**

*(c) 2018-2019 by ZhooL. Be so kind to credit me when using this mod or the source code (or parts of it) somewhere.*
License: https://creativecommons.org/licenses/by-nc-sa/4.0/

## Default Keybindings
| Key | Action |
| --  | --     |
| <kbd>Space</kbd> | (shuttle shift) switch driving direction |
| <kbd>L Ctrl</kbd>+<kbd>Space</kbd> | turn shuttle shift functionality on/off |
| <kbd>Insert</kbd> / <kbd>Delete</kbd> | switch driving direction directly to forward/backward |
| <kbd>End</kbd> | turn parking brake on/off |
| <kbd>Num 7</kbd> | enable/disable front axle differential lock |
| <kbd>Num 8</kbd> | enable/disable back axle differential lock |
| <kbd>Num 9</kbd> | switch wheel drive mode between 4WD (four wheel drive) or 2WD (two wheel drive) |
| <kbd>Num /</kbd> | reset mods HUD elements to its default position<br>use this if you messed up the config or changed the GUI scale |
| <kbd>Num *</kbd> | reload XML config from disk to show modifications immediately without restarting the complete game |
| <kbd>L Alt</kbd>+<kbd>1</kbd> | rear attached devices up/down |
| <kbd>L Alt</kbd>+<kbd>2</kbd> | rear attached devices on/off |
| <kbd>L Alt</kbd>+<kbd>3</kbd> | front attached devices up/down |
| <kbd>L Alt</kbd>+<kbd>4</kbd> | front attached devices on/off |

## What this mod does
* When the game starts, it changes all "motorized" and "controllable" vehicles on the map to default settings: wheel drive mode to "all-wheel (4WD)" and deactivation of both differentials.
* Add a shuttle shift (incl. parking brake) functionality. If enabled you have to select a driving direction, and the vehicle will only drive in that direction if the acceleration key is pressed.
* On HUD it displays:
  * An indicator for shuttle shift status.
  * Damage values in % for controlled vehicle and all its attachments.
  * Fuel fill level for Diesel and AdBlue and the current fuel usage rate<sup>1</sup>.
  * The current status of the differential locks and wheel drive mode.
  * The current engine RPM and temperature<sup>1</sup>.
  * The current mass of the vehicle and the total mass<sup>1</sup> of vehicle and all its attachments and loads.
* Keybindings can be changed in the game options menu.
* If mod 'keyboardSteeringMogli' is detected, some HUD elements are moved a bit to avoid overlap.
* Vehicles without AdBlue/DEF will produce more black'n'blue exhaust smoke.

**<sup>1</sup> In multiplayer games, all clients, except the host, won't display the fuel usage rate, engine temperature and mass correctly due to GIANTS Engine fail**

## What this mod doesn't do
* Work on consoles. Buy a PC for proper gaming.
* Multi-language support (right now it's a mix of German and English)

# The rest
**Make Strohablage great again!**
https://zhool.de
https://github.com/ZhooL/TSX_EnhancedVehicle
