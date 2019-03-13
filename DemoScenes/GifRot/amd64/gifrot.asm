;*********************************************************
; Gif Rotation 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/12/2019
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include gif_public.inc
include dbuffer_public.inc
include font_public.inc
include soft3d_public.inc



;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc


;*********************************************************
; Structures
;*********************************************************
LMEM_ZEROINIT         EQU <40h>
MAX_FRAMES_PER_IMAGE  EQU <3>
COLOR_THRESHOLD       EQU <33>
;*********************************************************
; Public Declarations
;*********************************************************
public GifRot_Init
public GifRot_Demo
public GifRot_Free

FRAME_COUNT_DOWN EQU <3>

IMAGE_INFORMATION struct
   GifHandle      dq ?
   ImageListPtr   dq ?
   ImgOffsets     dq ?
   NumberOfImages dq ?
   CurrImagePtr   dq ?
   CurrentImage   dq ?
   ImageFrameNum  dq ?
   ImageMaxFrames dq ?
   ImageWidth     dq ?
   ImageHeight    dq ?
IMAGE_INFORMATION ends

GIF_ROT_STRUCT struct
   ImageOne     IMAGE_INFORMATION <?>
   ImageTwo     IMAGE_INFORMATION <?>
   DoubleBuffer dq ?
   MasterPtr    dq ?
GIF_ROT_STRUCT ends

NumberOfFunctions EQU <3>
INFLATE_DELAY     EQU <4>
;*********************************************************
; Data Segment
;*********************************************************
.DATA

  FirstFile             db "Image1.gif", 0
  SecondFile            db "Image2.gif", 0
  GifCtx                GIF_ROT_STRUCT  {}
  InflateCountDown      dq INFLATE_DELAY
  InflateCountDown2     dq INFLATE_DELAY
  FrameCounter          dq 0
  NumberOfFrames        dq 50
                        dq 1000
  FunctionArray         dq GifRot_DisplayCenteredGif
                        dq GifRot_FullScreen
                        dq GifRot_Combined
  FunctionIndex         dq 0
  FrameLoopHandle       dq 0
  StartX                dq 0
  StartY                dq 0
  Soft3D                dq 0
  StartX2               dq 1024/2 - 50
  StartY2               dq 768/2 - 50

  IncrementX          mmword 0.0
  IncrementY          mmword 0.0

.CODE

;*********************************************************
;   GifRot_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GifRot_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV [GifCtx.MasterPtr], RSI

  ;
  ; Load and Populate Image 1
  ;
  LEA RDX, [GifCtx.ImageOne]
  MOV RCX, OFFSET FirstFile
  DEBUG_FUNCTION_CALL GifRot_LoadGif
  CMP EAX, 0
  JE @Failed

  ;
  ; Load and Populate Image 2
  ;
  LEA RDX, [GifCtx.ImageTwo]
  MOV RCX, OFFSET SecondFile
  DEBUG_FUNCTION_CALL GifRot_LoadGif
  CMP EAX, 0
  JE @FailedWithCleanup
 
  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Soft3D_Init
  MOV [Soft3D], RAX
  TEST RAX, RAX
  JZ @FailedWithCleanup

  ;
  ; Create the screen double buffer
  ;
  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [GifCtx.DoubleBuffer], RAX
  CMP RAX, 0
  JE @FailedWithCleanup

  ;
  ; Create the frame loop implementation
  ; 
;  LEA RCX, [FrameLoopList]
;  DEBUG_FUNCTION_CALL FrameLoop_Create
;  CMP RAX, 0
;  JE @FailedWithCleanup
;  MOV [FrameLoopHandle], RAX


@ReadToGo:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  MOV EAX, 1
  RET

;
;
; Failure Path
;
@FailedWithCleanup:
 ;
 ; Add Clean up TBD
 ;
@Failed:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  XOR RAX, RAX
  RET

NESTED_END GifRot_Init, _TEXT$00

