;*********************************************************
; The Great Machine Game - Game Loading Functions
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
; Initialization & Support Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_AllocateMemory
;
;        Parameters: Ignored, RDX is the size.
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AllocateMemory, _TEXT$00
.ENDPROLOG
  MOV RAX, [CurrentMemoryPtr]
  ADD [CurrentMemoryPtr], RDX

  MOV RDX, [LargeMemoryAllocationEnd]
  CMP [CurrentMemoryPtr], RDX
  JAE @OutOfMemory
  RET
@OutOfMemory:
  INT 3
  RET

NESTED_END GreatMachine_AllocateMemory, _TEXT$00



ifndef USE_FILES
;*********************************************************
;   GreatMachine_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifResourceType         ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA

  MOV RDX, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGifResource, _TEXT$00
endif

;*********************************************************
;   GreatMachine_SetupHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SetupHiScores, _TEXT$00
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
  MOV R8, 03h   	; File Share Read / Write
  MOV RDX, 01h   ; File Read Data
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; File exists, read in the Hi-Scores
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120*3				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL ReadFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation: 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedToOpenAttemptToCreate:

  DEBUG_FUNCTION_CALL GreatMachine_CreateHiScores
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_SetupHiScores, _TEXT$00



;*********************************************************
;   GreatMachine_CreateHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CreateHiScores, _TEXT$00
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
  MOV RDX, OFFSET HiScoreAppDataDirFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  XOR RDX, RDX
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateDirectoryA
 
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat2
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 02h  ; CREATE_ALWAYS
  MOV R9, 0
  MOV R8, 3h   	; File Share Read/Write
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
  MOV R8, 120*3				; File Size is fixed to 120 bytes.
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
  
NESTED_END GreatMachine_CreateHiScores, _TEXT$00





;*********************************************************
;   GreatMachine_InitializeTrees
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_InitializeTrees, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV R10, 350

  XOR RDI, RDI
  XOR R8, R8
  LEA RDX, [TreeScrollData]
  LEA R9, [TreeScrollList]
