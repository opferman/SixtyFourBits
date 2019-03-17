;*********************************************************
; Space Invaders Game
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/8/2019
;
;
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************



;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include dbuffer_public.inc
include font_public.inc
include input_public.inc
include gif_public.inc


;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc

LMEM_ZEROINIT EQU <40h>

;*********************************************************
; Structures
;*********************************************************


IMAGE_INFORMATION struct
   GifHandle      dq ?
   ImageListPtr   dq ?
   ImgOffsets     dq ?
   NumberOfImages dq ?
   CurrImagePtr   dq ?
   CurrentImage   dq ?
   ImageFrameNum  dq ?
   ImageMaxFrames dq ?
   ImageWidth     dq ?
   ImageHeight    dq ?
IMAGE_INFORMATION ends
SPRITE_STRUCT struct
   SpriteIndex dd ?
   SpritePtr   dq ?
   SpriteMaxX  dd ?
   SpriteMaxY  dd ?
SPRITE_STRUCT ends

FIRE_STRUCT struct
   VelocityY dd ?
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
FIRE_STRUCT ends

EXPLODE_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   SpriteCountdown dd ?
   Sprite      SPRITE_STRUCT <?>
EXPLODE_STRUCT ends



ALIEN_SPRITE_STRUCT struct
   LocationX   dd ?
   LocationY   dd ?
   Sprite      SPRITE_STRUCT <?>
ALIEN_SPRITE_STRUCT ends

PLAYER_SPRITE_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
PLAYER_SPRITE_STRUCT ends

SPACE_SHIP_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
SPACE_SHIP_STRUCT ends

SHEILD_SPRITE_STRUCT struct
   LocationX         dd ?
   LocationY         dd ?
   DestructCountDown dd ?
   Sprite      SPRITE_STRUCT <?>
SHEILD_SPRITE_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Invaders_Init
public Invaders_FrameStateMachine
public Invaders_Free

;
; Space Invaders State Machine
;
SPACE_INVADERS_STATE_LOADING_SCREEN       EQU <0>
SPACE_INVADERS_STATE_LOADING              EQU <1>
SPACE_INVADERS_STATE_INTRO                EQU <2>
SPACE_INVADERS_STATE_MENU                 EQU <3>
SPACE_INVADERS_LEVEL                      EQU <4>
SPACE_INVADERS_FINAL                      EQU <5>
SPACE_INVADERS_GAMEPLAY                   EQU <6>
SPACE_INVADERS_HISCORE                    EQU <7>
SPACE_INVADERS_FAILURE_STATE              EQU <0FFFFh>

;
; Space Invaders Constants
;
MAX_SCORES            EQU  <5>
MAX_SHIELDS           EQU <3>
MAX_ALIENS_PER_ROW    EQU <1>
MAX_ALIEN_ROWS        EQU <1>
NUMBER_OF_SPRITES     EQU <2>
MAX_LOADING_COLORS    EQU <9>
LOADING_Y             EQU <768/2 - 10>
LOADING_X             EQU <10>
MAX_FRAMES_PER_IMAGE  EQU <1>
LODING_FONT_SIZE      EQU <10>

;*********************************************************
; Data Segment
;*********************************************************
.DATA
    DoubleBuffer       dq ?
    SpaceInvadersState dq ?
    SpaceCurrentLevel  dq ?
    SpaceStateFuncPtrs dq Invaders_LoadingScreen,
                          Invaders_Loading


    SpaceInvadersLoadingScreenImage db "spaceloadingbackground.gif", 0

    ImageLoadingComplete            db 0

    SpriteImageFileListAttributes   db 1, 2
    
    ;
    ; File Lists
    ;
    LoadingString       db "Loading...", 0 
    CurrentLoadingColor dd 0, 0FF000h, 0FF00h, 0FFh, 0FFFFFFh, 0FF00FFh, 0FFFF00h, 0FFFFh, 0F01F0Eh
    LoadingColorsLoop   dd 0

    SpriteImageFileList db  'Alien1_m1.gif', 0
                        db  'Alien1_m2.gif', 0


    ;
    ; Game Variable Structures
    ;
    LoadingScreen      IMAGE_INFORMATION <?>
    ThePlayer          PLAYER_SPRITE_STRUCT <?>
    TheSpaceShip       SPACE_SHIP_STRUCT    <?>
    Aliens             ALIEN_SPRITE_STRUCT (MAX_ALIENS_PER_ROW*MAX_ALIEN_ROWS) DUP(<0>)
    TheShields         SHEILD_SPRITE_STRUCT MAX_SHIELDS DUP(<0>)
    ;HiScoreList        dq MAX_SCORES DUP(<0>)
