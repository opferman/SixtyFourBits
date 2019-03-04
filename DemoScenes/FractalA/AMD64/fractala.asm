;*********************************************************
; Template 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/2/2019
;
;
;   Dynamic Equation from this project: https://github.com/HackerPoet/Chaos-Equations 
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include dbuffer_public.inc
include font_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc


;*********************************************************
; Structures
;*********************************************************
PIXEL_ENTRY struct
   X              mmword    ?
   Y              mmword    ?
   ColorInc       dd        ?
   Color          dd        ?
   t              mmword    ?
PIXEL_ENTRY ends

PIXEL_HISTORY struct
   X              mmword    ?
   Y              mmword    ?
PIXEL_HISTORY ends

EQUATION_PARAMS struct
   Param          mmword    ?
EQUATION_PARAMS ends

LOCAL_VARS struct
    LocalVar1  dq ?
    LocalVar2  dq ?
LOCAL_VARS ends


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
    SaveRbp        dq ?
    Padding        dq ?

    SaveXmm6       oword ? 
    SaveXmm7       oword ? 
    SaveXmm8       oword ? 
    SaveXmm9       oword ? 
    SaveXmm10      oword ? 
    SaveXmm11      oword ? 
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





FRACTAL_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   LocalVariables LOCAL_VARS      <?>
FRACTAL_DEMO_STRUCTURE ends

FRACTAL_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   LocalVariables LOCAL_VARS      <?>
   FuncParams     FUNC_PARAMS     <?>
FRACTAL_DEMO_STRUCTURE_FUNC ends

;*********************************************************
; Public Declarations
;*********************************************************
public FractalA_Init
public FractalA_Demo
public FractalA_Free

MAX_FRAMES EQU <50000>
NUM_PIXELS EQU <1>
STEPS_FRAME EQU <500>
EQU_ITTERATIONS EQU <800>
EQU_PARAMETERS EQU <18>

NEWX_X2 EQU <0 * SIZE EQUATION_PARAMS>
NEWX_Y2 EQU <1 * SIZE EQUATION_PARAMS>
NEWX_T2 EQU <2 * SIZE EQUATION_PARAMS>
NEWX_XY EQU <3 * SIZE EQUATION_PARAMS>
NEWX_XT EQU <4 * SIZE EQUATION_PARAMS>
NEWX_YT EQU <5 * SIZE EQUATION_PARAMS>
NEWX_X  EQU <6 * SIZE EQUATION_PARAMS>
NEWX_Y  EQU <7 * SIZE EQUATION_PARAMS>
NEWX_T  EQU <8 * SIZE EQUATION_PARAMS>
NEWY_X2 EQU <9 * SIZE EQUATION_PARAMS>
NEWY_Y2 EQU <10 * SIZE EQUATION_PARAMS>
NEWY_T2 EQU <11 * SIZE EQUATION_PARAMS>
NEWY_XY EQU <12 * SIZE EQUATION_PARAMS>
NEWY_XT EQU <13 * SIZE EQUATION_PARAMS>
NEWY_YT EQU <14 * SIZE EQUATION_PARAMS>
NEWY_X  EQU <15 * SIZE EQUATION_PARAMS>
NEWY_Y  EQU <16 * SIZE EQUATION_PARAMS>
NEWY_T  EQU <17 * SIZE EQUATION_PARAMS>



