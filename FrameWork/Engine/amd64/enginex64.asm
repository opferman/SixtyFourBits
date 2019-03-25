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

ENGINE_INCLUDE EQU <1>

;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64.inc
include ddrawx64.inc
include master.inc
include engdbg_internal.inc
include ddraw_internal.inc
include debug_public.inc

extern GetCurrentThreadId:proc
extern LocalAlloc:proc
extern LocalFree:proc

extern vsprintf:proc
extern OutputDebugStringA:proc
extern TlsAlloc:proc
extern TlsGetValue:proc
extern TlsSetValue:proc
extern CloseHandle:proc
extern CreateThread:proc


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

SAVEFRAME_TOTAL struct
    SaveRax        dq ?
    SaveRbx        dq ?
    SaveRcx        dq ?
    SaveRdx        dq ?
    SaveR8         dq ?
    SaveR9         dq ?
    SaveR10        dq ?
    SaveR11        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
    SaveR14        dq ?
    SaveR15        dq ?
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbp        dq ?
SAVEFRAME_TOTAL ends

SAVEFRAME_TOTAL_XMM struct
    SaveXmm0       oword ?
    SaveXmm1       oword ?
    SaveXmm2       oword ?
    SaveXmm3       oword ?
    SaveXmm4       oword ?
    SaveXmm5       oword ?
    SaveXmm6       oword ?
    SaveXmm7       oword ?
    SaveXmm8       oword ?
    SaveXmm9       oword ?
    SaveXmm10      oword ?
    SaveXmm11      oword ?
    SaveXmm12      oword ?
    SaveXmm13      oword ?
    SaveXmm14      oword ?
    SaveXmm15      oword ?
    SaveRflags     dq ?
SAVEFRAME_TOTAL_XMM ends

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
   Param6                dq      ?
   Padding               dq      ?
   SaveFrameCtx         SAVEFRAME <?>
ENGINE_FREE_LOCALS ends

ENGINE_SAVE_TOTAL struct
   ParamFrameArea PARAMFRAME            <?>
   Param5                dq              ?
   Param6                dq              ?
   StringBuffer          db    256     DUP(<?>)
   Padding               dq  ?
   SaveRegs           SAVEFRAME_TOTAL <?>
   SaveXmmRegs        SAVEFRAME_TOTAL_XMM <?>
ENGINE_SAVE_TOTAL ends

ENGINE_SAVE_TOTAL_FUNC struct
   ParamFrameArea PARAMFRAME            <?>
   Param5                dq              ?
   Param6                dq              ?
   StringBuffer          db    256     DUP(<?>)
   Padding               dq  ?
   SaveRegs           SAVEFRAME_TOTAL   <?>
   SaveXmmRegs        SAVEFRAME_TOTAL_XMM <?>
   Func               FUNC_PARAMS       <?>
ENGINE_SAVE_TOTAL_FUNC ends


ENGINE_INIT_LOCALS struct
   ParamFrameArea PARAMFRAME    <?>
   Param5                dq      ?
   Padding               dq      ?
   Param6                dq      ?
   SaveFrameCtx         SAVEFRAME <?>
ENGINE_INIT_LOCALS ends

SAVE_COMPLETE_STD_REGS MACRO Structure
 save_reg r8, Structure.SaveRegs.SaveR8
 save_reg r9, Structure.SaveRegs.SaveR9
 save_reg r10, Structure.SaveRegs.SaveR10
 save_reg r11, Structure.SaveRegs.SaveR11
 save_reg rax, Structure.SaveRegs.SaveRax
 save_reg rcx, Structure.SaveRegs.SaveRcx
 save_reg rdx, Structure.SaveRegs.SaveRdx
 save_reg r12, Structure.SaveRegs.SaveR12
 save_reg r13, Structure.SaveRegs.SaveR13
 save_reg r14, Structure.SaveRegs.SaveR14
 save_reg r15, Structure.SaveRegs.SaveR15
 save_reg rdi, Structure.SaveRegs.SaveRdi
 save_reg rsi, Structure.SaveRegs.SaveRsi
 save_reg rbx, Structure.SaveRegs.SaveRbx
 save_reg rbp, Structure.SaveRegs.SaveRbp
ENDM

