;*********************************************************
; The Great Machine Game - Parallax Scrolling Background
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
; Parralax Scrolling and Background Support Functions.
;***************************************************************************************************************************************************************************



;*********************************************************
;   GreatMachine_AnimateBackground
;
;        Parameters: Master Context
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AnimateBackground, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDX, OFFSET RoadScroll
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif
  
  MOV RDX, OFFSET MountainScroll
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif

  MOV RDX, OFFSET SkyScroll
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif

  XOR R12, R12
  LEA R15, [TreeScrollList]
@TreeSpriteLoop:
  CMP R12, NUMBER_OF_TREE_SCROLLING
  JE @TreeLoopComplete
     CMP QWORD PTR [R15], 0
     JE @SkipTree

     MOV RDX, QWORD PTR [R15 + 8]
     MOV RCX, RSI
     DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingSprite
     MOV QWORD PTR [R15], RAX

@SkipTree:
     ADD R15, 16
     INC R12
     JMP @TreeSpriteLoop
@TreeLoopComplete:
  INC [CurrentTreeTick]
  CMP [CurrentTreeTick], TREE_GENERATE_TICK
  JB @SkipCheck

  XOR R12, R12
  LEA R15, [TreeScrollList]
@TreeSpriteLoop2:
  CMP R12, NUMBER_OF_TREE_SCROLLING
  JE @SkipCheck
     CMP QWORD PTR [R15], 0
     JNE @SkipTree2

     CALL Math_Rand
     AND EAX, 0Fh
     CMP EAX, 4
     JA @SkipTree2

     MOV [CurrentTreeTick], 0
     
     MOV QWORD PTR [R15], 1
     MOV RDX, [R15 + 8]
     MOV SCROLLING_GIF.CurrentX[RDX], 1023
     JMP @SkipCheck
     
@SkipTree2:
     ADD R15, 16
     INC R12
     JMP @TreeSpriteLoop2

@SkipCheck:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_AnimateBackground, _TEXT$00