@InitializeScrollList:

  MOV QWORD PTR [R9], 0
  LEA RAX, [RDX]
  MOV QWORD PTR [R9 + 8], RAX


  CMP RDI, 0
  JNE @TryTree2
  LEA RAX, [Tree1Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate
@TryTree2:
  CMP RDI, 1
  JNE @TryTree3
  LEA RAX, [Tree2Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate
@TryTree3:
  CMP RDI, 2
  JNE @DoTree4
  LEA RAX, [Tree3Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate

@DoTree4:
  XOR RDI, RDI
  LEA RAX, [Tree4Graphic]
  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

;  ADD R10, 45
  JMP @SkipIncRdi
@EndOfLoopUpdate:
  INC RDI
@SkipIncRdi:
  MOV SCROLLING_GIF.ImageInformation[RDX], RAX
  MOV SCROLLING_GIF.CurrentX[RDX], 1023
  
  MOV SCROLLING_GIF.XIncrement[RDX], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[RDX], ROAD_SCROLL_Y_INC
  ADD R9, 16
  ADD RDX, SIZE SCROLLING_GIF
  INC R8
  CMP R8, NUMBER_OF_TREE_SCROLLING
  JB @InitializeScrollList
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_InitializeTrees, _TEXT$00




;*********************************************************
;   GreatMachine_LoadAndCreatePlayerSprite
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadAndCreatePlayerSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET PlayerFirstCarGraphic
  MOV RCX, OFFSET PlayerStartCarImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  LEA RCX, [PlayerFirstCarConvert]
  LEA RDX, [PlayerFirstCarGraphic]
  MOV SPRITE_CONVERT.ImageInformationPtr[RCX], RDX
  LEA RDX, [PlayerSpriteBasicInformation]
  MOV SPRITE_CONVERT.SpriteBasicInformtionPtr[RCX], RDX
  MOV SPRITE_CONVERT.SpriteImageStart[RCX], 0
  MOV SPRITE_CONVERT.SpriteNumImages[RCX], 2
  MOV SPRITE_CONVERT.SpriteX[RCX], 0
  MOV SPRITE_CONVERT.SpriteY[RCX], 0
  MOV R8, [PlayerFirstCarGraphic.ImageWidth]
  MOV SPRITE_CONVERT.SpriteX2[RCX], R8
  MOV R8, [PlayerFirstCarGraphic.ImageHeight]
  MOV SPRITE_CONVERT.SpriteY2[RCX], R8
  DEBUG_FUNCTION_CALL GameEngine_ConvertImageToSprite
  LEA RAX, [PlayerSpriteBasicInformation]
  MOV [CurrentPlayerSprite], RAX

@FailureExit:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LoadAndCreatePlayerSprite, _TEXT$00







;*********************************************************
;   GreatMachine_SetupMemoryAllocations
;
;        Parameters: None
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SetupMemoryAllocations, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, LARGE_GAME_ALLOCATION
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
  CMP RAX, 0
  JE @Failure
  MOV [LargeMemoryAllocation], RAX
  MOV [LargeMemoryAllocationEnd], RAX
  ADD [LargeMemoryAllocationEnd],LARGE_GAME_ALLOCATION
  MOV [CurrentMemoryPtr], RAX
  MOV EAX, 1
@Failure:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SetupMemoryAllocations, _TEXT$00



;*********************************************************
;   GreatMachine_LoadingThread
;
;        Parameters: Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadingThread, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  ;
  ; Large Memory Allocation
  ;
  DEBUG_FUNCTION_CALL GreatMachine_SetupMemoryAllocations
  CMP RAX, 0
  JE @FailureExit
  
  ;
  ; Game Over Capture Screen; create a buffer
  ; as large as the screen to capture it.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SHL RAX, 2
  
  MOV [GameCaptureSize], RAX
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL GreatMachine_AllocateMemory
  CMP RAX, 0
  JE @FailureExit
  
  MOV [GameOverCaptureScreen], RAX
  
  ;
  ; Determine Hi Scores
  ;
  DEBUG_FUNCTION_CALL GreatMachine_SetupHiScores

  ;    
  ; Load the player sprites
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadAndCreatePlayerSprite
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the Level Name Graphics
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadLevelNameGraphics
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load The Icon Graphics
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadPanelIcons
  CMP RAX, 0
  JE @FailureExit


  ;
  ; Load the Tree Graphics and Initialize Trees
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadTreeGraphics
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_InitializeTrees
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the Background Graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadBackgroundGraphics
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the General Background Graphics for Screens (Menu, Credits, etc.)
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadGeneralScreenGraphics
  CMP RAX, 0
  JE @FailureExit  

  ;
  ; Load the Generic Car Graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadCarGraphics
  CMP RAX, 0
  JE @FailureExit 

  ;
  ; Load the Pedestrian/People Graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadPeopleGraphics
  CMP RAX, 0
  JE @FailureExit 

  ;
  ; Load Items and other support graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadItemsAndSupportGraphics
  CMP RAX, 0
  JE @FailureExit 

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CreateStarField

  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailureExit:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LoadingThread, _TEXT$00


;*********************************************************
;   GreatMachine_LoadTreeGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadTreeGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET Tree1Graphic
  MOV RCX, OFFSET Tree1Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree2Graphic
  MOV RCX, OFFSET Tree2Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree3Graphic
  MOV RCX, OFFSET Tree3Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree4Graphic
  MOV RCX, OFFSET Tree4Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadTreeGraphics, _TEXT$00


;*********************************************************
;   GreatMachine_LoadGeneralScreenGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGeneralScreenGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET GeneralGraphic
  MOV RCX, OFFSET GeneralImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET TitleGraphic
  MOV RCX, OFFSET GreatMachineTitle
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET MenuScreen
  MOV RCX, OFFSET MenuImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET IntroScreen
  MOV RCX, OFFSET IntroImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGeneralScreenGraphics, _TEXT$00


;*********************************************************
;   GreatMachine_LoadBackgroundGraphics
;
;        Parameters: Master Structure
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadBackgroundGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, OFFSET RoadGraphic
  MOV RCX, OFFSET RoadImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Road
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [RoadGraphic.ImageHeight]

  MOV [RoadScroll.CurrentX], 0
  MOV [RoadScroll.CurrentY], RAX
  MOV [RoadScroll.XIncrement], ROAD_SCROLL_X_INC
  MOV [RoadScroll.YIncrement], ROAD_SCROLL_Y_INC
  LEA RAX, [RoadGraphic]
  MOV [RoadScroll.ImageInformation], RAX

  MOV RDX, OFFSET MountainGraphic
  MOV RCX, OFFSET MountainImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Mountain
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [MountainGraphic.ImageHeight]
  SUB RAX, [RoadGraphic.ImageHeight]

  MOV [MountainScroll.CurrentX], 0
  MOV [MountainScroll.CurrentY], RAX
  MOV [MountainScroll.XIncrement], MOUNTAIN_SCROLL_X_INC
  MOV [MountainScroll.YIncrement], MOUNTAIN_SCROLL_Y_INC
  LEA RAX, [MountainGraphic]
  MOV [MountainScroll.ImageInformation], RAX

  MOV RDX, OFFSET SkyGraphic
  MOV RCX, OFFSET SkyImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Sky
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [SkyGraphic.ImageHeight]
  SUB RAX, [MountainGraphic.ImageHeight]
  SUB RAX, [RoadGraphic.ImageHeight]
  MOV [SkyScroll.CurrentX], 0
  MOV [SkyScroll.CurrentY], RAX
  MOV [SkyScroll.XIncrement], SKY_SCROLL_X_INC
  MOV [SkyScroll.YIncrement], SKY_SCROLL_Y_INC
  LEA RAX, [SkyGraphic]
  MOV [SkyScroll.ImageInformation], RAX


@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadBackgroundGraphics, _TEXT$00




;*********************************************************
;   GreatMachine_LoadCarGraphics
;
;        Parameters: Master Structure
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadCarGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  XOR RBX, RBX
  MOV R15, OFFSET GenericCarImageList
  MOV R14, OFFSET GenericCarScrollList
  MOV R13, OFFSET GenericCarSpriteList
  MOV R12, OFFSET GenericCarListPtr
@LoadCarGraphics:
  CMP RBX, NUMBER_OF_CARS             ; This way you can disable the cars by setting the equates to 0
  JE @CarsComplete
  INC RBX

ifdef USE_FILES
  MOV RCX, OFFSET GenericCarImage
  ADD RCX, 10
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '.'
  INC RCX
  MOV BYTE PTR [RCX], 'g'
  INC RCX
  MOV BYTE PTR [RCX], 'i'
  INC RCX
  MOV BYTE PTR [RCX], 'f'
  INC RCX
  MOV BYTE PTR [RCX], 0
else
  MOV RCX, OFFSET GenericCarImage
  ADD RCX, 11
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '_'
  INC RCX
  MOV BYTE PTR [RCX], 'G'
  INC RCX
  MOV BYTE PTR [RCX], 'I'
  INC RCX
  MOV BYTE PTR [RCX], 'F'
  INC RCX
  MOV BYTE PTR [RCX], 0
endif

  MOV RDX, R15                          ; Car Image List Entry
  MOV RCX, OFFSET GenericCarImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV SCROLLING_GIF.CurrentX[R14], 0
  MOV SCROLLING_GIF.CurrentY[R14], 0
  MOV SCROLLING_GIF.XIncrement[R14], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R14], ROAD_SCROLL_Y_INC
  MOV SCROLLING_GIF.ImageInformation[R14], R15

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteMaxVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteY[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpritePoints[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ScrollingPtr[R13], R14
  MOV SPECIAL_SPRITE_STRUCT.SpriteType[R13], SPRITE_TYPE_CAR
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteDeBounceRefresh[R13], 0

  LEA RAX, [GreatMachine_Car_CollisionNPC]
  MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R13], RAX

  LEA RAX, [GreatMachine_Car_Collision]
  MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R13], RAX

  LEA RAX, [GreateMachine_Car_OffScreen]
  MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R13], RAX

  MOV QWORD PTR [R12], R13

  ADD R12, 8
  ADD R13, SIZE SPECIAL_SPRITE_STRUCT
  ADD R14, SIZE SCROLLING_GIF
  ADD R15, SIZE IMAGE_INFORMATION
  JMP @LoadCarGraphics
@CarsComplete:
  MOV EAX, 1
@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadCarGraphics, _TEXT$00



;*********************************************************
;   GreatMachine_LoadPeopleGraphics
;
;        Parameters: Master Structure
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadPeopleGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  XOR RBX, RBX
  MOV R15, OFFSET GenericPersonImageList
  MOV R14, OFFSET GenericPersonScrollList
  MOV R13, OFFSET GenericPersonSpriteList
  MOV R12, OFFSET GenericPersonListPtr
@LoadPeopleGraphics:
  CMP RBX, NUMBER_OF_PEOPLE       ; This way you can disable the cars by setting the equates to 0
  JE @PeopleComplete
  INC RBX

ifdef USE_FILES
  MOV RCX, OFFSET GenericPersonImage
  ADD RCX, 6
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '.'
  INC RCX
  MOV BYTE PTR [RCX], 'g'
  INC RCX
  MOV BYTE PTR [RCX], 'i'
  INC RCX
  MOV BYTE PTR [RCX], 'f'
  INC RCX
  MOV BYTE PTR [RCX], 0
else
  MOV RCX, OFFSET GenericPersonImage
  ADD RCX, 6
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '_'
  INC RCX
  MOV BYTE PTR [RCX], 'G'
  INC RCX
  MOV BYTE PTR [RCX], 'I'
  INC RCX
  MOV BYTE PTR [RCX], 'F'
  INC RCX
  MOV BYTE PTR [RCX], 0
endif

  MOV RDX, R15                          ; Car Image List Entry
  MOV RCX, OFFSET GenericPersonImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV SCROLLING_GIF.CurrentX[R14], 0
  MOV SCROLLING_GIF.CurrentY[R14], 0
  MOV SCROLLING_GIF.XIncrement[R14], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R14], ROAD_SCROLL_Y_INC
  MOV SCROLLING_GIF.ImageInformation[R14], R15

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteMaxVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteY[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpritePoints[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ScrollingPtr[R13], R14
  MOV SPECIAL_SPRITE_STRUCT.SpriteType[R13], SPRITE_TYPE_PEDESTRIAN
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R13], 0

  LEA RAX, [GreatMachine_Pedestrian_CollisionNPC]
  MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R13], RAX

  LEA RAX, [GreatMachine_Pedestrian_Collision]
  MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R13], RAX

  LEA RAX, [GreateMachine_Pedestrian_OffScreen]
  MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R13], RAX

  MOV QWORD PTR [R12], R13

  ADD R12, 8
  ADD R13, SIZE SPECIAL_SPRITE_STRUCT
  ADD R14, SIZE SCROLLING_GIF
  ADD R15, SIZE IMAGE_INFORMATION
  JMP @LoadPeopleGraphics
