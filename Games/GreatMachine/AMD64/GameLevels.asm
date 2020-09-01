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
  CMP LEVEL_INFORMATION.LevelStartDelay[RAX], 0
  JE @LevelPlay

  MOV R9, LEVEL_NAME_Y 
  MOV R8, LEVEL_NAME_X
  MOV RDX, OFFSET LevelNameGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, LEVEL_NUMBER_Y
  MOV R8, LEVEL_NUMBER_X
  MOV RAX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFORMATION.LevelNumberGraphic[RAX]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV RAX, [LevelInformationPtr]
  DEC LEVEL_INFORMATION.LevelStartDelay[RAX]
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
  MOV R12, 3                    ; Signal we are between lanes.
@NotBetweenLanes:

  ;**************************************************************
  ; Level Action - Section One - New Game Pieces
  ;**************************************************************

  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DispatchGamePieces 

  ;**************************************************************
  ; Level Action - Section Two - Detection
  ;**************************************************************
  XOR R8, R8
  CMP R12, 3
  JE @NotInALane
  MOV R8, [LaneZeroPtr] 
  CMP R12, 0
  JE @InLaneZero
  MOV R8, [LaneOnePtr]
@InLaneZero:
@NotInALane:
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionPlayer

  MOV R8, [LaneZeroPtr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC

  MOV R8, [LaneOnePtr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC

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

  MOV R8, [LaneZeroPtr]
  MOV RDX, RBX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayLevelSprites

  ;
  ; Character transition between lanes
  ;
  CMP R12, 3
  JNE @SkipPlayerUpdateForBetweenLanes
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForBetweenLanes:

  ;
  ; Lane 1
  ;
  CMP R12, 1
  JNE @SkipPlayerUpdateForLane1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForLane1:

  MOV R8, [LaneOnePtr]
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

  CMP [BoomTimerActive], 0
  JE @BoomNotActive
  MOV [PlayerSprite.SpriteAlive], 0

  DEC [PlayerLives]
  CMP [PlayerLives], 0
  JNE @DoNotUpdateState
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
  MOV RAX, LEVEL_INFORMATION.LevelTimerRefresh[RCX]
  SUB RAX, LEVEL_INFORMATION.LevelTimer[RCX]
  MOV [TimerAdjustMs], RAX
  MOV [LevelStartTimer], 0
  JMP @SkipPanelUpdate

@BoomNotActive:

  ;
  ; Display the Game Panel
  ;
  MOV RDX, [LevelInformationPtr] 
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayGamePanel

@LevelDelay:
@SkipPanelUpdate:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Levels, _TEXT$00


