;*********************************************************
; Primatives Library
;
;  Written in Assembly x64
; 
;  By Toby Opferman  10/19/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include debug_public.inc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

FUNCTIONFRAME struct
    ReturnAddress  dq ?
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
    Param8         dq ?
FUNCTIONFRAME ends


SAVEFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR10        dq ?
    SaveR11        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
  SAVEFRAME ends

PRM_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame      SAVEFRAME  <?>
PRM_INIT_LOCALS ends


PRM_INIT_FUNC struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
   FuncParams     FUNCTIONFRAME <?>
PRM_INIT_FUNC ends

public Prm_DrawCircle
public Prm_DrawLine

.DATA 
.CODE


;*********************************************************
;  Prm_DrawCircle
;
;        Parameters: Master Context, X, Y, Radius, PlotPixelCallback, Context
;
;             PlotPixelCallback(X, Y, Context, Master Context)
;
;
;*********************************************************  
NESTED_ENTRY Prm_DrawCircle, _TEXT$00
 alloc_stack(SIZEOF PRM_INIT_LOCALS)
 save_reg rdi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRdi
 save_reg rsi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRsi
 save_reg rbx, PRM_INIT_LOCALS.SaveRegsFrame.SaveRbx
 save_reg r12, PRM_INIT_LOCALS.SaveRegsFrame.SaveR12
 save_reg r13, PRM_INIT_LOCALS.SaveRegsFrame.SaveR13
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RSI, RCX
 MOV PRM_INIT_FUNC.FuncParams.Param3[RSP], R9 ; Radius
 MOV PRM_INIT_FUNC.FuncParams.Param4[RSP], R8  ; Y Center
 MOV R12, RDX ; X Center
 
 XOR RDI, RDI ; y Increment
 MOV RBX, PRM_INIT_FUNC.FuncParams.Param3[RSP]
 DEC RBX      ; x Increment

 MOV PRM_INIT_FUNC.FuncParams.Param1[RSP], 1 ; Change in X
 MOV PRM_INIT_FUNC.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, PRM_INIT_FUNC.FuncParams.Param3[RSP]
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

@PlotQudrant_Pixels:
;
; Quadrant 1.1
;
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  ADD RDX, RDI
  MOV RCX, R12
  ADD RCX, RBX
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]



 ;
 ; Quadrant 1.2
 ; 
 @PlotQudrant_1_2_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  ADD RDX, RBX
  MOV RCX, R12
  ADD RCX, RDI
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]


 ;
 ; Quadrant 2.1
 ; 
 @PlotQudrant_2_1_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  ADD RDX, RBX
  MOV RCX, R12
  SUB RCX, RDI
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]



 ;
 ; Quadrant 2.2
 ; 
 @PlotQudrant_2_2_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  ADD RDX, RDI
  MOV RCX, R12
  SUB RCX, RBX
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]

  
 ;
 ; Quadrant 3.1
 ; 
 @PlotQudrant_3_1_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  SUB RDX, RDI
  MOV RCX, R12
  SUB RCX, RBX
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]

 ;
 ; Quadrant 3.2
 ; 
 @PlotQudrant_3_2_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  SUB RDX, RBX
  MOV RCX, R12
  SUB RCX, RDI
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]


 ;
 ; Quadrant 4.1
 ; 
 @PlotQudrant_4_1_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  SUB RDX, RBX
  MOV RCX, R12
  ADD RCX, RDI
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]


 ;
 ; Quadrant 4.2
 ; 
  @PlotQudrant_4_2_Pixel:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param4[RSP]
  SUB RDX, RDI
  MOV RCX, R12
  ADD RCX, RBX
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]

  ;
  ; Error Checks
  ;
  CMP R13, 0
  JG @Check_Second_Error
  INC RDI
  ADD R13, PRM_INIT_FUNC.FuncParams.Param2[RSP]
  ADD PRM_INIT_FUNC.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error:  
  CMP R13, 0
  JLE @Check_Loop_Condition

  DEC RBX
  ADD PRM_INIT_FUNC.FuncParams.Param1[RSP], 2
  MOV RAX, PRM_INIT_FUNC.FuncParams.Param3[RSP]
  SHL RAX, 1
  NEG RAX
  ADD RAX, PRM_INIT_FUNC.FuncParams.Param1[RSP]
  ADD R13, RAX
  
@Check_Loop_Condition:
  CMP RBX, RDI
  JGE @PlotQudrant_Pixels
  
  MOV rdi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV rsi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV rbx, PRM_INIT_LOCALS.SaveRegsFrame.SaveRbx[RSP]
  MOV r12, PRM_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  MOV r13, PRM_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
  ADD RSP, SIZE PRM_INIT_LOCALS
  RET
NESTED_END Prm_DrawCircle, _TEXT$00

;*********************************************************
;  Prm_DrawLine
;
;        Parameters: Master Context, X, Y, X2, Y2, PlotPixelCallback, Context
;
;             PlotPixelCallback(X, Y, Context, Master Context)
;
;
;*********************************************************  
NESTED_ENTRY Prm_DrawLine, _TEXT$00
 alloc_stack(SIZEOF PRM_INIT_LOCALS)
 save_reg rdi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRdi
 save_reg rsi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRsi
 save_reg rbx, PRM_INIT_LOCALS.SaveRegsFrame.SaveRbx
 save_reg r12, PRM_INIT_LOCALS.SaveRegsFrame.SaveR12
 save_reg r13, PRM_INIT_LOCALS.SaveRegsFrame.SaveR13
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RSI, RCX

 CMP RDX, R9
 JE @DrawVerticleLine

 CMP R8, PRM_INIT_FUNC.FuncParams.Param5[RSP]
 JE @DrawHorizontalLine

@DrawDiagonalLine:

  JMP @DoneDrawingLine
@DrawVerticleLine:
  MOV RDI, RDX
  CMP R8, PRM_INIT_FUNC.FuncParams.Param5[RSP]
  JA @StartDrawingVertLine
  XCHG R8, PRM_INIT_FUNC.FuncParams.Param5[RSP]
@StartDrawingVertLine:
  MOV R12, R8
  MOV R13, PRM_INIT_FUNC.FuncParams.Param5[RSP]

@DrawVertLine:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, R12
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]

  INC R12
  CMP R12, R13
  JBE @DrawVertLine

  JMP @DoneDrawingLine

@DrawHorizontalLine:
  CMP R9, RDX
  JA @StartDrawingHorzLine
  XCHG R9, RDX
@StartDrawingHorzLine:
  MOV R12, RDX
  MOV R13, R9

@DrawHorzLine:
  MOV R9, RSI
  MOV R8, PRM_INIT_FUNC.FuncParams.Param6[RSP]
  MOV RDX, PRM_INIT_FUNC.FuncParams.Param5[RSP]
  MOV RCX, R12
  DEBUG_FUNCTION_CALL PRM_INIT_FUNC.FuncParams.Param5[RSP]

  INC R12
  CMP R12, R13
  JBE @DrawHorzLine

@DoneDrawingLine:
  
 MOV rdi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
 MOV rsi, PRM_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
 MOV rbx, PRM_INIT_LOCALS.SaveRegsFrame.SaveRbx[RSP]
 MOV r12, PRM_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
 MOV r13, PRM_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
 ADD RSP, SIZE PRM_INIT_LOCALS
 RET
NESTED_END Prm_DrawLine, _TEXT$00

END