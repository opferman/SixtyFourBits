;*********************************************************
; Copper Bars Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2017
;
;     Redone to look like Kukoo2 in September 2020.
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
extern cos:proc
extern sin:proc

LMEM_ZEROINIT EQU <40h>
;*********************************************************
; Demo Structures
;*********************************************************
COPPERBARS_FIELD_ENTRY struct
   X              dq ?
   Y              dq ?
   Bounds         dq ?
   StartColor     dw ?
   MinVelocity    dq ?
   MaxVelocity    dq ?
   Velocity       dq ?
   LeftWall       dq ?
   RightWall      dq ?
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


DEMO_TEXT_STRUCT struct
   BetweenCharacters       dq ?
   CurrentIndex            dq ?
   StartBitIndex           dq ?
   String                  dq ?
   FontScale               dq ?
   CenterYorX              dq ?
   WaveScale               dq ?
DEMO_TEXT_STRUCT ends



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

WAVE_TRACKER struct
  WaveVelocity         dq ?
  WaveThetaAddition    dq ?
  WaveCenter           dq ?
  WaveCenterVelocity   dq ?
  WaveRange            dq ?
  WaveRangeVelocity    dq ?
WAVE_TRACKER ends

;*********************************************************
; Demo Constants
;*********************************************************
COLOR_DESCRIPTIONS_SIZE       EQU <38>
NUMBER_TOP_HORIZONTAL_BARS    EQU <3>
NUMBER_MID_HORIZONTAL_BARS    EQU <4>
HEIGHT_OF_HORIZONTAL_BARS     EQU <20>
THRESHOLD_UPPER               EQU <255-60>
THRESHOLD_LOWER               EQU <30>
MIDDLE_BACKGROUND             EQU <11>
TILE_IMAGE_PIXELS             EQU <10000>
THRESHOLD_LOW_MID             EQU <540>
THRESHOLD_HIGH_MID            EQU <300>
NUMBER_OF_VERTICLE_BARS       EQU <300/2>
VERTICLE_BAR_START            EQU <255>
VERTICLE_BAR_END              EQU <586>
LEFT_VERT_WALL                EQU <20>
RIGHT_VERT_WALL               EQU <1024 - 20>
STARTING_VELOCITY             EQU <10>
START_OF_VERTICLE_BARS_COLOR  EQU <4000>
LAST_COLOR_INDEX_VERTICLE     EQU <START_OF_VERTICLE_BARS_COLOR + (30*14)>
MAX_VELOCITY                  EQU <15>
MIN_VELOCITY                  EQU <8>
TRANSPARENT_TILE_1_COLOR      EQU <01a1a1ah>
TRANSPARENT_TILE_2_COLOR      EQU <0h>
TRANSPARENT_TILE_3_COLOR      EQU <0a2c380h>

FIRE_START_Y                  EQU <VERTICLE_BAR_END - (FIRE_HEIGHT-2)>
FIRE_WIDTH                    EQU <1024>
FIRE_HEIGHT                   EQU <330>
MAX_FIRE_INDEX                EQU <256>
TRANSPARENT_TILE_COLOR        EQU <0h>

COPPER_BARS_CENTER_LOW        EQU <200>
COPPER_BARS_CENTER_HIGH       EQU <512>
COPPER_BARS_RANGE_LOW         EQU <80>
COPPER_BARS_RANGE_HIGH        EQU <350>

FIRE_FONT_HEIGHT_SIZE_PER_LINE  EQU <8>
FIRE_FONT_WIDTH_SIZE            EQU <8>

FIRE_START_COUNT              EQU <500>
;*********************************************************
; Public Functions
;*********************************************************
public CopperBarsDemo_Init
public CopperBarsDemo_Demo
public CopperBarsDemo_Free


