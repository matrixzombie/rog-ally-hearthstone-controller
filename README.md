# ROG Ally Hearthstone Controller Mapper

Script: `RogAlly_Hearthstone_Controller.ahk`

A public, unofficial AutoHotkey v2 controller mapper for playing standard or arena Hearthstone on an ASUS ROG Ally. It is designed for players using the accessibility mod documented at [hearthstoneaccess.com](https://hearthstoneaccess.com/).

Keyboard shortcut source: https://hearthstoneaccess.com/commands.html

> This project is not affiliated with Blizzard, ASUS, AutoHotkey, or the accessibility mod team/community. It is just a controller mapping script intended to make the mod's existing keyboard commands comfortable from the ROG Ally in Gamepad Mode.

## Requirements

- ASUS ROG Ally or another Xbox/XInput-style controller
- Armoury Crate / Command Center set to **Gamepad Mode**
- [AutoHotkey v2](https://www.autohotkey.com/)
- Hearthstone with the accessibility mod installed

## Research-based design choices

I polished the layout using these controller/accessibility principles:

- Windows/Xbox gamepad UI conventions map **D-pad/left stick to arrows/focus**, **A to select**, and **B to back**.
- Xbox accessibility guidance recommends avoiding mandatory rapid inputs, long holds, and complex simultaneous button sequences. This script uses simple taps for most actions and only a short deliberate hold for End Turn.
- Game Accessibility Guidelines recommend remappable/configurable controls and allowing the same input method everywhere. The script keeps everything on the controller while leaving key values editable near the top.
- Stick-clicks are comparatively awkward and easy to press accidentally on handhelds, so they are no longer required for important commands. They are optional duplicate info only.
- Frequent actions should be on easy controls: A/B/X/Y, D-pad/stick, and bumpers. Less frequent info is on LT/RT layers.

## Base battle layout

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
| View | F1 | Help for current screen/prompt |
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
| Go back/cancel if HA allows it | B |
| Help for the current prompt | View |

So there is no separate mulligan mode to toggle; use **X for Space** on cards, then **A for Enter** to finish.

## LT: your info/action layer

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
| View | O | Anomalies affecting current game |

## RT: opponent / shifted layer

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
| View | O | Anomalies affecting current game |

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

That duplication is intentional and matches common gamepad UI behavior: D-pad gives precise one-step navigation, while left stick is comfortable for longer browsing. The right stick adds read-only list helpers like Home/End and Shift+Up/Shift+Down, which are especially helpful for mulligan and card text. The important change is that **LB/RB are not duplicate Left/Right**; they are now the mod's high-value battle commands for previous/next valid play.

## Install/use

1. Install **AutoHotkey v2** on the ROG Ally.
2. Put Armoury Crate / Command Center controller mode in **Gamepad Mode**.
3. Run `HearthstoneAccess_RogAlly.ahk`.
4. Start Hearthstone with Hearthstone Access.
5. If Hearthstone is running as Administrator, run the script as Administrator too.
