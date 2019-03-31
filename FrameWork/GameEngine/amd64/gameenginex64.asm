;*********************************************************
; Game Engine
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/17/2019
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include demoscene.inc
include dbuffer_public.inc
include font_public.inc
include gif_public.inc
include gameengine_vars.inc 

LMEM_ZEROINIT EQU        <40h>
MAX_FRAMES_PER_IMAGE EQU <3>
DEBUG_STACK_SIZE EQU     <25>  ; Currently ignored, perhaps will be enabled in the future.

extern CloseHandle:proc
extern WaitForSingleObject:proc
extern LocalAlloc:proc
extern Engine_Private_OverrideDemoFunction:proc
extern cos:proc
extern sin:proc
extern LocalFree:proc

public GameEngine_Init
public GameEngine_Free
public GameEngine_PrintWord
public GameEngine_LoadGif
public GameEngine_ConvertImageToSprite
public GameEngine_DisplayFullScreenAnimatedImage
public GameEngine_DisplayCenteredImage
public GameEngine_DisplayTransparentImage
public GameEngine_ChangeState
public GameEngine_DisplaySprite
public GameEngine_LoadGifMemory
public GameEngine_DisplaySpriteNoLoop

MAX_KEYS EQU <256>

.DATA
    GameEngineState             dq ?
    DoubleBuffer                dq ?
    GameEngineStateFunctionPtrs dq ?
    ThreadLoadHandle            dq ?
.CODE

;*********************************************************
;  GameEngine_Init
;
;        Parameters: Mater Demo Struct, Game Init Structure
;
;        Return TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  XOR RAX, RAX
  CMP GAME_ENGINE_INIT.GameLoadFunction[RDI], 0
  JE @SkipLoadingThread

  MOV R8, DEBUG_STACK_SIZE
  MOV RDX, GAME_ENGINE_INIT.GameLoadCxt[RDI]
  MOV RCX, GAME_ENGINE_INIT.GameLoadFunction[RDI]
  DEBUG_FUNCTION_CALL Engine_CreateThread
  CMP EAX, -1
  JE @FailureExit
  CMP EAX, 0
  JE @FailureExit

@SkipLoadingThread:
  MOV [ThreadLoadHandle], RAX

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  CMP EAX, 0
  JE @FailureExit
  MOV [DoubleBuffer], RAX

  MOV RDX, OFFSET GameEngine_FrameStateMachine
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Engine_Private_OverrideDemoFunction

  MOV [GameEngineState], 0
  MOV RCX, GAME_ENGINE_INIT.GameFunctionPtrs[RDI]
  MOV [GameEngineStateFunctionPtrs], RCX
  
  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@FailureExit:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_Init, _TEXT$00

;*********************************************************
;  GameEngine_Free
;
;        Parameters: 
;
;        Return 
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_Free, _TEXT$00



;*********************************************************
;  GameEngine_ChangeState
;     It is up to the user to sync between this and the game scene.
;        Parameters: Game State
;
;        Return 
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_ChangeState, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [GameEngineState], RCX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_ChangeState, _TEXT$00



;*********************************************************
;   GameEngine_FrameStateMachine
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_FrameStateMachine, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP [GameEngineState], GAME_ENGINE_FAILURE_STATE
  JE @Failure

  CMP [ThreadLoadHandle], 0
  JE @SkipWaitCheck

  XOR RDX, RDX
  MOV RCX, [ThreadLoadHandle]
  DEBUG_FUNCTION_CALL WaitForSingleObject
  CMP EAX, 0
  JNE @NotComplete

  MOV RCX, [ThreadLoadHandle]
  DEBUG_FUNCTION_CALL CloseHandle
  MOV [ThreadLoadHandle], 0
  MOV [GameEngineState], 1
  
