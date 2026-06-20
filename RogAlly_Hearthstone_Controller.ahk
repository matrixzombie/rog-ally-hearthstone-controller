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
global ExitHoldMs := 2000          ; hold View+Menu/Start this long to exit the mapper

; Controller support:
; - Xbox controllers and the ROG Ally's Gamepad Mode both expose an Xbox/XInput-like layout.
; - By default, poll controllers 1-4 and accept input from any of them. This lets the
;   same script work with the built-in Ally controls or a connected Xbox controller.
; - If you get duplicate/unwanted input, set this to just one number, e.g. [1] or [2].
global ControllerNumbers := [1, 2, 3, 4]
global CurrentMode := "standard"   ; "standard" or "battlegrounds". Hold View to toggle.

; Input backend:
; - "auto" prefers XInput and falls back to AutoHotkey's legacy Joy API.
; - "xinput" uses only XInput. This is usually best for Xbox controllers and ROG Ally/Ally X.
; - "joy" uses only AutoHotkey's legacy Joy API.
global InputBackend := "auto"

; User settings are stored in AppData so installed builds can save settings even
; when the program itself lives under Program Files.
global ConfigDir := A_AppData "\RogAllyHearthstoneController"
global ConfigFile := ConfigDir "\settings.ini"
global SpeakOnLaunch := true
global SpeakModeChanges := true
global EnableExitCombo := true
global EnableHearthstoneWindowCheck := true
global MapperEnabled := true

; Stick-clicks are awkward on handhelds and can happen accidentally while steering.
; They are therefore only duplicate/safe info by default, and can be disabled.
global EnableStickClickInfo := false

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

; Battlegrounds shortcuts
KBgGold := "a"
KBgMinionsForSale := "g"
KBgMyMinions := "b"
KBgHand := "c"
KBgTavernTier := "t"
KBgUpgradeTavern := "u"
KBgUpgradeTavernFast := "+u"
KBgFreeze := "f"
KBgFreezeFast := "+f"
KBgRefresh := "r"
KBgRefreshFast := "+r"
KBgHeroPower := "p"
KBgOppHeroPower := "+p"
KBgBuddy := "d"
KBgMyLeaderboard := "m"
KBgMyLeaderboardQuick := "+m"
KBgNextOpponentStats := "n"
KBgNextOpponentStatsQuick := "+n"
KBgLeaderboardTop := "l"
KBgSecondsLeft := "e"
KBgSecretsQuests := "s"
KBgOppSecretsQuests := "+s"
KBgQuestReward := "w"
KBgOppQuestReward := "+w"
KBgTrinkets := "q"
KBgOppTrinkets := "+q"
KBgReorder := "{Space}"

; Global
KHelp := "{F1}"

; -------------------- Internal state --------------------
global ButtonStates := Map()
global RepeatStates := Map()
global HoldStates := Map()
global ExitComboState := {held:false, start:0, warned:false}

LoadSettings()
SetupTrayMenu()
SetTimer(PollController, PollMs)
TrayTip("ROG Ally Hearthstone mapper", "Loaded. Gamepad Mode + Hearthstone active window required.", 3)
if (SpeakOnLaunch)
    Speak("Mapper loaded. " ModeDisplayName(CurrentMode) " mode")
return

IsHearthstoneActive() {
    global HearthstoneExe, EnableHearthstoneWindowCheck
    if (!EnableHearthstoneWindowCheck)
        return true
    return WinActive(HearthstoneExe) || WinActive("Hearthstone")
}

BoolToString(value) {
    return value ? "true" : "false"
}

ReadIniBool(section, key, defaultValue) {
    global ConfigFile
    value := StrLower(Trim(IniRead(ConfigFile, section, key, BoolToString(defaultValue))))
    return (value = "1" || value = "true" || value = "yes" || value = "on")
}

ReadIniInt(section, key, defaultValue, minValue := "", maxValue := "") {
    global ConfigFile
    value := IniRead(ConfigFile, section, key, defaultValue)
    if (!IsNumber(value))
        value := defaultValue
    value := Integer(value)
    if (minValue != "" && value < minValue)
        value := minValue
    if (maxValue != "" && value > maxValue)
        value := maxValue
    return value
}