;*********************************************************
;  GifRot_LoadGif
;
;        Parameters: File Name, Image Information
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY GifRot_LoadGif, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RDX

  ;
  ; Open and Initialize the GIF Library
  ;
  DEBUG_FUNCTION_CALL Gif_Open
  CMP RAX, 0
  JE @Failed
  MOV IMAGE_INFORMATION.GifHandle[RSI], RAX
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_NumberOfImages
  MOV IMAGE_INFORMATION.NumberOfImages[RSI], RAX

  ;
  ; Get the size of the image to create the buffer
  ;
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageSize
  MOV IMAGE_INFORMATION.ImgOffsets[RSI], RAX
   
 ;
 ; Determine the complete buffer size for all images 
 ;
  XOR EDX, EDX
  MUL IMAGE_INFORMATION.NumberOfImages[RSI]
  
  ;
  ; Allocate the Image Buffer
  ;
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  CMP RAX,0
  JE @FailedWithCleanup
  
  ;
  ; Initialize all of the start up variables
  ;
  MOV IMAGE_INFORMATION.ImageListPtr[RSI], RAX
  MOV IMAGE_INFORMATION.CurrImagePtr[RSI], RAX
  MOV IMAGE_INFORMATION.ImageFrameNum[RSI], 0
  MOV IMAGE_INFORMATION.CurrentImage[RSI], 0
  MOV IMAGE_INFORMATION.ImageMaxFrames[RSI], MAX_FRAMES_PER_IMAGE

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageWidth
  MOV IMAGE_INFORMATION.ImageWidth[RSI], RAX

  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImageHeight
  MOV IMAGE_INFORMATION.ImageHeight[RSI], RAX
 
  XOR RBX, RBX
  MOV RDI, IMAGE_INFORMATION.ImageListPtr[RSI]
@GetImages:

  ;
  ; Decode the Image into the buffer
  ;
  MOV R8, RDI
  MOV RDX, RBX
  MOV RCX, IMAGE_INFORMATION.GifHandle[RSI]
  DEBUG_FUNCTION_CALL Gif_GetImage32bpp

  ADD RDI, IMAGE_INFORMATION.ImgOffsets[RSI]

  INC RBX
  CMP RBX, IMAGE_INFORMATION.NumberOfImages[RSI]
  JB @GetImages

  MOV RAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedWithCleanup:
;
; Cleanup TBD
;
@Failed:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_LoadGif, _TEXT$00



;*********************************************************
;  GifRot_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY GifRot_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ;
  ; Clear the double buffer for use.
  ;
  MOV RCX, [GifCtx.DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_ClearBuffer

;
; Update the frame count.
;
  INC [FrameCounter]
  MOV RAX, [FunctionIndex]
  SHL RAX, 3
  MOV RDX, OFFSET NumberOfFrames
  ADD RDX, RAX
  MOV R8, [RDX]

   ;
   ; Check for Frame Reset
   ;
   CMP [FrameCounter], R8
   JB @NoResetFrameCounter
   MOV [FrameCounter], 0
   INC [FunctionIndex]

   ;
   ; Check for Function Reset
   ;
   CMP [FunctionIndex], NumberOfFunctions
   JB @NoResetFunctions

   MOV [FunctionIndex], 0
@NoResetFunctions:
@NoResetFrameCounter:

 
  ;
  ; Draw the frame using the Function callbacks
  ;
   MOV RAX, [FunctionIndex]
   SHL RAX, 3
   MOV RDX, OFFSET FunctionArray
   ADD RDX, RAX
   MOV RCX, OFFSET GifCtx
   DEBUG_FUNCTION_CALL QWORD PTR [RDX]


@SkipReset:
  ;
  ; Update the double buffer on screen
  ;
  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, [GifCtx.DoubleBuffer]
  DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

  MOV RAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_Demo, _TEXT$00



;*********************************************************
;  GifRot_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ; Nothing to clean up

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_Free, _TEXT$00


;*********************************************************
;  GifRot_Combined
;
;        Parameters: GfxContet
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_Combined, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RSI, RCX
  DEBUG_FUNCTION_CALL GifRot_FullScreen

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GifRot_GrowToScreen

  MOV RCX, GIF_ROT_STRUCT.MasterPtr[RSI]
  MOV RDX, GIF_ROT_STRUCT.DoubleBuffer[RSI]
  DEBUG_FUNCTION_CALL GifRot_Rotation

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_Combined, _TEXT$00



;*********************************************************
;  GifRot_Rotation
;
;        Parameters: GfxContet
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_Rotation, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_Rotation, _TEXT$00


;*********************************************************
;  GifRot_DisplayCenteredGif
;
;        Parameters: Gif Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_DisplayCenteredGif, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R8, RCX

  MOV R9, GIF_ROT_STRUCT.MasterPtr[R8]
  MOV RDI, GIF_ROT_STRUCT.DoubleBuffer[R8]

  ;
  ; Check if frame should be advanced
  ;
  INC GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageMaxFrames[R8]
  CMP GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8], RCX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8], 0
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImgOffsets[R8]
  ADD GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8], RCX

  ;
  ; Check for Frame Wraparound
  ;
  INC GIF_ROT_STRUCT.ImageOne.CurrentImage[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageOne.NumberOfImages[R8]
  CMP GIF_ROT_STRUCT.ImageOne.CurrentImage[R8], RCX
  JB @NoFrameReset

    MOV GIF_ROT_STRUCT.ImageOne.CurrentImage[R8], 0   
    MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageListPtr[R8]
    MOV GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8], RCX