RESTORE_COMPLETE_STD_REGS MACRO Structure
 MOV rax, Structure.SaveRegs.SaveRax[RSP]
 MOV rbx, Structure.SaveRegs.SaveRbx[RSP]
 MOV rcx, Structure.SaveRegs.SaveRcx[RSP]
 MOV rdx, Structure.SaveRegs.SaveRdx[RSP]
 MOV rdi, Structure.SaveRegs.SaveRdi[RSP]
 MOV rsi, Structure.SaveRegs.SaveRsi[RSP]
 MOV r8, Structure.SaveRegs.SaveR8[RSP]
 MOV r9, Structure.SaveRegs.SaveR9[RSP]
 MOV r10, Structure.SaveRegs.SaveR10[RSP]
 MOV r11, Structure.SaveRegs.SaveR11[RSP]
 MOV r12, Structure.SaveRegs.SaveR12[RSP]
 MOV r13, Structure.SaveRegs.SaveR13[RSP]
 MOV r14, Structure.SaveRegs.SaveR14[RSP]
 MOV r15, Structure.SaveRegs.SaveR15[RSP]
 MOV rdi, Structure.SaveRegs.SaveRdi[RSP]
 MOV rsi, Structure.SaveRegs.SaveRsi[RSP]
 MOV rbp, Structure.SaveRegs.SaveRbp[RSP]
ENDM

SAVE_COMPLETE_XMM_REGS MACRO Structure
 MOVAPS  Structure.SaveXmmRegs.SaveXmm0[RSP], xmm0
 MOVAPS  Structure.SaveXmmRegs.SaveXmm1[RSP], xmm1  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm2[RSP], xmm2  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm3[RSP], xmm3  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm4[RSP], xmm4  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm5[RSP], xmm5  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm6[RSP], xmm6  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm7[RSP], xmm7  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm8[RSP], xmm8  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm9[RSP], xmm9  
 MOVAPS  Structure.SaveXmmRegs.SaveXmm10[RSP], xmm10 
 MOVAPS  Structure.SaveXmmRegs.SaveXmm11[RSP], xmm11 
 MOVAPS  Structure.SaveXmmRegs.SaveXmm12[RSP], xmm12 
 MOVAPS  Structure.SaveXmmRegs.SaveXmm13[RSP], xmm13 
 MOVAPS  Structure.SaveXmmRegs.SaveXmm14[RSP], xmm14 
 MOVAPS  Structure.SaveXmmRegs.SaveXmm15[RSP], xmm15 
ENDM

RESTORE_COMPLETE_XMM_REGS MACRO Structure
 MOVAPS  xmm0, Structure.SaveXmmRegs.SaveXmm0[RSP]
 MOVAPS  xmm1, Structure.SaveXmmRegs.SaveXmm1[RSP]
 MOVAPS  xmm2, Structure.SaveXmmRegs.SaveXmm2[RSP]
 MOVAPS  xmm3, Structure.SaveXmmRegs.SaveXmm3[RSP]
 MOVAPS  xmm5, Structure.SaveXmmRegs.SaveXmm4[RSP]
 MOVAPS  xmm6, Structure.SaveXmmRegs.SaveXmm5[RSP]
 MOVAPS  xmm6, Structure.SaveXmmRegs.SaveXmm6[RSP]
 MOVAPS  xmm7, Structure.SaveXmmRegs.SaveXmm7[RSP]
 MOVAPS  xmm8, Structure.SaveXmmRegs.SaveXmm8[RSP]
 MOVAPS  xmm9, Structure.SaveXmmRegs.SaveXmm9[RSP]
 MOVAPS  xmm10, Structure.SaveXmmRegs.SaveXmm10[RSP]
 MOVAPS  xmm11, Structure.SaveXmmRegs.SaveXmm11[RSP]
 MOVAPS  xmm12, Structure.SaveXmmRegs.SaveXmm12[RSP]
 MOVAPS  xmm13, Structure.SaveXmmRegs.SaveXmm13[RSP]
 MOVAPS  xmm14, Structure.SaveXmmRegs.SaveXmm14[RSP]
 MOVAPS  xmm15, Structure.SaveXmmRegs.SaveXmm15[RSP]
ENDM

public Engine_Debug
public Engine_Private_OverrideDemoFunction
public Engine_DebugInit

NESTED_FUNCTIONS_FOR_DEBUG EQU <25>
NUMBER_THREADS             EQU <5>