;*********************************************************
; Data Segment
;*********************************************************
.DATA
   FrameCounter   dd ?
   EquationXString db "x' = -x^2 - y^2 - t^2 - xy - xt - yt - x - y - t ", 0
   EquationYString db "y' = -x^2 - y^2 - t^2 - xy - xt - yt - x - y - t ", 0
   t_Start        mmword -3.0
   t_End          mmword 3.0
   t_Input        mmword -3.0
   t_Increment    mmword 0.01
   PixelEntry     PIXEL_ENTRY NUM_PIXELS DUP(<>)
   ColorArray     dd     STEPS_FRAME*EQU_ITTERATIONS DUP(?)
   NegativeOne    mmword -1.0
   Scale          mmword 0.25
   PlotX          mmword 0.0
   PlotY          mmword 0.0
   PointFive      mmword 0.5
   FiveHundred    mmword 500.0
   RollingDelta   mmword 0.00001
   DeltaPerStep   mmword 0.00001
   MinDelta       mmword 0.0000001
   Delta          mmword ?
   TenNegFive     mmword 0.00001
   SpeedMult      mmword 1.0
   One            mmword 1.0
   NegOne         mmword -1.0
   Zero           mmword 0.0
   NineyNine      mmword 0.99
   PontOhOne      mmword 0.01
   XSquared       mmword ?
   YSquared       mmword ?
   TSquared       mmword ?
   XandY          mmword ?
   XandT          mmword ?
   YandT          mmword ?
   Ten            mmword 10.0
   ParameterText  db "x^2", 0 
                  db "y^2", 0
                  db "t^2", 0 
                  db "xy", 0 
                  db "xt", 0
                  db "yt", 0 
                  db "x", 0 
                  db "y", 0
                  db "t",0

   StringSize     mmword 100000.0
   FormatString   db  "t = -3.00000", 0
   DoubleBuffer     dq ?
   PixelHistory   PIXEL_HISTORY EQU_ITTERATIONS DUP(<>)
   Parameters     EQUATION_PARAMS EQU_PARAMETERS DUP(<>)
   IsOffScreen    dd ?
.CODE

;*********************************************************
;   FractalA_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY FractalA_Init, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
   
  MOV RSI, RCX

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX

  MOV [FrameCounter], 0

  XOR R8, R8
  MOV RDI, OFFSET PixelEntry

  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 0FFFFFFh
  MOV PIXEL_ENTRY.Color[RDI], EAX
  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 0FFFFFFh 
  MOV RDI, OFFSET ColorArray
@Init_Color_Array:
  MOV DWORD PTR [RDI], EAX
  CMP AL, 0FFh
  JE @TryOtherColor
  INC AL
  JMP @NextPix

@TryOtherColor:
  CMP AH, 0FFh
  JE  @TryOtherColor2
  INC AH
  JMP @NextPix
@TryOtherColor2:
  MOV EDX, EAX
  SHR EDX, 15
  CMP DL, 0FFh
  JE @NextPix
  INC DL
  SHL DL, 16
  OR EAX, EDX
@NextPix:
  ADD RDI, 4
  INC R8
  CMP R8, STEPS_FRAME*EQU_ITTERATIONS
  JB @Init_Color_Array
  
  MOV RDI, OFFSET PixelHistory
  XOR R8, R8
@Init_To_Zero:
  MOV PIXEL_HISTORY.X[RDI], 0
  MOV PIXEL_HISTORY.Y[RDI], 0
  ADD RDI, SIZE PIXEL_HISTORY
  INC R8
  CMP R8, EQU_ITTERATIONS
  JB @Init_To_Zero

  ;DEBUG_FUNCTION_CALL FractalA_RandomInitParams
  
  ;
  ; Initialize to a known algorithm and then randomize later
  ;
  DEBUG_FUNCTION_CALL FractalA_InitSpecialAlgo

  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_NewEquationStrings
  

  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  MOV EAX, 1
  RET
NESTED_END FractalA_Init, _TEXT$00



;*********************************************************
;   FractalA_RandomInitParams
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY FractalA_RandomInitParams, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, OFFSET Parameters
  XOR RSI, RSI
@Random_Init:
  
  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 3

  CMP EAX, 1
  JE @SetToOne

  CMP EAX, 2
  JE @SetToZero
  JMP @SetToNegativeOne

@SetToZero:

  MOVSD xmm0, [Zero]
  MOVSD EQUATION_PARAMS.Param[RDI], xmm0
  JMP @LoopTest

@SetToOne:
  MOVSD xmm0, [One]
  MOVSD EQUATION_PARAMS.Param[RDI], xmm0
  JMP @LoopTest

@SetToNegativeOne:
  MOVSD xmm0, [NegOne]
  MOVSD EQUATION_PARAMS.Param[RDI], xmm0

