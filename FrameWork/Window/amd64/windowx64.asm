;*********************************************************
; Windows Code
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/24/2010-2017
;
;*********************************************************



;*********************************************************
; Public Interfaces
;*********************************************************
public Windowx64_Setup
public Windowx64_Loop

;*********************************************************
; Key Interfaces
;*********************************************************
extern Inputx64_HandleKeyPress:proc
extern Inputx64_HandleKeyRelease:proc

;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64.inc
include init_vars.inc
include debug_public.inc
include paramhelp_public.inc

WM_TIMER EQU <0113h>
TIMER_EMULATE_VRTRACE EQU <1>

extern AdjustWindowRectEx:proc
extern ValidateRect:proc
extern SetTimer:proc
extern DwmFlush:proc

HKEY_LOCAL_MACHINE EQU <080000002h>
KEY_READ EQU <020019h>
extern RegOpenKeyExA:proc
extern RegCloseKey:proc
extern RegQueryValueExA:proc
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

FRAME_DELAY_VALUE  EQU <10>

.DATA
 pszWindowClass  dq ?
 pszWindowTitle  dq ?
 FullScreenMode  dq ?
 EmulateVRTrace  dq ?
 EscapeDisabled  dq ?
 StartValue      dq 0
 CpuMhz                      dq 0
 RegistryCpuKey              db "HARDWARE\DESCRIPTION\System\CentralProcessor\0", 0
 RegistryMhzValue            db "~MHz", 0
.CODE

;*********************************************************
;  Windowx64_Setup
;
;        Parameters: InitializationContext
;
;        Return Value: Window Handle
;
;
;*********************************************************

NESTED_ENTRY Windowx64_Setup, _TEXT$00
 alloc_stack(SIZEOF W_SETUP_PARAMS)
 save_reg rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi
.ENDPROLOG 
  MOV [EmulateVRTrace], 0
  MOV RDI, RCX

  MOV RCX, INIT_DEMO_STRUCT.DisableEscapeExit[RdI]
  MOV [EscapeDisabled], RCX

  MOV RCX, INIT_DEMO_STRUCT.pszWindowClass[RdI]
  MOV [pszWindowClass], RCX

  MOV RDX, INIT_DEMO_STRUCT.pszWindowTitle[RdI]
  MOV [pszWindowTitle], RDX

  MOV R8, INIT_DEMO_STRUCT.FullScreen[RdI]
  MOV [FullScreenMode], R8

  MOV R8, RDI
  LEA RDI, W_SETUP_PARAMS.ParamFrameStruct[RSP]
  MOV RCX, (SIZE W_SETUP_PARAMS - SIZE SAVEREGS) / 8
  XOR RAX, RAX
  REP STOSQ
  MOV RDI, R8

  
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL GetModuleHandleA
  
  MOV W_SETUP_PARAMS.WndClassStruct.hInstance[RSP], RAX
  MOV RAX, OFFSET Windowx64_WinProc
  MOV W_SETUP_PARAMS.WndClassStruct.lpfnWndProc[RSP],  RAX
  MOV RAX, [pszWindowClass]
  MOV W_SETUP_PARAMS.WndClassStruct.lpszClassName[RSP],  RAX
  MOV W_SETUP_PARAMS.WndClassStruct.cbSize[RSP], SIZE WNDCLASSEX
 
  MOV RCX, BLACK_BRUSH
  DEBUG_FUNCTION_CALL GetStockObject                   
 
  MOV W_SETUP_PARAMS.WndClassStruct.hbrBackground[RSP], RAX
