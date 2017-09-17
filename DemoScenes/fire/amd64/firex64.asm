;*********************************************************
; Fire 
;
;  Written in Assembly x64
;
;  
; 
;  By Toby Opferman  2/27/2010-2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include demovariables.inc
include demoprocs.inc
include master.inc
include vpal_public.inc
include font_public.inc
include debug_public.inc

extern LocalAlloc:proc
extern LocalFree:proc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveRbp        dq ?
    Padding        dq ?
    SaveR14        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
    SaveR15        dq ?
SAVEREGSFRAME ends

FIRE_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
FIRE_DEMO_STRUCTURE ends

public Fire_Init
public Fire_Demo
public Fire_Free

extern time:proc
extern srand:proc
extern rand:proc

INFALTE_FONT EQU <12>
FRAME_TEXT EQU <150>

.DATA

 FirePalette       db 0h, 0h, 0h 
                   db 00h, 00h, 00h
                   db 01h, 00h, 01h
                   db 01h, 00h, 01h
                   db 02h, 00h, 02h
                   db 02h, 00h, 02h
                   db 03h, 00h, 03h
                   db 03h, 00h, 03h
                   db 03h, 00h, 04h
                   db 04h, 00h, 04h
                   db 04h, 00h, 05h
                   db 05h, 00h, 05h
                   db 05h, 00h, 05h
                   db 05h, 00h, 06h
                   db 06h, 00h, 06h
                   db 06h, 00h, 07h
                   db 07h, 00h, 07h
                   db 07h, 00h, 08h
                   db 08h, 00h, 08h
                   db 08h, 00h, 09h
                   db 08h, 00h, 09h
                   db 09h, 00h, 09h
                   db 09h, 00h, 0Ah
                   db 0Ah, 00h, 0Ah
                   db 0Ah, 00h, 0Bh
                   db 0Ah, 00h, 0Bh
                   db 0Bh, 00h, 0Ch
                   db 0Bh, 00h, 0Ch
                   db 0Ch, 00h, 0Dh
                   db 0Ch, 00h, 0Dh
                   db 0Dh, 00h, 0Eh
                   db 0Dh, 00h, 0Eh
                   db 0Dh, 00h, 0Eh
                   db 0Dh, 00h, 0Dh
                   db 0Eh, 00h, 0Ch
                   db 0Eh, 00h, 0Bh
                   db 0Fh, 01h, 0Ah
                   db 0Fh, 01h, 09h
                   db 10h, 01h, 08h
                   db 10h, 01h, 07h
                   db 11h, 01h, 07h
                   db 11h, 01h, 06h
                   db 12h, 01h, 05h
                   db 12h, 01h, 04h
                   db 13h, 02h, 03h
                   db 13h, 02h, 02h
                   db 14h, 02h, 01h
                   db 14h, 02h, 00h
                   db 15h, 02h, 00h
                   db 16h, 03h, 00h
                   db 17h, 03h, 00h
                   db 18h, 03h, 00h
                   db 18h, 04h, 01h
                   db 19h, 04h, 01h
                   db 1Ah, 04h, 01h
                   db 1Bh, 05h, 01h
                   db 1Ch, 05h, 01h
                   db 1Dh, 05h, 01h
                   db 1Eh, 05h, 01h
                   db 1Fh, 06h, 01h
                   db 1Fh, 06h, 01h
                   db 20h, 06h, 01h
                   db 21h, 07h, 01h
                   db 22h, 07h, 01h
                   db 23h, 07h, 01h
                   db 24h, 08h, 01h
                   db 24h, 08h, 02h
                   db 25h, 08h, 02h
                   db 26h, 09h, 02h
                   db 27h, 09h, 02h
                   db 28h, 0Ah, 02h
                   db 29h, 0Ah, 02h
                   db 2Ah, 0Bh, 02h
                   db 2Bh, 0Bh, 02h
                   db 2Ch, 0Ch, 02h
                   db 2Dh, 0Ch, 02h
                   db 2Eh, 0Dh, 02h
                   db 2Fh, 0Dh, 02h
                   db 2Fh, 0Dh, 03h
                   db 30h, 0Eh, 03h
                   db 31h, 0Eh, 03h
                   db 32h, 0Fh, 03h
                   db 33h, 0Fh, 03h
                   db 34h, 10h, 03h
                   db 35h, 10h, 03h
                   db 36h, 11h, 03h
                   db 37h, 11h, 03h
                   db 38h, 11h, 03h
                   db 39h, 12h, 03h
                   db 3Ah, 12h, 03h
                   db 3Ah, 13h, 04h
                   db 3Bh, 13h, 04h
                   db 3Ch, 14h, 04h
                   db 3Dh, 14h, 04h
                   db 3Eh, 15h, 04h
                   db 3Fh, 15h, 04h
                   db 3Fh, 15h, 04h
                   db 3Fh, 16h, 04h
                   db 3Fh, 17h, 04h
                   db 3Fh, 17h, 04h
                   db 3Fh, 18h, 05h
                   db 3Fh, 19h, 05h
                   db 3Fh, 19h, 05h
                   db 3Fh, 1Ah, 05h
                   db 3Fh, 1Bh, 05h
                   db 3Fh, 1Bh, 05h
                   db 3Fh, 1Ch, 05h
                   db 3Fh, 1Dh, 05h
                   db 3Fh, 1Dh, 06h
                   db 3Fh, 1Eh, 06h
                   db 3Fh, 1Fh, 06h
                   db 3Fh, 1Fh, 06h
                   db 3Fh, 20h, 06h
                   db 3Fh, 20h, 06h
                   db 3Fh, 21h, 06h
                   db 3Fh, 22h, 06h
                   db 3Fh, 22h, 07h
                   db 3Fh, 23h, 07h
                   db 3Fh, 24h, 07h
                   db 3Fh, 24h, 07h
                   db 3Fh, 25h, 07h
                   db 3Fh, 26h, 07h
                   db 3Fh, 26h, 07h
                   db 3Fh, 27h, 07h
                   db 3Fh, 28h, 08h
                   db 3Fh, 28h, 08h
                   db 3Fh, 29h, 08h
                   db 3Fh, 2Ah, 08h
                   db 3Fh, 2Ah, 08h
                   db 3Fh, 2Bh, 08h
                   db 3Fh, 2Ch, 08h
                   db 3Fh, 2Ch, 08h
                   db 3Fh, 2Dh, 09h
                   db 3Fh, 2Eh, 09h
                   db 3Fh, 2Eh, 09h
                   db 3Fh, 2Fh, 09h
                   db 3Fh, 30h, 09h
                   db 3Fh, 30h, 09h
                   db 3Fh, 31h, 09h
                   db 3Fh, 32h, 09h
                   db 3Fh, 32h, 0Ah
                   db 3Fh, 33h, 0Ah
                   db 3Fh, 34h, 0Ah
                   db 3Fh, 34h, 0Ah
                   db 3Fh, 35h, 0Ah
                   db 3Fh, 36h, 0Ah
                   db 3Fh, 36h, 0Ah
                   db 3Fh, 37h, 0Ah
                   db 3Fh, 38h, 0Bh
                   db 3Fh, 38h, 0Bh
                   db 3Fh, 39h, 0Bh
                   db 3Fh, 3Ah, 0Bh
                   db 3Fh, 3Ah, 0Bh
                   db 3Fh, 3Bh, 0Bh
                   db 3Fh, 3Ch, 0Bh
                   db 3Fh, 3Ch, 0Bh
                   db 3Fh, 3Dh, 0Ch
                   db 3Fh, 3Eh, 0Ch
                   db 3Fh, 3Eh, 0Ch
                   db 3Fh, 3Fh, 0Ch
                   db 3Fh, 3Fh, 0Ch
                   db 3Fh, 3Fh, 0Dh
                   db 3Fh, 3Fh, 0Dh
                   db 3Fh, 3Fh, 0Eh
                   db 3Fh, 3Fh, 0Eh
                   db 3Fh, 3Fh, 0Fh
                   db 3Fh, 3Fh, 0Fh
                   db 3Fh, 3Fh, 10h
                   db 3Fh, 3Fh, 10h
                   db 3Fh, 3Fh, 11h
                   db 3Fh, 3Fh, 11h
                   db 3Fh, 3Fh, 12h
                   db 3Fh, 3Fh, 12h
                   db 3Fh, 3Fh, 13h
                   db 3Fh, 3Fh, 14h
                   db 3Fh, 3Fh, 14h
                   db 3Fh, 3Fh, 15h
                   db 3Fh, 3Fh, 15h
                   db 3Fh, 3Fh, 16h
                   db 3Fh, 3Fh, 16h
                   db 3Fh, 3Fh, 17h
                   db 3Fh, 3Fh, 17h
                   db 3Fh, 3Fh, 18h
                   db 3Fh, 3Fh, 18h
                   db 3Fh, 3Fh, 19h
                   db 3Fh, 3Fh, 19h
                   db 3Fh, 3Fh, 1Ah
                   db 3Fh, 3Fh, 1Ah
                   db 3Fh, 3Fh, 1Bh
                   db 3Fh, 3Fh, 1Ch
                   db 3Fh, 3Fh, 1Ch
                   db 3Fh, 3Fh, 1Dh
                   db 3Fh, 3Fh, 1Dh
                   db 3Fh, 3Fh, 1Eh
                   db 3Fh, 3Fh, 1Eh
                   db 3Fh, 3Fh, 1Fh
                   db 3Fh, 3Fh, 1Fh
                   db 3Fh, 3Fh, 20h
                   db 3Fh, 3Fh, 20h
                   db 3Fh, 3Fh, 21h
                   db 3Fh, 3Fh, 21h
                   db 3Fh, 3Fh, 22h
                   db 3Fh, 3Fh, 23h
                   db 3Fh, 3Fh, 23h
                   db 3Fh, 3Fh, 24h
                   db 3Fh, 3Fh, 24h
                   db 3Fh, 3Fh, 25h
                   db 3Fh, 3Fh, 25h
                   db 3Fh, 3Fh, 26h
                   db 3Fh, 3Fh, 26h
                   db 3Fh, 3Fh, 27h
                   db 3Fh, 3Fh, 27h
                   db 3Fh, 3Fh, 28h
                   db 3Fh, 3Fh, 28h
                   db 3Fh, 3Fh, 29h
                   db 3Fh, 3Fh, 2Ah
                   db 3Fh, 3Fh, 2Ah
                   db 3Fh, 3Fh, 2Bh
                   db 3Fh, 3Fh, 2Bh
                   db 3Fh, 3Fh, 2Ch
                   db 3Fh, 3Fh, 2Ch
                   db 3Fh, 3Fh, 2Dh
                   db 3Fh, 3Fh, 2Dh
                   db 3Fh, 3Fh, 2Eh
                   db 3Fh, 3Fh, 2Eh
                   db 3Fh, 3Fh, 2Fh
                   db 3Fh, 3Fh, 2Fh
                   db 3Fh, 3Fh, 30h
                   db 3Fh, 3Fh, 31h
                   db 3Fh, 3Fh, 31h
                   db 3Fh, 3Fh, 32h
                   db 3Fh, 3Fh, 32h
                   db 3Fh, 3Fh, 33h
                   db 3Fh, 3Fh, 33h
                   db 3Fh, 3Fh, 34h
                   db 3Fh, 3Fh, 34h
                   db 3Fh, 3Fh, 35h
                   db 3Fh, 3Fh, 35h
                   db 3Fh, 3Fh, 36h
                   db 3Fh, 3Fh, 36h
                   db 3Fh, 3Fh, 37h
                   db 3Fh, 3Fh, 37h
                   db 3Fh, 3Fh, 38h
                   db 3Fh, 3Fh, 39h
                   db 3Fh, 3Fh, 39h
                   db 3Fh, 3Fh, 3Ah
                   db 3Fh, 3Fh, 3Ah
                   db 3Fh, 3Fh, 3Bh
                   db 3Fh, 3Fh, 3Bh
                   db 3Fh, 3Fh, 3Ch
                   db 3Fh, 3Fh, 3Ch
                   db 3Fh, 3Fh, 3Dh
                   db 3Fh, 3Fh, 3Dh
                   db 3Fh, 3Fh, 3Eh
                   db 3Fh, 3Fh, 3Eh
                   db 3Fh, 3Fh, 3Fh                      

                   
                  FrameTarget dd ?
                  FireBuffer  dq ?
                  StarBuffer  dq ?
                  TopWind     db ?
                  VirtualPallete dq ?
                  VirtualPalleteStars dq ?
                  Temp  dd ?
                  CurrentText dq ?

                  CometList dd 10, 11, 2, 2
                            dd 400, 11, 2, 2
                            dd 500, 11, -3, 2
                            dd 1, 11, 2, 3
                            dd 600, 11, -3, 3
                            dd 350, 11, 2, 3
                            dd 555, 11, -3, 3
                            dd 200, 11, 2, 3
                            dd 650, 11, -3, 3
                            dd -1

                  TextStart dd 350, 625 
                            db "Pure", 0
                            dd 250, 625 
                            db "x86-64", 0
                            dd 77, 625
                            db "Assembly", 0
                            dd 75, 625
                            db 1,1,1,1,1,1,1,1, 0
                            dd 10, 625
                            db  "JMP @Text", 0
                            ; ; Add more text
                            db 0

                  FrameCountDown dd 2500
