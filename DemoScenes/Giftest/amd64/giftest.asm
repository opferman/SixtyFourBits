;*********************************************************
; Gif Test 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/9/2019
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include gif_public.inc
include dbuffer_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc


;*********************************************************
; Structures
;*********************************************************
LMEM_ZEROINIT        EQU <40h>

;*********************************************************
; Public Declarations
;*********************************************************
public Gif_Init
public Gif_Demo
public Gif_Free


;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FileName      db "MyGif.gif", 0
   GifHandle     dq ?
   ImageBuffer   dq ?
   DoubleBuffer  dq ?

.CODE

;*********************************************************
;   Gif_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_Init, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Open and Initialize the GIF Library
  ;
  MOV RCX, OFFSET FileName
  DEBUG_FUNCTION_CALL Gif_Open
  CMP RAX, 0
  JE @Failed
  MOV [GifHandle], RAX

  ;
  ; Get the size of the image to create the buffer
  ;
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_GetImageSize

  ;
  ; Allocate the Buffer
  ;
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX,0
  JE @FailedAndCloseGif
  MOV [ImageBuffer], RAX

  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RAX
  MOV RDX, 0
  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_GetImage32bpp

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  CMP RAX, 0
  JE @FailedAndCloseGifAndDeallocate

@ReadToGo:
  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  MOV EAX, 1
  RET
@FailedAndCloseGifAndDeallocate:
  MOV RCX, [ImageBuffer]
  DEBUG_FUNCTION_CALL LocalFree

@FailedAndCloseGif:
  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_Close
@Failed:
  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  XOR RAX, RAX
  RET

NESTED_END Gif_Init, _TEXT$00



;*********************************************************
;  Gif_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Gif_Demo, _TEXT$00
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
  MOV RAX, 0
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  MOV r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14[RSP]
  MOV r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  MOV r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END Gif_Demo, _TEXT$00



;*********************************************************
;  Gif_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Gif_Free, _TEXT$00
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
NESTED_END Gif_Free, _TEXT$00


END