.DATA

 FirePalette       db  0h, 0h, 0h    , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  0h, 0h, 00h , 0h
                   db  2Ah, 0Bh, 02h , 0h
                   db  2Bh, 0Bh, 02h , 0h
                   db  2Ch, 0Ch, 02h , 0h
                   db  2Dh, 0Ch, 02h , 0h
                   db  2Eh, 0Dh, 02h , 0h
                   db  2Fh, 0Dh, 02h , 0h
                   db  2Fh, 0Dh, 03h , 0h
                   db  30h, 0Eh, 03h , 0h
                   db  31h, 0Eh, 03h , 0h
                   db  32h, 0Fh, 03h , 0h
                   db  33h, 0Fh, 03h , 0h
                   db  34h, 10h, 03h , 0h
                   db  35h, 10h, 03h , 0h
                   db  36h, 11h, 03h , 0h
                   db  37h, 11h, 03h , 0h
                   db  38h, 11h, 03h , 0h
                   db  39h, 12h, 03h , 0h
                   db  3Ah, 12h, 03h , 0h
                   db  3Ah, 13h, 04h , 0h
                   db  3Bh, 13h, 04h , 0h
                   db  3Ch, 14h, 04h , 0h
                   db  3Dh, 14h, 04h , 0h
                   db  3Eh, 15h, 04h , 0h
                   db  3Fh, 15h, 04h , 0h
                   db  3Fh, 15h, 04h , 0h
                   db  3Fh, 16h, 04h , 0h
                   db  3Fh, 17h, 04h , 0h
                   db  3Fh, 17h, 04h , 0h
                   db  3Fh, 18h, 05h , 0h
                   db  3Fh, 19h, 05h , 0h
                   db  3Fh, 19h, 05h , 0h
                   db  3Fh, 1Ah, 05h , 0h
                   db  3Fh, 1Bh, 05h , 0h
                   db  3Fh, 1Bh, 05h , 0h
                   db  3Fh, 1Ch, 05h , 0h
                   db  3Fh, 1Dh, 05h , 0h
                   db  3Fh, 1Dh, 06h , 0h
                   db  3Fh, 1Eh, 06h , 0h
                   db  3Fh, 1Fh, 06h , 0h
                   db  3Fh, 1Fh, 06h , 0h
                   db  3Fh, 20h, 06h , 0h
                   db  3Fh, 20h, 06h , 0h
                   db  3Fh, 21h, 06h , 0h
                   db  3Fh, 22h, 06h , 0h
                   db  3Fh, 22h, 07h , 0h
                   db  3Fh, 23h, 07h , 0h
                   db  3Fh, 24h, 07h , 0h
                   db  3Fh, 24h, 07h , 0h
                   db  3Fh, 25h, 07h , 0h
                   db  3Fh, 26h, 07h , 0h
                   db  3Fh, 26h, 07h , 0h
                   db  3Fh, 27h, 07h , 0h
                   db  3Fh, 28h, 08h , 0h
                   db  3Fh, 28h, 08h , 0h
                   db  3Fh, 29h, 08h , 0h
                   db  3Fh, 2Ah, 08h , 0h
                   db  3Fh, 2Ah, 08h , 0h
                   db  3Fh, 2Bh, 08h , 0h
                   db  3Fh, 2Ch, 08h , 0h
                   db  3Fh, 2Ch, 08h , 0h
                   db  3Fh, 2Dh, 09h , 0h
                   db  3Fh, 2Eh, 09h , 0h
                   db  3Fh, 2Eh, 09h , 0h
                   db  3Fh, 2Fh, 09h , 0h
                   db  3Fh, 30h, 09h , 0h
                   db  3Fh, 30h, 09h , 0h
                   db  3Fh, 31h, 09h , 0h
                   db  3Fh, 32h, 09h , 0h
                   db  3Fh, 32h, 0Ah , 0h
                   db  3Fh, 33h, 0Ah , 0h
                   db  3Fh, 34h, 0Ah , 0h
                   db  3Fh, 34h, 0Ah , 0h
                   db  3Fh, 35h, 0Ah , 0h
                   db  3Fh, 36h, 0Ah , 0h
                   db  3Fh, 36h, 0Ah , 0h
                   db  3Fh, 37h, 0Ah , 0h
                   db  3Fh, 38h, 0Bh , 0h
                   db  3Fh, 38h, 0Bh , 0h
                   db  3Fh, 39h, 0Bh , 0h
                   db  3Fh, 3Ah, 0Bh , 0h
                   db  3Fh, 3Ah, 0Bh , 0h
                   db  3Fh, 3Bh, 0Bh , 0h
                   db  3Fh, 3Ch, 0Bh , 0h
                   db  3Fh, 3Ch, 0Bh , 0h
                   db  3Fh, 3Dh, 0Ch , 0h
                   db  3Fh, 3Eh, 0Ch , 0h
                   db  3Fh, 3Eh, 0Ch , 0h
                   db  3Fh, 3Fh, 0Ch , 0h
                   db  3Fh, 3Fh, 0Ch , 0h
                   db  3Fh, 3Fh, 0Dh , 0h
                   db  3Fh, 3Fh, 0Dh , 0h
                   db  3Fh, 3Fh, 0Eh , 0h
                   db  3Fh, 3Fh, 0Eh , 0h
                   db  3Fh, 3Fh, 0Fh , 0h
                   db  3Fh, 3Fh, 0Fh , 0h
                   db  3Fh, 3Fh, 10h , 0h
                   db  3Fh, 3Fh, 10h , 0h
                   db  3Fh, 3Fh, 11h , 0h
                   db  3Fh, 3Fh, 11h , 0h
                   db  3Fh, 3Fh, 12h , 0h
                   db  3Fh, 3Fh, 12h , 0h
                   db  3Fh, 3Fh, 13h , 0h
                   db  3Fh, 3Fh, 14h , 0h
                   db  3Fh, 3Fh, 14h , 0h
                   db  3Fh, 3Fh, 15h , 0h
                   db  3Fh, 3Fh, 15h , 0h
                   db  3Fh, 3Fh, 16h , 0h
                   db  3Fh, 3Fh, 16h , 0h
                   db  3Fh, 3Fh, 17h , 0h
                   db  3Fh, 3Fh, 17h , 0h
                   db  3Fh, 3Fh, 18h , 0h
                   db  3Fh, 3Fh, 18h , 0h
                   db  3Fh, 3Fh, 19h , 0h
                   db  3Fh, 3Fh, 19h , 0h
                   db  3Fh, 3Fh, 1Ah , 0h
                   db  3Fh, 3Fh, 1Ah , 0h
                   db  3Fh, 3Fh, 1Bh , 0h
                   db  3Fh, 3Fh, 1Ch , 0h
                   db  3Fh, 3Fh, 1Ch , 0h
                   db  3Fh, 3Fh, 1Dh , 0h
                   db  3Fh, 3Fh, 1Dh , 0h
                   db  3Fh, 3Fh, 1Eh , 0h
                   db  3Fh, 3Fh, 1Eh , 0h
                   db  3Fh, 3Fh, 1Fh , 0h
                   db  3Fh, 3Fh, 1Fh , 0h
                   db  3Fh, 3Fh, 20h , 0h
                   db  3Fh, 3Fh, 20h , 0h
                   db  3Fh, 3Fh, 21h , 0h
                   db  3Fh, 3Fh, 21h , 0h
                   db  3Fh, 3Fh, 22h , 0h
                   db  3Fh, 3Fh, 23h , 0h
                   db  3Fh, 3Fh, 23h , 0h
                   db  3Fh, 3Fh, 24h , 0h
                   db  3Fh, 3Fh, 24h , 0h
                   db  3Fh, 3Fh, 25h , 0h
                   db  3Fh, 3Fh, 25h , 0h
                   db  3Fh, 3Fh, 26h , 0h
                   db  3Fh, 3Fh, 26h , 0h
                   db  3Fh, 3Fh, 27h , 0h
                   db  3Fh, 3Fh, 27h , 0h
                   db  3Fh, 3Fh, 28h , 0h
                   db  3Fh, 3Fh, 28h , 0h
                   db  3Fh, 3Fh, 29h , 0h
                   db  3Fh, 3Fh, 2Ah , 0h
                   db  3Fh, 3Fh, 2Ah , 0h
                   db  3Fh, 3Fh, 2Bh , 0h
                   db  3Fh, 3Fh, 2Bh , 0h
                   db  3Fh, 3Fh, 2Ch , 0h
                   db  3Fh, 3Fh, 2Ch , 0h
                   db  3Fh, 3Fh, 2Dh , 0h
                   db  3Fh, 3Fh, 2Dh , 0h
                   db  3Fh, 3Fh, 2Eh , 0h
                   db  3Fh, 3Fh, 2Eh , 0h
                   db  3Fh, 3Fh, 2Fh , 0h
                   db  3Fh, 3Fh, 2Fh , 0h
                   db  3Fh, 3Fh, 30h , 0h
                   db  3Fh, 3Fh, 31h , 0h
                   db  3Fh, 3Fh, 31h , 0h
                   db  3Fh, 3Fh, 32h , 0h
                   db  3Fh, 3Fh, 32h , 0h
                   db  3Fh, 3Fh, 33h , 0h
                   db  3Fh, 3Fh, 33h , 0h
                   db  3Fh, 3Fh, 34h , 0h
                   db  3Fh, 3Fh, 34h , 0h
                   db  3Fh, 3Fh, 35h , 0h
                   db  3Fh, 3Fh, 35h , 0h
                   db  3Fh, 3Fh, 36h , 0h
                   db  3Fh, 3Fh, 36h , 0h
                   db  3Fh, 3Fh, 37h , 0h
                   db  3Fh, 3Fh, 37h , 0h
                   db  3Fh, 3Fh, 38h , 0h
                   db  3Fh, 3Fh, 39h , 0h
                   db  3Fh, 3Fh, 39h , 0h
                   db  3Fh, 3Fh, 3Ah , 0h
                   db  3Fh, 3Fh, 3Ah , 0h
                   db  3Fh, 3Fh, 3Bh , 0h
                   db  3Fh, 3Fh, 3Bh , 0h
                   db  3Fh, 3Fh, 3Ch , 0h
                   db  3Fh, 3Fh, 3Ch , 0h
                   db  3Fh, 3Fh, 3Dh , 0h
                   db  3Fh, 3Fh, 3Dh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h                                                         
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h  
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Dh , 0h
                   db  3Fh, 3Fh, 3Dh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h                                                         
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h  
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Eh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h   
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h
                   db  3Fh, 3Fh, 3Fh , 0h

  ColorDescriptions     COLOR_DESCRIPTIONS_STRUCT<1, 0, 0, 1, 255, 01h, 0>
                        COLOR_DESCRIPTIONS_STRUCT<256, 3, 2, -1, 44, 00101FFh, 0>
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
                        COLOR_DESCRIPTIONS_STRUCT<600, 2, 5, 5, 30, 02A4000h, 0>  ; 13

  MiddleHorizontalBars  COLOR_DESCRIPTIONS_STRUCT<700, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3000, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3030, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3060, 0, 0, 10, 20, 044h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<3090, 0, 0, 10, 20, 044h, 1> ; 5

  TopHorizontalBars     COLOR_DESCRIPTIONS_STRUCT<900, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<1000, 15, 15, 15, 20, 0646464h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2000, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2030, 0, 17,  5, 20, 0005420h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<2060, 0, 17,  5, 20, 0005420h, 1> ; 5

  VerticleBarsColors    COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR, 5, 5, 5, 20, 0CBC13Dh, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + 30, 5, 5, 5, 20, 0ABA130h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*2), 5, 5, 5, 20, 08B813Dh, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*3), 5, 5, 5, 20, 080712Dh, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*4), 5, 5, 5, 20, 0D23333h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*5), 5, 5, 5, 20, 0D37373h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*6), 5, 5, 5, 20, 0B35353h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*7), 5, 5, 5, 20, 06C762Eh, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*8), 5, 5, 5, 20, 0C3CC1B0h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*9), 5, 5, 5, 20, 07F8081h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*10), 5, 5, 5, 20, 09390BEh, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*11), 5, 5, 5, 20, 02F29C4h, 1>                        
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*12), 5, 5, 5, 20, 082875h, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*13), 5, 5, 5, 20, 066009Ch, 1>
                        COLOR_DESCRIPTIONS_STRUCT<START_OF_VERTICLE_BARS_COLOR + (30*14), 5, 5, 5, 20, 049619Ah, 1> ; 15
  

  HoriztonalBarsTop     COLOR_BAR_STRUCT <10, 1, THRESHOLD_UPPER, 2, 900, 1000, 2000>
                        COLOR_BAR_STRUCT <40, 1, THRESHOLD_UPPER, 2, 900, 1000, 2030>
                        COLOR_BAR_STRUCT <70, 1, THRESHOLD_UPPER, 2, 900, 1000, 2060>

  HoriztonalBarsMid     COLOR_BAR_STRUCT <300,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3000>
                        COLOR_BAR_STRUCT <330,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3030>
                        COLOR_BAR_STRUCT <360,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3060>
                        COLOR_BAR_STRUCT <380,  1, THRESHOLD_LOW_MID, 2, 700, 0, 3090>

  PureWord               db "Pure", 0
  AssemblyWord           db "Assembly", 0
  CodedBy                db "Coded By", 0
  MyName                 db "Toby Opferman", 0
  Tribute                db "A Tribute", 0
  Demo                   db "to the Demos", 0
  Ninties                db "of the 1990s", 0

  CurrentFireWordPtr     dq OFFSET PureAssembly
  PureAssembly           dw 382, 250
                         dq OFFSET PureWord
                         dw 257, 250
                         dq OFFSET AssemblyWord
                         dw 257, 250
                         dq OFFSET CodedBy
                         dw 100, 250
                         dq OFFSET MyName
                         dw 240, 250
                         dq OFFSET Tribute
                         dw 110, 250
                         dq OFFSET Demo
                         dw 110, 250
                         dq OFFSET Ninties
                         dw 0, 0
                         dq OFFSET PureAssembly

  DemoFrameCounter       dq 0

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

  DISPLAY_FIRE_WORD       dq 800
  FLASH_TO_BOLD_START     dq 1000
  BOLD_START              dq 1050
  FLASH_TO_LIGHT_START    dq 1500
  LIGHT_START             dq 1550
  FLASH_TO_SOLID_START    dq 2000
  SOLID_START             dq 2050

  SquareGrid             SQUARE_TRCKER <20, 10, 1, 3, 200, 200, -3, 250, 250>
  Transparent            dq 1
  PaletteArray           dq ?
  DoubleBuffer           dq ?
  FireDoubleBuffer       dq ?
  VirtualPalette         dq ?
  CopperBarsVertOne      dq ?
  CopperBarsVertTwo      dq ?
  CopperBarsVertOneHead  dq ?
  CopperBarsVertTwoHead  dq ?
  
  CopperBarsOneWave      WAVE_TRACKER <4, 0, 512, 0, 300, 5>
  CopperBarsTwoWave      WAVE_TRACKER <4, 180, 512, 0, 300, 5>
  PI                     mmword 3.14
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

  MOV [VirtualPalette], 0
    
  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CopperInit_Failed

  MOV RDX, FIRE_WIDTH * FIRE_HEIGHT * 2
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  MOV [FireDoubleBuffer], RAX
  TEST RAX, RAX
  JZ @CopperInit_Failed


  MOV RCX, 65536
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @CopperInit_Failed
  MOV [VirtualPalette], RAX

  MOV RCX, RAX
  DEBUG_FUNCTION_CALL VPal_DirectAccess
  MOV [PaletteArray], RAX


  LEA RDI, [ColorDescriptions]
  XOR RBX, RBX
