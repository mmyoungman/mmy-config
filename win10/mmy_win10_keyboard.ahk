; Mark Youngman's Windows 10 AutoHotKey script

; ctrl+alt+a opens start menu
<^<!a::
Send ^{Esc}
return

; ctrl+alt+t opens terminal
<^<!t::
Run "C:\tools\Cmder\Cmder.exe"
return

; ctrl+alt+b opens browser
<^<!b::
Run "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
return

; ctrl+alt+s opens slack
<^<!s::
Run "C:\Program Files\Slack\Slack.exe"
return

; ctrl+alt+c opens calculator
<^<!c::
Run calc.exe
return

; ctrl+alt+left moves window to left monitor
<^<!Left::
Send {Shift down}#{Left}{Shift up}

; ctrl+alt+right moves window to right monitor
<^<!Right::
Send {Shift down}#{Right}{Shift up}

; stuff to turn capslock into escape
g_LastCtrlKeyDownTime := 0
g_AbortSendEsc := false
g_ControlRepeatDetected := false

*CapsLock::
if (g_ControlRepeatDetected)
{
return
}

send,{Ctrl down}
g_LastCtrlKeyDownTime := A_TickCount
g_AbortSendEsc := false
g_ControlRepeatDetected := true

return

*CapsLock Up::
send,{Ctrl up}
g_ControlRepeatDetected := false
if (g_AbortSendEsc)
{
return
}
current_time := A_TickCount
time_elapsed := current_time - g_LastCtrlKeyDownTime
if (time_elapsed <= 250)
{
SendInput {Esc}
}
return

~*^a::
~*^b::
~*^c::
~*^d::
~*^e::
~*^f::
~*^g::
~*^h::
~*^i::
~*^j::
~*^k::
~*^l::
~*^m::
~*^n::
~*^o::
~*^p::
~*^q::
~*^r::
~*^s::
~*^t::
~*^u::
~*^v::
~*^w::
~*^x::
~*^y::
~*^z::
~*^1::
~*^2::
~*^3::
~*^4::
~*^5::
~*^6::
~*^7::
~*^8::
~*^9::
~*^0::
~*^Space::
~*^Backspace::
~*^Delete::
~*^Insert::
~*^Home::
~*^End::
~*^PgUp::
~*^PgDn::
~*^Tab::
~*^Return::
~*^,::
~*^.::
~*^/::
~*^;::
~*^'::
~*^[::
~*^]::
~*^\::
~*^-::
~*^=::
~*^`::
~*^F1::
~*^F2::
~*^F3::
~*^F4::
~*^F5::
~*^F6::
~*^F7::
~*^F8::
~*^F9::
~*^F10::
~*^F11::
~*^F12::
    g_AbortSendEsc := true
    return