;
; Parameter Helper Header File
;
;   Toby Opferman  2017
;
;


LOCAL_PARAMETER_FRAME8 struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
    Param8         dq ?
LOCAL_PARAMETER_FRAME8 ends

LOCAL_PARAMETER_FRAME4 struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
LOCAL_PARAMETER_FRAME4 ends

FUNCTION_PARAMETERS_FRAME struct
    ReturnAddress  dq ?
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
    Param8         dq ?
FUNCTION_PARAMETERS_FRAME ends

SAVE_REGISTERS_FRAME struct
    SaveR12  dq ?
	SaveR13  dq ?
	SaveR14  dq ?
	SaveR15  dq ?
	SaveRdi  dq ?
	SaveRsi  dq ?
	SaveRbx  dq ?
	SaveRbp  dq ?
SAVE_REGISTERS_FRAME ends

SAVE_REGISTERS_FRAME_XMM struct
    SaveXmm6  oword ?
	SaveXmm7  oword ?
	SaveXmm8  oword ?
	SaveXmm9  oword ?
	SaveXmm10 oword ?
	SaveXmm11 oword ?
	SaveXmm12 oword ?
	SaveXmm13 oword ?
	SaveXmm14 oword ?
    SaveXmm15 oword ?
SAVE_REGISTERS_FRAME_XMM ends

STD_FUNCTION_STACK struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
	SaveRegs    SAVE_REGISTERS_FRAME      <?>
	SaveXmmRegs SAVE_REGISTERS_FRAME_XMM  <?>
	Padding     dq                         ?
STD_FUNCTION_STACK ends

STD_FUNCTION_STACK_PARAMS struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
	SaveRegs    SAVE_REGISTERS_FRAME      <?>
	SaveXmmRegs SAVE_REGISTERS_FRAME_XMM  <?>
	Padding     dq                         ?
	FuncParams  FUNCTION_PARAMETERS_FRAME <?>
STD_FUNCTION_STACK_PARAMS ends

