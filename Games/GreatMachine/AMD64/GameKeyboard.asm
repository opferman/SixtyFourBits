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
;   GreatMachine_M_Press (Toggle Music}
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_M_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_TogglePauseMusic

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_M_Press, _TEXT$00


;*********************************************************
;   GreatMachine_VolumeDown_Press (Toggle Music}
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_VolumeDown_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [AudioVolume], 0
  JE @NoMoreDown
  SUB [AudioVolume], 5

  MOV RDX, [AudioVolume]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_SetVolume
@NoMoreDown:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_VolumeDown_Press, _TEXT$00


;*********************************************************
;   GreatMachine_VolumeUp_Press (Toggle Music}
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_VolumeUp_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  CMP [AudioVolume], 1000
  JE @NoMoreUp
  ADD [AudioVolume], 5

  MOV RDX, [AudioVolume]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_SetVolume
@NoMoreUp:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_VolumeUp_Press, _TEXT$00

;*********************************************************
;   GreatMachine_E_Press (Toggle Effect}
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_E_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_TogglePauseEffects

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_E_Press, _TEXT$00

ifdef MACHINE_GAME_DEBUG

;*********************************************************
;   GreatMachine_D_Press (Debug)
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_D_Press, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  INT 3

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_D_Press, _TEXT$00

endif

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
  MOV RSI, RCX
  
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
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JNE @NotOnMenu

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetGame

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
  MOV RSI, RCX

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  JE @WinnerScreen

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0


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

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JNE @SkipGameReset

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetGame

@SkipGameReset:
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

  DEBUG_FUNCTION_CALL GreatMachine_ResetLevelToOne

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
  
  MOV EAX, [NextPlayerRoadLane]
  CMP EAX, [CurrentPlayerRoadLane]
  JNE @AlreadyInProgress
  
  CMP [CurrentPlayerRoadLane], 2
  JE @AlreadyAtLowestLane

  MOV [MovingLanesDown], 1
  INC [NextPlayerRoadLane]

@AlreadyAtLowestLane:
@AlreadyInProgress:
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

  MOV EAX, [NextPlayerRoadLane]
  CMP EAX, [CurrentPlayerRoadLane]
  JNE @AlreadyInProgress
  
  CMP [CurrentPlayerRoadLane], 0
  JE @AlreadyAtLowestLane

  MOV [MovingLanesDown], 0
  DEC [NextPlayerRoadLane]
  
@AlreadyAtLowestLane:
@AlreadyInProgress:
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