@NotComplete:  
@SkipWaitCheck:
  ;
  ; Clear the double buffer for use.
  ;
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_ClearBuffer
  
  ;
  ; Determine the state function to call.
  ;
  MOV R10, [GameEngineState]
  MOV R11, [GameEngineStateFunctionPtrs]
  SHL R10, 3
  MOV R11, QWORD PTR [R11 + R10]

  MOV RDX, [DoubleBuffer]               ; Double Buffer
  MOV RCX, RSI                          ; Master Context
  DEBUG_FUNCTION_CALL R11
  
  ;
  ; Update the State Machine
  ;
  MOV [GameEngineState], RAX
  CMP RAX, GAME_ENGINE_FAILURE_STATE
  JE @Failure
  
  ;
  ; Update the double buffer on screen
  ;
  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

  MOV RAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@Failure:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_FrameStateMachine, _TEXT$00

;*********************************************************
;  GameEngine_LoadGif
;
;        Parameters: File Name, Image Information
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_LoadGif, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RDX

  ;
  ; Open and Initialize the GIF Library
  ;
  DEBUG_FUNCTION_CALL Gif_Open
  CMP RAX, 0
  JE @Failed
  MOV IMAGE_INFORMATION.GifHandle[RSI], RAX
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_NumberOfImages
  MOV IMAGE_INFORMATION.NumberOfImages[RSI], RAX

  ;
  ; Get the size of the image to create the buffer
  ;
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageSize
  MOV IMAGE_INFORMATION.ImgOffsets[RSI], RAX
   
 ;
 ; Determine the complete buffer size for all images 
 ;
  XOR EDX, EDX
  MUL IMAGE_INFORMATION.NumberOfImages[RSI]
  
  ;
  ; Allocate the Image Buffer
  ;
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX,0
  JE @FailedWithCleanup
  
  ;
  ; Initialize all of the start up variables
  ;
  MOV IMAGE_INFORMATION.ImageListPtr[RSI], RAX
  MOV IMAGE_INFORMATION.CurrImagePtr[RSI], RAX
  MOV IMAGE_INFORMATION.ImageFrameNum[RSI], 0
  MOV IMAGE_INFORMATION.CurrentImage[RSI], 0
  MOV IMAGE_INFORMATION.ImageMaxFrames[RSI], MAX_FRAMES_PER_IMAGE

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageWidth
  MOV IMAGE_INFORMATION.ImageWidth[RSI], RAX

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageHeight
  MOV IMAGE_INFORMATION.ImageHeight[RSI], RAX
 

  MOV RDI, IMAGE_INFORMATION.ImageListPtr[RSI]
  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RDI
  MOV RDX, IMAGE_INFORMATION.NumberOfImages[RSI]
  DEC RDX
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetAllImage32bpp

  MOV RAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedWithCleanup:
;
; Cleanup TBD
;
@Failed:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_LoadGif, _TEXT$00


;*********************************************************
;  GameEngine_LoadGifMemory
;
;        Parameters: Memory, Image Information
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_LoadGifMemory, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RDX

  ;
  ; Open and Initialize the GIF Library
  ;
  DEBUG_FUNCTION_CALL Gif_InitMemory
  CMP RAX, 0
  JE @Failed
  MOV IMAGE_INFORMATION.GifHandle[RSI], RAX
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_NumberOfImages
  MOV IMAGE_INFORMATION.NumberOfImages[RSI], RAX

  ;
  ; Get the size of the image to create the buffer
  ;
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageSize
  MOV IMAGE_INFORMATION.ImgOffsets[RSI], RAX
   
 ;
 ; Determine the complete buffer size for all images 
 ;
  XOR EDX, EDX
  MUL IMAGE_INFORMATION.NumberOfImages[RSI]
  
  ;
  ; Allocate the Image Buffer
  ;
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX,0
  JE @FailedWithCleanup
  
  ;
  ; Initialize all of the start up variables
  ;
  MOV IMAGE_INFORMATION.ImageListPtr[RSI], RAX
  MOV IMAGE_INFORMATION.CurrImagePtr[RSI], RAX
  MOV IMAGE_INFORMATION.ImageFrameNum[RSI], 0
  MOV IMAGE_INFORMATION.CurrentImage[RSI], 0
  MOV IMAGE_INFORMATION.ImageMaxFrames[RSI], MAX_FRAMES_PER_IMAGE

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageWidth
  MOV IMAGE_INFORMATION.ImageWidth[RSI], RAX

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageHeight
  MOV IMAGE_INFORMATION.ImageHeight[RSI], RAX
 

  MOV RDI, IMAGE_INFORMATION.ImageListPtr[RSI]
  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RDI
  MOV RDX, IMAGE_INFORMATION.NumberOfImages[RSI]
  DEC RDX
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetAllImage32bpp

  MOV RAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedWithCleanup:
