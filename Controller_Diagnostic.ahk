#Requires AutoHotkey v2.0
#SingleInstance Force
; Controller diagnostic for RogAlly_Hearthstone_Controller.ahk
; Run this, move one control at a time, and watch which Joy control changes.

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

UpdateDisplay(*) {
    text := "Controller diagnostic - press Esc to quit`n"
    text .= "Move one stick/trigger at a time and note which value changes.`n`n"
    text .= "Expected for Xbox/ROG Ally Gamepad Mode:`n"
    text .= "  LT/RT: JoyZ, LT below 50, RT above 50`n"
    text .= "  Right stick X/Y: JoyU / JoyR`n`n"

    for n in [1, 2, 3, 4] {
        name := ReadJoy(n, "Name", "")
        buttonsCount := ReadJoy(n, "Buttons", "")
        axesInfo := ReadJoy(n, "Axes", "")
        info := ReadJoy(n, "Info", "")

        ; Skip totally absent controllers unless a name/info is available.
        if (name = "" && buttonsCount = "" && axesInfo = "" && info = "")
            continue

        text .= "Controller " n ": " (name != "" ? name : "unknown") "`n"
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

    ToolTip(text, 20, 20)
}
