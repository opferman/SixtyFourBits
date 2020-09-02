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

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenerateGameFuel

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenerateGameCarParts

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

  CMP QWORD PTR [R15], 0
  JE @AddSelfToList

  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RBX], 0
  MOV RCX, QWORD PTR [R15]
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], RBX
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




;*********************************************************
;   GreatMachine_GenerateGameFuel
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GenerateGameFuel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R14, RCX
  ;
  ; Check Lanes Available.
  ;
  MOV RDI, [LevelInformationPtr]
  XOR R12, R12

  CMP LEVEL_INFORMATION.CurrentBarrelCountL0[RDI], 1
  JE @Lane0Closed
  MOV R12, 1

@Lane0Closed:
  CMP LEVEL_INFORMATION.CurrentBarrelCountL1[RDI], 1
  JE @Lane1Closed
  OR R12, 2
@Lane1Closed:
  
  TEST R12, 1
  JZ @NoCheckForLane0

  CMP LEVEL_INFORMATION.BarrelGenerateTimerL0[RDI], 0
  JE @NoTicksOnLane0
  XOR R12, 1   ; Remove Lane 0
  DEC LEVEL_INFORMATION.BarrelGenerateTimerL0[RDI]
@NoCheckForLane0:
@NoTicksOnLane0:
  TEST R12, 2
  JZ @NoCheckForLane1

  CMP LEVEL_INFORMATION.BarrelGenerateTimerL1[RDI], 0
  JE @NoTicksOnLane1
  XOR R12, 2   ; Remove Lane 1
  DEC LEVEL_INFORMATION.BarrelGenerateTimerL1[RDI]
@NoTicksOnLane1:
@NoCheckForLane1:
  CMP R12, 0
  JE @NoFreeLanes

  XOR RBX, RBX
  MOV RSI, [FuelItemsList]
@GenerateFuelLoop:
  CMP R12, 0
  JE @CompletedList

  CMP RBX, NUMBER_OF_FUEL
  JE @CompletedList

  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 0
  JNE @NextLoopIncrement

  DEBUG_FUNCTION_CALL Math_Rand
  AND RAX, SPECIAL_SPRITE_STRUCT.SpriteBiasMask[RSI]
  CMP RAX, SPECIAL_SPRITE_STRUCT.SpriteBias[RSI]
  JA @SpriteSkipped

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 1
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R14]
  DEC RCX
  MOV SCROLLING_GIF.CurrentX[RAX], RCX
  MOV SCROLLING_GIF.XIncrement[RAX], ROAD_SCROLL_X_INC       
  MOV SCROLLING_GIF.YIncrement[RAX], 0

  CMP R12, 3
  JNE @OnlyOneLane

  DEBUG_FUNCTION_CALL Math_Rand
  TEST EAX, 1
  JZ @UseLane0
  JMP @UseLane1
@OnlyOneLane:
  TEST R12, 1
  JZ @UseLane1
  JMP @UseLane0
@UseLane0:
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV SCROLLING_GIF.CurrentY [RAX], PLAYER_LANE_0
  XOR R12, 1
  MOV LEVEL_INFORMATION.CurrentBarrelCountL0[RDI], 1
  ADD LEVEL_INFORMATION.CarPartGenerateTimerL0[RDI], SPECIAL_DEBOUNCE
  MOV R13, OFFSET LaneZeroPtr
  JMP  @AddToList

@UseLane1:
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV SCROLLING_GIF.CurrentY[RAX], PLAYER_LANE_1
  XOR R12, 2
  MOV LEVEL_INFORMATION.CurrentBarrelCountL1[RDI], 1
  ADD LEVEL_INFORMATION.CarPartGenerateTimerL1[RDI], SPECIAL_DEBOUNCE
  MOV R13, OFFSET LaneOnePtr
  JMP  @AddToList
@AddToList:
  CMP QWORD PTR [R13], 0
  JE @AddSelfToList
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV RAX, [R13]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], RAX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13
  MOV QWORD PTR [R13], RSI
  JMP @NextLoopIncrement
@AddSelfToList:
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV QWORD PTR [R13], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13
  

@SpriteSkipped:
@NextLoopIncrement:
  INC RBX
  ADD RSI, SIZE SPECIAL_SPRITE_STRUCT
  JMP @GenerateFuelLoop
@CompletedList:
@NoFreeLanes:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GenerateGameFuel, _TEXT$00

     