@LoopTest:

  ADD RDI, SIZE EQUATION_PARAMS
  INC RSI
  CMP RSI, EQU_PARAMETERS
  JB @Random_Init

  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END FractalA_RandomInitParams, _TEXT$00

;*********************************************************
;   FractalA_InitSpecialAlgo
;
;        Parameters: None
;
;        Return Value: None
;
;
;      x' = x^2 - xt + yt - x
;      y' = -y^2 - t^2 - xy - xt - yt - y
;
;
;*********************************************************  
NESTED_ENTRY FractalA_InitSpecialAlgo, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, OFFSET Parameters
  
  MOVSD xmm0, [Zero]
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_Y2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_T2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_XY], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_T], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_Y], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_X2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_XT], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_X], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_T], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_X], xmm0

  MOVSD xmm0, [One]
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_X2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_YT], xmm0
  
  MOVSD xmm0, [NegOne]
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_Y2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_T2], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_XY], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_XT], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_YT], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWY_Y], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_XT], xmm0
  MOVSD EQUATION_PARAMS.Param[RDI+NEWX_X], xmm0

  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END FractalA_InitSpecialAlgo, _TEXT$00




;*********************************************************
;   FractalA_FadePixels
;
;        Parameters: MASTER_CONTEXT
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY FractalA_FadePixels, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, [DoubleBuffer]
  
  XOR R10, R10
@Height:
  XOR R9, R9
  @Width:
   MOV EDX, DWORD PTR [RDI]
   CMP EDX, 0
   JE @NextPixelTest
   MOV EAX, EDX
   CMP DL, 0
   JE @Skip1
   DEC DL
@Skip1:
   CMP DH, 0
   JE @Skip2
   DEC DH
@Skip2:
   CMP AL, 0
   JE @Skip3
   DEC AL
@Skip3:
   XOR ECX, ECX
   MOV CX, DX
   SHL EAX, 16
   OR EAX, ECX
   MOV DWORD PTR [RDI], EAX
@NextPixelTest:
   ADD RDI, 4
   INC R9
   CMP R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
   JB @Width
   INC R10
   CMP R10, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
   JB @Height

  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END FractalA_FadePixels, _TEXT$00



;*********************************************************
;  FractalA_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY FractalA_Demo, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14
 save_reg r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
 save_reg r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RSI, RCX
  DEBUG_FUNCTION_CALL FractalA_FadePixels

  ;
  ; Get the Double Buffer
  ; 
  MOV RDI, [DoubleBuffer]
  
  MOVSD xmm0, [DeltaPerStep]
  MULSD xmm0, [SpeedMult]
  MOVSD [Delta], xmm0                   ; Delta = DeltaPerSTep * Speed Multiplier

  MOVSD xmm1, [RollingDelta]
  MULSD xmm1, [NineyNine]
  MULSD xmm0, [PontOhOne]
  ADDSD xmm0, xmm1
  MOVSD [RollingDelta], xmm0            ; Rolling Delta = Rolling Detla * 0.99 + Delta * 0.01
  

  XOR R8, R8
  MOV R9, OFFSET PixelEntry
  MOV R12, OFFSET ColorArray

@OutterLoop:

  MOVSD xmm0, [t_Input]
  MOVSD PIXEL_ENTRY.X[R9], xmm0
  MOVSD PIXEL_ENTRY.Y[R9], xmm0
  MOVSD PIXEL_ENTRY.t[R9], xmm0
  
  XOR R10, R10
  MOV R14, OFFSET PixelHistory
  MOV [IsOffScreen], 1
  JMP @UpdatePixelMath
  ;
  ; Update Pixels
  ;