@CreateDitheringColors:  

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_CreateColorDither

  ADD RDI, SIZE COLOR_DESCRIPTIONS_STRUCT
  INC RBX

  CMP RBX, COLOR_DESCRIPTIONS_SIZE
  JB @CreateDitheringColors

  DEBUG_FUNCTION_CALL CopperBarsDemo_SetupVerticleBars

  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadImages

  DEBUG_FUNCTION_CALL CopperBarsDemo_LoadAndStartAudio
  
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

  ;MOV RDX, TILE_IMAGE_PIXELS
  ;LEA RCX, [GifImageInformation]
  ;DEBUG_FUNCTION_CALL CopperBarsDemo_ConvertImageToPalImage

@NotLoaded:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_LoadImages, _TEXT$00




;*********************************************************
;  CopperBarsDemo_SetupVerticleBars
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_SetupVerticleBars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RDX, ((SIZE COPPERBARS_FIELD_ENTRY) * NUMBER_OF_VERTICLE_BARS)
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JE @FailedToAllocate

  MOV [CopperBarsVertOne], RAX

  MOV RDX, ((SIZE COPPERBARS_FIELD_ENTRY) * NUMBER_OF_VERTICLE_BARS)
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JE @FailedToAllocate

  MOV [CopperBarsVertTwo], RAX
  
  MOV R9, (1024 / 2 - 100)
  MOV R8, START_OF_VERTICLE_BARS_COLOR
  MOV RDX, NUMBER_OF_VERTICLE_BARS
  MOV RCX, [CopperBarsVertOne]
  DEBUG_FUNCTION_CALL CopperBarsDemo_InitializeVerticleBars
  MOV [CopperBarsVertOneHead], RAX

  MOV R9, (1024 / 2 + 100)
  MOV R8, START_OF_VERTICLE_BARS_COLOR + (30*8)
  MOV RDX, NUMBER_OF_VERTICLE_BARS
  MOV RCX, [CopperBarsVertTwo]
  DEBUG_FUNCTION_CALL CopperBarsDemo_InitializeVerticleBars
  MOV [CopperBarsVertTwoHead], RAX

@FailedToAllocate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_SetupVerticleBars, _TEXT$00


;*********************************************************
;  CopperBarsDemo_InitializeVerticleBars
;
;        Parameters: CopperBar List, Number of bars, Starting Color Index, Starting X
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_InitializeVerticleBars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, 20
  MOV R10, 3
  MOV RBX, 5
  MOV R11, VERTICLE_BAR_START
  CMP R8, START_OF_VERTICLE_BARS_COLOR
  JE @Initialize
  NEG R10
  NEG RBX
@Initialize:
  MOV COPPERBARS_FIELD_ENTRY.X[RCX], R9
  MOV COPPERBARS_FIELD_ENTRY.Y[RCX], R11
  MOV COPPERBARS_FIELD_ENTRY.StartColor[RCX], R8W
  MOV COPPERBARS_FIELD_ENTRY.Bounds[RCX], RSI
  MOV COPPERBARS_FIELD_ENTRY.LeftWall[RCX], LEFT_VERT_WALL
  MOV COPPERBARS_FIELD_ENTRY.RightWall[RCX], RIGHT_VERT_WALL
  ADD R11, 2
  ADD R9, R10

  CMP R9, RIGHT_VERT_WALL
  JB @CheckOtherWall
  MOV R9, RIGHT_VERT_WALL
  DEC R9
  NEG R10
  NEG RBX
@CheckOtherWall:
  CMP R9, LEFT_VERT_WALL
  JA @ContinueGoing
  MOV R9, LEFT_VERT_WALL
  INC R9
  NEG R10
  NEG RBX

@ContinueGoing:
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RCX],RBX
  MOV COPPERBARS_FIELD_ENTRY.MaxVelocity[RCX], MAX_VELOCITY
  MOV COPPERBARS_FIELD_ENTRY.MinVelocity[RCX], MIN_VELOCITY

  ADD R8, 30
  CMP R8, LAST_COLOR_INDEX_VERTICLE
  JLE @SkipWrapAround
  MOV R8, START_OF_VERTICLE_BARS_COLOR
