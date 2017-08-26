;****************************************
;
; Windows x64 Definitions
;
;     Toby Opferman
;
;****************************************


; Function Procedures
extern ExitProcess:proc
extern RegisterClassExA:proc
extern CreateWindowExA:proc
extern DefWindowProcA:proc
extern ShowCursor:proc
extern PostQuitMessage:proc
extern DestroyWindow:proc
extern GetModuleHandleA:proc
extern PeekMessageA:proc
extern TranslateMessage:proc
extern DispatchMessageA:proc
extern ShowWindow:proc
extern UpdateWindow:proc
extern GetStockObject:proc
extern SetFocus:proc
extern LocalFree:proc
extern LocalAlloc:proc

; Constants

VK_ESCAPE  EQU <01Bh>
WM_CLOSE   EQU <00010h>
WM_DESTROY EQU <00002h>
WM_KEYUP   EQU <00101h>
WM_CREATE  EQU <00001h>
WS_POPUP   EQU <080000000h>
WM_PAINT   EQU <0Fh>
PM_REMOVE  EQU <0001h>
WM_QUIT    EQU <0012h>
SW_SHOW    EQU <5>
WS_OVERLAPPED EQU <000000000h>
WS_CAPTION    EQU <000C00000h>
WS_SYSMENU    EQU <080000h>
WS_MAXIMIZE   EQU <01000000h>
WS_BORDER     EQU <00800000h>
WS_OVERLAPPEDWINDOW EQU <WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX>
WS_THICKFRAME   EQU <040000h>
WS_MINIMIZEBOX  EQU <020000h>
WS_MAXIMIZEBOX  EQU <010000h>
BLACK_BRUSH     EQU <4>
SW_SHOWNORMAL   EQU <1>
LMEM_ZEROINIT   EQU <40h>
CW_USEDEFAULT   EQU <80000000>

; Structure Definitions

WNDCLASSEX struct
    cbSize         dd ?
    style          dd ?
    lpfnWndProc    dq ?
    cbClsExtra     dd ?
    cbWndExtra     dd ?
    hInstance      dq ?
    hIcon          dq ?
    hCursor        dq ?
    hbrBackground  dq ?
    lpszMenuName   dq ?
    lpszClassName  dq ?
    hIconSm        dq ?
WNDCLASSEX ends

POINT struct
    x        dd ?
    y        dd ?
	padding dq ?
POINT ends

RECT struct
  left     dd ?
  top      dd ?
  right    dd ?
  bottom   dd ?   
RECT ends

MSG struct
    hwnd      dq  ?
    message   dq  ?
    wParam    dq  ?
    lParam    dq  ?
    time      dq  ?
    pt        POINT <?>
MSG ends