; ***************
 
  LEA RCX, W_SETUP_PARAMS.WndClassStruct[RSP]
  DEBUG_FUNCTION_CALL RegisterClassExA   

  MOV W_SETUP_PARAMS.WinRect.left[RSP], 0
  MOV W_SETUP_PARAMS.WinRect.top[RSP], 0

  MOV RCX, INIT_DEMO_STRUCT.ScreenWidth[RDI]
  MOV W_SETUP_PARAMS.WinRect.right[RSP], ECX

  MOV RCX, INIT_DEMO_STRUCT.ScreenHeight[RDI]
  MOV W_SETUP_PARAMS.WinRect.bottom[RSP], ECX
  
  MOV R9, 8 ; WS_EX_TOPMOST  
  XOR R8, R8
  MOV RDX, WS_CAPTION

  LEA RCX,  W_SETUP_PARAMS.WinRect[RSP]
  DEBUG_FUNCTION_CALL AdjustWindowRectEx

    
  MOV RAX, W_SETUP_PARAMS.WndClassStruct.hInstance[RSP]
  MOV W_SETUP_PARAMS.Param11[RSP], RAX

  MOV ECX, W_SETUP_PARAMS.WinRect.right[RSP]
  SUB ECX, W_SETUP_PARAMS.WinRect.left[RSP]
  MOV W_SETUP_PARAMS.Param7[RSP], RCX

  MOV ECX, W_SETUP_PARAMS.WinRect.bottom[RSP]
  SUB ECX, W_SETUP_PARAMS.WinRect.top[RSP]
  MOV W_SETUP_PARAMS.Param8[RSP], RCX

  MOV W_SETUP_PARAMS.Param5[RSP], 0
  MOV W_SETUP_PARAMS.Param6[RSP], 0
  
  MOV R8, [FullScreenMode]
  TEST R8, R8
  JZ @WindowedMode
  MOV R9, WS_POPUP
  JMP @SkipToMyLoo
@WindowedMode:
   MOV R9, WS_CAPTION

@SkipToMyLoo:
  MOV R8, pszWindowTitle
  ; ***************
  
  MOV RDX, [pszWindowClass]
  MOV RCX, 8 ; WS_EX_TOPMOST  
  DEBUG_FUNCTION_CALL CreateWindowExA

  TEST EAX, EAX
  JZ @FailedToCreateWindow

  CMP INIT_DEMO_STRUCT.EmulateVRTrace[RdI], 0
  JE @SkipVRTraceEmulate
  MOV [EmulateVRTrace], 1
  MOV RDI, RAX

  DEBUG_FUNCTION_CALL Windowx64_ReadCpuMhz
;  XOR R9, R9
;  MOV R8, INIT_DEMO_STRUCT.EmulateVRTrace[RdI]
;  MOV RDX, TIMER_EMULATE_VRTRACE
;  MOV RCX, RAX
;  DEBUG_FUNCTION_CALL SetTimer

  MOV RAX, RDI

@SkipVRTraceEmulate:
@FailedToCreateWindow:
  MOV rdi, W_SETUP_PARAMS.SaveRegsStruct.SaveRdi[RSP]
  ADD RSP, SIZE W_SETUP_PARAMS
  RET

NESTED_END Windowx64_Setup, _TEXT$00



;*********************************************************
;  Windowx64_Loop
;
;        Parameters: None
;
;        Return Value: 0 = Continue, 1 = Exit
;
;
;*********************************************************
NESTED_ENTRY Windowx64_Loop, _TEXT$00
   alloc_stack(SIZEOF LOOP_STACK_FRAME)
.ENDPROLOG 
   CMP [EmulateVRTrace], 0
   JE @Windowx64_MessageLoop
   
;   CMP [StartValue], 0
;   JNE @Windowx64_MessageLoop
;   DEBUG_FUNCTION_CALL Windowx64_StartTimerValue
;   MOV [StartValue], RAX
   
@Windowx64_MessageLoop:

        MOV LOOP_STACK_FRAME.Param5[RSP], PM_REMOVE
        XOR RDX, RDX
        XOR R8, R8
        XOR R9, R9
        LEA RCX, LOOP_STACK_FRAME.Message[RSP]
        DEBUG_FUNCTION_CALL PeekMessageA
  
        TEST RAX, RAX
        JNZ SHORT @Windowx64_DeliverMessage

	CMP [EmulateVRTrace], 0
	JE @Windowx64_EngineDrawFrame
        
        DEBUG_FUNCTION_CALL DwmFlush 
;        MOV RCX, [StartValue]
;        DEBUG_FUNCTION_CALL Windowx64_GetElapsedMs
;        CMP RAX, FRAME_DELAY_VALUE
;        JB @Windowx64_MessageLoop

        DEBUG_FUNCTION_CALL Windowx64_StartTimerValue
        MOV [StartValue], RAX
 @Windowx64_EngineDrawFrame:        
        ADD RSP, SIZEOF LOOP_STACK_FRAME
        XOR RAX, RAX
        RET

