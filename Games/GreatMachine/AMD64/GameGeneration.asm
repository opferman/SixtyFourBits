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

  MOV RDX, OFFSET GenerateCarsStructure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate

  MOV RDX, OFFSET GenerateFuelStructure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate
 
  MOV RDX, OFFSET GeneratePart1Structure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate
 
  MOV RDX, OFFSET GeneratePart2Structure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate
 
  MOV RDX, OFFSET GeneratePart3Structure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate
 
  MOV RDX, OFFSET GeneratePedestriansStructure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate
 
  MOV RDX, OFFSET GenerateExtraLifeStructure
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate

 ; MOV RDX, OFFSET GenerateHazardsStructure
 ; MOV RCX, RSI
 ; DEBUG_FUNCTION_CALL GreatMachine_GenericGenerate

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DispatchGamePieces, _TEXT$00



;*********************************************************
;   GreatMachine_GenericGenerate
;
;        Parameters: Master Context, Generation Structure
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GenericGenerate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R14, RCX
  MOV R15, RDX
  
  MOV RDX, GENERATE_STRUCT.NumberOfItemsOnList[R15]
  MOV RCX, GENERATE_STRUCT.ItemListPtr[R15]
  DEBUG_FUNCTION_CALL GreatMachine_SpriteDebounce

  MOV RCX, R15
  MOV RAX, GENERATE_STRUCT.pfnTickDebounceUpdate[R15]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JE @TimerStillRunning
  
  MOV RCX, R15
  MOV RAX, GENERATE_STRUCT.pfnPreGenerateCheck[R15]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JE @PreChecksFailed

  XOR RBX, RBX
  MOV RSI, GENERATE_STRUCT.ItemListPtr[R15]

@GenerateObjectsLoop:
  MOV RCX, R15
  MOV RAX, GENERATE_STRUCT.pfnLoopCheck[R15]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JE @ExitLoop

  CMP RBX, GENERATE_STRUCT.NumberOfItemsOnList[R15]
  JE @CompletedList

  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI], 0
  JNE @NextLoopIncrement

  CMP SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], 0
  JNE @NextLoopIncrement

  MOV RDX, RSI
  MOV RCX, R15
  DEBUG_FUNCTION_CALL GreatMachine_RandomSelection
  CMP RAX, 0
  JE @ItemNotSelected

  MOV R8, R14
  MOV RDX, RSI
  MOV RCX, R15
  MOV RAX, GENERATE_STRUCT.pfnActivateSprite[R15]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JE @NoListToAddTo

  MOV R13, RAX                          ; List to add to
  CMP QWORD PTR [R13], 0
  JE @AddToEmptyList

;
; Add the item to a non-empty list
;
@AddToNonEmptyList:
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV RAX, [R13]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], RAX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13
  MOV QWORD PTR [R13], RSI
  JMP @NextLoopIncrement

;
; Add the item to an empty list
;
@AddToEmptyList:
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0
  MOV QWORD PTR [R13], RSI
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], R13

@ItemNotSelected:   
@NoListToAddTo:
@NextLoopIncrement:
  INC RBX
  ADD RSI, SIZE SPECIAL_SPRITE_STRUCT
  JMP @GenerateObjectsLoop

@ExitLoop:
@CompletedList:
@PreChecksFailed:
@TimerStillRunning:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GenericGenerate, _TEXT$00

;*********************************************************
;   GreatMachine_RandomSelection
;
;        Parameters: Generation Structure, Sprite
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RandomSelection, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, 100                                  ; We are going to generate a number from 1 to 100
  XOR RDX, RDX
  DIV RCX
  INC RDX                                       ; Increment past 0

  ;
  ; The percentage chance of generation is done by checking that the random number 1-100
  ; is equal to or less than the percentage chance of generation.
  ;
  XOR RAX, RAX
  CMP SPECIAL_SPRITE_STRUCT.SpriteGenerationPercent[RDI], RDX
  JB @FailedToGenerate

  MOV RAX, 1

@FailedToGenerate: 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_RandomSelection, _TEXT$00



;*********************************************************
;   GreatMachine_SpriteDebounce
;
;        Parameters: SpriteList, Count
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SpriteDebounce, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

@UpdateSpriteDebounceLoop:
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RCX], 0
  JNE @NextSprite

  CMP SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RCX], 0
  JE @NextSprite

  DEC SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RCX]