;
; Cleanup TBD
;
@Failed:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_LoadGifMemory, _TEXT$00


;*********************************************************
;   GameEngine_ConvertImageToSprite
;
;        Parameters: Sprite Convert Structure
;
;        Return Value: True or False
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_ConvertImageToSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RCX
  MOV RBX, SPRITE_CONVERT.ImageInformationPtr[R12]
  MOV R14, SPRITE_CONVERT.SpriteBasicInformtionPtr[R12]
  
  MOV SPRITE_CONVERT.SpriteBasicAllocated[R12], 0
	
  ;
  ; Error Checking, ensure the caller isn't requesting
  ; more images than are in the image.
  ;
  MOV R8, SPRITE_CONVERT.SpriteImageStart[R12]
  ADD R8, SPRITE_CONVERT.SpriteNumImages[R12]
  CMP R8, IMAGE_INFORMATION.NumberOfImages[RBX]
  JA @FailureExit
  
  CMP R14, 0
  JNE @SkipAllocation
  
  ;
  ; Allocate sprite information if not passed in.
  ;  
  MOV RDX, SIZE SPRITE_BASIC_INFORMATION
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JE @FailureExit
  MOV SPRITE_CONVERT.SpriteBasicInformtionPtr[R12], RAX
  MOV SPRITE_CONVERT.SpriteBasicAllocated[R12], 1
  MOV R14, RAX
@SkipAllocation:
  
  ;
  ; Determine A Single Sprite Image Size
  ;
  MOV RCX, SPRITE_CONVERT.SpriteX2[R12]
  SUB RCX, SPRITE_CONVERT.SpriteX[R12]
  MOV SPRITE_BASIC_INFORMATION.SpriteWidth[R14], RCX
  MOV RAX, SPRITE_CONVERT.SpriteY2[R12]
  SUB RAX, SPRITE_CONVERT.SpriteY[R12]
  MOV SPRITE_BASIC_INFORMATION.SpriteHeight[R14], RAX
  XOR RDX, RDX
  MUL RCX
  SHL RAX, 2
  MOV SPRITE_BASIC_INFORMATION.SpriteOffsets[R14], RAX
  
  ;
  ; Determine the amount of memory needed for all images
  ;
  XOR RDX, RDX
  MOV R8, SPRITE_CONVERT.SpriteNumImages[R12]
  MUL R8
  MOV SPRITE_BASIC_INFORMATION.NumberOfSprites[R14], R8
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JE @FailureExit
  
  MOV SPRITE_BASIC_INFORMATION.SpriteListPtr[R14], RAX
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[R14], RAX
  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[R14], 0
  MOV SPRITE_BASIC_INFORMATION.SpriteFrameNum[R14], 0
  MOV SPRITE_BASIC_INFORMATION.SpriteMaxFrames[R14], 3
  MOV RSI, IMAGE_INFORMATION.ImageListPtr[RBX]
  MOV R10, RSI
  ;
  ; Setup transparent color
  ;
  MOV EAX, DWORD PTR [RSI]
  MOV SPRITE_BASIC_INFORMATION.SpriteTransparentColor[R14], EAX
  
  ;
  ; Copy Images
  ;
  CMP SPRITE_CONVERT.SpriteImageStart[R12], 0
  JE @SkipAdvanceImagePtr
  ;
  ; Advance to the selected start image.
  ;
  XOR RDX, RDX
  MOV RAX, IMAGE_INFORMATION.ImgOffsets[RBX]
  MUL SPRITE_CONVERT.SpriteImageStart[R12]
  ADD RSI, RAX
  MOV R10, RSI
  
@SkipAdvanceImagePtr:
  XOR R9, R9  
  MOV RDI, SPRITE_BASIC_INFORMATION.SpriteListPtr[R14]
