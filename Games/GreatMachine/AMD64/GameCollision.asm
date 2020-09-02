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
;        Parameters: Master Context, Level information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CollisionNPC, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG


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
   MOV [BoomXLocation], RCX
   JMP @EndOfList

@CrashAtFrontOfPlayer:
   MOV RAX, [BoomGraphic.ImageWidth]
   SHR RAX, 1
   MOV RCX, RBX
   SUB RCX, RAX
   MOV [BoomXLocation], RCX
JMP @EndOfList

;
; Collect the Fuel
;
@ToxicCollision:

  MOV RCX, [LevelInformationPtr]
  MOV RDX,OFFSET LaneOnePtr   
  CMP SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15], RDX
  JE @DecrementLane1
  DEC LEVEL_INFORMATION.CurrentBarrelCountL0[RCX]
  MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefresh[RCX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL0[RCX], RAX
  JMP @CreatePointsEntry
@DecrementLane1:
  DEC LEVEL_INFORMATION.CurrentBarrelCountL1[RCX]
  MOV RAX, LEVEL_INFORMATION.BarrelGenerateTimerRefresh[RCX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimerL1[RCX], RAX

@CreatePointsEntry:
  MOV RAX, SPECIAL_SPRITE_STRUCT.ScrollingPtr[R15]


    
  MOV R8, LEVEL_INFORMATION.BarrelPoints[RCX]  
  ADD [PlayerScore], R8
  MOV RDX, LEVEL_INFORMATION.LevelCompleteBarrelCount[RCX]
  CMP RDX, LEVEL_INFORMATION.CurrentLevelBarrelCount[RCX]
  JE @AlreadyComplete
  INC LEVEL_INFORMATION.CurrentLevelBarrelCount[RCX]
@AlreadyComplete:
  MOV RDX, SCROLLING_GIF.CurrentY[RAX]
  MOV RCX, SCROLLING_GIF.CurrentX[RAX]
  DEBUG_FUNCTION_CALL GreatMachine_CreatePointEntry

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[R15], 0
  CMP SPECIAL_SPRITE_STRUCT.ListNextPtr[R15], 0
  JE @NothingInFront
  ; Fix up next on list to point to before.
  
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15]
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RAX], RCX

@NothingInFront:
  CMP SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15], 0
  JE @OnHeadOfList
  
  MOV RAX, SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RAX], RCX

  JMP @NextItemCheck
@OnHeadOfList:
  MOV RAX, SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15]
  MOV RCX, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
  CMP RCX, 0
  JE @NothingOnList

  MOV QWORD PTR [RAX], RCX
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15], 0

  JMP @NextItemCheck
@NothingOnList:
  MOV QWORD PTR [RAX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15], 0
JMP @NextItemCheck

;
; Collect the Part
;
@PartCollision:

JMP @NextItemCheck

;
; Cannot hit pedestrians
;
@PedesstrianCollision:

JMP @EndOfList

;
; Random items you get points for getting
;
@PointsItem:

JMP @NextItemCheck

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


