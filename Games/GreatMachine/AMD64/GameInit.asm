;*********************************************************
; The Great Machine Game - Game Entry point / early init functions
;
;  Written in Assembly x64
; 
;  By Toby Opferman  8/28/2020
;
;     AKA ChecksumError on Youtube
;     AKA BinaryBomb on Discord
;
;*********************************************************



;*********************************************************
;   GreatMachine_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_LOADING
ifdef USE_FILES
  MOV RDX, OFFSET LoadingScreen
  MOV RCX, OFFSET LoadingScreenImage
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
else  
  MOV RCX, OFFSET LoadingScreenImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
endif
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, OFFSET GreatMachineStateFuncPtrs
  MOV RDX, OFFSET GameEngInit
  MOV GAME_ENGINE_INIT.GameFunctionPtrs[RDX], RCX
  MOV RCX, OFFSET GreatMachine_LoadingThread
  MOV GAME_ENGINE_INIT.GameLoadFunction[RDX],RCX
  MOV GAME_ENGINE_INIT.GameLoadCxt[RDX], RSI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_Init
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, GreatMachine_SpaceBar
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease
  
  MOV RDX, GreatMachine_UpArrow
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_DownArrow
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, GreatMachine_Enter
  MOV RCX, VK_RETURN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, GreatMachine_RightArrow
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_RightArrowPress
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_LeftArrow
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_LeftArrowPress
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_UpArrowPress
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress
  
  MOV RDX, GreatMachine_DownArrowPress
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_SpacePress
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_P_Press
  MOV RCX, VK_P
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_H_Press
  MOV RCX, VK_H
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress
  

;
; TBD: Add keys and sequences for cheat codes.
;


@SuccessExit:
  MOV EAX, 1
  JMP @ActualExit  
@FailureExit:
  XOR EAX, EAX
@ActualExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Init, _TEXT$00


;*********************************************************
;   GreatMachine_Demo
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Demo, _TEXT$00


;*********************************************************
;   GreatMachine_Free
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
;
; Ya, TBD on clean up :)
;

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Free, _TEXT$00





