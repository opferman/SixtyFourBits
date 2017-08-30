;*********************************************************
; Wormhole Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2017
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
include master.inc
include vpal_public.inc
include font_public.inc

extern LocalAlloc:proc
extern LocalFree:proc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR10        dq ?
    SaveR11        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

FUNC_PARAMS struct
    ReturnAddress  dq ?
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
FUNC_PARAMS ends

WH_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
WH_DEMO_STRUCTURE ends

WH_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
WH_DEMO_STRUCTURE_FUNC ends

public WormHole_Init
public WormHole_Demo
public WormHole_Free

extern time:proc
extern srand:proc
extern rand:proc

MAX_COLORS EQU <256+256+256+256+256+256>
.DATA

DoubleBuffer   dq ?
VirtualPallete dq ?
FrameCountDown dd 4000
Red            db 0h
Blue           db 0h
Green          db 0h
ColorInc       dw 1h
ColorOffset    dw 0

.CODE

;*********************************************************
;   WormHole_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Init, _TEXT$00
 alloc_stack(SIZEOF WH_DEMO_STRUCTURE)
 save_reg rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  MOV RSI, RCX

  MOV [VirtualPallete], 0

  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  SHL RDX, 1    ; Turn Buffer into WORD values
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @PalInit_Failed

  MOV RCX, MAX_COLORS
  CALL VPal_Create
  TEST RAX, RAX
  JZ @PalInit_Failed

  MOV [VirtualPallete], RAX

  XOR R12, R12

@PopulatePallete:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  INC [Blue]

  INC R12
  CMP R12, 256
  JB @PopulatePallete


@PopulatePallete2:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  INC [Red]

  INC R12
  CMP R12, 256+256
  JB @PopulatePallete2


  @PopulatePallete3:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  INC [Green]

  INC R12
  CMP R12, 256+256+256
  JB @PopulatePallete3

 @PopulatePallete4:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  DEC [Blue]

  INC R12
  CMP R12, 256+256+256+256
  JB @PopulatePallete4

 @PopulatePallete5:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  DEC [Red]

  INC R12
  CMP R12, 256+256+256+256+256
  JB @PopulatePallete5


 @PopulatePallete6:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  DEC [Green]
  INC [Red]

  INC R12
  CMP R12, 256+256+256+256+256+256
  JB @PopulatePallete6

  MOV R12, 1024-51
  MOV R10, 1

@PlotCircles:
  MOV R9, R10
  MOV R8, 768/2
  MOV RDX, 1024/2
  MOV RCX, RSI
  CALL WormHole_DrawCircle   
  INC R10

@skipit:
  CMP R10, 768/2 - 10
  JB @PlotCircles

  MOV r10, [DoubleBuffer]
  XOR R12, r12
  XOR R9, R9

 @FillScreenInit:

      CMP WORD PTR [r10], 0
	  JNE @SkipPixel

	  MOV CX, [ColorInc]
	  MOV WORD PTR [r10], CX

	  INC [ColorInc]
      CMP  [ColorInc], MAX_COLORS
      JB @SkipPixel
      MOV [ColorInc], 1

@SkipPixel:
      Add r10, 2
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
      JB @FillScreenInit

   ; Screen Height Increment

   XOR r12, r12
   INC R9

   CMP R9, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
   JB @FillScreenInit

;@PlotCircles2:
;  MOV R9, R12
;  MOV R8, 350
;  MOV RDX, 500
;  MOV RCX, RSI
;  CALL WormHole_DrawCircle   
;  INC R12

;  CMP R12, 100
  ;JB @PlotCircles2
 
  
  MOV RSI, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WH_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@PalInit_Failed:
  MOV RSI, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WH_DEMO_STRUCTURE
  XOR RAX, RAX
  RET
NESTED_END WormHole_Init, _TEXT$00



;*********************************************************
;  WormHole_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Demo, _TEXT$00
 alloc_stack(SIZEOF WH_DEMO_STRUCTURE)
 save_reg rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, WH_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, WH_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, WH_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  MOV RDI, RCX

  ;
  ; Update the screen with the buffer
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [DoubleBuffer]

  XOR R9, R9
  XOR r12, r12

