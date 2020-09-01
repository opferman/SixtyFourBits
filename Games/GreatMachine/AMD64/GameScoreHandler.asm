;*********************************************************
; The Great Machine Game - Handle High Scores
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
;   GreatMachine_EnterHiScore
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_EnterHiScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display High Score with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HS_GAME_OVER_SIZE
  MOV R9, HS_GAME_OVER_Y
  MOV R8, HS_GAME_OVER_X
  MOV RDX, OFFSET HighScoreText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], ENTER_INITIALS_SIZE
  MOV R9, ENTER_INITIALS_Y
  MOV R8, ENTER_INITIALS_X
  MOV RDX, OFFSET EnterInitials
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INITIALS_SIZE
  MOV R9, INITIALS_Y
  MOV R8, INITIALS_X
  MOV RDX, OFFSET InitialsEnter
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  MOV RAX, GREAT_MACHINE_STATE_ENTER_HI_SCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_EnterHiScore, _TEXT$00




;*********************************************************
;   GreatMachine_HiScoreScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_HiScoreScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Hi-Score Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_TITLE_SIZE
  MOV R9, HI_SCORE_TITLE_Y
  MOV R8, HI_SCORE_TITLE_X
  MOV RDX, OFFSET HighScoresText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_MODE_FONT
  MOV R9, HI_SCORE_MODE_Y
  MOV R8, HI_SCORE_MODE_X
  CMP [GameModeSelect], 0
  JNE @ItsNotEasy
  MOV RDX, OFFSET EasyModeText
  MOV RDI, [HiScoreListPtr]
  JMP @PrintTheMode
@ItsNotEasy:
  CMP [GameModeSelect], 1
  JNE @ItsHard
  MOV RDI, [HiScoreListPtr]
  ADD RDI, 120
  MOV RDX, OFFSET MediumModeText
  JMP @PrintTheMode
@ItsHard:
  MOV RDI, [HiScoreListPtr]
  ADD RDI, 120*2
  MOV RDX, OFFSET HardModeText    
@PrintTheMode:
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  
  XOR RBX, RBX
  MOV R12, HI_SCORE_Y_START
@DisplayHighScoreLoop:
  
  MOV R9, QWORD PTR [RDI+4]
  MOV R8, RDI
  MOV RDX, OFFSET HiScoreFormatString
  MOV RCX, OFFSET HiScoreString
  DEBUG_FUNCTION_CALL sprintf
  ADD RDI, 4+8		; 3 Initials + NULL + QWORD
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_FONT_SIZE
  MOV R9, R12
  ADD R12, HI_SCORE_Y_INC
  MOV R8, HI_SCORE_X
  MOV RDX, OFFSET HiScoreString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  
  INC RBX
  CMP RBX, MAX_HI_SCORES
  JB @DisplayHighScoreLoop

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_HISCORE
  MOV RAX, GREAT_MACHINE_HISCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_HiScoreScreen, _TEXT$00



  
;*********************************************************
;   GreatMachine_UpdateHighScore
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateHighScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  ;
  ; No Error Checking, assume this is all correct.
  ;
  MOV RDX, [HiScoreListPtr]
  CMP [GameModeSelect], 0
  JE @EasyMode
  ADD RDX, 120
  CMP [GameModeSelect], 1
  JE @MediumMode
  ADD RDX, 120
@MediumMode:
@EasyMode:
  ADD RDX, (120-12)          ; Set it to the last entry

@MoveAllScores:
  CMP RDX, [HiScoreLocationPtr]
  JE @FoundLocation
  
  MOV RAX, QWORD PTR [RDX-12]
  MOV QWORD PTR [RDX], RAX
  MOV EAX, DWORD PTR [RDX-4]
  MOV DWORD PTR [RDX+8], EAX
  SUB RDX, 12
  JMP @MoveAllScores

@FoundLocation:
  ;
  ; Update Hi-Scores
  ;
  MOV RCX, OFFSET InitialsEnter
  MOV EAX, DWORD PTR [RCX]
  MOV DWORD PTR [RDX], EAX
  MOV RCX, [PlayerScore]
  MOV QWORD PTR [RDX + 4], RCX
  MOV [InitialsEnterPtr], RCX
        
  MOV [HiScoreLocationPtr], 0
  
  ;  
  ; Save the scores in the file.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_UpdateHiScores

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_UpdateHighScore, _TEXT$00


;*********************************************************
;   GreatMachine_HiScoreEnterUpdate
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_HiScoreEnterUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JNE @NoScoreUpdate

  MOV RCX, [InitialsEnterPtr]
  ADD BYTE PTR [RCX], AL

  CMP BYTE PTR [RCX], 'A'
  JAE @CheckAbove

  MOV BYTE PTR [RCX], 'Z'

@CheckAbove:
  CMP BYTE PTR [RCX], 'Z'
  JBE @CompleteandDone

  MOV BYTE PTR [RCX], 'A'

@CompleteandDone:
@NoScoreUpdate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_HiScoreEnterUpdate, _TEXT$00


;*********************************************************
;   GreatMachine_UpdateHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 03h  ; OPEN_EXISTING
  MOV R9, 0
  MOV R8, 3h   	 ; File Share Read/Write
  MOV RDX, 2h    ; File write
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; Write out the initial high scores list.
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120*3				; File Size is fixed to 120*3 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL WriteFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation:
@FailedToOpenAttemptToCreate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_UpdateHiScores, _TEXT$00


;*********************************************************
;   GreatMachine_CheckHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CheckHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  ;
  ;   Reset High Scores
  ;
  MOV RAX, OFFSET InitialsConst
  MOV EAX, [RAX]
  MOV RCX, OFFSET InitialsEnter
  MOV [RCX], EAX
  MOV [InitialsEnterPtr], RCX
        
  MOV RDX, [HiScoreListPtr]
  CMP [GameModeSelect], 0
  JE @EasyMode
  ADD RDX, 120
  CMP [GameModeSelect], 1
  JE @MediumMode
  ADD RDX, 120
@MediumMode:
@EasyMode:
  XOR R8, R8
  MOV RCX, [PlayerScore]
  
  
  MOV [HiScoreLocationPtr], 0

@CheckNextScore:
  CMP RCX, QWORD PTR [RDX + 4]
  JA @NewHighScore

  ADD RDX, 12
  INC R8
  CMP R8, MAX_HI_SCORES
  JB @CheckNextScore
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@NewHighScore:
  MOV [HiScoreLocationPtr], RDX                 ; Update New High Score Location!
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_CheckHiScores, _TEXT$00
