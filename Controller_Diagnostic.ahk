#Requires AutoHotkey v2.0
#SingleInstance Force
; Controller diagnostic for RogAlly_Hearthstone_Controller.ahk
; Run this, move one control at a time, and watch which values change.

SetTimer(UpdateDisplay, 100)
Esc::ExitApp

JoyName(controllerNumber, controlName) {
    return (controllerNumber = 1) ? "Joy" controlName : controllerNumber "Joy" controlName
}

ReadJoy(controllerNumber, controlName, fallback := "n/a") {
    try return GetKeyState(JoyName(controllerNumber, controlName))
    catch
        return fallback
}

Clamp(value, low, high) {
    return value < low ? low : value > high ? high : value
}

XInputGetState(userIndex, state) {
    static dlls := ["xinput1_4", "xinput1_3", "xinput9_1_0"]
    for , dll in dlls {
        try return DllCall(dll "\XInputGetState", "UInt", userIndex, "Ptr", state.Ptr, "UInt")
        catch
            continue
    }
    return 1167
}

ButtonNames(buttons) {
    names := []
    if (buttons & 0x0001)
        names.Push("DPadUp")
    if (buttons & 0x0002)
        names.Push("DPadDown")
    if (buttons & 0x0004)
        names.Push("DPadLeft")
    if (buttons & 0x0008)
        names.Push("DPadRight")
    if (buttons & 0x0010)
        names.Push("Menu/Start")
    if (buttons & 0x0020)
        names.Push("View/Back")
    if (buttons & 0x0040)
        names.Push("L3")
    if (buttons & 0x0080)
        names.Push("R3")
    if (buttons & 0x0100)
        names.Push("LB")
    if (buttons & 0x0200)
        names.Push("RB")
    if (buttons & 0x1000)
        names.Push("A")
    if (buttons & 0x2000)
        names.Push("B")
    if (buttons & 0x4000)
        names.Push("X")
    if (buttons & 0x8000)
        names.Push("Y")
    return names.Length ? ArrayJoin(names, " ") : "none"
}

ArrayJoin(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i = 1 ? "" : sep) v
    return out
}

UpdateDisplay(*) {
    text := "Controller diagnostic - press Esc to quit`n"
    text .= "Move one stick/trigger/button at a time and note which value changes.`n`n"
    text .= "The main script now prefers XInput, then falls back to Joy API.`n"
    text .= "For ROG Ally/Ally X/Xbox, XInput is usually the important section.`n`n"

    text .= "=== XInput controllers 1-4 ===`n"
    anyXInput := false
    Loop 4 {
        userIndex := A_Index - 1
        state := Buffer(16, 0)
        if (XInputGetState(userIndex, state) != 0)
            continue

        anyXInput := true
        buttons := NumGet(state, 4, "UShort")
        lt := NumGet(state, 6, "UChar")
        rt := NumGet(state, 7, "UChar")
        lx := NumGet(state, 8, "Short")
        ly := NumGet(state, 10, "Short")
        rx := NumGet(state, 12, "Short")
        ry := NumGet(state, 14, "Short")

        lxNorm := Clamp(50 + (lx * 50 / 32767), 0, 100)
        lyNorm := Clamp(50 - (ly * 50 / 32767), 0, 100)
        rxNorm := Clamp(50 + (rx * 50 / 32767), 0, 100)
        ryNorm := Clamp(50 - (ry * 50 / 32767), 0, 100)

        text .= "XInput " A_Index " connected`n"
        text .= "  Buttons: " ButtonNames(buttons) "`n"
        text .= "  LT:" lt "  RT:" rt "`n"
        text .= "  LeftStick X/Y:" Round(lxNorm, 1) "/" Round(lyNorm, 1)
        text .= "  RightStick X/Y:" Round(rxNorm, 1) "/" Round(ryNorm, 1) "`n`n"
    }
    if (!anyXInput)
        text .= "No XInput controllers detected.`n`n"

    text .= "=== AutoHotkey Joy API controllers 1-4 ===`n"
    anyJoy := false
    for n in [1, 2, 3, 4] {
        name := ReadJoy(n, "Name", "")
        buttonsCount := ReadJoy(n, "Buttons", "")
        axesInfo := ReadJoy(n, "Axes", "")
        info := ReadJoy(n, "Info", "")

        if (name = "" && buttonsCount = "" && axesInfo = "" && info = "")
            continue

        anyJoy := true
        text .= "Joy " n ": " (name != "" ? name : "unknown") "`n"
        text .= "  Buttons: " buttonsCount "  Axes: " axesInfo "  Info: " info "`n"
        text .= "  X:" Round(ReadJoy(n, "X", 50), 1)
        text .= "  Y:" Round(ReadJoy(n, "Y", 50), 1)
        text .= "  Z:" Round(ReadJoy(n, "Z", 50), 1)
        text .= "  R:" Round(ReadJoy(n, "R", 50), 1)
        text .= "  U:" Round(ReadJoy(n, "U", 50), 1)
        text .= "  V:" Round(ReadJoy(n, "V", 50), 1)
        text .= "  POV:" ReadJoy(n, "POV", -1) "`n"

        pressed := ""
        Loop 16 {
            if (ReadJoy(n, A_Index, false))
                pressed .= A_Index " "
        }
        text .= "  Pressed buttons: " (pressed != "" ? pressed : "none") "`n`n"
    }
    if (!anyJoy)
        text .= "No Joy API controllers detected.`n`n"

    ToolTip(text, 20, 20)
}