;*********************************************************
;   GreatMachine_GenerateGameCarParts
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GenerateGameCarParts, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R14, RCX
  ;
  ; Check Lanes Available.
  ;
  MOV RDI, [LevelInformationPtr]
  XOR R12, R12

  CMP LEVEL_INFORMATION.CurrentCarPartCountL0[RDI], 1
  JE @Lane0Closed
  MOV R12, 1

@Lane0Closed:
  CMP LEVEL_INFORMATION.CurrentCarPartCountL1[RDI], 1
  JE @Lane1Closed
  OR R12, 2
@Lane1Closed:
  
  TEST R12, 1
  JZ @NoCheckForLane0

  CMP LEVEL_INFORMATION.CarPartGenerateTimerL0[RDI], 0
  JE @NoTicksOnLane0
  XOR R12, 1   ; Remove Lane 0
  DEC LEVEL_INFORMATION.CarPartGenerateTimerL0[RDI]
@NoCheckForLane0:
@NoTicksOnLane0:
  TEST R12, 2
  JZ @NoCheckForLane1

  CMP LEVEL_INFORMATION.CarPartGenerateTimerL1[RDI], 0
  JE @NoTicksOnLane1
  XOR R12, 2   ; Remove Lane 1
  DEC LEVEL_INFORMATION.CarPartGenerateTimerL1[RDI]
@NoTicksOnLane1:
@NoCheckForLane1:
  CMP R12, 0
  JE @NoFreeLanes

  XOR RBX, RBX
  MOV RSI, [CarPartsItemsList]
@GenerateCarPartLoop:
  CMP R12, 0
  JE @CompletedList

  CMP RBX, NUMBER_OF_PARTS
  JE @CompletedList

  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 0
  JNE @NextLoopIncrement

  DEBUG_FUNCTION_CALL Math_Rand
  AND RAX, SPECIAL_SPRITE_STRUCT.SpriteBiasMask[RSI]
  CMP RAX, SPECIAL_SPRITE_STRUCT.SpriteBias[RSI]
  JA @SpriteSkipped

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 1
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R14]
  DEC RCX
  MOV SCROLLING_GIF.CurrentX[RAX], RCX
  MOV SCROLLING_GIF.XIncrement[RAX], ROAD_SCROLL_X_INC       
  MOV SCROLLING_GIF.YIncrement[RAX], 0

  CMP R12, 3
  JNE @OnlyOneLane

  DEBUG_FUNCTION_CALL Math_Rand
  TEST EAX, 1
  JZ @UseLane0
  JMP @UseLane1
@OnlyOneLane:
  TEST R12, 1
  JZ @UseLane1
  JMP @UseLane0
@UseLane0:
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV RCX, SCROLLING_GIF.ImageInformation[RAX]
  MOV RCX, IMAGE_INFORMATION.ImageHeight[RCX]
  MOV RDX, PLAYER_Y_DIM
  SUB RDX, RCX
  MOV RCX, PLAYER_LANE_0
  ADD RCX, RDX
  MOV SCROLLING_GIF.CurrentY[RAX], RCX

  XOR R12, 1
  MOV LEVEL_INFORMATION.CurrentCarPartCountL0[RDI], 1
  ADD LEVEL_INFORMATION.BarrelGenerateTimerL0[RDI], SPECIAL_DEBOUNCE
  MOV R13, OFFSET LaneZeroPtr
  JMP  @AddToList

@UseLane1:
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV RCX, SCROLLING_GIF.ImageInformation[RAX]
  MOV RCX, IMAGE_INFORMATION.ImageHeight[RCX]
  MOV RDX, PLAYER_Y_DIM
  SUB RDX, RCX
  MOV RCX, PLAYER_LANE_1
  ADD RCX, RDX
  MOV SCROLLING_GIF.CurrentY[RAX], RCX

  XOR R12, 2
  MOV LEVEL_INFORMATION.CurrentCarPartCountL1[RDI], 1
  ADD LEVEL_INFORMATION.BarrelGenerateTimerL1[RDI], SPECIAL_DEBOUNCE
  MOV R13, OFFSET LaneOnePtr
  JMP  @AddToList
@AddToList:
  CMP QWORD PTR [R13], 0
  JE @AddSelfToList
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV RAX, [R13]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], RAX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13
  MOV QWORD PTR [R13], RSI
  JMP @NextLoopIncrement
@AddSelfToList:
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV QWORD PTR [R13], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13
   

@SpriteSkipped:
@NextLoopIncrement:
  INC RBX
  ADD RSI, SIZE SPECIAL_SPRITE_STRUCT
  JMP @GenerateCarPartLoop
@CompletedList:
@NoFreeLanes:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GenerateGameCarParts, _TEXT$00



