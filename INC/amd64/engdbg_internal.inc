;
; Toby Opferman
;   Engine / Framework Debug Functions
;

;
; Set "ENGINE_DEBUG_IS_ENABLED" to 1 to enable debug build or 0 to disable
;
ENGINE_DEBUG_IS_ENABLED EQU <0>

;
; Ensure RSP is aligned
;
IF ENGINE_DEBUG_IS_ENABLED 
ENGINE_DEBUG_RSP_CHECK_MACRO MACRO
   LOCAL TestRspComplete
   TEST RSP, 0Fh
   JZ TestRspComplete
   INT 3
TestRspComplete:
ENDM
ELSE
ENGINE_DEBUG_RSP_CHECK_MACRO MACRO
ENDM
ENDIF



;
; Debug Enabled Function Calls
;
IF ENGINE_DEBUG_IS_ENABLED 
ENGINE_DEBUG_FUNCTION_CALL MACRO FunctionName
   CALL Engine_PreFunctionCall
   CALL FunctionName
   CALL Engine_PostFunctionCall
ENDM
ELSE
ENGINE_DEBUG_FUNCTION_CALL MACRO FunctionName
   CALL FunctionName
ENDM
ENDIF


