;*********************************************************
; Copper Bars Demo 
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
include demoprocs.inc
include master.inc
include vpal_public.inc
include font_public.inc
include debug_public.inc
include dbuffer_public.inc

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
    SaveR14        dq ?
    SaveR15        dq ?
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

COPPERBARS_FIELD_ENTRY struct
   X              dq ?
   Y              dq ?
   StartColor     dw ?
   Velocity       dq ?
COPPERBARS_FIELD_ENTRY ends

COPPERBARS_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
COPPERBARS_DEMO_STRUCTURE ends

COPPERBARS_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
COPPERBARS_DEMO_STRUCTURE_FUNC ends

MAX_HORZ_BARS     EQU <4>
MAX_VERTICLE_BARS EQU <200>
VBAR_LOWER_BOUNDS EQU <10>
VBAR_UPPER_BOUNDS EQU <1000>

public CopperBarsDemo_Init
public CopperBarsDemo_Demo
public CopperBarsDemo_Free


.DATA
  DoubleBuffer     dq ?
  VirtualPallete   dq ?
  FrameCountDown   dd 2800
  CopperBarsVert   dq ?
  CopperBarsVert2  dq ?
  CopperBarsHorz   dq ?
  Opacity          mmword 0.80
  InverseOpacity   mmword 0.20
  WaitState        dq 3
.CODE

;*********************************************************
;   CopperBarsDemo_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Init, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [VirtualPallete], 0
    
  MOV RDX, 2
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CopperInit_Failed

  MOV RCX, 65536
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @CopperInit_Failed

  MOV [VirtualPallete], RAX

  MOV RDX, 0D37373h
  MOV RCX, 10
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 2F29C4h
  MOV RCX, 20
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 9390BEh
  MOV RCX, 30
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 0CBC13Dh
  MOV RCX, 40
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 6C762Eh
  MOV RCX, 50
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 0C3CC1B0h
  MOV RCX, 60
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 143B95h
  MOV RCX, 70
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 07F8081h
  MOV RCX, 80
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 082875h
  MOV RCX, 90
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 0D23333h
  MOV RCX, 100
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  MOV RDX, 066009Ch
  MOV RCX, 110
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBarColor

  
  MOV RDX, 049619Ah
  MOV RCX, 200
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateBackgroundColor

  MOV RDX, 200
  MOV RCX, 110
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateTransparancy
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateHorzBars

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateVertBars

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateVertBars
    
  MOV RSI, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@CopperInit_Failed:
  MOV RSI, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  XOR EAX, EAX
  RET
NESTED_END CopperBarsDemo_Init, _TEXT$00



;*********************************************************
;   CopperBarsDemo_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Demo, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR15
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

  ;
  ; Update the screen with the buffer
  ;  
   MOV RCX, [DoubleBuffer]
   MOV RDX, [VirtualPallete]
   MOV R8, DB_FLAG_CLEAR_BUFFER
   DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

   MOV RDX, [CopperBarsVert]
   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_MoveVertBars

   MOV RDX, [CopperBarsVert2]
   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_MoveVertBars
   
   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_MoveHorzBars

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_CreateBackground
   
   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_PlotHBars

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_PlotVBars


  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END CopperBarsDemo_Demo, _TEXT$00



;*********************************************************
;  CopperBarsDemo_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Free, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free

  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarsDemo_Free, _TEXT$00


;*********************************************************
;  CopperBarDemo_CreateVertBars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateVertBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, 5
  LEA RDI, [CopperBarsVert]
  CMP QWORD PTR [RDI], 0
  JZ @PopulateFirst
    
  LEA RDI, [CopperBarsVert2]
  
  MOV RBX, -5
  
@PopulateFirst:
  MOV RDX, SIZEOF COPPERBARS_FIELD_ENTRY * MAX_VERTICLE_BARS 
  MOV RCX, 040h   
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [RDI], RAX
  TEST RAX, RAX
  JZ @FailedCreateVert
  
  MOV RDI, RAX
  MOV RSI, MAX_VERTICLE_BARS
  MOV R12, 300
@CopperBarsCreate:
  
  MOV RAX, RSI
  ADD RAX, 200
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], R12
  ADD R12, RBX

  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, 10
  DIV RCX
  INC RDX
  MOV RCX, RDX
  MOV RAX, 10
  XOR RDX, RDX
  MUL RCX
  MOV COPPERBARS_FIELD_ENTRY.StartColor[RDI], AX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RBX

  ADD RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  DEC RSI
  DEC RSI
  CMP RSI, 0
  JA @CopperBarsCreate

@FailedCreateVert:
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]

  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateVertBars, _TEXT$00