@SkipWrapAround:
  MOV RAX, RCX
  ADD RCX, SIZE COPPERBARS_FIELD_ENTRY
  DEC RDX
  JNZ @Initialize
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_InitializeVerticleBars, _TEXT$00


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
  INC [DemoFrameCounter]
  ;CMP [DemoFrameCounter], 5000
  JMP @NoMelt
  JB @NoMelt

  MOV RCX, [DoubleBuffer]
  ;MOV RDX, [VirtualPalette]
  XOR RDX, RDX
  XOR R8, R8
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

;  TEST [ScreenMelt], 03h
  JNZ @ExitFunction

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_ScreenMelt

  JMP @ExitFunction
@NoMelt:

 ;
 ; Update the screen with the buffer
 ;  
  MOV RCX, [DoubleBuffer]
  ;MOV RDX, [VirtualPalette]
  XOR RDX, RDX
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

  CMP [DemoFrameCounter], FIRE_START_COUNT
  JB @FireNoActivated

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_FeedTheFire

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_RandomFireball

  MOV RAX, [DISPLAY_FIRE_WORD]
  CMP [DemoFrameCounter], RAX
  JNE @SkipFireWord
  XOR R8, R8
  MOV RDX, R8

  MOV R9, [CurrentFireWordPtr]
  MOV R8W, WORD PTR [R9 + 2]
  MOV DX, WORD PTR [R9]
  MOV R9, QWORD PTR [R9 + 4]
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DisplayFireWord

  MOV R9, [CurrentFireWordPtr]
  ADD R9, 2 + 2 + 8
  MOV [CurrentFireWordPtr], R9
  ADD [DISPLAY_FIRE_WORD], 50
  CMP WORD PTR [R9], 0
  JNE @SkipWordUpdate

  ADD [DISPLAY_FIRE_WORD], 800
  MOV R9, QWORD PTR [R9 + 4]
  MOV [CurrentFireWordPtr], R9

@SkipWordUpdate:
@SkipFireWord:
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_UpdateTheFire
@FireNoActivated:

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

  MOV R8, 1
  MOV RDX, R15
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DrawHorizBar

  ADD R15, SIZE COLOR_BAR_STRUCT
  INC RBX
  CMP RBX, NUMBER_MID_HORIZONTAL_BARS
  JB @DrawMidBars

  MOV R8, OFFSET CopperBarsOneWave
  MOV RDX, [CopperBarsVertOneHead]
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_MoveVertBarsWave
  
  MOV R8, OFFSET CopperBarsTwoWave
  MOV RDX, [CopperBarsVertTwoHead]
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_MoveVertBarsWave
  
  XOR RBX, RBX  
  MOV R12, [CopperBarsVertOne]
  MOV R13, [CopperBarsVertTwo]



  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid

  MOV RAX, [FLASH_TO_BOLD_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  TEST [DemoFrameCounter], 1
  JE @SkipTheSolid
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
@SkipTheSolid:
  MOV RAX, [BOLD_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  
  MOV RAX, [FLASH_TO_LIGHT_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsLightTransparent


  MOV RAX, [DemoFrameCounter]
  AND AL, 3
  CMP AL, 2
  JB @SkipTheDark
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
@SkipTheDark:

  MOV RAX, [LIGHT_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsLightTransparent
  
  MOV RAX, [FLASH_TO_SOLID_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid

  TEST [DemoFrameCounter], 1
  JE @SkipTheLight
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
@SkipTheLight:
  MOV RAX, [SOLID_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid

  ; 
  ; Reset cycle
  ;
  MOV RAX, [SOLID_START]
  ADD RAX, 500
  MOV [FLASH_TO_BOLD_START], RAX
  MOV RCX, 50
  ADD RCX, RAX
  MOV [BOLD_START], RCX
  ADD RAX, 500
  MOV [FLASH_TO_LIGHT_START], RAX
  MOV RCX, 50
  ADD RCX, RAX
  MOV [LIGHT_START], RCX
  ADD RAX, 500
  MOV [FLASH_TO_SOLID_START], RAX
  MOV RCX, 100
  ADD RCX, RAX
  MOV [SOLID_START], RCX


@DrawVerticleBars:

  MOV RDX, R12
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL R14

  MOV RDX, R13
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL R14

  INC RBX
  ADD R12, SIZE COPPERBARS_FIELD_ENTRY
  ADD R13, SIZE COPPERBARS_FIELD_ENTRY
  CMP RBX, NUMBER_OF_VERTICLE_BARS
  JB @DrawVerticleBars
 

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_DrawSquares
 
  CMP [DemoFrameCounter], FIRE_START_COUNT
  JAE @FireReady
  JMP @SkipFireOverlay
@FireReady: 
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_OverlayFire
@SkipFireOverlay:
@ExitFunction:
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

 MOV RCX, [VirtualPalette]
 DEBUG_FUNCTION_CALL VPal_Free

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Free, _TEXT$00



;*********************************************************
;  CopperBarsDemo_ConvertImageToPalImage
;
;        Parameters: Image Information, Start Palette Number
;
;        Return: Image Buffer
;
;
;*********************************************************  
;NESTED_ENTRY CopperBarsDemo_ConvertImageToPalImage, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
; DEBUG_RSP_CHECK_MACRO
;  MOV R15, RCX
;  MOV RBX, RDX
;  
;  MOV RCX, IMAGE_INFORMATION.ImageWidth[R15]
;  MOV RAX, IMAGE_INFORMATION.ImageHeight[R15]
;  XOR RDX, RDX
;  MUL RCX
;  MOV R12, RAX
;  SHL RAX, 1
;
;  MOV RDX, RAX
;  MOV RCX, LMEM_ZEROINIT
;  DEBUG_FUNCTION_CALL LocalAlloc
;  MOV [GifPalBufPtr], RAX
;  CMP RAX, 0
;  JE @AllocationError
;
;  MOV RSI, IMAGE_INFORMATION.CurrImagePtr[R15]
;  MOV RDI, [GifPalBufPtr]
;@CreateVPalBufferLoop:
;  XOR R8, R8
;  MOV EDX, DWORD PTR [RSI]
;  MOV RCX, [VirtualPalette]
;  DEBUG_FUNCTION_CALL VPal_FindColorIndex
;  CMP AX, 0FFFFh
;  JNE @SetFoundIndex
;
;  MOV R8D, DWORD PTR [RSI]
;  MOV RDX, RBX
;  MOV RCX,  [VirtualPalette]
;  DEBUG_FUNCTION_CALL VPal_SetColorIndex
;  MOV RAX, RBX
;  INC RBX
;@SetFoundIndex:
;  MOV WORD PTR [RDI], AX
;  ADD RSI, 4
;  ADD RDI, 2
;  DEC R12
;  JNZ @CreateVPalBufferLoop
;
;@AllocationError:
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END CopperBarsDemo_ConvertImageToPalImage, _TEXT$00




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
  MOV R12, [PaletteArray]
  ADD R12, 4
  MOV RDX, 1
@BackgroundTopPlot:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  MOV EAX, DWORD PTR [R12]
  REP STOSD
  ADD R12, 4
  INC RDX
  CMP RDX, 256
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
  SHL RAX, 2
  ADD RDI, RAX
  XOR R9, R9
  MOV R10, [PaletteArray]
@DrawScanLines:
  XOR R11, R11
@DrawBackgroundBar:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RAX, RBX
  SHL RAX, 2
  MOV EAX, DWORD PTR [R10 + RAX]
  REP STOSD
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
  MOV RCX, [VirtualPalette]
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
  MOV RCX, [VirtualPalette]
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
 
  CMP COLOR_BAR_STRUCT.CurrentY[RSI], 560
  JL @Done

  MOV COLOR_BAR_STRUCT.CurrentY[RSI], 560
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
   MOV RCX, [VirtualPalette]
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
   MOV RCX, [VirtualPalette]
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
   MOV RCX, [VirtualPalette]
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
  MOV R10, [PaletteArray]
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, COLOR_BAR_STRUCT.CurrentY[R15]
  MUL R8
  SHL RAX, 2
  ADD RDI, RAX
  XOR RBX, RBX
@GoingUp:
  
  CMP R14, 0
  JE @NoTransparentcy
  XOR R11, R11
@PerformTransparency:
  MOV RAX, R12
  SHL RAX, 2
  ADD RAX, R11
  MOV AL, BYTE PTR [R10 + RAX]
  XOR RCX, RCX
  MOV CL, AL
  XOR RDX, RDX
  MOV DL, BYTE PTR [RDI + R11]
  ADD CX, DX
  CMP CX, 255
  JB @SkipFixUp
  MOV CL, 255
@SkipFixUp:
  MOV BYTE PTR [RDI + R11], CL
  INC R11
  CMP R11, 3
  JB @PerformTransparency

  MOV EAX, DWORD PTR [RDI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD

  JMP @CompletedWritingPixel  
@NoTransparentcy:
  MOV RAX, R12
  SHL RAX, 2
  MOV EAX, [R10 + RAX]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD
@CompletedWritingPixel:
  INC RBX
  INC R12
  CMP RBX, 10
  JB @GoingUp


  XOR RBX, RBX
@GoingDown:

  CMP R14, 0
  JE @NoTransparentcy2
  XOR R11, R11
@PerformTransparency2:
  MOV RAX, R12
  SHL RAX, 2
  ADD RAX, R11
  MOV AL, BYTE PTR [R10 + RAX]
  XOR RCX, RCX
  MOV CL, AL
  XOR RDX, RDX
  MOV DL, BYTE PTR[RDI + R11]
  ADD CX, DX
  CMP CX, 255
  JB @SkipFixUp2
  MOV CL, 255
@SkipFixUp2:
  MOV BYTE PTR [RDI + R11], CL
  INC R11
  CMP R11, 3
  JB @PerformTransparency2

  MOV EAX, DWORD PTR [RDI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD

  JMP @CompletedWritingPixel2  
@NoTransparentcy2:
  MOV RAX, R12
  SHL RAX, 2
  MOV EAX, DWORD PTR [R10 + RAX]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD
@CompletedWritingPixel2:
  INC RBX
  INC R12
  CMP RBX, 10
  JB @GoingDown

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawHorizBar, _TEXT$00



;*********************************************************
;  CopperBarDemo_DrawVertBarsDarkTransparent
;
;        Parameters: MMaster Context, Vert Bar Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawVertBarsDarkTransparent, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  MOV R15, RDX
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, COPPERBARS_FIELD_ENTRY.Y[R15]
  MUL R8
  SHL RAX, 2
  ADD RDI, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[R15]
  SHL RAX, 2
  ADD RDI, RAX

  XOR RCX, RCX
  MOV CX, COPPERBARS_FIELD_ENTRY.StartColor[R15]
  MOV RBX, [PaletteArray]
  SHL RCX, 2
  ADD RCX, RBX
  XOR RBX, RBX
@DrawVerticleBar:
  MOV R10, COPPERBARS_FIELD_ENTRY.Y[R15]
  MOV R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R11, 2
  MOV R14, RDI

@DrawVerticleLine:
  ;
  ; Blue
  ;
  SUB R14, R11
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX]
  MOV DL, BYTE PTR [R14]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 4]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 4]
  SHR DL, 1
  ADD AX, DX
  SHR RAX, 2
  MOV [R14], AL
  SUB R14, R11
  
  ;
  ; Green
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 1]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 5]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
  SHR DL, 1
  ADD AX, DX
  SHR RAX, 2
  MOV [R14 + 1], AL
  SUB R14, R11

  ;
  ; Red
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 2]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 6]
  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
  SHR DL, 1
  ADD AX, DX
  SHR RAX, 2
  MOV [R14 + 2], AL

  ADD R14, R11
  INC R10
  CMP R10, 586
  JB @DrawVerticleLine

  ADD RCX, 4
  ADD RDI, 4
  INC RBX
  CMP RBX, 20
  JB @DrawVerticleBar

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawVertBarsDarkTransparent, _TEXT$00


;*********************************************************
;  CopperBarDemo_DrawVertBarsLightTransparent
;
;        Parameters: MMaster Context, Vert Bar Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawVertBarsLightTransparent, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  MOV R15, RDX
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, COPPERBARS_FIELD_ENTRY.Y[R15]
  MUL R8
  SHL RAX, 2
  ADD RDI, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[R15]
  SHL RAX, 2
  ADD RDI, RAX

  XOR RCX, RCX
  MOV CX, COPPERBARS_FIELD_ENTRY.StartColor[R15]
  MOV RBX, [PaletteArray]
  SHL RCX, 2
  ADD RCX, RBX
  XOR RBX, RBX
@DrawVerticleBar:
  MOV R10, COPPERBARS_FIELD_ENTRY.Y[R15]
  MOV R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R11, 2
  MOV R14, RDI

@DrawVerticleLine:
  ;
  ; Blue
  ;
  SUB R14, R11
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX]
  MOV DL, BYTE PTR [R14]
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 4]
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 4]
  ADD AX, DX
  SHR RAX, 2
  MOV [R14], AL
  SUB R14, R11
  
  ;
  ; Green
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 1]
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 5]
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
  ADD AX, DX
  SHR RAX, 2
  MOV [R14 + 1], AL
  SUB R14, R11

  ;
  ; Red
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 2]
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 6]
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
  ADD AX, DX
  SHR RAX, 2
  MOV [R14 + 2], AL
  ADD R14, R11
  INC R10

  CMP R10, 586
  JB @DrawVerticleLine

  ADD RCX, 4
  ADD RDI, 4
  INC RBX
  CMP RBX, 20
  JB @DrawVerticleBar

    RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawVertBarsLightTransparent, _TEXT$00




