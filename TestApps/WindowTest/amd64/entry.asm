;*********************************************************
; Window Test Code
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/24/2010-2017
;
;*********************************************************

include ksamd64.inc
include windowsx64_public.inc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends


WINMAIN_FRAME struct
   ParamFrameArea PARAMFRAME <?>
   hWnd           dq <?>
   
WINMAIN_FRAME ends

;*********************************************************
; Included Files
;*********************************************************
.DATA

pszWindowClass       db 'TestClassWindow', 0
pszWindowTitle       db 'Test Demo', 0
bFullScreenMode      dq  1
.CODE


;*********************************************************
; WinMain
;
;  The main entry point to the application.
;
;
;
;*********************************************************     
NESTED_ENTRY WinMain, _TEXT$00
  alloc_stack(SIZEOF WINMAIN_FRAME)
.ENDPROLOG 

  LEA RCX, [pszWindowClass]
  LEA RDX, [pszWindowTitle]
  MOV R8, [bFullScreenMode]
  CALL Windowx64_Setup
  TEST RAX, RAX
  JZ @Entry_Exit
  
  MOV WINMAIN_FRAME.hWnd[RSP], RAX
  
  ; TEST REPLACEMENT
  MOV RDX, SW_SHOW
  MOV RCX, RAX
  CALL ShowWindow
  ; ***************
  
  ; TEST REPLACEMENT
  MOV RCX, WINMAIN_FRAME.hWnd[RSP]
  CALL UpdateWindow
  ; ***************
  
@Entry_MessageLoop:  
  CALL Windowx64_Loop
  TEST RAX, RAX
  JZ SHORT @Entry_MessageLoop
  
@Entry_Exit:
  XOR RCX, RCX
  CALL ExitProcess

NESTED_END WinMain, _TEXT$00

END
