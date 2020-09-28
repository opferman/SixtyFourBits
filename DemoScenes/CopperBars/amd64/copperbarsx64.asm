;*********************************************************
; Copper Bars Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include vpal_public.inc
include font_public.inc
include dbuffer_public.inc
include soft3d_public.inc
include audio_public.inc
include gif_public.inc
include gameengine_public.inc

;*********************************************************
; External APIs
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern LoadResource:proc
extern SizeofResource:proc
extern LockResource:proc
extern FindResourceA:proc
LMEM_ZEROINIT EQU <40h>
;*********************************************************
; Demo Structures
;*********************************************************
COPPERBARS_FIELD_ENTRY struct
   X              dq ?
   Y              dq ?
   StartColor     dw ?
   MinVelocity    dq ?
   MaxVelocity    dq ?
   Velocity       dq ?
COPPERBARS_FIELD_ENTRY ends


COLOR_BAR_STRUCT struct
   CurrentY               dq ?
   Velocity               dq ?
   CurrentYThreshold      dq ?
   MaxVelocity            dq ?
   TopColors              dq ?  ; Used for transparency if set
   BottomColors           dq ?
   ScratchColors          dq ?
COLOR_BAR_STRUCT ends

COLOR_DESCRIPTIONS_STRUCT struct
   StartingColorIndex     dq ?
   RedColorIncrement      db ?
   GreenColorIncrement    db ?
   BlueColorIncrement     db ?
   ColorLength            dq ?
   StartingColorValue     dd ?
   BooleanDitherUpAndDown db ?
COLOR_DESCRIPTIONS_STRUCT ends

SQUARE_TRCKER struct

  CurrentTopCornerX      dq ?
  CurrentTopCornerY      dq ?
  SquareVisibleAt00      dq ?
  CurrentIncrementX      dq ?
  CurrentDecayX          dq ?
  CurrentDecayXRefresh   dq ?
  CurrentIncrementY      dq ?
  CurrentDecayY          dq ?
  CurrentDecayYRefresh   dq ?

SQUARE_TRCKER ends

;*********************************************************
; Demo Constants
;*********************************************************
COLOR_DESCRIPTIONS_SIZE     EQU <22>
NUMBER_TOP_HORIZONTAL_BARS  EQU <3>
NUMBER_MID_HORIZONTAL_BARS  EQU <4>
HEIGHT_OF_HORIZONTAL_BARS   EQU <20>
THRESHOLD_UPPER             EQU <255-60>
THRESHOLD_LOWER             EQU <30>
MIDDLE_BACKGROUND           EQU <11>
TILE_IMAGE_PIXELS           EQU <10000>
THRESHOLD_LOW_MID           EQU <550>
THRESHOLD_HIGH_MID          EQU <300>

;*********************************************************
; Public Functions
;*********************************************************
public CopperBarsDemo_Init
public CopperBarsDemo_Demo
public CopperBarsDemo_Free


