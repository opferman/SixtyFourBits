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

LMEM_ZEROINIT EQU <40h>
MAX_FRAMES_PER_IMAGE EQU <3>

extern LocalAlloc:proc
extern Engine_Private_OverrideDemoFunction:proc
extern cos:proc
extern sin:proc

public GameEngine_Init
public GameEngine_Free
public GameEngine_PrintWord
public GameEngine_LoadGif
public GameEngine_ConvertImageToSprite

.DATA
    GameEngineState             dq ?
    DoubleBuffer                dq ?
    GameEngineStateFunctionPtrs dq ?

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
 
  XOR RBX, RBX
  MOV RDI, IMAGE_INFORMATION.ImageListPtr[RSI]
@GetImages:

  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RDI
  MOV RDX, RBX
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImage32bpp

  ADD RDI, IMAGE_INFORMATION.ImgOffsets[RSI]

  INC RBX
  CMP RBX, IMAGE_INFORMATION.NumberOfImages[RSI]
  JB @GetImages

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
