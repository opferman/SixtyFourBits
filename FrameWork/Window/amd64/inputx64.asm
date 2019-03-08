;*********************************************************
; Input Code
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/7/2019
;
;*********************************************************



;*********************************************************
; Window Library Interfaces
;*********************************************************
public Inputx64_HandleKeyPress
public Inputx64_HandleKeyRelease


;*********************************************************
; Public Interfaces
;*********************************************************
public Inputx64_RegisterKeyPress
public Inputx64_RegisterKeyRelease

;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64.inc
include init_vars.inc
include debug_public.inc

;*********************************************************
; Assembly Options
;*********************************************************
;option casemap :none


PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEREGS struct
    SaveRdi        dq ?
SAVEREGS ends

LOOP_STACK_FRAME struct
    ParamFrameStruct   PARAMFRAME  <?>
    Param5         dq ?
    Param6         dq ?
    Message        MSG  <?>
LOOP_STACK_FRAME ends

WINPROG_STACK_FRAME struct
    ParamFrameStruct   PARAMFRAME  <?>
    Param5         dq ?
    SaveParam1     dq ?
    SaveParam2     dq ?
    SaveParam3     dq ?
    SaveParam4     dq ?
WINPROG_STACK_FRAME ends

W_SETUP_PARAMS struct
    ParamFrameStruct     PARAMFRAME  <?>
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
    Param8         dq ?
    Param9         dq ?
    Param10        dq ?
    Param11        dq ?
    Param12        dq ?
    WinRect        RECT <?>
    WndClassStruct WNDCLASSEX <?>
    SaveRegsStruct       SAVEREGS <?>
W_SETUP_PARAMS ends

INPUT_HANDLER struct
   Handler dq  ?
INPUT_HANDLER  ends

MAX_KEYS EQU <256>

.DATA
  KeyPressArray    INPUT_HANDLER MAX_KEYS DUP(<0>)
  KeyReleaseArray INPUT_HANDLER MAX_KEYS DUP(<0>)



.CODE

;*********************************************************
;  Inputx64_RegisterKeyPress
;
;        Parameters: Key, Handler
;
;        Return Value: TRUE/FALSE if hooked
;
;
;*********************************************************

NESTED_ENTRY Inputx64_RegisterKeyPress, _TEXT$00
 alloc_stack(SIZEOF W_SETUP_PARAMS)
 save_reg rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi
.ENDPROLOG 
  AND RCX, 0FFh
  SHL RCX, 3
  MOV RDI, OFFSET KeyPressArray
  ADD RDI, RCX
  XOR EAX, EAX
  CMP QWORD PTR [RDI], 0
  JNE @HandlerExists
  MOV QWORD PTR [RDI], RDX
  MOV EAX, 1
@HandlerExists:
  MOV rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi[RSP]
  ADD RSP, SIZE W_SETUP_PARAMS
  RET

NESTED_END Inputx64_RegisterKeyPress, _TEXT$00

;*********************************************************
;  Inputx64_RegisterKeyRelease
;
;        Parameters: Key, Handler
;
;        Return Value: TRUE/FALSE if hooked
;
;
;*********************************************************

NESTED_ENTRY Inputx64_RegisterKeyRelease, _TEXT$00
 alloc_stack(SIZEOF W_SETUP_PARAMS)
 save_reg rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi
.ENDPROLOG 
  AND RCX, 0FFh
  SHL RCX, 3
  MOV RDI, OFFSET KeyReleaseArray
  ADD RDI, RCX
  XOR RAX, RAX
  CMP QWORD PTR [RDI], 0
  JNE @HandlerExists
  MOV QWORD PTR [RDI], RDX
  MOV EAX, 1
@HandlerExists:
  MOV rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi[RSP]
  ADD RSP, SIZE W_SETUP_PARAMS
  RET

NESTED_END Inputx64_RegisterKeyRelease, _TEXT$00


;*********************************************************
;  Inputx64_HandleKeyPress
;
;        Parameters: Key
;
;        Return Value: TRUE/FALSE if handled
;
;
;*********************************************************

NESTED_ENTRY Inputx64_HandleKeyPress, _TEXT$00
 alloc_stack(SIZEOF W_SETUP_PARAMS)
 save_reg rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi
.ENDPROLOG 
  AND RCX, 0FFh
  SHL RCX, 3
  MOV RDI, OFFSET KeyPressArray
  ADD RDI, RCX
  XOR EAX, EAX
  CMP QWORD PTR [RDI], 0
  JE @NoHandler
  CALL QWORD PTR [RDI]
  MOV EAX, 1
@NoHandler:
  MOV rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi[RSP]
  ADD RSP, SIZE W_SETUP_PARAMS
  RET

NESTED_END Inputx64_HandleKeyPress, _TEXT$00


;*********************************************************
;  Inputx64_HandleKeyRelease
;
;        Parameters: Key
;
;        Return Value: TRUE/FALSE if handled
;
;
;*********************************************************

NESTED_ENTRY Inputx64_HandleKeyRelease, _TEXT$00
 alloc_stack(SIZEOF W_SETUP_PARAMS)
 save_reg rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi
.ENDPROLOG 
  AND RCX, 0FFh
  SHL RCX, 3
  MOV RDI, OFFSET KeyReleaseArray
  ADD RDI, RCX
  XOR EAX, EAX
  CMP QWORD PTR [RDI], 0
  JE @NoHandler
  CALL QWORD PTR [RDI]
  MOV EAX, 1
@NoHandler:
  MOV rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi[RSP]
  ADD RSP, SIZE W_SETUP_PARAMS
  RET

NESTED_END Inputx64_HandleKeyRelease, _TEXT$00



END