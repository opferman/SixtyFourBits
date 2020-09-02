;*********************************************************
; The Great Machine Game - Game Reset Functions
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
; Game Reset Functions
;***************************************************************************************************************************************************************************




;*********************************************************
;   GreatMachine_ResetGame
;                This will reset the game for level 1.
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetGame, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Setup Game Level information
  ;
  CMP [GameModeSelect], 1
  JAE @MediumOrHard
  MOV RAX, OFFSET LevelInformationEasy  
  JMP @GameModeSelectionComplete
@MediumOrHard:
  CMP [GameModeSelect], 1
  JA @HardMode  
  MOV RAX, OFFSET LevelInformationMedium
  JMP @GameModeSelectionComplete
@HardMode:  
  MOV RAX, OFFSET LevelInformationHard
  
  ;
  ; Refresh Game Level Data
  ;
@GameModeSelectionComplete:
  MOV [LevelInformationPtr], RAX
  MOV RCX, LEVEL_INFORMATION.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelStartDelay[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.LevelTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelTimer[RAX], RCX

  MOV LEVEL_INFORMATION.TimerAfterCarsLeave[RAX], 0

  MOV RCX, LEVEL_INFORMATION.TimerBetweenConcurrentRefresh[RAX]
  MOV LEVEL_INFORMATION.TimerBetweenConcurrent[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.PesdestrianTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.PesdestrianTimer[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentLevelBarrelCount[RAX], 0

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentBarrelCountL0[RAX], 0
  MOV LEVEL_INFORMATION.CurrentBarrelCountL1[RAX], 0

  MOV LEVEL_INFORMATION.CurrentCarPartCount[RAX], 0

  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimer[RAX], RCX

  ;
  ; Reset Player
  ; 
  MOV [PlayerSprite.ImagePointer], 0
  MOV [PlayerSprite.ExplodePointer], 0
  MOV [PlayerSprite.SpriteAlive], 1
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [PlayerSprite.SpriteVelMaxX], PLAYER_START_MAX_VEL_X
  MOV [PlayerSprite.SpriteVelMaxY], PLAYER_START_MAX_VEL_Y
  MOV [PlayerSprite.SpriteWidth], PLAYER_X_DIM
  MOV [PlayerSprite.SpriteHeight], PLAYER_Y_DIM
  MOV [PlayerSprite.HitPoints], PLAYER_START_HP
  MOV [PlayerSprite.MaxHp], PLAYER_START_HP
  MOV [PlayerSprite.Damage], PLAYER_DAMAGE
  MOV [PlayerLives], PLAYER_START_LIVES     
  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1
  MOV [GamePanel], 1
  MOV [PlayerScore], 0

  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0

  MOV [LevelStartTimer], 0
  MOV [TimerAdjustMs], 0

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists

  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ResetGame, _TEXT$00