@CopyImage:
  XOR R8, R8
  ;
  ; Advance RSI to Sprite Location.
  ;
  MOV RAX, SPRITE_CONVERT.SpriteY[R12]
  XOR RDX, RDX
  MUL IMAGE_INFORMATION.ImageWidth[RBX]
  MOV RCX, SPRITE_CONVERT.SpriteX[R12]
  ADD RAX, RCX
  SHL RAX, 2
  ADD RSI, RAX
  
  @CopyWidth:
  MOV RCX, SPRITE_BASIC_INFORMATION.SpriteWidth[R14]
  REP MOVSD
  
  ;
  ; Advance to the next line.
  ;
  MOV RAX, IMAGE_INFORMATION.ImageWidth[RBX]
  SUB RAX, SPRITE_BASIC_INFORMATION.SpriteWidth[R14]
  SHL RAX, 2
  ADD RSI, RAX
  
  INC R8
  CMP R8, SPRITE_BASIC_INFORMATION.SpriteHeight[R14]
  JB @CopyWidth
  
  ADD R10, IMAGE_INFORMATION.ImgOffsets[RBX]
  MOV RSI, R10
  INC R9
  CMP R9, SPRITE_BASIC_INFORMATION.NumberOfSprites[R14]
  JB @CopyImage
 
  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@FailureExit:
  CMP SPRITE_CONVERT.SpriteBasicAllocated[RSI], 0
  JE @SkipFree
  MOV SPRITE_CONVERT.SpriteBasicAllocated[RSI], 0
  MOV RCX, SPRITE_CONVERT.SpriteBasicInformtionPtr[RSI]
  DEBUG_FUNCTION_CALL LocalFree
@SkipFree:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_ConvertImageToSprite, _TEXT$00


;*********************************************************
;   GameEngine_DisplaySprite
;
;        Parameters: Master struct, SpriteBasic, X, Y
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_DisplaySprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [DoubleBuffer]
  
  ;
  ; Check if frame should be advanced
  ;
  INC SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX]
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RDX]
  CMP SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX], RAX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX], 0
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteOffsets[RDX]
  ADD SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX], RAX

  ;
  ; Check for Frame Wraparound
  ;
  INC SPRITE_BASIC_INFORMATION.CurrentSprite[RDX]
  MOV RAX, SPRITE_BASIC_INFORMATION.NumberOfSprites[RDX]
  CMP SPRITE_BASIC_INFORMATION.CurrentSprite[RDX], RAX
  JB @NoFrameReset

  MOV SPRITE_BASIC_INFORMATION.CurrentSprite[RDX], 0   
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteListPtr[RDX]
  MOV SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX], RAX

@NoFrameReset:
@NoFrameUpdate:

  MOV RSI, SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX]
  MOV R11D, SPRITE_BASIC_INFORMATION.SpriteTransparentColor[RDX]
                          

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
  CMP R10, SPRITE_BASIC_INFORMATION.SpriteWidth[RDX]
  JB @PlotHorizontal
  ;
  ; Wrap to the next location.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RCX]
  SUB RAX, SPRITE_BASIC_INFORMATION.SpriteWidth[RDX]
  SHL RAX, 2
  ADD RDI, RAX

  INC R9
  CMP R9, SPRITE_BASIC_INFORMATION.SpriteHeight[RDX]
  JB @PlotVerticle

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_DisplaySprite, _TEXT$00



;*********************************************************
;   GameEngine_DisplaySpriteNoLoop
;
;        Parameters: Master struct, SpriteBasic, X, Y
;
;        Return Value: TRUE is Complete.
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_DisplaySpriteNoLoop, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [DoubleBuffer]
  
  ;
  ; Check if frame should be advanced
  ;
  INC SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX]
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RDX]
  CMP SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX], RAX
  JB @NoFrameUpdate
  
  ;
  ; Check for Frame Wraparound
  ;
  INC SPRITE_BASIC_INFORMATION.CurrentSprite[RDX]
  MOV RAX, SPRITE_BASIC_INFORMATION.NumberOfSprites[RDX]
  CMP SPRITE_BASIC_INFORMATION.CurrentSprite[RDX], RAX
  JAE @NoFrameUpdate
  ;
  ;  General Frame Update
  ;
  MOV SPRITE_BASIC_INFORMATION.SpriteFrameNum[RDX], 0
  MOV RAX, SPRITE_BASIC_INFORMATION.SpriteOffsets[RDX]
  ADD SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX], RAX

