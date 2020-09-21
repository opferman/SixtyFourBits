;*********************************************************
; The Great Machine Game - Detect Collisions in the game
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
; Colission Detection Functions
;***************************************************************************************************************************************************************************





;*********************************************************
;   GreatMachine_CollisionNPC
;
;        Parameters: Master Context, Level information, lane pointer address
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RDI, RDX
  MOV R15, R8
  MOV RBX, [R15]
@CollisionLoopForNPC:
  CMP RBX, 0
  JE @NoMoreCollisions
ifdef MACHINE_GAME_DEBUG
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RBX],0
  JNE @DebugSkip
  INT 3
@DebugSkip: 
endif
  CMP SPECIAL_SPRITE_STRUCT.SpriteType[RBX], SPRITE_TYPE_CAR
  JNE @LoopUpdate


  MOV R12, [R15]
@InnerLoopForCar:
  CMP R12, 0
  JE @LoopUpdate
  CMP R12, RBX 
  JE @InnerLoopUpdate
ifdef MACHINE_GAME_DEBUG
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[R12],0
  JNE @DebugSkip2
  INT 3
@DebugSkip2: 
endif
   ;
   ; Grab the image width and current X location.
   ;
   MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[R12]
   MOV RCX, SCROLLING_GIF.ImageInformation[RAX]
   MOV RCX, IMAGE_INFORMATION.ImageWidth[RCX]
   MOV RAX, SCROLLING_GIF.CurrentX[RAX]

   ;
   ; Compare: Car_Rear > X_Front Then No Collision
   ;          Car_Front < X_Rear Then No Collision
   ;
   MOV R9, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RBX]
   MOV R10, SCROLLING_GIF.ImageInformation[R9]
   MOV R10, IMAGE_INFORMATION.ImageWidth[R10]
   MOV R9, SCROLLING_GIF.CurrentX[R9]

   ; R9 = X of Car; R10 = Width Of Car
   ; RAX = X of Item ; RCX = Width Of Item

   ADD R10, R9                           ; Car_Front < X_Rear
   CMP R10, RAX
   JL @IsNotCollision
   ADD RAX, RCX
   CMP R9, RAX                         ; Car_Rear > X_Front
   JG @IsNotCollision

   MOV RCX, R12
   MOV RAX, SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R12]
   DEBUG_FUNCTION_CALL RAX

@RemoveFromList:   
   ;
   ; Fix up and Remove Sprite
   ;  
   MOV RCX, R12
   MOV R12, SPECIAL_SPRITE_STRUCT.ListNextPtr[R12] 
   DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithoutPoints

ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET Lane0Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane1Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET Lane2Ptr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

   JMP @InnerLoopForCar  

@IsNotCollision:
@InnerLoopUpdate:
  MOV R12, SPECIAL_SPRITE_STRUCT.ListNextPtr[R12] 
  JMP @InnerLoopForCar  
@LoopUpdate:
  MOV RBX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RBX] 
  JMP @CollisionLoopForNPC

@NoMoreCollisions:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CollisionNPC, _TEXT$00