@PeopleComplete:
  MOV EAX, 1
@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadPeopleGraphics, _TEXT$00





;*********************************************************
;   GreatMachine_LoadPanelIcons
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadPanelIcons, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET PanelIcon1Graphic
  MOV RCX, OFFSET PanelIcon1
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET PanelIcon2Graphic
  MOV RCX, OFFSET PanelIcon2
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET PanelIcon3Graphic
  MOV RCX, OFFSET PanelIcon3
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET PanelIcon4Graphic
  MOV RCX, OFFSET PanelIcon4
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit


@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadPanelIcons, _TEXT$00


;*********************************************************
;   GreatMachine_LoadLevelNameGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadLevelNameGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET LevelNameGraphic
  MOV RCX, OFFSET LevelNameImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelOneGraphic
  MOV RCX, OFFSET LevelOneImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelTwoGraphic
  MOV RCX, OFFSET LevelTwoImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelThreeGraphic
  MOV RCX, OFFSET LevelThreeImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelFourGraphic
  MOV RCX, OFFSET LevelFourImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadLevelNameGraphics, _TEXT$00


       
;*********************************************************
;   GreatMachine_LoadGraphicsImage
;
;        Parameters: Pointer to Image (Resource or File depending on USE_FILES define), Graphics Pointer
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGraphicsImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
        
