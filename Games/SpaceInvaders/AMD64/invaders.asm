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
include primatives_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc
extern FindResourceA:proc
extern LoadResource:proc

LMEM_ZEROINIT EQU <40h>

;*********************************************************
; Structures
;*********************************************************



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
SPACE_INVADERS_ABOUT                      EQU <7>
SPACE_INVADERS_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>

SPRITE_STRUCT  struct
   ImagePointer    dq ?
   ExplodePointer  dq ?
   SpriteAlive     dq ?
   SpriteX         dq ?
   SpriteY         dq ?
SPRITE_STRUCT  ends 

;
; Space Invaders Constants
;
MAX_SCORES            EQU <5>
MAX_SHIELDS           EQU <3>
MAX_ALIENS_PER_ROW    EQU <1>
MAX_ALIEN_ROWS        EQU <1>
NUMBER_OF_SPRITES     EQU <2>
MAX_LOADING_COLORS    EQU <9>
LOADING_Y             EQU <768/2 - 10>
LOADING_X             EQU <10>
MAX_FRAMES_PER_IMAGE  EQU <1>
LODING_FONT_SIZE      EQU <10>
TITLE_X               EQU <250>
TITLE_Y               EQU <10>
INTRO_Y               EQU <768 - 40>
INTRO_X               EQU <300>
INTRO_FONT_SIZE       EQU <3>
NUMBER_OF_SPRITES     EQU <29>
MAX_MENU_SELECTION    EQU <5>

