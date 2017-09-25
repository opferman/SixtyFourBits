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
; include frameloop_public.inc
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


MAX_VERTICLE_BARS EQU <200>
VBAR_LOWER_BOUNDS EQU <300>
VBAR_UPPER_BOUNDS EQU <500>

public CopperBarsDemo_Init
public CopperBarsDemo_Demo
public CopperBarsDemo_Free


.DATA
  DoubleBuffer     dq ?
  VirtualPallete   dq ?
  FrameCountDown   dd 2800
  CopperBarsVert   dq ?
  CopperBarsHorz   dq ?
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

  MOV RDX, 0C3CC1D0h
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
  
;  MOV RCX, RSI
;  DEBUG_FUNCTION_CALL CopperBarDemo_CreateHorzBars

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateVertBars

;  LEA RCX, [FrameLoopList]
;  DEBUG_FUNCTION_CALL FrameLoop_Create
;  MOV [FrameLoopHandle], RAX
;  TEST RAX, RAX
;  JZ @CopperInit_Failed
    
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

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_MoveVertBars

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL CopperBarDemo_PlotVBars

;   MOV RCX, [FrameLoopHandle]
;   DEBUG_FUNCTION_CALL FrameLoop_PerformFrame
;   CMP RAX, 0
;   JNE @SkipReset
   
   ;LEA RCX, [FrameLoopList]
   ;MOV FRAMELOOP_ENTRY_CB.EndFrame[RCX], 5
   ;MOV FRAMELOOP_ENTRY_CB.StartFrame[RCX], 5

   ;MOV RCX, [FrameLoopHandle]
   ;DEBUG_FUNCTION_CALL FrameLoop_Reset

@SkipReset:
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
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RDX, SIZEOF COPPERBARS_FIELD_ENTRY * MAX_VERTICLE_BARS 
  MOV RCX, 040h   
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [CopperBarsVert], RAX
  TEST RAX, RAX
  JZ @FailedCreateVert
  
  MOV RDI, [CopperBarsVert]
  XOR RSI, RSI
  MOV R10, 500
@CopperBarsCreate:
  
  MOV RAX, RSI
  ADD RAX, 200
  MOV COPPERBARS_FIELD_ENTRY.Y[RDI], RAX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], R10
  ADD R10, 8

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
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], 3 

  ADD RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI
  INC RSI
  CMP RSI,MAX_VERTICLE_BARS
  JB @CopperBarsCreate

@FailedCreateVert:
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_CreateVertBars, _TEXT$00



;*********************************************************
;  CopperBarDemo_MoveVertBars
;
;        Parameters: Master Context
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

  MOV RDI, [CopperBarsVert]
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
  MOV RCX, 2
  DIV RCX
  INC RDX
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
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV RDI, [CopperBarsVert]
  XOR RSI, RSI
  XOR R13, R13
@CopperBarsPlot:
  XOR RDX, RDX
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  SHL RCX, 1
  MUL RCX
  MOV RCX, [DoubleBuffer]
  ADD RCX, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  SHL RAX, 1
  ADD RCX, RAX
  MOV AX, COPPERBARS_FIELD_ENTRY.StartColor[RDI]
  XOR R9, R9
@PlotX:
  
  XOR R8, R8
  MOV R11, R13
@PlotY:
  MOV [RCX + R8], AX
  MOV R10, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  SHL R10, 1
  ADD R8, R10
  INC R11
  CMP R11, 550
  JB @PlotY

  INC R9
  CMP R9, 10
  JB @IncrementColor
  DEC AX
  JMP @SkipIncrement
@IncrementColor:
  INC AX
@SkipIncrement:
  ADD RCX, 2
  CMP R9, 19
  JB @PlotX
  ADD R13, 2
  ADD RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI  
  INC RSI
  CMP RSI,MAX_VERTICLE_BARS
  JB @CopperBarsPlot
  
  MOV rdi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, COPPERBARS_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE COPPERBARS_DEMO_STRUCTURE
  RET
NESTED_END CopperBarDemo_PlotVBars, _TEXT$00

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
;  StarDemo_IncStarVelocity_CB
;
;        Parameters: Leaf function for updating Velocity
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_IncStarVelocity_CB, _TEXT$00
  .ENDPROLOG 
  RET
NESTED_END StarDemo_IncStarVelocity_CB, _TEXT$00


END