@NoFrameReset:
@NoFrameUpdate:

  ;
  ; Center the GIF on the screen
  ;
  MOV RDX, GIF_ROT_STRUCT.ImageOne.ImageHeight[R8]
  SHR RDX, 1
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  SHR RAX, 1
  SUB RAX, RDX
  MOV [StartY], RAX
  SHL RAX, 2
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]

  MOV RDX, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  SHR RDX, 1
  MOV RBX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHR RBX, 1
  SUB RBX, RDX
  MOV [StartX], RBX
  SHL RBX, 2
  ADD RAX, RBX
  ADD RDI, RAX

;  ADD RCX, RAX
;  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
;  SHL RAX, 1
  

  MOV RSI, GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8]
  
;
; Plot the image on the screen
;
  XOR R10, R10
@PlotImageOnScreenCentered:
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  REP MOVSD
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  SHL RCX, 2
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2
  SUB RAX, RCX
  ADD RDI, RAX
  INC R10
  CMP R10, GIF_ROT_STRUCT.ImageOne.ImageHeight[R8]
  JB @PlotImageOnScreenCentered

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_DisplayCenteredGif, _TEXT$00

;*********************************************************
;  GifRot_FullScreen
;
;        Parameters: Gif Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_FullScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R8, RCX
  MOV R9, GIF_ROT_STRUCT.MasterPtr[R8]

  ;
  ; Check if should advance Start/End to go to full screen
  ;
  DEC [InflateCountDown]
  JNZ @NoUpdate
  MOV [InflateCountDown], INFLATE_DELAY
  CMP [StartX], 0
  JE @StartXIsComplete
  DEC [StartX]
@StartXIsComplete:
  CMP [StartY], 0
  JE @StartYIsComplete
  DEC [StartY]
@StartYIsComplete:
@NoUpdate:
  ;
  ; Check if frame should be advanced
  ;
  INC GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageMaxFrames[R8]
  CMP GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8], RCX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV GIF_ROT_STRUCT.ImageOne.ImageFrameNum[R8], 0
  MOV RCX, GIF_ROT_STRUCT.ImageOne.ImgOffsets[R8]
  ADD GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8], RCX

  ;
  ; Check for Frame Wraparound
  ;
  INC GIF_ROT_STRUCT.ImageOne.CurrentImage[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageOne.NumberOfImages[R8]
  CMP GIF_ROT_STRUCT.ImageOne.CurrentImage[R8], RCX
  JB @NoFrameReset

    MOV GIF_ROT_STRUCT.ImageOne.CurrentImage[R8], 0   
    MOV RCX, GIF_ROT_STRUCT.ImageOne.ImageListPtr[R8]
    MOV GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8], RCX

