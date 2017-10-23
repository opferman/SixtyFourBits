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

;
;
; Frame Loop Rules:
;
;  Last Frame should have no flags and a NULL function pointer.
;  StartFrame of subsequent frames must be >= current frame. It cannot be > current frame.
;  Frame ranges must all terminate at the same location, frame following that occur must also have the same end frame.
;  Every series of frames that is > 1 must be followed by a frame with a NULL function pointer and the STOP_FRAME_SERIES flag of the same end time.
;  This will reset the relative Counter approproately.
;   
;  This is good, it contains all invdividual times.
;  FrameLoopList   FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 300, 300>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 10, 10>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 3, 3>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 2, 2>
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 45, 45>
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
;                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker
;
;  This is good, it contains all invdividual times but has some ranges.  
;  FrameLoopList   FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 300, 300>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 10, 10>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 3, 3>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 2, 25>   
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 45, 45>  ; This is OK because 45 > 25 but note it will be 45 frames after the previous instance and only 45-25.
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
;                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker
;  This is bad, it contains all invdividual times but has some ranges that overlap.
;  FrameLoopList   FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 300, 300>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 10, 10>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 3, 3>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 2, 25>   
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PRE;VIOUS_FRAME, 0, 0>  
;                              This is bad because it it less than 25. You need to add:
;							              FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 25, 25>
;										  after the 2, 25 range for this to work.  It will stop at 25 and start over.  If you wanted it to really be at 0 before 2,25 you would have to move it there.
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
;                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker
;
; This is good beacuse it uses a stop frame to stop a series and all of the frames following the >1 range have the same end time.
;  FrameLoopList   FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 300, 300>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 10, 10>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 3, 3>
;                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 2, 25>   
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PRE;VIOUS_FRAME, 25, 25>  
;   	           FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 25, 25>
;                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
;                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker