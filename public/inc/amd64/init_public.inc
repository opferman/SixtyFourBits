;****************************************
;
; Initialization Library
;
;     Toby Opferman
;
;****************************************


include init_vars.inc


VR_RETRACE_DEFAULT_HARDWARE       EQU <0>  ; Best for full screen
VR_RETRACE_SYSTEM_MSG_TIMER       EQU <1>
VR_RETRACE_CPU_TIMESTAMP          EQU <2>
VR_RETRACE_DWM_SYNC               EQU <3>


extern Initialization_Demo:proc
