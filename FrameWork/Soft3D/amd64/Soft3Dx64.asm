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

extern cos:proc
extern sin:proc
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
    SaveR11        dq ?
	SaveXmm6       xmmword ?
	SaveXmm7       xmmword ?
	SaveXmm8       xmmword ?
	SaveXmm9       xmmword ?
    SaveR12        dq ?
SAVEFRAME ends

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


SOFT3D_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
SOFT3D_INIT_LOCALS ends

SOFT3D_INIT_FUNC struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
   FunctionParams FUNC_PARAMS <?>
SOFT3D_INIT_FUNC ends


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
    PlotPixelFunc     dq ?
SOFT3D_INTERNAL_CONTEXT ends

.DATA

ConstantZero    xmmword 0.0 
ConstantOne     xmmword 1.0 

.CODE

;*********************************************************
;   Soft3D_Init
;
;        Parameters: Master Context, Flags, Plot Pixel Callback
;
;        Return Value: 3D Handle
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_Init, _TEXT$00
  alloc_stack(SIZEOF SOFT3D_INIT_LOCALS)
  save_reg rdi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r12, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveR12
.ENDPROLOG 
  MOV RDI, RCX
  MOV RSI, RDX
  MOV R12, R8

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
  MOV SOFT3D_INTERNAL_CONTEXT.PlotPixelFunc[RAX], R12

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
  MOV R12, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
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
;           3D Handle, PTD_POINT pTdPointA, PTD_POINT pTdPointB, Pixel Color, PTD_POINT pPixelWorld
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
;           3D Handle, PTD_POINT pTdPoint, Pixel Color, PTD_POINT pPixelWorld
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
  alloc_stack(SIZEOF SOFT3D_INIT_LOCALS)
  save_reg rdi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r12, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveR12
  MOVAPS SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm6[RSP], xmm6
  MOVAPS SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm7[RSP], xmm7
  MOVAPS SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm8[RSP], xmm8
  MOVAPS SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm9[RSP], xmm9
.ENDPROLOG 

  MOV RDI, RCX
  MOV RSI, R9

  MOVSD xmm6, TD_POINT.x[RDX]
  MOVSD xmm7, TD_POINT.y[RDX]
  MOVSD xmm8, TD_POINT.z[RDX]

  ;
  ; Add World Coordinates
  ;
  CMP R8, 0
  JE @Skip_NoWorldCoordinates

  ADDSD xmm6, TD_POINT.x[R8]
  ADDSD xmm7, TD_POINT.y[R8]
  ADDSD xmm8, TD_POINT.z[R8]

@Skip_NoWorldCoordinates:

  ;
  ; Camera Transform, Start by subtracting the viewpoint.
  ;    

  SUBSD xmm6, SOFT3D_INTERNAL_CONTEXT.ViewPoint.x[RDI]
  SUBSD xmm7, SOFT3D_INTERNAL_CONTEXT.ViewPoint.y[RDI]
  SUBSD xmm8, SOFT3D_INTERNAL_CONTEXT.ViewPoint.z[RDI]
  
  ;
  ; Rotate the Camera X
  ; 
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RDI]
  UCOMISD xmm0, mmword ptr [ConstantZero]
  JE @Perform_CameraYRotation

  ; cos(r)*y - sin(r)*z
  CALL Cos
  MULSD xmm0, xmm7
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm8

  SUBSD xmm9, xmm0

  ; (sin(r)*y + cos(r)*z)
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm7
  MOVSD xmm7, xmm9
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraX_Radians[RDI]
  CALL Cos
  MULSD xmm0, xmm8
  ADDSD xmm0, xmm9
  MOVSD xmm8, xmm0

  ;
  ; Rotate the Camera Y
  ; 
@Perform_CameraYRotation:
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RDI]
  UCOMISD xmm0,  mmword ptr [ConstantZero]
  JE @Perform_CameraZRotation

  ; cos(r)*x - sin(r)*z
  CALL Cos
  MULSD xmm0, xmm6
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm8

  SUBSD xmm9, xmm0

  ; (sin(r)*x + cos(r)*z)
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm6
  MOVSD xmm6, xmm9
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraY_Radians[RDI]
  CALL Cos
  MULSD xmm0, xmm8
  ADDSD xmm0, xmm9
  MOVSD xmm8, xmm0
  
  ;
  ; Rotate the Camera Z
  ; 