;*********************************************************
;  CopperBarDemo_CreateHorzBars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateHorzBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RDX, SIZEOF COPPERBARS_FIELD_ENTRY * MAX_HORZ_BARS 
  MOV RCX, 040h   
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [CopperBarsHorz], RAX
  TEST RAX, RAX
  JZ @FailedCreateVert
  
  MOV RDI, [CopperBarsHorz]
  XOR RSI, RSI
  MOV R8, 10
@CopperBarsHorzCreate:
  MOV RCX, 50
  IMUL RCX, RSI
  MOV RAX, RCX
  ADD RAX, 200
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], 0
  MOV COPPERBARS_FIELD_ENTRY.StartColor[RDI], 110
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], R8
  SUB R8, 2

  ADD RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI
  CMP RSI,MAX_HORZ_BARS
  JB @CopperBarsHorzCreate

@FailedCreateVert:
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateHorzBars, _TEXT$00




;*********************************************************
;  CopperBarDemo_MoveVertBars
;
;        Parameters: Master Context, Verticle Bars
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveVertBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13
 save_reg r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RDI, RDX
  XOR RSI, RSI
  MOV R13, -1
  MOV R14, 8
@CopperBarsPlot:
  XOR RDX, RDX

  MOV RAX, COPPERBARS_FIELD_ENTRY.Velocity[RDI]
  ADD RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX

  CMP RAX, VBAR_LOWER_BOUNDS
  JG @CheckUpperBounds

  MOV COPPERBARS_FIELD_ENTRY.X[RDI], VBAR_LOWER_BOUNDS + 1
  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocity
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@AdjustVelocity:
  CMP RDX, 4
  JA @NotOutOfBounds
  ADD RDX, 4
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@CheckUpperBounds:
  ADD RAX, 21
  CMP RAX, VBAR_UPPER_BOUNDS
  JL @NotOutOfBounds
  
  MOV RAX, VBAR_UPPER_BOUNDS 
  SUB RAX, 22
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX
  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocityNeg
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@AdjustVelocityNeg:
  CMP RDX, 4
  JA @SkipIncrease
  ADD RDX, 4
@SkipIncrease:
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
@NotOutOfBounds:
  CMP RSI, 0
  JE @SkipPreviousXAlignmentCheck
  
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV RCX, R13
  SUB RCX, 18
  CMP RAX, RCX
  JG @CheckUpperBoundsOfPreviousBar
  INC RCX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RCX

  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX

  CMP R14, 8
  JE @AdjustVelocity2
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck

@AdjustVelocity2:
  CMP RDX, 4
  JA @DontAdjustVel
   ADD RDX, 4

@DontAdjustVel:
   MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck

@CheckUpperBoundsOfPreviousBar:
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV RCX, R13
  ADD RCX, 18
  CMP RAX, RCX
  JL @SkipPreviousXAlignmentCheck

  DEC RCX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RCX

  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocity3
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck
@AdjustVelocity3:
  CMP RDX, 4
  JA @DoNotAdjustVelocity
  ADD RDX, 4
@DoNotAdjustVelocity:
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
@SkipPreviousXAlignmentCheck:
  MOV R14, 3
  MOV R13, COPPERBARS_FIELD_ENTRY.X[RDI]
  ADD RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI  
  CMP RSI, MAX_VERTICLE_BARS
  JB @CopperBarsPlot
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  MOV r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET

NESTED_END CopperBarDemo_MoveVertBars, _TEXT$00

;*********************************************************
;  CopperBarDemo_MoveHorzBars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveHorzBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RDI, [CopperBarsHorz]
  MOV RSI, [CopperBarsHorz]
  XOR R13, R13

@CopperBarsMove:
  CMP R13, 0
  JNE @PlotFollowers

  CMP [WaitState], 3
  JB @Complete

  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  ADD RAX, COPPERBARS_FIELD_ENTRY.Velocity[RDI]
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  CMP RAX, 100 
  JA @CheckUpperBounds
  MOV [WaitState], 0
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], 100
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], 10
  JMP @Complete

@CheckUpperBounds:
  CMP RAX, 700
  JB @Complete
  MOV [WaitState], 0
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], 700
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], -10
  JMP @Complete
@PlotFollowers:
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RSI]
  MOV RCX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  CMP RCX, RAX
  JB @MoveFromLower
  MOV RAX, COPPERBARS_FIELD_ENTRY.Velocity[RDI]
  SUB COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  SUB RAX, 20
  CMP COPPERBARS_FIELD_ENTRY.Y[RSI], RAX
  JB @Complete
  INC [WaitState]
  JMP @Complete
@MoveFromLower:
  MOV RAX, COPPERBARS_FIELD_ENTRY.Velocity[RDI]
  ADD COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  ADD RAX, 20
  CMP COPPERBARS_FIELD_ENTRY.Y[RSI], RAX
  JA @Complete
  INC [WaitState]