@Update_Pixel:

  ;
  ; xmm0 = Scale * Screen Height/2
  ;
  MOV RAX,MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SHR EAX, 1
  CVTSI2SD xmm0, RAX                                    ; Screen Height / 2
  MULSD xmm0, [Scale]

  ;
  ; NewX (xmm1) = Screen Width * 0.5 + (x - PlotX) * xmm0
  ;
  MOV RAX,MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  CVTSI2SD xmm1, RAX   
  MULSD xmm1, [PointFive]
  MOVSD xmm2, PIXEL_ENTRY.X[R9]
  SUBSD xmm2, [PlotX]
  MULSD xmm2, xmm0
  ADDSD xmm1, xmm2

  ;
  ; NewY (xmm2) = Screen Height * 0.5 + (y - PlotY) * xmm0
  ;
  MOV RAX,MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  CVTSI2SD xmm2, RAX   
  MULSD xmm2, [PointFive]
  MOVSD xmm3, PIXEL_ENTRY.Y[R9]
  SUBSD xmm3, [PlotY]
  MULSD xmm3, xmm0
  ADDSD xmm2, xmm3

  ;
  ; Convert to integers and determine if they are on-screen to draw.
  ;
  CVTSD2SI RCX, xmm1
  CVTSD2SI RAX, xmm2

  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JAE @CantPlotPixel

  CMP RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JAE @CantPlotPixel

  ;JMP @NoUpdateRollingDelta

  MOV [IsOffScreen], 0
  CMP RCX, 522
  JNE @Skipit
  CMP RAX, 268
  JNE @Skipit
;  INT 3
@Skipit:
  MOVSD xmm3, PIXEL_HISTORY.X[R14]
  MOVSD xmm4, PIXEL_HISTORY.Y[R14]
  SUBSD xmm3, xmm1
  SUBSD xmm4, xmm2
  
  ;
  ; Save Pixel History
  ;
  MOVSD PIXEL_HISTORY.X[R14], xmm1
  MOVSD PIXEL_HISTORY.Y[R14], xmm2
  ADD R14, SIZE PIXEL_HISTORY 

  MULSD xmm3, xmm3                      ; dx*dx
  MULSD xmm4, xmm4                      ; dy*dy
  ADDSD xmm3, xmm3                      ; dx*dx + dy*dy
  MOVSD xmm0, xmm3
  SQRTSD xmm0, xmm0
  MULSD xmm0, [FiveHundred]             ; dist = sqrt() * 500

  MOVSD xmm1, [Delta]                   ; Delta
  ADDSD xmm0, [TenNegFive]              ; dist + 1e-5
  DIVSD xmm1, xmm0                      ; Delta / (dist + 1e-5) = xmm1

  MOVSD xmm0, [MinDelta]
  MULSD xmm0, [SpeedMult]                ; Delta Minimum * Speed Multiplier

  UCOMISD  xmm0, xmm1                      ; Determine the Maximum
  JA @CompareMin

  MOVSD xmm0, xmm1

@CompareMin:                              ; xmm0 will have the max of the previous two operations
  MOVSD xmm1, [RollingDelta]
  UCOMISD  xmm0, xmm1                     ; Determine the minimum
  JA @NoUpdateRollingDelta

  MOV RDX, [RollingDelta]
  MOVSD [RollingDelta], xmm0              ; Update if it's less than.

@NoUpdateRollingDelta:
@PlotPixelOnScreen:
;
; Plot Pixel and Update ColorInc
;
  MOV RBX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL EBX, 2
  XOR EDX, EDX
  MUL EBX
  SHL RCX, 2
  ADD RAX, RCX
  MOV ECX, [R12]
  MOV DWORD PTR [RDI+RAX], ECX

  
  ADD ECX, PIXEL_ENTRY.ColorInc[R9]
  AND ECX, 0FFFFFFh
  MOV PIXEL_ENTRY.Color[R9], ECX

@PixelLoopUpdate:

  ADD R12, 4
  INC R10
  CMP R10, EQU_ITTERATIONS
  JB @UpdatePixelMath
  
  CMP [IsOffScreen], 0
  JE @UpdateRollingDelta
  MOVSD xmm0, [t_Increment]
  JMP @FinalUpdateOfT
@UpdateRollingDelta:

  MOVSD xmm0, [RollingDelta]
@FinalUpdateOfT:
  ADDSD xmm0, [t_Input]
  MOVSD [t_Input], xmm0

  INC R8
  CMP R8, STEPS_FRAME
  JB @OutterLoop
  JMP @DonePlotting