FUNCTION_STATE_STACK struct
 ; Nesting Counter At The Top Of The Stack
 SaveR12Register      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR13Register      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR14Register      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveR15Register      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRsiRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRdiRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRbxRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRbpRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveRspRegister      dq  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm6Register     oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm7Register     oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm8Register     oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm9Register     oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm10Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm11Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm12Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm13Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm14Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
 SaveXmm15Register    oword  NESTED_FUNCTIONS_FOR_DEBUG DUP(?)
FUNCTION_STATE_STACK ends

THREAD_CONTEXT struct
 ThreadFunction dq ?
 ThreadContext  dq ?
 DebugStackSize dq ?
THREAD_CONTEXT ends

.DATA
 GlobalDemoStructure  dq ?
 ThreadStackTls       dq ?
 
 GarbageXmmData        dq 0FFFFFFFFFFFFFFFFh
                       dq 0FFFFFFFFFFFFFFFFh

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
  ENGINE_DEBUG_RSP_CHECK_MACRO
  MOV [GlobalDemoStructure], RDX
  MOV RDI, RCX
  MOV RDX, SIZE MASTER_DEMO_STRUCT
  MOV RCX, LMEM_ZEROINIT
  ENGINE_DEBUG_FUNCTION_CALL LocalAlloc
  
  TEST RAX, RAX
  JZ @Engine_Init_Failure
  
  MOV MASTER_DEMO_STRUCT.DirectDrawCtx[RAX], RDI
  MOV RDI, RAX
  
  MOV RSI, [GlobalDemoStructure]
  
  MOV MASTER_DEMO_STRUCT.CurrentDemoStruct[RDI], RSI

  LEA RDX, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  LEA R8, MASTER_DEMO_STRUCT.Pitch[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_LockSurfaceBuffer  

  LEA R9, MASTER_DEMO_STRUCT.BitsPerPixel[RDI]
  LEA RDX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  LEA R8, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_GetScreenRes

  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_UnLockSurfaceAndFlip

@Engine_Init_loop:  
  XOR RAX, RAX
  CMP QWORD PTR [RSI], RAX
  JZ @Engine_Init_Complete
  
  MOV RAX, DEMO_STRUCT.InitFunction[RSI]
  MOV RCX, RDI
  ENGINE_DEBUG_FUNCTION_CALL RAX
  
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
;  Engine_Private_OverrideDemoFunction
;
;        Parameters: Maeter Demo Structure, New Demo Function
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Engine_Private_OverrideDemoFunction, _TEXT$00
 alloc_stack(SIZEOF ENGINE_FREE_LOCALS)
 save_reg rdi, ENGINE_FREE_LOCALS.SaveFrameCtx.SaveRdi
.ENDPROLOG 
  ENGINE_DEBUG_RSP_CHECK_MACRO

  MOV RDI, MASTER_DEMO_STRUCT.CurrentDemoStruct[RCX]
  MOV DEMO_STRUCT.DemoFunction[RDI], RDX

  MOV RDI, ENGINE_FREE_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZEOF ENGINE_FREE_LOCALS
  RET
NESTED_END Engine_Private_OverrideDemoFunction, _TEXT$00


;*********************************************************
;  Engine_DebugInit
;
;        Parameters: None
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Engine_DebugInit, _TEXT$00
  SUB RSP, 8 + 8*4
.ENDPROLOG 
  ENGINE_DEBUG_RSP_CHECK_MACRO
IF DEBUG_IS_ENABLED 
  CALL TlsAlloc
  MOV [ThreadStackTls], RAX

  MOV RDX, (NESTED_FUNCTIONS_FOR_DEBUG * SIZE FUNCTION_STATE_STACK) + (2*SIZE QWORD)
  MOV RCX, LMEM_ZEROINIT
  CALL LocalAlloc
  ;
  ; TODO Error handling
  ;
  MOV RDX, RAX
  ADD RDX, 8*2                          ; Setup Stack Pointer
  MOV QWORD PTR [RAX + 8], RDX
  MOV RDX, RAX
  MOV RCX, [ThreadStackTls]
  CALL TlsSetValue
ENDIF
  ADD RSP, 8 + 8*4
  RET
NESTED_END Engine_DebugInit, _TEXT$00



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
  ENGINE_DEBUG_RSP_CHECK_MACRO
  
  MOV RDI, ENGINE_FREE_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  ADD RSP, SIZEOF ENGINE_FREE_LOCALS
  RET
NESTED_END Engine_Free, _TEXT$00

;*********************************************************
;  Engine_Debug
;
;        Parameters: Format String, ...
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Engine_Debug, _TEXT$00
 PUSHFQ
 alloc_stack(SIZEOF ENGINE_SAVE_TOTAL - 8)
.ENDPROLOG 
 SAVE_COMPLETE_XMM_REGS  ENGINE_SAVE_TOTAL
 SAVE_COMPLETE_STD_REGS  ENGINE_SAVE_TOTAL

  ENGINE_DEBUG_RSP_CHECK_MACRO
  ;MOV ENGINE_SAVE_TOTAL_FUNC.Func.Param1[RSP], RCX  Caller to use Parameters Instead of Regiters.
  ;MOV ENGINE_SAVE_TOTAL_FUNC.Func.Param2[RSP], RDX
  ;MOV ENGINE_SAVE_TOTAL_FUNC.Func.Param3[RSP], R8
  ;MOV ENGINE_SAVE_TOTAL_FUNC.Func.Param4[RSP], R9

  LEA R8, ENGINE_SAVE_TOTAL_FUNC.Func.Param2[RSP]
  MOV RDX, ENGINE_SAVE_TOTAL_FUNC.Func.Param1[RSP]
  LEA RCX, ENGINE_SAVE_TOTAL_FUNC.StringBuffer[RSP]
  CALL vsprintf

  LEA RCX, ENGINE_SAVE_TOTAL_FUNC.StringBuffer[RSP]
  CALL OutputDebugStringA
  
  RESTORE_COMPLETE_STD_REGS  ENGINE_SAVE_TOTAL
  RESTORE_COMPLETE_XMM_REGS  ENGINE_SAVE_TOTAL
  ADD RSP, SIZEOF ENGINE_SAVE_TOTAL - 8
  POPFQ 
  RET
NESTED_END Engine_Debug, _TEXT$00

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
  ENGINE_DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_RestoreSurfacesIfNeeded

  LEA RDX, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  LEA R8, MASTER_DEMO_STRUCT.Pitch[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_LockSurfaceBuffer

  TEST RAX, RAX
  JZ @Engine_Loop_Exit

  LEA RDX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  LEA R8, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  LEA R9, MASTER_DEMO_STRUCT.BitsPerPixel[RDI]

  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]  
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_GetScreenRes
  
  TEST RAX, RAX
  JZ @Engine_Loop_ExitFailure

  MOV RSI, MASTER_DEMO_STRUCT.CurrentDemoStruct[RDI]
  
  MOV RCX, RDI
  MOV RAX, DEMO_STRUCT.DemoFunction[RSI]
  ENGINE_DEBUG_FUNCTION_CALL RAX
  
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
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_UnLockSurfaceAndFlip
  
@Engine_Loop_Exit:
  MOV RAX, 1
  MOV RDI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  MOV RSI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRsi[RSP]
  ADD RSP, SIZE ENGINE_LOOP_LOCALS
  RET
@Engine_Loop_Demo_Complete:
  MOV RCX, MASTER_DEMO_STRUCT.DirectDrawCtx[RDI]
  ENGINE_DEBUG_FUNCTION_CALL DDrawx64_UnLockSurfaceAndFlip
    
@Engine_Loop_ExitFailure:
  XOR RAX, RAX
  MOV RDI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRdi[RSP]
  MOV RSI, ENGINE_LOOP_LOCALS.SaveFrameCtx.SaveRsi[RSP]
  ADD RSP, SIZE ENGINE_LOOP_LOCALS
  RET
  
NESTED_END Engine_Loop, _TEXT$00


;*********************************************************
;  Engine_PushDebugThreadContext
;
;        Parameters: None
;
;          This will create a context for a thread
;
;*********************************************************  
NESTED_ENTRY Engine_PushDebugThreadContext, _TEXT$00
SUB RSP, 8*4
;
; Save Registers
;
.ENDPROLOG 
 MOV RCX, [ThreadStackTls]
 CALL TlsGetValue
 CMP RAX, 0
 JE @NoData
 INC QWORD PTR [RAX]
 CMP QWORD PTR [RAX], NESTED_FUNCTIONS_FOR_DEBUG                        ; TODO, allow this to be configured Per-Stack
 JAE @Overflow
 MOV RCX, RAX
 MOV RAX, QWORD PTR [RAX + 8]
 ADD QWORD PTR [RCX + 8], SIZE FUNCTION_STATE_STACK
 ADD RSP, 8*4
 RET
@Overflow:
@NoData:
 INT 3 
 INT 3 
NESTED_END Engine_PushDebugThreadContext, _TEXT$00


;*********************************************************
;  Engine_PopDebugThreadContext
;
;        Parameters: None
;
;          This will get a context for a thread
;
;*********************************************************  
NESTED_ENTRY Engine_PopDebugThreadContext, _TEXT$00
 SUB RSP, 8*4
.ENDPROLOG 
;
; Save Registers
;
.ENDPROLOG 
 MOV RCX, [ThreadStackTls]
 CALL TlsGetValue
 CMP RAX, 0
 JE @NoData
 DEC QWORD PTR [RAX]
 CMP QWORD PTR [RAX], 0
 JL @Underflow
 SUB QWORD PTR [RAX + 8], SIZE FUNCTION_STATE_STACK
 MOV RAX, QWORD PTR [RAX + 8]
 ADD RSP, 8*4
 RET
@Underflow:
@NoData:
 INT 3 
 RET
NESTED_END Engine_PopDebugThreadContext, _TEXT$00

;*********************************************************
;  Engine_CreateThread
;
;        Parameters: Function, Context, Debug Depth (ignored currently)
;
;        Return: Handle
;
;*********************************************************  
NESTED_ENTRY Engine_CreateThread, _TEXT$00
 SUB RSP, SIZE QWORD + (8*SIZE QWORD)
.ENDPROLOG 
 ENGINE_DEBUG_RSP_CHECK_MACRO
 MOV [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + SIZE QWORD)], RCX
 MOV [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + (2*SIZE QWORD))], RDX
 MOV [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + (3*SIZE QWORD))], R8

 MOV RDX, SIZE THREAD_CONTEXT
 MOV RCX, LMEM_ZEROINIT
 DEBUG_FUNCTION_CALL LocalAlloc
 ;
 ; TODO: Error Handling
 ;
 MOV RCX, [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + SIZE QWORD)]
 MOV RDX, [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + (2*SIZE QWORD))]
 MOV R8, [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + (3*SIZE QWORD))]

 MOV THREAD_CONTEXT.ThreadFunction[RAX], RCX
 MOV THREAD_CONTEXT.ThreadContext[RAX], RDX
 MOV THREAD_CONTEXT.DebugStackSize[RAX], R8

 ;
 ; Create Function Call
 ;
 MOV QWORD PTR [RSP + 4*SIZE QWORD], 0
 MOV QWORD PTR [RSP + 5*SIZE QWORD], 0
 MOV R9, RAX
 MOV R8, Engine_Thread
 XOR RDX, RDX
 XOR RCX, RCX
 DEBUG_FUNCTION_CALL CreateThread
 ;
 ; TODO: Error Handling
 ;
 ADD RSP, SIZE QWORD + (8*SIZE QWORD)
 RET