;*********************************************************
;  CopperBarDemo_DrawVertBarSolid
;
;        Parameters: MMaster Context, Vert Bar Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawVertBarSolid, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  MOV R15, RDX
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, COPPERBARS_FIELD_ENTRY.Y[R15]
  MUL R8
  SHL RAX, 2
  ADD RDI, RAX
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[R15]
  SHL RAX, 2
  ADD RDI, RAX

  XOR RCX, RCX
  MOV CX, COPPERBARS_FIELD_ENTRY.StartColor[R15]
  MOV RBX, [PaletteArray]
  SHL RCX, 2
  ADD RCX, RBX
  XOR RBX, RBX
@DrawVerticleBar:
  MOV R10, COPPERBARS_FIELD_ENTRY.Y[R15]
  MOV R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R11, 2
  MOV R14, RDI

 @DrawVerticleLine:
    MOV R12D, DWORD PTR [RCX]
    MOV DWORD PTR [R14], R12D
    ADD R14, R11
    INC R10
    CMP R10, 586
    JB @DrawVerticleLine

    ADD RCX, 4
    ADD RDI, 4
    INC RBX
    CMP RBX, 20
    JB @DrawVerticleBar

    RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawVertBarSolid, _TEXT$00



;*********************************************************
;  CopperBarDemo_DrawTopSquares
;
;        Parameters: Master Context
;
;       
;
;
;;*********************************************************  
;NESTED_ENTRY CopperBarDemo_DrawTopSquares, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
;  DEBUG_RSP_CHECK_MACRO
;  MOV R12, RCX
;  XOR RAX, RAX
;  MOV RDI, [DoubleBuffer]
;  MOV RSI, [GifImageInformation.CurrImagePtr]
;@HeightLoop:
;  XOR RDX, RDX
;  XOR R8, R8
;@WidthLoop:
;  MOV ECX, DWORD PTR [RSI]
;  MOV DWORD PTR [RDI + RDX], ECX
;  ADD RSI, 4
;  INC R8
;  ADD RDX, 4
;  CMP R8, [GifImageInformation.ImageWidth]
;  JB @WidthLoop
;
;  MOV R10, MASTER_DEMO_STRUCT.ScreenWidth[R12]
;  SHL R10, 2
;  ADD RDI, R10
;  INC RAX
;  CMP RAX, [GifImageInformation.ImageHeight]
;  JB @HeightLoop
;
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END CopperBarDemo_DrawTopSquares, _TEXT$00


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
  SHL RAX, 2
  MOV RDX, [GifImageInformation.CurrImagePtr]
  ADD RDX, RAX

  XOR R13, R13                                  ; Count Scan Lines