@FillScreen:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
      MOV DX, WORD PTR [r13] ; Get Virtual Pallete Index
      MOV RCX, [VirtualPallete]
      CALL VPal_GetColorIndex 

      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX

      ; Increment to the next location
      ADD RSI, 4
      Add R13, 2
  
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
   INC R9

   CMP R9, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen

   ;
   ; Rotate the pallete by 1.  This is the only animation being performed.
   ;
   MOV RDX, 1
   MOV RCX, [VirtualPallete]
   CALL  VPal_Rotate
    
   MOV rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
   MOV rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
   MOV rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

   MOV r10, WH_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
   MOV r11, WH_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
   MOV r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
   MOV r13, WH_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

   ADD RSP, SIZE WH_DEMO_STRUCTURE
  
   DEC [FrameCountDown]
   MOV EAX, [FrameCountDown]
   RET
NESTED_END WormHole_Demo, _TEXT$00



;*********************************************************
;  WormHole_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Free, _TEXT$00
 alloc_stack(SIZEOF WH_DEMO_STRUCTURE)
 save_reg rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE WH_DEMO_STRUCTURE
  RET
NESTED_END WormHole_Free, _TEXT$00






;*********************************************************
;  WormHole_DrawCircle
;
;        Parameters: Master Context, X, Y, Radius
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_DrawCircle, _TEXT$00
 alloc_stack(SIZEOF WH_DEMO_STRUCTURE)
 save_reg rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, WH_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, WH_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, WH_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 

MOV  [ColorOffset], 0
 
 MOV RSI, RCX
 MOV R10, R9 ; Radius
 MOV R11, R8  ; Y Center
 MOV R12, RDX ; X Center
 
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

 ;
 ; Quadrant 1.1
 ; 

@PlotQudrant_1_1_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  ADD RCX, RDI
  MUL RCX

  ADD RAX, R12
  ADD RAX, RBX
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  INC  [ColorInc]
  INC  [ColorOffset]
  CMP  [ColorInc], MAX_COLORS
  JB @NoColorRest_1_1
  MOV [ColorInc], 0
@NoColorRest_1_1:

  CMP R13, 0
  JG @Check_Second_Error_1_1

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_1_1:  
  CMP R13, 0
  JLE @Check_Loop_Condition_1_1

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  SHL RAX, 1
  NEG RAX
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_1_1:
  CMP RBX, RDI
  JGE @PlotQudrant_1_1_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

 MOV CX, [ColorOffset]
 ADD [ColorInc], CX
 ;
 ; Quadrant 1.2
 ; 
 @PlotQudrant_1_2_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  ADD RCX, RBX
  MUL RCX

  ADD RAX, R12
  ADD RAX, RDI
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  DEC  [ColorInc]
  CMP  [ColorInc], 0
  JNE @NoColorRest_1_2
  MOV [ColorInc], 1
@NoColorRest_1_2:


  CMP R13, 0
  JG @Check_Second_Error_1_2

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_1_2:  
  CMP R13, 0
  JLE @Check_Loop_Condition_1_2

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_1_2:
  CMP RBX, RDI
  JGE @PlotQudrant_1_2_Pixel
  ;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

 MOV CX, [ColorOffset]
 ADD [ColorInc], CX
 ;
 ; Quadrant 2.1
 ; 
 @PlotQudrant_2_1_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  ADD RCX, RBX
  MUL RCX

  ADD RAX, R12
  SUB RAX, RDI
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  INC  [ColorInc]
  CMP  [ColorInc], MAX_COLORS
  JB @NoColorRest2_1
  MOV [ColorInc], 0
@NoColorRest2_1:

  CMP R13, 0
  JG @Check_Second_Error_2_1

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_2_1:  
  CMP R13, 0
  JLE @Check_Loop_Condition_2_1

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_2_1:
  CMP RBX, RDI
  JGE @PlotQudrant_2_1_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

 MOV CX, [ColorOffset]
 ADD [ColorInc], CX

 ;
 ; Quadrant 2.2
 ; 
 @PlotQudrant_2_2_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  ADD RCX, RDI
  MUL RCX

  ADD RAX, R12
  SUB RAX, RBX
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  DEC  [ColorInc]
  CMP  [ColorInc], 0
  JNE @NoColorRest_2_2
  MOV [ColorInc], 1
