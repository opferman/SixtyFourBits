;*********************************************************
; Copper Bars Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2017
;
;     Completely Rewritten to look a style simmilar to Kukoo2 in September 2020.
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


PLASMA_DESCRIPTIONS_STRUCT struct
  StartRange           dq ?
  StartColor           dd ?
  UseStartColor        dd ?
  RedVelocity          db ?
  GreenVelocity        db ?
  BlueVelocity         db ?
PLASMA_DESCRIPTIONS_STRUCT ends


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
NUMBER_OF_VERTICLE_BARS       EQU <300/4>
VERTICLE_BAR_DIFFERENCE       EQU <4>
VERTICLE_BAR_START            EQU <255>
VERTICLE_BAR_END              EQU <586>
PLASMA_AREA_START             EQU <586>
PLASMA_AREA_END               EQU <768>
PLASMA_WIDTH                  EQU <1024>
PLASMA_HEIGHT                 EQU <182>
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
COPPER_BARS_RANGE_LOW         EQU <5>
COPPER_BARS_RANGE_HIGH        EQU <325>

SIN_FONT_HEIGHT_SIZE_PER_LINE  EQU <12>
SIN_FONT_WIDTH_SIZE            EQU <12>  

FIRE_FONT_HEIGHT_SIZE_PER_LINE  EQU <8>
FIRE_FONT_WIDTH_SIZE            EQU <8>
FIRE_START_COUNT                EQU <500>

TRIG_TABLE_SIZE               EQU <1>

PLASMA_CENTER                 EQU <4096 / 15>

BOTTOM_TEXT_LETTER_SPACE      EQU <2*(SIN_FONT_WIDTH_SIZE/2)>

;*********************************************************
; Public Functions
;*********************************************************
public CopperBarsDemo_Init
public CopperBarsDemo_Demo
public CopperBarsDemo_Free


.DATA

ifdef USE_SORTOF_FIRE_PAL
FirePalette     db 0, 0, 0, 0
db 0, 0, 0, 0
db 4, 0, 4, 0
db 4, 0, 4, 0
db 8, 0, 8, 0
db 8, 0, 8, 0
db 12, 0, 12, 0
db 12, 0, 12, 0
db 12, 0, 16, 0
db 16, 0, 16, 0
db 16, 0, 20, 0
db 20, 0, 20, 0
db 20, 0, 20, 0
db 20, 0, 24, 0
db 24, 0, 24, 0
db 24, 0, 28, 0
db 28, 0, 28, 0
db 28, 0, 32, 0
db 32, 0, 32, 0
db 32, 0, 36, 0
db 32, 0, 36, 0
db 36, 0, 36, 0
db 36, 0, 40, 0
db 40, 0, 40, 0
db 40, 0, 44, 0
db 40, 0, 44, 0
db 44, 0, 48, 0
db 44, 0, 48, 0
db 48, 0, 52, 0
db 48, 0, 52, 0
db 52, 0, 56, 0
db 52, 0, 56, 0
db 52, 0, 56, 0
db 52, 0, 52, 0
db 56, 0, 48, 0
db 56, 0, 44, 0
db 60, 4, 40, 0
db 60, 4, 36, 0
db 64, 4, 32, 0
db 64, 4, 28, 0
db 68, 4, 28, 0
db 68, 4, 24, 0
db 72, 4, 20, 0
db 72, 4, 16, 0
db 76, 8, 12, 0
db 76, 8, 8, 0
db 80, 8, 4, 0
db 80, 8, 0, 0
db 85, 8, 0, 0
db 89, 12, 0, 0
db 93, 12, 0, 0
db 97, 12, 0, 0
db 97, 16, 4, 0
db 101, 16, 4, 0
db 105, 16, 4, 0
db 109, 20, 4, 0
db 113, 20, 4, 0
db 117, 20, 4, 0
db 121, 20, 4, 0
db 125, 24, 4, 0
db 125, 24, 4, 0
db 129, 24, 4, 0
db 133, 28, 4, 0
db 137, 28, 4, 0
db 141, 28, 4, 0
db 145, 32, 4, 0
db 145, 32, 8, 0
db 149, 32, 8, 0
db 153, 36, 8, 0
db 157, 36, 8, 0
db 161, 40, 8, 0
db 165, 40, 8, 0
db 170, 44, 8, 0
db 174, 44, 8, 0
db 178, 48, 8, 0
db 182, 48, 8, 0
db 186, 52, 8, 0
db 190, 52, 8, 0
db 190, 52, 12, 0
db 194, 56, 12, 0
db 198, 56, 12, 0
db 202, 60, 12, 0
db 206, 60, 12, 0
db 210, 64, 12, 0
db 214, 64, 12, 0
db 218, 68, 12, 0
db 222, 68, 12, 0
db 226, 68, 12, 0
db 230, 72, 12, 0
db 234, 72, 12, 0
db 234, 76, 16, 0
db 238, 76, 16, 0
db 242, 80, 16, 0
db 246, 80, 16, 0
db 250, 85, 16, 0
db 255, 85, 16, 0
db 255, 85, 16, 0
db 255, 89, 16, 0
db 255, 93, 16, 0
db 255, 93, 16, 0
db 255, 97, 20, 0
db 255, 101, 20, 0
db 255, 101, 20, 0
db 255, 105, 20, 0
db 255, 109, 20, 0
db 255, 109, 20, 0
db 255, 113, 20, 0
db 255, 117, 20, 0
db 255, 117, 24, 0
db 255, 121, 24, 0
db 255, 125, 24, 0
db 255, 125, 24, 0
db 255, 129, 24, 0
db 255, 129, 24, 0
db 255, 133, 24, 0
db 255, 137, 24, 0
db 255, 137, 28, 0
db 255, 141, 28, 0
db 255, 145, 28, 0
db 255, 145, 28, 0
db 255, 149, 28, 0
db 255, 153, 28, 0
db 255, 153, 28, 0
db 255, 157, 28, 0
db 255, 161, 32, 0
db 255, 161, 32, 0
db 255, 165, 32, 0
db 255, 170, 32, 0
db 255, 170, 32, 0
db 255, 174, 32, 0
db 255, 178, 32, 0
db 255, 178, 32, 0
db 255, 182, 36, 0
db 255, 186, 36, 0
db 255, 186, 36, 0
db 255, 190, 36, 0
db 255, 194, 36, 0
db 255, 194, 36, 0
db 255, 198, 36, 0
db 255, 202, 36, 0
db 255, 202, 40, 0
db 255, 206, 40, 0
db 255, 210, 40, 0
db 255, 210, 40, 0
db 255, 214, 40, 0
db 255, 218, 40, 0
db 255, 218, 40, 0
db 255, 222, 40, 0
db 255, 226, 44, 0
db 255, 226, 44, 0
db 255, 230, 44, 0
db 255, 234, 44, 0
db 255, 234, 44, 0
db 255, 238, 44, 0
db 255, 242, 44, 0
db 255, 242, 44, 0
db 255, 246, 48, 0
db 255, 250, 48, 0
db 255, 250, 48, 0
db 255, 255, 48, 0
db 255, 255, 48, 0
db 255, 255, 52, 0
db 255, 255, 52, 0
db 255, 255, 56, 0
db 255, 255, 56, 0
db 255, 255, 60, 0
db 255, 255, 60, 0
db 255, 255, 64, 0
db 255, 255, 64, 0
db 255, 255, 68, 0
db 255, 255, 68, 0
db 255, 255, 72, 0
db 255, 255, 72, 0
db 255, 255, 76, 0
db 255, 255, 80, 0
db 255, 255, 80, 0
db 255, 255, 85, 0
db 255, 255, 85, 0
db 255, 255, 89, 0
db 255, 255, 89, 0
db 255, 255, 93, 0
db 255, 255, 93, 0
db 255, 255, 97, 0
db 255, 255, 97, 0
db 255, 255, 101, 0
db 255, 255, 101, 0
db 255, 255, 105, 0
db 255, 255, 105, 0
db 255, 255, 109, 0
db 255, 255, 113, 0
db 255, 255, 113, 0
db 255, 255, 117, 0
db 255, 255, 117, 0
db 255, 255, 121, 0
db 255, 255, 121, 0
db 255, 255, 125, 0
db 255, 255, 125, 0
db 255, 255, 129, 0
db 255, 255, 129, 0
db 255, 255, 133, 0
db 255, 255, 133, 0
db 255, 255, 137, 0
db 255, 255, 141, 0
db 255, 255, 141, 0
db 255, 255, 145, 0
db 255, 255, 145, 0
db 255, 255, 149, 0
db 255, 255, 149, 0
db 255, 255, 153, 0
db 255, 255, 153, 0
db 255, 255, 157, 0
db 255, 255, 157, 0
db 255, 255, 161, 0
db 255, 255, 161, 0
db 255, 255, 165, 0
db 255, 255, 170, 0
db 255, 255, 170, 0
db 255, 255, 174, 0
db 255, 255, 174, 0
db 255, 255, 178, 0
db 255, 255, 178, 0
db 255, 255, 182, 0
db 255, 255, 182, 0
db 255, 255, 186, 0
db 255, 255, 186, 0
db 255, 255, 190, 0
db 255, 255, 190, 0
db 255, 255, 194, 0
db 255, 255, 198, 0
db 255, 255, 198, 0
db 255, 255, 202, 0
db 255, 255, 202, 0
db 255, 255, 206, 0
db 255, 255, 206, 0
db 255, 255, 210, 0
db 255, 255, 210, 0
db 255, 255, 214, 0
db 255, 255, 214, 0
db 255, 255, 218, 0
db 255, 255, 218, 0
db 255, 255, 222, 0
db 255, 255, 222, 0
db 255, 255, 226, 0
db 255, 255, 230, 0
db 255, 255, 230, 0
db 255, 255, 234, 0
db 255, 255, 234, 0
db 255, 255, 238, 0
db 255, 255, 238, 0
db 255, 255, 242, 0
db 255, 255, 242, 0
db 255, 255, 246, 0
db 255, 255, 246, 0
db 255, 255, 250, 0
db 255, 255, 250, 0
db 255, 255, 255, 0
else