@NoFrameReset:
@NoFrameUpdate:

  ;
  ; Determine Growth of Image by scaling of X and Y
  ;
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SUB RCX, [StartX]
  SUB RCX, [StartX]
  CVTSI2SD XMM0, RCX
  CVTSI2SD XMM1, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  DIVSD XMM1, XMM0
  MOVSD [IncrementX], XMM1

  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  SUB RDX, [StartY]
  SUB RDX, [StartY]
  CVTSI2SD XMM0, RDX
  CVTSI2SD XMM1, GIF_ROT_STRUCT.ImageOne.ImageHeight[R8]
  DIVSD XMM1, XMM0
  MOVSD [IncrementY], XMM1

  ;
  ; Create the Y start Location.
  ;
  MOV RAX, [StartY]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2

  ;
  ; Create the X Start Location
  ;
  MOV RCX, [StartX]
  SHL RCX, 2
  ADD RAX, RCX
 
  ;
  ; The Stride
  ;
  MOV RDX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RDX, 2

  MOV RSI, GIF_ROT_STRUCT.ImageOne.CurrImagePtr[R8]
  MOV RDI, GIF_ROT_STRUCT.DoubleBuffer[R8]  
  ADD RDI, RAX
;
; Plot the image on the screen
;
  PXOR XMM0, XMM0
  XOR R10, R10
@PlotScaledY:
  PXOR XMM1, XMM1
  XOR R14, R14
  XOR R12, R12
  ;
  ; Loop and Plot Pixels
  ;
@PlotScaledX:
  SHL R12, 2
  MOV EAX, [RSI + R12]
  MOV [RDI + R14], EAX
  ADD R14, 4
  ADDSD XMM1, [IncrementX]
  CVTSD2SI R12, XMM1
  CMP R12, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  JB @PlotScaledX
  ;
  ; Wrap around to the next line
  ;
  ADD RDI, RDX
  ADDSD XMM0, [IncrementY]
  CVTSD2SI R9, XMM0
  CMP R9, R10
  JE @PlotScaledY
  MOV RAX, GIF_ROT_STRUCT.ImageOne.ImageWidth[R8]
  ;
  ; Wrap Image to the next size
  ;
  SHL RAX, 2
  ADD RSI, RAX
  MOV R10, R9
  CMP R10, GIF_ROT_STRUCT.ImageOne.ImageHeight[R8]
  JB @PlotScaledY

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_FullScreen, _TEXT$00




;*********************************************************
;  GifRot_GrowToScreen
;
;        Parameters: Gif Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY GifRot_GrowToScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R8, RCX
  MOV R9, GIF_ROT_STRUCT.MasterPtr[R8]

  ;
  ; Check if should advance Start/End to go to full screen
  ;
  DEC [InflateCountDown2]
  JNZ @NoUpdate
  MOV [InflateCountDown2], INFLATE_DELAY
  CMP [StartX2], 300
  JE @StartXIsComplete
  DEC [StartX2]
@StartXIsComplete:
  CMP [StartY2], 200
  JE @StartYIsComplete
  DEC [StartY2]
