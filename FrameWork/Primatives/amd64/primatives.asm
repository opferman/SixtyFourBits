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
include paramhelp_public.inc

public Prm_DrawCircle
public Prm_DrawLine

.DATA 
  ConstantNegative MMWORD -1.0

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
 alloc_stack(SIZEOF STD_FUNCTION_STACK)
 save_reg rdi, STD_FUNCTION_STACK.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK.SaveRegs.SaveR12
 save_reg r13, STD_FUNCTION_STACK.SaveRegs.SaveR13
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RSI, RCX
 MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], R9 ; Radius
 MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP], R8  ; Y Center
 MOV R12, RDX ; X Center
 
 XOR RDI, RDI ; y Increment
 MOV RBX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
 DEC RBX      ; x Increment

 MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], 1 ; Change in X
 MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP], 1 ; Change in Y
 
 MOV R13, 1
 MOV RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
 SHL RAX, 1
 SUB R13, RAX   ; Error Correction

@PlotQudrant_Pixels:
;
; Quadrant 1.1
;
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  ADD RDX, RDI
  MOV RCX, R12
  ADD RCX, RBX
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]



 ;
 ; Quadrant 1.2
 ; 
 @PlotQudrant_1_2_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  ADD RDX, RBX
  MOV RCX, R12
  ADD RCX, RDI
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]


 ;
 ; Quadrant 2.1
 ; 
 @PlotQudrant_2_1_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  ADD RDX, RBX
  MOV RCX, R12
  SUB RCX, RDI
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]



 ;
 ; Quadrant 2.2
 ; 
 @PlotQudrant_2_2_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  ADD RDX, RDI
  MOV RCX, R12
  SUB RCX, RBX
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]

  
 ;
 ; Quadrant 3.1
 ; 
 @PlotQudrant_3_1_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  SUB RDX, RDI
  MOV RCX, R12
  SUB RCX, RBX
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]

 ;
 ; Quadrant 3.2
 ; 
 @PlotQudrant_3_2_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  SUB RDX, RBX
  MOV RCX, R12
  SUB RCX, RDI
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]


 ;
 ; Quadrant 4.1
 ; 
 @PlotQudrant_4_1_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  SUB RDX, RBX
  MOV RCX, R12
  ADD RCX, RDI
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]


 ;
 ; Quadrant 4.2
 ; 
  @PlotQudrant_4_2_Pixel:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  SUB RDX, RDI
  MOV RCX, R12
  ADD RCX, RBX
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]

  ;
  ; Error Checks
  ;
  CMP R13, 0
  JG @Check_Second_Error
  INC RDI
  ADD R13, STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP]
  ADD STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP], 2
  
 @Check_Second_Error:  
  CMP R13, 0
  JLE @Check_Loop_Condition

  DEC RBX
  ADD STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], 2
  MOV RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  SHL RAX, 1
  NEG RAX
  ADD RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP]
  ADD R13, RAX
  
@Check_Loop_Condition:
  CMP RBX, RDI
  JGE @PlotQudrant_Pixels
  
  MOV rdi, STD_FUNCTION_STACK.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK.SaveRegs.SaveR12[RSP]
  MOV r13, STD_FUNCTION_STACK.SaveRegs.SaveR13[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK
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
 alloc_stack(SIZEOF STD_FUNCTION_STACK)
 save_reg rdi, STD_FUNCTION_STACK.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK.SaveRegs.SaveR12
 save_reg r13, STD_FUNCTION_STACK.SaveRegs.SaveR13
 MOVAPS STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm6[RSP], XMM6
 MOVAPS STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm7[RSP], XMM7
 MOVAPS STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm8[RSP], XMM8
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RSI, RCX

 CMP RDX, R9
 JE @DrawVerticleLine

 CMP R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
 JE @DrawHorizontalLine

@DrawDiagonalLine:
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], RDX
  
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP], R8
  SUB STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], R9
  
  MOV RAX,  STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  SUB STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP], RAX


  CMP STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP], 0
  JGE @NoAbsAdjustForY

  NEG STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP]