@DrawTopGrid:
  CMP R10, 0
  JE @SetupSecondSquare
  MOV R11, [SquareGrid.CurrentTopCornerX]       ; Starting X  of the current line for the first square.
  MOV RSI, R11
  SHL RSI, 2
  ADD RSI, RDX
  XOR R14, R14
  XOR RAX, RAX
  JMP @ScanLine
@SetupSecondSquare:
  MOV R14, [GifImageInformation.ImageWidth]
  SUB R14, [SquareGrid.CurrentTopCornerX]
  MOV RAX, R14
  SHL RAX, 2
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
;  REP MOVSD
  CMP RCX, 0
  JE @SkipDrawing
@MovsdTransparentLoop:
  MOV EAX, DWORD PTR [RSI]
  ADD RSI, 4
  CMP EAX, TRANSPARENT_TILE_COLOR
  JE @TransparentColor
  MOV DWORD PTR [RDI], EAX
@TransparentColor:
  ADD RDI, 4  
  DEC RCX
  JNZ @MovsdTransparentLoop
@SkipDrawing:
  MOV RAX, [GifImageInformation.ImageWidth]
  ADD RAX, R14
  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  JB @NoFixUp
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SUB RAX, R14
  SHL RAX, 2
  ADD RDI, RAX
@NoFixUp:
  MOV RAX, [GifImageInformation.ImageWidth]
  ADD R14, RAX
  SHL RAX, 2
  MOV RSI, RDX
  XOR R11, R11
  CMP R14, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  JB @ScanLine

  MOV RAX, [GifImageInformation.ImageWidth]
  SHL RAX, 2
  ADD RDX, RAX
  INC R9
  CMP R9, [GifImageInformation.ImageHeight]
  JB @SkipResetOfGifLines
  XOR R10, 1
  MOV RDX, [GifImageInformation.CurrImagePtr]
  XOR R9, R9
@SkipResetOfGifLines: 
  INC R13
  CMP R13, 255
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









;*********************************************************
;  CopperBarDemo_RandomFireball
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_RandomFireball, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  DEBUG_FUNCTION_CALL Math_Rand 
  XOR RDX, RDX
  MOV RCX, 10
  DIV RCX
  MOV RSI, RDX
  INC RSI

@CreateAFireball:
  MOV RDI, [FireDoubleBuffer]
    
  DEBUG_FUNCTION_CALL Math_Rand 
  XOR RDX, RDX
  MOV RCX, FIRE_WIDTH-10
  DIV RCX
  MOV RBX, RDX
  ADD RBX, 5

  DEBUG_FUNCTION_CALL Math_Rand 
  XOR RDX, RDX
  MOV RCX, FIRE_HEIGHT-10
  DIV RCX
  MOV RAX, RDX
  ADD RAX, 5
  XOR RDX, RDX
  MOV RCX, FIRE_WIDTH
  MUL RCX
  SHL RAX, 1

  ADD RDI, RAX
  SHL RBX, 1
  ADD RDI, RBX

  MOV WORD PTR [RDI], MAX_FIRE_INDEX - 5
  MOV WORD PTR [RDI + 2], MAX_FIRE_INDEX - 5
  MOV WORD PTR [RDI + FIRE_WIDTH*2], MAX_FIRE_INDEX - 5
  MOV WORD PTR [RDI + FIRE_WIDTH*2 + 2], MAX_FIRE_INDEX - 5

  DEC RSI
  JNZ @CreateAFireball

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_RandomFireball, _TEXT$00



;*********************************************************
;  CopperBarDemo_FeedTheFire
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_FeedTheFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [FireDoubleBuffer]

  XOR RDX, RDX
  MOV RAX, FIRE_WIDTH
  MOV RCX, FIRE_HEIGHT
  SUB RCX, 3
  MUL RCX
  SHL RAX, 1
  ADD RDI, RAX

  XOR RBX, RBX

@PrimeTheFire:
  DEBUG_FUNCTION_CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, 225
  TEST RBX, 1
  JZ @ContinueNumber
  MOV RCX, 150
@ContinueNumber:
  DIV RCX
  ADD RDX, MAX_FIRE_INDEX - 225
  MOV WORD PTR [RDI], DX

;@PrimeTheFire:
;  DEBUG_FUNCTION_CALL Math_Rand
;  MOV CX, 255
;  TEST AL, 1
;  JZ @Write255
;  MOV CX, 20
;@Write255:
;  MOV WORD PTR [RDI], CX
;
  ADD RDI, 2
  INC RBX
  CMP RBX, FIRE_WIDTH*3
  JB @PrimeTheFire

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_FeedTheFire, _TEXT$00



;*********************************************************
;  CopperBarDemo_UpdateTheFire
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_UpdateTheFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [FireDoubleBuffer]
  ADD RDI, FIRE_WIDTH*2
  MOV R8, 1
@HeightLoop:
  ;ADD RDI, 2                    ; Don't compute the boundaries.  
  XOR R9, R9

@WidthLoop:

  ;MOV AX, [RDI]
  ;ADD AX, [RDI - 2]
  ;ADD AX, [RDI + 2]

  MOV AX, [RDI + FIRE_WIDTH*2]
  ADD AX, [RDI + FIRE_WIDTH*2 - 2]
  ADD AX, [RDI + FIRE_WIDTH*2 + 2]

  ADD AX, [RDI + FIRE_WIDTH*4]
  ;ADD AX, [RDI + FIRE_WIDTH*2]

  SHR AX, 2
  CMP AX, 0
  JE @SkipDecrement
  DEC AX
@SkipDecrement:
  MOV [RDI], AX
  ADD RDI, 2
  INC R9
  CMP R9, FIRE_WIDTH
  JB @WidthLoop

;  ADD RDI, 2                   ; Don't compute the boundaries.  
  INC R8
  CMP R8, FIRE_HEIGHT-2
  JB @HeightLoop

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_UpdateTheFire, _TEXT$00


;*********************************************************
;  CopperBarDemo_UpdateTheFireAlgorithm2
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_UpdateTheFireAlgorithm2, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDI, [FireDoubleBuffer]
  XOR R8, R8
@HeightLoop:
  XOR R9, R9
@WidthLoop:
  XOR RDX, RDX
  MOV AX, [RDI]
  ADD AX, [RDI + 2]
  ADC AX, DX
  ADD AX, [RDI - FIRE_WIDTH*2]
  ADC AX, DX
  ADD AX, [RDI + FIRE_WIDTH*2]
  ADC AX, DX
  SHR AX, 2
  CMP AX, 0
  JE @SkipDecrement
  DEC AX
@SkipDecrement:
  MOV [RDI], AX
  ADD RDI, 2
  INC R9
  CMP R9, FIRE_WIDTH
  JB @WidthLoop
  INC R8
  CMP R8, FIRE_HEIGHT-2
  JB @HeightLoop

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_UpdateTheFireAlgorithm2, _TEXT$00




;*********************************************************
;  CopperBarDemo_OverlayFire
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_OverlayFire, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RCX
  MOV RSI, [FireDoubleBuffer]
  MOV RDI, [DoubleBuffer]
  MOV R10, OFFSET FirePalette

  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SHL RAX, 2
  XOR RDX, RDX
  MOV RCX, FIRE_START_Y + 1
  MUL RCX

  ADD RDI, RAX

  XOR R8, R8
@CopyFireLoop:
  XOR R9, R9
@CopyFireRow:
  XOR RAX, RAX
  MOV AX, WORD PTR [RSI]
  CMP EAX, 0
  JE @NothingToPlot
  SHL EAX, 2
  CMP DWORD PTR [R10 + RAX], 0
  JE @NothingToPlot
  XOR R11, R11
  XOR RCX, RCX
  XOR RDX, RDX

  MOV CL, BYTE PTR [R10 + RAX]
  CMP CL, 63
  JAE @NoTransparent
  JMP @NoTransparent    ; Temporary trying this
  MOV R11, 1
  MOV DL, BYTE PTR [RDI + 2]
  ADD CX, DX
  SHR CX, 1
  CMP CX, 255
  JB @WriteRed
  MOV CX, 255