;*********************************************************
;   GreatMachine_Fuel_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_CollisionNPC, _TEXT$00
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

  MOV RDX, [CaritemEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Fuel_CollisionNPC, _TEXT$00


;*********************************************************
;   GreatMachine_Part1_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_CollisionNPC, _TEXT$00
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

  MOV RDX, [CaritemEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part1_CollisionNPC, _TEXT$00

;*********************************************************
;   GreatMachine_Part2_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_CollisionNPC, _TEXT$00
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

  MOV RDX, [CaritemEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part2_CollisionNPC, _TEXT$00

;*********************************************************
;   GreatMachine_Part3_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_CollisionNPC, _TEXT$00
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

  MOV RDX, [CaritemEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part3_CollisionNPC, _TEXT$00


;*********************************************************
;   GreatMachine_ExtraLife_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RCX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RCX, [LevelInformationPtr]

  MOV RAX, LEVEL_INFO.TimerForExtraLivesRefresh[RCX]
  MOV LEVEL_INFO.TimerForExtraLives[RCX], RAX

  MOV RDX, [CaritemEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ExtraLife_CollisionNPC, _TEXT$00

;*********************************************************
;   GreatMachine_Hazard_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazard_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  INT 3         ; A car should never hit a hazard

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Hazard_CollisionNPC, _TEXT$00


;*********************************************************
;   GreatMachine_Pedestrian_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrian_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  INT 3         ; A car should never hit a pedestrian

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Pedestrian_CollisionNPC, _TEXT$00


;*********************************************************
;   GreatMachine_Car_CollisionNPC
;
;        Parameters: Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Car_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG

  INT 3         ; Should never collide into a car.

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Car_CollisionNPC, _TEXT$00





;*********************************************************
;   GreatMachine_CollisionPlayer
;
;        Parameters: Master Context, Level information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CollisionPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
   MOV RSI, RCX
   MOV RDI, RDX

   ;
   ; Check if we are changing lanes, if so we are protected from collisions.
   ;
   MOV EAX, [NextPlayerRoadLane]
   CMP EAX, [CurrentPlayerRoadLane]
   JNE @ChangingLanesIsProtected
   
   MOV R15, [Lane0Ptr]
   CMP RAX, 0
   JE @CheckForCollisions

   MOV R15, [Lane1Ptr]
   CMP RAX, 1
   JE @CheckForCollisions

   MOV R15, [Lane2Ptr] 

@CheckForCollisions:
   CMP R15, 0
   JE @EndOfList
ifdef MACHINE_GAME_DEBUG
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[R15],0
  JNE @DebugSkip
  INT 3
@DebugSkip:  
endif
   ;
   ; Grab the image width and current X location.
   ;
   MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[R15]
   MOV RCX, SCROLLING_GIF.ImageInformation[RAX]
   MOV RCX, IMAGE_INFORMATION.ImageWidth[RCX]
   MOV RAX, SCROLLING_GIF.CurrentX[RAX]

   ;
   ; Compare: Player_Rear > X_Front Then No Collision
   ;          Player_Front < X_Rear Then No Collision
   ;
   MOV R10, [PlayerSprite.SpriteX]
   ADD R10, PLAYER_CAR_LENGTH           ; Player_Front < X_Rear
   CMP R10, RAX
   JL @IsNotCollision
   MOV RBX, RAX                         ; Save for evaluation of crash site.
   ADD RAX, RCX
   CMP [PlayerSprite.SpriteX], RAX       ; Player_Rear > X_Front
   JG @IsNotCollision

   MOV RDX, R15
   MOV RCX, RSI
   MOV RAX, SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R15]
   DEBUG_FUNCTION_CALL RAX
   CMP RAX, 0
   JE @EndOfList

   ADD [PlayerScore], RAX

   MOV RDX, RAX
   MOV RCX, R15
   MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
   DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithPoints

ifdef MACHINE_GAME_DEBUG
   MOV RCX, OFFSET Lane0Ptr
   DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
   MOV RCX, OFFSET Lane1Ptr
   DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
   MOV RCX, OFFSET Lane2Ptr
   DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

   JMP @CheckForCollisions
@IsNotCollision:
   MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
   JMP @CheckForCollisions

@EndOfList:
@ChangingLanesIsProtected:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CollisionPlayer, _TEXT$00



;*********************************************************
;   GreatMachine_RemoveItemFromListWithPoints
;
;        Parameters: Special Sprite Information, Points
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RemoveItemFromListWithPoints, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RSI]
  MOV R8, RDX
  MOV RDX, SCROLLING_GIF.CurrentY[RAX]
  MOV RCX, SCROLLING_GIF.CurrentX[RAX]
  DEBUG_FUNCTION_CALL GreatMachine_CreatePointEntry
ifdef MACHINE_GAME_DEBUG
  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RSI],0
  JNE @DebugSkip
  INT 3
@DebugSkip:
endif
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
  
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RAX], RCX

  JMP @CompletedRemoval
@OnHeadOfList:
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  CMP RCX, 0
  JE @NothingOnList

  MOV QWORD PTR [RAX], RCX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0

  JMP @CompletedRemoval
@NothingOnList:
  MOV QWORD PTR [RAX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0

@CompletedRemoval:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RemoveItemFromListWithPoints, _TEXT$00



;*********************************************************
;   GreatMachine_RemoveItemFromListWithoutPoints
;
;        Parameters: Special Sprite Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RemoveItemFromListWithoutPoints, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX

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
  
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RAX], RCX

  JMP @CompletedRemoval
@OnHeadOfList:
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI]
  CMP RCX, 0
  JE @NothingOnList

  MOV QWORD PTR [RAX], RCX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0

  JMP @CompletedRemoval
@NothingOnList:
  MOV QWORD PTR [RAX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RSI], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RSI], 0

@CompletedRemoval:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RemoveItemFromListWithoutPoints, _TEXT$00



;*********************************************************
;   GreatMachine_VerifyLinkedListIntegrity
;
;        Parameters: Linked List
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_VerifyLinkedListIntegrity, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RDI, [RSI]

  CMP RDI, 0
  JE @NothingElseOnTheList

  CMP SPECIAL_SPRITE_STRUCT.ListBeforePtr[RDI], 0
  JE @EntryIsCorrectBackPointer
  INT 3