ifdef USE_FILES
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
else
  DEBUG_FUNCTION_CALL GreatMachine_LoadGifResource
  MOV RCX, RAX
  MOV RDX, RDI
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
endif
  CMP RAX, 0
  JE @FailureExit

  MOV IMAGE_INFORMATION.StartX[RDI], 0
  MOV IMAGE_INFORMATION.StartY[RDI], 0
  MOV IMAGE_INFORMATION.InflateCountDown[RDI], 0
  MOV IMAGE_INFORMATION.InflateCountDownMax[RDI], 0
  PXOR XMM0, XMM0
  MOVSD IMAGE_INFORMATION.IncrementX[RDI], XMM0
  MOVSD IMAGE_INFORMATION.IncrementY[RDI], XMM0        

  MOV RAX, 1
@FailureExit:       
                       
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGraphicsImage, _TEXT$00         
          


;*********************************************************
;   GreatMachine_CreateStarField
;
;        Parameters: Master Context
;
;        Return Value: 
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CreateStarField, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, 1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @StarInit_Failed

  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @StarInit_Failed
  MOV [VirtualPallete], RAX
  

  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Soft3D_Init
  MOV [Soft3D], RAX
  TEST RAX, RAX
  JZ @StarInit_Failed


  LEA RCX, [WorldLocation]
  MOV TD_POINT.x[RCX], 0
  MOV TD_POINT.y[RCX], 0
  MOV TD_POINT.z[RCX], 0

  MOVSD xmm0, [View_Distance]
  MOVSD xmm1, xmm0
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_SetViewDistance

  XOR R12, R12

