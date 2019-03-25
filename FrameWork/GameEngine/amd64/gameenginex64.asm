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


public GameEngine_Init
public GameEngine_Free
public GameEngine_PrintWord
public GameEngine_LoadGif
public GameEngine_ConvertImageToSprite
public GameEngine_DisplayFullScreenAnimatedImage
public GameEngine_DisplayCenteredImage

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
;   GameEngine_ConvertImageToSprite
;
;        Parameters: Sprite Struct, Image Struct
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GameEngine_ConvertImageToSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GameEngine_ConvertImageToSprite, _TEXT$00


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