@CantPlotPixel:
  ;
  ; Save Pixel History
  ;
  ;MOVSD PIXEL_HISTORY.X[R14], xmm1
  ;MOVSD PIXEL_HISTORY.Y[R14], xmm2             ; For now, we need to skip these because these can lead to -INF/INF numbers that will screw up the delta.

  ADD R14, SIZE PIXEL_HISTORY

  JMP @PixelLoopUpdate

@UpdatePixelMath:

  MOVSD xmm0, PIXEL_ENTRY.X[R9]
  MOVSD xmm1, PIXEL_ENTRY.Y[R9]
  MOVSD xmm2, [t_Input]

  MOVSD xmm3, xmm0
  MULSD xmm3, xmm3              ; x^2
  MOVSD [XSquared], xmm3

  MOVSD xmm3, xmm1              
  MULSD xmm3, xmm3              ; y^2
  MOVSD [YSquared], xmm3

  MOVSD xmm3, xmm2
  MULSD xmm3, xmm3              ; t^2
  MOVSD [TSquared], xmm3

  MOVSD xmm3, xmm0
  MULSD xmm3, xmm1
  MOVSD [XandY], xmm3           ; x*y

  MOVSD xmm3, xmm0
  MULSD xmm3, xmm2
  MOVSD [XandT], xmm3           ; x*t

  MOVSD xmm3, xmm1
  MULSD xmm3, xmm2
  MOVSD [YandT], xmm3           ; y*t

  MOV R15, OFFSET Parameters
  
  MOVSD xmm3, [XSquared]
  MULSD xmm3, EQUATION_PARAMS.Param[R15]        ; c*x^2
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*y^2
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [TSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*t^2
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandY]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*xy
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*xt
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*yt
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.X[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*x
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.y[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*y
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [t_Input]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*t
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  ;
  ; New X = xmm3
  ;
  MOVSD xmm5, [XSquared]
  MULSD xmm5, EQUATION_PARAMS.Param[R15]        ; c*x^2
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*y^2
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [TSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*t^2
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandY]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*xy
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*xt
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*yt
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.X[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*x
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.y[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*y
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [t_Input]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]        ; c*t
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  ;
  ; xmm5 = New Y
  ;


  MOVSD PIXEL_ENTRY.X[R9], xmm3         ; x'
  MOVSD PIXEL_ENTRY.Y[R9], xmm5         ; y'

;
;  Originally we were doing per-pixel things, but now we are just itterative from one pixel to the next.
;  ADD R9, SIZE PIXEL_ENTRY
;
  JMP @Update_Pixel

@DonePlotting:
  MOVSD xmm0, [t_Input]
  MOVSD xmm1, [t_End]
  UCOMISD  xmm0, xmm1
  JB @NoReset
  MOVSD xmm0, [t_Start]
  MOVSD [t_Input], xmm0
  DEBUG_FUNCTION_CALL FractalA_RandomInitParams 

  MOV EDX, 1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_NewEquationStrings
  
@NoReset:

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_DisplayEquationStrings

  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_DisplayT
  ;
  ; Update the frame counter and determine if the demo is complete.
  ;
  XOR EAX, EAX
  INC [FrameCounter]
  CMP [FrameCounter], MAX_FRAMES
  SETE AL
  XOR AL, 1
 
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  MOV r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14[RSP]
  MOV r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  MOV r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END FractalA_Demo, _TEXT$00



;*********************************************************
;  FractalA_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_Free, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  ; Nothing to clean up

  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END FractalA_Free, _TEXT$00



;*********************************************************
;  FractalA_NewEquationStrings
;
;        Parameters: MASTER_STRUCT, BOOL Overwrite Old
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_NewEquationStrings, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  CMP EDX, 0
  JE @SkipErase
   ;
   ;  Erase Old Equations!!!!
   ;
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 1
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0
  MOV R9, 4
  MOV R8, 5
  MOV RDX, OFFSET EquationXString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_PrintWord

  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 1
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0
  MOV R9, 15
  MOV R8, 5
  MOV RDX, OFFSET EquationYString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_PrintWord

@SkipErase:

  MOV RDX, OFFSET Parameters
  MOV RCX, OFFSET EquationXString
  DEBUG_FUNCTION_CALL FractalA_UpdateEquation

  MOV RDX, OFFSET Parameters
  ADD RDX, NEWY_X2
  MOV RCX, OFFSET EquationYString
  DEBUG_FUNCTION_CALL FractalA_UpdateEquation

  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END FractalA_NewEquationStrings, _TEXT$00


;*********************************************************
;  FractalA_NewEquationStrings
;
;        Parameters: MASTER_STRUCT
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_DisplayEquationStrings, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RSI, RCX

   ;
   ;  Display Equations!
   ;
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 1
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0FFFFFFh
  MOV R9, 4
  MOV R8, 5
  MOV RDX, OFFSET EquationXString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_PrintWord

  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 1
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
  MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0FFFFFFh
  MOV R9, 15
  MOV R8, 5
  MOV RDX, OFFSET EquationYString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL FractalA_PrintWord

  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END FractalA_DisplayEquationStrings, _TEXT$00


;*********************************************************
;  FractalA_UpdateEquation
;
;        Parameters: String, Parameter
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_UpdateEquation, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  
  XOR RBX, RBX                                   ; Boolean for first item printed.

  ADD RCX, 5
  MOV RDI, OFFSET ParameterText
  XOR R8, R8

@CreateEquationStringLoop:
  
  MOV R9, [Zero]
  CMP EQUATION_PARAMS.Param[RDX], R9
  JE @SkipStringLoop

  MOV R9, [One]
  CMP EQUATION_PARAMS.Param[RDX], R9           ; Assume -1 otherwise.
  JE @Addition

  MOV BYTE PTR [RCX], '-'
  INC RCX
  JMP @AddEquationEntity

@Addition:
  CMP EBX, 0
  JE @AddEquationEntity
  MOV BYTE PTR [RCX], '+'
  INC RCX
@AddEquationEntity:
  CMP EBX, 0
  JE @SkipSpaceForFirstItem
  MOV BYTE PTR [RCX], ' '
  INC RCX 
@SkipSpaceForFirstItem:
  MOV EBX, 1
@AddStringLoop:
  MOV AL, BYTE PTR [RDI]
  MOV BYTE PTR [RCX], AL 
  INC RCX
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNE @AddStringLoop
  MOV BYTE PTR [RCX], ' '
  INC RCX
  INC RDI
  JMP @FinishedAddition

@SkipStringLoop:
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNE @SkipStringLoop
  INC RDI
@FinishedAddition:
  ADD RDX, SIZE EQUATION_PARAMS
  INC R8
  CMP R8, 9
  JB @CreateEquationStringLoop

  MOV BYTE PTR [RCX], 0

  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END FractalA_UpdateEquation, _TEXT$00


;*********************************************************
;  FractalA_DisplayT
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_DisplayT, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 3
   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0
   MOV R9, 4
   MOV R8, 600
   MOV RDX, OFFSET FormatString
   MOV RSI, RCX
   DEBUG_FUNCTION_CALL FractalA_PrintWord

   MOV RDI, OFFSET FormatString
   PXOR xmm0, xmm0
   MOVSD xmm1, [t_Input]
   MOV BYTE PTR [RDI + 4], ' '
   UCOMISD xmm1, xmm0
   JAE @PositiveFont
   MOV BYTE PTR [RDI + 4], '-'
   MOVSD xmm3, [NegOne]
   MULSD xmm1, xmm3
@PositiveFont:
   MOVSD xmm2, [StringSize]
   MULSD xmm1, xmm2
   CVTSD2SI RAX, xmm1
@Display:
   CMP RAX, 1000000
   JAE @T_IS_TOO_BIG
   MOV R8, 11
@OurLittleLoop:
   MOV EBX, 10
   XOR EDX, EDX
   DIV EBX
   ADD DL, '0'
   MOV BYTE PTR [RDI + R8], DL
   DEC R8
   CMP R8, 6
   JA @OurLittleLoop
   ADD AL, '0'
   MOV BYTE PTR [RDI + 5], AL

   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 3
   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param6[RSP], 0
   MOV FRACTAL_DEMO_STRUCTURE.ParameterFrame.Param7[RSP], 0FFFFFFh
   MOV R9, 4
   MOV R8, 600
   MOV RDX, OFFSET FormatString
   MOV RCX, RSI
   DEBUG_FUNCTION_CALL FractalA_PrintWord

@T_IS_TOO_BIG:
  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END FractalA_DisplayT, _TEXT$00


;*********************************************************
;  FractalA_PrintWord
;
;        Parameters: Master Context, String, X, Y, Font Size, Radians, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY FractalA_PrintWord, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rbp, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbp
 save_reg r14, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR15
 save_reg r12, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR13
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP], xmm6
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP], xmm7
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP], xmm8
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP], xmm9
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX ; Master Context
  MOV R15, RDX ; String
  MOV R14, R8  ; X Location
  MOV R12, R9  ; Y Location
  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param3[RSP], R12