ParseControllerNumbers(value) {
    result := []
    for , part in StrSplit(value, ",") {
        part := Trim(part)
        if (part != "" && IsNumber(part)) {
            number := Integer(part)
            if (number >= 1 && number <= 4)
                result.Push(number)
        }
    }
    return result.Length ? result : [1, 2, 3, 4]
}

ControllerNumbersToString() {
    global ControllerNumbers
    output := ""
    for index, number in ControllerNumbers
        output .= (index = 1 ? "" : ",") number
    return output
}

WriteDefaultSettings(includeComments := false) {
    global ConfigFile, HearthstoneExe, CurrentMode, InputBackend, ControllerNumbers
    global EndTurnHoldMs, ExitHoldMs, SpeakOnLaunch, SpeakModeChanges
    global EnableExitCombo, EnableHearthstoneWindowCheck
    global EnableStickClickInfo, EnableAttackFaceShortcuts

    if (includeComments) {
        settingsText := ""
        settingsText .= "; ROG Ally Hearthstone Controller Mapper settings`r`n"
        settingsText .= "; Edit this file, save it, then use the tray menu's Reload settings item or restart the mapper.`r`n"
        settingsText .= "; true/false values can also be written as yes/no or on/off.`r`n`r`n"
        settingsText .= "[General]`r`n"
        settingsText .= "; Starting/current mode. Valid values: standard, battlegrounds.`r`n"
        settingsText .= "CurrentMode=" CurrentMode "`r`n`r`n"
        settingsText .= "; Controller input backend. auto is recommended. Valid values: auto, xinput, joy.`r`n"
        settingsText .= "InputBackend=" InputBackend "`r`n`r`n"
        settingsText .= "; Controller numbers to poll, comma-separated. Leave 1,2,3,4 unless troubleshooting duplicate/unwanted input.`r`n"
        settingsText .= "ControllerNumbers=" ControllerNumbersToString() "`r`n`r`n"
        settingsText .= "; Hold time in milliseconds for Standard/Arena end turn. Default 450.`r`n"
        settingsText .= "EndTurnHoldMs=" EndTurnHoldMs "`r`n`r`n"
        settingsText .= "; Hold time in milliseconds for View+Menu/Start exit shortcut. Default 2000.`r`n"
        settingsText .= "ExitHoldMs=" ExitHoldMs "`r`n`r`n"
        settingsText .= "; Speak the current mode when the mapper starts.`r`n"
        settingsText .= "SpeakOnLaunch=" BoolToString(SpeakOnLaunch) "`r`n`r`n"
        settingsText .= "; Speak mode changes when switching Standard/Arena and Battlegrounds.`r`n"
        settingsText .= "SpeakModeChanges=" BoolToString(SpeakModeChanges) "`r`n`r`n"
        settingsText .= "; Enable holding View+Menu/Start to exit the mapper.`r`n"
        settingsText .= "EnableExitCombo=" BoolToString(EnableExitCombo) "`r`n`r`n"
        settingsText .= "; Only send keys while Hearthstone is active. Set false only for troubleshooting.`r`n"
        settingsText .= "EnableHearthstoneWindowCheck=" BoolToString(EnableHearthstoneWindowCheck) "`r`n`r`n"
        settingsText .= "; Hearthstone window matcher used when EnableHearthstoneWindowCheck is true.`r`n"
        settingsText .= "HearthstoneExe=" HearthstoneExe "`r`n`r`n"
        settingsText .= "[Advanced]`r`n"
        settingsText .= "; Enable optional stick-click info shortcuts. Required for attack-face shortcuts below.`r`n"
        settingsText .= "EnableStickClickInfo=" BoolToString(EnableStickClickInfo) "`r`n`r`n"
        settingsText .= "; Enable RT+L3 and RT+R3 attack-face shortcuts. Off by default to prevent accidental attacks.`r`n"
        settingsText .= "EnableAttackFaceShortcuts=" BoolToString(EnableAttackFaceShortcuts) "`r`n"
        settingsFile := FileOpen(ConfigFile, "w", "UTF-8")
        settingsFile.Write(settingsText)
        settingsFile.Close()
        return
    }

    IniWrite(CurrentMode, ConfigFile, "General", "CurrentMode")
    IniWrite(InputBackend, ConfigFile, "General", "InputBackend")
    IniWrite(ControllerNumbersToString(), ConfigFile, "General", "ControllerNumbers")
    IniWrite(EndTurnHoldMs, ConfigFile, "General", "EndTurnHoldMs")
    IniWrite(ExitHoldMs, ConfigFile, "General", "ExitHoldMs")
    IniWrite(BoolToString(SpeakOnLaunch), ConfigFile, "General", "SpeakOnLaunch")
    IniWrite(BoolToString(SpeakModeChanges), ConfigFile, "General", "SpeakModeChanges")
    IniWrite(BoolToString(EnableExitCombo), ConfigFile, "General", "EnableExitCombo")
    IniWrite(BoolToString(EnableHearthstoneWindowCheck), ConfigFile, "General", "EnableHearthstoneWindowCheck")
    IniWrite(HearthstoneExe, ConfigFile, "General", "HearthstoneExe")
    IniWrite(BoolToString(EnableStickClickInfo), ConfigFile, "Advanced", "EnableStickClickInfo")
    IniWrite(BoolToString(EnableAttackFaceShortcuts), ConfigFile, "Advanced", "EnableAttackFaceShortcuts")
}

