;*********************************************************
; The Great Machine Game - Handle Level Reset and Winning and Loosing
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
; Level Resets, Winning and Loosing handlers
;***************************************************************************************************************************************************************************



;*********************************************************
;   GreatMachine_GameOver
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GameOver, _TEXT$00
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
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], GAME_OVER_SIZE
  MOV R9, GAME_OVER_Y
  MOV R8, GAME_OVER_X
  MOV RDX, OFFSET GameOverText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV RDX, [TitleMusicId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic

  MOV [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
  MOV RAX, GREAT_MACHINE_END_GAME
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GameOver, _TEXT$00

;*********************************************************
;   GreatMachine_Winner
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Winner, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  DEBUG_FUNCTION_CALL GreatMachine_DisplayWinnerAnimation

  MOV R9, 400
  MOV R8, 230
 ; MOV [CarSpinGraphic.ImageFrameNum], 0  ; keep resetting it so it doesn't animate
  MOV RDX, OFFSET CarSpinGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage


  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], WINNER_SIZE
  MOV R9, WINNER_Y
  MOV R8, WINNER_X
  MOV RDX, OFFSET WinnerText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  MOV RAX, GREAT_MACHINE_STATE_WINSCREEN
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Winner, _TEXT$00




;*********************************************************
;   GreatMachine_ResetLevelToOne
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetLevelToOne, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; We first need to update the score here since 
  ; we are resetting the level location after this.
  ;
  MOV RAX, [LevelInformationPtr]
  MOV RCX, LEVEL_INFO.LevelTimer[RAX]
  ADD [PlayerScore], RCX

  ;
  ; Setup Game Level information
  ;
  DEBUG_FUNCTION_CALL GreatMachine_SelectLevelMode
  
  MOV RDX, LEVEL_WRAP_AROUND
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevelInformation

  MOV RDX, PLAYER_WRAP_AROUND
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetPlayer

  MOV RDX, GLOBALS_WRAP_AROUND
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_SetupGameGlobals


  MOV RDX, [GameMusicId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists
  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ResetLevelToOne, _TEXT$00



;*********************************************************
;   GreatMachine_ResetLevel
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, LEVEL_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevelInformation

  MOV RDX, PLAYER_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetPlayer

  MOV RDX, GLOBALS_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_SetupGameGlobals  

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists

  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ResetLevel, _TEXT$00

;*********************************************************
;   GreatMachine_NextLevel
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, [LevelInformationPtr]
  ADD RAX, SIZE LEVEL_INFO
  MOV [LevelInformationPtr], RAX

  MOV RDX, LEVEL_NEXT_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevelInformation

  MOV RDX, PLAYER_NEXT_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_ResetPlayer


  MOV RDX, GLOBALS_NEXT_LEVEL_RESET
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_SetupGameGlobals

  ;
  ; Reset all game lists
  ;
  DEBUG_FUNCTION_CALL GreatMachine_EmptyAllLists
  DEBUG_FUNCTION_CALL GreatMachine_ResetPoints

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel, _TEXT$00



;*********************************************************
;   GreatMachine_NextLevel_Win
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel_Win, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN

  MOV RDX, [WinMusicId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel_Win, _TEXT$00



;*********************************************************
;   GreatMachine_Boom
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Boom, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  DEC [BoomTimer]

  CMP [BoomTimer], 0
  JA @KeepBooming
  MOV [BoomTimerActive], 0
  MOV [BoomTimer], 0
  MOV RAX, [LevelInformationPtr]
  MOV RAX, LEVEL_INFO.pfnLevelReset[RAX]
  DEBUG_FUNCTION_CALL RAX
@GameOver:
@KeepBooming:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Boom, _TEXT$00


;*********************************************************
;   GreatMachine_Pause
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Pause, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast

  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], GAME_OVER_SIZE
  MOV R9, GAME_OVER_Y
  MOV R8, GAME_OVER_X
  MOV RDX, OFFSET HoldText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  CMP [PauseGame],0
  JNE @KeepPausing

  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS

@KeepPausing:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Pause, _TEXT$00



;*********************************************************
;  GreatMachine_MoveStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_MoveStars, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, [StarEntryPtr]
  XOR RSI, RSI
  MOV R12, RCX
  
@Move_Stars:

  MOVSD xmm0, STAR_FIELD_ENTRY.Location.z[RDI]
  UCOMISD xmm0,  mmword ptr [ConstantZero]
  JG @CheckOffScreen
  JMP @CreateNewStar

@CheckOffScreen:
  CMP STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_OFF_SCREEN
  JE @CreateNewStar

  MOVSD xmm0, STAR_FIELD_ENTRY.Velocity[RDI]
  MOVSD xmm1, STAR_FIELD_ENTRY.Location.z[RDI]
  SUBSD xmm1, xmm0
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm1

  CMP STAR_FIELD_ENTRY.Color[RDI], 255
  JE @SkipIncrementColor

  INC STAR_FIELD_ENTRY.Color[RDI]
 @SkipIncrementColor:

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Move_Stars
  JMP @StarMoveComplete

@CreateNewStar:
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.x[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[R12]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.y[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  AND RAX, 0FFh
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm0

  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_ON_SCREEN

  DEBUG_FUNCTION_CALL Math_rand
  MOV STAR_FIELD_ENTRY.Color[RDI], AL

  MOV RAX, [CurrentVelocity]
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0

  JMP  @SkipIncrementColor
@StarMoveComplete:
   
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END GreatMachine_MoveStars, _TEXT$00

;*********************************************************
;  GreatMachine_PlotStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_PlotStars, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, [StarEntryPtr]
  XOR RSI, RSI
  MOV R12, RCX
  
@Plot_Stars:
  MOV STD_FUNCTION_STACK_MIN.Parameters.Param5[RSP], 0
  LEA R9, [TwoDPlot]
  LEA R8, [WorldLocation]
  LEA RDX, STAR_FIELD_ENTRY.Location[RDI]
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_Convert3Dto2D
  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], RAX
  CMP RAX, SOFT3D_PIXEL_OFF_SCREEN
  JE @SkipPixelPlot
  
  MOV RBX, [DoubleBuffer]
  LEA R9, [TwoDPlot]

  MOV RCX, TD_POINT_2D.y[R9]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  MUL RCX
  ADD RBX, RAX
  ADD RBX, TD_POINT_2D.x[R9]
  
  MOV AL, STAR_FIELD_ENTRY.Color[RDI]
  MOV [RBX], AL

 @SkipPixelPlot:
  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Plot_Stars
  
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END GreatMachine_PlotStars, _TEXT$00

;*********************************************************
;  GreatMachine_IncStarVelocity
;
;        Parameters: Leaf function for updating Velocity
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_IncStarVelocity, _TEXT$00
  .ENDPROLOG 
  CMP [CurrentVelocity], 5
  JAE @SkipUpdate
  INC [CurrentVelocity]
@SkipUpdate:
  RET
NESTED_END GreatMachine_IncStarVelocity, _TEXT$00


;*********************************************************
;  GreatMachine_DisplayWinnerAnimation
;
;        Parameters: Master Context, Double Buffer
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayWinnerAnimation, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV R9, RDX
  MOV RCX, [DoubleBuffer]
  MOV RDX, [VirtualPallete]
  MOV R8, DB_FLAG_CLEAR_BUFFER
  DEBUG_FUNCTION_CALL Dbuffer_UpdateOther32BitDoubleBuffer

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_MoveStars

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_PlotStars

  DEBUG_FUNCTION_CALL GreatMachine_IncStarVelocity

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DisplayWinnerAnimation, _TEXT$00