@PopulatePallete:
  MOV RAX, R12
  MOV AH, AL
  SHL RAX, 8
  MOV AL, AH

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  INC R12
  CMP R12, 256
  JB @PopulatePallete

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_CreateStars
@StarInit_Failed:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_CreateStarField, _TEXT$00  

;*********************************************************
;  GreatMachine_CreateStars
;
;        Parameters: Master Context
;          
;         Return: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CreateStars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX

  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, (SIZE STAR_FIELD_ENTRY * 1000)
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
  CMP RAX, 0
  JE @Failure

  MOV RDI, RAX
  MOV [StarEntryPtr], RAX
  XOR RSI, RSI

@Initialize_Stars:

  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.x[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RBX]
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

  DEBUG_FUNCTION_CALL Math_rand
  AND RAX, 3
  INC RAX
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Initialize_Stars

  MOV EAX, 1
@Failure:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CreateStars, _TEXT$00



;*********************************************************
;   GreatMachine_LoadGraphicsImage
;
;        Parameters: None
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadItemsAndSupportGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET CarSpinGraphic
  MOV RCX, OFFSET CarSpinImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RAX, OFFSET CarSpinGraphic
  MOV [CarSpinConvert.ImageInformationPtr], RAX
  MOV IMAGE_INFORMATION.ImageMaxFrames[RAX], 15

  MOV RAX, OFFSET CarSpinSprite
  MOV [CarSpinConvert.SpriteBasicInformtionPtr], RAX
  MOV [CarSpinConvert.SpriteBasicAllocated], 0
  MOV [CarSpinConvert.SpriteX], 0                   
  MOV [CarSpinConvert.SpriteY], 0      
  MOV RAX, [CarSpinGraphic.ImageWidth]
  MOV [CarSpinConvert.SpriteX2], RAX                  
  MOV RAX, [CarSpinGraphic.ImageHeight]
  MOV [CarSpinConvert.SpriteY2], RAX          
  MOV [CarSpinConvert.SpriteImageStart], 0          
  MOV [CarSpinConvert.SpriteNumImages], 6           

  MOV RCX, OFFSET CarSpinConvert
  DEBUG_FUNCTION_CALL GameEngine_ConvertImageToSprite
  CMP RAX, 0
  JE @FailureExit

  MOV [CarSpinSprite.SpriteMaxFrames], 25

  MOV RDX, OFFSET BoomGraphic
  MOV RCX, OFFSET BoomImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET PanelGraphic
  MOV RCX, OFFSET PanelImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the list of generic items
  ;
  XOR RBX, RBX
  MOV RSI, OFFSET GenericItemsImagePtr
  MOV RDI, OFFSET GenericItemsImageList
  MOV R14, OFFSET GenericItemsScrollList
  MOV R15, OFFSET GenericItemsList

