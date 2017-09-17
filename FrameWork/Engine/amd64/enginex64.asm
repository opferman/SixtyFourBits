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


NESTED_FUNCTIONS_FOR_DEBUG EQU <10>

.DATA

GlobalDemoStructure  dq ?
 
 SaveR12Register      dq NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR13Register      dq NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR14Register      dq NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR15Register      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)

 SaveRsiRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRdiRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRbxRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRbpRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRspRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)

 SaveXmm6Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm7Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm8Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm9Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm10Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm11Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm12Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm13Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm14Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm15Register     xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 CompareXmmRegister    xmmword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SpecialSaveRegister1    dq ?
 SpecialSaveRegister2    dq ?

 GarbageXmmData        dq 0FFFFFFFFFFFFFFFFh
                       dq 0FFFFFFFFFFFFFFFFh

  NestingCounter       dq 0

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


;*********************************************************
;  Engine_PreFunctionCall
;
;        Parameters: None
;
;          This is a single threaded test function that will
;        save the Non-Volatile registers.  The purpose is to 
;        use this before a function call and then use 
;        "Engine_PostFunctionCall" to verify the integrity
;        of your function.
;
;*********************************************************  
NESTED_ENTRY Engine_PreFunctionCall, _TEXT$00
.ENDPROLOG 
 CMP [NestingCounter], NESTED_FUNCTIONS_FOR_DEBUG
 JB @ValidNesting
 INT 3

@ValidNesting:
 MOV [SpecialSaveRegister1], RAX
 MOV [SpecialSaveRegister2], RBX
 MOV RBX, [NestingCounter]
 SHL RBX, 6

 LEA RAX, [SaveR12Register]
 MOV [RAX + RBX], R12

 LEA RAX, [SaveR13Register]
 MOV [RAX + RBX], R13

 LEA RAX, [SaveR14Register]
 MOV [RAX + RBX], R14

 LEA RAX, [SaveR15Register]
 MOV [RAX + RBX], R15

 LEA RAX, [SaveRsiRegister]
 MOV [RAX + RBX], RSI

 LEA RAX, [SaveRdiRegister]
 MOV [RAX + RBX], RDI
 
 LEA RAX, [SaveRbpRegister]
 MOV [RAX + RBX], RBP
 
 LEA RAX, [SaveRspRegister]
 MOV [RAX + RBX], RSP
 
 LEA RAX, [SaveXmm6Register]
 MOVUPS [RAX + RBX], xmm6 
 LEA RAX, [SaveXmm7Register]
 MOVUPS [RAX + RBX], xmm7
 LEA RAX, [SaveXmm8Register]
 MOVUPS [RAX + RBX], xmm8
 LEA RAX, [SaveXmm9Register]
 MOVUPS [RAX + RBX], xmm9
 LEA RAX, [SaveXmm10Register]
 MOVUPS [RAX + RBX], xmm10
 LEA RAX, [SaveXmm11Register]
 MOVUPS [RAX + RBX], xmm11
 LEA RAX, [SaveXmm12Register]
 MOVUPS [RAX + RBX], xmm12
 LEA RAX, [SaveXmm13Register]
 MOVUPS [RAX + RBX], xmm13
 LEA RAX, [SaveXmm14Register]
 MOVUPS [RAX + RBX], xmm14
 LEA RAX, [SaveXmm15Register]
 MOVUPS [RAX + RBX], xmm15

 LEA RAX, [SaveRbxRegister]
 ADD RAX, RBX
 MOV RBX, [SpecialSaveRegister2]
 MOV [RAX], RBX

 INC [NestingCounter]

 MOV RAX, [SpecialSaveRegister1]
 RET
NESTED_END Engine_PreFunctionCall, _TEXT$00

