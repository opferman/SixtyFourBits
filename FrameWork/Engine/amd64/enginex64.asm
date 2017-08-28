;*********************************************************
; Demo Engine
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/26/2010-2017
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
include demoprocs.inc
include ddrawx64.inc
include master.inc

extern LocalAlloc:proc

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
SAVEFRAME ends



ENGINE_LOOP_LOCALS struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq      ?
   Padding               dq      ?
   Param6                dq      ?
   SaveFrameCtx         SAVEFRAME <?>
ENGINE_LOOP_LOCALS ends

ENGINE_FREE_LOCALS struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq      ?
   Padding               dq      ?
   Param6                dq      ?
   SaveFrameCtx         SAVEFRAME <?>
ENGINE_FREE_LOCALS ends

ENGINE_INIT_LOCALS struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq      ?
   Padding               dq      ?
   Param6                dq      ?
   SaveFrameCtx         SAVEFRAME <?>
ENGINE_INIT_LOCALS ends



.DATA

GlobalDemoStructure  dq ?


.CODE
  
;*********************************************************
;  Engine_Init
;
;        Parameters: DirectDrawCtx, GlobalDemoStructure
;
;        Return Value: Master Context
;
;
;*********************************************************  
NESTED_ENTRY Engine_Init, _TEXT$00
 alloc_stack(SIZEOF ENGINE_INIT_LOCALS)
 save_reg rdi, ENGINE_INIT_LOCALS.SaveFrameCtx.SaveRdi
 save_reg rsi, ENGINE_INIT_LOCALS.SaveFrameCtx.SaveRsi
.ENDPROLOG 
  MOV [GlobalDemoStructure], RDX
  MOV RDI, RCX
  MOV RDX, SIZE MASTER_DEMO_STRUCT
  MOV RCX, LMEM_ZEROINIT
  CALL LocalAlloc
  
  TEST RAX, RAX
  JZ @Engine_Init_Failure
  
  MOV MASTER_DEMO_STRUCT.DirectDrawCtx[RAX], RDI
  MOV RDI, RAX
  
  MOV RSI, [GlobalDemoStructure]
  
  MOV MASTER_DEMO_STRUCT.CurrentDemoStruct[RDI], RSI

  LEA RDX, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  LEA R8, MASTER_DEMO_STRUCT.Pitch[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  CALL DDrawx64_LockSurfaceBuffer  

  LEA R9, MASTER_DEMO_STRUCT.BitsPerPixel[RDI]
  LEA RDX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  LEA R8, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  CALL DDrawx64_GetScreenRes

  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]
  CALL DDrawx64_UnLockSurfaceAndFlip

@Engine_Init_loop:  
  XOR RAX, RAX
  CMP QWORD PTR [RSI], RAX
  JZ @Engine_Init_Complete
  
  MOV RAX, DEMO_STRUCT.InitFunction[RSI]
  MOV RCX, RDI
  CALL RAX
  
  ;
  ; TODO: Check Return Value
  ;
  
  ADD RSI, SIZE DEMO_STRUCT
  JMP @Engine_Init_loop
  
@Engine_Init_Complete:
  MOV RAX, RDI
  
@Engine_Init_Failure:
  
  MOV RDI, ENGINE_INIT_LOCALS.SaveFrameCtx.SaveRdi[RSP]  
  MOV RSI, ENGINE_INIT_LOCALS.SaveFrameCtx.SaveRsi[RSP]  
  ADD RSP, SIZE ENGINE_INIT_LOCALS 
  RET

NESTED_END Engine_Init, _TEXT$00



;*********************************************************
;  Engine_Free
;
;        Parameters: Direct Draw Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Engine_Free, _TEXT$00
 alloc_stack(SIZEOF ENGINE_FREE_LOCALS)
 save_reg rdi, ENGINE_FREE_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 
  
  
  MOV RDI, ENGINE_FREE_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZEOF ENGINE_FREE_LOCALS
  RET
NESTED_END Engine_Free, _TEXT$00



;*********************************************************
;  Engine_Loop
;
;        Parameters: Direct Draw Context, Pointer To Video Buffer, Pointer to Pitch
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Engine_Loop, _TEXT$00
 alloc_stack(SIZEOF ENGINE_LOOP_LOCALS)
 save_reg rdi, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRdi
 save_reg rsi, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRsi
.ENDPROLOG 
  MOV RDI, RCX
  
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  CALL DDrawx64_RestoreSurfacesIfNeeded

  LEA RDX, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  LEA R8, MASTER_DEMO_STRUCT.Pitch[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  CALL DDrawx64_LockSurfaceBuffer

  TEST RAX, RAX
  JZ @Engine_Loop_Exit

  LEA RDX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  LEA R8, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  LEA R9, MASTER_DEMO_STRUCT.BitsPerPixel[RDI]

  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  CALL DDrawx64_GetScreenRes
  
  TEST RAX, RAX
  JZ @Engine_Loop_ExitFailure

  MOV RSI, MASTER_DEMO_STRUCT.CurrentDemoStruct[RDI]
  
  MOV RCX, RDI
  MOV RAX, DEMO_STRUCT.DemoFunction[RSI]
  CALL RAX
  
  TEST RAX, RAX  
  JNZ @Engine_FlipSurface
  
  ADD RSI, SIZE DEMO_STRUCT
  MOV MASTER_DEMO_STRUCT.CurrentDemoStruct[RDI], RSI
  
  XOR RAX, RAX
  CMP QWORD PTR [RSI], RAX
  JNZ @Engine_FlipSurface
  JMP @Engine_Loop_Demo_Complete
@Engine_FlipSurface:
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]
  CALL DDrawx64_UnLockSurfaceAndFlip
  
@Engine_Loop_Exit:
  MOV RAX, 1
  MOV RDI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  MOV RSI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRsi[RSP]
  ADD RSP, SIZE ENGINE_LOOP_LOCALS
  RET
@Engine_Loop_Demo_Complete:
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]
  CALL DDrawx64_UnLockSurfaceAndFlip
    
@Engine_Loop_ExitFailure:
  XOR RAX, RAX
  MOV RDI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  MOV RSI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRsi[RSP]
  ADD RSP, SIZE ENGINE_LOOP_LOCALS
  RET
  
NESTED_END Engine_Loop, _TEXT$00



END