@NoAbsAdjustForY:
  CMP STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], 0
  JGE @NoAbsAdjustForX
  
  NEG STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP]

@NoAbsAdjustForX:
  MOV RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP]

  CMP RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param2[RSP]
  JA @ItterateByX

@ItterateByY:

  MOV RBX, R8
  MOV RDI, 1
  CMP R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  JB @SkipNegatingYDirection
  NEG RDI
@SkipNegatingYDirection:
  SUB R9, RDX
  MOV RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  SUB RAX, R8
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], RAX
  CMP STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], 0
  JGE @DoNotNegateY
  NEG STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
@DoNotNegateY:
  cvtsi2sd Xmm0, R9 
  cvtsi2sd Xmm1, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  cvtsi2sd Xmm7, RDX
  DIVSD Xmm0, Xmm1
  MOVSD Xmm6, Xmm0
  MOVSD Xmm0, [ConstantNegative]
 ; MULSD Xmm6, Xmm0
    
@KeepDrawingDiagYLine:

  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param7[RSP]
  MOV RDX, RBX
  cvttsd2si RCX, Xmm7
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]

  ADDSD Xmm7, Xmm6
  ADD RBX, RDI
  DEC STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  JNZ @KeepDrawingDiagYLine

  JMP @DoneDrawingLine

@ItterateByX:

  MOV RBX, RDX
  MOV RDI, 1
  CMP RDX, R9
  JB @SkipNegatingXDirection
  NEG RDI
@SkipNegatingXDirection:
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param1[RSP], R9
  SUB R9, RDX
  MOV RAX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  SUB RAX, R8

  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], R9
  CMP STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], 0
  JGE @DoNotNegateX
  NEG STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
@DoNotNegateX:

  cvtsi2sd Xmm0, RAX
  cvtsi2sd Xmm1, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP] 
  cvtsi2sd Xmm7, R8
  DIVSD Xmm0, Xmm1
  MOVSD Xmm6, Xmm0
  MOVSD Xmm0, [ConstantNegative]
  ;MULSD Xmm6, Xmm0
    
@KeepDrawingDiagXLine:

  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param7[RSP]
  MOV RCX, RBX
  cvttsd2si RDX, Xmm7
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]

  ADDSD Xmm7, Xmm6
  ADD RBX, RDI
  DEC STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  JNZ @KeepDrawingDiagXLine
  
  JMP @DoneDrawingLine
  
@DrawVerticleLine:
  MOV RDI, RDX
  CMP R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  JB @StartDrawingVertLine
  XCHG R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
@StartDrawingVertLine:
  MOV R12, R8
  MOV R13, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]

@DrawVertLine:
  MOV R9, RSI
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param7[RSP]
  MOV RDX, R12
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]

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
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param7[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV RCX, R12
  DEBUG_FUNCTION_CALL STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]

  INC R12
  CMP R12, R13
  JBE @DrawHorzLine

@DoneDrawingLine:

 MOVAPS XMM6, STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm6[RSP]
 MOVAPS XMM7, STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm7[RSP]
 MOVAPS XMM8, STD_FUNCTION_STACK.SaveXmmRegs.SaveXmm8[RSP]
 MOV rdi, STD_FUNCTION_STACK.SaveRegs.SaveRdi[RSP]
 MOV rsi, STD_FUNCTION_STACK.SaveRegs.SaveRsi[RSP]
 MOV rbx, STD_FUNCTION_STACK.SaveRegs.SaveRbx[RSP]
 MOV r12, STD_FUNCTION_STACK.SaveRegs.SaveR12[RSP]
 MOV r13, STD_FUNCTION_STACK.SaveRegs.SaveR13[RSP]
 ADD RSP, SIZE STD_FUNCTION_STACK
 RET
NESTED_END Prm_DrawLine, _TEXT$00

END
