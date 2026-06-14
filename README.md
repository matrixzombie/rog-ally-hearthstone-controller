# ROG Ally Hearthstone Controller Mapper

Script: `RogAlly_Hearthstone_Controller.ahk`

A public, unofficial AutoHotkey v2 controller mapper for playing standard, arena, or Battlegrounds Hearthstone on an ASUS ROG Ally or Xbox/XInput-style controller. It is designed for players using the accessibility mod documented at [hearthstoneaccess.com](https://hearthstoneaccess.com/).

Keyboard shortcut source: https://hearthstoneaccess.com/commands.html

> This project is not affiliated with Blizzard, ASUS, AutoHotkey, or the accessibility mod team/community. It is just a controller mapping script intended to make the mod's existing keyboard commands comfortable from the ROG Ally in Gamepad Mode.

## Requirements

- ASUS ROG Ally or another Xbox/XInput-style controller
- If using the ROG Ally built-in controls: Armoury Crate / Command Center set to **Gamepad Mode**
- [AutoHotkey v2](https://www.autohotkey.com/)
- Hearthstone with the accessibility mod installed

## Research-based design choices

I polished the layout using these controller/accessibility principles:

- Windows/Xbox gamepad UI conventions map **D-pad/left stick to arrows/focus**, **A to select**, and **B to back**.
- Xbox accessibility guidance recommends avoiding mandatory rapid inputs, long holds, and complex simultaneous button sequences. This script uses simple taps for most actions and only short deliberate holds for mode toggle and dangerous actions like End Turn or tavern upgrade.
- Game Accessibility Guidelines recommend remappable/configurable controls and allowing the same input method everywhere. The script keeps everything on the controller while leaving key values editable near the top.
- Stick-clicks are comparatively awkward and easy to press accidentally on handhelds, so they are no longer required for important commands. They are optional duplicate info only.
- Frequent actions should be on easy controls: A/B/X/Y, D-pad/stick, and bumpers. Less frequent info is on LT/RT layers.

## Modes

The script starts in **Standard/Arena mode**.

| Control | Action |
|---|---|
| Hold View for about 0.7 seconds | Toggle between Standard/Arena and Battlegrounds mode |
| Tap View | Help for the current screen/prompt |

A tray notification and beep confirm the mode change.

## Xbox controller support

Yes, this should work with a connected Xbox controller too. The ROG Ally in Gamepad Mode and Xbox controllers both expose the standard XInput-style layout to Windows:

- A/B/X/Y are Joy1/Joy2/Joy3/Joy4
- LB/RB are Joy5/Joy6
- View/Menu are Joy7/Joy8
- L3/R3 are Joy9/Joy10
- D-pad is JoyPOV
- Left stick is JoyX/JoyY
- Right stick is normally JoyU/JoyR
- LT/RT normally share JoyZ

The script now polls controller numbers **1 through 4**, so it can accept input from either the Ally's built-in controls or a connected Xbox controller. If Windows gives you duplicate/unwanted input, edit this line near the top of the script:

```ahk
ControllerNumbers := [1, 2, 3, 4]
```

Examples:

```ahk
ControllerNumbers := [1] ; only the first controller
ControllerNumbers := [2] ; only the second controller
```

## Standard/Arena base battle layout

| ROG Ally control | Sent key | Action |
|---|---:|---|
| D-pad / left stick | Arrow keys | Read previous/next item or line |
| Right stick left/right | Home / End | Read first / last item in the list |
| Right stick up/down | Shift+Up / Shift+Down | Repeat current line / read rest of current item |
| A | Enter | Play card / attack / select target / confirm |
| B | Backspace | Cancel current action / go back |
| X | Space | Context toggle: mulligan keep/replace; emotes/squelch on hero |
| Y | B | Look at your minions |
| LB | Shift+Tab | Previous valid play |
| RB | Tab | Next valid play |
| Tap View | F1 | Help for current screen/prompt |
| Hold View | Script mode toggle | Switch Standard/Arena ↔ Battlegrounds |
| Tap Menu/Start | Y | Play history log |
| Hold Menu/Start | E | End turn |
| L3/R3 | V / B | Optional duplicate: your hero / your minions |

## Mulligan phase

The accessibility mod does not list separate mulligan-only commands; the mulligan uses the normal horizontal-list/menu commands. The script covers those:

| Mulligan task | Control |
|---|---|
| Move between offered cards | D-pad/left stick left/right |
| Read more/previous text for focused card | D-pad/left stick down/up |
| Toggle whether focused card is kept/replaced | X |
| Finish/confirm mulligan after choosing cards | A |
| Jump to first/last offered card | Right stick left/right |
| Repeat/read rest of focused card text | Right stick up/down |
| Go back/cancel if the mod allows it | B |
| Help for the current prompt | View |

So there is no separate mulligan mode to toggle; use **X for Space** on cards, then **A for Enter** to finish.

## Battlegrounds mode

Hold **View** to switch to Battlegrounds mode. The design keeps normal navigation the same, but moves Battlegrounds recruit-phase actions like refresh/freeze/gold/tavern info onto comfortable controls.

### Battlegrounds base layout

| Control | Sent key | Action |
|---|---:|---|
| D-pad / left stick | Arrow keys | Read previous/next item or line |
| Right stick left/right | Home / End | Read first / last item in the list |
| Right stick up/down | Shift+Up / Shift+Down | Repeat current line / read rest of current item |
| A | Enter | Buy/sell minion, confirm, select |
| B | Backspace | Go back / stop leaderboard reading |
| X | C | Read hand |
| Y | G | Read minions for sale |
| LB | Shift+F | Freeze/unfreeze tavern without confirmation |
| RB | Shift+R | Refresh tavern without confirmation |
| Tap Menu/Start | E | Read seconds left in recruit phase |
| Hold Menu/Start | Shift+U | Upgrade tavern without confirmation |
| Tap View | F1 | Help |
| Hold View | Script mode toggle | Switch Battlegrounds ↔ Standard/Arena |

### Battlegrounds LT: your/shop layer

Hold **LT** and press:

| Control | Sent key | Action |
|---|---:|---|
| A | A | Read gold |
| B | P | Read your hero power |
| X | Space | Select minion to reorder |
| Y | Shift+U | Upgrade tavern without confirmation |
| LB | F | Freeze/unfreeze tavern, with confirmation |
| RB | R | Refresh tavern, with confirmation/cost readout |
| D-pad Left | S | Read your secrets or quests |
| D-pad Right | T | Read tavern tier and Bartender |
| D-pad Up | I | Focused card keywords |
| D-pad Down | K | Focused card enchantments/stats |
| Right stick Left | Q | Read your trinkets if applicable |
| Right stick Right | D | Read buddy meter / Hero Buddy card if applicable |
| Right stick Up | W | Read your quest reward if applicable |
| Right stick Down | O | Read minion families/races and anomalies |
| Tap Menu/Start | D | Read buddy meter / Hero Buddy card if applicable |
| Hold Menu/Start | U | Upgrade tavern, with confirmation |
| Tap View | O | Read minion families/races and anomalies |

### Battlegrounds RT: opponent/leaderboard layer

Hold **RT** and press:

| Control | Sent key | Action |
|---|---:|---|
| A | Shift+P | Read opponent hero power during combat |
| B | M | Read your leaderboard stats; Backspace stops reading |
| X | Shift+S | Read opponent secrets/quests during combat |
| Y | N | Read next opponent's leaderboard stats |
| LB | Shift+Q | Read opponent trinkets if applicable |
| RB | Shift+W | Read opponent quest reward if applicable |
| D-pad Left | L | Read leaderboard from top; Backspace stops reading |
| D-pad Right | Shift+N | Quickly read next opponent stats without changing focus |
| D-pad Up | Shift+M | Quickly read your stats without changing focus |
| D-pad Down | N | Read next opponent's leaderboard stats |
| Right stick Left | Shift+Q | Read opponent trinkets if applicable |
| Right stick Right | Shift+P | Read opponent hero power during combat |
| Right stick Up | Shift+W | Read opponent quest reward if applicable |
| Right stick Down | Shift+S | Read opponent secrets/quests during combat |
| Tap Menu/Start | N | Read next opponent's leaderboard stats |
| Tap View | O | Read minion families/races and anomalies |

Safety notes:

- No-confirm refresh/freeze are on the bumpers because they are high-frequency recruit-phase actions.
- No-confirm upgrade is available two ways: **LT+Y** for fast use, or **hold Menu/Start** to reduce accidents.
- Confirming versions are still available on LT+LB, LT+RB, and LT+hold Menu/Start.

### Battlegrounds command coverage

Commands from the site's Battlegrounds list are covered as follows:

| Official command | Controller mapping |
|---|---|
| Read minions for sale `G` | Y |
| Read hand `C` | X |
| Read gold `A` | LT+A |
| Keywords `I` | LT+D-pad Up |
| Enchantments/stats `K` | LT+D-pad Down |
| Tavern tier/Bartender `T` | LT+D-pad Right |
| Upgrade tavern `U` | LT+hold Menu/Start |
| Upgrade tavern without confirmation `Shift+U` | LT+Y or hold Menu/Start |
| Freeze/unfreeze `F` | LT+LB |
| Freeze/unfreeze without confirmation `Shift+F` | LB |
| Refresh tavern `R` | LT+RB |
| Refresh tavern without confirmation `Shift+R` | RB |
| Your hero power `P` | LT+B |
| Opponent hero power `Shift+P` | RT+A or RT+right stick Right |
| Buddy meter / Hero Buddy `D` | LT+right stick Right or LT+tap Menu |
| Buy/sell minion `Enter` | A |
| Select minion to reorder `Space` | LT+X |
| Reorder selected minion `Left/Right/Home/End` | D-pad/left stick, right stick left/right in base layer |
| Your leaderboard stats `M` | RT+B |
| Quick your stats `Shift+M` | RT+D-pad Up |
| Next opponent stats `N` | RT+Y, RT+D-pad Down, or RT+tap Menu |
| Quick next opponent stats `Shift+N` | RT+D-pad Right |
| Leaderboard from top `L` | RT+D-pad Left |
| Minion families/races/anomalies `O` | LT+right stick Down or trigger+tap View |
| Seconds left `E` | Tap Menu/Start |
| Your secrets/quests `S` | LT+D-pad Left |
| Opponent secrets/quests `Shift+S` | RT+X or RT+right stick Down |
| Your quest reward `W` | LT+right stick Up |
| Opponent quest reward `Shift+W` | RT+RB or RT+right stick Up |
| Your trinkets `Q` | LT+right stick Left |
| Opponent trinkets `Shift+Q` | RT+LB or RT+right stick Left |

Number-row shortcuts for jumping directly to positions are not individually mapped because there are ten of them and they do not fit cleanly on a comfortable controller layout; use arrows/Home/End instead.

## Standard/Arena LT: your info/action layer

Hold **LT** and press:

| Control | Sent key | Action |
|---|---:|---|
| A | A | Your mana/corpses |
| X | C | Your hand |
| Y | B | Your minions |
| B | V | Your hero |
| LB | R | Your hero power |
| RB | W | Your weapon |
| D-pad Left | S | Your secrets |
| D-pad Right | D | Your deck count |
| D-pad Up | I | Focused card keywords |
| D-pad Down | K | Focused minion attack/health/enchantments |
| Tap Menu/Start | T | Trade or forge focused card if possible |
| Tap View | O | Anomalies affecting current game |
| Hold View | Script mode toggle | Switch Standard/Arena ↔ Battlegrounds |

## Standard/Arena RT: opponent / shifted layer

Hold **RT** and press:

| Control | Sent key | Action |
|---|---:|---|
| A | Shift+A | Opponent mana/corpses |
| X | Shift+C | Count opponent's hand |
| Y | G | Opponent minions |
| B | F | Opponent hero |
| LB | Shift+R | Opponent hero power |
| RB | Shift+W | Opponent weapon |
| D-pad Left | Shift+S | Opponent secrets |
| D-pad Right | Shift+D | Opponent deck count |
| D-pad Up | PageUp | Original card lines |
| D-pad Down | PageDown | Related card lines |
| Tap Menu/Start | Space | Emotes/squelch when focused on a hero |
| Tap View | O | Anomalies affecting current game |
| Hold View | Script mode toggle | Switch Standard/Arena ↔ Battlegrounds |

## Safety options in the script

Near the top of `RogAlly_Hearthstone_Controller.ahk`:

```ahk
EnableStickClickInfo := true
EnableAttackFaceShortcuts := false
```

- Set `EnableStickClickInfo := false` if stick-clicks are uncomfortable or accidental.
- `EnableAttackFaceShortcuts` is off by default because Shift+F/Ctrl+F can make attacks you did not intend. If enabled:
  - RT+L3 = currently selected minion attacks opponent hero
  - RT+R3 = all minions attack opponent hero

## Why D-pad and stick both navigate

That duplication is intentional and matches common gamepad UI behavior: D-pad gives precise one-step navigation, while left stick is comfortable for longer browsing. The right stick adds read-only list helpers like Home/End and Shift+Up/Shift+Down, which are especially helpful for mulligan and card text. The important change is that **LB/RB are not duplicate Left/Right**: in Standard/Arena they are previous/next valid play, and in Battlegrounds they are freeze/refresh.

## Install/use

1. Install **AutoHotkey v2** on the ROG Ally or Windows PC.
2. If using the Ally built-in controls, put Armoury Crate / Command Center controller mode in **Gamepad Mode**.
3. Run `RogAlly_Hearthstone_Controller.ahk`.
4. Start Hearthstone with the accessibility mod.
5. If Hearthstone is running as Administrator, run the script as Administrator too.
