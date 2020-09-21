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
  JNE @NotOnHeadOfList

@OnHeadOfList:
  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI]
  MOV R9, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV QWORD PTR [RCX], RAX

  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RCX

  MOV RCX, RAX

  JMP @CallSpriteHandler

@NotOnHeadOfList:  
  ;
  ; Fix up before pointer and advance to next on the list.
  ;
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RAX], RCX
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]

  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV R9, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RAX

@CallSpriteHandler:  
  ;
  ; RCX has the next pointer in the list here.
  ;
  MOV RAX, SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[RSI]
  XCHG RSI, RCX                 ; Swap so the current sprite is the parameter and the next sprite is in RSI for the continue of the loop.
  DEBUG_FUNCTION_CALL RAX

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

  CMP EAX, 2
  JE @MoveDownToLane2

  CMP EAX, 0
  JE @MoveUpToLane0

  CMP [MovingLanesDown], 1
  JE @MoveDownLane1
@MoveUpLane1:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  SUB [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_1
  JA @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 1
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
  JMP @DoneUpdatingMovement

@MoveDownLane1:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_1
  JB @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 1
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
  JMP @DoneUpdatingMovement

@MoveDownToLane2:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_2
  JB @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 2
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_2
  JMP @DoneUpdatingMovement

@MoveUpToLane0:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  SUB [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_0
  JA @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 0
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_0
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
  CMP [CurrentPlayerRoadLane], 1
  JE @DoneUpdatingMovement
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_2
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

  MOV RAX, 0
  CMP [PlayerScore], 0
  JGE @SkipNegativeColorChange
  MOV RAX, 0FF0000h
@SkipNegativeColorChange:
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SCORE_FONT_SIZE      ; Font Size
  MOV R9, 5
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHR R8, 2
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RCX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFO.LevelTimer[RCX]    ; Milliseconds
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
  ; Display The Current Mode
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 22
  MOV R8, 2
  MOV RDX, [GameModeText]
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
  
  MOV R8, LEVEL_INFO.LevelNumber[RDI]
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

  MOV R9, LEVEL_INFO.RequiredFuelCollection[RDI]
  MOV R8, LEVEL_INFO.CurrentFuelCollection[RDI]
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
  
  MOV R9, LEVEL_INFO.RequiredPartOneCollection[RDI]
  MOV R8, LEVEL_INFO.CurrentPartOneCollection[RDI]
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

  MOV R9, LEVEL_INFO.RequiredPartTwoCollection[RDI]
  MOV R8, LEVEL_INFO.CurrentPartTwoCollection[RDI]
  MOV RDX, OFFSET PlayerParts
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 85
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV R9, LEVEL_INFO.RequiredPartThreeCollection[RDI]
  MOV R8, LEVEL_INFO.CurrentPartThreeCollection[RDI]
  MOV RDX, OFFSET PlayerParts
  MOV RCX, OFFSET PlayerOutputText
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0      ; Color
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], PLAYER_SIDE_PANEL_FONT_SIZE
  MOV R9, 105
  MOV R8, RBX
  MOV RDX, OFFSET PlayerOutputText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  ;
  ; Display the ICONs for the items to collect
  ;

  MOV R9, 43
  MOV R8, RBX
  ADD R8, 250
  MOV RDX, OFFSET PanelIcon1Graphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, 65
  MOV R8, RBX
  ADD R8, 250
  MOV RDX, OFFSET PanelIcon2Graphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, 85
  MOV R8, RBX
  ADD R8, 250
  MOV RDX, OFFSET PanelIcon3Graphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, 105
  MOV R8, RBX
  ADD R8, 250
  MOV RDX, OFFSET PanelIcon4Graphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage


@PanelIsOff:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayGamePanel, _TEXT$00




;*********************************************************
;   GreatMachine_DisplayPoints
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayPoints, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX

  XOR RBX, RBX
  MOV RDI, OFFSET DisplayPointsList 
@DisplayPointsLoop:
  CMP RBX, POINTS_DISPLAY_LIST_SIZE
  JE @DoneDisplayPoints

  CMP DISPLAY_PLAYER_POINTS.PointTicks[RDI], 0
  JE @AdvanceToNextEntry
  DEC DISPLAY_PLAYER_POINTS.PointTicks[RDI]
  LEA RCX, [POINT_EXTRA_LIFE]
  CMP DISPLAY_PLAYER_POINTS.NumberOfPoints[RDI], RCX
  JE @ExtraLifeText

  MOV R12, 0FFFFFFh
  CMP DISPLAY_PLAYER_POINTS.NumberOfPoints[RDI], 0
  JG @SkipNegativeColor
  MOV R12, 0FF0000h
@SkipNegativeColor:
  
  MOV R8, DISPLAY_PLAYER_POINTS.NumberOfPoints[RDI]
  MOV RDX, OFFSET PointsScoreFormat
  MOV RCX, OFFSET PointsScoreString
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], R12
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], POINTS_DISPLAY_LIST_SIZE
  MOV R9, DISPLAY_PLAYER_POINTS.PointY[RDI]
  MOV R8, DISPLAY_PLAYER_POINTS.PointX[RDI]
  MOV RDX, OFFSET PointsScoreString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  JMP @ContinueDisplayingText