@Complete:
  
  ADD RDI, SIZE COPPERBARS_FIELD_ENTRY
  INC R13
  CMP R13,MAX_HORZ_BARS
  JB @CopperBarsMove
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_MoveHorzBars, _TEXT$00

;*********************************************************
;  CopperBarDemo_PlotVBars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_PlotVBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13
 save_reg r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR15
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R14, RCX

  MOV RSI, [CopperBarsVert2]
  MOV RDI, [CopperBarsVert]
  XOR RDX, RDX
  MOV RAX, MAX_VERTICLE_BARS/2
  MOV RCX, SIZE COPPERBARS_FIELD_ENTRY
  MUL RCX
  ADD RDI, RAX
  SUB RDI, SIZE COPPERBARS_FIELD_ENTRY
  ADD RSI, RAX
  SUB RSI, SIZE COPPERBARS_FIELD_ENTRY
  XOR R11, R11
@CopperBarsPlot:
  XOR RDX, RDX
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  MOV R13, RAX
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R14]
  SHL RCX, 1
  MUL RCX
  MOV RCX, [DoubleBuffer]
  ADD RCX, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  SHL RAX, 1
  ADD RCX, RAX
  MOV AX, COPPERBARS_FIELD_ENTRY.StartColor[RDI]
  MOV BX, AX

  XOR RDX, RDX
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RSI]
  MOV R13, RAX
  MOV R10, MASTER_DEMO_STRUCT.ScreenWidth[R14]
  SHL R10, 1
  MUL R10
  MOV RDX, [DoubleBuffer]
  ADD RDX, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RSI]
  SHL RAX, 1
  ADD RDX, RAX
  MOV AX, BX
  MOV BX, COPPERBARS_FIELD_ENTRY.StartColor[RDI]

  XOR R9, R9
@PlotX:
  
  XOR R8, R8
  MOV R15, R13
@PlotY:
  MOV [RCX + R8], AX
  MOV [RDX + R8], BX
  MOV R10, MASTER_DEMO_STRUCT.ScreenWidth[R14]
  SHL R10, 1
  ADD R8, R10
  INC R15
  CMP R15, 767
  JB @PlotY

  INC R9
  CMP R9, 10
  JB @IncrementColor
  DEC AX
  DEC BX
  JMP @SkipIncrement
@IncrementColor:
  INC AX
  INC BX
@SkipIncrement:
  ADD RCX, 2
  ADD RDX, 2
  CMP R9, 19
  JB @PlotX
  SUB RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  SUB RSI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC R11  
  INC R11
  CMP R11, MAX_VERTICLE_BARS
  JB @CopperBarsPlot
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  MOV r14, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_PlotVBars, _TEXT$00


;*********************************************************
;  CopperBarDemo_PlotHBars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_PlotHBars, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RSI, [CopperBarsHorz]
  XOR R13, R13

@StartPlotBar:  
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  XOR RDX, RDX
  MOV RDI, COPPERBARS_FIELD_ENTRY.Y[RSI]
  MUL RDI
  SHL RAX, 1
  MOV RDI, RAX
  ADD RDI, [DoubleBuffer]
  
  MOV AX, COPPERBARS_FIELD_ENTRY.StartColor[RSI]
  XOR RDX, RDX

@PlotHorizontal:
;  CMP R13, 0
;  JA @TransparentBars  transparency needs work, disable it for now.
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  REP STOSW
  JMP @NextLine
@TransparentBars:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  SHL AX, 8
@NextPixel:
  ADD WORD PTR [RDI], AX
  ADD RDI, 2
  DEC RCX  
  JNZ @NextPixel
  SHR AX, 8
@NextLine:
  INC RDX
  CMP RDX, 10
  JB @IncrementColor
  DEC AX
  JMP @CheckHorzLines
@IncrementColor:
  INC AX
@CheckHorzLines:
  CMP RDX, 20
  JB @PlotHorizontal

  INC R13
  ADD RSI, SIZE COPPERBARS_FIELD_ENTRY

  CMP R13, MAX_HORZ_BARS
  JB @StartPlotBar
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_PlotHBars, _TEXT$00

;*********************************************************
;  CopperBarDemo_CreateBackground
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateBackground, _TEXT$00
 alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
 save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RCX, [DoubleBuffer]
  MOV R12, 200
  XOR R8, R8
  XOR R9, R9
@BackgroundPlot:
  MOV RAX, R12
  MOV [RCX], AX
  ADD RCX, 2
  INC R8
  CMP R8, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  JB @BackgroundPlot
  INC R12
  CMP R12, 250
  JB @ColorStillValid
  MOV R12, 200