;*********************************************************
; Data Segment
;*********************************************************
.DATA
    SpaceCurrentLevel  dq ?
    SpaceStateFuncPtrs dq Invaders_Loading,
                          Invaders_IntroScreen,
                          Invaders_MenuScreen, 
                          Invaders_BoxIt
                          ;Invaders_HiScores,
                          ;Invaders_About,
                          ;Invaders_Instructions,
                         ; 0

			;Invaders_SpriteTest
                          
                          ;Invaders_MenuScreen
    SpaceCurrentState  dq ?
    GifResourceType                 db "GIFFILE", 0
    SpaceInvadersLoadingScreenImage db "LOADING_GIF", 0
    SpaceInvadersIntroImage         db "INTRO_GIF", 0
    SpaceInvadersMenuImage          db "MENU_GIF", 0
    SpaceInvadersTitle              db "LOGO_GIF", 0
    SpaceInvaderSprites             db "SPRITES_GIF", 0
    SpaceInvadersAbout              db "ABOUT_GIF", 0

    PressSpaceToContinue            db "<Press Spacebar>", 0

    MenuText                        dq 400, 300
                                    db "Play Game", 0
                                    dq 350, 350
                                    db "Instructions",0
                                    dq 400, 400
                                    db "Hi-Scores", 0
                                    dq 440, 450
                                    db "About", 0
                                    dq 445, 500
                                    db "Quit", 0
                                    dq 0
    MenuSelection                   dq 0
    MenuToState                     dq SPACE_INVADERS_LEVEL
                                    dq SPACE_INVADERS_GAMEPLAY
                                    dq SPACE_INVADERS_HISCORE
                                    dq SPACE_INVADERS_ABOUT
                                    dq SPACE_INVADERS_FAILURE_STATE  ; Quit

    SpriteImageFileListAttributes   db 1, 2
    ;
    ; File Lists
    ;
    LoadingString       db "Loading...", 0 
    CurrentLoadingColor dd 0 
    LoadingColorsLoop   dd 0FF000h, 0FF00h, 0FFh, 0FFFFFFh, 0FF00FFh, 0FFFF00h, 0FFFFh, 0F01F0Eh
    SpritePointer       dq OFFSET BasicSpriteData
    ;
    ; List of Sprite Information
    ;
    SpriteInformation   dq  26, 47, 89, 144, 0,16       ; X, Y, X2, Y2, Start Image Number, Number Of Images
                        dq 103, 31, 167, 159, 0,16
                        dq 189, 31, 253, 159, 0,16
                        dq 426, 54, 490, 150, 0,16
                        dq 508, 54, 572, 150, 0, 16
                        dq 53, 284, 84, 319, 0,16
                        dq 104, 284, 135, 319, 0,16
                        dq 155, 284, 186, 319, 0,16
                        dq 53+51+51+51, 284, 84+51+51+51, 319, 0,16
                        dq 53+51+51+51+51-3, 284, 84+51+51+51+51-3, 319, 0, 16
                        dq 53+51+51+51+51+51-2, 284, 84+51+51+51+51+51, 319, 0,16
                        dq 53+51+51+51+51+51+51-1, 284, 84+51+51+51+51+51+51, 319, 0,16
                        dq 53+51+51+51+51+51+51+51, 284, 84+51+51+51+51+51+51+51-7, 319, 0,16
                        dq 53+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51-4, 319, 0,16
                        dq 53+51+51+51+51+51+51+51+51+51-4, 284, 84+51+51+51+51+51+51+51+51+51-3, 319, 0,16
                        dq 115-1,420-31,  150-1, 454-31, 0,16
                        dq 164-1, 420-31, 201-1, 454-31, 0,16
                        dq 213-1, 420-31, 247-1,  454-31, 0,16
                        dq 37-1, 369-31, 66-1, 401-31, 0,16
                        dq 37+50-1, 369-31, 66+50-1, 401-31, 0,16
                        dq 37+50+50-1, 369-31,  66+50+50-1, 401-31, 0,16
                        dq 37+50+50+50-1,369-31, 66+50+50+50-1, 401-31, 0,16
                        dq 37+50+50+50+50-1, 369-31, 66+50+50+50+50-1, 401-31, 0,16
                        dq  37+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50-1,  401-31, 0,16
                        dq  37+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50-1, 401-31, 0,16
                        dq 37+50+50+50+50+50+50+50-1, 369-31, 66 +50+50+50+50+50+50+50-1, 401-31, 0,16
                        dq  37+50+50+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50+50+50-1, 401-31, 0,16
                        dq  37+50+50+50+50+50+50+50+50+50-1, 369-31, 66+50+50+50+50+50+50+50+50+50-1, 401-31, 0,16
                        dq  37+50+50+50+50+50+50+50+50+50+50-1, 369-31,66+50+50+50+50+50+50+50+50+50+50-1 , 401-31, 0,16
    ;
    ; Game Variable Structures
    ;
    SpriteConvert      SPRITE_CONVERT <?>
    GameEngInit        GAME_ENGINE_INIT   <?>
    LoadingScreen      IMAGE_INFORMATION  <?>
    IntroScreen        IMAGE_INFORMATION  <?>
    MenuScreen         IMAGE_INFORMATION  <?>
    SpTitle            IMAGE_INFORMATION  <?>
    SpAbout            IMAGE_INFORMATION  <?>
    SpInvaders         IMAGE_INFORMATION  <?>
    BasicSpriteData    SPRITE_BASIC_INFORMATION  NUMBER_OF_SPRITES DUP(<?>) 
    SpSpriteList       dq ?
  ;  HiScoreList        dq MAX_SCORES DUP(<>)
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

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_LOADING
  
  MOV RCX, OFFSET SpaceInvadersLoadingScreenImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
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

  MOV RDX, Invaders_SpaceBar
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease
  
  MOV RDX, Invaders_UpArrow
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, Invaders_DownArrow
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, Invaders_Enter
  MOV RCX, VK_RETURN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

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
;   Invaders_SpaceBar
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SpaceBar, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  JNE @CheckOtherState
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RCX, SPACE_INVADERS_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_SpaceBar, _TEXT$00


;*********************************************************
;   Invaders_Enter
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Enter, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState
  
  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RCX, SPACE_INVADERS_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  ADD [SpritePointer], SIZE SPRITE_BASIC_INFORMATION
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_Enter, _TEXT$00



;*********************************************************
;   Invaders_DownArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DownArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState

  INC QWORD PTR [MenuSelection]
  
  CMP QWORD PTR [MenuSelection], MAX_MENU_SELECTION
  JB @NoResetToStart
  MOV [MenuSelection], 0

@NoResetToStart:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_DownArrow, _TEXT$00


;*********************************************************
;   Invaders_UpArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_UpArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  JNE @CheckOtherState

  CMP QWORD PTR [MenuSelection], 0
  JA @Decrement
  MOV [MenuSelection], MAX_MENU_SELECTION