LoadSettings() {
    global ConfigDir, ConfigFile, HearthstoneExe, CurrentMode, InputBackend, ControllerNumbers
    global EndTurnHoldMs, ExitHoldMs, SpeakOnLaunch, SpeakModeChanges
    global EnableExitCombo, EnableHearthstoneWindowCheck
    global EnableStickClickInfo, EnableAttackFaceShortcuts

    DirCreate(ConfigDir)
    if (!FileExist(ConfigFile))
        WriteDefaultSettings(true)

    mode := StrLower(Trim(IniRead(ConfigFile, "General", "CurrentMode", CurrentMode)))
    CurrentMode := (mode = "battlegrounds") ? "battlegrounds" : "standard"

    backend := StrLower(Trim(IniRead(ConfigFile, "General", "InputBackend", InputBackend)))
    InputBackend := (backend = "xinput" || backend = "joy") ? backend : "auto"

    ControllerNumbers := ParseControllerNumbers(IniRead(ConfigFile, "General", "ControllerNumbers", "1,2,3,4"))
    EndTurnHoldMs := ReadIniInt("General", "EndTurnHoldMs", EndTurnHoldMs, 100, 5000)
    ExitHoldMs := ReadIniInt("General", "ExitHoldMs", ExitHoldMs, 500, 10000)
    SpeakOnLaunch := ReadIniBool("General", "SpeakOnLaunch", SpeakOnLaunch)
    SpeakModeChanges := ReadIniBool("General", "SpeakModeChanges", SpeakModeChanges)
    EnableExitCombo := ReadIniBool("General", "EnableExitCombo", EnableExitCombo)
    EnableHearthstoneWindowCheck := ReadIniBool("General", "EnableHearthstoneWindowCheck", EnableHearthstoneWindowCheck)
    HearthstoneExe := Trim(IniRead(ConfigFile, "General", "HearthstoneExe", HearthstoneExe))
    EnableStickClickInfo := ReadIniBool("Advanced", "EnableStickClickInfo", EnableStickClickInfo)
    EnableAttackFaceShortcuts := ReadIniBool("Advanced", "EnableAttackFaceShortcuts", EnableAttackFaceShortcuts)
}

SaveSettings() {
    WriteDefaultSettings()
}

ModeDisplayName(mode) {
    return (mode = "battlegrounds") ? "Battlegrounds" : "Standard and Arena"
}

SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Standard/Arena mode", TrayStandardMode)
    A_TrayMenu.Add("Battlegrounds mode", TrayBattlegroundsMode)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Pause mapper", TrayTogglePause)
    A_TrayMenu.Add("Reload settings", TrayReloadSettings)
    A_TrayMenu.Add("Open settings", TrayOpenSettings)
    A_TrayMenu.Add("Open README", TrayOpenReadme)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", TrayExit)
    UpdateTrayModeChecks()
    UpdateTrayPauseCheck()
}

