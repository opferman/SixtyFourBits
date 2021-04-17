;*********************************************************
; Coderotting Intro
;
;  Written in Assembly x64
; 
;  By Toby Opferman  April 2021
;
;
;*********************************************************


;**********************************************************************************************************
; Assembly Options
;**********************************************************************************************************


;**********************************************************************************************************
; Included Files
;**********************************************************************************************************
include demoscene.inc
include vpal_public.inc
include font_public.inc
include dbuffer_public.inc
include soft3d_public.inc
include audio_public.inc
include gif_public.inc
include gameengine_public.inc

;**********************************************************************************************************
; External APIs
;**********************************************************************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern LoadResource:proc
extern SizeofResource:proc
extern LockResource:proc
extern FindResourceA:proc
extern cos:proc
extern sin:proc
LMEM_ZEROINIT EQU <40h>


;**********************************************************************************************************
; Public Functions
;**********************************************************************************************************
public Coderotting_Init
public Coderotting_Demo
public Coderotting_Free

;**********************************************************************************************************
; Constants
;**********************************************************************************************************
SCREEN_BUFFER_PIXELS       EQU          <1024*768>
SCREEN_BUFFER_BYTES        EQU          <1024*768*4>                            ; We can hard code this.
SCREEN_WIDTH               EQU          <1024>
PHASE_1                    EQU          <30*3>
PHASE_2                    EQU          <30*21>
PHASE_3                    EQU          <30*26>
PHASE_4                    EQU          <30*36>
;**********************************************************************************************************
; Data Section
;**********************************************************************************************************
.DATA
  DoubleBuffer                          dq ?
  BackDoubleBuffer                      dq ?
  DemoDone                              dq 1
                                      
  FrameCount                            dq 0
                                      
  ;                                   
  ; Audio variable section            
  ;                                   
  AudioFormat                           db 01h, 00h, 02h, 00h, 080h, 03eh, 00h, 00h, 00h, 0fah, 00h, 00h, 04h, 00h, 010h, 00h,00h, 00h
  AudioVolume                           dq 150
  AudioHandle                           dq ?
  AudioDataId                           dq ?
  AudioData                             AUDIO_SOUND_DATA <?>
  AudioImage                            db "AUDIODEMO", 0
  AudioType                             db "AUDIO_TYPE", 0
                                      
  ;                                   
  ; Image variable section            
  ;                                   
  GifType                               db "GIF_TYPE", 0
                                      
  GifBackgroundImage                    db "BACKGROUND", 0
  GifBackgroundImageInformation         IMAGE_INFORMATION <?>
  GifBackgroundDataPtr                  dq ?

  GifCoderottingImage                   db "CODROTTING", 0  
  GifCoderottingImageInformation        IMAGE_INFORMATION <?>  
  GifCoderottingImageFadeInformation    IMAGE_INFORMATION <?>               
  GifCoderottingDataPtr                 dq ?
     

;**********************************************************************************************************
; Code Section
;**********************************************************************************************************
.CODE