@NoFrameUpdate:

  MOV RSI, SPRITE_BASIC_INFORMATION.CurrSpritePtr[RDX]
  MOV R11D, SPRITE_BASIC_INFORMATION.SpriteTransparentColor[RDX]
                          

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
  CMP R10, SPRITE_BASIC_INFORMATION.SpriteWidth[RDX]
  JB @PlotHorizontal
  ;
  ; Wrap to the next location.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RCX]
  SUB RAX, SPRITE_BASIC_INFORMATION.SpriteWidth[RDX]
  SHL RAX, 2
  ADD RDI, RAX

  INC R9
  CMP R9, SPRITE_BASIC_INFORMATION.SpriteHeight[RDX]
  JB @PlotVerticle

  XOR RAX, RAX
  MOV RCX, SPRITE_BASIC_INFORMATION.NumberOfSprites[RDX]
  CMP SPRITE_BASIC_INFORMATION.CurrentSprite[RDX], RCX
  JB @AnimationStillGoing
  MOV EAX, 1                    ; Animation Completed
@AnimationStillGoing:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_DisplaySpriteNoLoop, _TEXT$00


;*********************************************************
;   GameEngine_DisplayTransparentImage
;
;        Parameters: Master struct, Image, X, Y
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_DisplayTransparentImage, _TEXT$00
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

NESTED_END GameEngine_DisplayTransparentImage, _TEXT$00




;*********************************************************
;   GameEngine_DisplayCenteredImage
;
;        Parameters: Master Struct, Image Struct
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_DisplayCenteredImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R8, RDX
  MOV R9, RCX
  MOV RDI, [DoubleBuffer]

  ;
  ; Check if frame should be advanced
  ;
  INC IMAGE_INFORMATION.ImageFrameNum[R8]
  MOV RCX, IMAGE_INFORMATION.ImageMaxFrames[R8]
  CMP IMAGE_INFORMATION.ImageFrameNum[R8], RCX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV IMAGE_INFORMATION.ImageFrameNum[R8], 0
  MOV RCX, IMAGE_INFORMATION.ImgOffsets[R8]
  ADD IMAGE_INFORMATION.CurrImagePtr[R8], RCX

  ;
  ; Check for Frame Wraparound
  ;
  INC IMAGE_INFORMATION.CurrentImage[R8]
  MOV RCX, IMAGE_INFORMATION.NumberOfImages[R8]
  CMP IMAGE_INFORMATION.CurrentImage[R8], RCX
  JB @NoFrameReset

    MOV IMAGE_INFORMATION.CurrentImage[R8], 0   
    MOV RCX, IMAGE_INFORMATION.ImageListPtr[R8]
    MOV IMAGE_INFORMATION.CurrImagePtr[R8], RCX

@NoFrameReset:
@NoFrameUpdate:

  ;
  ; Center the GIF on the screen
  ;
  MOV RDX, IMAGE_INFORMATION.ImageHeight[R8]
  SHR RDX, 1
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  SHR RAX, 1
  SUB RAX, RDX
  MOV IMAGE_INFORMATION.StartY[R8], RAX
  SHL RAX, 2
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]

  MOV RDX, IMAGE_INFORMATION.ImageWidth[R8]
  SHR RDX, 1
  MOV RBX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHR RBX, 1
  SUB RBX, RDX
  MOV IMAGE_INFORMATION.StartX[R8], RBX
  SHL RBX, 2
  ADD RAX, RBX
  ADD RDI, RAX

;  ADD RCX, RAX
;  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
;  SHL RAX, 1
  

  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[R8]
  
;
; Plot the image on the screen
;
  XOR R10, R10
@PlotImageOnScreenCentered:
  MOV RCX, IMAGE_INFORMATION.ImageWidth[R8]
  REP MOVSD
  MOV RCX, IMAGE_INFORMATION.ImageWidth[R8]
  SHL RCX, 2
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2
  SUB RAX, RCX
  ADD RDI, RAX
  INC R10
  CMP R10, IMAGE_INFORMATION.ImageHeight[R8]
  JB @PlotImageOnScreenCentered

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_DisplayCenteredImage, _TEXT$00


