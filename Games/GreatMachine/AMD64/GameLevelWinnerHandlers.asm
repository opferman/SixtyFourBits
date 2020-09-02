;*********************************************************
; The Great Machine Game - Handle Level Reset and Winning and Loosing
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
; Level Resets, Winning and Loosing handlers
;***************************************************************************************************************************************************************************



;*********************************************************
;   GreatMachine_GameOver
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GameOver, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], GAME_OVER_SIZE
  MOV R9, GAME_OVER_Y
  MOV R8, GAME_OVER_X
  MOV RDX, OFFSET GameOverText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
  MOV RAX, GREAT_MACHINE_END_GAME
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GameOver, _TEXT$00

;*********************************************************
;   GreatMachine_Winner
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Winner, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX


 ; DEBUG_FUNCTION_CALL GreatMachine_DisplayWinnerAnimation
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], WINNER_SIZE
  MOV R9, WINNER_Y
  MOV R8, WINNER_X
  MOV RDX, OFFSET WinnerText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  MOV RAX, GREAT_MACHINE_STATE_WINSCREEN
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Winner, _TEXT$00



;*********************************************************
;   GreatMachine_ResetLevel
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, [LevelInformationPtr]
  MOV RCX, LEVEL_INFORMATION.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelStartDelay[RAX], RCX
  MOV LEVEL_INFORMATION.CurrrentNumberOfCars[RAX], 0
  MOV LEVEL_INFORMATION.TimerAfterCarsLeave[RAX], 0
  MOV RCX, LEVEL_INFORMATION.TimerBetweenConcurrentRefresh[RAX]
  MOV LEVEL_INFORMATION.TimerBetweenConcurrent[RAX], RCX
  MOV RCX, LEVEL_INFORMATION.PesdestrianTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.PesdestrianTimer[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL0[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL1[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentBarrelCountL0[RAX], 0
  MOV LEVEL_INFORMATION.CurrentBarrelCountL1[RAX], 0
  MOV LEVEL_INFORMATION.CurrentCarPartCountL0[RAX], 0
  MOV LEVEL_INFORMATION.CurrentCarPartCountL1[RAX], 0

  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL0[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL0[RAX], RCX
  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL1[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL1[RAX], RCX

  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0

  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1

  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS

  MOV [PlayerSprite.SpriteAlive], 1

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists

  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ResetLevel, _TEXT$00

;*********************************************************
;   GreatMachine_NextLevel
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, [LevelInformationPtr]
  ADD RAX, SIZE LEVEL_INFORMATION
  MOV [LevelInformationPtr], RAX

  MOV RCX, LEVEL_INFORMATION.LevelTimer[RAX]
  ADD [PlayerScore], RCX

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

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL0[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL1[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentBarrelCountL0[RAX], 0
  MOV LEVEL_INFORMATION.CurrentBarrelCountL1[RAX], 0
  MOV LEVEL_INFORMATION.CurrentCarPartCount[RAX], 0

  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL0[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL0[RAX], RCX
  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL1[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL1[RAX], RCX

  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0

  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1

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

NESTED_END GreatMachine_NextLevel, _TEXT$00



;*********************************************************
;   GreatMachine_NextLevel_Win
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel_Win, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel_Win, _TEXT$00



;*********************************************************
;   GreatMachine_Boom
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Boom, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  DEC [BoomTimer]

  CMP [BoomTimer], 0
  JA @KeepBooming
  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0
  MOV RAX, [LevelInformationPtr]
  MOV RAX, LEVEL_INFORMATION.pfnLevelReset[RAX]
  DEBUG_FUNCTION_CALL RAX
@GameOver:
@KeepBooming:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Boom, _TEXT$00