NESTED_END Engine_CreateThread, _TEXT$00


;*********************************************************
;  Engine_Thread
;
;        Parameters: Context
;
;        Return: Handle
;
;*********************************************************
NESTED_ENTRY Engine_Thread, _TEXT$00
 SUB RSP, 8 + 8*4
.ENDPROLOG 
 ENGINE_DEBUG_RSP_CHECK_MACRO
 MOV [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + SIZE QWORD)], RCX

IF DEBUG_IS_ENABLED 
 MOV RDX, (NESTED_FUNCTIONS_FOR_DEBUG * SIZE FUNCTION_STATE_STACK) + (2*SIZE QWORD)
 MOV RCX, LMEM_ZEROINIT
 CALL LocalAlloc
 ;
 ; TODO: Error Handling
 ;
 MOV RDX, RAX
 ADD RDX, 8*2
 MOV QWORD PTR [RAX + 8], rdx   ; setup stack pointer

 MOV RDX, RAX
 MOV RCX, [ThreadStackTls]
 CALL TlsSetValue
ENDIF

 MOV RCX, [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + SIZE QWORD)] 
 MOV RDX, RCX
 MOV RCX, THREAD_CONTEXT.ThreadContext[RDX]
 DEBUG_FUNCTION_CALL THREAD_CONTEXT.ThreadFunction[RDX]

 MOV RCX, [RSP + ((SIZE QWORD + (8*SIZE QWORD)) + SIZE QWORD)]
 CALL LocalFree

