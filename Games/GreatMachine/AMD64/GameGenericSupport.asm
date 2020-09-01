;*********************************************************
; The Great Machine Game - Generic Support Functions
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
; Generic Support Functions
;***************************************************************************************************************************************************************************





;*********************************************************
;   GreatMachine_ScreenCapture
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ScreenCapture, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 
  MOV RSI, RCX
  MOV RDI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_ScreenCapture, _TEXT$00


;*********************************************************
;   GreatMachine_ScreenBlast
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ScreenBlast, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_ScreenBlast, _TEXT$00












;*********************************************************
;   GreatMachine_EmptyAllLists
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_EmptyAllLists, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RCX, [TopSideWalkPtr]
  MOV [TopSideWalkPtr], 0
  DEBUG_FUNCTION_CALL GreatMachine_EmptyList

  MOV RCX, [LaneZeroPtr]
  MOV [LaneZeroPtr], 0
  DEBUG_FUNCTION_CALL GreatMachine_EmptyList

  MOV RCX, [LaneOnePtr]
  MOV [LaneOnePtr], 0
  DEBUG_FUNCTION_CALL GreatMachine_EmptyList

  MOV RCX, [BottomSideWalkPtr]
  MOV [BottomSideWalkPtr], 0
  DEBUG_FUNCTION_CALL GreatMachine_EmptyList
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_EmptyAllLists, _TEXT$00

;*********************************************************
;   GreatMachine_EmptyList
;
;        Parameters: List
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_EmptyList, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

@EmptyListLoop:
  CMP RCX, 0
  JE @ListIsEmpty

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounce[RCX], 0
  MOV RDX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RCX]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], 0
  MOV RCX, RDX
  JMP @EmptyListLoop

@ListIsEmpty:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_EmptyList, _TEXT$00

;*********************************************************
;   GreatMachine_RemoveFromList
;
;        Parameters: List Entry
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RemoveFromList, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[RCX], 0
  MOV RDX, SPECIAL_SPRITE_STRUCT.ListNextPtr[RCX]
  MOV R8, SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX]
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[RCX], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RCX], 0
  CMP RDX, 0
  JE @SkipUpdatingRdx
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[RDX], R8
@SkipUpdatingRdx:
  CMP R8, 0
  JNE @UpdateBeforeList

  MOV R8, SPECIAL_SPRITE_STRUCT.SpriteListPtr[RCX]
  MOV [R8], RDX
  MOV SPECIAL_SPRITE_STRUCT.SpriteListPtr[RCX], 0
  JMP @ListEntryRemoved
  
@UpdateBeforeList:
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R8], RDX

@ListEntryRemoved:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_RemoveFromList, _TEXT$00


;*********************************************************
;   GreatMachine_UpdateTimer
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateTimer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RCX, [LevelStartTimer]
  DEBUG_FUNCTION_CALL GameEngine_GetElapsedMs

  MOV RCX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFORMATION.LevelTimerRefresh[RCX]
  SUB RDX, RAX
  SUB RDX, [TimerAdjustMs]
  CMP RDX, 0
  JG @SkipUpdateToZero
  MOV RDX, 0
  ; 
  ; Do Level Timeout Stuff.
  ;
@SkipUpdateToZero:
  MOV LEVEL_INFORMATION.LevelTimer[RCX], RDX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_UpdateTimer, _TEXT$00