.CODE

;*********************************************************
;   Fire_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Fire_Init, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Initialize Global Variables 
  ;
  MOV [VirtualPallete], 0
  MOV EAX, [FrameCountDown]
  SUB EAX, FRAME_TEXT
  MOV [FrameTarget], EAX

  LEA RAX, [TextStart]
  MOV [CurrentText], RAX

  ;
  ; Allocate Double Screen Buffer for Fire
  ;
  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [FireBuffer], RAX
  TEST RAX, RAX
  JZ @FireInit_Failed

  ;
  ; Allocate Double Screen Buffer for Stars
  ;
  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [StarBuffer], RAX
  TEST RAX, RAX
  JZ @FireInit_Failed

  ;
  ; Create Virtual Palette for Stars
  ;   
  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @FireInit_Failed

  MOV [VirtualPalleteStars], RAX

  XOR EAX, EAX
  XOR RDX, RDX

@PopulateStarPallete:
  MOV [Temp], EAX
  MOV R8, RAX
  MOV R12, RDX
  MOV RCX, [VirtualPalleteStars]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex
  MOV EAX, [Temp]
  ADD EAX, 010101h

  MOV RDX, R12
  INC RDX
  CMP RDX, 256
  JB @PopulateStarPallete

  ;
  ; Create Virtual Palette for Fire
  ; 
  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @FireInit_Failed

  MOV [VirtualPallete], RAX

  LEA RDI, [FirePalette]
  XOR RDX, RDX
  