@NoTransparent:
@WriteRed:
  MOV BYTE PTR [RDI + 2], CL
  
  XOR RCX, RCX
  XOR RDX, RDX
  INC RAX
  MOV CL, BYTE PTR [R10 + RAX]
  CMP R11, 0
  JE @WriteGreen
  MOV DL, BYTE PTR [RDI + 1]
  ADD CX, DX
  SHR CX, 1
  CMP CX, 255
  JB @WriteGreen
  MOV CX, 255
@WriteGreen:
  MOV BYTE PTR [RDI + 1], CL
  
  XOR RCX, RCX
  XOR RDX, RDX
  INC RAX
  MOV CL, BYTE PTR [R10 + RAX]
  CMP R11, 0
  JE @WriteBlue
  MOV DL, BYTE PTR [RDI]
  ADD CX, DX
  SHR CX, 1
  CMP CX, 255
  JB @WriteBlue
  MOV CX, 255
@WriteBlue:
  MOV BYTE PTR [RDI], CL
@NothingToPlot:
  ADD RSI, 2
  ADD RDI, 4
  INC R9
  CMP R9, FIRE_WIDTH
  JB @CopyFireRow
  
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  SHL R9, 2
  SHL RAX, 2
  SUB RAX, R9
  ADD RDI, RAX
   
  INC R8
  CMP R8, FIRE_HEIGHT-3
  JB @CopyFireLoop

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_OverlayFire, _TEXT$00

;*********************************************************
;  CopperBarDemo_ScreenMelt
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_ScreenMelt, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, [DoubleBuffer]

  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  XOR RDX, RDX
  MUL RCX
  SUB RAX, 1
  SHL RAX, 2
  ADD RDI, RAX
  XOR R8, R8
@BufferLoop:
  ;
  ; Special dealing with right side outter pixel.
  ; 

  XOR RDX, RDX

@CreateColorMixRight:
  XOR RAX, RAX
  XOR RCX, RCX

  MOV R11, RDI
  SUB R11, FIRE_WIDTH*2

  MOV AL, BYTE PTR [R11 + RDX]
  SUB R11, 4
  ADD R11, RDX
  MOV CL, BYTE PTR [R11]
  ADD AX, CX

  MOV CL, BYTE PTR [RDI + RDX]
  ADD AX, CX
  MOV R11, RDI
  SUB R11, 4
  MOV CL, BYTE PTR [R11 + RDX]
  ADD AX, CX
  SHR AX, 2
  CMP AX, 0
  JE @SkipRightDecrement
  DEC AX
@SkipRightDecrement:
  CMP AX, 255
  JB @NoUpdateForRight
  MOV AL, 254
@NoUpdateForRight:
  MOV BYTE PTR [RDI + RDX], AL
  INC RDX
  CMP RDX, 3
  JB @CreateColorMixRight

  SUB RDI, 4
  MOV R9, 1
@InnerWidthLoop:

  XOR RDX, RDX

@CreateColorMixCenter:
  XOR RAX, RAX
  XOR RCX, RCX

  MOV R11, RDI
  SUB R11, FIRE_WIDTH*2
  MOV AL, BYTE PTR [R11 + RDX]


  SUB R11, 4
  ADD R11, RDX
  MOV CL, BYTE PTR [R11]
  ADD AX, CX

  MOV R11, RDI
  SUB R11, FIRE_WIDTH*2-4
  ADD R11, RDX
  MOV CL, BYTE PTR [R11]
  ADD AX, CX

  MOV CL, BYTE PTR [RDI + RDX]

  ADD AX, CX
  SHR AX, 2
  CMP AX, 0
  JE @SkipCenterDecrement
  DEC AX
@SkipCenterDecrement:
  CMP AX, 255
  JB @NoUpdateForCenter
  MOV AL, 254
@NoUpdateForCenter:
  MOV BYTE PTR [RDI + RDX], AL
  INC RDX
  CMP RDX, 3
  JB @CreateColorMixCenter

  SUB RDI, 4
  INC R9
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SUB RAX, 2
  CMP R9, RAX
  JB @InnerWidthLoop
  
  ;
  ; Special dealing with left side outter pixel.
  ; 

  XOR RDX, RDX

@CreateColorMixLeft:
  XOR RAX, RAX
  XOR RCX, RCX

  MOV R11, RDI
  SUB R11, FIRE_WIDTH*2

  MOV AL, BYTE PTR [R11 + RDX]
  SUB R11, 4
  ADD R11, RDX
  MOV CL, BYTE PTR [R11]
  ADD AX, CX

  MOV CL, BYTE PTR [RDI + RDX]
  ADD AX, CX
  MOV R11, RDI
  SUB R11, 4
  MOV CL, BYTE PTR [R11 + RDX]
  ADD AX, CX
  SHR AX, 2
  CMP AX, 0
  JE @SkipLeftDecrement
  DEC AX
@SkipLeftDecrement:
  CMP AX, 255
  JB @NoUpdateForLeft
  MOV AL, 254
@NoUpdateForLeft:
  MOV BYTE PTR [RDI + RDX], AL
  INC RDX
  CMP RDX, 3
  JB @CreateColorMixLeft
  
  SUB RDI, 4
  INC R8
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  DEC RAX
  CMP R8, RAX
  JB @BufferLoop

  XOR RAX, RAX
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RCX, 1
  MOV RDI, [DoubleBuffer]
  REP STOSQ

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_ScreenMelt, _TEXT$00

;*********************************************************
;  CopperBarDemo_MoveVertBars
;
;        Parameters: Master Context, Verticle Bars
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveVertBars, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RBX, RCX

  MOV RDI, RDX
  XOR RSI, RSI
  MOV R13, -1
  MOV R14, 8
@CopperBarsPlot:
  XOR RDX, RDX

  MOV RAX, COPPERBARS_FIELD_ENTRY.Velocity[RDI]
  ADD RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX

  CMP RAX, COPPERBARS_FIELD_ENTRY.LeftWall[RDI]
  JG @CheckUpperBounds
             
  MOV RAX, COPPERBARS_FIELD_ENTRY.LeftWall[RDI]
  INC RAX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX
  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocity
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@AdjustVelocity:
  CMP RDX, 4
  JA @NotOutOfBounds
  ADD RDX, 4
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@CheckUpperBounds:
  ADD RAX, 21
  CMP RAX, COPPERBARS_FIELD_ENTRY.RightWall[RDI] 
  JL @NotOutOfBounds
  
  MOV RAX, COPPERBARS_FIELD_ENTRY.RightWall[RDI] 
  SUB RAX, 22
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX
  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocityNeg
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @NotOutOfBounds
@AdjustVelocityNeg:
  CMP RDX, 4
  JA @SkipIncrease
  ADD RDX, 4
@SkipIncrease:
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
@NotOutOfBounds:
  CMP RSI, 0
  JE @SkipPreviousXAlignmentCheck
  
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV RCX, R13
  SUB RCX, COPPERBARS_FIELD_ENTRY.Bounds[RDI]
  CMP RAX, RCX
  JG @CheckUpperBoundsOfPreviousBar
  INC RCX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RCX

  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX

  CMP R14, 8
  JE @AdjustVelocity2
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck

@AdjustVelocity2:
  CMP RDX, 4
  JA @DontAdjustVel
   ADD RDX, 4

@DontAdjustVel:
   MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck

