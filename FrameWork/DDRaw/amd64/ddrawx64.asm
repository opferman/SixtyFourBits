;*********************************************************
; Direct Draw Setup Code
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/24/2010
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64.inc
include demovariables.inc
include ddrawx64.inc
include init_public.inc

FUNC_PARAMS struct
    ReturnAddress  dq ?
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
FUNC_PARAMS ends

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveR12        dq ?
SAVEFRAME ends

public DDrawx64_GetScreenRes

;
; DDRAW_INIT_LOCALS and DDRAW_INIT_LOCALS_WITH_PFRAME must be identical except that " FunctionParams       FUNC_PARAMS <?>"
; is at the bottom of DDRAW_INIT_LOCALS_WITH_PFRAME.  This allows access to the parameters above the return address if these
; are not properly aligned then you can overwrite the return address and crash.
;
;
DDRAW_INIT_LOCALS struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq ?
   Param6                dq ?
   Param7                dq ?
   Param8                dq ?
   DdrawInternalContext  dq      ?
   hWnd                  dq      ?
   FullScreenMode        dq      ?
   SourceRect            RECT    <?>
   DestinationRect       RECT    <?>
   PointLoc              POINT   <?>
   Padding               dq ?
   SaveFrameCtx         SAVEFRAME <?>
DDRAW_INIT_LOCALS ends

DDRAW_INIT_LOCALS_WITH_PFRAME struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq ?
   Param6                dq ?
   Param7                dq ?
   Param8                dq ?
   DdrawInternalContext  dq      ?
   hWnd                  dq      ?
   FullScreenMode        dq      ?
   SourceRect            RECT        <?>
   DestinationRect       RECT       <?>
   PointLoc                 POINT       <?>
   Padding               dq ?
   SaveFrameCtx         SAVEFRAME   <?>
   FunctionParams       FUNC_PARAMS <?>
DDRAW_INIT_LOCALS_WITH_PFRAME ends

extern GetWindowRect:proc
extern GetClientRect:proc
extern ClientToScreen:proc
extern OffsetRect:proc
extern SetRect:proc

.CODE
  
;*********************************************************
;  DDrawx64_Init
;
;        Parameters: hWnd, InitializationContext
;
;        Return Value: Direct Draw Context
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_Init, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 

  MOV RSI, RDX

  MOV DDRAW_INIT_LOCALS.hWnd[RSP], RCX
  MOV RDX, INIT_DEMO_STRUCT.FullScreen[RSI]
  MOV DDRAW_INIT_LOCALS.FullScreenMode[RSP], RDX

  
  MOV RDX, SIZE DDRAW_INTERNAL_CONTEXT
  MOV RCX, LMEM_ZEROINIT
  CALL LocalAlloc
  
  MOV DDRAW_INIT_LOCALS.DdrawInternalContext[RSP], RAX

  TEST RAX, RAX
  JZ @DDrawx64_ExitWithFailureNoFree
  MOV RCX, DDRAW_INIT_LOCALS.hWnd[RSP]
  MOV DDRAW_INTERNAL_CONTEXT.hWnd[RAX], RCX
    
  XOR RCX, RCX
  XOR R8, R8
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  LEA RDX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  CALL DirectDrawCreate

  TEST EAX, EAX
  JL @DDrawx64_InitExitWithFailure
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  XOR RDX, RDX
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Initialize]

  CMP  DDRAW_INIT_LOCALS.FullScreenMode[RSP], 0
  JE @SetWindowModeFlags
  
   
  MOV R8, DDSCL_FULLSCREEN or DDSCL_ALLOWMODEX or DDSCL_EXCLUSIVE or DDSCL_ALLOWREBOOT
  JMP @SkipWindowMOdeFlags

@SetWindowModeFlags:
  MOV R8, DDSCL_NORMAL  

@SkipWindowMOdeFlags:  

  MOV RDX, DDRAW_INIT_LOCALS.hWnd[RSP]
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_SetCooperativeLevel]


  CMP  DDRAW_INIT_LOCALS.FullScreenMode[RSP], 0
  JE @SkipSettingFullScreen
  
  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.Param5[RSP], 0  ; Refresh Rate Default
  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.Param6[RSP], 0  ; No Flags
  