;*********************************************************
;  GameEngine_DisplayFullScreenAnimatedImage
;
;         Parameters: Master Struct, Image Struct
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_DisplayFullScreenAnimatedImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R8, RDX
  MOV R9, RCX

  ;
  ; Check if should advance Start/End to go to full screen
  ;
  CMP IMAGE_INFORMATION.InflateCountDown[R8], 0
  JE @NoUpdate

  DEC IMAGE_INFORMATION.InflateCountDown[R8]
  JNZ @NoUpdate
  MOV RCX, IMAGE_INFORMATION.InflateCountDownMax[R8]
  MOV IMAGE_INFORMATION.InflateCountDown[R8], RCX
  CMP IMAGE_INFORMATION.StartX[R8], 0
  JE @StartXIsComplete
  DEC IMAGE_INFORMATION.StartX[R8]
@StartXIsComplete:
  CMP IMAGE_INFORMATION.StartY[R8], 0
  JE @StartYIsComplete
  DEC IMAGE_INFORMATION.StartY[R8]
@StartYIsComplete:
@NoUpdate:
  ;
  ; Check if frame should be advanced
  ;
  INC IMAGE_INFORMATION.ImageFrameNum[R8]
  MOV RCX, IMAGE_INFORMATION.ImageMaxFrames[R8]
  CMP IMAGE_INFORMATION.ImageFrameNum[R8], RCX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV IMAGE_INFORMATION.ImageFrameNum[R8], 0
  MOV RCX, IMAGE_INFORMATION.ImgOffsets[R8]
  ADD IMAGE_INFORMATION.CurrImagePtr[R8], RCX

  ;
  ; Check for Frame Wraparound
  ;
  INC IMAGE_INFORMATION.CurrentImage[R8]
  MOV RCX, IMAGE_INFORMATION.NumberOfImages[R8]
  CMP IMAGE_INFORMATION.CurrentImage[R8], RCX
  JB @NoFrameReset

  MOV IMAGE_INFORMATION.CurrentImage[R8], 0   
  MOV RCX, IMAGE_INFORMATION.ImageListPtr[R8]
  MOV IMAGE_INFORMATION.CurrImagePtr[R8], RCX

@NoFrameReset:
@NoFrameUpdate:

  ;
  ; Determine Growth of Image by scaling of X and Y
  ;
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SUB RCX, IMAGE_INFORMATION.StartX[R8]
  SUB RCX, IMAGE_INFORMATION.StartX[R8]
  CVTSI2SD XMM0, RCX
  CVTSI2SD XMM1, IMAGE_INFORMATION.ImageWidth[R8]
  DIVSD XMM1, XMM0
  MOVSD IMAGE_INFORMATION.IncrementX[R8], XMM1

  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  SUB RDX, IMAGE_INFORMATION.StartY[R8]
  SUB RDX, IMAGE_INFORMATION.StartY[R8]
  CVTSI2SD XMM0, RDX
  CVTSI2SD XMM1, IMAGE_INFORMATION.ImageHeight[R8]
  DIVSD XMM1, XMM0
  MOVSD IMAGE_INFORMATION.IncrementY[R8], XMM1

  ;
  ; Create the Y start Location.
  ;
  MOV RAX, IMAGE_INFORMATION.StartY[R8]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2

  ;
  ; Create the X Start Location
  ;
  MOV RCX,  IMAGE_INFORMATION.StartX[R8]
  SHL RCX, 2
  ADD RAX, RCX
 
  ;
  ; The Stride
  ;
  MOV RDX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RDX, 2

  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[R8]
  MOV RDI, [DoubleBuffer]
  ADD RDI, RAX
;
; Plot the image on the screen
;
  PXOR XMM0, XMM0
  XOR R10, R10
@PlotScaledY:
  PXOR XMM1, XMM1
  XOR R14, R14
  XOR R12, R12
  ;
  ; Loop and Plot Pixels
  ;