@ColorStillValid:
  XOR R8, R8
  INC R9
  CMP R9, MASTER_DEMO_STRUCT.ScreenHeight[RBX]
  JB @BackgroundPlot
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateBackground, _TEXT$00

;*********************************************************
;  CopperBarDemo_CreateBarColor
;
;        Parameters: Start Index, Start Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateBarColor, _TEXT$00
  alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
  save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
  save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
  .ENDPROLOG 

   XOR EBX, EBX
   MOV R12, 10
   MOV RDI, RCX
   MOV RSI, RDX

@CreateCopperBarColor:
   MOV RAX, RSI
   MOV DL, AL
   SHR RAX, 8
   ADD DL, 5
   ADD AL, 5
   ADD AH, 5
   SHL RAX, 8
   MOV AL, DL
   MOV RSI, RAX

   MOV R8, RAX
   MOV RDX, RBX
   ADD RDX, RDI
   MOV RCX, [VirtualPallete]
   DEBUG_FUNCTION_CALL VPal_SetColorIndex

   DEC R12
   INC RBX
   CMP EBX, 10
   JB @CreateCopperBarColor
   
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateBarColor, _TEXT$00


;*********************************************************
;  CopperBarDemo_CreateBackgroundColor
;
;        Parameters: Start Index, Start Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateBackgroundColor, _TEXT$00
  alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
  save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
  save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
  .ENDPROLOG 

   XOR EBX, EBX
   MOV RDI, RCX
   MOV RSI, RDX

@CreateCopperBarColor:
   MOV RAX, RSI
   MOV DL, AL
   SHR RAX, 8
   ADD DL, 1
   ADD AL, 1
   ADD AH, 1
   SHL RAX, 8
   MOV AL, DL
   MOV RSI, RAX
   MOV R8, RAX
   MOV RDX, RBX
   ADD RDX, RDI
   MOV RCX, [VirtualPallete]
   DEBUG_FUNCTION_CALL VPal_SetColorIndex
   INC RBX
   CMP EBX, 50
   JB @CreateCopperBarColor



  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateBackgroundColor, _TEXT$00


;*********************************************************
;  CopperBarDemo_CreateTransparancy
;
;        Parameters: Start Index, Start Background
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateTransparancy, _TEXT$00
  alloc_stack(SIZEOF COPPERBARS_DEMO_STRUCTURE)
  save_reg rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx
  save_reg r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12
  .ENDPROLOG 

   MOV RDI, RCX
   MOV RSI, RDX

@CreateTransparancyOutterLoop:
  MOV RDX, RDI
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_GetColorIndex
  MOV R12, RAX
  MOV RBX, RSI

@CreateTransparancyInnerLoop:
  MOV RDX, RBX
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_GetColorIndex

  ; New Color = Opacity * Color + (1-Opacity) * Background

  MOVSD xmm0, [Opacity]
  MOV RDX, RAX
  MOV RCX, R12
  AND RCX, 0FFh
  AND RDX, 0FFh
  CVTSI2SD xmm1, RCX
  MULSD xmm1, xmm0
  CVTSI2SD xmm2, RDX
  MOVSD xmm0, [InverseOpacity]
  MULSD xmm2, xmm0
  ADDSD xmm1, xmm2
  CVTSD2SI RDX, xmm1
  MOV R8, RDX

  MOVSD xmm0, [Opacity]
  MOV RDX, RAX
  MOV RCX, R12
  SHL RCX, 8
  AND RCX, 0FFh
  SHL RCX, 8
  AND RDX, 0FFh
  CVTSI2SD xmm1, RCX
  MULSD xmm1, xmm0
  CVTSI2SD xmm2, RDX
  MOVSD xmm0, [InverseOpacity]
  MULSD xmm2, xmm0
  ADDSD xmm1, xmm2
  CVTSD2SI RDX, xmm1
  SHL RDX, 8
  OR R8, RDX

  MOVSD xmm0, [Opacity]
  MOV RDX, RAX
  MOV RCX, R12
  SHL RCX, 16
  AND RCX, 0FFh
  SHL RDX, 16
  AND RDX, 0FFh
  CVTSI2SD xmm1, RCX
  MULSD xmm1, xmm0
  CVTSI2SD xmm2, RDX
  MOVSD xmm0, [InverseOpacity]
  MULSD xmm2, xmm0
  ADDSD xmm1, xmm2
  CVTSD2SI RDX, xmm1
  SHL RDX, 16
  OR R8, RDX

  MOV RDX, RDI
  SHL RDX, 8
  ADD RDX, RBX
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  INC RBX
  CMP RBX, 250
  JB @CreateTransparancyInnerLoop

  
  INC RDI
  CMP RDI, 120
  JB @CreateTransparancyOutterLoop



  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateTransparancy, _TEXT$00





END