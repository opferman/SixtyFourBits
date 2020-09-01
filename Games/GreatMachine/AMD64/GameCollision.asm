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
   ; Compare: Player_Rear > Car_Front Then No Crash
   ;          Player_Front < Car_Rear Then No Crash
   ;
   MOV R10, [PlayerSprite.SpriteX]
   ADD R10, PLAYER_CAR_LENGTH           ; Player_Front < Car_Rear
   CMP R10, RAX
   JL @CarIsNotCollision

   ADD RAX, RCX
   CMP [PlayerSprite.SpriteX], RAX       ; Player_Rear > Car_Front
   JG @CarIsNotCollision
   
   INT 3
   
@CarIsNotCollision:
   MOV R15, SPECIAL_SPRITE_STRUCT.ListNextPtr[R15]
   JMP @CheckForCollisions

@EndOfList:
@ChangingLanesIsProtected:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CollisionPlayer, _TEXT$00


