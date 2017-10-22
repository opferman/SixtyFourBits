;*********************************************************
; Tic Tac Toe Demo 
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
include frameloop_public.inc
include dbuffer_public.inc
include primatives_public.inc

CHECK_SELECT MACRO RegCheckMask, Constant, RegBlockMask
   LOCAL NotAMatch
   TEST RAX, RAX
   JNZ NotAMatch
   MOV R8, RegCheckMask
   AND R8, Constant
   XOR R8, Constant
   POPCNT RBX, R8
   CMP RBX, 1
   JNE NotAMatch
   MOV R9, RegBlockMask
   AND R9, R8
   XOR R8, R9
   MOV RAX, R8
NotAMatch:
ENDM

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
    Param8         dq ?
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


TTT_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
TTT_DEMO_STRUCTURE ends

TTT_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
TTT_DEMO_STRUCTURE_FUNC ends

public TTT_Init
public TTT_Demo
public TTT_Free



.DATA
  DoubleBuffer     dq ?
  VirtualPallete   dq ?
  FrameCountDown   dd 2800
  EndOfGamePause   dd 0
  EndOfGameActive  dd 0

  FrameLoopHandleCircle dq ?
  FrameLoopHandleX dq ?
  FrameLoopHandleCurrent dq ?
  MasterContext dq ?

  FrameLoopList_Circle   FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
                  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
                  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
                  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker

  FrameLoopList_X   FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
                  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
                  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
                  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_Circle, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
				  FRAMELOOP_ENTRY_CB <0, 0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 20, 20>
				  FRAMELOOP_ENTRY_CB <TTT_Plot_X, 0, RELATIVE_FROM_PREVIOUS_FRAME, 20, 20>
                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker
  
  CircleLocations dq 0
  XLocations      dq 0

.CODE

;*********************************************************
;   TTT_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY TTT_Init, _TEXT$00
 alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
 save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, TTT_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [VirtualPallete], 0
    
  MOV RDX, 1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @TTT_Failed

  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @TTT_Failed
  MOV [VirtualPallete], RAX
 
  MOV R8, 0FFFFFFh
  MOV RDX, 255
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  MOV R8, 0FF0000h
  MOV RDX, 10
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  LEA RCX, [FrameLoopList_Circle]
  DEBUG_FUNCTION_CALL FrameLoop_Create
  MOV [FrameLoopHandleCircle], RAX
  TEST RAX, RAX
  JZ @TTT_Failed

  LEA RCX, [FrameLoopList_X]
  DEBUG_FUNCTION_CALL FrameLoop_Create
  MOV [FrameLoopHandleX], RAX
  TEST RAX, RAX
  JZ @TTT_Failed

  MOV [FrameLoopHandleCurrent], RAX

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL TTT_CreateBoard
    
  MOV RSI, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, TTT_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@TTT_Failed:
  MOV RSI, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, TTT_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  XOR EAX, EAX
  RET
NESTED_END TTT_Init, _TEXT$00



;*********************************************************
;  TTT_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_Demo, _TEXT$00
 alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
 save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r14, TTT_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, TTT_DEMO_STRUCTURE.SaveFrame.SaveR15
 save_reg r12, TTT_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, TTT_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV [MasterContext], RDI

  ;
  ; Update the screen with the buffer
  ;  
  MOV RCX, [DoubleBuffer]
  MOV RDX, [VirtualPallete]
  XOR R8, R8
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

  CMP [EndOfGameActive], 1
  JNE @GameContinue

  DEC [EndOfGamePause]
  JNZ @SkipReset
  
  MOV [EndOfGameActive], 0

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL TTT_CreateBoard

  MOV RCX, [FrameLoopHandleCurrent]
  DEBUG_FUNCTION_CALL FrameLoop_Reset
    
@GameContinue:
  MOV RCX, [FrameLoopHandleCurrent]
  DEBUG_FUNCTION_CALL FrameLoop_PerformFrame
  CMP RAX, 0
  JNE @CheckWin
  MOV [EndOfGameActive], 1
  MOV [EndOfGamePause], 20