FirePalette db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 4, 0
db 0, 0, 12, 0
db 0, 0, 16, 0
db 0, 0, 24, 0
db 0, 0, 24, 0
db 4, 0, 24, 0
db 8, 0, 24, 0
db 12, 0, 24, 0
db 16, 0, 24, 0
db 24, 0, 24, 0
db 28, 0, 20, 0
db 32, 0, 20, 0
db 36, 0, 20, 0
db 40, 0, 20, 0
db 44, 0, 20, 0
db 52, 0, 20, 0
db 56, 0, 20, 0
db 60, 0, 16, 0
db 64, 0, 16, 0
db 68, 0, 16, 0
db 72, 0, 16, 0
db 80, 0, 16, 0
db 85, 0, 16, 0
db 89, 0, 12, 0
db 93, 0, 12, 0
db 97, 0, 12, 0
db 105, 0, 12, 0
db 109, 0, 12, 0
db 113, 0, 12, 0
db 117, 0, 8, 0
db 121, 0, 8, 0
db 125, 0, 8, 0
db 133, 0, 8, 0
db 137, 0, 8, 0
db 141, 0, 8, 0
db 145, 0, 4, 0
db 149, 0, 4, 0
db 153, 0, 4, 0
db 161, 0, 4, 0
db 165, 0, 4, 0
db 174, 0, 0, 0
db 174, 4, 0, 0
db 178, 4, 0, 0
db 178, 8, 0, 0
db 182, 12, 4, 0
db 186, 16, 4, 0
db 186, 20, 4, 0
db 190, 24, 8, 0
db 194, 28, 8, 0
db 194, 32, 8, 0
db 198, 36, 12, 0
db 198, 40, 12, 0
db 202, 44, 12, 0
db 206, 48, 16, 0
db 206, 52, 16, 0
db 210, 56, 16, 0
db 214, 60, 20, 0
db 214, 64, 20, 0
db 218, 64, 20, 0
db 218, 68, 20, 0
db 222, 72, 24, 0
db 226, 76, 24, 0
db 226, 80, 24, 0
db 230, 85, 28, 0
db 234, 89, 28, 0
db 234, 93, 28, 0
db 238, 97, 32, 0
db 238, 101, 32, 0
db 242, 105, 32, 0
db 246, 109, 36, 0
db 255, 121, 40, 0
db 255, 133, 40, 0
db 255, 145, 40, 0
db 255, 157, 40, 0
db 255, 174, 40, 0
db 255, 186, 40, 0
db 255, 198, 40, 0
db 255, 214, 40, 0
db 255, 226, 40, 0
db 255, 238, 40, 0
db 255, 242, 40, 0
db 255, 242, 44, 0
db 255, 242, 44, 0
db 255, 242, 48, 0
db 255, 242, 52, 0
db 255, 242, 56, 0
db 255, 242, 60, 0
db 255, 242, 64, 0
db 255, 242, 64, 0
db 255, 242, 68, 0
db 255, 242, 72, 0
db 255, 242, 76, 0
db 255, 242, 80, 0
db 255, 242, 80, 0
db 255, 242, 85, 0
db 255, 242, 89, 0
db 255, 242, 93, 0
db 255, 242, 97, 0
db 255, 242, 101, 0
db 255, 242, 101, 0
db 255, 242, 105, 0
db 255, 242, 109, 0
db 255, 246, 113, 0
db 255, 246, 117, 0
db 255, 246, 121, 0
db 255, 246, 121, 0
db 255, 246, 125, 0
db 255, 246, 129, 0
db 255, 246, 133, 0
db 255, 246, 137, 0
db 255, 246, 141, 0
db 255, 246, 141, 0
db 255, 246, 145, 0
db 255, 246, 149, 0
db 255, 246, 153, 0
db 255, 246, 157, 0
db 255, 246, 161, 0
db 255, 246, 161, 0
db 255, 246, 165, 0
db 255, 246, 170, 0
db 255, 246, 174, 0
db 255, 246, 178, 0
db 255, 246, 178, 0
db 255, 250, 182, 0
db 255, 250, 186, 0
db 255, 250, 190, 0
db 255, 250, 194, 0
db 255, 250, 198, 0
db 255, 250, 198, 0
db 255, 250, 202, 0
db 255, 250, 206, 0
db 255, 250, 210, 0
db 255, 250, 214, 0
db 255, 250, 218, 0
db 255, 250, 218, 0
db 255, 250, 222, 0
db 255, 250, 226, 0
db 255, 250, 230, 0
db 255, 250, 234, 0
db 255, 250, 238, 0
db 255, 250, 238, 0
db 255, 250, 242, 0
db 255, 250, 246, 0
db 255, 250, 250, 0
db 255, 255, 255, 0
db 255, 255, 255, 0
db 255, 255, 250, 0
db 255, 255, 250, 0
db 255, 255, 246, 0
db 255, 255, 246, 0
db 255, 250, 242, 0
db 255, 250, 242, 0
db 255, 250, 238, 0
db 255, 250, 238, 0
db 255, 250, 234, 0
db 255, 250, 234, 0
db 255, 250, 230, 0
db 255, 246, 230, 0
db 255, 246, 226, 0
db 255, 246, 226, 0
db 255, 246, 222, 0
db 255, 246, 222, 0
db 255, 246, 218, 0
db 255, 242, 218, 0
db 255, 242, 214, 0
db 255, 242, 214, 0
db 255, 242, 210, 0
db 255, 242, 210, 0
db 255, 242, 206, 0
db 255, 242, 206, 0
db 255, 238, 202, 0
db 255, 238, 202, 0
db 255, 238, 198, 0
db 255, 238, 198, 0
db 255, 238, 194, 0
db 255, 238, 194, 0
db 255, 234, 194, 0
db 255, 234, 190, 0
db 255, 234, 190, 0
db 255, 234, 186, 0
db 255, 234, 186, 0
db 255, 234, 182, 0
db 255, 230, 182, 0
db 255, 230, 178, 0
db 255, 230, 178, 0
db 255, 230, 174, 0
db 255, 230, 174, 0
db 255, 230, 170, 0
db 255, 230, 170, 0
db 255, 226, 165, 0
db 255, 226, 165, 0
db 255, 226, 161, 0
db 255, 226, 161, 0
db 255, 226, 157, 0
db 255, 226, 157, 0
db 255, 222, 153, 0
db 255, 222, 153, 0
db 255, 222, 149, 0
db 255, 222, 149, 0
db 255, 222, 145, 0
db 255, 222, 145, 0
db 255, 222, 141, 0
db 255, 218, 141, 0
db 255, 218, 137, 0
db 255, 218, 137, 0
db 255, 218, 133, 0
db 255, 218, 133, 0
db 255, 218, 129, 0
db 255, 214, 129, 0
db 255, 214, 125, 0
db 255, 214, 125, 0
db 255, 214, 121, 0
db 255, 214, 121, 0
db 255, 214, 117, 0
db 255, 210, 117, 0
db 255, 210, 113, 0
db 255, 210, 113, 0
db 255, 210, 109, 0
db 255, 210, 109, 0
db 255, 210, 105, 0
db 255, 210, 105, 0
db 255, 206, 101, 0
db 255, 206, 101, 0
db 255, 206, 97, 0
db 255, 206, 97, 0
db 255, 206, 93, 0
db 255, 206, 93, 0
db 255, 202, 89, 0
db 255, 202, 89, 0
db 255, 202, 85, 0
db 255, 202, 85, 0
db 255, 202, 80, 0
db 255, 202, 80, 0
db 255, 202, 76, 0
db 255, 198, 76, 0
db 255, 198, 72, 0
db 255, 198, 72, 0
db 255, 198, 68, 0
db 255, 198, 68, 0
db 255, 198, 64, 0
db 255, 194, 64, 0
db 255, 194, 64, 0
db 255, 194, 60, 0
db 255, 194, 60, 0
db 255, 194, 56, 0
db 255, 194, 56, 0
db 255, 190, 52, 0
db 255, 190, 52, 0
db 255, 190, 48, 0
db 255, 190, 48, 0
endif
        