@Plasma_PrintStringLoop:
  ;
  ; Get the Bit Font
  ;
  XOR RCX, RCX
  MOV CL, [R15]
  DEBUG_FUNCTION_CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured

  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], RAX
  MOV RSI, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 8


@VerticleLines:
       MOV BL, 80h
       MOV R13, R14

@HorizontalLines:
           MOV RAX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
           TEST BL, [RAX]
           JZ @NoPixelToPlot 

           MOV  FRACTAL_DEMO_STRUCTURE_FUNC.LocalVariables.LocalVar1[RSP], RBX

           ;
           ; Let's get the Font Size in R9
           ;
           MOV R9, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
		   

@PlotRotatedPixel:
              MOV  FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param4[RSP], R9

			  MOV RAX, R14 ; X
			  MOV  R8, R12  ; Y


			  JMP @PlotPixel
			  ;
			  ; Rotate
			  ;
			  ;
			  ; cos(r)*x - sin(r)*y
			  ;
			  CVTSI2SD xmm6, R14 ; X
			  CVTSI2SD xmm7, R12 ; Y

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  SUBSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  SUBSD xmm6, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL cos
			  MULSD xmm0, xmm6
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm7
			  SUBSD xmm9, xmm0

			  ;
			  ; (sin(r)*x + cos(r)*y)
			  ;
			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm6
			  MOVSD xmm6, xmm9
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL cos
			  MULSD xmm0, xmm7
			  ADDSD xmm0, xmm9
			  MOVSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  ADDSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  ADDSD xmm6, xmm0

			  CVTTSD2SI RAX, xmm6 ; X
			  CVTTSD2SI R8, xmm7  ; Y

