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
;        Parameters: Master Context Level Info
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


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayGamePanel, _TEXT$00