@PopulatePallete:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [RDI]  
  SHL EAX, 16
  INC RDI

  ; Green
  MOV AL, BYTE PTR [RDI]
  SHL AX, 8
  INC RDI

  ; Blue
  MOV AL, BYTE PTR [RDI]
  INC RDI

  MOV R8, RAX
  MOV R12, RDX
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  MOV RDX, R12
  INC RDX
  CMP RDX, 256
  JB @PopulatePallete

  ;
  ; Initialize Graphics for Fire and Stars
  ; 

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Fire_RandomFillBottom
  
  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV R14, RAX
  MOV R13, [StarBuffer]
  ADD R14, R13

@PlotStars:
  
  DEBUG_FUNCTION_CALL Math_Rand

  CMP AX, 25
  JA @NoStarPlot
  DEBUG_FUNCTION_CALL Math_Rand
  MOV [R13], AL
 @NoStarPlot:
  INC R13

  CMP R13, R14
  JB @PlotStars
  
  MOV RSI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@FireInit_Failed:
  MOV RSI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  XOR RAX, RAX
  RET
NESTED_END Fire_Init, _TEXT$00



;*********************************************************
;  Fire_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_Demo, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX


  ;
  ; Plot the background stars
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [StarBuffer]

  XOR r14, r14
  XOR r12, r12