;*********************************************************
;  Engine_PostFunctionCall
;
;        Parameters: None
;
;          This is a single threaded test function that will
;        save the Non-Volatile registers.  The purpose is to 
;        use this before a function call and then use 
;        "Engine_PostFunctionCall" to verify the integrity
;        of your function.
;
;*********************************************************  
NESTED_ENTRY Engine_PostFunctionCall, _TEXT$00
.ENDPROLOG 
 DEC [NestingCounter]

 MOV [RSP+8], RAX ; We can use Param1-4 in Post Function call but not in Pre.

 MOV R10, [NestingCounter]
 SHL R10, 6

 ;
 ; Check Non-Volatile Registers were preserved
 ;

 MOV RAX, 12
 LEA RDX, [SaveR12Register]
 CMP [RDX + R10], R12
 JNE @Engine_Debug_Issue

 MOV RAX, 13
 LEA RDX, [SaveR13Register]
 CMP [RDX + R10], R13
 JNE @Engine_Debug_Issue

 MOV RAX, 14
 LEA RDX, [SaveR14Register]
 CMP [RDX + R10], R14
 JNE @Engine_Debug_Issue

 MOV RAX, 15
 LEA RDX, [SaveR15Register]
 CMP [RDX + R10], R15
 JNE @Engine_Debug_Issue

 MOV RAX, 1
 LEA RDX, [SaveRsiRegister]
 CMP [RDX + R10], RSI
 JNE @Engine_Debug_Issue

 MOV RAX, 2
 LEA RDX, [SaveRdiRegister]
 CMP [RDX + R10], RDI
 JNE @Engine_Debug_Issue

 MOV RAX, 3
 LEA RDX, [SaveRbxRegister]
 CMP [RDX + R10], RBX
 JNE @Engine_Debug_Issue

 MOV RAX, 4
 LEA RDX, [SaveRbpRegister]
 CMP [RDX + R10], RBP
 JNE @Engine_Debug_Issue

 MOV RAX, 5
 LEA RDX, [SaveRspRegister]
 CMP [RDX + R10], RSP
 JNE @Engine_Debug_Issue

 LEA RCX, [CompareXmmRegister]


 MOV RAX, 6
 MOVUPS [CompareXmmRegister], xmm6 
 LEA RDX, [SaveXmm6Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 MOV RAX, 7
 MOVUPS [CompareXmmRegister], xmm7
 LEA RDX, [SaveXmm7Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue


 MOV RAX, 8
 MOVUPS [CompareXmmRegister], xmm8
 LEA RDX, [SaveXmm8Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue


 MOV RAX, 9
 MOVUPS [CompareXmmRegister], xmm9
 LEA RDX, [SaveXmm9Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue


 MOV RAX, 10
 MOVUPS [CompareXmmRegister], xmm10
 LEA RDX, [SaveXmm10Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue


 MOV RAX, 11
 MOVUPS [CompareXmmRegister], xmm11
 LEA RDX, [SaveXmm11Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 MOV RAX, 12
 MOVUPS [CompareXmmRegister], xmm12
 LEA RDX, [SaveXmm12Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 MOV RAX, 13
 MOVUPS [CompareXmmRegister], xmm13
 LEA RDX, [SaveXmm13Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 MOV RAX, 14
 MOVUPS [CompareXmmRegister], xmm14
 LEA RDX, [SaveXmm14Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 MOV RAX, 15
 MOVUPS [CompareXmmRegister], xmm15
 LEA RDX, [SaveXmm15Register]
 ADD RDX, R10
 MOV R8, QWORD PTR [RDX]
 MOV R9, QWORD PTR [RDX+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ;
 ; Except RAX and XMM0, populate Volatile Registers with Garbage
 ;
 MOV RCX, 0FFFFFFFFFFFFFFFFh
 MOV RDX, 0FFFFFFFFFFFFFFFFh
 MOV R8,0FFFFFFFFFFFFFFFFh
 MOV R9,0FFFFFFFFFFFFFFFFh
 MOV R10,0FFFFFFFFFFFFFFFFh
 MOV R11,0FFFFFFFFFFFFFFFFh

 LEA RAX, [GarbageXmmData]
 MOVUPS xmm1, xmmword ptr [RAX]
 MOVUPS xmm2,xmm1
 MOVUPS xmm3,xmm1
 MOVUPS xmm4,xmm1
 MOVUPS xmm5,xmm1
 
 MOV RAX, [RSP+8]
 RET  
@Engine_Debug_Issue:
 INT 3
 RET  
NESTED_END Engine_PostFunctionCall, _TEXT$00

END