@CheckWin:
  MOV RCX, [CircleLocations]
  DEBUG_FUNCTION_CALL TTT_CheckWin
  CMP RAX, 0
  JNE @CircleWin

  MOV RCX, [XLocations]
  DEBUG_FUNCTION_CALL TTT_CheckWin
  CMP RAX, 0
  JNE @XWin
  JMP @SkipReset
@CircleWin:
  MOV [EndOfGameActive], 1
  MOV [EndOfGamePause], 20
  MOV RCX, [FrameLoopHandleCircle]
  MOV [FrameLoopHandleCurrent], RCX
  MOV RDI, RAX
  MOV RSI, 1

 @TryPlotCircleAgain:
  TEST RSI, RDI
  JZ @NextCircleCheck
  MOV RCX, RSI
  MOV RDX, 10
  DEBUG_FUNCTION_CALL TTT_DrawCircle

@NextCircleCheck:
  SHL RSI, 1
  TEST RSI, 800h
  JZ @TryPlotCircleAgain

  JMP @SkipReset

@XWin:
  MOV [EndOfGameActive], 1
  MOV [EndOfGamePause], 20
  MOV RCX, [FrameLoopHandleX]
  MOV [FrameLoopHandleCurrent], RCX
  MOV RDI, RAX
  MOV RSI, 1

 @TryPlotXAgain:
  TEST RSI, RDI
  JZ @NextXCheck
  MOV RCX, RSI
  MOV RDX, 10
  DEBUG_FUNCTION_CALL TTT_DrawX

@NextXCheck:
  SHL RSI, 1
  TEST RSI, 800h
  JZ @TryPlotXAgain

@SkipReset:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r14, TTT_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, TTT_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  MOV r12, TTT_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, TTT_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END TTT_Demo, _TEXT$00



;*********************************************************
;  TTT_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_Free, _TEXT$00
 alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
 save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_Free, _TEXT$00

;*********************************************************
;  TTT_CheckWin
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_CheckWin, _TEXT$00
 alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, RCX
  AND RAX, 07h
  CMP RAX, 07h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 070h
  CMP RAX, 070h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0700h
  CMP RAX, 0700h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0111h
  CMP RAX, 0111h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0222h
  CMP RAX, 0222h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0444h
  CMP RAX, 0444h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0124h
  CMP RAX, 0124h
  JE @WinFound

  MOV RAX, RCX
  AND RAX, 0421h
  CMP RAX, 0421h
  JE @WinFound

  XOR RAX, RAX

@WinFound:
  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_CheckWin, _TEXT$00


;*********************************************************
;  TTT_GetNextMove
;
;        Parameters: Current Player Bits, Opponent Bits
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_GetNextMove, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  XOR RAX, RAX
  CHECK_SELECT RDX, 07h, RCX
  CHECK_SELECT RDX, 070h, RCX
  CHECK_SELECT RDX, 0700h, RCX
  CHECK_SELECT RDX, 0111h, RCX
  CHECK_SELECT RDX, 0222h, RCX
  CHECK_SELECT RDX, 0444h, RCX
  CHECK_SELECT RDX, 0124h, RCX
  CHECK_SELECT RDX, 0421h, RCX

@DoneCheck:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_GetNextMove, _TEXT$00

;*********************************************************
;  TTT_Plot_X
;
;        Parameters: Leaf function for plotting X
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_Plot_X, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDX, [CircleLocations]
  MOV RCX, [XLocations]
  DEBUG_FUNCTION_CALL TTT_GetNextMove
  CMP RAX, 0
  JNE @PerformPlot

  MOV RDX, [XLocations]
  MOV RCX, [CircleLocations]
  DEBUG_FUNCTION_CALL TTT_GetNextMove
  CMP RAX, 0
  JNE @PerformPlot

