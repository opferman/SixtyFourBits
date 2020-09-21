;*********************************************************
; The Great Machine Game - Game Screens for the Menu, Menu Options and Start Up.
;
;  Written in Assembly x64
; 
;  By Toby Opferman  8/28/2020
;
;     AKA ChecksumError on Youtube
;     AKA BinaryBomb on Discord
;
;*********************************************************

;***************************************************************************************************************************************************************************
; Non-Level Screens
;***************************************************************************************************************************************************************************


;*********************************************************
;   GreatMachine_Loading
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value:State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Loading, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV RAX, GREAT_MACHINE_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Loading, _TEXT$00



;*********************************************************
;   GreatMachine_IntroScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_IntroScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
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

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RAX, GREAT_MACHINE_STATE_INTRO
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_IntroScreen, _TEXT$00



;*********************************************************
;   GreatMachine_Credits
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Credits, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_CREDITS
  MOV R12, OFFSET CreditsText1
  CMP [CreditsPage], 0
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText2
  CMP [CreditsPage], 1
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText3
  CMP [CreditsPage], 2
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText4
  CMP [CreditsPage], 3
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText5
  CMP [CreditsPage], 4
  JE @DisplayCreditsPage
  
  MOV [CreditsPage], 0
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JMP @GoToMenu


@DisplayCreditsPage:

  MOV RDX, OFFSET GeneralGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, 20
  MOV RDX, R12
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], CREDITS_FONT_SIZE
  MOV R9, INTRO_Y + 40
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  JMP @CompleteDisplayingPage


@CompleteDisplayingPage:
@GoToMenu:  
@ScreenDrawComplete:
  MOV RAX, [GreatMachineCurrentState] 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Credits, _TEXT$00



;*********************************************************
;   GreatMachine_AboutScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AboutScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, 20
  MOV RDX, OFFSET AboutText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y + 40
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ABOUT
  MOV RAX, GREAT_MACHINE_STATE_ABOUT
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_AboutScreen, _TEXT$00



;*********************************************************
;   GreatMachine_OptionsScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_OptionsScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, [GameModeSelect]
  MOV RDX, OFFSET ModeSelectText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_OptionsScreen, _TEXT$00



;*********************************************************
;   GreatMachine_MenuScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_MenuScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, [MenuSelection]
  MOV RDX, OFFSET MenuText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU

  INC [MenuIntroTimer]
  MOV RAX, [MenuIntroTimer]
  CMP RAX, MENU_MAX_TIMEOUT
  JB @KeepOnMenu

  MOV [MenuIntroTimer], 0
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  
@KeepOnMenu:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_MenuScreen, _TEXT$00


;*********************************************************
;   GreatMachine_GamePlayScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GamePlayScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage
  
  MOV [GreatMachineCurrentState], GREAT_MACHINE_GAMEPLAY
  
  CMP [GamePlayPage], 0
  JE @GamePlayPageOne
  CMP [GamePlayPage], 1
  JE @GamePlayPageTwo
  CMP [GamePlayPage], 2
  JE @GamePlayPageThree
  CMP [GamePlayPage], 3
  JE @GamePlayPageFour
  
  MOV [GamePlayPage], 0
  
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JMP @GoToMenu
  
@GamePlayPageOne:
  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextOne
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

JMP @ScreenDrawComplete

@GamePlayPageTwo:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextTwo
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  JMP @ScreenDrawComplete
@GamePlayPageThree:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextThree
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText
  JMP @ScreenDrawComplete
@GamePlayPageFour:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextFour
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

@GoToMenu:  
@ScreenDrawComplete:
  MOV RAX, [GreatMachineCurrentState] 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GamePlayScreen, _TEXT$00