@LoadGenericItems:
  CMP RBX, NUMBER_OF_GENERIC_ITEMS
  JE @ItemsLoadCompleted

  MOV RDX, RDI
  MOV RCX, [RSI]
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Items
  ;
  MOV SCROLLING_GIF.CurrentX[R14], 0
  MOV SCROLLING_GIF.CurrentY[R14], 0
  MOV SCROLLING_GIF.XIncrement[R14], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R14], ROAD_SCROLL_Y_INC
  MOV SCROLLING_GIF.ImageInformation[R14], RDI


  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteVelX[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteMaxVelX[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteX[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteY[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.SpritePoints[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ScrollingPtr[R15], R14
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R15], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R15], 0
  DEBUG_FUNCTION_CALL Math_Rand
  ADD R15, SIZE SPECIAL_SPRITE_STRUCT
  ADD R14, SIZE SCROLLING_GIF
  ADD RDI, SIZE IMAGE_INFORMATION
  ADD RSI, 8
  INC RBX
  JMP @LoadGenericItems
@ItemsLoadCompleted:

;
; Setup Specialized settings
;

   XOR RBX, RBX
   MOV R12, [FuelItemsList]
@SetupFuelItems:
   CMP RBX, NUMBER_OF_FUEL
   JE @FuelItemsComplete

   MOV SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_FUEL
   LEA RAX, [GreatMachine_Fuel_CollisionNPC]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R12], RAX

   LEA RAX, [GreatMachine_Fuel_Collision]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R12], RAX

   LEA RAX, [GreateMachine_Fuel_OffScreen]
   MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R12], RAX

   ADD R12, SIZE SPECIAL_SPRITE_STRUCT
   INC RBX
   JMP @SetupFuelItems
@FuelItemsComplete:

   XOR RBX, RBX
   MOV R12, OFFSET GenericItems_CarPart1
@SetupParts1:
   CMP RBX, NUMBER_OF_PARTS1
   JE @Parts1Complete

   MOV SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_PART1
   LEA RAX, [GreatMachine_Part1_CollisionNPC]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R12], RAX

   LEA RAX, [GreatMachine_Part1_Collision]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R12], RAX

   LEA RAX, [GreateMachine_Part1_OffScreen]
   MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R12], RAX


   ADD R12, SIZE SPECIAL_SPRITE_STRUCT
   INC RBX
   JMP @SetupParts1
@Parts1Complete:

   XOR RBX, RBX
   MOV R12, OFFSET GenericItems_CarPart2
@SetupParts2:
   CMP RBX, NUMBER_OF_PARTS2
   JE @Parts2Complete

   MOV SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_PART2
   LEA RAX, [GreatMachine_Part2_CollisionNPC]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R12], RAX

   LEA RAX, [GreatMachine_Part2_Collision]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R12], RAX

   LEA RAX, [GreateMachine_Part2_OffScreen]
   MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R12], RAX


   ADD R12, SIZE SPECIAL_SPRITE_STRUCT
   INC RBX
   JMP @SetupParts2
@Parts2Complete:

   XOR RBX, RBX
   MOV R12, OFFSET GenericItems_CarPart3
@SetupParts3:
   CMP RBX, NUMBER_OF_PARTS3
   JE @Parts3Complete

   MOV SPECIAL_SPRITE_STRUCT.SpriteType[R12], SPRITE_TYPE_PART3
   LEA RAX, [GreatMachine_Part3_CollisionNPC]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionNpc[R12], RAX

   LEA RAX, [GreatMachine_Part3_Collision]
   MOV SPECIAL_SPRITE_STRUCT.pfnCollisionPlayer[R12], RAX

   LEA RAX, [GreateMachine_Part3_OffScreen]
   MOV SPECIAL_SPRITE_STRUCT.pfnSpriteOffScreen[R12], RAX


   ADD R12, SIZE SPECIAL_SPRITE_STRUCT
   INC RBX
   JMP @SetupParts3
@Parts3Complete:

   MOV [GenericItems_ExtraLife.SpriteType], SPRITE_TYPE_EXTRA_LIFE
   LEA RAX, [GreatMachine_ExtraLife_CollisionNPC]
   MOV [GenericItems_ExtraLife.pfnCollisionNpc], RAX

   LEA RAX, [GreatMachine_ExtraLife_Collision]
   MOV [GenericItems_ExtraLife.pfnCollisionPlayer], RAX

   LEA RAX, [GreateMachine_ExtraLife_OffScreen]
   MOV [GenericItems_ExtraLife.pfnSpriteOffScreen], RAX
      
   MOV EAX, 1
@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadItemsAndSupportGraphics, _TEXT$00         