@ReTry:
  DEBUG_FUNCTION_CALL Math_Rand

  AND RAX, 0777h
  MOV RDX, [XLocations]
  NOT RDX
  AND RAX, RDX

  MOV RDX, [CircleLocations]
  NOT RDX
  AND RAX, RDX

  TEST RAX, RAX
  JZ @ReTry

  BSR RCX, RAX
  MOV RAX, 1
  SHL RAX, CL

@PerformPlot:

 MOV RDX, 255
 MOV RCX, RAX
 DEBUG_FUNCTION_CALL TTT_DrawX

@DoneXPlot:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_Plot_X, _TEXT$00


;*********************************************************
;  TTT_DrawX
;
;        Parameters: Bitmask, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_DrawX, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, RCX
  MOV RBX, RDX

  CMP RAX ,0400h
  JE @X_Top_First 

  CMP RAX, 0200h
  JE @X_Top_Second

  CMP RAX, 0100h
  JE @X_Top_Third

  CMP RAX, 040h
  JE @X_Mid_First

  CMP RAX, 020h
  JE @X_Mid_Second

  CMP RAX, 010h
  JE @X_Mid_Third

  CMP RAX, 4
  JE @X_Bottom_First

  CMP RAX, 2
  JE @X_Bottom_Second

  CMP RAX, 1
  JE @X_Bottom_Third

  INT 3

  JMP @DoneXPlot

@X_Top_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 300
  MOV R8, 200
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 200
  MOV R9, 300
  MOV R8, 300
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  OR [XLocations], 0400h
  JMP @DoneXPlot

@X_Top_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 400
  MOV R8, 200
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 200
  MOV R9, 400
  MOV R8, 300
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  OR [XLocations], 0200h
  JMP @DoneXPlot

@X_Top_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 500
  MOV R8, 200
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 200
  MOV R9, 500
  MOV R8, 300
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   
  
  OR [XLocations], 0100h
  JMP @DoneXPlot

@X_Mid_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 300
  MOV R8, 400
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 300
  MOV R8, 300
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  OR [XLocations], 040h
  JMP @DoneXPlot

@X_Mid_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 400
  MOV R8, 400
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 400
  MOV R8, 300
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   
  OR [XLocations], 020h
  JMP @DoneXPlot

@X_Mid_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 500
  MOV R8, 400
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 500
  MOV R8, 300
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   
  

  OR [XLocations], 010h
  JMP @DoneXPlot

@X_Bottom_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 500
  MOV R9, 300
  MOV R8, 400
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 300
  MOV R8, 500
  MOV RDX, 200
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  OR [XLocations], 4
  JMP @DoneXPlot

@X_Bottom_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 500
  MOV R9, 400
  MOV R8, 400
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 400
  MOV R8, 500
  MOV RDX, 300
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   
  OR [XLocations], 2
  JMP @DoneXPlot

@X_Bottom_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 500
  MOV R9, 500
  MOV R8, 400
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], RBX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 500
  MOV R8, 500
  MOV RDX, 400
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawLine   
  OR [XLocations], 1

@DoneXPlot:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_DrawX, _TEXT$00

;*********************************************************
;  TTT_Plot_Circle
;
;        Parameters: Leaf function for plotting CIrcle
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_Plot_Circle, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, [XLocations]
  MOV RCX, [CircleLocations]
  DEBUG_FUNCTION_CALL TTT_GetNextMove
  CMP RAX, 0
  JNE @PerformPlot

  MOV RDX, [CircleLocations]
  MOV RCX, [XLocations]
  DEBUG_FUNCTION_CALL TTT_GetNextMove
  CMP RAX, 0
  JNE @PerformPlot

@ReTry:
  DEBUG_FUNCTION_CALL Math_Rand

  AND RAX, 0777h
  MOV RDX, [XLocations]
  NOT RDX
  AND RAX, RDX

  MOV RDX, [CircleLocations]
  NOT RDX
  AND RAX, RDX

  TEST RAX, RAX
  JZ @ReTry

  BSR RCX, RAX
  MOV RAX, 1
  SHL RAX, CL


