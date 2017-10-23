;
; Toby Opferman
;   Debug Functions
;

;
; Set "DEBUG_IS_ENABLED" to 1 to enable debug build or 0 to disable
;
DEBUG_IS_ENABLED EQU <0>

;
; Ensure RSP is aligned
;
IF DEBUG_IS_ENABLED 
DEBUG_RSP_CHECK_MACRO MACRO
   LOCAL TestRspComplete
   TEST RSP, 0Fh
   JZ TestRspComplete
   INT 3
TestRspComplete:
ENDM
ELSE
DEBUG_RSP_CHECK_MACRO MACRO
ENDM
ENDIF

extern Engine_PreFunctionCall:proc
extern Engine_PostFunctionCall: proc

;
; Debug Enabled Function Calls
;
IF DEBUG_IS_ENABLED 
DEBUG_FUNCTION_CALL MACRO FunctionName
   CALL Engine_PreFunctionCall
   CALL FunctionName
   CALL Engine_PostFunctionCall
ENDM
ELSE
DEBUG_FUNCTION_CALL MACRO FunctionName
   CALL FunctionName
ENDM
ENDIF