@Decrement:
  DEC QWORD PTR [MenuSelection]
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Invaders_UpArrow, _TEXT$00

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

  MOV RCX, OFFSET SpaceInvadersIntroImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX
    
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [IntroScreen.StartX], 0
  MOV [IntroScreen.StartY], 0
  MOV [IntroScreen.InflateCountDown], 0
  MOV [IntroScreen.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [IntroScreen.IncrementX], XMM0
  MOVSD [IntroScreen.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersMenuImage
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [MenuScreen.StartX], 0
  MOV [MenuScreen.StartY], 0
  MOV [MenuScreen.InflateCountDown], 0
  MOV [MenuScreen.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [MenuScreen.IncrementX], XMM0
  MOVSD [MenuScreen.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersTitle
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpTitle
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpTitle.StartX], 0
  MOV [SpTitle.StartY], 0
  MOV [SpTitle.InflateCountDown], 0
  MOV [SpTitle.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpTitle.IncrementX], XMM0
  MOVSD [SpTitle.IncrementY], XMM0

  MOV RCX, OFFSET SpaceInvadersAbout
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpAbout
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpAbout.StartX], 0
  MOV [SpAbout.StartY], 0
  MOV [SpAbout.InflateCountDown], 0
  MOV [SpAbout.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpAbout.IncrementX], XMM0
  MOVSD [SpAbout.IncrementY], XMM0
  
  MOV RCX, OFFSET SpaceInvaderSprites
  DEBUG_FUNCTION_CALL Invaders_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET SpInvaders
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
  CMP RAX, 0
  JE @FailureExit

  MOV [SpInvaders.StartX], 0
  MOV [SpInvaders.StartY], 0
  MOV [SpInvaders.InflateCountDown], 0
  MOV [SpInvaders.InflateCountDownMax], 0
  PXOR XMM0, XMM0
  MOVSD [SpInvaders.IncrementX], XMM0
  MOVSD [SpInvaders.IncrementY], XMM0
  MOV [SpInvaders.ImageHeight], 700
  
  DEBUG_FUNCTION_CALL Invaders_LoadSprites


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
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadSprites, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, OFFSET BasicSpriteData
  MOV RDI, OFFSET SpInvaders

  XOR RSI, RSI
  MOV R12, OFFSET SpriteInformation
@LoadNextSprite:

  MOV [SpriteConvert.ImageInformationPtr], RDI
  MOV [SpriteConvert.SpriteBasicInformtionPtr], RBX

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteX], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteY], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteX2], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteY2], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteImageStart], R8
  ADD R12, 8

  MOV R8, [R12]
  MOV [SpriteConvert.SpriteNumImages],R8
  ADD R12, 8

  MOV RCX, OFFSET SpriteConvert
  DEBUG_FUNCTION_CALL GameEngine_ConvertImageToSprite

  MOV SPRITE_BASIC_INFORMATION.SpriteMaxFrames[RBX], 10
  ADD RBX, SIZE SPRITE_BASIC_INFORMATION
  INC RSI
  CMP RSI, NUMBER_OF_SPRITES
  JB @LoadNextSprite
  

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

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_INTRO
  MOV RAX, SPACE_INVADERS_STATE_INTRO
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_IntroScreen, _TEXT$00




;*********************************************************
;   Invaders_DisplayMenuText
;
;        Parameters: Master Context
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DisplayMenuText, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, OFFSET MenuText

  XOR R12, R12

@DisplayMenuText:
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  CMP R12, [MenuSelection]
  JNE @SkipColorChange
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FF0000h

@SkipColorChange:
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE

  MOV R8, QWORD PTR [RDI]
  ADD RDI, 8
  MOV R9, QWORD PTR [RDI]
  ADD RDI, 8

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
@FindEnd:
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNZ @FindEnd

  INC R12

  INC RDI
  CMP QWORD PTR [RDI], 0
  JNE @DisplayMenuText

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DisplayMenuText, _TEXT$00