@Windowx64_DeliverMessage:

  CMP LOOP_STACK_FRAME.Message.message[RSP], WM_QUIT
  JE SHORT @Windowx64_ReturnExitCode

;  CMP [EmulateVRTrace], 0
;  JE @SkipEmulateVRTrace

;  CMP LOOP_STACK_FRAME.Message.message[RSP], WM_TIMER
;  JNE SHORT @SkipEmulateVRTrace

;  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
;  DEBUG_FUNCTION_CALL TranslateMessage
  
;  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
;  CALL DispatchMessageA
;  JMP @Windowx64_EngineDrawFrame

@SkipEmulateVRTrace:
  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
  DEBUG_FUNCTION_CALL TranslateMessage
  
  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
  DEBUG_FUNCTION_CALL DispatchMessageA
                
  JMP @Windowx64_MessageLoop
    
@Windowx64_ReturnExitCode:
  ADD RSP, SIZEOF LOOP_STACK_FRAME
  MOV EAX, 1
  RET   
  
NESTED_END Windowx64_Loop, _TEXT$00

;*********************************************************
; Windowx64_WinProc
;   
;   The Window Procedure
;   
;
;*********************************************************
NESTED_ENTRY Windowx64_WinProc, _TEXT$00
  alloc_stack(SIZEOF WINPROG_STACK_FRAME)
.ENDPROLOG 

  CMP EDX, WM_CREATE
  JE @Windowx64_HandleCreate

  CMP EDX, WM_KEYDOWN
  JE @Windowx64_HandleKeyDown

  CMP EDX, WM_KEYUP
  JE @Windowx64_HandleKeyUp
  
  CMP EDX, WM_DESTROY
  JE @Windowx64_HandleDestroy

  CMP EDX, WM_CLOSE
  JE @Windowx64_HandleClose

  CMP EDX, WM_PAINT
  JNE @Window_DefaultWindow

  MOV WINPROG_STACK_FRAME.SaveParam1[RSP], RCX
  MOV WINPROG_STACK_FRAME.SaveParam2[RSP], RDX
  MOV WINPROG_STACK_FRAME.SaveParam3[RSP], R8
  MOV WINPROG_STACK_FRAME.SaveParam4[RSP], R9

  XOR RDX, RDX
  DEBUG_FUNCTION_CALL ValidateRect 

  MOV RCX, WINPROG_STACK_FRAME.SaveParam1[RSP]
  MOV RDX, WINPROG_STACK_FRAME.SaveParam2[RSP]
  MOV R8, WINPROG_STACK_FRAME.SaveParam3[RSP]
  MOV R9, WINPROG_STACK_FRAME.SaveParam4[RSP]

@Window_DefaultWindow:
  DEBUG_FUNCTION_CALL DefWindowProcA
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET

@Windowx64_HandleCreate:
  XOR RAX, RAX
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET

@Windowx64_HandleKeyDown:

  MOV WINPROG_STACK_FRAME.SaveParam1[RSP], RCX
  MOV WINPROG_STACK_FRAME.SaveParam2[RSP], RDX
  MOV WINPROG_STACK_FRAME.SaveParam3[RSP], R8
  MOV WINPROG_STACK_FRAME.SaveParam4[RSP], R9

  MOV RCX, R8
  DEBUG_FUNCTION_CALL Inputx64_HandleKeyPress

  MOV RCX, WINPROG_STACK_FRAME.SaveParam1[RSP]
  MOV RDX, WINPROG_STACK_FRAME.SaveParam2[RSP]
  MOV R8, WINPROG_STACK_FRAME.SaveParam3[RSP]
  MOV R9, WINPROG_STACK_FRAME.SaveParam4[RSP]
  JMP @Window_DefaultWindow