.DATA

  

  ColorDescriptions     COLOR_DESCRIPTIONS_STRUCT<1, 0, 0, 1, 255, 01h, 0>
  Middlebackground      COLOR_DESCRIPTIONS_STRUCT<300, 7, 2, 1, 30, 0160400h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<330, 6, 3, 1, 30, 0260A00h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<360, 6, 3, 0, 30, 0391005h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<390, 5, 3, 0, 30, 0392905h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<420, 4, 4, 0, 30, 0304005h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<450, 3, 5, 0, 30, 0304005h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<480, 3, 5, 1, 30, 02A4000h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<510, 3, 5, 2, 30, 0204000h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<540, 3, 5, 3, 30, 0104000h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<570, 3, 5, 4, 30, 02A4000h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<600, 2, 5, 5, 30, 02A4000h, 0>

  MiddleHorizontalBars  COLOR_DESCRIPTIONS_STRUCT<700, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3000, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3030, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3060, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3090, 0, 0, 10, 20, 044h, 1>

  TopHorizontalBars     COLOR_DESCRIPTIONS_STRUCT<900, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<1000, 15, 15, 15, 20, 0646464h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2000, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2030, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2060, 0, 17,  5, 20, 0005420h, 1>

  HoriztonalBarsTop     COLOR_BAR_STRUCT <5,  1, THRESHOLD_UPPER, 2, 900, 1000, 2000>
                        COLOR_BAR_STRUCT <40, 1, THRESHOLD_UPPER, 2, 900, 1000, 2030>
                        COLOR_BAR_STRUCT <70, 1, THRESHOLD_UPPER, 2, 900, 1000, 2060>

  HoriztonalBarsMid     COLOR_BAR_STRUCT <300,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3000>
                        COLOR_BAR_STRUCT <350,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3030>
                        COLOR_BAR_STRUCT <400,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3060>
                        COLOR_BAR_STRUCT <450,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3090>


  AudioFormat            db 01h, 00h, 02h, 00h, 044h, 0ach, 00h, 00h, 010h, 0b1h, 02h, 00h, 04h, 00h, 010h, 00h, 00h, 00h
  AudioVolume            dq 150
  AudioHandle            dq ?
  AudioDataId            dq ?
  AudioData              AUDIO_SOUND_DATA <?>
  AudioImage             db "AUDIODEMO", 0
  AudioType              db "AUDIO_TYPE", 0
  GifType                db "GIF_TYPE", 0
  GifImage               db "TILE", 0
  GifDataPtr             dq ?
  GifImageInformation    IMAGE_INFORMATION <?>
  GifPalBufPtr           dq ?

  SquareGrid             SQUARE_TRCKER <20, 10, 1, 3, 200, 200, -3, 250, 250>


  DoubleBuffer           dq ?
  VirtualPallete         dq ?
  CopperBarsVertOne      dq ?
  CopperBarsVertTwo      dq ?
  CopperBarsHorzTop      dq ?
  CopperBarsHorzBottom   dq ?
.CODE

;*********************************************************
;   CopperBarsDemo_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  MOV RSI, RCX

  MOV [VirtualPallete], 0
    
  MOV RDX, 2
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CopperInit_Failed

  MOV RCX, 65536
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @CopperInit_Failed
  MOV [VirtualPallete], RAX

  LEA RDI, [ColorDescriptions]
  XOR RBX, RBX
@CreateDitheringColors:  

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateColorDither

  ADD RDI, SIZE COLOR_DESCRIPTIONS_STRUCT
  INC RBX

  CMP RBX, COLOR_DESCRIPTIONS_SIZE
  JB @CreateDitheringColors

  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadAndStartAudio
  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadImages
    
  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CopperInit_Failed:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Init, _TEXT$00




;*********************************************************
;  CopperBarsDemo_LoadImages
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_LoadImages, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  LEA RCX, [GifImage]
  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadGifResource
  CMP RAX, 0
  JE @NotLoaded
  MOV [GifDataPtr], RAX

  LEA RDX, [GifImageInformation]
  MOV RCX, [GifDataPtr]
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory

  MOV RDX, TILE_IMAGE_PIXELS
  LEA RCX, [GifImageInformation]
  DEBUG_FUNCTION_CALL CopperBarsDemo_ConvertImageToPalImage

@NotLoaded:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_LoadImages, _TEXT$00




;*********************************************************
;  CopperBarsDemo_LoadAndStartAudio
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_LoadAndStartAudio, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

  LEA RCX, [AudioFormat]
  DEBUG_FUNCTION_CALL Audio_Init
  CMP RAX, 0
  JE @Audio_Failed
  MOV [AudioHandle], RAX

  LEA RDX, [AudioData]
  LEA RCX, [AudioImage]
  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadAudioResource

  LEA RDX, [AudioData]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_AddMusic
  MOV [AudioDataId], RAX

  MOV RDX, [AudioVolume]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_SetVolume

  MOV RDX, [AudioDataId]
  MOV RCX, [AudioHandle]
  DEBUG_FUNCTION_CALL Audio_PlayMusic
  MOV RAX, 1