@ExtraLifeText:

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], POINTS_DISPLAY_LIST_SIZE
  MOV R9, DISPLAY_PLAYER_POINTS.PointY[RDI]
  MOV R8, DISPLAY_PLAYER_POINTS.PointX[RDI]
  MOV RDX, OFFSET ExtraLife
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
       
@ContinueDisplayingText:  
  SUB DISPLAY_PLAYER_POINTS.PointY[RDI], 2

@AdvanceToNextEntry:
  ADD RDI, SIZE DISPLAY_PLAYER_POINTS
  INC RBX
  JMP @DisplayPointsLoop


@DoneDisplayPoints:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DisplayPoints, _TEXT$00

;*********************************************************
;   GreateMachine_Pedestrian_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Pedestrian_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  MOV RAX, LEVEL_INFO.TimerForPedestriansRefresh[RCX]
  MOV LEVEL_INFO.TimerForPedestrians[RCX], RAX
  
  MOV RDX, RCX
  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteLaneBitmask[RDI]

  DEBUG_FUNCTION_CALL GreatMachine_UnblockLane

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Pedestrian_OffScreen, _TEXT$00


;*********************************************************
;   GreateMachine_Fuel_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Fuel_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfFuel[RCX]

  MOV RAX, LEVEL_INFO.TimerForFuelRefresh[RCX]
  MOV LEVEL_INFO.TimerForFuel[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Fuel_OffScreen, _TEXT$00


;*********************************************************
;   GreateMachine_Part1_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Part1_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  DEC LEVEL_INFO.CurrentNumberOfPartOne[RCX]
  MOV RAX, LEVEL_INFO.TimerForParts1Refresh[RCX]
  MOV LEVEL_INFO.TimerForParts1[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Part1_OffScreen, _TEXT$00

;*********************************************************
;   GreateMachine_Part2_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Part2_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  DEC LEVEL_INFO.CurrentNumberOfPartTwo[RCX]
  MOV RAX, LEVEL_INFO.TimerForParts2Refresh[RCX]
  MOV LEVEL_INFO.TimerForParts2[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Part2_OffScreen, _TEXT$00

;*********************************************************
;   GreateMachine_Part3_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Part3_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  DEC LEVEL_INFO.CurrentNumberOfPartThree[RCX]
  MOV RAX, LEVEL_INFO.TimerForParts3Refresh[RCX]
  MOV LEVEL_INFO.TimerForParts3[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Part3_OffScreen, _TEXT$00

;*********************************************************
;   GreateMachine_ExtraLife_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_ExtraLife_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  MOV RAX, LEVEL_INFO.TimerForExtraLivesRefresh[RCX]
  MOV LEVEL_INFO.TimerForExtraLives[RCX], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_ExtraLife_OffScreen, _TEXT$00


;*********************************************************
;   GreateMachine_Hazard_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Hazard_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  MOV RDX, [LevelInformationPtr]
  MOV RAX, LEVEL_INFO.TimerForHazardRefresh[RDX]
  MOV LEVEL_INFO.TimerForHazard[RDX], RAX
  DEC LEVEL_INFO.CurrentNumberOfBlockers[RDX]

  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteLaneBitmask[RCX]
  DEBUG_FUNCTION_CALL GreatMachine_UnblockLane

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Hazard_OffScreen, _TEXT$00


;*********************************************************
;   GreateMachine_Car_OffScreen
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreateMachine_Car_OffScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  
  MOV RDX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfCars[RDX]
  MOV RAX, LEVEL_INFO.TimerAfterCarExitsScreenRefresh[RDX]
  MOV LEVEL_INFO.TimerAfterCarExitsScreen[RDX], RAX

  MOV RCX, SPECIAL_SPRITE_STRUCT.SpriteLaneBitmask[RCX]
  DEBUG_FUNCTION_CALL GreatMachine_UnblockLane
   
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreateMachine_Car_OffScreen, _TEXT$00


;*********************************************************
;   GreatMachine_UnblockLane
;
;        Parameters: Lane Bitmask
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UnblockLane, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
 

 TEST RCX, LANE_BITMASK_0
 JZ @NotLane0
 DEC LEVEL_INFO.BlockingItemCountLane0[RDX]

@NotLane0:
 TEST RCX, LANE_BITMASK_1
 JZ @NotLane1
 DEC LEVEL_INFO.BlockingItemCountLane1[RDX]

@NotLane1:
 TEST RCX, LANE_BITMASK_2
 JZ @NotLane2
 DEC LEVEL_INFO.BlockingItemCountLane2[RDX]

@NotLane2:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_UnblockLane, _TEXT$00
