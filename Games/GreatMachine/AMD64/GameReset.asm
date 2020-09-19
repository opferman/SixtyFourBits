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

  DEBUG_FUNCTION_CALL GreatMachine_SelectLevelMode

  MOV RDX, LEVEL_GAME_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevelInformation

  MOV RDX, PLAYER_GAME_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetPlayer

  MOV RDX, GLOBALS_GAME_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_SetupGameGlobals

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists

  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  MOV RDX, [GameMusicId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ResetGame, _TEXT$00


      
     


;*********************************************************
;   GreatMachine_SetupGameGlobals
;                This will reset the game for level 1.
;
;        Parameters: Master Context, GLOBALS_GAME_RESET      
;                                    GLOBALS_LEVEL_RESET     
;                                    GLOBALS_NEXT_LEVEL_RESET
;                                    GLOBALS_WRAP_AROUND     
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SetupGameGlobals, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  
  CMP RDX, GLOBALS_GAME_RESET
  JE @GameReset

  CMP RDX, GLOBALS_LEVEL_RESET
  JE @LevelReset

  CMP RDX, GLOBALS_NEXT_LEVEL_RESET
  JE @NextLevelReset

  CMP RDX, GLOBALS_WRAP_AROUND
  JE @LevelWrapAround

  INT 3 

@LevelWrapAround:
  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0
  MOV [LevelStartTimer], 0
  MOV [TimerAdjustMs], 0
  JMP @ResetComplete

@NextLevelReset:
  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0
  MOV [LevelStartTimer], 0
  MOV [TimerAdjustMs], 0
  JMP @ResetComplete

@LevelReset:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JMP @ResetComplete

@GameReset:
  MOV [GamePanel], 1
  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0
  MOV [LevelStartTimer], 0
  MOV [TimerAdjustMs], 0
  MOV [PauseGame], 0

@ResetComplete:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SetupGameGlobals, _TEXT$00



;*********************************************************
;   GreatMachine_SelectLevelMode
;                This will select the level data
;
;        Parameters: None
;                    
;                    
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SelectLevelMode, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
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

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SelectLevelMode, _TEXT$00



;*********************************************************
;   GreatMachine_ResetPlayer
;                This will reset the game for level 1.
;
;        Parameters: Master Context, PLAYER_GAME_RESET      
;                                    PLAYER_LEVEL_RESET     
;                                    PLAYER_NEXT_LEVEL_RESET
;                                    PLAYER_WRAP_AROUND     
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP RDX, PLAYER_GAME_RESET
  JE @GameReset

  CMP RDX, PLAYER_LEVEL_RESET
  JE @LevelReset

  CMP RDX, PLAYER_NEXT_LEVEL_RESET
  JE @NextLevelReset

  CMP RDX, PLAYER_WRAP_AROUND
  JE @WrapAround

  INT 3 ; Should never get here.

@WrapAround:
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0

  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1
  JMP @ResetComplete

@NextLevelReset:
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0

  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1
  JMP @ResetComplete

@LevelReset:
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1
  MOV [PlayerSprite.SpriteAlive], 1
  JMP @ResetComplete

@GameReset:
  ;
  ; Reset Player
  ; 
  MOV [PlayerSprite.SpriteAlive], 1
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [PlayerSprite.SpriteVelMaxX], PLAYER_START_MAX_VEL_X
  MOV [PlayerSprite.SpriteVelMaxY], PLAYER_START_MAX_VEL_Y
  MOV [PlayerLives], PLAYER_START_LIVES     
  MOV [NextPlayerRoadLane], 2
  MOV [CurrentPlayerRoadLane], 2
  MOV [PlayerScore], 0

@ResetComplete:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ResetPlayer, _TEXT$00



;*********************************************************
;   GreatMachine_ResetLevelInformation
;                This will reset the Level game for level 1.
;
;        Parameters: Master Context, LEVEL_GAME_RESET      
;                                    LEVEL_LEVEL_RESET     
;                                    LEVEL_NEXT_LEVEL_RESET
;                                    LEVEL_WRAP_AROUND     
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetLevelInformation, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, [LevelInformationPtr]


  CMP RDX, LEVEL_GAME_RESET
  JE @GameReset

  CMP RDX, LEVEL_LEVEL_RESET
  JE @LevelReset

  CMP RDX, LEVEL_NEXT_LEVEL_RESET
  JE @NextLevelReset

  CMP RDX, LEVEL_WRAP_AROUND
  JE @LevelWrapAround

  INT 3

@LevelWrapAround:

  JMP @GameReset

@LevelReset:
  CMP LEVEL_INFO.TimerForExtraLives[RAX], 0
  JNE @SkipUpdateOfItemTimer
  MOV RCX, LEVEL_INFO.TimerForExtraLivesRefresh[RAX]
  MOV LEVEL_INFO.TimerForExtraLives[RAX], RCX
@SkipUpdateOfItemTimer:

  MOV RCX, LEVEL_INFO.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFO.LevelStartDelay[RAX], RCX

  JMP @NewLevelAndInLevelCommonCode


@NextLevelReset:
  ;
  ; Update player score with remaining milliseconds
  ;
  MOV RCX, LEVEL_INFO.LevelTimer[RAX]
  ADD [PlayerScore], RCX
  ; Fall Through
@GameReset:
  ;
  ; Reset Current Level Stats
  ;
  MOV LEVEL_INFO.CurrentFuelCollection[RAX], 0   
  MOV LEVEL_INFO.CurrentPartOneCollection[RAX], 0       
  MOV LEVEL_INFO.CurrentPartTwoCollection[RAX], 0       
  MOV LEVEL_INFO.CurrentPartThreeCollection[RAX], 0    

  ;
  ; Reset New Level Common Code
  ;
@NewLevelCommonReset:  
  ;
  ; Reset Level Timers
  ;
  MOV RCX, LEVEL_INFO.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFO.LevelStartDelay[RAX], RCX
  MOV RCX, LEVEL_INFO.LevelTimerRefresh[RAX]
  MOV LEVEL_INFO.LevelTimer[RAX], RCX
  MOV RCX, LEVEL_INFO.TimerForExtraLivesRefresh[RAX]
  MOV LEVEL_INFO.TimerForExtraLives[RAX], RCX

@NewLevelAndInLevelCommonCode:
  MOV RSI, RAX

  MOV R8, LEVEL_INFO.GenerateCarsPercentage[RSI]
  MOV RDX, LEVEL_INFO.CarDebounceRefresh[RSI]
  MOV RCX, OFFSET GenerateCarsStructure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GenerateFuelPercentage[RSI]
  MOV RDX, LEVEL_INFO.FuelDebounceRefresh[RSI]
  MOV RCX, OFFSET GenerateFuelStructure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GenerateCarPartOnPercentage[RSI]
  MOV RDX, LEVEL_INFO.Parts1DebounceRefresh[RSI]
  MOV RCX, OFFSET GeneratePart1Structure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GenerateCarPartTwoPercentage[RSI]
  MOV RDX, LEVEL_INFO.Parts2DebounceRefresh[RSI]
  MOV RCX, OFFSET GeneratePart2Structure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GenerateCarPartThreePercentage[RSI]
  MOV RDX, LEVEL_INFO.Parts3DebounceRefresh[RSI]
  MOV RCX, OFFSET GeneratePart3Structure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GeneratePedestriansPercentage[RSI]
  MOV RDX, LEVEL_INFO.PedestrianDebounceRefresh[RSI]
  MOV RCX, OFFSET GeneratePedestriansStructure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

  MOV R8, LEVEL_INFO.GenerateExtraLifePercentage[RSI]
  MOV RDX, LEVEL_INFO.TimerForExtraLives[RSI]
  MOV RCX, OFFSET GenerateExtraLifeStructure
  DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite

 ; MOV R8, LEVEL_INFO.GenerateHazardsPercentage[RSI]
 ; MOV RDX, LEVEL_INFO.HazardDebounceRefresh[RSI]
 ; MOV RCX, OFFSET GenerateHazardsStructure
 ; DEBUG_FUNCTION_CALL GreatMachine_UpdateLevelSettingsToSprite


 ;
 ; Any level reset
 ;

  ;
  ; Set or Clear in-game timers
  ;
  MOV RCX, LEVEL_INFO.TimerBetweenConCurrentCarsRefresh[RAX]
  MOV LEVEL_INFO.TimerBetweenConCurrentCars[RAX], 0        
  MOV LEVEL_INFO.TimerAfterCarExitsScreen[RAX], 0          
  MOV LEVEL_INFO.TimerForPedestrians[RAX], 0               
  MOV LEVEL_INFO.TimerForFuel[RAX], 0                      
  MOV RCX, LEVEL_INFO.TimerForHazardRefresh[RAX]
  MOV LEVEL_INFO.TimerForHazard[RAX], RCX                    
  MOV RCX, LEVEL_INFO.TimerForParts1Refresh[RAX]
  MOV LEVEL_INFO.TimerForParts1[RAX], RCX       
  MOV RCX, LEVEL_INFO.TimerForParts2Refresh[RAX]             
  MOV LEVEL_INFO.TimerForParts2[RAX], RCX       
  MOV RCX, LEVEL_INFO.TimerForParts3Refresh[RAX]             
  MOV LEVEL_INFO.TimerForParts3[RAX], RCX                    
  MOV LEVEL_INFO.TimerForLane0ItemSelection[RAX], 0        
  MOV LEVEL_INFO.TimerForLane1ItemSelection[RAX], 0        
  MOV LEVEL_INFO.TimerForLane2ItemSelection[RAX], 0  
        
  ;
  ; Clear active sprites
  ;
  MOV LEVEL_INFO.CurrentNumberOfCars[RAX], 0            
  MOV LEVEL_INFO.CurrentNumberOfFuel[RAX], 0            
  MOV LEVEL_INFO.CurrentNumberOfPartOne[RAX], 0         
  MOV LEVEL_INFO.CurrentNumberOfPartTwo[RAX], 0         
  MOV LEVEL_INFO.CurrentNumberOfPartThree[RAX], 0         
  MOV LEVEL_INFO.CurrentNumberOfBlockers[RAX], 0 
  MOV LEVEL_INFO.BlockingItemCountLane0[RAX], 0 
  MOV LEVEL_INFO.BlockingItemCountLane1[RAX], 0 
  MOV LEVEL_INFO.BlockingItemCountLane2[RAX], 0 

@ResetComplete:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ResetLevelInformation, _TEXT$00



;*********************************************************
;   GreatMachine_UpdateLevelSettingsToSprite
;
;        Parameters: Generation Structure, DeBounce Number, Percentage Number
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateLevelSettingsToSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R15, RCX
  MOV RSI, GENERATE_STRUCT.ItemListPtr[R15]

@UpdateSpritesLoop:
  CMP RBX, GENERATE_STRUCT.NumberOfItemsOnList[R15]
  JE @CompletedList

  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI], RDX
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RDX
  MOV SPECIAL_SPRITE_STRUCT.SpriteGenerationPercent[RSI], R8
  
  ADD RSI, SIZE SPECIAL_SPRITE_STRUCT
  INC RBX
  JMP @UpdateSpritesLoop
@CompletedList:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_UpdateLevelSettingsToSprite, _TEXT$00