@Audio_Failed:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_LoadAndStartAudio, _TEXT$00


;*********************************************************
;   CopperBarsDemo_LoadAudioResource
;
;        Parameters: Resource Name, Sound Data Structure
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_LoadAudioResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX

  MOV R8, OFFSET AudioType               ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA
  MOV RDX, RAX
  MOV R15, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL SizeofResource
  MOV AUDIO_SOUND_DATA.PcmDataSize[RDI], RAX

  MOV RDX, R15
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  MOV AUDIO_SOUND_DATA.PcmData[RDI], RAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END CopperBarsDemo_LoadAudioResource, _TEXT$00


;*********************************************************
;   CopperBarsDemo_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifType                 ; Resource Type
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

NESTED_END CopperBarsDemo_LoadGifResource, _TEXT$00



;*********************************************************
;   CopperBarsDemo_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

 ;
 ; Update the screen with the buffer
 ;  
  MOV RCX, [DoubleBuffer]
  MOV RDX, [VirtualPallete]
  MOV R8, DB_FLAG_CLEAR_BUFFER
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_ChangeDirections

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_MoveSquares

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_GenerateTopBackground

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_MiddleBackGround

  XOR RBX, RBX
  MOV R15, OFFSET HoriztonalBarsTop
@DrawBars:

  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarDemo_MoveTopHorzBars

  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarDemo_UpdateBarColorColors
  XOR R8, R8
  MOV RDX, R15
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DrawHorizBar

  ADD R15, SIZE COLOR_BAR_STRUCT
  INC RBX
  CMP RBX, NUMBER_TOP_HORIZONTAL_BARS
  JB @DrawBars

  MOV R15, OFFSET HoriztonalBarsMid
  XOR RBX, RBX
@DrawMidBars:

  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarDemo_MoveMidHorzBars

 ; MOV RCX, R15
 ; DEBUG_FUNCTION_CALL CopperBarDemo_UpdateBarColorColors
  MOV R8, 1
  MOV RDX, R15
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DrawHorizBar

  ADD R15, SIZE COLOR_BAR_STRUCT
  INC RBX
  CMP RBX, NUMBER_MID_HORIZONTAL_BARS
  JB @DrawMidBars
  

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DrawSquares
 
  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Demo, _TEXT$00



;*********************************************************
;  CopperBarsDemo_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO

 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Free, _TEXT$00



;*********************************************************
;  CopperBarsDemo_ConvertImageToPalImage
;
;        Parameters: Image Information, Start Pallete Number
;
;        Return: Image Buffer
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_ConvertImageToPalImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  MOV R15, RCX
  MOV RBX, RDX
  
  MOV RCX, IMAGE_INFORMATION.ImageWidth[R15]
  MOV RAX, IMAGE_INFORMATION.ImageHeight[R15]
  XOR RDX, RDX
  MUL RCX
  MOV R12, RAX
  SHL RAX, 1

  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [GifPalBufPtr], RAX
  CMP RAX, 0
  JE @AllocationError

  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[R15]
  MOV RDI, [GifPalBufPtr]
