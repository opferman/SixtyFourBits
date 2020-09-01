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


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CollisionPlayer, _TEXT$00