;
;
;  Set the graphics mode.  This can be commented out to leave the current resolution.
;   R9 = Bits Per Pixel (32 bit)
;   R8 = Height
;   RDX = Width
;
;  TODO: Should this be configurable for each demo?
;
;

  MOV R9, INIT_DEMO_STRUCT.BitsPerPixel[RSI]
  MOV R8, INIT_DEMO_STRUCT.ScreenHeight[RSI]
  MOV RDX, INIT_DEMO_STRUCT.ScreenWidth[RSI]
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_SetDisplayMode]  

 
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]   
  LEA RDI, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RAX] 
  MOV RCX, SIZE DDSURFACEDESC
  XOR RAX, RAX 
  REP STOSB
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwSize[RAX], SIZE DDSURFACEDESC
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwFlags[RAX], DDSD_CAPS or DDSD_BACKBUFFERCOUNT
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddsCapsctx[RAX], DDSCAPS_PRIMARYSURFACE or DDSCAPS_COMPLEX or DDSCAPS_FLIP
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwBackBufferCount[RAX], 1
  MOV R8,  DDRAW_INIT_LOCALS.FullScreenMode[RSP]
  MOV DDRAW_INTERNAL_CONTEXT.FullScreenMode[RAX], R8  


  
  LEA RDX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RAX]
  LEA R8, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RAX]
  XOR R9, R9
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_CreateSurface]      

  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  
  MOV DDRAW_INTERNAL_CONTEXT.DSurfaceCaps[RAX], DDSCAPS_BACKBUFFER
  LEA R8, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RAX]
  LEA RDX, DDRAW_INTERNAL_CONTEXT.DSurfaceCaps[RAX]
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_GetAttachedSurface]     
  
  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure

@DDrawx64_exitsuccess:  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET

  ;
  ;
  ; Windowed mode setup
  ;
  ;
@SkipSettingFullScreen:  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]   
  LEA RDI, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RAX] 
  MOV RCX, SIZE DDSURFACEDESC
  XOR RAX, RAX 
  REP STOSB
  
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwSize[RAX], SIZE DDSURFACEDESC
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwFlags[RAX], DDSD_CAPS 
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddsCapsctx[RAX], DDSCAPS_PRIMARYSURFACE

  MOV R8,  DDRAW_INIT_LOCALS.FullScreenMode[RSP]
  MOV DDRAW_INTERNAL_CONTEXT.FullScreenMode[RAX], R8  

  LEA RDX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RAX]
  LEA R8, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RAX]
  XOR R9, R9
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_CreateSurface]      

  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure
   

  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwSize[RAX], SIZE DDSURFACEDESC
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwFlags[RAX], DDSD_WIDTH or DDSD_HEIGHT or DDSD_CAPS 
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddsCapsctx[RAX], DDSCAPS_OFFSCREENPLAIN
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwWidth[RAX], 1024
  MOV DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwHeight[RAX], 768

  LEA RDX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RAX]
  LEA R8, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RAX]
  XOR R9, R9
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_CreateSurface]      

  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  XOR R9, R9
  LEA R8, DDRAW_INTERNAL_CONTEXT.lpDirectDrawClipperCtx[RAX]
  XOR RDX, RDX
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_CreateClipper]      

  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure

  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  MOV R8, DDRAW_INIT_LOCALS.hWnd[RSP]
  XOR RDX, RDX
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawClipperCtx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Clipper_SetHWnd]     
  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure
  MOV RAX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]

  MOV RDX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawClipperCtx[RAX]
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RAX]
  MOV  RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_SetClipper]     
  CMP EAX, 0
  JL @DDrawx64_InitExitWithFailure

 
  JMP @DDrawx64_exitsuccess
      
@DDrawx64_InitExitWithFailure:
  MOV RCX, DDRAW_INIT_LOCALS.DdrawInternalContext[RSP]
  CALL DDrawx64_Free
  
@DDrawx64_ExitWithFailureNoFree:
  XOR RAX, RAX
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET

NESTED_END DDrawx64_Init, _TEXT$00



;*********************************************************
;  DDrawx64_Free
;
;        Parameters: Direct Draw Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_Free, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 

  MOV RDI, RCX
  MOV RAX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
  
  TEST RAX, RAX
  JZ SHORT @DDrawx64_Free_DirectDraw
  
  MOV RCX, RAX
  MOV RAX, [RAX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Release]

@DDrawx64_Free_DirectDraw:

  MOV RAX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawctx[RDI]
    
  TEST RAX, RAX
  JZ SHORT @DDrawx64_Free_Exit
  
  MOV RCX, RAX
  MOV RAX, [RAX]
  CALL QWORD PTR [RAX + DDRAWDD_Release]
 
@DDrawx64_Free_Exit:
  
  MOV RCX, RDI
  CALL LocalFree
  
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
NESTED_END DDrawx64_Free, _TEXT$00

;*********************************************************
;  DDrawx64_PixelPlot
;
;        Parameters: Direct Draw Context, ARGB (DWORD), X, Y
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_PixelPlot, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
 save_reg rsi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRsi
 save_reg r12, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveR12