@FillScreenStars:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
      MOV DL, BYTE PTR [r13] ; Get Virtual Pallete Index

      MOV RCX, [VirtualPalleteStars]
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX

      ; Increment to the next location
      ADD RSI, 4
      INC r13
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreenStars

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreenStars


  ;
  ; Plot the fire buffer
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [FireBuffer]

  XOR r14, r14
  XOR r12, r12

@FillScreen:
      ;
      ; Get the Virtual Pallete Index for the pixe on the screen
      ;
      XOR EDX, EDX
      MOV DL, BYTE PTR [r13] ; Get Virtual Pallete Index

	  ;
	  ; Skip zero so the stars will show.  The stars have already zeroed out the screen also.
	  ;
      CMP DL, 0
      JE @SkipPlottingPixelItIszero
      MOV RCX, [VirtualPallete]
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX
@SkipPlottingPixelItIszero:
      ; Increment to the next location
      ADD RSI, 4
      INC r13
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen

  ;
  ; Update the fire graphics
  ;      
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Fire_RandomFillBottom

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Fire_MoveFire

  ;
  ; Words are displayed at certain frame intervals
  ; perform that check now.
  ;
  MOV EAX, [FrameCountDown]

  CMP EAX, [FrameTarget]
  JE @HandleNextWord

  ; Add more effects

  JMP  @DoneFireDemo
