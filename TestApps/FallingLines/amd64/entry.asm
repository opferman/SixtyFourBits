;*********************************************************
; Demo Entry Code
;
;  Written in Assembly x64
; 
;  By Sarthak Shah August - 2017

; Incorporated fallingline from Toby Opferman
;
;*********************************************************



;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include fallingline_public.inc
include init_public.inc

extern ExitProcess:proc

;*********************************************************
; Structures
;*********************************************************
PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

extern MessageBoxA:proc

WINMAIN_FRAME struct
   ParamFrameArea        PARAMFRAME       <?>
   InitializationStruct  INIT_DEMO_STRUCT <?>
WINMAIN_FRAME ends

.DATA

;*********************************************************
; Global Data
;*********************************************************

GlobalDemoStructure  dq Fallingline_Init 
                     dq Fallingline_Demo
                     dq Fallingline_Free
;
; End Tag
;
                     dq 0
                     dq 0
                     dq 0

pszWindowClass       db 'FallinglineClassWindow', 0
pszWindowTitle       db 'Fallingline Demo', 0

pszMsgCpt       db 'Fallingline Demo', 0
pszMsgTxt       db 'Do you want to view in full screen?', 0

.CODE
  
NESTED_ENTRY WinMain, _TEXT$00
  alloc_stack(SIZEOF WINMAIN_FRAME)
.ENDPROLOG 
  
  MOV WINMAIN_FRAME.InitializationStruct.BitsPerPixel[RSP], 20h
  MOV WINMAIN_FRAME.InitializationStruct.ScreenWidth[RSP],  1024
  MOV WINMAIN_FRAME.InitializationStruct.ScreenHeight[RSP], 768

  LEA RCX, [pszWindowTitle]
  MOV WINMAIN_FRAME.InitializationStruct.pszWindowTitle[RSP], RCX
  LEA RCX, [pszWindowClass]
  MOV WINMAIN_FRAME.InitializationStruct.pszWindowClass[RSP], RCX
  LEA RCX, [GlobalDemoStructure]    
  MOV WINMAIN_FRAME.InitializationStruct.GlobalDemoStructure[RSP], RCX

  MOV R9, 24h ; MB_YESNO | MB_ICONQUESTION
  LEA R8, [pszMsgCpt]
  LEA RDX, [pszMsgTxt]
  XOR RCX, RCX
  CALL MessageBoxA
  CMP RAX, 6
  SETE AL
  MOV WINMAIN_FRAME.InitializationStruct.FullScreen[RSP], RAX

  LEA RCX, WINMAIN_FRAME.InitializationStruct[RSP]
  CALL Initialization_Demo

@Entry_Exit:
  XOR RCX, RCX
  CALL ExitProcess

NESTED_END WinMain, _TEXT$00

END