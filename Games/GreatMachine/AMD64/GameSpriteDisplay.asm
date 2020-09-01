;*********************************************************
; The Great Machine Game - Display Game Sprites
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
; Display Graphics Functions
;***************************************************************************************************************************************************************************



;*********************************************************
;   GreatMachine_DisplayLevelSprites
;
;        Parameters: Master Context, Double Buffer, Sprite Linked List
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayLevelSprites, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RBX, RCX
  MOV RSI, R8

@DrawAllScrollingSprites:
  CMP RSI, 0
  JE @NothingToDraw

  MOV RDX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV RCX, RBX
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingSprite
  CMP RAX, 0
  JE @DeactivateSprite
  
  MOV RSI, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  JMP @DrawAllScrollingSprites
@DeactivateSprite:
  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 0
  CMP SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  JE @NothingInFront
  ; Fix up next on list to point to before.
  
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX], RCX

@NothingInFront:
  CMP SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  JE @OnHeadOfList
  
  ;
  ; Fix up before pointer and advance to next on the list.
  ;
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RAX], RCX
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RAX
  MOV RSI, RCX

  MOV RCX, [LevelInformationPtr]
  
  MOV RAX, LEVEL_INFORMATION.TimerAfterCarsLeaveRefresh[RCX]
  MOV LEVEL_INFORMATION.TimerAfterCarsLeave[RCX], RAX
  DEC LEVEL_INFORMATION.CurrrentNumberOfCars[RCX]

  JMP @DrawAllScrollingSprites

@OnHeadOfList:
  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI]
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV QWORD PTR [RCX], RAX

  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RCX
  MOV RSI, RAX

  MOV RCX, [LevelInformationPtr]
  
  MOV RAX, LEVEL_INFORMATION.TimerAfterCarsLeaveRefresh[RCX]
  MOV LEVEL_INFORMATION.TimerAfterCarsLeave[RCX], RAX
  DEC LEVEL_INFORMATION.CurrrentNumberOfCars[RCX]

  JMP @DrawAllScrollingSprites
@NothingToDraw:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DisplayLevelSprites, _TEXT$00



;*********************************************************
;   GreatMachine_DisplayPlayer
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  CMP [PlayerSprite.SpriteAlive], 0
  JE @SpriteIsDead

  CMP [PlayerSprite.SpriteVelX], 0
  JE @SkipUpdateOfX
  MOV RAX, [PlayerSprite.SpriteVelX]
  ADD [PlayerSprite.SpriteX], RAX
  CMP [PlayerSprite.SpriteX], 0
  JGE @TestOtherEnd
  MOV [PlayerSprite.SpriteX], 0
  JMP @DoneUpdatingX
@TestOtherEnd:
  MOV RAX, [PlayerSprite.SpriteX]
  ADD RAX, PLAYER_CAR_LENGTH
  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JB @DoneUpdatingX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC RAX
  SUB RAX, PLAYER_CAR_LENGTH
  MOV [PlayerSprite.SpriteX], RAX
@DoneUpdatingX:
@SkipUpdateOfX:
  MOV EAX, [NextPlayerRoadLane]
  CMP [CurrentPlayerRoadLane], EAX
  JE @SkipPlayerMovementToNewLane
  CMP EAX, 1
  JE @MoveDown
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  NEG RAX
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_0
  JA @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 0
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_0
  JMP @DoneUpdatingMovement
@MoveDown:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_1
  JB @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 1
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
  JMP @DoneUpdatingMovement
@SkipPlayerMovementToNewLane:
  ;
  ; Unfortunately, we need to do this quick fix up rather than add more complicated
  ; code to deal with someone pressing both up and down at the same time and getting the
  ; car stuck in the middle of the road.
  ;
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_0
  CMP [CurrentPlayerRoadLane], 0
  JE @DoneUpdatingMovement
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
@DoneUpdatingMovement:

  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [CurrentPlayerSprite]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  

@SpriteIsDead:
  XOR RAX, RAX
@ExitDisplayPlayer:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DisplayPlayer, _TEXT$00








;*********************************************************
;   GreatMachine_DisplayGamePanel
;
;        Parameters: Master Context, Level Info
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayGamePanel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  ;
  ; Display The Current Score
  ;
  
  MOV R8, [PlayerScore]
  MOV RDX, OFFSET PlayerScoreFormat
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SCORE_FONT_SIZE      ; Font Size
  MOV R9, 5
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHR R8, 1
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RCX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFORMATION.LevelTimer[RCX]    ; Milliseconds
  XOR R9, R9                   ; Seconds
  XOR R8, R8                   ; Minutes 
                               
@ConvertToMinutes:
  CMP RDX, 60000
  JB @CheckRoundTo1Second
  SUB RDX, 60000
  INC R8
  JMP @ConvertToMinutes

@CheckRoundTo1Second:
  CMP RDX, (60000 - 1000)
  JB @ConvertToSeconds
  INC R8
  JMP @DisplayTime
@ConvertToSeconds:
  CMP RDX, 0
  JE @DisplayTime
  CMP RDX, 1000
  JB @RoundUpTo1Second
  SUB RDX, 1000
  INC R9
  JMP @ConvertToSeconds



  ;
  ; Display The Current Time Count Down
  ;
@RoundUpTo1Second:
  INC R9
@DisplayTime:
  MOV RDX, OFFSET PlayerTimerFormat
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE    ; Font Size
  MOV R9, 2
  MOV R8, 2
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord




  ;
  ; Now display side panel
  ;
  CMP [GamePanel], 0
  JE @PanelIsOff

  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R8
  MOV RDX, [PanelGraphic.ImageWidth]
  SUB R8, RDX
  MOV RBX, R8                                          ; Save the X offset for displaying text
  ADD RBX, 5

  XOR R9, R9 
  MOV RDX, OFFSET PanelGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayImage
  
  ;
  ; Display The Current Level
  ;
  
  MOV R8, LEVEL_INFORMATION.LevelNumber[RDI]
  MOV RDX, OFFSET PlayerCurLevelText
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 5
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  ;
  ; Display The Current Number of Lives the player has left
  ;

  MOV R8, [PlayerLives]
  MOV RDX, OFFSET PlayerLivesText
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 25
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  ;
  ; Display The Current Number of Barrels collected for the level
  ;

  MOV R9, LEVEL_INFORMATION.LevelCompleteBarrelCount[RDI]
  MOV R8, LEVEL_INFORMATION.CurrentLevelBarrelCount[RDI]
  MOV RDX, OFFSET PlayerBarrels
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 45
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  ;
  ; Display The Current Number of Car Parts collected for the level
  ;
  
  MOV R9, LEVEL_INFORMATION.LevelCompleteBarrelCount[RDI]
  MOV R8, LEVEL_INFORMATION.CurrentLevelBarrelCount[RDI]
  MOV RDX, OFFSET PlayerParts
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 65
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

@PanelIsOff:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayGamePanel, _TEXT$00



