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
extern GetCommandLineA:proc

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

FRAME_COUNT_DOWN EQU <3>

;*********************************************************
; Data Segment
;*********************************************************
.DATA
   Success              dq ?
   GifHandle            dq ?
   ImageBufferPtr       dq ?
   NumberOfImages       dq ?
   ImageOffsetIncrement dq ?
   CurrentImagePtr      dq ?
   CurrentImageIndex    dq ?
   DoubleBuffer         dq ?
   ImageStride          dq ?
   ScreenStride         dq ?
   ImageFrameNumber     dq ?

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
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Open and Initialize the GIF Library
  ;
  DEBUG_FUNCTION_CALL Gif_GetCommandLine
  CMP RAX, 0
  JE @Failed

  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_Open
  CMP RAX, 0
  JE @Failed
  MOV [GifHandle], RAX
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_NumberOfImages
  MOV [NumberOfImages], RAX

  ;
  ; Get the size of the image to create the buffer
  ;
  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_GetImageSize
  SHL RAX, 1
  MOV [ImageOffsetIncrement], RAX
  
  XOR EDX, EDX
  MUL [NumberOfImages]
  
  ;
  ; Allocate the Buffer
  ;
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX,0
  JE @FailedAndCloseGif
  MOV [ImageBufferPtr], RAX
  MOV [CurrentImagePtr], RAX
  MOV [CurrentImageIndex], 0
  MOV [ImageFrameNumber], FRAME_COUNT_DOWN
  
  XOR RBX, RBX
  MOV RDI, [ImageBufferPtr]
@GetImages:
  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RDI
  MOV RDX, RBX
  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_GetImage32bpp
  ADD RDI, [ImageOffsetIncrement]
  INC RBX
  CMP RBX, [NumberOfImages]
  JB @GetImages

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
  MOV [Success], 1
  MOV EAX, 1
  RET
@FailedAndCloseGifAndDeallocate:
  MOV RCX, [ImageBufferPtr]
  DEBUG_FUNCTION_CALL LocalFree

@FailedAndCloseGif:
  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_Close
@Failed:
  MOV [Success], 0
  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV RBX, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
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
  MOV RSI, RCX
  CMP [Success], 0
  JE @Failed

  DEC [ImageFrameNumber]
  JNZ @SkipUpdate
  MOV [ImageFrameNumber], FRAME_COUNT_DOWN
  INC [CurrentImageIndex]
  MOV RAX, [ImageOffsetIncrement]
  ADD [CurrentImagePtr], RAX
  MOV RAX, [NumberOfImages]
  CMP [CurrentImageIndex], RAX
  JB @SkipUpdate
  MOV RAX, [ImageBufferPtr]
  MOV [CurrentImagePtr], RAX
  MOV [CurrentImageIndex], 0
  
@SkipUpdate:

  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_GetImageWidth
  MOV R12, RAX

  MOV RCX, [GifHandle]
  DEBUG_FUNCTION_CALL Gif_GetImageHeight
  MOV R13, RAX

  MOV [ImageStride], 0
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SUB R8,R12
  SHL R8, 2
  MOV [ScreenStride], R8

  CMP R12, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JB @NoUpdateToWidth

  MOV R8, R12
  SUB R8,MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R8, 2
  MOV [ImageStride], R8

  MOV R12, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV [ScreenStride], 0
  
@NoUpdateToWidth:

  CMP R13, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JB @NoUpdateToHeight
  MOV R13, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
@NoUpdateToHeight:
  MOV RDX, [DoubleBuffer]
  MOV R11, [CurrentImagePtr]
  XOR R8, R8
@IncrementHeight:
  CMP R8, R13
  JAE @ImageDrawingComplete
  XOR R9, R9
@IncrementWidth:
  CMP R9, R12
  JAE @NextItteration
  MOV EAX, DWORD PTR [R11]
  MOV DWORD PTR [RDX], EAX
  ADD R11, 4
  ADD RDX, 4
  INC R9
  JMP @IncrementWidth
@NextItteration:
  INC R8
  ADD R11, [ImageStride]
  ADD RDX, [ScreenStride]
  JMP @IncrementHeight

@ImageDrawingComplete:
  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen
  

  
  MOV RAX, 1
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]  
  MOV r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14[RSP]
  MOV r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  MOV r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
@Failed:
  XOR RAX, RAX
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
;  Gif_GetCommandLine
;
;        Parameters: None
;        Return: File Pointer
;       
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetCommandLine, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  
  DEBUG_FUNCTION_CALL GetCommandLineA

@FindFile:
  CMP BYTE PTR [RAX], ' '
  JE @FoundSpace
  CMP BYTE PTR [RAX], 0
  JE @Error
  INC RAX
  JMP @FindFile

  ;
  ; Keep Looping Until we find the first
  ; letter of the file name
  ;
@FoundSpace:
  INC RAX
  CMP BYTE PTR [RAX], ' '
  JE @FoundSpace
  CMP BYTE PTR [RAX], 0
  JE @Error
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET

@Error:
  XOR RAX, RAX
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET

NESTED_END Gif_GetCommandLine, _TEXT$00


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