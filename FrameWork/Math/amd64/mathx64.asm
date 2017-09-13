;*********************************************************
; Math Library 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/27/2010-2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc


PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    SaveRdi        dq ?
SAVEFRAME ends

MATH_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
MATH_INIT_LOCALS ends

extern srand:proc
extern time:proc
extern rand:proc
.DATA 
  RdRandSupported dd 0
.CODE

;*********************************************************
;   Math_Init
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Math_Init, _TEXT$00
  alloc_stack(SIZEOF MATH_INIT_LOCALS)
  save_reg rdi, MATH_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 
  
  XOR RCX, RCX
  CALL time
  
  MOV RCX, RAX
  CALL srand
  
  MOV EAX, 1
  CPUID
  TEST ECX, 040000000h
  JZ @NoRdRand
  MOV [RdRandSupported], 1
 @NoRdRand:  
  MOV RDI, MATH_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE MATH_INIT_LOCALS
  
  RET

NESTED_END Math_Init, _TEXT$00

;*********************************************************
;   
;   Math_Rand
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Math_Rand, _TEXT$00
  alloc_stack(SIZEOF MATH_INIT_LOCALS)
.ENDPROLOG 
  
  CMP [RdRandSupported], 1
  JE @PerformRdRand
  CALL rand
  ADD RSP, SIZE MATH_INIT_LOCALS
  RET
    
@PerformRdRand:
  ; db 0fh, 0c7h, 0f0h  Faster RDRAND EAX random number generator.
  
  ADD RSP, SIZE MATH_INIT_LOCALS
  RET

NESTED_END Math_Rand, _TEXT$00



;*********************************************************
;  Math_Sin
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Math_Sin, _TEXT$00
.ENDPROLOG 

  RET
NESTED_END Math_Sin, _TEXT$00



;*********************************************************
;  Math_Cos
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Math_Cos, _TEXT$00
.ENDPROLOG 
  RET
NESTED_END Math_Cos, _TEXT$00



END