@CreateVPalBufferLoop:
  XOR R8, R8
  MOV EDX, DWORD PTR [RSI]
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_FindColorIndex
  CMP AX, 0FFFFh
  JNE @SetFoundIndex

  MOV R8D, DWORD PTR [RSI]
  MOV RDX, RBX
  MOV RCX,  [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex
  MOV RAX, RBX
  INC RBX
@SetFoundIndex:
  MOV WORD PTR [RDI], AX
  ADD RSI, 4
  ADD RDI, 2
  DEC R12
  JNZ @CreateVPalBufferLoop

@AllocationError:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_ConvertImageToPalImage, _TEXT$00




;*********************************************************
;  CopperBarDemo_GenerateTopBackground
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_GenerateTopBackground, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX
  MOV RDI, [DoubleBuffer]
  MOV R12, 1
@BackgroundTopPlot:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  MOV AX, R12W
  REP STOSW
  INC R12
  CMP R12, 256
  JB @BackgroundTopPlot
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_GenerateTopBackground, _TEXT$00

;*********************************************************
;  CopperBarDemo_MiddleBackGround
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MiddleBackGround, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RBX, 300
  XOR R10, R10
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, 256
  MUL RCX
  SHL RAX, 1
  ADD RDI, RAX
  XOR R9, R9
@DrawScanLines:
  XOR R11, R11
@DrawBackgroundBar:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RAX, RBX
  REP STOSW
  INC RBX
  INC R11
  CMP R11, 30
  JB @DrawBackgroundBar
  INC R9
  CMP R9, MIDDLE_BACKGROUND
  JB @DrawScanLines

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_MiddleBackGround, _TEXT$00


;*********************************************************
;  CopperBarDemo_UpdateBarColorColors
;
;        Parameters: Color Bar
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_UpdateBarColorColors, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JL @GoingUp

@GoingDown:
  MOV RAX, THRESHOLD_UPPER
  SUB RAX, COLOR_BAR_STRUCT.CurrentY[RSI]
  MOV RBX, COLOR_BAR_STRUCT.BottomColors[RSI]
  CMP RAX, 0
  JLE @JustUpdateDirectly
  MOV R12, RAX
  MOV R15, COLOR_BAR_STRUCT.ScratchColors[RSI]
  JMP @LoopAllIndexes
@GoingUp:
  MOV RAX, COLOR_BAR_STRUCT.CurrentY[RSI]
  SUB RAX, THRESHOLD_LOWER
  MOV RBX, COLOR_BAR_STRUCT.TopColors[RSI]
  CMP RAX, 0
  JLE @JustUpdateDirectly
  MOV R12, RAX
  XOR R13, R13
  MOV R15, COLOR_BAR_STRUCT.ScratchColors[RSI]
@LoopAllIndexes:  

  MOV R9, R15
  MOV R8, RBX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_MoveColorIndexes  

  INC RBX
  INC R15
  INC R13
  CMP R13, HEIGHT_OF_HORIZONTAL_BARS
  JB @LoopAllIndexes
  JMP @DoneUpdatingColors
     
@JustUpdateDirectly:
  MOV R9, 30
  MOV R8, COLOR_BAR_STRUCT.ScratchColors[RSI]
  MOV RDX, RBX
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_CopyIndexRange

@DoneUpdatingColors:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_UpdateBarColorColors, _TEXT$00







;*********************************************************
;  CopperBarDemo_CreateBarColor
;
;        Parameters: Color Description Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateColorDither, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

   CMP COLOR_DESCRIPTIONS_STRUCT.BooleanDitherUpAndDown[RCX], 0
   JE @OnlyOneWayDither

   DEBUG_FUNCTION_CALL CopperBarDemo_CreateColorDitherBothWays

   JMP @DoneCreatingDither
@OnlyOneWayDither:
   DEBUG_FUNCTION_CALL CopperBarDemo_CreateColorDitherOneWay
   
@DoneCreatingDither:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_CreateColorDither, _TEXT$00

;*********************************************************
;  CopperBarDemo_MoveTopHorzBars
;
;        Parameters: Color Description Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveTopHorzBars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JL @DoNegativeVelocity
  
  MOV RAX, COLOR_BAR_STRUCT.CurrentYThreshold[RSI]
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JB @SkipDecrementVelocity

  DEC COLOR_BAR_STRUCT.Velocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JNE @UpdateVelocity

  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1
  ;NEG COLOR_BAR_STRUCT.Velocity[RSI]
  ;NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
  ;MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_LOWER

@UpdateVelocity:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @DoAnotherCheck

@SkipDecrementVelocity:
  MOV RAX, COLOR_BAR_STRUCT.MaxVelocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], RAX
  JE @SkipIncrement
  INC COLOR_BAR_STRUCT.Velocity[RSI]