.ENDPROLOG 

  MOV RDI, RCX
  MOV RCX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.lpSurface[RDI]

  ; Calculate the start of the screen height
  MOV EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.lPitch[RDI]
  
  ;
  ; Move to the height
  ;
  MOV DDRAW_INIT_LOCALS.ParamFrameArea.Param1[RSP], RDX
  XOR RDX, RDX  
  MUL R9
  ADD RCX, RAX

  ;
  ; Calculate bits per pixel (Assume at least 1 byte per pixel)
  ;
  MOV EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwRGBBitCount[RDI]
  SHR EAX, 3
  XOR RDX, RDX  
  MUL R8

  ;
  ; Add X Location
  ;
  ADD RCX, RAX

  ;
  ; Decode the bit layout; assume R-G-B
  ;
  MOV R8, DDRAW_INIT_LOCALS.ParamFrameArea.Param1[RSP]
  MOV RDX, R8
  
  ;
  ; Mask the blue since it should be the lowest bit
  ;
  MOV EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwBBitMask[RDI]
  AND R8, RAX
  
  ;
  ; Determine the mask for Green
  ;
  BSF EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwGBitMask[RDI]
  SHR RDX, 8
  XCHG CL, AL
  SHL RDX, CL
  MOV CL, AL
  AND EDX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwGBitMask[RDI]
  OR R8, RDX

  ;
  ; Determine the mask for Red
  ;
  BSF EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwRBitMask[RDI]
  MOV RDX, DDRAW_INIT_LOCALS.ParamFrameArea.Param1[RSP]
  SHR RDX, 16
  XCHG CL, AL
  SHL RDX, CL
  MOV CL, AL
  AND EDX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwRBitMask[RDI]
  OR R8, RDX

  MOV EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwRGBBitCount[RDI]
  SHR EAX, 3

  CMP EAX, 1
  je @PlotByteColor
  CMP EAX, 2
  je @PlotWordColor

@Plot32Color:
  MOV DWORD PTR [RCX], R8D
  jmp @CompletePlot

@PlotWordColor:
  MOV WORD PTR [RCX], R8W
  jmp @CompletePlot

@PlotByteColor:
  MOV BYTE PTR [RCX], R8B

@CompletePlot:  
	  
  MOV EAX, 1
      
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  MOV RSI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRsi[RSP]
  MOV R12, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveR12[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
NESTED_END DDrawx64_PixelPlot, _TEXT$00

;*********************************************************
;  DDrawx64_LockSurfaceBuffer
;
;        Parameters: Direct Draw Context, Pointer To Video Buffer, Pointer to Pitch
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_LockSurfaceBuffer, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 
  
  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param1[RSP], RDX
  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param2[RSP], R8
    
  MOV RDI, RCX
   
  ; CMP DDRAW_INTERNAL_CONTEXT.FullScreenMode[RDI], 0
  ; JE @LockSurfaceBuffer_For_WindowedMode

  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.Param5[RSP], 0
  MOV R9, DDLOCK_SURFACEMEMORYPTR or DDLOCK_WAIT
  LEA R8, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription[RDI]
  XOR RDX, RDX
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
  
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Lock]
  
  CMP EAX, 0
  JL @DDrawx64_FailedToLockSurface
  

  MOV RDX, DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param1[RSP]
  
  MOV RAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.lpSurface[RDI]
  MOV QWORD PTR [RDX], RAX
  
  MOV R8, DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param2[RSP]
  MOV EAX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.lPitch[RDI]
  MOV [R8], EAX
    
  MOV RAX, 1  
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
@DDrawx64_FailedToLockSurface:

  XOR RAX, RAX
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET

;@LockSurfaceBuffer_For_WindowedMode:
;  XOR RAX, RAX
;  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
;  ADD RSP, SIZE DDRAW_INIT_LOCALS
;  RET
  
NESTED_END DDrawx64_LockSurfaceBuffer, _TEXT$00

;*********************************************************
;  DDrawx64_GetScreenRes
;
;        Parameters: Direct Draw Context, Pointer to Height, Pointer to Width, Bits Per Pixel
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_GetScreenRes, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 

  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param1[RSP], RDX
  MOV DDRAW_INIT_LOCALS_WITH_PFRAME.FunctionParams.Param2[RSP], R8
  MOV RDI, RCX
  MOV DDRAW_INIT_LOCALS.Param5[RSP], 0

  MOV ECX, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.ddpfPixelFormat.dwRGBBitCount[RDI]
  MOV [R9], ECX

  MOV R9D, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwHeight[RDI]
  MOV [RDX], R9D
  
  MOV R9D, DDRAW_INTERNAL_CONTEXT.DdSurfaceDescription.dwWidth[RDI]
  MOV [R8], R9D
      
  MOV RAX, 1  
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
  