@Perform_CameraZRotation:
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RDI]
  UCOMISD xmm0,  mmword ptr [ConstantZero]
  JE @Done_Rotations
  

  ; cos(r)*x - sin(r)*y
  CALL Cos
  MULSD xmm0, xmm6
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm7

  SUBSD xmm9, xmm0

  ; (sin(r)*x + cos(r)*y)
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RDI]
  CALL Sin
  MULSD xmm0, xmm6
  MOVSD xmm6, xmm9
  MOVSD xmm9, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.CameraZ_Radians[RDI]
  CALL Cos
  MULSD xmm0, xmm7
  ADDSD xmm0, xmm9
  MOVSD xmm7, xmm0
@Done_Rotations:

  ;
  ; Return Camera Transform
  ;
  MOV RCX, SOFT3D_INIT_FUNC.FunctionParams.Param5[RSP]
  CMP RCX, 0
  JE @Perform_TransformTo2D

  MOVSD TD_POINT.x[RCX], xmm6
  MOVSD TD_POINT.y[RCX], xmm7
  MOVSD TD_POINT.z[RCX], xmm8

@Perform_TransformTo2D:
  UCOMISD xmm8,  mmword ptr [ConstantZero]
  JLE @PixelOffScreen

  ; X = (((pInternal3d->ViewDistance*CameraX/CameraZ) + pInternal3d->HalfScreenWidth));
  MOVSD xmm1, SOFT3D_INTERNAL_CONTEXT.ViewDistance[RDI]
  MULSD xmm1, xmm6
  DIVSD xmm1, xmm8
  ADDSD xmm1, SOFT3D_INTERNAL_CONTEXT.HalfScreenWidth[RDI]

  ; Y = ((pInternal3d->HalfScreenHeight - (pInternal3d->ViewDistance*CameraY/CameraZ)));
  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.ViewDistance[RDI]
  MULSD xmm0, xmm7
  DIVSD xmm0, xmm8
  MOVSD xmm2, SOFT3D_INTERNAL_CONTEXT.HalfScreenHeight[RDI]
  SUBSD xmm2, xmm0

  MOVSD xmm0, SOFT3D_INTERNAL_CONTEXT.Aspect[RDI]
  UCOMISD xmm0,  mmword ptr [ConstantOne]
  JG @AdjustAspect_X

;  MULSD xmm2, xmm0  Ignore the aspect ratio for now it was creating an off center.
  cvttsd2si  RAX, xmm2
  MOV TD_POINT_2D.y[RSI], RAX
  cvttsd2si  RAX, xmm1
  MOV TD_POINT_2D.x[RSI], RAX

  JMP @DoneAdjustAspect
@AdjustAspect_X:

;  DIVSD xmm1, xmm0  Ignore the aspect ratio for now it was creating an off center.
  cvttsd2si  RAX, xmm2
  MOV TD_POINT_2D.y[RSI], RAX
  cvttsd2si  RAX, xmm1
  MOV TD_POINT_2D.x[RSI], RAX

  ;
  ; Check Bounds
  ;

@DoneAdjustAspect:
  
  MOV RDX, SOFT3D_INTERNAL_CONTEXT.MasterContext[RDI]

  MOV RCX, TD_POINT_2D.x[RSI]
  CMP RCX, 0
  JL @PixelOffScreen
  
  CMP RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDX]
  JGE @PixelOffScreen

  MOV RCX, TD_POINT_2D.y[RSI]
  CMP RCX, 0
  JL @PixelOffScreen

  CMP RCX, MASTER_DEMO_STRUCT.ScreenHeight[RDX]
  JGE @PixelOffScreen
		      
  MOV RAX, SOFT3D_PIXEL_ON_SCREEN
  JMP @DoneTransforming

@PixelOffScreen:
  MOV RAX, SOFT3D_PIXEL_OFF_SCREEN

@DoneTransforming:  
      
  MOVAPS xmm6, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm6[RSP]
  MOVAPS xmm7, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm7[RSP]
  MOVAPS xmm8, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm8[RSP]
  MOVAPS xmm9, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveXmm9[RSP]
  MOV RDI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV RSI, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV R12, SOFT3D_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  ADD RSP, SIZE SOFT3D_INIT_LOCALS
  RET
NESTED_END Soft3D_Convert3Dto2D, _TEXT$00



END