IF DEBUG_IS_ENABLED 
 MOV RCX, [ThreadStackTls]
 CALL TlsGetValue
 MOV RCX, RAX
 CALL LocalFree
ENDIF

 ADD RSP, 8 + 8*4
 RET
NESTED_END Engine_Thread, _TEXT$00


;*********************************************************
;  Engine_CloseThread
;
;        Parameters: Function
;
;        Return: Handle
;
;*********************************************************  
NESTED_ENTRY Engine_CloseThread, _TEXT$00
 SUB RSP, 8
.ENDPROLOG 
 ENGINE_DEBUG_RSP_CHECK_MACRO
 DEBUG_FUNCTION_CALL CloseHandle
@NoData:
 ADD RSP, 8
 RET
NESTED_END Engine_CloseThread, _TEXT$00


;*********************************************************
;  Engine_PreFunctionCall
;
;        Parameters: None
;
;
;*********************************************************  
NESTED_ENTRY Engine_PreFunctionCall, _TEXT$00
.ENDPROLOG 
 ;
 ; Save Function Parameters
 ;
 MOV [RSP+8h], RCX
 MOV [RSP+10h], RDX
 MOV [RSP+18h], R8
 MOV [RSP+20h], R9
 CALL Engine_PushDebugThreadContext

 ;
 ; GP Registers
 ;
 MOV [RAX], R12
 ADD RAX, SIZE QWORD 
 MOV [RAX], R13
 ADD RAX, SIZE QWORD
 MOV [RAX], R14
 ADD RAX, SIZE QWORD
 MOV [RAX], R15
 ADD RAX, SIZE QWORD
 MOV [RAX], RSI
 ADD RAX, SIZE QWORD
 MOV [RAX], RDI
 ADD RAX, SIZE QWORD
 MOV [RAX], RBX
 ADD RAX, SIZE QWORD
 MOV [RAX], RBP
 ADD RAX, SIZE QWORD
 MOV [RAX], RSP
 ADD RAX, SIZE QWORD
 
 ;
 ; XMM Registers
 ;
 MOVUPS [RAX], xmm6 
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm7
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm8
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm9
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm10
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm11
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm12
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm13
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm14
 ADD RAX, SIZE OWORD
 MOVUPS [RAX], xmm15

 ;
 ; Restore Function Parameters
 ;
 MOV RCX, [RSP+8h]
 MOV RDX, [RSP+10h]
 MOV R8, [RSP+18h]
 MOV R9, [RSP+20h]
 RET