@SkipIncrement:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  ;JMP @CompleteUpdate
@DoAnotherCheck:
 
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], 255-30
  JL @Done

  MOV COLOR_BAR_STRUCT.CurrentY[RSI], 255-31
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1
  NEG COLOR_BAR_STRUCT.Velocity[RSI]
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_LOWER
  JMP @Done
  
@DoNegativeVelocity:

  MOV RAX, COLOR_BAR_STRUCT.CurrentYThreshold[RSI]
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JA @SkipDecrementVelocity2

  INC COLOR_BAR_STRUCT.Velocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JNE @UpdateVelocity2
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1

  NEG COLOR_BAR_STRUCT.Velocity[RSI]
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_UPPER

@UpdateVelocity2:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @CompleteUpdate

@SkipDecrementVelocity2:
  MOV RAX, COLOR_BAR_STRUCT.MaxVelocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], RAX
  JE @SkipDecrement
  DEC COLOR_BAR_STRUCT.Velocity[RSI]
@SkipDecrement:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @CompleteUpdate

@CompleteUpdate:
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], 0
  JG @SkipFixUp

  MOV COLOR_BAR_STRUCT.CurrentY[RSI], 1
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1
  CMP COLOR_BAR_STRUCT.MaxVelocity[RSI], 0
  JG @SkipNegate
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
@SkipNegate:
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_UPPER
@SkipFixUp:
@Done:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_MoveTopHorzBars, _TEXT$00



;*********************************************************
;  CopperBarDemo_MoveMidHorzBars
;
;        Parameters: Color bar Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveMidHorzBars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JL @DoNegativeVelocity
  
  MOV RAX, COLOR_BAR_STRUCT.CurrentYThreshold[RSI]
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JB @SkipDecrementVelocity

  DEC COLOR_BAR_STRUCT.Velocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JNE @UpdateVelocity

  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1

@UpdateVelocity:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @DoAnotherCheck

@SkipDecrementVelocity:
  MOV RAX, COLOR_BAR_STRUCT.MaxVelocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], RAX
  JE @SkipIncrement
  INC COLOR_BAR_STRUCT.Velocity[RSI]
@SkipIncrement:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  ;JMP @CompleteUpdate
@DoAnotherCheck:
 
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], 600-30
  JL @Done

  MOV COLOR_BAR_STRUCT.CurrentY[RSI], 600-31
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1
  NEG COLOR_BAR_STRUCT.Velocity[RSI]
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_HIGH_MID
  JMP @Done
  
@DoNegativeVelocity:

  MOV RAX, COLOR_BAR_STRUCT.CurrentYThreshold[RSI]
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JA @SkipDecrementVelocity2

  INC COLOR_BAR_STRUCT.Velocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], 0
  JNE @UpdateVelocity2
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1

  NEG COLOR_BAR_STRUCT.Velocity[RSI]
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_LOW_MID

@UpdateVelocity2:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @CompleteUpdate

@SkipDecrementVelocity2:
  MOV RAX, COLOR_BAR_STRUCT.MaxVelocity[RSI]
  CMP COLOR_BAR_STRUCT.Velocity[RSI], RAX
  JE @SkipDecrement
  DEC COLOR_BAR_STRUCT.Velocity[RSI]
@SkipDecrement:
  MOV RAX, COLOR_BAR_STRUCT.Velocity[RSI]
  ADD COLOR_BAR_STRUCT.CurrentY[RSI], RAX
  JMP @CompleteUpdate

@CompleteUpdate:
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], 257
  JG @SkipFixUp

  MOV COLOR_BAR_STRUCT.CurrentY[RSI], 258
  MOV COLOR_BAR_STRUCT.Velocity[RSI], 1
  CMP COLOR_BAR_STRUCT.MaxVelocity[RSI], 0
  JG @SkipNegate
  NEG COLOR_BAR_STRUCT.MaxVelocity[RSI]
@SkipNegate:
  MOV COLOR_BAR_STRUCT.CurrentYThreshold[RSI], THRESHOLD_LOW_MID
@SkipFixUp:
@Done:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_MoveMidHorzBars, _TEXT$00







