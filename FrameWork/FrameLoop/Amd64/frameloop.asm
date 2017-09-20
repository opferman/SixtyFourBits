;*********************************************************
; Frame Loop Library 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  9/19/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include debug_public.inc
include frameloop_vars.inc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    VarSave   dq ?
	SaveRbx   dq ?
	SaveRsi   dq ?
	SaveRdi   dq ?
	SaveR12   dq ?
	SaveR13   dq ?
    SaveR14   dq ?
SAVEFRAME ends

FRAMELOOP_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
FRAMELOOP_INIT_LOCALS ends

FRAMELOOP_INTERNAL_STRUCT struct
   LoopItteration     dq ?
   CurrentIndex       dq ?
   LastFrame          dq ?
   FrameLoopCBListPtr dq ?
FRAMELOOP_INTERNAL_STRUCT ends

extern LocalFree:proc
extern LocalAlloc:proc

public FrameLoop_Create
public FrameLoop_PerformFrame
public FrameLoop_Free
public FrameLoop_Reset

.CODE


;*********************************************************
;   FrameLoop_Create
;
;        Parameters: Frame Loop Callback List Pointer
;
;        Return Value: FrameLoop Handle
;
;
;*********************************************************  
NESTED_ENTRY FrameLoop_Create, _TEXT$00
  alloc_stack(SIZEOF FRAMELOOP_INIT_LOCALS)
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  MOV FRAMELOOP_INIT_LOCALS.SaveRegsFrame.VarSave[RSP], RCX
  MOV RDX, SIZE FRAMELOOP_INTERNAL_STRUCT
  MOV RCX, 040h ; LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  TEST RAX, RAX
  JZ @FailedToAllocateInternalFrameLoop

  MOV RCX, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.VarSave[RSP]
  MOV FRAMELOOP_INTERNAL_STRUCT.FrameLoopCBListPtr[RAX], RCX
  
@FailedToAllocateInternalFrameLoop:
  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  RET

NESTED_END FrameLoop_Create, _TEXT$00

;*********************************************************
;   FrameLoop_Reset
;
;        Parameters: FrameLoop Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY FrameLoop_Reset, _TEXT$00
  alloc_stack(SIZEOF FRAMELOOP_INIT_LOCALS)
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  MOV FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RCX], 0
  MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RCX], 0
  MOV FRAMELOOP_INTERNAL_STRUCT.LastFrame[RCX], 0

  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  RET

NESTED_END FrameLoop_Reset, _TEXT$00


;*********************************************************
;   FrameLoop_Free
;
;        Parameters: FrameLoop Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY FrameLoop_Free, _TEXT$00
  alloc_stack(SIZEOF FRAMELOOP_INIT_LOCALS)
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  DEBUG_FUNCTION_CALL LocalFree

  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  RET

NESTED_END FrameLoop_Free, _TEXT$00


;*********************************************************
;   FrameLoop_Free
;
;        Parameters: FrameLoop Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY FrameLoop_PerformFrame, _TEXT$00
  alloc_stack(SIZEOF FRAMELOOP_INIT_LOCALS)
  save_reg rdi, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rbx, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRbx
  save_reg rsi, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r12, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR12
  save_reg r13, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR13
  save_reg r14, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR14 

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 
  MOV RDI, FRAMELOOP_INTERNAL_STRUCT.FrameLoopCBListPtr[RCX]
  MOV RSI, RCX 
  XOR RBX, RBX

  MOV R12, FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI]
  MOV RAX, SIZEOF FRAMELOOP_ENTRY_CB
  MUL R12
  ADD RDI, RAX
  
  MOV R13, FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RSI]

@PerformFrameLoop:

  TEST FRAMELOOP_ENTRY_CB.Flags[RDI], STOP_FRAME_SERIES
  JNZ @SkipFunctionCheck

@StartFunctionCheck:
  CMP FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RDI], 0
  JE @NoMoreFrames

@SkipFunctionCheck:    
  TEST FRAMELOOP_ENTRY_CB.Flags[RDI], ABSOLUTE_FRAME
  JNZ @HandleAbsFrames

@HandleRelFrames:
   MOV RDX, R13
   MOV RCX, FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI]
   SUB RDX, RCX

   CMP FRAMELOOP_ENTRY_CB.StartFrame[RDI], RDX
   JA @LoopComplete

   CMP FRAMELOOP_ENTRY_CB.EndFrame[RDI], RDX
   JB @GoToNextFrame

  TEST FRAMELOOP_ENTRY_CB.Flags[RDI], STOP_FRAME_SERIES
  JZ @PerformTheCallbackRel

     INC R12
     MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI], R12
     MOV FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI], R13
     JMP @LoopComplete

@PerformTheCallbackRel:
   ;
   ; Perform the callback
   ;
   MOV RCX, FRAMELOOP_ENTRY_CB.Context[RDI] 
   DEBUG_FUNCTION_CALL FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RDI]  

   JMP @GoToNextFrame_SaveOld

@HandleAbsFrames:
   CMP FRAMELOOP_ENTRY_CB.StartFrame[RDI], R13
   JA @LoopComplete

   CMP R13, FRAMELOOP_ENTRY_CB.EndFrame[RDI]
   JA @GoToNextFrame

  TEST FRAMELOOP_ENTRY_CB.Flags[RDI], STOP_FRAME_SERIES
  JZ @PerformTheCallbackAbs

     INC R12
     MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI], R12
     MOV FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI], R13
     JMP @LoopComplete
@PerformTheCallbackAbs:
   ;
   ; Perform the callback
   ;
   MOV RDX, FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RSI]
   MOV RCX, FRAMELOOP_ENTRY_CB.Context[RSI] 
   DEBUG_FUNCTION_CALL FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RSI]
   
@GoToNextFrame_SaveOld:
  INC RBX	
  INC R12
  ADD RDI, SIZEOF FRAMELOOP_ENTRY_CB
  JMP  @PerformFrameLoop

@GoToNextFrame:
  INC R12
  MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI], R12
  MOV FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI], R13
  ADD RDI, SIZEOF FRAMELOOP_ENTRY_CB
  JMP  @PerformFrameLoop
  
@LoopComplete:

  INC FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RSI]

  MOV RSI, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV RDI, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV rbx, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRbx[RSP]
  MOV r12, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  MOV r13, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
  MOV r14, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR14[RSP]
  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  MOV RAX, 1
  RET

@NoMoreFrames:
  MOV RSI, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV RDI, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV rbx, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveRbx[RSP]
  MOV r12, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  MOV r13, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
  MOV r14, FRAMELOOP_INIT_LOCALS.SaveRegsFrame.SaveR14[RSP]
  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  XOR RAX, RAX
  RET

NESTED_END FrameLoop_PerformFrame, _TEXT$00

END

