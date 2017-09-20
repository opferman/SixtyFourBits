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
    VarSave        dq ?
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
  CMP FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RDI], 0
  JE @LoopComplete
    
  CMP FRAMELOOP_ENTRY_CB.Flags[RDI], ABSOLUTE_FRAME
  JE @HandleAbsFrames

@HandleRelFrames:
   MOV RDX, R13
   MOV RCX, FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI]
   SUB RDX, RCX

   CMP FRAMELOOP_ENTRY_CB.StartFrame[RDI], RDX
   JB @LoopComplete

   CMP FRAMELOOP_ENTRY_CB.EndFrame[RDI], RDX
   JA @GoToNextFrame

   ;
   ; Perform the callback
   ;
   MOV RCX, FRAMELOOP_ENTRY_CB.Context[RSI] 
   DEBUG_FUNCTION_CALL FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RSI]  

   JMP @GoToNextFrame_SaveOld

@HandleAbsFrames:
   CMP FRAMELOOP_ENTRY_CB.StartFrame[RDI], R13
   JB @LoopComplete

   CMP FRAMELOOP_ENTRY_CB.EndFrame[RDI], R13
   JA @GoToNextFrame
   ;
   ; Perform the callback
   ;
   MOV RDX, FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RSI]
   MOV RCX, FRAMELOOP_ENTRY_CB.Context[RSI] 
   DEBUG_FUNCTION_CALL FRAMELOOP_ENTRY_CB.FrameLoopCallBack[RSI]

@GoToNextFrame_SaveOld:
  INC RBX
  MOV RAX, SIZEOF FRAMELOOP_ENTRY_CB
  ADD RDI, RAX
  JMP  @PerformFrameLoop

@GoToNextFrame:
  INC R12
  CMP RBX, 0
  JNE @SkipUPdatingStructIndexFrame
  MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI], R12
  MOV FRAMELOOP_INTERNAL_STRUCT.LastFrame[RSI], R13
@SkipUPdatingStructIndexFrame:
  MOV RAX, SIZEOF FRAMELOOP_ENTRY_CB
  ADD RDI, RAX
  JMP  @PerformFrameLoop
  
@LoopComplete:
  CMP RBX, 0
  JNE @SkipUPdatingStructIndex
  MOV FRAMELOOP_INTERNAL_STRUCT.CurrentIndex[RSI], R12
@SkipUPdatingStructIndex:
  INC FRAMELOOP_INTERNAL_STRUCT.LoopItteration[RSI]

  ADD RSP, SIZE FRAMELOOP_INIT_LOCALS
  RET

NESTED_END FrameLoop_PerformFrame, _TEXT$00

END