@NextSprite:  
  ADD RCX, SIZE SPECIAL_SPRITE_STRUCT
  DEC RDX
  JNZ @UpdateSpriteDebounceLoop  
@DoneUpdating:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_SpriteDebounce, _TEXT$00

;*********************************************************
;   GreatMachine_Cars_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Cars_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, 1                            ; Return Value of TRUE.
  MOV RAX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerAfterCarExitsScreen[RAX], 0
  JE @CheckConcurrentCars
  DEC LEVEL_INFO.TimerAfterCarExitsScreen[RAX]
  XOR RDX, RDX

@CheckConcurrentCars:
  CMP LEVEL_INFO.CurrentNumberOfCars[RAX], 0
  JE @ClearTimer
  CMP LEVEL_INFO.TimerBetweenConCurrentCars[RAX], 0
  JE @NothingToUpdate
  DEC LEVEL_INFO.TimerBetweenConCurrentCars[RAX]
  XOR RDX, RDX
  JMP @UpdatedTimerBetweenCars
@ClearTimer:
  MOV LEVEL_INFO.CurrentNumberOfCars[RAX], 0
@UpdatedTimerBetweenCars:
@NothingToUpdate:
  
  MOV RAX, RDX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Cars_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Cars_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Cars_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Cars_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Cars_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Cars_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDX, 1
  MOV RAX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerBetweenConCurrentCars[RAX], 0
  JE @NoCarsGenerated
  XOR RDX, RDX  
@NoCarsGenerated:
  
  MOV R8, LEVEL_INFO.NumberOfConcurrentCars[RAX]
  CMP LEVEL_INFO.CurrentNumberOfCars[RAX], R8
  JB @CanStillGenerateCars
  XOR RDX, RDX  
@CanStillGenerateCars:
  
  MOV RAX, RDX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Cars_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Cars_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: Lane Pointer
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Cars_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RAX, [LevelInformationPtr]
  MOV RCX, LEVEL_INFO.BlockingItemCountLane2[RAX]
  XOR RCX, 1
  SHL RCX, 1
  MOV RDX, LEVEL_INFO.BlockingItemCountLane1[RAX]
  XOR RDX, 1
  OR RCX, RDX
  SHL RCX, 1
  MOV RDX, LEVEL_INFO.BlockingItemCountLane0[RAX]
  XOR RDX, 1
  OR RCX, RDX
  CMP RCX, 0
  JE @NoLanesAvailable

  INC LEVEL_INFO.CurrentNumberOfCars[RAX]
  MOV R8, LEVEL_INFO.TimerBetweenConcurrentCarsRefresh[RAX]
  MOV LEVEL_INFO.TimerBetweenConCurrentCars[RAX], R8
  
  MOV RDX, RDI                ; Pass In The Sprite
  MOV R8, LANE_GENERATE_LEFT  ; Pass In The Side to Generate For.
  MOV R9, 1
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable

  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9,  SCROLLING_GIF.ImageInformation [R10]
  MOV R9, IMAGE_INFORMATION.ImageWidth[R9]
  NEG R9
  INC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV RDI, R10

  MOV RSI, [LevelInformationPtr] 
  MOV R10, LEVEL_INFO.MinCarVelocity[RSI]
  DEC R10
  MOV R11, LEVEL_INFO.MaxCarVelocity[RSI]
  SUB R11, R10
  MOV R12, R11

  ;
  ; Second car has to go min velocity so it does not
  ; overtake car 1 and there should be enough space for
  ; the player to get through.
  ;
  MOV RDX, LEVEL_INFO.MinCarVelocity[RSI]
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV R12
  ADD RDX, LEVEL_INFO.MinCarVelocity[RSI]  
  MOV SCROLLING_GIF.XIncrement[RDI], RDX
  MOV SCROLLING_GIF.YIncrement[RDI], 0
  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Cars_ActivateSprite, _TEXT$00


;*********************************************************
;   GreatMachine_SelectLane
;
;        Parameters: Lane Selection Bits, Sprite, Left or Right, Blocking 1 or 0
;
;        Return Value: Lane Pointer
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SelectLane, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, RCX
  MOV RBX, R8
  MOV R12, R9
  XOR R15, R15

  MOV R14, OFFSET LaneSelectionSpace

  TEST RSI, LANE_BITMASK_0
  JZ @TryNext_1

  MOV QWORD PTR [R14], LANE_BITMASK_0
  LEA RAX, [Lane0Ptr]
  MOV QWORD PTR [R14 + SIZE QWORD], RAX
  ADD R14, (SIZE QWORD * 2)
  
  INC R15
