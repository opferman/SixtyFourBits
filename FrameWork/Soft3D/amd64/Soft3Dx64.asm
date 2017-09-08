;*********************************************************
; Soft3D Library 
;
;  Written in Assembly x64
; 
;     Software 3D Library
;
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
include ksamd64.inc
include demovariables.inc
include master.inc
include soft3d_public.inc


extern LocalAlloc:proc
extern LocalFree:proc 

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveR10        dq ?
SAVEFRAME ends

SOFT3D_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
SOFT3D_INIT_LOCALS ends


;
; Internal 3D Context
;
SOFT3D_INTERNAL_CONTEXT struct
    MasterContext     dq ?
	Flags             dq ?
    ZBufferPtr        dq ?
	CameraX_Radians   mmword ?
    CameraY_Radians   mmword ?
    CameraZ_Radians   mmword ?
    Aspect            mmword ?
    ViewDistance      mmword ?
	HalfScreenWidth   mmword ?
	HalfScreenHeight  mmword ?
	ViewPoint         TD_POINT <?>
SOFT3D_INTERNAL_CONTEXT ends



.CODE

;*********************************************************
;   Soft3D_Init
;
;        Parameters: Master Context, Flags
;
;        Return Value: 3D Handle
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_Init, _TEXT$00
  alloc_stack(SIZEOF SOFT3D_INIT_LOCALS)
  save_reg rdi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi
.ENDPROLOG 
  MOV RDI, RCX
  MOV RSI, RDX

  ;
  ; Allocate 3D context
  ;
  MOV RDX, SIZE SOFT3D_INTERNAL_CONTEXT
  MOV RCX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  TEST RAX, RAX
  JZ @Soft3D_Init_Failed

  ;
  ; Initialize 3D Context
  ;
  MOV SOFT3D_INTERNAL_CONTEXT.MasterContext[RAX], RDI
  MOV SOFT3D_INTERNAL_CONTEXT.Flags[RAX],         RSI

  cvtsi2sd xmm0, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RCX, 2
  cvtsi2sd xmm1, RCX
  DIVSD xmm0, xmm1
  MOVSD SOFT3D_INTERNAL_CONTEXT.HalfScreenWidth[RAX], xmm0

  cvtsi2sd xmm0, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  DIVSD xmm0, xmm1
  MOVSD SOFT3D_INTERNAL_CONTEXT.HalfScreenHeight[RAX], xmm0

  cvtsi2sd xmm0, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  cvtsi2sd xmm1, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  DIVSD xmm0, xmm1
  MOVSD SOFT3D_INTERNAL_CONTEXT.Aspect[RAX], xmm0
      
  ;
  ; Z Buffer Allocation
  ; 
  TEST SOFT3D_INTERNAL_CONTEXT.Flags[RAX], SOFT3D_FLAG_ZBUFFER
  JZ @NoZBuffer

  MOV RSI, RAX

  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  MUL RCX
  MOV RCX, SIZE MMWORD
  MUL RCX
  
  ;
  ; Allocate Z Buffer context
  ;
  MOV RDX, RAX
  MOV RCX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  TEST RAX, RAX
  JZ @Soft3D_ZBuffer_Failed

  MOV SOFT3D_INTERNAL_CONTEXT.ZBufferPtr[RSI], RAX
  
@Soft3D_ZBuffer_Failed:
  MOV RAX, RSI        ; Even if ZBuffer failed, we can move on without using it when we check it's still NULL.

@Soft3D_Init_Failed:  

@NoZBuffer:  

  MOV RDI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV RSI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  ADD RSP, SIZE SOFT3D_INIT_LOCALS
  
  RET

NESTED_END Soft3D_Init, _TEXT$00



;*********************************************************
;  Soft3D_SetCameraRotation
;
;        Parameters: 3D Context, X, Y, Z
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetCameraRotation, _TEXT$00
.ENDPROLOG 
  MOVSD SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RCX], xmm1
  MOVSD SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RCX], xmm2
  MOVSD SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RCX], xmm3
  RET
NESTED_END Soft3D_SetCameraRotation, _TEXT$00


;*********************************************************
;  Soft3D_SetViewDistance
;
;        Parameters: 3D Context, View Distance
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetViewDistance, _TEXT$00
.ENDPROLOG 
  MOVSD SOFT3D_INTERNAL_CONTEXT.ViewDistance[RCX], xmm1
  RET
NESTED_END Soft3D_SetViewDistance, _TEXT$00

;*********************************************************
;  Soft3D_SetViewPoint
;
;        Parameters: 3D Context, TD_POINT
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetViewPoint, _TEXT$00
.ENDPROLOG 
  MOVSD xmm0, TD_POINT.x[RDX]
  MOVSD SOFT3D_INTERNAL_CONTEXT.ViewPoint.x[RCX], xmm0

  MOVSD xmm0, TD_POINT.y[RDX]
  MOVSD SOFT3D_INTERNAL_CONTEXT.ViewPoint.y[RCX], xmm0

  MOVSD xmm0, TD_POINT.z[RDX]
  MOVSD SOFT3D_INTERNAL_CONTEXT.ViewPoint.z[RCX], xmm0
  RET
NESTED_END Soft3D_SetViewPoint, _TEXT$00


;*********************************************************
;  Soft3D_Close
;
;        Parameters: 3D Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_Close, _TEXT$00
  alloc_stack(SIZEOF SOFT3D_INIT_LOCALS)
  save_reg rdi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi
.ENDPROLOG 
  ;
  ; TODO: Free Z Buffer
  ;
  CALL LocalFree

  MOV RDI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV RSI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  ADD RSP, SIZE SOFT3D_INIT_LOCALS
  
  RET
NESTED_END Soft3D_Close, _TEXT$00


;*********************************************************
;  Soft3D_SetAspectRatio
;
;        Parameters: 3D Context, Aspect Ratio
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetAspectRatio, _TEXT$00
.ENDPROLOG 
  MOVSD SOFT3D_INTERNAL_CONTEXT.Aspect[RCX], xmm1
  RET
NESTED_END Soft3D_SetAspectRatio, _TEXT$00

;*********************************************************
;  Soft3D_GetAspectRatio
;
;        Parameters: 3D Context
;
;          Return: Aspect Ratio
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_GetAspectRatio, _TEXT$00
.ENDPROLOG 
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.Aspect[RCX]
  RET
NESTED_END Soft3D_GetAspectRatio, _TEXT$00


;*********************************************************
;  Soft3D_DrawLine
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_DrawLine, _TEXT$00
.ENDPROLOG 

  RET
NESTED_END Soft3D_DrawLine, _TEXT$00

;*********************************************************
;  Soft3D_PlotPixel
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_PlotPixel, _TEXT$00
.ENDPROLOG 

  RET
NESTED_END Soft3D_PlotPixel, _TEXT$00



;*********************************************************
;  Soft3D_Convert3Dto2D
;
;        Parameters: 
;           3D Handle, PTD_POINT pTdPoint, PTD_POINT pPixelWorld, PTD_POINT_2D pTdPoint2d, PTD_POINT pTdCamera
;       
;        Return: Pixel Status (On Screen or Off Screen)
;
;*********************************************************  
NESTED_ENTRY Soft3D_Convert3Dto2D, _TEXT$00
.ENDPROLOG 

  RET
NESTED_END Soft3D_Convert3Dto2D, _TEXT$00



END