;  PlasmaDefinition      PLASMA_DESCRIPTIONS_STRUCT<0, 0010456h, 1, 2, 2, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<100, 0, 0, -1, -3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<200, 0, 0, -2, -1, -1>
;                        PLASMA_DESCRIPTIONS_STRUCT<300, 0, 0, -1, 5, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<400, 0, 0, -5, 1, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<500, 0, 0, -1, 1, 6>
;                        PLASMA_DESCRIPTIONS_STRUCT<600, 0, 0, 1, 5, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<700, 0, 0, -1, -3, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<800, 0, 0, 2, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<900, 0, 0, 1, 3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1000, 0, 0, 5, 1, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1100, 0, 0, 5, 6, -1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1200, 0, 0, 3, 0, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1300, 0, 0, 0, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<1400, 0, 0, 2, 5, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<1500, 0, 0, -1, 0, 6>
;                        PLASMA_DESCRIPTIONS_STRUCT<1600, 0, 0, 0, 3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1700, 0, 0, 0, 3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<1800, 0, 0, -4, 0, 3>
;                        PLASMA_DESCRIPTIONS_STRUCT<1900, 0, 0, 0, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<2000, 0, 0, 1, 1, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<2100, 0, 0, -1, 4, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<2200, 0, 0, 1, -1, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<2300, 0, 0, 1, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<2350, 0, 0, 2, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<2500, 0, 0, 0, 1, 5>
;                        PLASMA_DESCRIPTIONS_STRUCT<2600, 0, 0, -2, 0, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<2700, 0, 0, 1, 1, -1>
;                        PLASMA_DESCRIPTIONS_STRUCT<2800, 0, 0, 0, 3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<2900, 0, 0, 0, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<3000, 0, 0, 1, 0, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<3100, 0, 0, 0, -1, 9>
;                        PLASMA_DESCRIPTIONS_STRUCT<3200, 0, 0, 1, 0, -1>
;                        PLASMA_DESCRIPTIONS_STRUCT<3300, 0, 0, -1, 5, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<3400, 0, 0, 1, -3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<3500, 0, 0, -5, -1, -1>
;                        PLASMA_DESCRIPTIONS_STRUCT<3600, 0, 0, 1, 3, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<3700, 0, 0, 1, 5, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<3800, 0, 0, 0, 1, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<3900, 0, 0, 1, 5, 0>
;                        PLASMA_DESCRIPTIONS_STRUCT<4000, 0, 0, 5, 0, 1>
;                        PLASMA_DESCRIPTIONS_STRUCT<10000, 0, 0, 0, 0, 0>  ; Not Reachable
;
;

 


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

  BottomTextPtr          dq OFFSET BottomText
  BottomText             db "Shout out to 90s demos like Kukoo2 Descent and Second Reality -- No demo would be complete without"
                         db " hard to read text talking about things no one understands anyway!  Special shout out to IRC Channels from"
                         db " the mid 90s #C #Coders #ASM #WIN32ASM #Winprog #GameDev #GameProg #RPGDEV ... Maybe I should also shout out"
                         db " some people from the mid 90s!  TheHornet PeZzA Bufferman Comrade fflush Zhivago Doc_O Sledgehammer"
                         db " Iczelion hutch MultiAGP PenT|uM SD_Adept fatslayer SilverStr coderman Dawai drano Furan KrZDG Eskimo programax"
                         db " [ryan] RuebiaYat spec t_gypsy Wyatt xor magey kritical Stonecyph Pizzi and many more I've left out!"
                         db " This was written in 100% x86 64-bit assembly language using a framework I have written for games and demos."
                         db " You can use it as well to write your own demos or games it is available on github!  https://github.com/opferman/SixtyFourBits"
                         db " Even if you dont know assembly you can learn!  You can write a pixel onto the screen in a few minutes with the framework!"
                         db " Demos would go on forever with text that you could barely comprehend what they were talking about so I have to figure out"
                         db " some more things to add!  I'm basically building up this Assembly graphics library.", 0
  PlasmaX                dq 1023
  PlasmaXIncrement       dq -3  
                         
  SineTablePtr           dq 0
  CosineTablePtr         dq 0

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


  FLASH_TO_BOLD_START      dq 1000
  BOLD_START               dq 1050
  FLASH_TO_LIGHT_START     dq 1500
  LIGHT_START              dq 1550
  FLASH_TO_SOLID_START     dq 2000
  SOLID_START              dq 2050
  FLASH_TO_UPSIDE_DOWN     dq 2500  
  UPSIDE_DOWN_START        dq 2550
  FLASH_TO_BOLD_UPSIDEDOWN dq 3000
  BOLD_RESTART             dq 3050



  HeightAngle            mmword 0.001
  WidthAngle             mmword 0.023
  HeightAngleInc         mmword 0.0001
  WidthAngleInc          mmword 0.0011
  MULTIPLER_X            mmword 0.001
  MULTIPLER_Y            mmword 1.013
  MULTIPLIER_Y_INC       mmword 0.12
  MULTIPLIER_X_INC       mmword 0.052

  SquareGrid             SQUARE_TRCKER <20, 10, 1, 3, 200, 200, -3, 250, 250>
  Transparent            dq 1
  PaletteArray           dq ?
  DoubleBuffer           dq ?
  FireDoubleBuffer       dq ?