@PerformPlot:
 
 MOV RDX, 255
 MOV RCX, RAX
 DEBUG_FUNCTION_CALL TTT_DrawCircle

@DoneCirclePlot:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE

  RET
NESTED_END TTT_Plot_Circle, _TEXT$00


;*********************************************************
;  TTT_DrawCircle
;
;        Parameters: Bitmask, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_DrawCircle, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, RCX

  CMP RAX, 0400h
  JE @Circle_Top_First

  CMP RAX, 0200h
  JE @Circle_Top_Second

  CMP RAX, 0100h
  JE @Circle_Top_Third

  CMP RAX, 040h
  JE @Circle_Mid_First

  CMP RAX, 020h
  JE @Circle_Mid_Second

  CMP RAX, 010h
  JE @Circle_Mid_Third

  CMP RAX, 4
  JE @Circle_Bottom_First

  CMP RAX, 2
  JE @Circle_Bottom_Second

  CMP RAX, 1
  JE @Circle_Bottom_Third

  INT 3

  JMP @DoneCirclePlot

@Circle_Top_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 250
  MOV RDX, 250
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 0400h
  JMP @DoneCirclePlot

@Circle_Top_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 250
  MOV RDX, 350
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 0200h
  JMP @DoneCirclePlot

@Circle_Top_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 250
  MOV RDX, 450
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 0100h
  JMP @DoneCirclePlot

@Circle_Mid_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 350
  MOV RDX, 250
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 040h
  JMP @DoneCirclePlot

@Circle_Mid_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 350
  MOV RDX, 350
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 020h
  JMP @DoneCirclePlot

@Circle_Mid_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 350
  MOV RDX, 450
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 010h
  JMP @DoneCirclePlot

@Circle_Bottom_First:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 450
  MOV RDX, 250
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 4
  JMP @DoneCirclePlot

@Circle_Bottom_Second:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 450
  MOV RDX, 350
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 2
  JMP @DoneCirclePlot

@Circle_Bottom_Third:
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RDX
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], RCX
  MOV R9, 50
  MOV R8, 450
  MOV RDX, 450
  MOV RCX, [MasterContext]
  DEBUG_FUNCTION_CALL Prm_DrawCircle   
  OR [CircleLocations], 1

@DoneCirclePlot:
  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  ADD RSP, SIZE TTT_DEMO_STRUCTURE

  RET
NESTED_END TTT_DrawCircle, _TEXT$00

;*********************************************************
;  TTT_CreateBoard
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_CreateBoard, _TEXT$00
  alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
  save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
  save_reg rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_ClearBuffer
  
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0ffh
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 500
  MOV R9, 300
  MOV R8, 200
  MOV RDX, 300
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0ffh
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 500
  MOV R9, 400
  MOV R8, 200
  MOV RDX, 400
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0ffh
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 300
  MOV R9, 500
  MOV R8, 300
  MOV RDX, 200
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0ffh
  MOV RCX, OFFSET TTT_DrawPixel
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], RCX
  MOV TTT_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 400
  MOV R9, 500
  MOV R8, 400
  MOV RDX, 200
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  MOV [CircleLocations], 0
  MOV [XLocations], 0

  MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, TTT_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE TTT_DEMO_STRUCTURE
  RET
NESTED_END TTT_CreateBoard, _TEXT$00



;*********************************************************
;  TTT_DrawPixel
;
;        Parameters: X, Y, Context (Color), Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY TTT_DrawPixel, _TEXT$00
 alloc_stack(SIZEOF TTT_DEMO_STRUCTURE)
 save_reg rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
 MOV RDI, RDX
 XOR RDX, RDX
 MUL RDI
 ADD RAX, RCX
 ADD RAX,[DoubleBuffer]
 MOV RCX, R8
 MOV BYTE PTR [RAX], CL
  
 MOV rdi, TTT_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
 ADD RSP, SIZE TTT_DEMO_STRUCTURE
 RET
NESTED_END TTT_DrawPixel, _TEXT$00

END