UpdateTrayModeChecks() {
    global CurrentMode
    try {
        A_TrayMenu.Uncheck("Standard/Arena mode")
        A_TrayMenu.Uncheck("Battlegrounds mode")
        A_TrayMenu.Check((CurrentMode = "battlegrounds") ? "Battlegrounds mode" : "Standard/Arena mode")
    }
}

UpdateTrayPauseCheck() {
    global MapperEnabled
    try {
        if (MapperEnabled)
            A_TrayMenu.Uncheck("Pause mapper")
        else
            A_TrayMenu.Check("Pause mapper")
    }
}

TrayStandardMode(*) {
    SetMode("standard", true, true)
}

TrayBattlegroundsMode(*) {
    SetMode("battlegrounds", true, true)
}

TrayTogglePause(*) {
    global MapperEnabled
    MapperEnabled := !MapperEnabled
    ResetStates()
    UpdateTrayPauseCheck()
    TrayTip("ROG Ally Hearthstone mapper", MapperEnabled ? "Mapper resumed" : "Mapper paused", 2)
    Speak(MapperEnabled ? "Mapper resumed" : "Mapper paused")
}

TrayReloadSettings(*) {
    LoadSettings()
    ResetStates()
    UpdateTrayModeChecks()
    UpdateTrayPauseCheck()
    TrayTip("ROG Ally Hearthstone mapper", "Settings reloaded", 2)
    Speak("Settings reloaded. " ModeDisplayName(CurrentMode) " mode")
}