NESTED_END DDrawx64_GetScreenRes, _TEXT$00

;*********************************************************
;  DDrawx64_UnLockSurfaceAndFlip
;
;        Parameters: Direct Draw Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_UnLockSurfaceAndFlip, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 
  
  MOV RDI, RCX
  XOR RDX, RDX

  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
  
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Unlock]  
   
  CMP DDRAW_INTERNAL_CONTEXT.FullScreenMode[RDI], 0
  JE @UnLockSurfaceBuffer_For_WindowedMode

@DDrawx64_UnLockSurfaceAndFlip_WaitFlip:
 
  MOV R8, DDFLIP_WAIT
  XOR RDX, RDX
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
  MOV RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Flip]
  
  TEST RAX, RAX
  JNZ SHORT @DDrawx64_UnLockSurfaceAndFlip_WaitFlip
  
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
 @UnLockSurfaceBuffer_For_WindowedMode:
 

 MOV DDRAW_INIT_LOCALS.PointLoc.x[RSP], 0
 MOV DDRAW_INIT_LOCALS.PointLoc.y[RSP], 0
 LEA RDX, DDRAW_INIT_LOCALS.PointLoc[RSP]
 MOV RCX, DDRAW_INTERNAL_CONTEXT.hWnd[RDI]
 CALL ClientToScreen

 LEA RDX, DDRAW_INIT_LOCALS.DestinationRect[RSP]
 MOV RCX, DDRAW_INTERNAL_CONTEXT.hWnd[RDI]
 CALL GetClientRect

 MOV R8D, DDRAW_INIT_LOCALS.PointLoc.y[RSP]
 MOV EDX, DDRAW_INIT_LOCALS.PointLoc.x[RSP]
 LEA RCX, DDRAW_INIT_LOCALS.DestinationRect[RSP]
 CALL OffsetRect

 MOV DDRAW_INIT_LOCALS.Param5[RSP], 768
 MOV R9, 1024

 XOR R8, R8
 XOR RDX, RDX
 LEA RCX, DDRAW_INIT_LOCALS.SourceRect[RSP]
 CALL SetRect

;
;  BltFast cannot be used when clipping is enabled.
;
;  MOV DDRAW_INIT_LOCALS.Param7[RSP], 0  
;  MOV DDRAW_INIT_LOCALS.Param6[RSP],  DDBLTFAST_WAIT
;  LEA R9, DDRAW_INIT_LOCALS.SourceRect[RSP]
;  MOV DDRAW_INIT_LOCALS.Param5[RSP],  R9
;
;  MOV R9, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
; 
;  MOV R8D, DDRAW_INIT_LOCALS.DestinationRect.left[RSP]
;  MOV EDX, DDRAW_INIT_LOCALS.DestinationRect.top[RSP]
;  
;  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
;  MOV RAX, [RCX]
;  CALL QWORD PTR [RAX + DDRAWDD_Surface_BltFast]
;  

  MOV DDRAW_INIT_LOCALS.Param6[RSP], 0  
  LEA R9, DDRAW_INIT_LOCALS.SourceRect[RSP]
  MOV DDRAW_INIT_LOCALS.Param5[RSP],  DDBLTFAST_WAIT
  MOV R8, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
  LEA RDX, DDRAW_INIT_LOCALS.DestinationRect[RSP]

  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
  MOV RAX, [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Blt]

  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
NESTED_END DDrawx64_UnLockSurfaceAndFlip, _TEXT$00



;*********************************************************
;  DDrawx64_RestoreSurfacesIfNeeded
;
;        Parameters: Direct Draw Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY DDrawx64_RestoreSurfacesIfNeeded, _TEXT$00
 alloc_stack(SIZEOF DDRAW_INIT_LOCALS)
 save_reg rdi, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 
  
  MOV RDI, RCX
  XOR RDX, RDX


  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_IsLost]  
  CMP EAX, DDERR_SURFACELOST
  JNE @PrimarySurfaceNotLost
  
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectDrawSurfacectx[RDI]
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Restore]  
     
@PrimarySurfaceNotLost:
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_IsLost]  
  CMP EAX, DDERR_SURFACELOST

  JNE @BackSurfaceNotLost
  MOV RCX, DDRAW_INTERNAL_CONTEXT.lpDirectBackSurfacectx[RDI]
  MOV RAX, QWORD PTR [RCX]
  CALL QWORD PTR [RAX + DDRAWDD_Surface_Restore]  

@BackSurfaceNotLost:
  MOV RDI, DDRAW_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZE DDRAW_INIT_LOCALS
  RET
NESTED_END DDrawx64_RestoreSurfacesIfNeeded, _TEXT$00




END
