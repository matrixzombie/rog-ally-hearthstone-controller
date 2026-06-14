#Requires AutoHotkey v2.0
#SingleInstance Force
; ASUS ROG Ally gamepad-mode controller mapper for Hearthstone
; Keyboard shortcut source: https://hearthstoneaccess.com/commands.html
;
; Design goals:
; - Keep the Ally in Gamepad Mode.
; - Send keys only while Hearthstone is the active window.
; - Use standard controller conventions: A = confirm, B = back/cancel,
;   D-pad/left stick = focus/list navigation, bumpers = rapid cycling.
; - Use LT for "my info" and RT for "opponent/shifted info".
; - Avoid requiring stick-clicks for critical actions.

SendMode("Input")
SetWorkingDir(A_ScriptDir)

; -------------------- Tunables --------------------
global HearthstoneExe := "ahk_exe Hearthstone.exe"
global PollMs := 20
global AxisDeadzone := 30          ; left-stick deadzone around 50 on a 0-100 axis
global RightStickDeadzone := 35    ; right-stick utility deadzone
global TriggerLow := 35            ; JoyZ below this = LT held
global TriggerHigh := 65           ; JoyZ above this = RT held
global RepeatInitialMs := 280
global RepeatEveryMs := 95
global EndTurnHoldMs := 450        ; hold Menu/Start this long to send End Turn

; Stick-clicks are awkward on handhelds and can happen accidentally while steering.
; They are therefore only duplicate/safe info by default, and can be disabled.
global EnableStickClickInfo := true

; Powerful "attack face" shortcuts are useful but too easy to fire by mistake on a
; controller. Leave off unless you specifically want RT+L3/RT+R3 to attack face.
global EnableAttackFaceShortcuts := false

; -------------------- Accessibility mod shortcuts --------------------
; Gameplay/list navigation
KPrevItem := "{Left}"
KNextItem := "{Right}"
KPrevLine := "{Up}"
KNextLine := "{Down}"
KFirstItem := "{Home}"
KLastItem := "{End}"
KRepeatCurrentLine := "+{Up}"
KReadRestOfItem := "+{Down}"
KNextValidPlay := "{Tab}"
KPrevValidPlay := "+{Tab}"
KSelect := "{Enter}"
KCancel := "{Backspace}"
KEndTurn := "e"

; Standard/arena battle info
KMyMana := "a"
KOppMana := "+a"
KMyHand := "c"
KOppHandCount := "+c"
KMyMinions := "b"
KOppMinions := "g"
KMyHero := "v"
KOppHero := "f"
KMyHeroPower := "r"
KOppHeroPower := "+r"
KMyWeapon := "w"
KOppWeapon := "+w"
KMySecrets := "s"
KOppSecrets := "+s"
KMyDeckCount := "d"
KOppDeckCount := "+d"
KKeywords := "i"
KEnchantments := "k"
KTradeForge := "t"
KPlayHistory := "y"
KAnomalies := "o"
KRelatedCard := "{PgDn}"
KOriginalCard := "{PgUp}"
KCurrentMinionAttackHero := "^f"
KAllMinionsAttackHero := "+f"
KEmotes := "{Space}"

; Global
KHelp := "{F1}"

; -------------------- Internal state --------------------
global ButtonStates := Map()
global RepeatStates := Map()
global HoldStates := Map()

SetTimer(PollController, PollMs)
TrayTip("ROG Ally Hearthstone mapper", "Loaded. Gamepad Mode + Hearthstone active window required.", 3)
return

IsHearthstoneActive() {
    global HearthstoneExe
    return WinActive(HearthstoneExe) || WinActive("Hearthstone")
}

ResetStates() {
    global ButtonStates, RepeatStates, HoldStates
    ButtonStates := Map()
    for , st in RepeatStates {
        st.held := false
        st.start := 0
        st.last := 0
    }
    for , st in HoldStates {
        st.held := false
        st.start := 0
        st.sent := false
    }
}

SendKey(sendText) {
    if (sendText != "")
        Send(sendText)
}

PressedEdge(id, pressed) {
    global ButtonStates
    wasPressed := ButtonStates.Has(id) ? ButtonStates[id] : false
    ButtonStates[id] := pressed
    return pressed && !wasPressed
}

HandleTap(id, pressed, sendText) {
    if (PressedEdge(id, pressed))
        SendKey(sendText)
}

HandleRepeat(id, pressed, sendText) {
    global RepeatStates, RepeatInitialMs, RepeatEveryMs
    now := A_TickCount
    if (!RepeatStates.Has(id))
        RepeatStates[id] := {held:false, start:0, last:0}
    st := RepeatStates[id]

    if (pressed) {
        if (!st.held) {
            SendKey(sendText)
            st.held := true
            st.start := now
            st.last := now
        } else if (((now - st.start) >= RepeatInitialMs) && ((now - st.last) >= RepeatEveryMs)) {
            SendKey(sendText)
            st.last := now
        }
    } else {
        st.held := false
        st.start := 0
        st.last := 0
    }
}

