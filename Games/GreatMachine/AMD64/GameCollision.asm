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

   CMP SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_PART
   JNE @TryNextType_One

          MOV RCX, [LevelInformationPtr]
          MOV RDX,OFFSET LaneOnePtr   
          CMP SPECIAL_SPRITE_STRUCT.SpriteListPtr[R12], RDX
          JE @DecrementLane1ForParts
          DEC LEVEL_INFORMATION.CurrentCarPartCountL0[RCX]
          MOV RAX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL0[RCX]
          MOV LEVEL_INFORMATION.CarPartGenerateTimerL0[RCX], RAX
          JMP @RemoveFromList
@DecrementLane1ForParts:
          DEC LEVEL_INFORMATION.CurrentCarPartCountL1[RCX]
          MOV RAX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL1[RCX]
          MOV LEVEL_INFORMATION.CarPartGenerateTimerL1[RCX], RAX


   JMP @RemoveFromList
@TryNextType_One:
   CMP SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_TOXIC 
   JNE @TryNextType_Two
@ToxicCollision:

          MOV RCX, [LevelInformationPtr]
          MOV RDX,OFFSET LaneOnePtr   
          CMP SPECIAL_SPRITE_STRUCT.SpriteListPtr[R12], RDX
          JE @DecrementLane1ForToxic
          DEC LEVEL_INFORMATION.CurrentBarrelCountL0[RCX]
          MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL0[RCX]
          MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RCX], RAX
          JMP @RemoveFromList
@DecrementLane1ForToxic:
          DEC LEVEL_INFORMATION.CurrentBarrelCountL1[RCX]
          MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL1[RCX]
          MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RCX], RAX

   JMP @RemoveFromList

@TryNextType_Two:
   CMP SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_TOXIC 
   JNE @TryNextType_Three
@ExtraLivesCollision:
    MOV RCX, [LevelInformationPtr]
    MOV RAX, LEVEL_INFORMATION.ItemGenerateTimerRefresh[RCX]
    MOV LEVEL_INFORMATION.ItemGenerateTimer[RCX], RAX
   
   JMP @RemoveFromList 
@TryNextType_Three:   
   JMP @RemoveFromList

@RemoveFromList:   
   ;
   ; Fix up and Remove Sprite
   ;  
   MOV RCX, R12
   MOV R12, SPECIAL_SPRITE_STRUCT.ListNextPtr[R12] 
   DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithoutPoints
ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET LaneZeroPtr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET LaneOnePtr
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
   
   MOV R15, [LaneZeroPtr]
   CMP RAX, 0
   JE @CheckForCollisions
   MOV R15, [LaneOnePtr]

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
   
   ; Here we have a collision with "some" object.  We need to determine the object to see 
   ; what we need to do.
   MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteType[R15]

   CMP RAX, SPRITE_TYPE_CAR        
   JE @CarCollision

   CMP RAX, SPRITE_TYPE_TOXIC      
   JE @ToxicCollision

   CMP RAX, SPRITE_TYPE_PART       
   JE @PartCollision

   CMP RAX, SPRITE_TYPE_PEDESTRIAN 
   JE @PedesstrianCollision

   CMP RAX, SPRITE_TYPE_POINT_ITEM
   JE @PointsItem
   ;
   ; Unless we have a bug, we cannot get here because SpriteType cannot be set
   ; to any other number.
   ;
   INT 3
;
; Car Collision is fatal, lose a life
;
@CarCollision:
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
   MOV [BoomXLocation], RCX
   JMP @EndOfList
@SecondCheck:

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
   MOV [BoomXLocation], RCX
JMP @EndOfList

;
; Collect the Fuel
;
@ToxicCollision:

  MOV RCX, [LevelInformationPtr]
  MOV RDX,OFFSET LaneOnePtr   
  CMP SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15], RDX
  JE @DecrementLane1ForToxic
  DEC LEVEL_INFORMATION.CurrentBarrelCountL0[RCX]
  MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL0[RCX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RCX], RAX
  JMP @CreatePointsEntryForToxic
@DecrementLane1ForToxic:
  DEC LEVEL_INFORMATION.CurrentBarrelCountL1[RCX]
  MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefreshL1[RCX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RCX], RAX

@CreatePointsEntryForToxic:
  
  MOV R8, LEVEL_INFORMATION.BarrelPoints[RCX]  
  ADD [PlayerScore], R8
  MOV RDX, LEVEL_INFORMATION.LevelCompleteBarrelCount[RCX]
  CMP RDX, LEVEL_INFORMATION.CurrentLevelBarrelCount[RCX]
  JE @AlreadyCompleteForToxic
  INC LEVEL_INFORMATION.CurrentLevelBarrelCount[RCX]
@AlreadyCompleteForToxic:

  MOV RDX, R8
  MOV RCX, R15
  MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithPoints

ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET LaneZeroPtr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET LaneOnePtr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif


JMP @CheckForCollisions

;
; Collect the Part
;
@PartCollision:
  MOV RCX, [LevelInformationPtr]
  MOV RDX,OFFSET LaneOnePtr   
  CMP SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15], RDX
  JE @DecrementLane1ForParts
  DEC LEVEL_INFORMATION.CurrentCarPartCountL0[RCX]
  MOV RAX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL0[RCX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL0[RCX], RAX
  JMP @CreatePointsEntryForParts
@DecrementLane1ForParts:
  DEC LEVEL_INFORMATION.CurrentCarPartCountL1[RCX]
  MOV RAX, LEVEL_INFORMATION.CarPartGenerateTimerRefreshL1[RCX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimerL1[RCX], RAX

@CreatePointsEntryForParts:
  
  MOV R8, LEVEL_INFORMATION.CarPartsPoints[RCX]  
  ADD [PlayerScore], R8
  MOV RDX, LEVEL_INFORMATION.LevelCompleteCarPartCount[RCX]
  CMP RDX, LEVEL_INFORMATION.CurrentCarPartCount[RCX]
  JE @AlreadyCompleteForParts
  INC LEVEL_INFORMATION.CurrentCarPartCount[RCX]
@AlreadyCompleteForParts:
  
  MOV RDX, R8
  MOV RCX, R15
  MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithPoints

ifdef MACHINE_GAME_DEBUG
  MOV RCX, OFFSET LaneZeroPtr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
  MOV RCX, OFFSET LaneOnePtr
  DEBUG_FUNCTION_CALL GreatMachine_VerifyLinkedListIntegrity
endif

JMP @CheckForCollisions

;
; Cannot hit pedestrians
;
@PedesstrianCollision:
  ; TBD
  INT 3; Currently, should never be on the list.
JMP @EndOfList

;
; Random items you get points for getting
;
@PointsItem:
  ;
  ; Only allowed to get 1 extra life per level.
  ;
  MOV RCX, [LevelInformationPtr]
  LEA RAX, [POINT_EXTRA_LIFE]
  MOV LEVEL_INFORMATION.ItemGenerateTimer[RCX], RAX

  INC [PlayerLives]
  LEA RDX, [POINT_EXTRA_LIFE]
  MOV RCX, R15
  MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  DEBUG_FUNCTION_CALL GreatMachine_RemoveItemFromListWithPoints
JMP @CheckForCollisions

@NextItemCheck:
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