@HandleNextWord:

  ;
  ; Update the next target to display text
  ; 
  SUB [FrameTarget], FRAME_TEXT

  MOV RAX, [CurrentText]

  MOV R8D, [RAX]
  MOV R9D, [RAX+4]
  LEA RDX, [RAX+8]
  MOV RCX, RDI

  ADD RAX, 8
@NextWord:
  CMP BYTE PTR [RAX], 0
  JE @FoundNextWord
  INC RAX
  JMP @NextWord
  
@FoundNextWord:
  INC RAX
  CMP BYTE PTR [RAX], 0
  JNE @UpdateNextWord
  LEA RAX, [TextStart]
@UpdateNextWord:
  MOV [CurrentText], RAX
     
  DEBUG_FUNCTION_CALL Fire_PrintWord

@DoneFireDemo:
 
  ;
  ; Make the stars blink or flicker
  ;

  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MUL R9
  MOV R14, RAX
  MOV R13, [StarBuffer]
  ADD R14, R13

@PlotStars:
  CMP BYTE PTR [R13], 0
  JE @SkipUpdateStar
  
  MOV EAX, [FrameCountDown]
  AND AL, 0Fh

  CMP AL, 8
  JB @Decrement

  ADD BYTE PTR [R13], 2

JMP @SkipUpdateStar      
@Decrement:
  SUB BYTE PTR [R13], 2

@SkipUpdateStar:
  INC R13

  CMP R13, R14
  JB @PlotStars  

  ;
  ; Update the comets
  ;
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Fire_HandleComets
 
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE FIRE_DEMO_STRUCTURE

  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END Fire_Demo, _TEXT$00



