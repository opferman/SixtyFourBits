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
	CameraX_Radians   dq ?
    CameraY_Radians   dq ?
    CameraZ_Radians   dq ?
    Aspect            dq ?
    ViewDistance      dq ?
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
  
  ;
  ; TODO: Z Buffer Allocation
  ;
   
@Soft3D_Init_Failed:  
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
  MOVQ SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RCX], xmm1
  MOVQ SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RCX], xmm2
  MOVQ SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RCX], xmm3
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
  MOVQ SOFT3D_INTERNAL_CONTEXT.ViewDistance[RCX], xmm1
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
  MOVQ xmm0, TD_POINT.x[RDX]
  MOVQ SOFT3D_INTERNAL_CONTEXT.ViewPoint.x[RCX], xmm0

  MOVQ xmm0, TD_POINT.y[RDX]
  MOVQ SOFT3D_INTERNAL_CONTEXT.ViewPoint.y[RCX], xmm0

  MOVQ xmm0, TD_POINT.z[RDX]
  MOVQ SOFT3D_INTERNAL_CONTEXT.ViewPoint.z[RCX], xmm0
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
  MOVQ SOFT3D_INTERNAL_CONTEXT.Aspect[RCX], xmm1
  RET
NESTED_END Soft3D_SetAspectRatio, _TEXT$00

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



END