;*********************************************************
;   Coderotting_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  MOV RSI, RCX

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CoderottingInit_Failed

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [BackDoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CoderottingInit_Failed

  DEBUG_FUNCTION_CALL Coderotting_LoadImages
  DEBUG_FUNCTION_CALL Coderotting_LoadAndStartAudio

  MOV R8, SCREEN_BUFFER_BYTES           
  MOV RDX, [GifBackgroundImageInformation.CurrImagePtr]
  MOV RCX, [BackDoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_FastMove

  MOV RCX, 1024*4 / 8
  XOR RAX, RAX
  MOV RDI, [BackDoubleBuffer]
  REP STOSQ

  MOV R8, RSI
  MOV RDX, OFFSET GifCoderottingImageFadeInformation
  MOV RCX, OFFSET GifCoderottingImageInformation
  DEBUG_FUNCTION_CALL Coderotting_DuplicateImage

  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CoderottingInit_Failed:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_Init, _TEXT$00


;*********************************************************
;   Coderotting_CodeRotting
;
;        Parameters: Input Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_CodeRotting, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  MOV RDI, RCX
  XOR R12, R12
@LoopNextPixel:
  CMP DWORD PTR [RDI], 0
  JE @NextPixel
  
  DEC BYTE PTR [RDI]
  DEC BYTE PTR [RDI+1]
  DEC BYTE PTR [RDI+2]

@NextPixel:
  ADD RDI, 4
  INC R12
  CMP R12, SCREEN_BUFFER_PIXELS
  JB @LoopNextPixel
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_CodeRotting, _TEXT$00


;*********************************************************
;  Coderotting_LoadAndStartAudio
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_LoadAndStartAudio, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  LEA RCX, [AudioFormat]
  DEBUG_FUNCTION_CALL Audio_Init
  CMP RAX, 0
  JE @Audio_Failed
  MOV [AudioHandle], RAX

  LEA RDX, [AudioData]
  LEA RCX, [AudioImage]
  DEBUG_FUNCTION_CALL Coderotting_LoadAudioResource

  LEA RDX, [AudioData]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_AddMusic
  MOV [AudioDataId], RAX

  MOV RDX, [AudioVolume]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_SetVolume

  MOV RDX, [AudioDataId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic
  MOV RAX, 1

@Audio_Failed:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_LoadAndStartAudio, _TEXT$00

;*********************************************************
;   Coderotting_LoadAudioResource
;
;        Parameters: Resource Name, Sound Data Structure
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_LoadAudioResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  MOV R8, OFFSET AudioType               ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA
  MOV RDX, RAX
  MOV R15, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL SizeofResource
  MOV AUDIO_SOUND_DATA.PcmDataSize[RDI], RAX

  MOV RDX, R15
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  MOV AUDIO_SOUND_DATA.PcmData[RDI], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Coderotting_LoadAudioResource, _TEXT$00


;*********************************************************
;  Coderotting_LoadImages
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_LoadImages, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  LEA RCX, [GifBackgroundImage]
  DEBUG_FUNCTION_CALL Coderotting_LoadGifResource
  CMP RAX, 0
  JE @NotLoaded
  MOV [GifBackgroundDataPtr], RAX

  LEA RDX, [GifBackgroundImageInformation]
  MOV RCX, [GifBackgroundDataPtr]
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory

  LEA RCX, [GifCoderottingImage]
  DEBUG_FUNCTION_CALL Coderotting_LoadGifResource
  CMP RAX, 0
  JE @NotLoaded
  MOV [GifCoderottingDataPtr], RAX

  LEA RDX, [GifCoderottingImageInformation]
  MOV RCX, [GifCoderottingDataPtr]
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory

@NotLoaded:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_LoadImages, _TEXT$00


;*********************************************************
;   Coderotting_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifType                 ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA

  MOV RDX, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Coderotting_LoadGifResource, _TEXT$00






;*********************************************************
;   Coderotting_Demo
;
;        Parameters: Master Context
;*********************************************************  
NESTED_ENTRY Coderotting_Demo, _TEXT$00                                 ; Demo tape
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK                                  ; I'm not even supposed to be here.
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO                                                 ; check this macro.
  MOV RDI, RCX
  INC [FrameCount]                                                      ; I don't even know how to count.
  CMP [FrameCount], PHASE_4                                             ; Using framecount to advance? what nonsense.
  JAE @PhaseFour
  CMP [FrameCount], PHASE_3
  JAE @PhaseThree                                                       ; This was a bad sequel to the original phase.
  CMP [FrameCount], PHASE_2
  JAE @PhaseTwo
  CMP [FrameCount], PHASE_1                                             ; Why do we need to setup phases like this?
  JBE @CopyToFrontBuffer
@TryUpdateBackground:                                                   ; Better do more than just try.
  TEST [FrameCount], 1
  JZ @CopyToFrontBuffer                                                 ; Front back side back scratching buffer?
  MOV RCX, [BackDoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_CodeRotting                           ; This code won't work for long
  MOV RAX, [FrameCount]
  AND AL, 3                                                             ; And what?
  CMP AL, 3                                                             ; Three.  I understand Three.
  JNE @CopyToFrontBuffer
  MOV RDX, OFFSET GifCoderottingImageFadeInformation                    ; TBD: Need to have this code fixed someday
  MOV RCX, OFFSET GifCoderottingImageInformation
  DEBUG_FUNCTION_CALL Coderotting_FadeInImage                           ;  Wax on, Wax Off
@CopyToFrontBuffer:
  MOV R8, SCREEN_BUFFER_BYTES                                           ; Screen Bites.
  MOV RDX, [BackDoubleBuffer]
  MOV RCX, [DoubleBuffer]                                               ; Double buffering back buffers side buffers?
  DEBUG_FUNCTION_CALL Coderotting_FastMove                              ; WIP: make this actually a fast move someday
@UpdateLogoImage:
  MOV R9, 768 / 3                                                       ; What is this, just random numbers?
  MOV R8, 20
  MOV RDX, OFFSET GifCoderottingImageFadeInformation                    ; Fix this before production.
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL Coderotting_DisplayTransparentImage               ; What else would you do with a transparent image?
  JMP @UpdateScreenAndExitToDenmark
@PhaseTwo:                                                              ; Something is rotten in the state of denmark.
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_CodeDripping                          ; I don't even know what I'm doing here.
  JMP @UpdateScreenAndExitToDenmark
@PhaseThree:                                                            ; What did you do last weekend?
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_ColorRotate                           
  JMP @UpdateScreenAndExitToDenmark
@PhaseFour:
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_ColorRotate 
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Coderotting_Fade
  MOV [DemoDone], RAX
@SkipFrame:
@UpdateScreenAndExitToDenmark:
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreenFast

  MOV RAX, [DemoDone]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Coderotting_Demo, _TEXT$00

;*********************************************************
;   Coderotting_FastMove
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_FastMove, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, RDX
  MOV RCX, R8
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Coderotting_FastMove, _TEXT$00


;*********************************************************
;  Coderotting_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; TODO: Stop being lazy about clean up.
  ;

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_Free, _TEXT$00


;*********************************************************
;  Coderotting_DuplicateImage
;
;        Parameters: Image, Duplicate, Master Image
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_DuplicateImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV IMAGE_INFORMATION.NumberOfImages[RDX], 1
  MOV IMAGE_INFORMATION.CurrentImage[RDX], 0
  MOV IMAGE_INFORMATION.ImageFrameNum[RDX], 0
  MOV IMAGE_INFORMATION.ImageMaxFrames[RDX], 1

  MOV RAX, IMAGE_INFORMATION.ImageWidth[RCX]
  MOV IMAGE_INFORMATION.ImageWidth[RDX], RAX

  MOV RAX, IMAGE_INFORMATION.ImageHeight[RCX]
  MOV IMAGE_INFORMATION.ImageHeight[RDX], RAX
  MOV RBX, RDX

  MOV RDX, 4
  MOV RCX, R8
  DEBUG_FUNCTION_CALL DBuffer_Create
  
  MOV IMAGE_INFORMATION.ImageListPtr[RBX], RAX
  MOV IMAGE_INFORMATION.CurrImagePtr[RBX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_DuplicateImage, _TEXT$00


;*********************************************************
;  Coderotting_FadeInImage
;
;        Parameters: Image, Duplicate
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_FadeInImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, IMAGE_INFORMATION.CurrImagePtr[RDX]
  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[RCX]

  XOR R8, R8
@UpdateVerticle:
  XOR R9, R9
@UpdateHorizontal:
  MOV EAX, [RDI]
  CMP [RSI], EAX
  JE @NextPixel

@TryBlue:
  CMP [RSI], AL
  JE @TryGreen
  INC BYTE PTR [RDI]

@TryGreen:
  SHR EAX, 8
  CMP [RSI+1], AL
  JE @TryRed
  INC BYTE PTR [RDI+1]

@TryRed:
  SHR EAX, 8
  CMP [RSI+2], AL
  JE @NextPixel
  INC BYTE PTR [RDI+2]


@NextPixel:
  ADD RDI, 4
  ADD RSI, 4
  INC R9
  CMP R9, IMAGE_INFORMATION.ImageWidth[RCX]
  JB @UpdateHorizontal
  INC R8
  CMP R8, IMAGE_INFORMATION.ImageHeight[RCX]
  JB @UpdateVerticle

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_FadeInImage, _TEXT$00


;*********************************************************
;   Coderotting_DisplayTransparentImage
;
;        Parameters: 
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_DisplayTransparentImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [DoubleBuffer]
  
  ;
  ; Check if frame should be advanced
  ;
  INC IMAGE_INFORMATION.ImageFrameNum[RDX]
  MOV RAX, IMAGE_INFORMATION.ImageMaxFrames[RDX]
  CMP IMAGE_INFORMATION.ImageFrameNum[RDX], RAX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV IMAGE_INFORMATION.ImageFrameNum[RDX], 0
  MOV RAX, IMAGE_INFORMATION.ImgOffsets[RDX]
  ADD IMAGE_INFORMATION.CurrImagePtr[RDX], RAX

  ;
  ; Check for Frame Wraparound
  ;
  INC IMAGE_INFORMATION.CurrentImage[RDX]
  MOV RAX, IMAGE_INFORMATION.NumberOfImages[RDX]
  CMP IMAGE_INFORMATION.CurrentImage[RDX], RAX
  JB @NoFrameReset

  MOV IMAGE_INFORMATION.CurrentImage[RDX], 0   
  MOV RAX, IMAGE_INFORMATION.ImageListPtr[RDX]
  MOV IMAGE_INFORMATION.CurrImagePtr[RDX], RAX

@NoFrameReset:
@NoFrameUpdate:

  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[RDX]
  MOV R11D, DWORD PTR [RSI]                             ; Assume 1st pixel is transparent.

  ; R8 - X
  ; R9 - Y
  MOV RAX, R9
  SHL RAX, 2
  MOV R9, RDX
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[RCX]
  ADD RDI, RAX
  SHL R8, 2
  ADD RDI, R8
  MOV RDX, R9

;
; Plot the image on the screen, no screen bounds checking currently -- TBD
;
  XOR R9, R9
@PlotVerticle:
  XOR R10, R10
@PlotHorizontal:
  CMP R11D, DWORD PTR [RSI]
  JE @SkipPixel

  MOV EAX, [RSI]
  MOV [RDI], EAX
@SkipPixel:
  ADD RDI, 4
  ADD RSI, 4
  INC R10
  CMP R10, IMAGE_INFORMATION.ImageWidth[RDX]
  JB @PlotHorizontal
  ;
  ; Wrap to the next location.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RCX]
  SUB RAX, IMAGE_INFORMATION.ImageWidth[RDX]
  SHL RAX, 2
  ADD RDI, RAX

  INC R9
  CMP R9, IMAGE_INFORMATION.ImageHeight[RDX]
  JB @PlotVerticle

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Coderotting_DisplayTransparentImage, _TEXT$00

;*********************************************************
;  Coderotting_Fade
;
;        Parameters: Buffer To Rot
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_Fade, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR R11, R11
  XOR R9, R9
  MOV RDI, RCX
  ADD RDI, SCREEN_BUFFER_BYTES-1
@RottingLoop:
  DEC RDI
  XOR R10, R10
@InnerRot:
  MOV AL, [RDI]
  MOV BL, [RDI - 1024*4]
  MOV CL, [RDI - 1024*4 + 4]
  MOV DL, [RDI - 1024*4 - 4]
  MOVZX AX, AL
  MOVZX BX, BL
  MOVZX CX, CL
  MOVZX DX, DL
  ADD AX, BX
  ADD CX, DX
  ADD AX, CX
  SHR AX, 2
  CMP AL, 0
  JE @NoDec
  DEC AL
@NoDec:
  MOV [RDI], AL
  CMP AL, 0
  JE @NoUpdate
  MOV R11, 1
@NoUpdate:
  DEC RDI
  INC R10
  CMP R10, 3
  JB @InnerRot
  INC R9
  CMP R9, SCREEN_BUFFER_PIXELS - (1024)
  JB @RottingLoop

  MOV RAX, R11

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_Fade, _TEXT$00

;*********************************************************
;  Coderotting_Fade
;
;        Parameters: Buffer To Rot
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_CodeDripping, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  XOR R9, R9
  MOV RDI, RCX
  ADD RDI, SCREEN_BUFFER_BYTES-1
@RottingLoop:
  DEC RDI
  XOR R10, R10
  CMP DWORD PTR [RDI], 0
  JE @InnerRot
  SUB RDI, 3
  JMP @SkipPixel
@InnerRot:
  MOV AL, [RDI - 1024*4 - 4]
  MOV [RDI], AL
  DEC RDI
  INC R10
  CMP R10, 3
  JB @InnerRot
@SkipPixel:
  INC R9
  CMP R9, SCREEN_BUFFER_PIXELS - (1024)
  JB @RottingLoop
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_CodeDripping, _TEXT$00



;*********************************************************
;  Coderotting_ColorRotate
;
;        Parameters: Buffer To Rot
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Coderotting_ColorRotate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  XOR R9, R9
  MOV RDI, RCX
@RottingLoop:
  CMP DWORD PTR [RDI], 0
  JE @SkipPixel
  MOV EAX, [RDI]
  MOV ECX, EAX
  SHR EAX, 16
  SHL ECX, 8
  MOV CL, AL
  AND ECX, 0FFFFFFh
  MOV DWORD PTR [RDI], ECX
@SkipPixel:
  ADD RDI, 4
  INC R9
  CMP R9, SCREEN_BUFFER_PIXELS
  JB @RottingLoop
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Coderotting_ColorRotate, _TEXT$00




END