;*********************************************************
;  Fire_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_Free, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free

  MOV RCX, [FireBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  DEBUG_FUNCTION_CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_Free, _TEXT$00



;*********************************************************
;  Fire_RandomFillBottom
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_RandomFillBottom, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
    
  MOV R12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  SUB RAX, 2
  MUL R12
  SHL R12, 1

  MOV R13, [FireBuffer]
  ADD R13, RAX

  CMP [FrameCountDown], 045h
  JBE @BlackOut

@FillBottomRow:
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, 256
  DIV RCX
  
  MOV BYTE PTR [R13], DL  ; Remainder
  INC R13
  DEC R12
  JNZ @FillBottomRow  

@ExitFunction:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
@BlackOut:

 
  MOV BYTE PTR [R13], 0 ; Blackout
  INC R13
  DEC R12
  JNZ @BlackOut

  JMP @ExitFunction

NESTED_END Fire_RandomFillBottom, _TEXT$00


;*********************************************************
;  Fire_PrintWord
;
;        Parameters: Master Context, String, X, Y
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_PrintWord, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
 save_reg r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR15
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV R14, RDX
  MOV R15, R8
  MOV R12, R9

@Fire_PrintStringLoop:

  XOR RCX, RCX
  MOV CL, [R14]
  DEBUG_FUNCTION_CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured
  MOV RCX, [FireBuffer]
  MOV R13, RAX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  XOR RDX, RDX
  MUL R12  
  ADD RCX, RAX
  MOV RAX, R13
  XOR RDX, RDX
  ADD RCX, R15
  XOR R13, R13
  MOV RSI, INFALTE_FONT
@VerticleLines:
  MOV BL, 80h
@HorizontalLines:
  TEST BL, [RAX]
  JZ @SkipBit
  ; Match INFALTE_FONT
  MOV DWORD PTR [RCX+RDX],   0FFFFFFFFh  
  MOV DWORD PTR [RCX+RDX+4], 0FFFFFFFFh
  MOV DWORD PTR [RCX+RDX+8], 0FFFFFFFFh  
@SkipBit:
  ADD RDX, INFALTE_FONT
  SHR BL, 1
  TEST BL, BL
  JNZ @HorizontalLines
  XOR RDX, RDX
  ADD RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  DEC RSI
  JNZ @VerticleLines 
  MOV RSI, INFALTE_FONT
  INC RAX
  INC R13
  CMP R13, 8
  JB @VerticleLines
  INC R14
  ADD R15, INFALTE_FONT * 8 + 3
  CMP BYTE PTR [R14], 0 
  JNE @Fire_PrintStringLoop
  MOV EAX, 1
@ErrorOccured:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  MOV r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_PrintWord, _TEXT$00


;*********************************************************
;  Fire_HandleComets
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_HandleComets, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

  DEBUG_FUNCTION_CALL Math_Rand
  MOV EBX, EAX
  AND EBX, 3h
  INC EBX
  INC EBX
  LEA R8, [CometList]

@CometLoop:
  CMP DWORD PTR [R8], -1
  JE @NoMoreComets

  ;
  ; Plot Coment
  ;
  MOV EAX,  DWORD PTR [R8+4]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MUL R9
  ADD EAX, DWORD PTR [R8]
  MOV R13, [FireBuffer]
  ADD RAX, R13
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV DWORD PTR [RAX], 0FFFFFFFFh ; Comet 
  ADD RAX, R9
  MOV DWORD PTR [RAX], 0FFFFFFFFh ; Comet 
  ADD RAX, R9
  MOV DWORD PTR [RAX], 0FFFFFFFFh ; Comet 
  ADD RAX, R9
  MOV DWORD PTR [RAX], 0FFFFFFFFh ; Comet 

  ;
  ; Update Comet Location
  ;
  MOV EAX, [R8 + 8]
  ADD [R8], EAX

  MOV EAX, [R8 + 12]
  ADD [R8 + 4], EAX
 
 ;
 ; Check Coment Bounds
 ;

  CMP DWORD PTR [R8], 0
  JLE @CometHitsLeft
  
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  SUB RAX, 10
  CMP DWORD PTR [R8], EAX
  JGE @CometHitsRight
  JMP @CometCheckYAxis

@CometHitsLeft:
  MOV DWORD PTR [R8], 0
  
  MOV [R8 + 8], EBX
  JMP @CometCheckYAxis

@CometHitsRight:
  MOV DWORD PTR [R8], EAX
  MOV [R8 + 8], EBX
  NEG DWORD PTR [R8 + 8]
  
@CometCheckYAxis:

  CMP DWORD PTR [R8+4], 10
  JLE @CometHitsTop
  
  CMP DWORD PTR [R8+4], 650
  JGE @CometHitsBottom

  JMP @GetNextComet

@CometHitsTop:
  MOV DWORD PTR [R8 + 4], 10
  MOV [R8 + 12], EBX
  JMP @GetNextComet

@CometHitsBottom:
  MOV DWORD PTR [R8 + 4], 650
  MOV [R8 + 12], EBX
  NEG DWORD PTR [R8 + 12]

@GetNextComet:
  
  ;
  ; Comets try to get different random velocity values
  ; so modify the new velocity assignment each round.
  ;
  INC EBX
  CMP EBX, 4
  JBE @Updated
  MOV EBX, 2

@Updated:
  ADD R8, 16

JMP @CometLoop

@NoMoreComets:

  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_HandleComets, _TEXT$00


;*********************************************************
;  Fire_MoveFire
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_MoveFire, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
 save_reg r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR15
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

  ;
  ; Start from the second to bottom row
  ;    
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  SUB RAX, 2
 
  ;
  ; Start at the second pixel inward.
  ;
  MOV r13, [FireBuffer]
  ADD r13, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  INC r13

  MOV r14, RAX
  MOV RBX, RCX

  XOR R15, R15

@MoveFireUp:
      DEBUG_FUNCTION_CALL Math_Rand
      MOV RCX, 3
	  XOR RDX, RDX
      DIV RCX

      MOV [TopWind], DL
      
      DEBUG_FUNCTION_CALL Math_Rand
      MOV RCX, 3
	  XOR RDX, RDX
      DIV RCX

      XOR ECX, ECX
      XOR EAX, EAX
              
      ;
      ; Get the pixels to determine the fire.  
      ;      
      ;  The algorithm is ((P+P+P+P/4)-1 = N)
      ;
      ;  Two Wind Options.
      ;
      ;             N     N      N
      ;            PPP    PPP  PPP
      ;             P       P  P



      MOV CL, [r13]
      MOV AL, CL
  
      MOV CL, [r13+1]
      ADD EAX, ECX
  
      MOV CL, [r13-1]
      ADD EAX, ECX

      ;
      ; Update for Wind
      ;
      DEC RDX
      ADD RDX, RBX
      MOV CL, [r13+RDX]

      ADD EAX, ECX
      SHR EAX, 2

      OR AL, AL
      JZ @PlotPixel

      DEC AL     ; Decay Pixels

@PlotPixel:
      ;
      ; Plot New Pixel
      ;
      MOV R12, r13
      SUB R12, RBX

      ;
      ; Implement the Top Wind.
      ;
      XOR EDX, EDX
      MOV DL, [TopWind]
      DEC RDX
      ADD R12, RDX       

      ;
      ; Plot the pixel
      ;
      MOV BYTE PTR [R12], AL

      INC r13
      INC R15
      MOV RCX, RBX
      DEC RCX
      CMP R15, RCX
      JB @MoveFireUp 

  XOR R15, R15
  ;
  ; Start at the second pixel inward.
  ;

  MOV RBX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  INC r13
  
  DEC r14
  JNZ  @MoveFireUp


 @SkipFreeingMem:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r14, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  MOV r15, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_MoveFire, _TEXT$00
END