; Toby Opferman
;
;
; Frameloop Strcutures

RELATIVE_FROM_PREVIOUS_FRAME  EQU <0>
ABSOLUTE_FRAME                EQU <1>
STOP_FRAME_SERIES             EQU <2>

FRAMELOOP_ENTRY_CB struct
   FrameLoopCallBack dq ?   ; (Context, FrameNumber (Absolute or Relative)
   Context           dq ?
   Flags             dq ?
   StartFrame        dq ?
   EndFrame          dq ?
FRAMELOOP_ENTRY_CB ends