.CODE

;*********************************************************
;   Invaders_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  CMP EAX, 0
  JE @FailureExit
  MOV [DoubleBuffer], RAX

  MOV RDX, OFFSET LoadingScreen
  MOV RCX, OFFSET SpaceInvadersLoadingScreenImage
  DEBUG_FUNCTION_CALL Invaders_LoadGif
  CMP RAX, 0
  JE @FailureExit

  MOV [SpaceInvadersState], SPACE_INVADERS_STATE_LOADING_SCREEN
  
@SuccessExit:
  MOV EAX, 1
  JMP @ActualExit  
@FailureExit:
  XOR EAX, EAX
@ActualExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Init, _TEXT$00






;*********************************************************
;  Invaders_LoadGif
;
;        Parameters: File Name, Image Information
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadGif, _TEXT$00
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
NESTED_END Invaders_LoadGif, _TEXT$00


;*********************************************************
;   Invaders_FrameStateMachine
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_FrameStateMachine, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP [SpaceInvadersState], SPACE_INVADERS_FAILURE_STATE
  JE @Failure
  
  ;
  ; Clear the double buffer for use.
  ;
  MOV RCX, [DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_ClearBuffer
  
  ;
  ; Determine the state function to call.
  ;
  MOV R8, [SpaceInvadersState]
  LEA RDX, [SpaceStateFuncPtrs]
  SHL R8, 3
  MOV RCX, RSI
  MOV RDX, QWORD PTR [RDX + R8]
  DEBUG_FUNCTION_CALL RDX
  
  ;
  ; Update the State Machine
  ;
  MOV [SpaceInvadersState], RAX
  CMP RAX, SPACE_INVADERS_FAILURE_STATE
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

NESTED_END Invaders_FrameStateMachine, _TEXT$00


;*********************************************************
;   Invaders_ConvertImageToSprite
;
;        Parameters: Sprite Struct, Image Struct
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_ConvertImageToSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_ConvertImageToSprite, _TEXT$00


;*********************************************************
;   Invaders_LoadSprites
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadSprites, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadSprites, _TEXT$00

;*********************************************************
;   Invaders_LoadingScreen
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadingScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R10, RCX
  MOV RSI, [LoadingScreen.ImageListPtr]
  MOV RDI, [DoubleBuffer]
  MOV RCX, [LoadingScreen.ImgOffsets]
  REP MOVSB

  MOV ECX, [LoadingColorsLoop]
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RCX    ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0      ; Radians
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], LODING_FONT_SIZE      ; Font Size
  MOV R9, LOADING_Y
  MOV R8, LOADING_X
  MOV RDX, OFFSET LoadingString
  MOV RCX, R10
  DEBUG_FUNCTION_CALL SpaceInvaders_PrintWord

  MOV RAX, SPACE_INVADERS_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadingScreen, _TEXT$00

;*********************************************************
;   Invaders_Loading
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Loading, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R10, RCX
  MOV RSI, [LoadingScreen.ImageListPtr]
  MOV RDI, [DoubleBuffer]
  MOV RCX, [LoadingScreen.ImgOffsets]
  REP MOVSB

  INC [CurrentLoadingColor]
  CMP [CurrentLoadingColor], MAX_LOADING_COLORS
  JB @DisplayLoading
  MOV [CurrentLoadingColor], 0

@DisplayLoading:
  ;
  ; Load next color
  ;
  MOV EDX, [CurrentLoadingColor]
  MOV RCX, OFFSET LoadingColorsLoop
  SHL RDX, 2
  ADD RCX, RDX
  MOV ECX, [RCX]

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RCX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], LODING_FONT_SIZE
  MOV R9, LOADING_Y
  MOV R8, LOADING_X
  MOV RDX, OFFSET LoadingString
  MOV RCX, R10
  DEBUG_FUNCTION_CALL SpaceInvaders_PrintWord

  MOV RAX, SPACE_INVADERS_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Loading, _TEXT$00



;*********************************************************
;   Invaders_Free
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Free, _TEXT$00



;*********************************************************
;  SpaceInvaders_PrintWord
;
;        Parameters: Master Context, String, X, Y, Font Size, Radians, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY SpaceInvaders_PrintWord, _TEXT$00
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
NESTED_END SpaceInvaders_PrintWord, _TEXT$00





END