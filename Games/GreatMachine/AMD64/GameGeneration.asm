;*********************************************************
; The Great Machine Game - Support generation of game pieces
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
; Creating Game Pieces
;***************************************************************************************************************************************************************************


;*********************************************************
;   GreatMachine_DispatchGamePieces
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DispatchGamePieces, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenerateGameCars


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DispatchGamePieces, _TEXT$00




;*********************************************************
;   GreatMachine_GenerateGameCars
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GenerateGameCars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
;  MOV RSI, RCX
;  MOV RDI, RDX 

  MOV RSI, [LevelInformationPtr]
  CMP LEVEL_INFORMATION.TimerAfterCarsLeave[RSI], 0
  JNE @StillTicking

  MOV RBX, [GenericCarListPtr]
  XOR RDI, RDI
@CheckCars:
  MOV R9, LEVEL_INFORMATION.NumberOfConcurrentCars[RSI]
  CMP LEVEL_INFORMATION.CurrrentNumberOfCars[RSI], R9
  JAE @AlreadyMaximumCapacityForCars

  CMP RDI, NUMBER_OF_CARS
  JE @NoMoreCarsToCheck
  
  CMP SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RBX], 0
  JNE @UpdateDebounce

  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RBX], 0
  JNE @SpriteIsAlreadyActive
  
  DEBUG_FUNCTION_CALL Math_Rand
  AND RAX, SPECIAL_SPRITE_STRUCT.SpriteBiasMask[RBX]
  CMP RAX, SPECIAL_SPRITE_STRUCT.SpriteBias[RBX]
  JA @SpriteSkipped

  ;
  ; Now this sprite will become active and put on one of the list.
  ;

  DEBUG_FUNCTION_CALL Math_Rand

  MOV R15, OFFSET LaneZeroPtr
  MOV R14, PLAYER_LANE_0
  TEST EAX, 1
  JE @LaneZeroItIs
  MOV R15, OFFSET LaneOnePtr
  MOV R14, PLAYER_LANE_1
@LaneZeroItIs:
  INC LEVEL_INFORMATION.CurrrentNumberOfCars[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RBX], 1

  MOV R10, LEVEL_INFORMATION.MinAddedVelocity[RSI]
  DEC R10
  MOV R11, LEVEL_INFORMATION.MaxAddedVelocity[RSI]
  SUB R11, R10
  MOV R12, R11
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV R12
  ADD RDX, LEVEL_INFORMATION.MinAddedVelocity[RSI]
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RBX]
  
  MOV SCROLLING_GIF.CurrentY[RAX], R14
  MOV SCROLLING_GIF.XIncrement[RAX], RDX       
  MOV SCROLLING_GIF.YIncrement[RAX], 0
  MOV RCX, SCROLLING_GIF.ImageInformation [RAX]

  MOV RCX, IMAGE_INFORMATION.ImageWidth[RCX]
  NEG RCX
  INC RCX
  MOV SCROLLING_GIF.CurrentX[RAX], RCX    

  CMP R15, 0
  JE @AddSelfToList

  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RBX], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15], RBX
  MOV RCX, QWORD PTR [R15]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RBX], RCX
  MOV QWORD PTR [R15], RBX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RBX], R15

@SpriteIsAlreadyActive:
@SpriteSkipped:
  INC RDI
  ADD RBX, SIZE SPECIAL_SPRITE_STRUCT
  JMP @CheckCars

@AddSelfToList:
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RBX], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RBX], 0
  MOV QWORD PTR [R15], RBX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RBX], R15
  JMP @CheckCars

@UpdateDebounce:
  INC RDI
  DEC SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RBX]
  ADD RBX, SIZE SPECIAL_SPRITE_STRUCT
  JMP @CheckCars
  
@StillTicking:
  DEC LEVEL_INFORMATION.TimerAfterCarsLeave[RSI]
@NoMoreCarsToCheck:  
@AlreadyMaximumCapacityForCars:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GenerateGameCars, _TEXT$00