NESTED_END Engine_PreFunctionCall, _TEXT$00

;*********************************************************
;  Engine_PostFunctionCall
;
;        Parameters: None
;
;
;
;
;*********************************************************  
NESTED_ENTRY Engine_PostFunctionCall, _TEXT$00
.ENDPROLOG 
 MOV [RSP+8], RAX 

 CALL Engine_PopDebugThreadContext
 MOV R11, RAX
 ;
 ; Check Non-Volatile Registers were preserved
 ;
 
 MOV RAX, 12
 CMP [R11], R12
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 13
 CMP [R11], R13
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 14
 CMP [R11], R14
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 15
 CMP [R11], R15
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 1
 CMP [R11], RSI
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 2
 CMP [R11], RDI
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 3
 CMP [R11], RBX
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 4
 CMP [R11], RBP
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 MOV RAX, 5
 CMP [R11], RSP
 JNE @Engine_Debug_Issue
 ADD R11, SIZE QWORD

 LEA RCX, [RSP + 16]

 MOV RAX, 6
 MOVUPS [RCX], xmm6 
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 7
 MOVUPS  [RCX], xmm7
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 8
 MOVUPS  [RCX], xmm8
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 9
 MOVUPS  [RCX], xmm9
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 10
 MOVUPS  [RCX], xmm10
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 11
 MOVUPS  [RCX], xmm11
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 12
 MOVUPS  [RCX], xmm12
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 13
 MOVUPS  [RCX], xmm13
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue
 
 ADD R11, SIZE OWORD

 MOV RAX, 14
 MOVUPS  [RCX], xmm14
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
 CMP QWORD PTR [RCX], R8
 JNE  @Engine_Debug_Issue
 CMP QWORD PTR [RCX+8], R9
 JNE  @Engine_Debug_Issue

 ADD R11, SIZE OWORD

 MOV RAX, 15
 MOVUPS  [RCX], xmm15
 MOV R8, QWORD PTR [R11]
 MOV R9, QWORD PTR [R11+8]
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
