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
include gameengine_public.inc

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
public Invaders_Demo
public Invaders_Free

;
; Space Invaders State Machine
;
SPACE_INVADERS_STATE_LOADING              EQU <0>
SPACE_INVADERS_STATE_INTRO                EQU <1>
SPACE_INVADERS_STATE_MENU                 EQU <2>
SPACE_INVADERS_LEVEL                      EQU <3>
SPACE_INVADERS_FINAL                      EQU <4>
SPACE_INVADERS_GAMEPLAY                   EQU <5>
SPACE_INVADERS_HISCORE                    EQU <6>
SPACE_INVADERS_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>


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
    SpaceCurrentLevel  dq ?
    SpaceStateFuncPtrs dq Invaders_Loading,
                          Invaders_IntroScreen

    SpaceInvadersLoadingScreenImage db "spaceloadingbackground.gif", 0
    SpaceInvadersIntroImage db "spaceinvadersintro.gif", 0


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
    GameEngInit        GAME_ENGINE_INIT  <?>
    LoadingScreen      IMAGE_INFORMATION <?>
    IntroScreen        IMAGE_INFORMATION  <?>
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
  
  MOV RDX, OFFSET LoadingScreen
  MOV RCX, OFFSET SpaceInvadersLoadingScreenImage
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, OFFSET SpaceStateFuncPtrs
  MOV RDX, OFFSET GameEngInit
  MOV GAME_ENGINE_INIT.GameFunctionPtrs[RDX], RCX
  MOV RCX, OFFSET Invaders_LoadingThread
  MOV GAME_ENGINE_INIT.GameLoadFunction[RDX],RCX
  MOV GAME_ENGINE_INIT.GameLoadCxt[RDX], 0
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_Init
  JE @FailureExit
  
  
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
;   Invaders_Demo
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_Demo, _TEXT$00




;*********************************************************
;   Invaders_LoadingThread
;
;        Parameters: Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadingThread, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
    
  MOV RDX, OFFSET IntroScreen
  MOV RCX, OFFSET SpaceInvadersIntroImage
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
  CMP RAX, 0
  JE @FailureExit

  MOV [IntroScreen.StartX], 0
  MOV [IntroScreen.StartY], 0
  MOV [IntroScreen.InflateCountDown], 0
  MOV [IntroScreen.InflateCountDownMax], 0

  PXOR XMM0, XMM0
  MOVSD [IntroScreen.IncrementX], XMM0
  MOVSD [IntroScreen.IncrementY], XMM0


  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailureExit:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_LoadingThread, _TEXT$00

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
;   Invaders_Loading
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value:State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Loading, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R10, RCX
  MOV R11, RDX
  MOV RSI, [LoadingScreen.ImageListPtr]
  MOV RDI, RDX
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
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RAX, SPACE_INVADERS_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_Loading, _TEXT$00



;*********************************************************
;   Invaders_IntroScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_IntroScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV RAX, SPACE_INVADERS_STATE_INTRO

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_IntroScreen, _TEXT$00


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









END