@EntryIsCorrectBackPointer:

  CMP SPECIAL_SPRITE_STRUCT.ListNextPtr[RDI], 0
  JE @NothingElseOnTheList

@LoopLinkedList:
  CMP RDI, 0
  JE @DoneChecking

  CMP SPECIAL_SPRITE_STRUCT.SpriteIsActive[RDI], 0
  JNE @SpriteIsActive
  INT 3
@SpriteIsActive:

  MOV RAX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RDI]
  CMP RAX, 0
  JE @NoMoreOnList
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX]

  CMP RCX, RDI
  JE @BackPointerCorrect
  INT 3
@BackPointerCorrect:
 
  MOV RDI, RAX

  JMP @LoopLinkedList
@NoMoreOnList:
@DoneChecking:
@NothingElseOnTheList:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_VerifyLinkedListIntegrity, _TEXT$00






;*********************************************************
;   GreatMachine_Fuel_Collision
;
;        Parameters: Master Context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Fuel_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RDX
  MOV RDI, RCX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RSI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RSI], RAX

  MOV RBX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfFuel[RBX]

  MOV RAX, LEVEL_INFO.TimerForFuelRefresh[RBX]
  MOV LEVEL_INFO.TimerForFuel[RBX], RAX

  MOV RAX, LEVEL_INFO.CurrentFuelCollection[RBX]
  CMP RAX, LEVEL_INFO.RequiredFuelCollection[RBX]
  JAE @CollectedEnough
  INC LEVEL_INFO.CurrentFuelCollection[RBX]
  INC RAX
  CMP RAX, LEVEL_INFO.RequiredFuelCollection[RBX]
  JB @RegularSound

  MOV RDX, [CollectEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  JMP @SkipRegularSound
@RegularSound:
@CollectedEnough:
  MOV RDX, [PickupEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
@SkipRegularSound:

  MOV RAX, LEVEL_INFO.FuelPoints[RBX]

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Fuel_Collision, _TEXT$00


;*********************************************************
;   GreatMachine_Part1_Collision
;
;         Parameters: Master Context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part1_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RDX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RBX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfPartOne[RBX]

  MOV RAX, LEVEL_INFO.TimerForParts1Refresh[RBX]
  MOV LEVEL_INFO.TimerForParts1[RBX], RAX

  MOV RAX, LEVEL_INFO.CurrentPartOneCollection[RBX]
  CMP RAX, LEVEL_INFO.RequiredPartOneCollection[RBX]
  JAE @CollectedEnough
  INC LEVEL_INFO.CurrentPartOneCollection[RBX]
  INC RAX
  CMP RAX, LEVEL_INFO.RequiredPartOneCollection[RBX]
  JB @RegularSound

  MOV RDX, [CollectEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  JMP @SkipRegularSound
@RegularSound:
@CollectedEnough:
  MOV RDX, [PickupEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
@SkipRegularSound:

  MOV RAX, LEVEL_INFO.CarPartOnePoints[RBX]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part1_Collision, _TEXT$00

;*********************************************************
;   GreatMachine_Part2_Collision
;
;          Parameters: Master Context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part2_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RDX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RBX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfPartTwo[RBX]

  MOV RAX, LEVEL_INFO.TimerForParts2Refresh[RBX]
  MOV LEVEL_INFO.TimerForParts1[RBX], RAX

  MOV RAX, LEVEL_INFO.CurrentPartTwoCollection[RBX]
  CMP RAX, LEVEL_INFO.RequiredPartTwoCollection[RBX]
  JAE @CollectedEnough
  INC LEVEL_INFO.CurrentPartTwoCollection[RBX]
  INC RAX
  CMP RAX, LEVEL_INFO.RequiredPartTwoCollection[RBX]
  JB @RegularSound

  MOV RDX, [CollectEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  JMP @SkipRegularSound
@RegularSound:
@CollectedEnough:
  MOV RDX, [PickupEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
@SkipRegularSound:

  MOV RAX, LEVEL_INFO.CarPartTwoPoints[RBX]

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part2_Collision, _TEXT$00

;*********************************************************
;   GreatMachine_Part3_Collision
;
;        Parameters: Mater context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Part3_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RDX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RBX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfPartThree[RBX]

  MOV RAX, LEVEL_INFO.TimerForParts3Refresh[RBX]
  MOV LEVEL_INFO.TimerForParts3[RBX], RAX

  MOV RAX, LEVEL_INFO.CurrentPartThreeCollection[RBX]
  CMP RAX, LEVEL_INFO.RequiredPartThreeCollection[RBX]
  JAE @CollectedEnough
  INC LEVEL_INFO.CurrentPartThreeCollection[RBX]
  INC RAX
  CMP RAX, LEVEL_INFO.RequiredPartThreeCollection[RBX]
  JB @RegularSound

  MOV RDX, [CollectEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  JMP @SkipRegularSound
@RegularSound:
@CollectedEnough:
  MOV RDX, [PickupEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
@SkipRegularSound:

  MOV RAX, LEVEL_INFO.CarPartThreePoints[RBX]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Part3_Collision, _TEXT$00


;*********************************************************
;   GreatMachine_ExtraLife_Collision
;
;        Parameters: master context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ExtraLife_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RDI, RDX

  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[RDI]
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RDI], RAX

  MOV RDX, [ExtralifeEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  INC [PlayerLives]

  MOV RCX, [LevelInformationPtr]
  LEA RAX, [POINT_EXTRA_LIFE]
  MOV LEVEL_INFO.TimerForExtraLives[RCX], RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ExtraLife_Collision, _TEXT$00

;*********************************************************
;   GreatMachine_Hazard_Collision
;
;        Parameters: Master Context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Hazard_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RDI, RDX
  
  MOV RAX, [LevelInformationPtr]
  DEC LEVEL_INFO.CurrentNumberOfBlockers[RAX]

  CMP SPECIAL_SPRITE_STRUCT.SpritePoints[RDI], SPRITE_KILLS
  JE @KillThePlayer
  MOV R12, SPECIAL_SPRITE_STRUCT.SpritePoints[RDI]
  MOV RBX, [CaritemEffectId]
  JMP @SkipKilling
@KillThePlayer:
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_EnableBomb
  XOR R12, R12
  MOV RBX, [CrashEffectId]
@SkipKilling: 
  MOV RDX, RBX
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect

  MOV RAX, R12

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Hazard_Collision, _TEXT$00


;*********************************************************
;   GreatMachine_Pedestrian_Collision
;
;        Parameters: Master Context, Sprite
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pedestrian_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RDI, RDX

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_EnableBomb

  MOV RDX, [CrashPedestrianId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
    
  XOR RAX, RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Pedestrian_Collision, _TEXT$00


;*********************************************************
;   GreatMachine_Car_Collision
;
;        Parameters: master context, Sprite
;
;        Return Value: Points or 0 for crash.
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Car_Collision, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX
  MOV RDI, RDX

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_EnableBomb

  MOV RDX, [CrashEffectId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayEffect
  
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Car_Collision, _TEXT$00



;*********************************************************
;   GreatMachine_EnableBomb
;
;        Parameters: Master COntext, Sprite
;
;        Return Value: N/A
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_EnableBomb, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG
  MOV RSI, RCX

  MOV RDI, SPECIAL_SPRITE_STRUCT.ScrollingPtr[RDX]
  MOV RBX, SCROLLING_GIF.CurrentX[RDI]

  MOV [BoomTimerActive], 1
  MOV RAX, [BoomTimerRefresh]
  MOV [BoomTimer], RAX
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_BOOM
  MOV RAX, [PlayerSprite.SpriteY]
  MOV [BoomYLocation], RAX

  CMP [PlayerSprite.SpriteX], RBX
  JL @CrashAtFrontOfPlayer

  MOV RAX, [BoomGraphic.ImageWidth]
  SHR RAX, 1
  MOV RCX, [PlayerSprite.SpriteX]
  SUB RCX, RAX
  CMP RCX, 0
  JGE @SkipZeroing
  XOR RCX, RCX
@SkipZeroing:
  MOV R9, RCX
  ADD R9, [BoomGraphic.ImageWidth]
  CMP R9, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JL @SkipFrontFix
  SUB RDX, [BoomGraphic.ImageWidth]
  DEC RDX
  MOV RCX, RDX
@SkipFrontFix:
  MOV [BoomXLocation], RCX
  JMP @DoneSetupBoom

@CrashAtFrontOfPlayer:
  MOV RAX, [BoomGraphic.ImageWidth]
  SHR RAX, 1
  MOV RCX, RBX
  SUB RCX, RAX
  MOV RDX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R9, RCX
  ADD R9, [BoomGraphic.ImageWidth]
  CMP R9, RDX
  JL @SkipFixUp
  SUB RDX, [BoomGraphic.ImageWidth]
  DEC RDX
  MOV RCX, RDX
@SkipFixUp:
  CMP RCX, 0
  JGE @SkipFixUpBack
  XOR RCX, RCX
@SkipFixUpBack:
  MOV [BoomXLocation], RCX
@DoneSetupBoom:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_EnableBomb, _TEXT$00