@TryNext_1:
  TEST RSI, LANE_BITMASK_1
  JZ @TryNext_2
  MOV QWORD PTR [R14], LANE_BITMASK_1
  LEA RAX, [Lane1Ptr]
  MOV [R14 + SIZE QWORD], RAX
  ADD R14, (SIZE QWORD * 2)
  INC R15
@TryNext_2:
  TEST RSI, LANE_BITMASK_2
  JZ @TryNext_3
  MOV QWORD PTR [R14], LANE_BITMASK_2
  LEA RAX, [Lane2Ptr]
  MOV [R14 + SIZE QWORD], RAX
  ADD R14, (SIZE QWORD * 2)
  INC R15
@TryNext_3:
  TEST RSI, LANE_TOP_SIDEWALK_BITMASK
  JZ @TryNext_4
  MOV QWORD PTR [R14], LANE_TOP_SIDEWALK_BITMASK
  LEA RAX, [TopSideWalkPtr]
  MOV [R14 + SIZE QWORD], RAX 
  ADD R14, (SIZE QWORD * 2)
  INC R15
@TryNext_4:
  TEST RSI, LANE_BOTTOM_SIDEWALK_BITMASK
  JZ @TestingForLanesComplete
  MOV QWORD PTR [R14], LANE_BOTTOM_SIDEWALK_BITMASK
  LEA RAX, [BottomSideWalkPtr]
  MOV [R14 + SIZE QWORD], RAX
  ADD R14, (SIZE QWORD * 2)
  INC R15
@TestingForLanesComplete:

  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  DIV R15

  SHL RDX, 4
  MOV R14, OFFSET LaneSelectionSpace
  ADD R14, RDX

  MOV RAX, QWORD PTR [R14 + SIZE QWORD]
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX    
  
  ;
  ; Update the lane bitmask
  ;
  MOV RCX, [R14]
  MOV SPECIAL_SPRITE_STRUCT.SpriteLaneBitmask[RDI], RCX
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, SCROLLING_GIF.ImageInformation[R10]
  MOV R9, IMAGE_INFORMATION.ImageHeight[R9]
  MOV R8, PLAYER_Y_DIM
  SUB R8, R9
  MOV SCROLLING_GIF.YIncrement[R10], 0



  CMP R12, 0
  JE @DoesNotBlockLane

  MOV RCX, [LevelInformationPtr]

  TEST QWORD PTR [R14], LANE_BITMASK_0
  JZ @TryNextLane_1

  ADD LEVEL_INFO.BlockingItemCountLane0[RCX], 1
  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_0
  
@TryNextLane_1:
  TEST QWORD PTR [R14], LANE_BITMASK_1
  JZ @TryNextLane_2

  ADD LEVEL_INFO.BlockingItemCountLane1[RCX], 1
  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_1

@TryNextLane_2:
  TEST QWORD PTR [R14], LANE_BITMASK_2
  JZ @TryNextLane_3

  ADD LEVEL_INFO.BlockingItemCountLane2[RCX], 1
  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_2

@TryNextLane_3:
  TEST QWORD PTR [R14], LANE_TOP_SIDEWALK_BITMASK
  JZ @TryNextLane_4

  MOV SCROLLING_GIF.CurrentY[R10], TOP_SIDEWALK_PERSON  

@TryNextLane_4:
  TEST QWORD PTR [R14], LANE_BOTTOM_SIDEWALK_BITMASK
  JZ @TestingForLanesComplete2

  MOV SCROLLING_GIF.CurrentY[R10], BOTTOM_SIDEWALK_PERSON
  JMP @CompleteSetup
@DoesNotBlockLane:

  TEST QWORD PTR [R14], LANE_BITMASK_0
  JZ @TryNextLane_1_NonBlockning

  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_0

@TryNextLane_1_NonBlockning:
  TEST QWORD PTR [R14], LANE_BITMASK_1
  JZ @TryNextLane_2_NonBlockning

  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_1

@TryNextLane_2_NonBlockning:
  TEST QWORD PTR [R14], LANE_BITMASK_2
  JZ @TryNextLane_3_NonBlockning

  MOV SCROLLING_GIF.CurrentY[R10], PLAYER_LANE_2