@PlotScaledX:
  SHL R12, 2
  MOV EAX, [RSI + R12]
  MOV [RDI + R14], EAX
  ADD R14, 4
  ADDSD XMM1, IMAGE_INFORMATION.IncrementX[R8]
  CVTSD2SI R12, XMM1
  CMP R12, IMAGE_INFORMATION.ImageWidth[R8]
  JB @PlotScaledX
  ;
  ; Wrap around to the next line
  ;
  ADD RDI, RDX
  ADDSD XMM0, IMAGE_INFORMATION.IncrementY[R8]
  CVTSD2SI R9, XMM0
  CMP R9, R10
  JE @PlotScaledY
  MOV RAX, IMAGE_INFORMATION.ImageWidth[R8]
  ;
  ; Wrap Image to the next size
  ;
  SHL RAX, 2
  ADD RSI, RAX
  MOV R10, R9
  CMP R10, IMAGE_INFORMATION.ImageHeight[R8]
  JB @PlotScaledY

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GameEngine_DisplayFullScreenAnimatedImage, _TEXT$00


;*********************************************************
;  GameEngine_PrintWord
;
;        Parameters: Master Context, String, X, Y, Font Size, Radians, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_PrintWord, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_LV)
 SAVE_ALL_STD_REGS STD_FUNCTION_STACK_LV
 SAVE_ALL_XMM_REGS STD_FUNCTION_STACK_LV
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX ; Master Context
  MOV R15, RDX ; String
  MOV R14, R8  ; X Location
  MOV R12, R9  ; Y Location
  MOV STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param3[RSP], R12

@Plasma_PrintStringLoop:
  ;
  ; Get the Bit Font
  ;
  XOR RCX, RCX
  MOV CL, [R15]
  DEBUG_FUNCTION_CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured

  MOV STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param1[RSP], RAX
  MOV RSI, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param5[RSP]
  MOV STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param2[RSP], 8


@VerticleLines:
       MOV BL, 80h
       MOV R13, R14

@HorizontalLines:
           MOV RAX, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param1[RSP]
           TEST BL, [RAX]
           JZ @NoPixelToPlot 

           MOV  STD_FUNCTION_STACK_LV_PARAMS.LocalVariables.LocalVar1[RSP], RBX

           ;
           ; Let's get the Font Size in R9
           ;
           MOV R9, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param5[RSP]
		   

@PlotRotatedPixel:
              MOV  STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param4[RSP], R9

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

			  MOVSD xmm0, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL cos
			  MULSD xmm0, xmm6
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm7
			  SUBSD xmm9, xmm0

			  ;
			  ; (sin(r)*x + cos(r)*y)
			  ;
			  MOVSD xmm0, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm6
			  MOVSD xmm6, xmm9
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param6[RSP]
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
                          MOV RAX, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param7[RSP]
			  MOV DWORD PTR [RCX], EAX

@PixelOffScreen:
			INC R14
			MOV  RBX, STD_FUNCTION_STACK_LV_PARAMS.LocalVariables.LocalVar1[RSP]
			MOV  R9, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param4[RSP]
			DEC R9
			JNZ @PlotRotatedPixel
			JMP @DonePlottingPixel

@NoPixelToPlot:
        ADD R14, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param5[RSP]
@DonePlottingPixel:
    SHR BL, 1
    TEST BL, BL
    JNZ @HorizontalLines

  MOV R14, R13
  INC R12
  DEC RSI
  JNZ @VerticleLines
  
  MOV RSI, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param5[RSP]
  INC STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param1[RSP]
  DEC STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param2[RSP]
  CMP STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param2[RSP], 0
  JA @VerticleLines

  MOV R12, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param3[RSP]
  

  INC R15

  MOV RCX, STD_FUNCTION_STACK_LV_PARAMS.FuncParams.Param5[RSP]
  SHL RCX, 3
  ADD R14, RCX
  ADD R14, 3
 
  CMP BYTE PTR [R15], 0 
  JNE @Plasma_PrintStringLoop


  MOV EAX, 1
@ErrorOccured:
  RESTORE_ALL_XMM_REGS STD_FUNCTION_STACK_LV
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_LV
  ADD RSP, SIZE STD_FUNCTION_STACK_LV
  RET
NESTED_END GameEngine_PrintWord, _TEXT$00

END
