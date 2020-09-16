;*********************************************************
; The Great Machine Game - Game Levels Implementation
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
; Levels
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_Levels
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Levels, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_AnimateBackground

  MOV RAX, [LevelInformationPtr]
  CMP LEVEL_INFO.LevelStartDelay[RAX], 0
  JE @LevelPlay

  MOV R9, LEVEL_NAME_Y 
  MOV R8, LEVEL_NAME_X
  MOV RDX, OFFSET LevelNameGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, LEVEL_NUMBER_Y
  MOV R8, LEVEL_NUMBER_X
  MOV RAX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFO.LevelNumberGraphic[RAX]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV RAX, [LevelInformationPtr]
  DEC LEVEL_INFO.LevelStartDelay[RAX]
  JMP @LevelDelay

@LevelPlay:
  CMP [LevelStartTimer], 0
  JNE @LevelTimerRunningUpdate
  DEBUG_FUNCTION_CALL GameEngine_StartTimerValue
  MOV [LevelStartTimer], RAX
  JMP @SkipTimerUpdate
@LevelTimerRunningUpdate:
  DEBUG_FUNCTION_CALL GreatMachine_UpdateTimer
@SkipTimerUpdate:
  MOV R12D, [CurrentPlayerRoadLane]
  MOV EAX, [NextPlayerRoadLane]
  CMP R12, RAX
  JE @NotBetweenLanes
  TEST EAX, EAX
  JZ @UseLane1
  TEST R12, R12
  JZ @UseLane1
@UseLane2:
  MOV R12, 2                    ; Signal we are between lanes.
  JMP @DeterminedPlayerLane
@UseLane1:
  MOV R12, 1
@NotBetweenLanes:
@DeterminedPlayerLane:

  ;**************************************************************
  ; Level Action - Section One - New Game Pieces
  ;**************************************************************

  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DispatchGamePieces
   
ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

  ;**************************************************************
  ; Level Action - Section Two - Detection
  ;**************************************************************

  MOV R8, [PlayerLanePtr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionPlayer


ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

  MOV R8, OFFSET Lane0Ptr
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC
ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

  MOV R8, OFFSET Lane1Ptr
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC
ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

  MOV R8, OFFSET Lane2Ptr
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC
ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif


  ;**************************************************************
  ; Level Action - Section Three - Display Graphics and Sprites
  ;**************************************************************

  ;
  ; Top Sidewalk First
  ;

   MOV R8, [TopSideWalkPtr]
   MOV RDX, RBX
   MOV RCX, RSI
   DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  ;
  ; Lane 0
  ;
  CMP R12, 0
  JNE @SkipPlayerUpdateForLane0
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForLane0:

  MOV R8, [Lane0Ptr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  ;
  ; Lane 1 or Between L1 and L0
  ;
  CMP R12, 1
  JNE @SkipPlayerUpdateForLane1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForLane1:

  MOV R8, [Lane1Ptr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  ;
  ; Lane 2 or Between L1 and L2
  ;
  CMP R12, 2
  JNE @SkipPlayerUpdateForBetweenLane2
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForBetweenLane2:

  MOV R8, [Lane2Ptr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  ;
  ; Bottom Sidewalk
  ;
  MOV R8, [BottomSideWalkPtr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPoints

  CMP [BoomTimerActive], 0
  JE @BoomNotActive
  MOV [PlayerSprite.SpriteAlive], 0

  DEC [PlayerLives]
  CMP [PlayerLives], 0
  JNE @DoNotUpdateState

@UpdateState:
  DEBUG_FUNCTION_CALL GreatMachine_CheckHiScores
  MOV [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
@DoNotUpdateState:

  MOV R9, [BoomYLocation] 
  MOV R8, [BoomXLocation]
  MOV RDX, OFFSET BoomGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage



  ;
  ; Display the Game Panel
  ;
  MOV RDX, [LevelInformationPtr] 
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayGamePanel


  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenCapture
  ;
  ; We need to adjust the timer so this dead time isn't counted towards the level.
  ;
  MOV RCX, [LevelInformationPtr]
  MOV RAX, LEVEL_INFO.LevelTimerRefresh[RCX]
  SUB RAX, LEVEL_INFO.LevelTimer[RCX]
  MOV [TimerAdjustMs], RAX
  MOV [LevelStartTimer], 0
  JMP @SkipPanelUpdate

@BoomNotActive:
  MOV RDX, [LevelInformationPtr] 
  CMP LEVEL_INFO.LevelTimer[RDX], 0
  JNE @StillTimeLeft
  MOV [BoomYLocation], 0
  MOV [BoomXLocation], 0
  JMP @UpdateState
@StillTimeLeft:
  
  ;
  ; Check if we have completed the 
  ;
  MOV R9, LEVEL_INFO.RequiredFuelCollection[RDX]
  MOV R8, LEVEL_INFO.CurrentFuelCollection[RDX]
  CMP R9, R8
  JNE @NotComplete

  MOV R9, LEVEL_INFO.RequiredPartOneCollection[RDX]
  MOV R8, LEVEL_INFO.CurrentPartOneCollection[RDX]
  CMP R9, R8
  JNE @NotComplete

  MOV R9, LEVEL_INFO.RequiredPartTwoCollection[RDX]
  MOV R8, LEVEL_INFO.CurrentPartTwoCollection[RDX]
  CMP R9, R8
  JNE @NotComplete

  MOV R9, LEVEL_INFO.RequiredPartThreeCollection[RDX]
  MOV R8, LEVEL_INFO.CurrentPartThreeCollection[RDX]
  CMP R9, R8
  JNE @NotComplete

  MOV RAX, LEVEL_INFO.pfnNextLevel[RDX]

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL RAX

@NotComplete:      
  ;
  ; Display the Game Panel
  ;
  MOV RDX, [LevelInformationPtr] 
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayGamePanel

  CMP [PauseGame], 0
  JE @NoPauseorHold

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenCapture
  ;
  ; We need to adjust the timer so this pause time isn't counted towards the level.
  ;
  MOV RCX, [LevelInformationPtr]
  MOV RAX, LEVEL_INFO.LevelTimerRefresh[RCX]
  SUB RAX, LEVEL_INFO.LevelTimer[RCX]
  MOV [TimerAdjustMs], RAX
  MOV [LevelStartTimer], 0
        
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_PAUSE

@NoPauseorHold:
@LevelDelay:
@SkipPanelUpdate:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Levels, _TEXT$00


