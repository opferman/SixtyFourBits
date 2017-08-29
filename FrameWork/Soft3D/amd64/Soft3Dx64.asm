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

  RET
NESTED_END Soft3D_SetCameraRotation, _TEXT$00


;*********************************************************
;  Soft3D_SetViewDistance
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetViewDistance, _TEXT$00
.ENDPROLOG 

  RET
NESTED_END Soft3D_SetViewDistance, _TEXT$00

;*********************************************************
;  Soft3D_SetViewPoint
;
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetViewPoint, _TEXT$00
.ENDPROLOG 

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
;        Parameters: 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Soft3D_SetAspectRatio, _TEXT$00
.ENDPROLOG 

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

void ThreeD_Close(H3D h3D);


END