@TryNextLane_3_NonBlockning:
  TEST QWORD PTR [R14], LANE_TOP_SIDEWALK_BITMASK
  JZ @TryNextLane_4_NonBlockning

  MOV SCROLLING_GIF.CurrentY[R10], TOP_SIDEWALK_PERSON  

@TryNextLane_4_NonBlockning:
  TEST QWORD PTR [R14], LANE_BOTTOM_SIDEWALK_BITMASK
  JZ @TestingForLanesComplete2

  MOV SCROLLING_GIF.CurrentY[R10], BOTTOM_SIDEWALK_PERSON
  JMP @CompleteSetup

@TestingForLanesComplete2:
@CompleteSetup:
  CMP R8, 0
  JL @Skip
  ADD SCROLLING_GIF.CurrentY[R10], R8
@Skip:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_SelectLane, _TEXT$00



;*********************************************************
;   GreatMachine_Fuel_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForFuel[RDX], 0
  JE @NoFuelTicks
  DEC LEVEL_INFO.TimerForFuel[RDX]
  XOR RAX, RAX
@NoFuelTicks:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Fuel_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Fuel_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Fuel_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Fuel_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForFuel[RDX], 0
  JE @NoFuelTicks
  XOR RAX, RAX
@NoFuelTicks:

  MOV R8, LEVEL_INFO.NumberOfConcurrentFuel[RDX]
  CMP LEVEL_INFO.CurrentNumberOfFuel[RDX], R8
  JB @CanStillGenerateFuel
  XOR RAX, RAX 
@CanStillGenerateFuel:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Fuel_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Fuel_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_BITMASK_0 or LANE_BITMASK_1 or LANE_BITMASK_2  

  INC LEVEL_INFO.CurrentNumberOfFuel[RAX]
  MOV R8, LEVEL_INFO.TimerForFuelRefresh[RAX]
  MOV LEVEL_INFO.TimerForFuel[RAX], R8
  
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Fuel_ActivateSprite, _TEXT$00




;*********************************************************
;   GreatMachine_Part1_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts1[RDX], 0
  JE @NoPartTicks
  DEC LEVEL_INFO.TimerForParts1[RDX]
  XOR RAX, RAX
@NoPartTicks:


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part1_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Part1_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part1_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part1_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts1[RDX], 0
  JE @NoPartTicks
  XOR RAX, RAX
@NoPartTicks:

  MOV R8, LEVEL_INFO.NumberOfConcurrentPartOne[RDX]
  CMP LEVEL_INFO.CurrentNumberOfPartOne[RDX], R8
  JB @CanStillGenerateParts
  XOR RAX, RAX 
@CanStillGenerateParts:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part1_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part1_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_BITMASK_0 or LANE_BITMASK_1 or LANE_BITMASK_2  

  INC LEVEL_INFO.CurrentNumberOfPartOne[RAX]
  MOV R8, LEVEL_INFO.TimerForParts1Refresh[RAX]
  MOV LEVEL_INFO.TimerForParts1[RAX], R8
  
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part1_ActivateSprite, _TEXT$00




;*********************************************************
;   GreatMachine_Part2_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
    MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts2[RDX], 0
  JE @NoPartTicks
  DEC LEVEL_INFO.TimerForParts2[RDX]
  XOR RAX, RAX
@NoPartTicks:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part2_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Part2_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part2_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part2_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts2[RDX], 0
  JE @NoPartTicks
  XOR RAX, RAX
@NoPartTicks:

  MOV R8, LEVEL_INFO.NumberOfConcurrentPartTwo[RDX]
  CMP LEVEL_INFO.CurrentNumberOfPartTwo[RDX], R8
  JB @CanStillGenerateParts
  XOR RAX, RAX 
@CanStillGenerateParts:  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part2_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part2_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_BITMASK_0 or LANE_BITMASK_1 or LANE_BITMASK_2  

  INC LEVEL_INFO.CurrentNumberOfPartTwo[RAX]
  MOV R8, LEVEL_INFO.TimerForParts2Refresh[RAX]
  MOV LEVEL_INFO.TimerForParts2[RAX], R8
  
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:    

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part2_ActivateSprite, _TEXT$00






;*********************************************************
;   GreatMachine_Part3_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts3[RDX], 0
  JE @NoPartTicks
  DEC LEVEL_INFO.TimerForParts3[RDX]
  XOR RAX, RAX
@NoPartTicks:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part3_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Part3_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part3_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part3_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForParts3[RDX], 0
  JE @NoPartTicks
  XOR RAX, RAX
