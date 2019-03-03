;*********************************************************
; Template 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/2/2019
;
;     x' = -x^2 + xt + y
;     y' = x^2 - y^2 - t^2 - xy + yt - x + y
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc

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
;*********************************************************
; Data Segment
;*********************************************************
.DATA
   FrameCounter   dd ?
   t_Start        mmword -3.0
   t_End          mmword 3.0
   t_Input        mmword -3.0
   t_Increment    mmword 0.01
   PixelEntry     PIXEL_ENTRY NUM_PIXELS DUP(<>)
   NegativeOne    mmword -1.0
   Scale          mmword 0.25
   PlotX          mmword 0.0
   PlotY          mmword 0.0
   PointFive      mmword 0.5
   FiveHundred    mmword 500.0
   RollingDelta   mmword 0.00001
   DeltaPerStep   mmword 0.00001
   MinDelta       mmword 0.0000001
   TenNegFive     mmword 0.00001
   SpeedMult      mmword 1.0
   One            mmword 1.0
   NegOne         mmword -1.0
   Zero           mmword 0.0
   XSquared       mmword ?
   YSquared       mmword ?
   TSquared       mmword ?
   XandY          mmword ?
   XandT          mmword ?
   YandT          mmword ?
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
  MOV [FrameCounter], 0

  XOR R8, R8
  MOV RDI, OFFSET PixelEntry
  
  ;
  ; Initialize Random Pixels
  ;
;  MOVSD xmm0, [t_Input]
;@Init_Pixel:
;  MOVSD PIXEL_ENTRY.X[RDI], xmm0
;  MOVSD PIXEL_ENTRY.Y[RDI], xmm0
;  MOVSD PIXEL_ENTRY.t[RDI], xmm0
;  ADDSD xmm0, [t_Increment]

  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 0FFFFFFh
  MOV PIXEL_ENTRY.Color[RDI], EAX
 
;
; Smooth Color Increment
;  
  MOV EAX,  000001h
  MOV PIXEL_ENTRY.ColorInc[RDI], EAX
  
  MOV RDI, OFFSET PixelHistory
  XOR R8, R8
@Init_To_Zero:
  MOV PIXEL_HISTORY.X[RDI], 0
  MOV PIXEL_HISTORY.Y[RDI], 0
  ADD RDI, SIZE PIXEL_HISTORY
  INC R8
  CMP R8, EQU_ITTERATIONS
  JB @Init_To_Zero

  DEBUG_FUNCTION_CALL FractalA_RandomInitParams
  
;  ADD RDI, SIZE PIXEL_ENTRY
;  INC R8
;  CMP R8, NUM_PIXELS
;  JB @Init_Pixel

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
  JE @SetToNegativeOne
;
; Else Zero
;
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

  ;
  ; Get the Video Buffer
  ; 
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  
  
  XOR R8, R8
  MOV R9, OFFSET PixelEntry

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

  ;
  ; Save these before calling sqrt
  ; 
  MOV R13, RCX
  MOV R12, RAX
  JMP @NoUpdateRollingDelta

  ;
  ; Nothing on screen if enable this code path.  TBD
  ;

  MOV [IsOffScreen], 0
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

  MOVSD xmm1, [SpeedMult]
  MULSD xmm1, [DeltaPerStep]            ; Delta
  ADDSD xmm0, [TenNegFive]              ; dist + 1e-5
  DIVSD xmm1, xmm0                      ; Delta / (dist + 1e-5) = xmm1

  MOVSD xmm0, [MinDelta]
  MULSD xmm0, [SpeedMult]                ; Delta Minimum * Speed Multiplier

  UCOMISD  xmm0, xmm1                      ; Determine the Maximum
  JA @CompareMin
  MOVSD xmm0, xmm1
@CompareMin:
  MOVSD xmm1, [RollingDelta]
  UCOMISD  xmm0, xmm1                     ; Determine the minimum
  JA @NoUpdateRollingDelta
  MOVSD [RollingDelta], xmm0              ; Update if it's less than.

@NoUpdateRollingDelta:
;
; Plot Pixel and Update ColorInc
;
  ;
  ; Restore these, probably should have just switched to using them instead.
  ; 
  MOV RCX, R13
  MOV RAX, R12

  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  XOR EDX, EDX
  MUL EBX
  SHL RCX, 2
  ADD RAX, RCX
  MOV ECX, PIXEL_ENTRY.Color[R9]
  MOV DWORD PTR [RDI+RAX], ECX
  ADD ECX, PIXEL_ENTRY.ColorInc[R9]
  AND ECX, 0FFFFFFh
  MOV PIXEL_ENTRY.Color[R9], ECX

@PixelLoopUpdate:


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
  CMP R8, NUM_PIXELS
  JB @OutterLoop
  JMP @DonePlotting

@CantPlotPixel:
  ;
  ; Save Pixel History
  ;
  MOVSD PIXEL_HISTORY.X[R14], xmm1
  MOVSD PIXEL_HISTORY.Y[R14], xmm2
  ADD R14, SIZE PIXEL_HISTORY

  JMP @PixelLoopUpdate

@UpdatePixelMath:

;     x' = -x^2 + xt + y
;     y' = x^2 - y^2 - t^2 - xy + yt - x + y

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
  MOVSD [XandY], xmm3

  MOVSD xmm3, xmm0
  MULSD xmm3, xmm2
  MOVSD [XandT], xmm3

  MOVSD xmm3, xmm1
  MULSD xmm3, xmm2
  MOVSD [YandT], xmm3

  MOV R15, OFFSET Parameters
  
  MOVSD xmm3, [XSquared]
  MULSD xmm3, EQUATION_PARAMS.Param[R15]
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [TSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandY]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.X[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.y[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm3, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  ;
  ; New X = xmm3
  ;
  MOVSD xmm5, [XSquared]
  MULSD xmm5, EQUATION_PARAMS.Param[R15]
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [TSquared]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandY]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [XandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, [YandT]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.X[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  MOVSD xmm4, PIXEL_ENTRY.y[R9]
  MULSD xmm4, EQUATION_PARAMS.Param[R15]
  ADDSD xmm5, xmm4
  ADD R15, SIZE EQUATION_PARAMS

  ;
  ; xmm5 = New Y
  ;

  MOVSD PIXEL_ENTRY.X[R9], xmm3         ; x'
  MOVSD PIXEL_ENTRY.Y[R9], xmm5         ; y'

;  ADD R9, SIZE PIXEL_ENTRY
  JMP @Update_Pixel

@DonePlotting:
  MOVSD xmm0, [t_Input]
  MOVSD xmm1, [t_End]
  UCOMISD  xmm0, xmm1
  JB @NoReset
  MOVSD xmm0, [t_Start]
  MOVSD [t_Input], xmm0
  DEBUG_FUNCTION_CALL FractalA_RandomInitParams 
  
@NoReset:
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


END