@StartYIsComplete:
@NoUpdate:
  ;
  ; Check if frame should be advanced
  ;
  INC GIF_ROT_STRUCT.ImageTwo.ImageFrameNum[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageTwo.ImageMaxFrames[R8]
  CMP GIF_ROT_STRUCT.ImageTwo.ImageFrameNum[R8], RCX
  JB @NoFrameUpdate
  
  ;
  ;  General Frame Update
  ;
  MOV GIF_ROT_STRUCT.ImageTwo.ImageFrameNum[R8], 0
  MOV RCX, GIF_ROT_STRUCT.ImageTwo.ImgOffsets[R8]
  ADD GIF_ROT_STRUCT.ImageTwo.CurrImagePtr[R8], RCX

  ;
  ; Check for Frame Wraparound
  ;
  INC GIF_ROT_STRUCT.ImageTwo.CurrentImage[R8]
  MOV RCX, GIF_ROT_STRUCT.ImageTwo.NumberOfImages[R8]
  CMP GIF_ROT_STRUCT.ImageTwo.CurrentImage[R8], RCX
  JB @NoFrameReset

    MOV GIF_ROT_STRUCT.ImageTwo.CurrentImage[R8], 0   
    MOV RCX, GIF_ROT_STRUCT.ImageTwo.ImageListPtr[R8]
    MOV GIF_ROT_STRUCT.ImageTwo.CurrImagePtr[R8], RCX

@NoFrameReset:
@NoFrameUpdate:

  ;
  ; Determine Growth of Image by scaling of X and Y
  ;
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SUB RCX, [StartX2]
  SUB RCX, [StartX2]
  CVTSI2SD XMM0, RCX
  CVTSI2SD XMM1, GIF_ROT_STRUCT.ImageTwo.ImageWidth[R8]
  DIVSD XMM1, XMM0
  MOVSD [IncrementX], XMM1

  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[R9]
  SUB RDX, [StartY2]
  SUB RDX, [StartY2]
  CVTSI2SD XMM0, RDX
  CVTSI2SD XMM1, GIF_ROT_STRUCT.ImageTwo.ImageHeight[R8]
  DIVSD XMM1, XMM0
  MOVSD [IncrementY], XMM1

  ;
  ; Create the Y start Location.
  ;
  MOV RAX, [StartY2]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RAX, 2

  ;
  ; Create the X Start Location
  ;
  MOV RCX, [StartX2]
  SHL RCX, 2
  ADD RAX, RCX
 
  ;
  ; The Stride
  ;
  MOV RDX, MASTER_DEMO_STRUCT.ScreenWidth[R9]
  SHL RDX, 2

  MOV RSI, GIF_ROT_STRUCT.ImageTwo.CurrImagePtr[R8]
  MOV RDI, GIF_ROT_STRUCT.DoubleBuffer[R8]  
  ADD RDI, RAX
;
; Plot the image on the screen
;
  PXOR XMM0, XMM0
  XOR R10, R10
@PlotScaledY:
  PXOR XMM1, XMM1
  XOR R14, R14
  XOR R12, R12
  ;
  ; Loop and Plot Pixels
  ;
@PlotScaledX:
  SHL R12, 2
  MOV EAX, [RSI + R12]
  CMP AL, COLOR_THRESHOLD
  JA @PlotIt
  CMP AH, COLOR_THRESHOLD
  JA @PlotIt
  SHR EAX, 16
  CMP AL, COLOR_THRESHOLD
  JBE @DoNotPlotZero
@PlotIt:
  ADD AL, BYTE PTR [RDI + R14]
  SHR AL, 1
  MOV BYTE PTR [RDI + R14], AL
  SHR AX, 8
  ADD AL, BYTE PTR [RDI + R14 + 1]
  SHR AL, 1
  MOV BYTE PTR [RDI + R14 + 1], AL

  SHR RAX, 16
  ADD AL, BYTE PTR [RDI + R14 + 2]
  SHR AL, 1
  MOV BYTE PTR [RDI + R14 + 2], AL

;  MOV [RDI + R14], EAX
@DoNotPlotZero:
  ADD R14, 4
  ADDSD XMM1, [IncrementX]
  CVTSD2SI R12, XMM1
  CMP R12, GIF_ROT_STRUCT.ImageTwo.ImageWidth[R8]
  JB @PlotScaledX
  ;
  ; Wrap around to the next line
  ;
  ADD RDI, RDX
  ADDSD XMM0, [IncrementY]
  CVTSD2SI R9, XMM0
  CMP R9, R10
  JE @PlotScaledY
  MOV RAX, GIF_ROT_STRUCT.ImageTwo.ImageWidth[R8]

  ;
  ; Wrap Image to the next size
  ;
  SHL RAX, 2
@LoopHeight:
  ADD RSI, RAX
  INC R10
  CMP R10, R9
  JB @LoopHeight

  MOV R10, R9
  CMP R10, GIF_ROT_STRUCT.ImageTwo.ImageHeight[R8]
  JB @PlotScaledY

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GifRot_GrowToScreen, _TEXT$00


END