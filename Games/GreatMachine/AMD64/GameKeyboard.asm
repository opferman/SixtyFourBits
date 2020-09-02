;*********************************************************
; The Great Machine Game - Keyboard Handlers
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
; Key Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_SpacePress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SpacePress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SpacePress, _TEXT$00



;*********************************************************
;   GreatMachine_P_Press
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_P_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  XOR [GamePanel], 1

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_P_Press, _TEXT$00

;*********************************************************
;   GreatMachine_H_Press (Hold)
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_H_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  XOR [PauseGame], 1

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_H_Press, _TEXT$00

;*********************************************************
;   GreatMachine_SpaceBar
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SpaceBar, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState],GREAT_MACHINE_GAMEPLAY
  JNE @TryNextItem
  
  INC [GamePlayPage]
  
@TryNextItem:   
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_CREDITS
  JE @CreditsPage
   
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions

  CMP [GreatMachineCurrentState], GREAT_MACHINE_HISCORE
  JE @GoToMenu
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ABOUT
  JE @GoToMenu
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  JNE @CheckOtherState

@GoToMenu:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  MOV RCX, GREAT_MACHINE_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@GoToIntro:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @NotOnMenu
  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL GreatMachine_ResetGame

  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

@NotOnMenu:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JNE @NotHighScore

  INC QWORD PTR [InitialsEnterPtr]
  MOV RAX, [InitialsEnterPtr]
  MOV AL, BYTE PTR [RAX]

  CMP AL, 0
  JNE @NotDoneEnteringYet

  ;
  ; Done entering high score, Update Hi Score File
  ; and go to Intro.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_UpdateHighScore
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  JMP @DoneWithEnteringScore
@NotDoneEnteringYet:
  MOV RAX, [InitialsEnterPtr]
  MOV BYTE PTR [RAX], 'A'
@NotHighScore:
@DoneWithEnteringScore:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  MOV RCX, GREAT_MACHINE_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@CreditsPage:
  INC [CreditsPage]
  MOV RAX, GREAT_MACHINE_STATE_CREDITS
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SpaceBar, _TEXT$00


;*********************************************************
;   GreatMachine_Enter
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Enter, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  JE @WinnerScreen

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL GreatMachine_ResetGame
  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:
  MOV RCX, GREAT_MACHINE_STATE_MENU
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
@CheckOtherState:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
  JNE @NotOnEndGame
  
  ;
  ;  Let's reset the level here to remove the active list.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevel

  CMP [HiScoreLocationPtr], 0
  JE @GoToIntro
   
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  MOV RCX, GREAT_MACHINE_STATE_ENTER_HI_SCORE
  DEBUG_FUNCTION_CALL GameEngine_ChangeState  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GoToIntro:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@NotOnEndGame:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@WinnerScreen:

  CMP [GameModeSelect], 1
  JAE @MediumOrHard
  ;MOV RCX, OFFSET EasyLevel1
  JMP @LevelResetComplete
@MediumOrHard:
  CMP [GameModeSelect], 1
  JA @HardMode  
  ;MOV RCX, OFFSET MediumLevel1
  JMP @LevelResetComplete
@HardMode:  
  ;MOV RCX, OFFSET HardLevel1
@LevelResetComplete:

  ;MOV [CurrentLevelInformationPtr], RCX

  DEBUG_FUNCTION_CALL GreatMachine_ResetLevel

  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  MOV RCX, GREAT_MACHINE_LEVELS
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Enter, _TEXT$00


;*********************************************************
;   GreatMachine_LeftArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LeftArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  ;DEC [DeBounceMovement]       ; TBD if we want to implement debounce
  ;CMP [DeBounceMovement], 0
  ;JGE @SkipUpate
  ;MOV [DeBounceMovement], MOVEMENT_DEBOUNCE

  MOV RAX, [PlayerSprite.SpriteVelMaxX]
  NEG RAX
  MOV [PlayerSprite.SpriteVelX], RAX
@SkipAdjustment:
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LeftArrowPress, _TEXT$00





;*********************************************************
;   GreatMachine_RightArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RightArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  ;DEC [DeBounceMovement]       ; TBD if we want to implement debounce
  ;CMP [DeBounceMovement], 0
  ;JGE @SkipUpate
  ;MOV [DeBounceMovement], MOVEMENT_DEBOUNCE

  MOV RAX, [PlayerSprite.SpriteVelMaxX]
  MOV [PlayerSprite.SpriteVelX], RAX

@SkipAdjustment:
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RightArrowPress, _TEXT$00

;*********************************************************
;   GreatMachine_LeftArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LeftArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead
  MOV [PlayerSprite.SpriteVelX], 0
  ; MOV [DeBounceMovement], 0
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LeftArrow, _TEXT$00




;*********************************************************
;   GreatMachine_RightArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RightArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  MOV [PlayerSprite.SpriteVelX], 0
; MOV [DeBounceMovement], 0
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RightArrow, _TEXT$00






;*********************************************************
;   GreatMachine_DownArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DownArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead
  
  MOV [NextPlayerRoadLane], 1  

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@UpdateHighScore:

  MOV AL, 1
  DEBUG_FUNCTION_CALL GreatMachine_HiScoreEnterUpdate
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DownArrowPress, _TEXT$00






;*********************************************************
;   GreatMachine_UpArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  MOV [NextPlayerRoadLane], 0

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@UpdateHighScore:

  MOV AL, -1
  DEBUG_FUNCTION_CALL GreatMachine_HiScoreEnterUpdate  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_UpArrowPress, _TEXT$00




;*********************************************************
;   GreatMachine_DownArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DownArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @OptionsMenu

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState
  MOV [MenuIntroTimer], 0
  INC QWORD PTR [MenuSelection]
  
  CMP QWORD PTR [MenuSelection], MAX_MENU_SELECTION
  JB @NoResetToStart
  MOV [MenuSelection], 0

@NoResetToStart:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@OptionsMenu:
  INC QWORD PTR [GameModeSelect]
  
  CMP QWORD PTR [GameModeSelect], MAX_GAME_OPTIONS
  JB @NoResetToStart
  MOV [GameModeSelect], 0  
@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DownArrow, _TEXT$00


;*********************************************************
;   GreatMachine_UpArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  CMP QWORD PTR [MenuSelection], 0
  JA @Decrement
  MOV [MenuSelection], MAX_MENU_SELECTION
@Decrement:
  DEC QWORD PTR [MenuSelection]
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:  
  CMP QWORD PTR [GameModeSelect], 0 
  JA @PerformSelectionDecrement  
  MOV [GameModeSelect], MAX_GAME_OPTIONS
@PerformSelectionDecrement:
  DEC [GameModeSelect]
  
@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_UpArrow, _TEXT$00
