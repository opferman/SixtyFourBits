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

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter dd ?
   t_Input        mmword -3.0
   t_Increment    mmword 0.01
   PixelEntry     PIXEL_ENTRY NUM_PIXELS DUP(<>)
   NegativeOne    mmword -1.0
   Scale          mmword 0.25
   PlotX          mmword 0.0
   PlotY          mmword 0.0
   PointFive      mmword 0.5
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

  DEBUG_FUNCTION_CALL Math_Rand
  AND EAX, 0FFFFFFh
  MOV PIXEL_ENTRY.ColorInc[RDI], EAX
  
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
  JMP @UpdatePixelMath
  ;
  ; Update Pixels
  ;
@Update_Pixel:
;int 3
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
  JA @CantPlotPixel

  CMP RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JA @CantPlotPixel

;
; Plot Pixel and Update ColorInc
;
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

  MOVSD xmm0, [t_Input]
  ADDSD xmm0, [t_Increment]
  MOVSD [t_Input], xmm0

  INC R8
  CMP R8, NUM_PIXELS
  JB @OutterLoop
  JMP @DonePlotting

@CantPlotPixel:
  ;
  ; TBD - Reinitialize Pixel?
  ;
 ; int 3
  JMP @PixelLoopUpdate

@UpdatePixelMath:

;     x' = -x^2 + xt + y
;     y' = x^2 - y^2 - t^2 - xy + yt - x + y
;int 3
  MOVSD xmm0, PIXEL_ENTRY.X[R9]
  MOVSD xmm1, PIXEL_ENTRY.Y[R9]
  MOVSD xmm2, [t_Input]
  MOVSD xmm3, xmm0
  MULSD xmm3, xmm3                      ; x^2
  MOVSD xmm4, xmm1
  MULSD xmm4, xmm4                      ; y^2
  MULSD xmm4, [NegativeOne]             ; - y^2
  ADDSD xmm4, xmm3                      ; -y^2 + x^2
  MULSD xmm3, [NegativeOne]             ; -x^2
  MOVSD xmm5, xmm2
  MULSD xmm5, xmm5                      ; t^2
  SUBSD xmm4, xmm5                      ; x^2 - y^2 - t^2
  MOVSD xmm5, xmm0
  MULSD xmm5, xmm1                      ; xy
  SUBSD xmm4, xmm5                      ; x^2 - y^2 - t^2 - xy
  MOVSD xmm5, xmm2
  MULSD xmm5, xmm1                      ; yt
  ADDSD xmm4, xmm5                      ; x^2 - y^2 - t^2 - xy + yt
  SUBSD xmm4, xmm0                      ; x^2 - y^2 - t^2 - xy + yt - x
  ADDSD xmm4, xmm1                      ; x^2 - y^2 - t^2 - xy + yt - x + y
  MULSD xmm0, xmm2                      ; xt
  ADDSD xmm3, xmm0                      ; -x^2 + xt
  ADDSD xmm3, xmm1                      ; -x^2 + xt + y

  MOVSD PIXEL_ENTRY.X[R9], xmm3         ; x'
  MOVSD PIXEL_ENTRY.Y[R9], xmm4         ; y'

;  ADD R9, SIZE PIXEL_ENTRY
  JMP @Update_Pixel

@DonePlotting:
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