;*********************************************************
;  CopperBarDemo_CreateColorDitherOneWay
;
;        Parameters: Color Description Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateColorDitherOneWay, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  XOR RDI, RDI
  MOV EBX, COLOR_DESCRIPTIONS_STRUCT.StartingColorValue[RSI]
@CreateColorDither:

   MOV R8, RBX
   MOV RDX, COLOR_DESCRIPTIONS_STRUCT.StartingColorIndex[RSI]
   ADD RDX, RDI
   MOV RCX, [VirtualPallete]
   DEBUG_FUNCTION_CALL VPal_SetColorIndex

   INC RDI
   CMP RDI, COLOR_DESCRIPTIONS_STRUCT.ColorLength[RSI]
   JE @DoneCreatingDither
   
   MOV RAX, RBX
   XOR RCX, RCX
   MOV CX, BX
   SHR RAX, 16
   ADD CL, COLOR_DESCRIPTIONS_STRUCT.BlueColorIncrement[RSI]
   ADD CH, COLOR_DESCRIPTIONS_STRUCT.GreenColorIncrement[RSI]
   ADD AL, COLOR_DESCRIPTIONS_STRUCT.RedColorIncrement[RSI]
   SHL RAX, 16
   MOV RBX, RCX
   OR RBX, RAX
   JMP @CreateColorDither

@DoneCreatingDither:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_CreateColorDitherOneWay, _TEXT$00



;*********************************************************
;  CopperBarDemo_CreateColorDitherBothWays
;
;        Parameters: Color Description Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_CreateColorDitherBothWays, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  XOR RDI, RDI
  MOV EBX, COLOR_DESCRIPTIONS_STRUCT.StartingColorValue[RSI]
@CreateColorDither:

   MOV R8, RBX
   MOV RDX, COLOR_DESCRIPTIONS_STRUCT.StartingColorIndex[RSI]
   ADD RDX, RDI
   MOV RCX, [VirtualPallete]
   DEBUG_FUNCTION_CALL VPal_SetColorIndex

   INC RDI
   MOV RAX, COLOR_DESCRIPTIONS_STRUCT.ColorLength[RSI]
   SHR RAX, 1
   CMP RDI, RAX
   JE @DoneCreatingDitherUp
   
   MOV RAX, RBX
   XOR RCX, RCX
   MOV CX, BX
   SHR RAX, 16
   ADD CL, COLOR_DESCRIPTIONS_STRUCT.BlueColorIncrement[RSI]
   ADD CH, COLOR_DESCRIPTIONS_STRUCT.GreenColorIncrement[RSI]
   ADD AL, COLOR_DESCRIPTIONS_STRUCT.RedColorIncrement[RSI]
   SHL RAX, 16
   MOV RBX, RCX
   OR RBX, RAX
   JMP @CreateColorDither

@DoneCreatingDitherUp:
@CreateColorDitherDown:

   MOV R8, RBX
   MOV RDX, COLOR_DESCRIPTIONS_STRUCT.StartingColorIndex[RSI]
   ADD RDX, RDI
   MOV RCX, [VirtualPallete]
   DEBUG_FUNCTION_CALL VPal_SetColorIndex

   INC RDI
   CMP RDI, COLOR_DESCRIPTIONS_STRUCT.ColorLength[RSI]
   JE @DoneCreatingDitherDown
   
   MOV RAX, RBX
   XOR RCX, RCX
   MOV CX, BX
   SHR RAX, 16
   SUB CL, COLOR_DESCRIPTIONS_STRUCT.BlueColorIncrement[RSI]
   SUB CH, COLOR_DESCRIPTIONS_STRUCT.GreenColorIncrement[RSI]
   SUB AL, COLOR_DESCRIPTIONS_STRUCT.RedColorIncrement[RSI]
   SHL RAX, 16
   MOV RBX, RCX
   OR RBX, RAX
   JMP @CreateColorDitherDown
@DoneCreatingDitherDown:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_CreateColorDitherBothWays, _TEXT$00