HandleTapOrHold(id, pressed, tapText, holdText, holdMs) {
    ; Stores tap/hold action at press time, so changing LT/RT while holding Menu
    ; does not change what happens when the button is released.
    global HoldStates
    now := A_TickCount
    if (!HoldStates.Has(id))
        HoldStates[id] := {held:false, start:0, sent:false, tapText:"", holdText:""}
    st := HoldStates[id]

    if (pressed) {
        if (!st.held) {
            st.held := true
            st.start := now
            st.sent := false
            st.tapText := tapText
            st.holdText := holdText
        } else if (!st.sent && st.holdText != "" && ((now - st.start) >= holdMs)) {
            SendKey(st.holdText)
            st.sent := true
            SoundBeep(900, 45)
        }
    } else {
        if (st.held && !st.sent && st.tapText != "")
            SendKey(st.tapText)
        st.held := false
        st.start := 0
        st.sent := false
        st.tapText := ""
        st.holdText := ""
    }
}

PollController(*) {
    global AxisDeadzone, RightStickDeadzone, TriggerLow, TriggerHigh, EndTurnHoldMs
    global EnableStickClickInfo, EnableAttackFaceShortcuts
    global KPrevItem, KNextItem, KPrevLine, KNextLine, KFirstItem, KLastItem
    global KRepeatCurrentLine, KReadRestOfItem, KNextValidPlay, KPrevValidPlay
    global KSelect, KCancel, KEndTurn, KHelp
    global KMyMana, KOppMana, KMyHand, KOppHandCount, KMyMinions, KOppMinions
    global KMyHero, KOppHero, KMyHeroPower, KOppHeroPower, KMyWeapon, KOppWeapon
    global KMySecrets, KOppSecrets, KMyDeckCount, KOppDeckCount, KKeywords, KEnchantments
    global KTradeForge, KPlayHistory, KAnomalies, KRelatedCard, KOriginalCard
    global KCurrentMinionAttackHero, KAllMinionsAttackHero, KEmotes

    if (!IsHearthstoneActive()) {
        ResetStates()
        return
    }

    ; Xbox/ROG Ally buttons exposed through Windows joystick API:
    ; Joy1=A, Joy2=B, Joy3=X, Joy4=Y, Joy5=LB, Joy6=RB,
    ; Joy7=View, Joy8=Menu/Start, Joy9=L3, Joy10=R3.
    a := GetKeyState("Joy1")
    b := GetKeyState("Joy2")
    xBtn := GetKeyState("Joy3")
    yBtn := GetKeyState("Joy4")
    lb := GetKeyState("Joy5")
    rb := GetKeyState("Joy6")
    viewBtn := GetKeyState("Joy7")
    menuBtn := GetKeyState("Joy8")
    l3 := GetKeyState("Joy9")
    r3 := GetKeyState("Joy10")

    pov := GetKeyState("JoyPOV")
    povUp := (pov = 0 || pov = 4500 || pov = 31500)
    povRight := (pov = 9000 || pov = 4500 || pov = 13500)
    povDown := (pov = 18000 || pov = 13500 || pov = 22500)
    povLeft := (pov = 27000 || pov = 22500 || pov = 31500)

    lx := GetKeyState("JoyX")
    ly := GetKeyState("JoyY")
    stickLeft := (lx < 50 - AxisDeadzone)
    stickRight := (lx > 50 + AxisDeadzone)
    stickUp := (ly < 50 - AxisDeadzone)
    stickDown := (ly > 50 + AxisDeadzone)

    ; Right stick is read-only list utility: useful during mulligan/card reading.
    ; On most XInput devices via AHK's legacy joystick API, JoyU = right-stick X
    ; and JoyR = right-stick Y. If your Ally reports these differently, swap them.
    rx := GetKeyState("JoyU")
    ry := GetKeyState("JoyR")
    rightStickLeft := (rx < 50 - RightStickDeadzone)
    rightStickRight := (rx > 50 + RightStickDeadzone)
    rightStickUp := (ry < 50 - RightStickDeadzone)
    rightStickDown := (ry > 50 + RightStickDeadzone)

    ; XInput controllers normally expose LT/RT as a shared Z axis through the
    ; legacy joystick API: LT lowers it, RT raises it.
    z := GetKeyState("JoyZ")
    lt := (z < TriggerLow)
    rt := (z > TriggerHigh)
    layer := lt ? "self" : rt ? "opponent" : "base"

    ; Navigation: Windows/Xbox conventions map both D-pad and left stick to focus
    ; movement. Keeping both lets the player choose precision or relaxed thumb use.
    HandleRepeat("stickPrev", stickLeft, KPrevItem)
    HandleRepeat("stickNext", stickRight, KNextItem)
    HandleRepeat("stickPrevLine", stickUp, KPrevLine)
    HandleRepeat("stickNextLine", stickDown, KNextLine)

    ; Right stick provides the remaining Hearthstone Access horizontal-list reading
    ; commands without stealing primary controls: first/last item and current/rest
    ; of card text. These are safe read/navigation commands, not gameplay actions.
    HandleTap("rightStickFirst", rightStickLeft, KFirstItem)
    HandleTap("rightStickLast", rightStickRight, KLastItem)
    HandleTap("rightStickRepeatLine", rightStickUp, KRepeatCurrentLine)
    HandleTap("rightStickReadRest", rightStickDown, KReadRestOfItem)

    if (layer = "base") {
        HandleRepeat("povPrev", povLeft, KPrevItem)
        HandleRepeat("povNext", povRight, KNextItem)
        HandleRepeat("povPrevLine", povUp, KPrevLine)
        HandleRepeat("povNextLine", povDown, KNextLine)
    } else {
        ; Stop any held D-pad repeat before using it as an info pad.
        HandleRepeat("povPrev", false, KPrevItem)
        HandleRepeat("povNext", false, KNextItem)
        HandleRepeat("povPrevLine", false, KPrevLine)
        HandleRepeat("povNextLine", false, KNextLine)

        if (layer = "self") {
            HandleTap("lt_dpad_up", povUp, KKeywords)
            HandleTap("lt_dpad_down", povDown, KEnchantments)
            HandleTap("lt_dpad_left", povLeft, KMySecrets)
            HandleTap("lt_dpad_right", povRight, KMyDeckCount)
        } else {
            HandleTap("rt_dpad_up", povUp, KOriginalCard)
            HandleTap("rt_dpad_down", povDown, KRelatedCard)
            HandleTap("rt_dpad_left", povLeft, KOppSecrets)
            HandleTap("rt_dpad_right", povRight, KOppDeckCount)
        }
    }

    ; Face buttons. Mnemonic grid:
    ; A = confirm/resources, B = back/hero, Y = board/minions.
    ; X = Space/context toggle because mulligan uses Space to mark cards,
    ; while A/Enter finishes the mulligan. During a match Space is only
    ; emotes/squelch when focused on a hero, so it is relatively safe.
    if (PressedEdge("A", a)) {
        if (layer = "self")
            SendKey(KMyMana)
        else if (layer = "opponent")
            SendKey(KOppMana)
        else
            SendKey(KSelect)
    }

    if (PressedEdge("B", b)) {
        if (layer = "self")
            SendKey(KMyHero)
        else if (layer = "opponent")
            SendKey(KOppHero)
        else
            SendKey(KCancel)
    }

    if (PressedEdge("X", xBtn)) {
        if (layer = "self")
            SendKey(KMyHand)
        else if (layer = "opponent")
            SendKey(KOppHandCount)
        else
            SendKey(KEmotes)
    }

    if (PressedEdge("Y", yBtn)) {
        if (layer = "self")
            SendKey(KMyMinions)
        else if (layer = "opponent")
            SendKey(KOppMinions)
        else
            SendKey(KMyMinions)
    }

    ; Bumpers are the frequent battle-cycling controls.
    if (PressedEdge("LB", lb)) {
        if (layer = "self")
            SendKey(KMyHeroPower)
        else if (layer = "opponent")
            SendKey(KOppHeroPower)
        else
            SendKey(KPrevValidPlay)
    }

    if (PressedEdge("RB", rb)) {
        if (layer = "self")
            SendKey(KMyWeapon)
        else if (layer = "opponent")
            SendKey(KOppWeapon)
        else
            SendKey(KNextValidPlay)
    }

    ; View is help in base mode; with a trigger it reads anomalies.
    if (PressedEdge("View", viewBtn)) {
        if (layer = "self" || layer = "opponent")
            SendKey(KAnomalies)
        else
            SendKey(KHelp)
    }

    ; Menu/Start: tap = useful but safe, hold = End Turn.
    ; LT+tap trades/forges because it is a self-card action. RT+tap opens emotes,
    ; useful for squelch when focused on a hero, but not dangerous.
    menuTap := (layer = "self") ? KTradeForge : (layer = "opponent") ? KEmotes : KPlayHistory
    menuHold := (layer = "base") ? KEndTurn : ""
    HandleTapOrHold("Menu", menuBtn, menuTap, menuHold, EndTurnHoldMs)

    ; Stick-clicks: optional duplicate info only. Attack-face shortcuts are off by
    ; default; enable them at the top of the file if you really want them.
    if (EnableStickClickInfo && PressedEdge("L3", l3)) {
        if (layer = "opponent" && EnableAttackFaceShortcuts)
            SendKey(KCurrentMinionAttackHero)
        else if (layer = "opponent")
            SendKey(KOppHero)
        else
            SendKey(KMyHero)
    }

    if (EnableStickClickInfo && PressedEdge("R3", r3)) {
        if (layer = "opponent" && EnableAttackFaceShortcuts)
            SendKey(KAllMinionsAttackHero)
        else if (layer = "opponent")
            SendKey(KOppMinions)
        else
            SendKey(KMyMinions)
    }
}