@PlotPixel:

			  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  JAE @PixelOffScreen

			  CMP R8, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  JAE @PixelOffScreen

			  MOV RCX, R8
			  IMUL RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHL RAX, 2
			  SHL RCX, 2
			  ADD RCX, RAX
			  ADD RCX, [DoubleBuffer]
                          MOV RAX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param7[RSP]
			  MOV DWORD PTR [RCX], EAX

@PixelOffScreen:
			INC R14
			MOV  RBX, FRACTAL_DEMO_STRUCTURE_FUNC.LocalVariables.LocalVar1[RSP]
			MOV  R9, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param4[RSP]
			DEC R9
			JNZ @PlotRotatedPixel
			JMP @DonePlottingPixel

@NoPixelToPlot:
        ADD R14, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
@DonePlottingPixel:
    SHR BL, 1
    TEST BL, BL
    JNZ @HorizontalLines

  MOV R14, R13
  INC R12
  DEC RSI
  JNZ @VerticleLines
  
  MOV RSI, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  INC FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  DEC FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  CMP FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 0
  JA @VerticleLines

  MOV R12, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param3[RSP]
  

  INC R15

  MOV RCX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  SHL RCX, 3
  ADD R14, RCX
  ADD R14, 3
 
  CMP BYTE PTR [R15], 0 
  JNE @Plasma_PrintStringLoop


  MOV EAX, 1
@ErrorOccured:
 MOVAPS xmm6,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP]
 MOVAPS xmm7,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP]
 MOVAPS xmm8,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP]
 MOVAPS xmm9,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP]
  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV rbp, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbp[RSP]
  MOV r14, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  MOV r12, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END FractalA_PrintWord, _TEXT$00





END