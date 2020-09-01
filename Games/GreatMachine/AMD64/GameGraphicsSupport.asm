;*********************************************************
; The Great Machine Game - Support functions for graphics
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
; Graphics Support Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_DisplayScrollText
;
;        Parameters: Master Context, Text, Highlight Index
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayScrollText, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RBX, R8

  XOR R12, R12

@DisplayMenuText:
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  CMP R12, RBX
  JNE @SkipColorChange
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FF0000h

@SkipColorChange:
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE

  MOV R8, QWORD PTR [RDI]
  ADD RDI, 8
  MOV R9, QWORD PTR [RDI]
  ADD RDI, 8

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
@FindEnd:
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNZ @FindEnd

  INC R12

  INC RDI
  CMP QWORD PTR [RDI], 0
  JNE @DisplayMenuText

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayScrollText, _TEXT$00

