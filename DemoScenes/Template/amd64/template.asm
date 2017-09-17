;*********************************************************
; Template 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  4/20/2017
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
include debug_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc


;*********************************************************
; Structures
;*********************************************************
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
    SaveR14        dq ?
    SaveR15        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

TEMPLATE_FUNCTION_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
TEMPLATE_FUNCTION_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Template_Init
public Template_Demo
public Template_Free

MAX_FRAMES EQU <200>

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter dd ?

.CODE

;*********************************************************
;   Template_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Template_Init, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [FrameCounter], 0

  MOV RSI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Template_Init, _TEXT$00



;*********************************************************
;  Template_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Template_Demo, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r14, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR14
 save_reg r15, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR15
 save_reg r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ; 
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  

  ;
  ; Generate new random color
  ;
  DEBUG_FUNCTION_CALL Math_rand
  AND EAX, 0FFFFFFh
  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]

@PlotLineColor:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD

  ;
  ; Wrap to the next line by adjusting for stride
  ;
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R8, 2
  SUB RBX, R8
  ADD RDI, RBX

  ;
  ; Decrement for the next line
  ;
  DEC RDX
  JNZ @PlotLineColor

  ;
  ; Update the frame counter and determine if the demo is complete.
  ;
  XOR EAX, EAX
  INC [FrameCounter]
  CMP [FrameCounter], MAX_FRAMES
  SETE AL
  XOR AL, 1
 
  MOV rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r14, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR14[RSP]
  MOV r15, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR15[RSP]
  MOV r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  RET
NESTED_END Template_Demo, _TEXT$00



;*********************************************************
;  Template_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Template_Free, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  ; Nothing to clean up

  MOV rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  RET
NESTED_END Template_Free, _TEXT$00


END