TrayOpenSettings(*) {
    global ConfigFile
    if (!FileExist(ConfigFile))
        WriteDefaultSettings(true)
    Run("notepad.exe `"" ConfigFile "`"")
}

TrayOpenReadme(*) {
    readmeHtml := A_ScriptDir "\readme.html"
    readmeMd := A_ScriptDir "\README.md"
    if (FileExist(readmeHtml))
        Run(readmeHtml)
    else if (FileExist(readmeMd))
        Run(readmeMd)
    else
        Run("https://github.com/matrixzombie/rog-ally-hearthstone-controller#readme")
}

TrayExit(*) {
    ExitApp()
}

ResetStates() {
    global ButtonStates, RepeatStates, HoldStates, ExitComboState
    ButtonStates := Map()
    ExitComboState.held := false
    ExitComboState.start := 0
    ExitComboState.warned := false
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
    if (sendText = "__TOGGLE_MODE__") {
        ToggleMode()
        return
    }
    if (sendText != "")
        Send(sendText)
}

Speak(text) {
    ; Use Windows SAPI for important mapper status announcements.
    ; Flag 3 = async + purge queued speech, so the current mode is spoken immediately.
    static initialized := false
    static voice := ""

    if (!initialized) {
        try voice := ComObject("SAPI.SpVoice")
        catch {
            initialized := true
            return
        }
        initialized := true
    }

    if (IsObject(voice)) {
        try voice.Speak(text, 3)
    }
}

SetMode(mode, announce := true, save := true) {
    global CurrentMode, SpeakModeChanges
    mode := (mode = "battlegrounds") ? "battlegrounds" : "standard"
    CurrentMode := mode
    UpdateTrayModeChecks()
    if (save)
        SaveSettings()
    if (announce) {
        displayName := ModeDisplayName(CurrentMode)
        TrayTip("ROG Ally Hearthstone mapper", displayName " mode", 2)
        if (SpeakModeChanges)
            Speak(displayName " mode")
    }
}

ToggleMode() {
    global CurrentMode
    SetMode((CurrentMode = "standard") ? "battlegrounds" : "standard", true, true)
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

HandleExitCombo(pressed) {
    global ExitComboState, ExitHoldMs
    now := A_TickCount

    if (pressed) {
        if (!ExitComboState.held) {
            ExitComboState.held := true
            ExitComboState.start := now
            ExitComboState.warned := false
        } else if (!ExitComboState.warned && (now - ExitComboState.start) >= 900) {
            TrayTip("ROG Ally Hearthstone mapper", "Keep holding View+Menu to exit...", 1)
            ExitComboState.warned := true
        } else if ((now - ExitComboState.start) >= ExitHoldMs) {
            TrayTip("ROG Ally Hearthstone mapper", "Exiting mapper", 1)
            ExitApp()
        }
        return true
    }

    ExitComboState.held := false
    ExitComboState.start := 0
    ExitComboState.warned := false
    return false
}

JoyName(controllerNumber, controlName) {
    return (controllerNumber = 1) ? "Joy" controlName : controllerNumber "Joy" controlName
}

JoyButton(buttonNumber) {
    global ControllerNumbers
    for , n in ControllerNumbers {
        try pressed := GetKeyState(JoyName(n, buttonNumber))
        catch
            continue
        if (pressed)
            return true
    }
    return false
}

JoyAxis(axisName, fallback := 50) {
    ; Returns the most-deflected value for an axis across enabled controllers.
    ; This supports either the Ally controls or a connected Xbox controller without
    ; caring which Windows joystick number it was assigned.
    global ControllerNumbers
    best := fallback
    bestDelta := -1
    for , n in ControllerNumbers {
        try v := GetKeyState(JoyName(n, axisName))
        catch
            continue
        if (!IsNumber(v))
            continue
        delta := Abs(v - 50)
        if (delta > bestDelta) {
            best := v
            bestDelta := delta
        }
    }
    return best
}

JoyPOVAny() {
    global ControllerNumbers
    for , n in ControllerNumbers {
        try pov := GetKeyState(JoyName(n, "POV"))
        catch
            continue
        if (IsNumber(pov) && pov != -1)
            return pov
    }
    return -1
}

Clamp(value, low, high) {
    return value < low ? low : value > high ? high : value
}

XInputGetState(userIndex, state) {
    ; Returns 0 on success. Try the common XInput DLLs used across Windows versions.
    static dlls := ["xinput1_4", "xinput1_3", "xinput9_1_0"]
    for , dll in dlls {
        try return DllCall(dll "\XInputGetState", "UInt", userIndex, "Ptr", state.Ptr, "UInt")
        catch
            continue
    }
    return 1167 ; ERROR_DEVICE_NOT_CONNECTED / unavailable fallback
}

ReadXInputControllerState() {
    global ControllerNumbers
    result := {
        connected:false,
        a:false, b:false, x:false, y:false,
        lb:false, rb:false, view:false, menu:false, l3:false, r3:false,
        povUp:false, povRight:false, povDown:false, povLeft:false,
        lx:50, ly:50, rx:50, ry:50,
        lt:false, rt:false
    }

    bestLXDelta := -1, bestLYDelta := -1, bestRXDelta := -1, bestRYDelta := -1
    maxLT := 0, maxRT := 0

    for , controllerNumber in ControllerNumbers {
        userIndex := controllerNumber - 1 ; XInput uses 0-3, while Joy uses 1-4.
        if (userIndex < 0 || userIndex > 3)
            continue

        state := Buffer(16, 0)
        if (XInputGetState(userIndex, state) != 0)
            continue

        result.connected := true
        buttons := NumGet(state, 4, "UShort")
        ltValue := NumGet(state, 6, "UChar")
        rtValue := NumGet(state, 7, "UChar")
        lxRaw := NumGet(state, 8, "Short")
        lyRaw := NumGet(state, 10, "Short")
        rxRaw := NumGet(state, 12, "Short")
        ryRaw := NumGet(state, 14, "Short")

        result.povUp := result.povUp || !!(buttons & 0x0001)
        result.povDown := result.povDown || !!(buttons & 0x0002)
        result.povLeft := result.povLeft || !!(buttons & 0x0004)
        result.povRight := result.povRight || !!(buttons & 0x0008)
        result.menu := result.menu || !!(buttons & 0x0010) ; Start/Menu
        result.view := result.view || !!(buttons & 0x0020) ; Back/View
        result.l3 := result.l3 || !!(buttons & 0x0040)
        result.r3 := result.r3 || !!(buttons & 0x0080)
        result.lb := result.lb || !!(buttons & 0x0100)
        result.rb := result.rb || !!(buttons & 0x0200)
        result.a := result.a || !!(buttons & 0x1000)
        result.b := result.b || !!(buttons & 0x2000)
        result.x := result.x || !!(buttons & 0x4000)
        result.y := result.y || !!(buttons & 0x8000)

        if (ltValue > maxLT)
            maxLT := ltValue
        if (rtValue > maxRT)
            maxRT := rtValue

        lxNorm := Clamp(50 + (lxRaw * 50 / 32767), 0, 100)
        lyNorm := Clamp(50 - (lyRaw * 50 / 32767), 0, 100) ; XInput Y up is positive; Joy Y up is low.
        rxNorm := Clamp(50 + (rxRaw * 50 / 32767), 0, 100)
        ryNorm := Clamp(50 - (ryRaw * 50 / 32767), 0, 100)

        if (Abs(lxNorm - 50) > bestLXDelta) {
            result.lx := lxNorm
            bestLXDelta := Abs(lxNorm - 50)
        }
        if (Abs(lyNorm - 50) > bestLYDelta) {
            result.ly := lyNorm
            bestLYDelta := Abs(lyNorm - 50)
        }
        if (Abs(rxNorm - 50) > bestRXDelta) {
            result.rx := rxNorm
            bestRXDelta := Abs(rxNorm - 50)
        }
        if (Abs(ryNorm - 50) > bestRYDelta) {
            result.ry := ryNorm
            bestRYDelta := Abs(ryNorm - 50)
        }
    }

    ; A small trigger threshold avoids accidental layer changes from trigger noise.
    result.lt := (maxLT > 30)
    result.rt := (maxRT > 30)
    return result
}

ReadJoyControllerState() {
    global TriggerLow, TriggerHigh
    pov := JoyPOVAny()
    z := JoyAxis("Z")
    return {
        connected:true,
        a:JoyButton(1), b:JoyButton(2), x:JoyButton(3), y:JoyButton(4),
        lb:JoyButton(5), rb:JoyButton(6), view:JoyButton(7), menu:JoyButton(8),
        l3:JoyButton(9), r3:JoyButton(10),
        povUp:(pov = 0 || pov = 4500 || pov = 31500),
        povRight:(pov = 9000 || pov = 4500 || pov = 13500),
        povDown:(pov = 18000 || pov = 13500 || pov = 22500),
        povLeft:(pov = 27000 || pov = 22500 || pov = 31500),
        lx:JoyAxis("X"), ly:JoyAxis("Y"),
        rx:JoyAxis("U"), ry:JoyAxis("R"),
        lt:(z < TriggerLow), rt:(z > TriggerHigh)
    }
}

ReadControllerState() {
    global InputBackend
    if (InputBackend != "joy") {
        state := ReadXInputControllerState()
        if (state.connected || InputBackend = "xinput")
            return state
    }
    return ReadJoyControllerState()
}

PollController(*) {
    global AxisDeadzone, RightStickDeadzone, TriggerLow, TriggerHigh, EndTurnHoldMs
    global CurrentMode, MapperEnabled, EnableExitCombo, EnableStickClickInfo, EnableAttackFaceShortcuts
    global KPrevItem, KNextItem, KPrevLine, KNextLine, KFirstItem, KLastItem
    global KRepeatCurrentLine, KReadRestOfItem, KNextValidPlay, KPrevValidPlay
    global KSelect, KCancel, KEndTurn, KHelp
    global KMyMana, KOppMana, KMyHand, KOppHandCount, KMyMinions, KOppMinions
    global KMyHero, KOppHero, KMyHeroPower, KOppHeroPower, KMyWeapon, KOppWeapon
    global KMySecrets, KOppSecrets, KMyDeckCount, KOppDeckCount, KKeywords, KEnchantments
    global KTradeForge, KPlayHistory, KAnomalies, KRelatedCard, KOriginalCard
    global KCurrentMinionAttackHero, KAllMinionsAttackHero, KEmotes
    global KBgGold, KBgMinionsForSale, KBgMyMinions, KBgHand, KBgTavernTier, KBgUpgradeTavern
    global KBgUpgradeTavernFast, KBgFreeze, KBgFreezeFast, KBgRefresh, KBgRefreshFast
    global KBgHeroPower, KBgOppHeroPower, KBgBuddy
    global KBgMyLeaderboard, KBgMyLeaderboardQuick, KBgNextOpponentStats
    global KBgNextOpponentStatsQuick, KBgLeaderboardTop, KBgSecondsLeft
    global KBgSecretsQuests, KBgOppSecretsQuests, KBgQuestReward, KBgOppQuestReward
    global KBgTrinkets, KBgOppTrinkets, KBgReorder

    if (!MapperEnabled || !IsHearthstoneActive()) {
        ResetStates()
        return
    }

    controller := ReadControllerState()

    ; Xbox/ROG Ally logical layout:
    ; A/B/X/Y, LB/RB, View/Menu, L3/R3, D-pad, sticks, LT/RT.
    ; In auto mode the script prefers XInput, which is more reliable on the
    ; ROG Ally X and Xbox controllers, then falls back to AHK's Joy API.
    a := controller.a
    b := controller.b
    xBtn := controller.x
    yBtn := controller.y
    lb := controller.lb
    rb := controller.rb
    viewBtn := controller.view
    menuBtn := controller.menu
    l3 := controller.l3
    r3 := controller.r3

    povUp := controller.povUp
    povRight := controller.povRight
    povDown := controller.povDown
    povLeft := controller.povLeft

    lx := controller.lx
    ly := controller.ly
    stickLeft := (lx < 50 - AxisDeadzone)
    stickRight := (lx > 50 + AxisDeadzone)
    stickUp := (ly < 50 - AxisDeadzone)
    stickDown := (ly > 50 + AxisDeadzone)

    rx := controller.rx
    ry := controller.ry
    rightStickLeft := (rx < 50 - RightStickDeadzone)
    rightStickRight := (rx > 50 + RightStickDeadzone)
    rightStickUp := (ry < 50 - RightStickDeadzone)
    rightStickDown := (ry > 50 + RightStickDeadzone)

    lt := controller.lt
    rt := controller.rt
    layer := lt ? "self" : rt ? "opponent" : "base"

    ; Exit shortcut for current/future builds. While this combo is held, block the
    ; normal View/Menu actions so it does not toggle modes or send End Turn/upgrade.
    if (EnableExitCombo && HandleExitCombo(viewBtn && menuBtn))
        return

    ; Navigation: Windows/Xbox conventions map both D-pad and left stick to focus
    ; movement. Keeping both lets the player choose precision or relaxed thumb use.
    HandleRepeat("stickPrev", stickLeft, KPrevItem)
    HandleRepeat("stickNext", stickRight, KNextItem)
    HandleRepeat("stickPrevLine", stickUp, KPrevLine)
    HandleRepeat("stickNextLine", stickDown, KNextLine)

    ; Right stick in base mode provides the accessibility mod's horizontal-list
    ; reading commands without stealing primary controls: first/last item and
    ; current/rest of card text. Trigger layers reuse right stick for mode-specific
    ; lower-priority info.
    if (layer = "base") {
        HandleTap("rightStickFirst", rightStickLeft, KFirstItem)
        HandleTap("rightStickLast", rightStickRight, KLastItem)
        HandleTap("rightStickRepeatLine", rightStickUp, KRepeatCurrentLine)
        HandleTap("rightStickReadRest", rightStickDown, KReadRestOfItem)
    } else {
        HandleTap("rightStickFirst", false, KFirstItem)
        HandleTap("rightStickLast", false, KLastItem)
        HandleTap("rightStickRepeatLine", false, KRepeatCurrentLine)
        HandleTap("rightStickReadRest", false, KReadRestOfItem)
    }

    if (CurrentMode = "battlegrounds") {
        ; Battlegrounds: base mode puts high-frequency recruit-phase actions on
        ; reachable controls. LT is your/shop info; RT is opponent/leaderboard info.
        if (layer = "base") {
            HandleRepeat("povPrev", povLeft, KPrevItem)
            HandleRepeat("povNext", povRight, KNextItem)
            HandleRepeat("povPrevLine", povUp, KPrevLine)
            HandleRepeat("povNextLine", povDown, KNextLine)
        } else {
            HandleRepeat("povPrev", false, KPrevItem)
            HandleRepeat("povNext", false, KNextItem)
            HandleRepeat("povPrevLine", false, KPrevLine)
            HandleRepeat("povNextLine", false, KNextLine)

            if (layer = "self") {
                HandleTap("bg_lt_dpad_up", povUp, KKeywords)
                HandleTap("bg_lt_dpad_down", povDown, KEnchantments)
                HandleTap("bg_lt_dpad_left", povLeft, KBgSecretsQuests)
                HandleTap("bg_lt_dpad_right", povRight, KBgTavernTier)
                HandleTap("bg_lt_rs_up", rightStickUp, KBgQuestReward)
                HandleTap("bg_lt_rs_down", rightStickDown, KAnomalies)
                HandleTap("bg_lt_rs_left", rightStickLeft, KBgTrinkets)
                HandleTap("bg_lt_rs_right", rightStickRight, KBgBuddy)
            } else {
                HandleTap("bg_rt_dpad_up", povUp, KBgMyLeaderboardQuick)
                HandleTap("bg_rt_dpad_down", povDown, "")
                HandleTap("bg_rt_dpad_left", povLeft, KBgLeaderboardTop)
                HandleTap("bg_rt_dpad_right", povRight, KBgNextOpponentStatsQuick)
                HandleTap("bg_rt_rs_up", rightStickUp, "")
                HandleTap("bg_rt_rs_down", rightStickDown, "")
                HandleTap("bg_rt_rs_left", rightStickLeft, KPrevValidPlay)
                HandleTap("bg_rt_rs_right", rightStickRight, KNextValidPlay)
            }
        }

        if (PressedEdge("A", a)) {
            if (layer = "self")
                SendKey(KBgGold)
            else if (layer = "opponent")
                SendKey(KBgOppHeroPower)
            else
                SendKey(KSelect)
        }

        if (PressedEdge("B", b)) {
            if (layer = "self")
                SendKey(KBgHeroPower)
            else if (layer = "opponent")
                SendKey(KBgMyLeaderboard)
            else
                SendKey(KCancel)
        }

        if (PressedEdge("X", xBtn)) {
            if (layer = "self")
                SendKey(KBgReorder)
            else if (layer = "opponent")
                SendKey(KBgOppSecretsQuests)
            else
                SendKey(KBgHand)
        }

        if (PressedEdge("Y", yBtn)) {
            if (layer = "self")
                SendKey(KBgMyMinions)
            else if (layer = "opponent")
                SendKey(KBgNextOpponentStats)
            else
                SendKey(KBgMinionsForSale)
        }

        if (PressedEdge("LB", lb)) {
            if (layer = "self")
                SendKey(KBgFreeze)
            else if (layer = "opponent")
                SendKey(KBgOppTrinkets)
            else
                SendKey(KBgFreezeFast)
        }

        if (PressedEdge("RB", rb)) {
            if (layer = "self")
                SendKey(KBgRefresh)
            else if (layer = "opponent")
                SendKey(KBgOppQuestReward)
            else
                SendKey(KBgRefreshFast)
        }

        viewTap := KHelp
        HandleTapOrHold("View", viewBtn, viewTap, "__TOGGLE_MODE__", 700)

        menuTap := (layer = "base") ? KBgSecondsLeft : ""
        menuHold := (layer = "base") ? KBgUpgradeTavernFast : (layer = "self") ? KBgUpgradeTavern : ""
        HandleTapOrHold("Menu", menuBtn, menuTap, menuHold, EndTurnHoldMs)

        if (EnableStickClickInfo && PressedEdge("L3", l3))
            SendKey((layer = "opponent") ? KBgOppHeroPower : KBgHeroPower)

        if (EnableStickClickInfo && PressedEdge("R3", r3))
            SendKey((layer = "opponent") ? KBgNextOpponentStats : KBgMinionsForSale)

        return
    }

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

    ; View is help in base mode; with a trigger it reads anomalies. Hold View
    ; to toggle Standard/Arena vs Battlegrounds layout.
    viewTap := (layer = "self" || layer = "opponent") ? KAnomalies : KHelp
    HandleTapOrHold("View", viewBtn, viewTap, "__TOGGLE_MODE__", 700)

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