@Windowx64_HandleKeyUp:
  MOV WINPROG_STACK_FRAME.SaveParam1[RSP], RCX
  MOV WINPROG_STACK_FRAME.SaveParam2[RSP], RDX
  MOV WINPROG_STACK_FRAME.SaveParam3[RSP], R8
  MOV WINPROG_STACK_FRAME.SaveParam4[RSP], R9
  MOV RCX, R8
  DEBUG_FUNCTION_CALL Inputx64_HandleKeyRelease

  MOV RCX, WINPROG_STACK_FRAME.SaveParam1[RSP]
  MOV RDX, WINPROG_STACK_FRAME.SaveParam2[RSP]
  MOV R8, WINPROG_STACK_FRAME.SaveParam3[RSP]
  MOV R9, WINPROG_STACK_FRAME.SaveParam4[RSP]
  
  CMP [EscapeDisabled], 0
  JNE @Window_DefaultWindow

  CMP R8D, VK_ESCAPE
  JNE @Window_DefaultWindow

  DEBUG_FUNCTION_CALL DestroyWindow
  
  XOR RAX, RAX
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET
  
 
@Windowx64_HandleDestroy:
@Windowx64_HandleClose:

  MOV ECX, 1
  DEBUG_FUNCTION_CALL ShowCursor
  
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL PostQuitMessage
  
  XOR RAX, RAX  
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET

NESTED_END Windowx64_WinProc, _TEXT$00




;*********************************************************
;  Windowx64_ReadCpuMhz
;     
;        Parameters: None
;
;        Return: None
;
;
;*********************************************************  
NESTED_ENTRY Windowx64_ReadCpuMhz, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_LV)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_LV
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  ;
  ; Default CPU MHz to 2GHz if we cannot open the key or query the value
  ;
  MOV [CpuMhz], 2000
  LEA R8, STD_FUNCTION_STACK_LV.LocalVariables.LocalVar1[RSP]
  MOV STD_FUNCTION_STACK_LV.Parameters.Param5[RSP], R8
  MOV R9, KEY_READ 
  XOR R8, R8
  MOV RDX, OFFSET RegistryCpuKey
  MOV RCX, HKEY_LOCAL_MACHINE
  DEBUG_FUNCTION_CALL RegOpenKeyExA 
  CMP RAX, 0
  JNE @OpenKeyFailed

  MOV STD_FUNCTION_STACK_LV.LocalVariables.LocalVar2[RSP], 4
  LEA RAX, STD_FUNCTION_STACK_LV.LocalVariables.LocalVar2[RSP]
  MOV STD_FUNCTION_STACK_LV.Parameters.Param6[RSP], RAX
  MOV RAX, OFFSET CpuMhz
  MOV STD_FUNCTION_STACK_LV.Parameters.Param5[RSP], RAX
  XOR R9, R9 
  XOR R8, R8
  MOV RDX, OFFSET RegistryMhzValue
  MOV RCX, STD_FUNCTION_STACK_LV.LocalVariables.LocalVar1[RSP]
  DEBUG_FUNCTION_CALL RegQueryValueExA
  ;
  ;  Don't care about success or failure, we have to close the handle anyway.
  ;

  MOV RCX, STD_FUNCTION_STACK_LV.LocalVariables.LocalVar1[RSP]
  DEBUG_FUNCTION_CALL RegCloseKey


@OpenKeyFailed:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_LV
  ADD RSP, SIZE STD_FUNCTION_STACK_LV
  RET
NESTED_END Windowx64_ReadCpuMhz, _TEXT$00


;*********************************************************
;  Windowx64_StartTimerValue
;     
;        Parameters: None
;
;        Return: Start Value
;
;
;*********************************************************  
NESTED_ENTRY Windowx64_StartTimerValue, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  RDTSC
  SHL RDX, 32
  OR RAX, RDX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Windowx64_StartTimerValue, _TEXT$00


;*********************************************************
;  Windowx64_GetElapsedMs
;     
;        Parameters: Start Value
;
;        Return: Milliseconds
;
;
;*********************************************************  
NESTED_ENTRY Windowx64_GetElapsedMs, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  RDTSC
  SHL RDX, 32
  OR RAX, RDX

  SUB RAX, RCX

  XOR RDX, RDX
  DIV [CpuMhz]
  ; RAX is now microseconds (us)
  XOR RDX, RDX
  MOV RCX, 1000
  DIV RCX
  ; RAX should now be milliseconds (ms)

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Windowx64_GetElapsedMs, _TEXT$00



END