@NoPartTicks:

  MOV R8, LEVEL_INFO.NumberOfConcurrentPartThree[RDX]
  CMP LEVEL_INFO.CurrentNumberOfPartThree[RDX], R8
  JB @CanStillGenerateParts
  XOR RAX, RAX 
@CanStillGenerateParts:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part3_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Part3_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_BITMASK_0 or LANE_BITMASK_1 or LANE_BITMASK_2  

  INC LEVEL_INFO.CurrentNumberOfPartThree[RAX]
  MOV R8, LEVEL_INFO.TimerForParts3Refresh[RAX]
  MOV LEVEL_INFO.TimerForParts3[RAX], R8
  
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:    

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Part3_ActivateSprite, _TEXT$00


;*********************************************************
;   GreatMachine_Pedestrians_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrians_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForPedestrians[RDX], 0
  JE @NoPedestrianTicks
  DEC LEVEL_INFO.TimerForPedestrians[RDX]
  XOR RAX, RAX
@NoPedestrianTicks:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Pedestrians_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_Pedestrians_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrians_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Pedestrians_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Pedestrians_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrians_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForPedestrians[RDX], 0
  JE @NoPedestrianTicks
  XOR RAX, RAX
@NoPedestrianTicks:


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Pedestrians_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Pedestrians_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrians_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_TOP_SIDEWALK_BITMASK or LANE_BOTTOM_SIDEWALK_BITMASK  

  MOV R8, LEVEL_INFO.TimerForPedestriansRefresh[RAX]
  MOV LEVEL_INFO.TimerForPedestrians[RAX], R8
  
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Pedestrians_ActivateSprite, _TEXT$00




;*********************************************************
;   GreatMachine_ExtraLife_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForExtraLives[RDX], 0
  JE @NoExtraLifeTicks
  DEC LEVEL_INFO.TimerForExtraLives[RDX]
  XOR RAX, RAX
@NoExtraLifeTicks:
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ExtraLife_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_ExtraLife_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ExtraLife_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_ExtraLife_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RAX, 1
  MOV RDX, [LevelInformationPtr]

  CMP LEVEL_INFO.TimerForExtraLives[RDX], 0
  JE @NoPartTicks
  XOR RAX, RAX
@NoPartTicks:

  ;
  ; Can only have 1 extra life active, so
  ; we can just check if the sprite
  ; is active or not.
  ;
  MOV RDX, GENERATE_STRUCT.ItemListPtr[RCX]
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDX], 0
  JE @SpriteIsNotActive
  XOR RAX, RAX          ; Just bail out of the loop.
@SpriteIsNotActive:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ExtraLife_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_ExtraLife_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RDX
  MOV RSI, R8

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 1

  MOV RAX, [LevelInformationPtr]
  
  ;
  ; Generate lane choices and choose.
  ;
  MOV RCX, LANE_BITMASK_0 or LANE_BITMASK_1 or LANE_BITMASK_2  
 
  MOV RDX, RDI                 ; Pass In The Sprite
  MOV R8, LANE_GENERATE_RIGHT  ; Pass In The Side to Generate For.
  XOR R9, R9
  DEBUG_FUNCTION_CALL GreatMachine_SelectLane
  CMP RAX, 0
  JE @NoLanesAvailable
  MOV RBX, RAX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RDI], RAX   
  MOV R10, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDI]
  MOV R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC R9
  MOV SCROLLING_GIF.CurrentX[R10], R9
  MOV SCROLLING_GIF.XIncrement[R10], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R10], ROAD_SCROLL_Y_INC

  MOV RAX, RBX
  JMP @LanesAvailable

@NoLanesAvailable:  
  XOR RAX, RAX
@LanesAvailable:     

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ExtraLife_ActivateSprite, _TEXT$00






;*********************************************************
;   GreatMachine_Hazards_TickDebounceUpdate
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazards_TickDebounceUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Hazards_TickDebounceUpdate, _TEXT$00

;*********************************************************
;   GreatMachine_EHazards_PreGenerateCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazards_PreGenerateCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Hazards_PreGenerateCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Hazards_LoopCheck
;
;        Parameters: Generation Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazards_LoopCheck, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Hazards_LoopCheck, _TEXT$00


;*********************************************************
;   GreatMachine_Hazards_ActivateSprite
;
;        Parameters: Generation Structure, Sprite, Master Context
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazards_ActivateSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Hazards_ActivateSprite, _TEXT$00