;*********************************************************
;   Invaders_BoxIt
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_BoxIt, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  XOR R9, R9
  XOR R8, R8
  MOV RDX, OFFSET SpInvaders
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 144
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 89
  MOV R9, 47
  MOV R8, 26
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 159
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 167
  MOV R9, 31
  MOV R8, 103
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 159
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 167+86
  MOV R9, 31
  MOV R8, 103+86
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 150
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 490
  MOV R9, 54
  MOV R8, 426
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 150
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 490+82
  MOV R9, 54
  MOV R8, 426+82
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84
  MOV R9, 284
  MOV R8, 53
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51
  MOV R9, 284
  MOV R8, 53+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51
  MOV R9, 284
  MOV R8, 53+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51-3
  MOV R9, 284
  MOV R8, 53+51+51+51+51-3
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51-2
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51-7
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51+51-4
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51+51-4
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 319
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 84+51+51+51+51+51+51+51+51+51-3
  MOV R9, 284
  MOV R8, 53+51+51+51+51+51+51+51+51+51-4
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 150-1
  MOV R9, 420-31
  MOV R8, 115-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 201-1
  MOV R9, 420-31
  MOV R8, 164-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 454-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 247-1
  MOV R9, 420-31
  MOV R8, 213-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66-1
  MOV R9, 369-31
  MOV R8, 37-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox


  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50-1
  MOV R9, 369-31
  MOV R8, 37+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP],66 +50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox

  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 401-31
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 66+50+50+50+50+50+50+50+50+50+50-1
  MOV R9, 369-31
  MOV R8, 37+50+50+50+50+50+50+50+50+50+50-1
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DrawBox



  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RAX, SPACE_INVADERS_STATE_MENU

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_BoxIt, _TEXT$00


;*********************************************************
;   Invaders_DrawBox
;   Not used in the game, this is the herlp function to split the
;   sprites up from a single image.
;        Parameters: Master Context, Double Buffer X, Y, X2, Y2
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_DrawBox, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP], R8     ; X
  MOV STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP], R9     ; Y

  ;
  ; X, Y to X2, Y
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  ;
  ; X, Y to X, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine

  ;
  ; X, Y2 to X2, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param3[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine


  ;
  ; X2, Y to X2, Y2
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RDI
  MOV R10, OFFSET Invaders_PlotPixel
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R10
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param6[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV R9, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV R8, STD_FUNCTION_STACK_PARAMS.FuncParams.Param4[RSP]
  MOV RDX, STD_FUNCTION_STACK_PARAMS.FuncParams.Param5[RSP]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Prm_DrawLine
 

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_DrawBox, _TEXT$00

;*********************************************************
;   Invaders_PlotPixel
;
;        Parameters: X, Y, Context, Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_PlotPixel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, R9
  MOV RDI, R8

  XOR RAX, RAX
  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  JA @OffScreen
  CMP RDX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  JA @OffScreen
  
  MOV RAX, RDX
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2
  SHL RCX, 2
  ADD RAX, RCX
  MOV DWORD PTR [RDI + RAX], 0FFFFFFh
  
  MOV EAX, 1
@OffScreen:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_PlotPixel, _TEXT$00

;*********************************************************
;   Invaders_MenuScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_MenuScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET SpTitle
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Invaders_DisplayMenuText

  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RAX, SPACE_INVADERS_STATE_MENU

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_MenuScreen, _TEXT$00




;*********************************************************
;   Invaders_SpriteTest
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY Invaders_SpriteTest, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  
  MOV R9, 100
  MOV R8, 100
  MOV RDX, [SpritePointer]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite



  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 4
  MOV R9, 500
  MOV R8, 500
  

  MOV RDX, [SpritePointer]
  MOV RAX, SPRITE_BASIC_INFORMATION.CurrentSprite[RDX]
  ADD RAX, 'A'
  MOV RDX, OFFSET LoadingString
  MOV [RDX], AL
  MOV BYTE PTR [RDX+1], 0

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV [SpaceCurrentState], SPACE_INVADERS_STATE_MENU
  MOV RAX, SPACE_INVADERS_STATE_MENU

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_SpriteTest, _TEXT$00


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
;   Invaders_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY Invaders_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifResourceType         ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA

  MOV RDX, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Invaders_LoadGifResource, _TEXT$00







END