;*********************************************************
;  CopperBarDemo_DrawHorizBar
;
;        Parameters: MMaster Context, Horizontal Bar Structure, Transparent
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawHorizBar, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  MOV R15, RDX
  MOV R14, R8
  MOV R12, COLOR_BAR_STRUCT.ScratchColors[R15]  

  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, COLOR_BAR_STRUCT.CurrentY[R15]
  MUL R8
  SHL RAX, 1
  ADD RDI, RAX
  MOV R13, COLOR_BAR_STRUCT.TopColors[R15]
  XOR RBX, RBX
@GoingUp:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  XOR RDX, RDX
  MOV DX, WORD PTR[RDI]
  MOV RAX, R12
  REP STOSW
  CMP R14, 0
  JE @NoTransparentcy
  MOV R9, R12
  MOV R8, R13
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_Transparent
@NoTransparentcy:
  INC RBX
  INC R12
  INC R13
  CMP RBX, 10
  JB @GoingUp
  MOV R13, COLOR_BAR_STRUCT.TopColors[R15]
  XOR RBX, RBX
@GoingDown:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  XOR RDX, RDX
  MOV DX, WORD PTR[RDI]
  MOV RAX, R12
  REP STOSW
  CMP R14, 0
  JE @NoTransparentcy2
  MOV R9, R12
  MOV R8, R13
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_Transparent
@NoTransparentcy2:
  INC RBX
  INC R13
  INC R12
  CMP RBX, 10
  JB @GoingDown

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawHorizBar, _TEXT$00




;*********************************************************
;  CopperBarDemo_DrawTopSquares
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawTopSquares, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RCX
  XOR RAX, RAX
  MOV RDI, [DoubleBuffer]
  MOV RSI, [GifPalBufPtr]
@HeightLoop:
  XOR RDX, RDX
  XOR R8, R8
@WidthLoop:
  MOV CX, WORD PTR [RSI]
  MOV WORD PTR [RDI + RDX], CX
  ADD RSI, 2
  INC R8
  ADD RDX, 2
  CMP R8, [GifImageInformation.ImageWidth]
  JB @WidthLoop

  MOV R10, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SHL R10, 1
  ADD RDI, R10
  INC RAX
  CMP RAX, [GifImageInformation.ImageHeight]
  JB @HeightLoop

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawTopSquares, _TEXT$00


;*********************************************************
;  CopperBarDemo_DrawSquares
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawSquares, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RCX

  MOV R10, [SquareGrid.SquareVisibleAt00]       ; If the current location has a square on the far left side.
  MOV RDI, [DoubleBuffer]                       ; Current line 
  MOV R9, [SquareGrid.CurrentTopCornerY]        ; Start of Y for current line.

  XOR RDX, RDX
  MOV RAX, [GifImageInformation.ImageWidth]
  MOV RSI, [SquareGrid.CurrentTopCornerY]
  MUL RSI
  SHL RAX, 1
  MOV RDX, [GifPalBufPtr]
  ADD RDX, RAX

  XOR R13, R13                                  ; Count Scan Lines
@DrawTopGrid:
  CMP R10, 0
  JE @SetupSecondSquare
  MOV R11, [SquareGrid.CurrentTopCornerX]       ; Starting X  of the current line for the first square.
  MOV RSI, R11
  SHL RSI, 1
  ADD RSI, RDX
  XOR R14, R14
  XOR RAX, RAX
  JMP @ScanLine
@SetupSecondSquare:
  MOV R14, [GifImageInformation.ImageWidth]
  SUB R14, [SquareGrid.CurrentTopCornerX]
  MOV RAX, R14
  SHL RAX, 1
  MOV RSI, RDX
  XOR R11, R11

@ScanLine:
  ADD RDI, RAX
  MOV RCX, [GifImageInformation.ImageWidth]
  SUB RCX, R11
  LEA RAX, [RCX + R14]
  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  JB @OkToProceed
  SUB RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SUB RCX, RAX