@NoColorRest_2_2:

  CMP R13, 0
  JG @Check_Second_Error_2_2

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_2_2:  
  CMP R13, 0
  JLE @Check_Loop_Condition_2_2

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_2_2:
  CMP RBX, RDI
  JGE @PlotQudrant_2_2_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction
 MOV CX, [ColorOffset]
 ADD [ColorInc], CX
 ;
 ; Quadrant 3.1
 ; 
 @PlotQudrant_3_1_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  SUB RCX, RDI
  MUL RCX

  ADD RAX, R12
  SUB RAX, RBX
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  INC  [ColorInc]
  CMP  [ColorInc], MAX_COLORS
  JB @NoColorRest_3_1
  MOV [ColorInc], 0
@NoColorRest_3_1:

  CMP R13, 0
  JG @Check_Second_Error_3_1

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_3_1:  
  CMP R13, 0
  JLE @Check_Loop_Condition_3_1

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_3_1:
  CMP RBX, RDI
  JGE @PlotQudrant_3_1_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction
 MOV CX, [ColorOffset]
 ADD [ColorInc], CX

 ;
 ; Quadrant 3.2
 ; 
 @PlotQudrant_3_2_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  SUB RCX, RBX
  MUL RCX

  ADD RAX, R12
  SUB RAX, RDI
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  DEC  [ColorInc]
  CMP  [ColorInc], 0
  JNE @NoColorRest_3_2
  MOV [ColorInc], 1
@NoColorRest_3_2:

  CMP R13, 0
  JG @Check_Second_Error_3_2

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_3_2:  
  CMP R13, 0
  JLE @Check_Loop_Condition_3_2

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_3_2:
  CMP RBX, RDI
  JGE @PlotQudrant_3_2_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction
 MOV CX, [ColorOffset]
 ADD [ColorInc], CX


 ;
 ; Quadrant 4.1
 ; 
 @PlotQudrant_4_1_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  SUB RCX, RBX
  MUL RCX

  ADD RAX, R12
  ADD RAX, RDI
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  INC  [ColorInc]
  CMP  [ColorInc], MAX_COLORS
  JB @NoColorRest_4_1
  MOV [ColorInc], 0
@NoColorRest_4_1:

  CMP R13, 0
  JG @Check_Second_Error_4_1

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_4_1:  
  CMP R13, 0
  JLE @Check_Loop_Condition_4_1

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_4_1:
  CMP RBX, RDI
  JGE @PlotQudrant_4_1_Pixel

;
; Re-Init
;
 XOR RDI, RDI ; y Increment
 MOV RBX, R10
 DEC RBX      ; x Increment

 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, R10
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

 MOV CX, [ColorOffset]
 ADD [ColorInc], CX

 ;
 ; Quadrant 4.2
 ; 
  @PlotQudrant_4_2_Pixel:
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, R11
  SUB RCX, RDI
  MUL RCX

  ADD RAX, R12
  ADD RAX, RBX
  SHL RAX, 1

  ADD RAX,[DoubleBuffer]
  MOV CX, [ColorInc]
  MOV WORD PTR [RAX], CX
  DEC  [ColorInc]
  CMP  [ColorInc], 0
  JNE @NoColorRest_4_2
  MOV [ColorInc], 1
@NoColorRest_4_2:

  CMP R13, 0
  JG @Check_Second_Error_4_2

  INC RDI
  ADD R13, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error_4_2:  
  CMP R13, 0
  JLE @Check_Loop_Condition_4_2

  DEC RBX
  ADD WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, R10
  NEG RAX
  SHL RAX, 1
  ADD RAX, WH_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  

@Check_Loop_Condition_4_2:
  CMP RBX, RDI
  JGE @PlotQudrant_4_2_Pixel




  MOV rdi, WH_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WH_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WH_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r10, WH_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, WH_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, WH_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, WH_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE WH_DEMO_STRUCTURE
  RET
NESTED_END WormHole_DrawCircle, _TEXT$00





END