@CheckUpperBoundsOfPreviousBar:
  MOV RAX, COPPERBARS_FIELD_ENTRY.X[RDI]
  MOV RCX, R13
  ADD RCX, COPPERBARS_FIELD_ENTRY.Bounds[RDI]
  CMP RAX, RCX
  JL @SkipPreviousXAlignmentCheck

  DEC RCX
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RCX

  CALL Math_Rand
  XOR RDX, RDX
  MOV RCX, R14
  DIV RCX
  INC RDX
  CMP R14, 8
  JE @AdjustVelocity3
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
  JMP @SkipPreviousXAlignmentCheck
@AdjustVelocity3:
  CMP RDX, 4
  JA @DoNotAdjustVelocity
  ADD RDX, 4
@DoNotAdjustVelocity:
  NEG RDX
  MOV COPPERBARS_FIELD_ENTRY.Velocity[RDI], RDX
@SkipPreviousXAlignmentCheck:
  MOV R14, 3
  MOV R13, COPPERBARS_FIELD_ENTRY.X[RDI]
  SUB RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI  
  CMP RSI, NUMBER_OF_VERTICLE_BARS
  JB @CopperBarsPlot
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END CopperBarDemo_MoveVertBars, _TEXT$00


;*********************************************************
;  CopperBarDemo_MoveVertBarsWave
;
;        Parameters: Master Context, Verticle Bars, Wave
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_MoveVertBarsWave, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RBX, RCX
  MOV RDI, RDX
  XOR RSI, RSI
  MOV R15, R8
@CopperBarsPlot:
  MOV RAX, COPPERBARS_FIELD_ENTRY.Y[RDI]
  ADD RAX, WAVE_TRACKER.WaveThetaAddition[R15]
  XOR RDX, RDX
  MOV RCX, 360
  DIV RCX
  MOV RCX, RDX
  MOV R9, R15

  MOV R8, WAVE_TRACKER.WaveCenter[R15]
  MOV RDX, WAVE_TRACKER.WaveRange[R15]
  DEBUG_FUNCTION_CALL CopperBarDemo_SineWave
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX
  
  MOV R13, COPPERBARS_FIELD_ENTRY.X[RDI]
  SUB RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI  
  CMP RSI, NUMBER_OF_VERTICLE_BARS
  JB @CopperBarsPlot

  MOV RAX, WAVE_TRACKER.WaveVelocity[R15]
  ADD WAVE_TRACKER.WaveThetaAddition[R15], RAX


  DEBUG_FUNCTION_CALL Math_rand

  TEST RAX, 080h
  JZ @DoNotUpdateRange
  MOV RCX, WAVE_TRACKER.WaveRangeVelocity[R15]
  ADD WAVE_TRACKER.WaveRange[R15], RCX

  CMP WAVE_TRACKER.WaveRange[R15], COPPER_BARS_RANGE_LOW
  JLE @FixUpRangeLow

  CMP WAVE_TRACKER.WaveRange[R15], COPPER_BARS_RANGE_HIGH
  JLE @DoNotUpdateRange

  MOV WAVE_TRACKER.WaveRange[R15], COPPER_BARS_RANGE_HIGH - 1
  NEG WAVE_TRACKER.WaveRangeVelocity[R15]
  JMP @DoneUpdateRange
@FixUpRangeLow:
  MOV WAVE_TRACKER.WaveRange[R15], COPPER_BARS_RANGE_LOW + 1
  NEG WAVE_TRACKER.WaveRangeVelocity[R15]
@DoneUpdateRange:
@DoNotUpdateRange:


  ;    TEST RAX, 014h
  ;    JZ @DoNotUpdateCenter
  ;  
  ;    MOV RCX, WAVE_TRACKER.WaveCenterVelocity[R15]
  ;    ADD WAVE_TRACKER.WaveCenter[R15], RCX
  ;  
  ;    CMP WAVE_TRACKER.WaveCenter[R15], COPPER_BARS_CENTER_LOW
  ;    JLE @FixUpCenterLow
  ;  
  ;    CMP WAVE_TRACKER.WaveCenter[R15], COPPER_BARS_CENTER_HIGH
  ;    JLE @DoNotUpdateCenter
  ;  
  ;    MOV WAVE_TRACKER.WaveCenter[R15], COPPER_BARS_CENTER_HIGH - 1
  ;    NEG WAVE_TRACKER.WaveCenterVelocity[R15]
  ;    JMP @DoneUpdateCenter
  ;  @FixUpCenterLow:
  ;    MOV WAVE_TRACKER.WaveCenter[R15], COPPER_BARS_CENTER_LOW + 1
  ;    NEG WAVE_TRACKER.WaveCenterVelocity[R15]
  ;  @DoneUpdateCenter:
  ;  @DoNotUpdateCenter:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END CopperBarDemo_MoveVertBarsWave, _TEXT$00




;*********************************************************
;  CopperBarDemo_SineWave
;
;        Parameters: Angle (Theta), Multiplier, Center
;
;           Return = Multiplier*SIN(Theta) + Center
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_SineWave, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RDX
  MOV R12, R8

  PXOR XMM0, XMM0
  PXOR XMM1, XMM1
  CVTSI2SD XMM0, RCX
  MOV RAX, 180
  CVTSI2SD XMM1, RAX
  DIVSD XMM0, XMM1
  MOVSD XMM1, [PI]
  MULSD XMM0, XMM1
  DEBUG_FUNCTION_CALL sin
  CVTSI2SD XMM1, RBX
  MULSD XMM0, XMM1
  CVTSI2SD XMM1, R12
  ADDSD XMM0, XMM1
  CVTSD2SI RAX, XMM0

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_SineWave, _TEXT$00


;*********************************************************
;  CopperBarDemo_DisplayFireWord
;
;        Parameters: Master Context, X, Y, String
;
;           
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DisplayFireWord, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX
  MOV R12, RDX
  MOV RSI, R9
  ;
  ; Set double buffer to the start.
  ;
  MOV R13, [FireDoubleBuffer]
  MOV RAX, R8
  XOR RDX, RDX
  MOV RCX, FIRE_WIDTH
  SHL RCX, 1
  MUL RCX
  ADD R13, RAX
  MOV RCX, R12
  SHL RCX, 1
  ADD R13, RCX

@OutterWordLoop:
  XOR RCX, RCX
  MOV CL, BYTE PTR [RSI]
  DEBUG_FUNCTION_CALL Font_GetBitFont  
  MOV R14, RAX
  XOR DH, DH

@HeightLoop:
  XOR R11, R11
@InnerHeightLoop:
  MOV R9, FIRE_FONT_HEIGHT_SIZE_PER_LINE
@FontSizeHeightLoop:
  XOR DL, DL
  MOV AL, BYTE PTR [R14]
  MOV AH, 080h
@WidthLoop:
  TEST AL, AH
  JZ @NoDraw
  MOV RCX, FIRE_FONT_WIDTH_SIZE
@DrawIt:
  MOV WORD PTR [R13 + R11], 255
  ADD R11, 2
  DEC RCX
  JNZ @DrawIt
  JMP @DontDoubleRemove
@NoDraw:
  ADD R11, 2*FIRE_FONT_WIDTH_SIZE
@DontDoubleRemove:
  SHR AH, 1
  INC DL
  CMP DL, 8
  JB @WidthLoop
  DEC R9
  JZ @NextLine
  
  SUB R11, (8*FIRE_FONT_WIDTH_SIZE*2)
  MOV RCX, FIRE_WIDTH
  SHL RCX, 1
  ADD R11, RCX
  JMP @FontSizeHeightLoop

@NextLine:
  INC R14
  SUB R11, (8*FIRE_FONT_WIDTH_SIZE*2)
  MOV RCX, FIRE_WIDTH
  SHL RCX, 1
  ADD R11, RCX
  INC DH
  CMP DH, 8
  JB @InnerHeightLoop
@NextLetter:

@ReTest:  
  ADD R13, (8*FIRE_FONT_WIDTH_SIZE*2) + 4
  INC RSI
  CMP BYTE PTR [RSI], ' '
  JNE @NextTest
  JMP @ReTest
@NextTest:
  CMP BYTE PTR [RSI], 0
  JNE @OutterWordLoop

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DisplayFireWord, _TEXT$00




END