;  PlasmaDoubleBuffer     dq ?
;  PlasmaPalette          dq ?
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
  
;  MOV RDX, PLASMA_WIDTH * PLASMA_HEIGHT * 2
;  MOV RCX, LMEM_ZEROINIT
;  DEBUG_FUNCTION_CALL LocalAlloc
;  MOV [PlasmaDoubleBuffer], RAX
;  TEST RAX, RAX
;  JZ @CopperInit_Failed

;  MOV RDX, 4096*4
;  MOV RCX, LMEM_ZEROINIT
;  DEBUG_FUNCTION_CALL LocalAlloc
;  MOV [PlasmaPalette], RAX
;  TEST RAX, RAX
;  JZ @CopperInit_Failed

;  DEBUG_FUNCTION_CALL CopperBarDemo_CreatePlasmaColorTable

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
  DEBUG_FUNCTION_CALL CopperBarsDemo_CreateSineTable
  DEBUG_FUNCTION_CALL CopperBarsDemo_CreateCosineTable

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
  ADD R11, VERTICLE_BAR_DIFFERENCE
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
  MOV R15, R14

  MOV RAX, [FLASH_TO_BOLD_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, R14


  TEST [DemoFrameCounter], 1
  JE @SkipTheSolid
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, R14
@SkipTheSolid:
  MOV RAX, [BOLD_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, R14
    
  MOV RAX, [FLASH_TO_LIGHT_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsLightTransparent
  MOV R15, R14

  MOV RAX, [DemoFrameCounter]
  AND AL, 3
  CMP AL, 2
  JB @SkipTheDark
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, R14
@SkipTheDark:

  MOV RAX, [LIGHT_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsLightTransparent
  MOV R15, R14  
  MOV RAX, [FLASH_TO_SOLID_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, R14
  TEST [DemoFrameCounter], 1
  JE @SkipTheLight
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, R14
@SkipTheLight:
  MOV RAX, [SOLID_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, R14

  MOV RAX, [FLASH_TO_UPSIDE_DOWN]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, OFFSET CopperBarDemo_DrawVertBarSolidUpsidedown  

  TEST [DemoFrameCounter], 1
  JE @SkipTheLight2
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, OFFSET CopperBarDemo_DrawVertBarSolid  
@SkipTheLight2:
  MOV RAX, [UPSIDE_DOWN_START]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, OFFSET CopperBarDemo_DrawVertBarSolidUpsidedown  

  MOV RAX, [FLASH_TO_BOLD_UPSIDEDOWN]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars
  MOV R14, OFFSET CopperBarDemo_DrawVertBarSolid
  MOV R15, OFFSET CopperBarDemo_DrawVertBarSolidUpsidedown  

  TEST [DemoFrameCounter], 1
  JE @SkipTheLight3
  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent  
@SkipTheLight3:
  MOV RAX, [BOLD_RESTART]
  CMP [DemoFrameCounter], RAX
  JB @DrawVerticleBars

  MOV R14, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent
  MOV R15, OFFSET CopperBarDemo_DrawVertBarsDarkTransparent  
  ; 
  ; Reset cycle
  ;
  MOV RAX, [BOLD_RESTART]
  MOV [BOLD_START], RAX
  ADD RAX, 500
  MOV [FLASH_TO_LIGHT_START], RAX
  MOV RCX, 100
  ADD RCX, RAX
  MOV [LIGHT_START], RCX
  ADD RAX, 500
  MOV [FLASH_TO_SOLID_START], RAX
  MOV RCX, 100
  ADD RCX, RAX
  MOV [SOLID_START], RCX
  ADD RAX, 500
  MOV [FLASH_TO_UPSIDE_DOWN], RAX
  MOV RCX, 100
  ADD RCX, RAX
  MOV [UPSIDE_DOWN_START], RCX
  ADD RAX, 500
  MOV [FLASH_TO_BOLD_UPSIDEDOWN], RAX
  MOV RCX, 100
  ADD RCX, RAX
  MOV [BOLD_RESTART], RCX

@DrawVerticleBars:

  MOV RDX, R12
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL R15

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
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarDemo_PerformPlasma

  MOV RCX, RDI
  DEBUG_FUNCTION_CALL CopperBarsDemo_DisplaySineText

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
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 4]
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 4]
;  SHR DL, 1
  ADD AX, DX
  SHR RAX, 3
  MOV [R14], AL
  SUB R14, R11
  
  ;
  ; Green
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 1]
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 5]
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
;  SHR DL, 1
  ADD AX, DX
  SHR RAX, 3
  MOV [R14 + 1], AL
  SUB R14, R11

  ;
  ; Red
  ;
  XOR RDX, RDX
  XOR RAX, RAX
  MOV AL, BYTE PTR [RCX + 1]
  MOV DL, BYTE PTR [R14 + 2]
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  MOV DL, BYTE PTR [R14 + 6]
;  SHR DL, 1
  ADD AX, DX
  XOR RDX, RDX
  ADD R14, R11
  MOV DL, BYTE PTR [R14 + 5]
;  SHR DL, 1
  ADD AX, DX
  SHR RAX, 3
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
;  CopperBarDemo_DrawVertBarSolidUpsidedown
;
;        Parameters: MMaster Context, Vert Bar Structure
;
;       
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DrawVertBarSolidUpsidedown, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX 
  MOV R15, RDX
  MOV RDI, [DoubleBuffer]
  XOR RDX, RDX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV R8, VERTICLE_BAR_START
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
  MOV R10, VERTICLE_BAR_START
  MOV R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R11, 2
  MOV R14, RDI

 @DrawVerticleLine:
    MOV R12D, DWORD PTR [RCX]
    MOV DWORD PTR [R14], R12D
    ADD R14, R11
    INC R10

    MOV RAX, COPPERBARS_FIELD_ENTRY.Y[R15]
    SUB RAX, VERTICLE_BAR_START
    MOV R12, VERTICLE_BAR_END
    SUB R12, RAX

    CMP R10, R12
    JB @DrawVerticleLine

    ADD RCX, 4
    ADD RDI, 4
    INC RBX
    CMP RBX, 20
    JB @DrawVerticleBar

    RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DrawVertBarSolidUpsidedown, _TEXT$00


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
  MOV RCX, 255
  TEST RBX, 1
  JZ @ContinueNumber
  MOV RCX, 160
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

  CMP AX, 40
  JA @SkipForceZero
  XOR AX, AX
@SkipForceZero:
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
  MOV RCX, FIRE_START_Y + 11
  MUL RCX

  ADD RDI, RAX

  XOR R8, R8
@CopyFireLoop:
  XOR R9, R9
@CopyFireRow:
  XOR RAX, RAX
  CMP R8, FIRE_HEIGHT-15
  JA @SkipZeroCheck
  MOV AX, WORD PTR [RSI]
  CMP EAX, 0
  JE @NothingToPlot
  SHL EAX, 2
  CMP DWORD PTR [R10 + RAX], 0
  JE @NothingToPlot
@SkipZeroCheck:
  XOR R11, R11
  XOR RCX, RCX
  XOR RDX, RDX
  ADD RAX, 2
  MOV CL, BYTE PTR [R10 + RAX]
  MOV BYTE PTR [RDI], CL

  DEC RAX
  MOV CL, BYTE PTR [R10 + RAX]
  MOV BYTE PTR [RDI + 1], CL

  DEC RAX
  MOV CL, BYTE PTR [R10 + RAX]
  MOV BYTE PTR [RDI + 2], CL
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
  CMP R8, FIRE_HEIGHT
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
;  XOR R12, R12
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
;  ADD RDX, R12
  DEBUG_FUNCTION_CALL CopperBarDemo_SineWave
  MOV COPPERBARS_FIELD_ENTRY.X[RDI], RAX
  
;  MOV RAX, R12
;  ADD RAX, WAVE_TRACKER.WaveRange[R15]
;  ADD RAX, 15
;  CMP RAX, COPPER_BARS_RANGE_HIGH
;  JAE @QuitAdding
;  ADD R12, 15
;@QuitAdding:
  
  MOV R13, COPPERBARS_FIELD_ENTRY.X[RDI]
  SUB RDI, SIZEOF COPPERBARS_FIELD_ENTRY
  INC RSI  
  CMP RSI, NUMBER_OF_VERTICLE_BARS
  JB @CopperBarsPlot

  MOV RAX, WAVE_TRACKER.WaveVelocity[R15]
  ADD WAVE_TRACKER.WaveThetaAddition[R15], RAX


  DEBUG_FUNCTION_CALL Math_rand

  AND RAX, 0FFh

  CMP RAX, 100
  JA @DoNotUpdateRange
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
@DoNotUpdateRange:
@DoneUpdateRange:

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
  MOV RDX, 0
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  ;CVTSI2SD XMM0, RCX
  ;MOV RAX, 180
  ;CVTSI2SD XMM1, RAX
  ;DIVSD XMM0, XMM1
  ;MOVSD XMM1, [PI]
  ;MULSD XMM0, XMM1
  ;DEBUG_FUNCTION_CALL sin
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


;*********************************************************
;  CopperBarDemo_PerformPlasma (Not Plasma)
;
;        Parameters: Master Struct
;
;             Well, ended up not really being a plasma,
;             but it was cool looking and kinda fit in with the
;             color bars in the other segments, so I kept it.
;               I was thinking that a plasma may look out of place anyway.
;   
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_PerformPlasma, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
  SAVE_ALL_XMM_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
 ; MOV RSI, [PlasmaDoubleBuffer]
  MOV RDI, [DoubleBuffer]
  MOV RAX, PLASMA_AREA_START
  XOR RDX, RDX
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RCX]
  SHL RCX,2
  MUL RCX
  ADD RDI, RAX
  PXOR XMM8, XMM8

  XOR R12, R12
@PlasmaHeight:
  XOR R13, R13

@PlasmaWidth:

  MOV RAX, 3
  CVTSI2SD XMM0, RAX
  CVTSI2SD XMM1, R13
  CVTSI2SD XMM2, R12
  MULSD XMM1, XMM1
  MULSD XMM2, XMM2
  MULSD XMM0, XMM1
  ADDSD XMM0, XMM2
  ADDSD XMM0, XMM8
  CVTSD2SI RCX, XMM0
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  CVTSI2SD XMM1, [DemoFrameCounter]
  MULSD XMM0, XMM1
  MOVSD XMM6, XMM0


  CVTSI2SD XMM1, R12
  CVTSI2SD XMM2, R13
  MOVSD XMM0, XMM1
  MULSD XMM1, XMM1
  MULSD XMM1, XMM0
  MOV RAX, 3
  CVTSI2SD XMM0, RAX
  MULSD XMM0, XMM1

  MULSD XMM2, XMM2
  SUBSD XMM0, XMM2
  ADDSD XMM0, XMM8
  CVTSD2SI RCX, XMM0
  DEBUG_FUNCTION_CALL CopperBarsDemo_Cos
  MOV RAX, R13
  INC RAX
  CVTSI2SD XMM1, RAX
  CVTSI2SD XMM2, [DemoFrameCounter]
  DIVSD XMM1, XMM2
  MULSD XMM0, XMM1

  ADDSD XMM6, XMM0
  MOV RAX, 1
  CVTSI2SD XMM1, RAX
  ADDSD XMM6, XMM1
  MOV RAX, 180
  CVTSI2SD XMM1, RAX
  MULSD XMM6, XMM1
  CVTSD2SI RCX, XMM6
  ADD RCX, R13
  ADD RCX, R12
  XOR RDX, RDX
  MOV RAX, 360
  XCHG RAX, RCX
  DIV RCX

  ; Blue
  MOV R15, RDX
  MOV RCX, RDX
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  MOV RAX, 1
  CVTSI2SD XMM1, RAX
  ADDSD XMM0, XMM1
  MOV RAX, 127
  CVTSI2SD XMM1, RAX
  MULSD XMM0, XMM1
  CVTSD2SI RAX, XMM0

;  CMP R12, 0
;  JE @SkipForFirstRow
;  CMP R12, PLASMA_HEIGHT-1
;  JE @SkipForLastRow
;  XOR RCX, RCX
;  XOR RDX, RDX
;  XOR R8, R8
;  MOV CL, BYTE PTR [RSI - 4]
;  MOV DL, BYTE PTR [RSI + 4]
;  MOV R8B, BYTE PTR [RSI - PLASMA_WIDTH*4]
 ; ADD CX, DX
 ; ADD CX, R8W
 ; ADD AX, CX
 ; SHR AX, 2 
@SkipForFirstRow:
@SkipForLastRow:
  MOV BYTE PTR [RDI], AL

  ; Green
  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarsDemo_Cos
  MOV RAX, 1
  CVTSI2SD XMM1, RAX
  ADDSD XMM0, XMM1
  MOV RAX, 127
  CVTSI2SD XMM1, RAX
  MULSD XMM0, XMM1
  CVTSD2SI RAX, XMM0

;  CMP R12, 0
;  JE @SkipForFirstRow2
;  CMP R12, PLASMA_HEIGHT-1
;  JE @SkipForLastRow2
;  XOR RCX, RCX
;  XOR RDX, RDX
;  XOR R8, R8
;  MOV CL, BYTE PTR [RSI - 3]
;  MOV DL, BYTE PTR [RSI + 5]
;  MOV R8B, BYTE PTR [RSI - PLASMA_WIDTH*4+1]
;  ADD CX, DX
;  ADD CX, R8W
;  ADD AX, CX
;  SHR AX, 2 

@SkipForFirstRow2:
@SkipForLastRow2:
  MOV BYTE PTR [RDI + 1], AL

  ;Red
  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  MULSD XMM0, XMM0
  MOV RAX, 1
  CVTSI2SD XMM1, RAX
  ADDSD XMM0, XMM1
  MOV RAX, 127
  CVTSI2SD XMM1, RAX
  MULSD XMM0, XMM1
  CVTSD2SI RAX, XMM0

;  CMP R12, 0
;  JE @SkipForFirstRow3
;  CMP R12, PLASMA_HEIGHT-1
;  JE @SkipForLastRow3
;  XOR RCX, RCX
;  XOR RDX, RDX
;  XOR R8, R8
;  MOV CL, BYTE PTR [RSI - 2]
;  MOV DL, BYTE PTR [RSI + 6]
;  MOV R8B, BYTE PTR [RSI - PLASMA_WIDTH*4+2]
;  ADD CX, DX
;  ADD CX, R8W
;  ADD AX, CX
;  SHR AX, 2 

@SkipForFirstRow3:
@SkipForLastRow3:


  MOV BYTE PTR [RDI + 2], AL


; MOV CX, [RSI-2]
; MOV DX, [RSI+2]
; ADD CX, DX
;
;PXOR XMM0, XMM0
;PXOR XMM1, XMM1
;PXOR XMM6, XMM6
;CVTSI2SD XMM0, RCX
;MOVSD XMM1, [PI]
;MULSD XMM0, XMM1              ; X * PI
;MOV RAX, 360
;CVTSI2SD XMM1, RAX
;DIVSD XMM0, XMM1              ; (X * PI) / 360
;MOVSD XMM1, [WidthAngle]
;MULSD XMM0, XMM1
;
;DEBUG_FUNCTION_CALL sin
;;MOVSD XMM6, [MULTIPLER_Y]
;MOVSD XMM6, XMM0
;
; MOVSD XMM0, [HeightAngle]
;MULSD XMM0, XMM7
;DEBUG_FUNCTION_CALL sin
;MOVSD XMM1, [MULTIPLER_X]
;MULSD XMM1, XMM0
;ADDSD XMM6, XMM1
;MOVSD XMM1, [WidthAngle]
;MULSD XMM0, XMM1
;DEBUG_FUNCTION_CALL cos
;MULSD XMM6, XMM0
;
;MOV RAX, PLASMA_CENTER
;CVTSI2SD XMM1, RAX
;MULSD XMM6, XMM1

;  CVTSD2SI RAX, XMM6
;  MOV CL, AL
;  SHL EAX, 16
;  MOV AH, CL
;  MOV AL, CL

 ; ADD AX, WORD PTR [RSI]
 ; ADD CX, DX
 ; SHR RAX, 2
 ; AND RAX, (4096-1)
 ; MOV WORD PTR [RSI], AX
 ; SHL RAX, 2
 ; ADD RAX, [PlasmaPalette]
 ; MOV EAX, DWORD PTR [RAX]
;  MOV DWORD PTR [RDI], EAX

;  ADD RSI, 2
  MOV RAX, 1
  CVTSI2SD XMM1, RAX
  ADDSD XMM8, XMM1
  ADD RDI, 4
  INC R13
  CMP R13, PLASMA_WIDTH
  JB @PlasmaWidth
  INC R12
  CMP R12, PLASMA_HEIGHT
  JB @PlasmaHeight

;  MOVSD xmm1, [HeightAngleInc]
;  MOVSD xmm0, [HeightAngle]
;  ADDSD xmm0, xmm1
;  MOVSD [HeightAngle], xmm0
;
;  MOVSD xmm1, [WidthAngleInc]
;  MOVSD xmm0, [WidthAngle]
;  ADDSD xmm0, xmm1
;  MOVSD [WidthAngle], xmm0
;
;  MOVSD xmm1, [MULTIPLIER_Y_INC]
;  MOVSD xmm0, [MULTIPLER_Y]
;  ADDSD xmm0, xmm1
;  MOVSD [MULTIPLER_Y], xmm0
;
;  MOVSD xmm1, [MULTIPLIER_X_INC]
;  MOVSD xmm0, [MULTIPLER_X]
;  ADDSD xmm0, xmm1
;  MOVSD [MULTIPLER_X], xmm0
;

  RESTORE_ALL_XMM_REGS STD_FUNCTION_STACK
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_PerformPlasma, _TEXT$00




;;*********************************************************
;;  CopperBarDemo_CreatePlasmaColorTable
;;
;;        Parameters: Angle (Theta), Multiplier, Center
;;
;;           Return = Multiplier*SIN(Theta) + Center
;;
;;
;;*********************************************************  
;NESTED_ENTRY CopperBarDemo_CreatePlasmaColorTable, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
;  DEBUG_RSP_CHECK_MACRO
;  MOV RDI, [PlasmaPalette]
;  MOV RSI, OFFSET PlasmaDefinition
;  MOV R12, RSI
;  ADD R12, SIZE PLASMA_DESCRIPTIONS_STRUCT
;  XOR RAX, RAX
;  XOR RBX, RBX
;@StartPlasmaPaletteEntry:
;
;  CMP PLASMA_DESCRIPTIONS_STRUCT.UseStartColor[RSI], 0
;  JE @SetColors
;
;  MOV EAX, PLASMA_DESCRIPTIONS_STRUCT.StartColor[RSI]
;  JMP @SetColorDirectly
;  
;@SetColors:
;  ;
;  ; Right now allow wrap around instead of truncate.
;  ;
;  MOV EDX, EAX
;  SHR EAX, 16
;  XOR AH, AH
;  XOR CX, CX
;  MOVSX CX, PLASMA_DESCRIPTIONS_STRUCT.RedVelocity[RSI]
;  ADD AX, CX
;  CMP AX, 0
;  JL @NegativeRed
;
;  CMP AX, 255
;  JL @SkipForceUpdate
;
;  MOV AX, 255
;  NEG PLASMA_DESCRIPTIONS_STRUCT.RedVelocity[RSI]
;  JMP @SkipForceUpdate
;@NegativeRed:
;  MOV AX, 0
;  NEG PLASMA_DESCRIPTIONS_STRUCT.RedVelocity[RSI]
;@SkipForceUpdate:
;  SHL EAX, 16
;  
;  MOVSX CX, PLASMA_DESCRIPTIONS_STRUCT.GreenVelocity[RSI]
;  MOV AL, DH
;  ADD AX, CX
;
;  CMP AX, 0
;  JL @NegativeGreen
;  CMP AX, 255
;  JL @SkipForceUpdateGreen
;  MOV AX, 255
;  NEG PLASMA_DESCRIPTIONS_STRUCT.GreenVelocity[RSI]
;  JMP @SkipForceUpdateGreen
;@NegativeGreen:
;  MOV AX, 0
;  NEG PLASMA_DESCRIPTIONS_STRUCT.GreenVelocity[RSI]
;
;@SkipForceUpdateGreen:
;  MOV DH, AL
;
;  MOV AL, DL
;  MOVSX CX, PLASMA_DESCRIPTIONS_STRUCT.BlueVelocity[RSI]
;  ADD AX, CX
;  CMP AX, 0
;  JE @NegativeBlue
;
;  CMP AX, 255
;  JL @SkipForceUpdateBlue
;
;  MOV AX, 255
;  NEG PLASMA_DESCRIPTIONS_STRUCT.BlueVelocity[RSI]
;  JMP @SkipForceUpdateBlue
;@NegativeBlue:
;  MOV AX, 0
;  NEG PLASMA_DESCRIPTIONS_STRUCT.BlueVelocity[RSI]
;@SkipForceUpdateBlue:
;  MOV AH, DH
;
;@SetColorDirectly:
;  MOV DWORD PTR [RDI], EAX
;  CMP EAX, 0FFFFFFh
;  JNE @KeepGoing
;  INT 3
;@KeepGoing:
;  ADD RDI, 4
;  INC RBX
;  CMP RBX, 4096
;  JE @DoneWithColors  
;
;  CMP PLASMA_DESCRIPTIONS_STRUCT.StartRange[R12], RBX
;  JNE @SetColors
;  MOV RSI, R12
;  ADD R12, SIZE PLASMA_DESCRIPTIONS_STRUCT
;  JMP @StartPlasmaPaletteEntry
;@DoneWithColors:
;
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END CopperBarDemo_CreatePlasmaColorTable, _TEXT$00
;
;*********************************************************
;  CopperBarsDemo_CreateSineTable
;
;        Parameters: 
;
;
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_CreateSineTable, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, 360 * TRIG_TABLE_SIZE * SIZE MMWORD
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JZ @FailedAllocation
  MOV [SineTablePtr], RAX

  PXOR XMM0, XMM0
  PXOR XMM1, XMM1
  PXOR XMM6, XMM6
  XOR RBX, RBX
  MOV RDI, [SineTablePtr]

  ;
  ; Create incremental angle and convert to radians
  ;
  MOV RAX, TRIG_TABLE_SIZE
  CVTSI2SD XMM1, RAX
  MOV RAX, 360
  CVTSI2SD XMM0, RAX
  MOVSD XMM2, XMM0
  DIVSD XMM0, XMM1
  DIVSD XMM0, XMM2
  MOVSD XMM6, XMM0
  MOVSD XMM1, [PI]
  MULSD XMM6, XMM1
  MOV RAX, 180
  CVTSI2SD XMM2, RAX
  DIVSD XMM6, XMM2
  PXOR XMM7, XMM7
@LoopForSineTableGeneration:
  MOVSD XMM0, XMM7
  DEBUG_FUNCTION_CALL sin
  MOVSD MMWORD PTR [RDI], XMM0
  ADD RDI, SIZEOF MMWORD
  ADDSD XMM7, XMM6
  INC RBX
  CMP RBX, 360 * TRIG_TABLE_SIZE
  JB @LoopForSineTableGeneration
@FailedAllocation:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_CreateSineTable, _TEXT$00

;*********************************************************
;  CopperBarsDemo_CreateCosineTable
;
;        Parameters: 
;
;
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_CreateCosineTable, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RDX, RDX
  MOV RDX, 360 * TRIG_TABLE_SIZE * SIZE MMWORD
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX, 0
  JZ @FailedAllocation
  MOV [CosineTablePtr], RAX

  PXOR XMM0, XMM0
  PXOR XMM1, XMM1
  PXOR XMM6, XMM6
  XOR RBX, RBX
  MOV RDI, [CosineTablePtr]

  ;
  ; Create incremental angle and convert to radians
  ;
  MOV RAX, TRIG_TABLE_SIZE
  CVTSI2SD XMM1, RAX
  MOV RAX, 360
  CVTSI2SD XMM0, RAX
  MOVSD XMM2, XMM0
  DIVSD XMM0, XMM1
  DIVSD XMM0, XMM2
  MOVSD XMM6, XMM0
  MOVSD XMM1, [PI]
  MULSD XMM6, XMM1
  MOV RAX, 180
  CVTSI2SD XMM2, RAX
  DIVSD XMM6, XMM2
  PXOR XMM7, XMM7
@LoopForSineTableGeneration:
  MOVSD XMM0, XMM7
  DEBUG_FUNCTION_CALL cos
  MOVSD MMWORD PTR [RDI], XMM0
  ADD RDI, SIZEOF MMWORD
  ADDSD XMM7, XMM6
  INC RBX
  CMP RBX, 360 * TRIG_TABLE_SIZE
  JB @LoopForSineTableGeneration
@FailedAllocation:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_CreateCosineTable, _TEXT$00


;*********************************************************
;  CopperBarsDemo_Cos
;
;        Parameters: Angle, Strap to 360
;
;
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Cos, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP RDX, 1
  JNZ @SkipStrapping
  XOR RDX, RDX
  MOV RAX, TRIG_TABLE_SIZE
  MUL RCX
  MOV RCX, RAX
@SkipStrapping:
  CMP RCX, 360*TRIG_TABLE_SIZE
  JB @NoNeedToWrap
  XOR RDX, RDX
  MOV RCX, 360*TRIG_TABLE_SIZE
  MUL RCX
  MOV RCX, RDX
@NoNeedToWrap:
  MOV RDI, [CosineTablePtr]
  SHL RCX, 3
  ADD RDI, RCX
  MOVSD XMM0, MMWORD PTR [RDI]
@FailedAllocation:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Cos, _TEXT$00

;*********************************************************
;  CopperBarsDemo_Sin
;
;        Parameters: Angle, Strap to 360
;
;
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_Sin, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
@RetryNegative:
  CMP RCX, 0
  JG @Positive
  ADD RCX, 360
  JMP @RetryNegative
@Positive:
  CMP RDX, 1
  JNZ @SkipStrapping
  XOR RDX, RDX
  MOV RAX, TRIG_TABLE_SIZE
  MUL RCX
  MOV RCX, RAX
@SkipStrapping:
  CMP RCX, 360*TRIG_TABLE_SIZE
  JB @NoNeedToWrap
  XOR RDX, RDX
  MOV RCX, 360*TRIG_TABLE_SIZE
  DIV RCX
  MOV RCX, RDX
@NoNeedToWrap:
  MOV RDI, [SineTablePtr]
  SHL RCX, 3
  ADD RDI, RCX
  MOVSD XMM0, MMWORD PTR [RDI]
@FailedAllocation:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_Sin, _TEXT$00




;*********************************************************
;  CopperBarDemo_DisplaySineLetter
;
;        Parameters: Letter, X/Angle/Letter Center, Multiplier, CenterOffset
;
;           
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DisplaySineLetter, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RDX                                  ; X which is used as the angle.  It is also the center X of the letter.
  MOV R13, R8                                   ; Multiplier
  MOV R14, R9                                   ; Center-OFFSET

  DEBUG_FUNCTION_CALL Font_GetBitFont  
  MOV RSI, RAX
  
  ;
  ; Set the Double Buffer to the plasma area start.
  ;
  MOV RDI, [DoubleBuffer]


  MOV RDX, 1
  MOV RCX, R12
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  CVTSI2SD XMM1, R13
  CVTSI2SD XMM2, R14
  MULSD XMM0, XMM1
  ADDSD XMM0, XMM2
  CVTSD2SI R11, XMM0

  ;
  ; Adjust center X to left for X.
  ;
  MOV RAX, SIN_FONT_WIDTH_SIZE
  SHL RAX, 3                            ; Ya, could do this in 1 SHL RAX, 2
  SHR RAX, 1
  SUB R12, RAX
  
  MOV RDX, SIN_FONT_WIDTH_SIZE*8
  MOV RCX, R12
  ADD RCX, RDX

  XOR RAX, RAX
  CMP RCX, 0
  JLE @OffScreenLetter

  ;
  ; Adjust center Y for top row
  ;
  XOR RDX, RDX
  MOV RAX, SIN_FONT_HEIGHT_SIZE_PER_LINE

  SHL RAX, 3                            ;  Ya, could do this in 1 SHL RAX, 2
  SHR RAX, 1
  SUB R11, RAX
  
  ;
  ; Set drawing to start location for Y/X[0]
  ;
  XOR RDX, RDX
  MOV RAX, PLASMA_AREA_START
  ADD RAX, R11
  MOV RCX, PLASMA_WIDTH
  MUL RCX
  SHL RAX,2
  ADD RDI, RAX
  MOV R15, R12
  CMP R12, 0
  JGE @NoAdjustment
  XOR R12, R12
@NoAdjustment:
  SHL R12, 2
  ADD RDI, R12

  XOR R8, R8  
@HeightLoop:
  MOV R9, SIN_FONT_HEIGHT_SIZE_PER_LINE
@FontSizeHeightLoop:
  XOR DL, DL
  MOV AL, BYTE PTR [RSI]
  MOV AH, 080h
  XOR R11, R11
  MOV R10, R15
@WidthLoop:
  TEST AL, AH
  JZ @NoDraw
  MOV RCX, SIN_FONT_WIDTH_SIZE
@DrawIt:
  CMP R10, 0
  JL @SkipDrawingPart
  CMP R10, PLASMA_WIDTH
  JGE @SkipDrawingPart

  MOV RBP, R11
  SUB RBP, PLASMA_WIDTH*5
  MOV EBP, DWORD PTR [RDI + RBP]
  MOV DWORD PTR [RDI + R11], EBP
;  SHL RAX, 16
;  MOV AL, BYTE PTR [RDI + R11]
;  MOV AH, 255
;  SUB AH, AL
;  SHR AH, 1
;  ADD AL, AH
;  MOV BYTE PTR [RDI + R11], AL
;
;  MOV RBP, R11
;  INC RBP
;  MOV AL, BYTE PTR [RDI + RBP]
;  MOV AH, 255
;  SUB AH, AL
;  SHR AH, 1
;  ADD AL, AH
;  MOV BYTE PTR [RDI + RBP], AL
;  
;  INC RBP
;  MOV AL, BYTE PTR [RDI + RBP]
;  MOV AH, 255
;  SUB AH, AL
;  SHR AH, 1
;  ADD AL, AH
;  MOV BYTE PTR [RDI + RBP], AL
;  SHR RAX, 16

  ADD R11, 4
@SkipDrawingPart:
  INC R10
  DEC RCX
  JNZ @DrawIt
  JMP @DontDoubleRemove
@NoDraw:
  MOV RCX, SIN_FONT_WIDTH_SIZE
@NoDrawLoop:
  CMP R10, 0
  JL @SkipNoDrawingPart
  CMP R10, PLASMA_WIDTH
  JGE @SkipNoDrawingPart
  ADD R11, 4
@SkipNoDrawingPart:    
  INC R10
  DEC RCX
  JNZ @NoDrawLoop
@DontDoubleRemove:
  SHR AH, 1
  INC DL
  CMP DL, 8
  JB @WidthLoop
  DEC R9
  JZ @NextLine
 
  XOR R11, R11
  ADD RDI, PLASMA_WIDTH*4
  JMP @FontSizeHeightLoop

@NextLine:
  ADD RDI, PLASMA_WIDTH*4
  INC RSI
  INC DH
  CMP DH, 8
  JB @HeightLoop

  MOV RAX, 1
 @OffScreenLetter:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DisplaySineLetter, _TEXT$00


;*********************************************************
;  CopperBarsDemo_DisplaySineText
;
;        Parameters: Master Context
;
;
;
;
;*********************************************************  
NESTED_ENTRY CopperBarsDemo_DisplaySineText, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV R13, 1
  MOV R12, [BottomTextPtr]
  MOV R14, [PlasmaX]
  CMP BYTE PTR [R12], 0
  JE @NoTextToDisplay

@DisplayTextLoop:
  MOV R9, 50
  MOV R8, 30
  MOV RDX, R14
  MOV CL, BYTE PTR [R12]
  DEBUG_FUNCTION_CALL CopperBarDemo_DisplaySineLetterWithColumnAngle
  INC R12
  ADD R14, (BOTTOM_TEXT_LETTER_SPACE) + (SIN_FONT_WIDTH_SIZE*8)
  CMP RAX, 0
  JNE @LetterStillActive
  CMP R13, 0
  JE @EndOfTheLine
  MOV [PlasmaX], R14
  MOV [BottomTextPtr], R12
  JMP @NowWeAreStillAtFirstLetter
@LetterStillActive:
  XOR R13, R13
@NowWeAreStillAtFirstLetter:
  CMP BYTE PTR [R12], 0
  JNE @DisplayTextLoop
@EndOfTheLine:

  MOV RAX, [PlasmaXIncrement]
  ADD [PlasmaX], RAX  

@NoTextToDisplay:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarsDemo_DisplaySineText, _TEXT$00



;*********************************************************
;  CopperBarDemo_DisplaySineLetterWithColumnAngle
;
;        Parameters: Letter, X/Angle/Letter Center, Multiplier, CenterOffset
;
;           
;
;
;*********************************************************  
NESTED_ENTRY CopperBarDemo_DisplaySineLetterWithColumnAngle, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R12, RDX                                  ; X which is used as the angle.  It is also the center X of the letter.
  MOV R13, R8                                   ; Multiplier
  MOV R14, R9                                   ; Center-OFFSET

  ;
  ; Adjust center X to left for X.
  ;
  MOV RAX, SIN_FONT_WIDTH_SIZE
  SHL RAX, 3                            ; Ya, could do this in 1 SHL RAX, 2
  SHR RAX, 1
  SUB R12, RAX                          ; R12 = First X Location
  
  MOV RAX, SIN_FONT_WIDTH_SIZE*8
  MOV RDX, R12
  ADD RDX, RAX

  ;
  ; Determine if we are already off screen, then skip this letter.
  ;
  XOR RAX, RAX
  CMP RDX, 0
  JLE @OffScreenLetter

  ; CL = Character already
  DEBUG_FUNCTION_CALL Font_GetBitFont  
  MOV RSI, RAX
  
  MOV R15, R12                  ; Save R15 = Start X Position.

  MOV BL, 80h                   ; Bit Shift for Columns in the Font
@LoopWidth:
  MOV RBP, SIN_FONT_WIDTH_SIZE
@CheckNextXLocation:
  CMP R15, PLASMA_WIDTH
  JGE @DoneWithLetter
  CMP R15, 0
  JGE @InitializeHeightLoop
  INC R15                       ; Next X Location
  DEC RBP
  JNZ @CheckNextXLocation
  SHR BL,1                      ; Next column of the font.
  CMP BL, 0
  JE @DoneWithLetter
  JMP @LoopWidth

@InitializeHeightLoop:
  MOV RDX, 1
  MOV RCX, R15
  DEBUG_FUNCTION_CALL CopperBarsDemo_Sin
  CVTSI2SD XMM1, R13
  CVTSI2SD XMM2, R14
  MULSD XMM0, XMM1
  ADDSD XMM0, XMM2
  CVTSD2SI R11, XMM0

  ;
  ; Set the Double Buffer to the plasma area start.
  ;
  MOV RDI, [DoubleBuffer]  
  ;
  ; Adjust center Y for top row
  ;
 ; XOR RDX, RDX
 ; MOV RAX, SIN_FONT_HEIGHT_SIZE_PER_LINE
 ; SHL RAX, 3                            ;  Ya, could do this in 1 SHL RAX, 2
 ; SHR RAX, 1
 ; SUB R11, RAX
    
  ;
  ; Set drawing to start location for Y/X[0]
  ;
  XOR RDX, RDX
  MOV RAX, PLASMA_AREA_START
  ADD RAX, R11
  MOV RCX, PLASMA_WIDTH
  MUL RCX
  SHL RAX,2
  ADD RDI, RAX
  MOV RCX, R15
  SHL RCX, 2
  ADD RDI, RCX
  ;
  ; RDI = (X,Y) starting Point of column
  ;
  XOR RDX, RDX
  XOR R11, R11
  MOV RCX, SIN_FONT_HEIGHT_SIZE_PER_LINE
@DrawColumn:
  TEST BL, BYTE PTR [RSI + R11]
  JZ @SkipDrawing
;  MOV EAX, DWORD PTR [RDI - PLASMA_WIDTH*5*4]
;  MOV DWORD PTR [RDI], EAX
  MOV DWORD PTR [RDI], 0FFFFFFh
@SkipDrawing:
  ADD RDI, PLASMA_WIDTH*4
  DEC RCX
  JNZ @DrawColumn
  MOV RCX, SIN_FONT_HEIGHT_SIZE_PER_LINE
  INC R11
  INC DL
  CMP DL, 8
  JB @DrawColumn
  INC R15
  DEC RBP
  JNZ @CheckNextXLocation
  SHR BL,1
  JMP @LoopWidth
@DoneWithLetter:
  MOV RAX, 1
@OffScreenLetter:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END CopperBarDemo_DisplaySineLetterWithColumnAngle, _TEXT$00






END