@OkToProceed:
  ADD R14, RCX
  REP MOVSW
  MOV RAX, [GifImageInformation.ImageWidth]
  ADD RAX, R14
  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  JB @NoFixUp
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SUB RAX, R14
  SHL RAX, 1
  ADD RDI, RAX
@NoFixUp:
  MOV RAX, [GifImageInformation.ImageWidth]
  ADD R14, RAX
  SHL RAX, 1
  MOV RSI, RDX
  XOR R11, R11
  CMP R14, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  JB @ScanLine

  MOV RAX, [GifImageInformation.ImageWidth]
  SHL RAX, 1
  ADD RDX, RAX
  INC R9
  CMP R9, [GifImageInformation.ImageHeight]
  JB @SkipResetOfGifLines
  XOR R10, 1
  MOV RDX, [GifPalBufPtr]
  XOR R9, R9
@SkipResetOfGifLines: 
  INC R13
  CMP R13, 256
  JB @DrawTopGrid

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawSquares, _TEXT$00



;*********************************************************
;  CopperBarDemo_MoveSquares
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveSquares, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  
  MOV RAX, [SquareGrid.CurrentIncrementX]
  MOV R8, [SquareGrid.CurrentTopCornerX]
  ADD R8, RAX

  CMP R8, [GifImageInformation.ImageWidth]
  JL @CheckLess2
  SUB R8, [GifImageInformation.ImageWidth]
  XOR [SquareGrid.SquareVisibleAt00], 1
@CheckLess2:
  CMP R8, 0
  JG @CheckY
  MOV RAX, [GifImageInformation.ImageWidth]
  ADD RAX, R8
  MOV R8, RAX
  XOR [SquareGrid.SquareVisibleAt00], 1
@CheckY:
  MOV [SquareGrid.CurrentTopCornerX], R8  

  MOV RAX, [SquareGrid.CurrentIncrementY]
  MOV R8, [SquareGrid.CurrentTopCornerY]
  ADD R8, RAX

  CMP R8, [GifImageInformation.ImageHeight]
  JL @CheckLess
  SUB R8, [GifImageInformation.ImageHeight]
  XOR [SquareGrid.SquareVisibleAt00], 1
@CheckLess:
  CMP R8, 0
  JG @DoneWithY
  MOV RAX, [GifImageInformation.ImageHeight]
  ADD RAX, R8
  MOV R8, RAX
  XOR [SquareGrid.SquareVisibleAt00], 1
@DoneWithY:
  MOV [SquareGrid.CurrentTopCornerY], R8  


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_MoveSquares, _TEXT$00


;*********************************************************
;  CopperBarDemo_ChangeDirections
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_ChangeDirections, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  DEC [SquareGrid.CurrentDecayX]
  JZ @DecayXExpire

  MOV RAX, [SquareGrid.CurrentIncrementX]
  MOV RCX, -1
  CMP RAX, 0
  JG @SkipNegate
  NEG RAX
  MOV RCX, 1
@SkipNegate:
  CMP RAX, [SquareGrid.CurrentDecayX] 
  JNE @GoToY
  JMP @GoToY
@DecayXExpire:
  NEG [SquareGrid.CurrentIncrementX]
  MOV RAX, [SquareGrid.CurrentDecayXRefresh]
  MOV [SquareGrid.CurrentDecayX], RAX
  ; TBD

@GoToY:
  DEC [SquareGrid.CurrentDecayY]
  JZ @DecayYExpire

  MOV RAX, [SquareGrid.CurrentIncrementY]
  MOV RCX, -1
  CMP RAX, 0
  JG @SkipNegate2
  NEG RAX
  MOV RCX, 1
@SkipNegate2:
  CMP RAX, [SquareGrid.CurrentDecayY] 
  JNE @Done
  JMP @Done
  ; TBD
@DecayYExpire:
  NEG [SquareGrid.CurrentIncrementY]
  MOV RAX, [SquareGrid.CurrentDecayYRefresh]
  MOV [SquareGrid.CurrentDecayY], RAX

@Done:


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_ChangeDirections, _TEXT$00


END
