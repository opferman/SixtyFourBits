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
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64.inc
include demovariables.inc
include init_vars.inc


extern AdjustWindowRectEx:proc
extern ValidateRect:proc

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

.DATA
 pszWindowClass  dq ?
 pszWindowTitle  dq ?
 FullScreenMode    dq ?

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

  MOV RDI, RCX
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
  CALL GetModuleHandleA
  
  MOV W_SETUP_PARAMS.WndClassStruct.hInstance[RSP], RAX
  MOV RAX, OFFSET Windowx64_WinProc
  MOV W_SETUP_PARAMS.WndClassStruct.lpfnWndProc[RSP],  RAX
  MOV RAX, [pszWindowClass]
  MOV W_SETUP_PARAMS.WndClassStruct.lpszClassName[RSP],  RAX
  MOV W_SETUP_PARAMS.WndClassStruct.cbSize[RSP], SIZE WNDCLASSEX
 
  MOV RCX, BLACK_BRUSH
  CALL GetStockObject                   
 
  MOV W_SETUP_PARAMS.WndClassStruct.hbrBackground[RSP], RAX
; ***************
 
  LEA RCX, W_SETUP_PARAMS.WndClassStruct[RSP]
  CALL RegisterClassExA   

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
  CALL AdjustWindowRectEx

    
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
  
  MOV RDI, [FullScreenMode]
  TEST RDI, RDI
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
  CALL CreateWindowExA

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

@Windowx64_MessageLoop:

        MOV LOOP_STACK_FRAME.Param5[RSP], PM_REMOVE
        XOR RDX, RDX
        XOR R8, R8
        XOR R9, R9
        LEA RCX, LOOP_STACK_FRAME.Message[RSP]
        CALL PeekMessageA
  
        TEST RAX, RAX
        JNZ SHORT @Windowx64_DeliverMessage
        
        ADD RSP, SIZEOF LOOP_STACK_FRAME
        XOR RAX, RAX
        RET

@Windowx64_DeliverMessage:

  CMP LOOP_STACK_FRAME.Message.message[RSP], WM_QUIT
  JE SHORT @Windowx64_ReturnExitCode
               

  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
  CALL TranslateMessage
  
  LEA RCX, LOOP_STACK_FRAME.Message[RSP]
  CALL DispatchMessageA
                
  JMP SHORT @Windowx64_MessageLoop
    
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
  CALL ValidateRect 

  MOV RCX, WINPROG_STACK_FRAME.SaveParam1[RSP]
  MOV RDX, WINPROG_STACK_FRAME.SaveParam2[RSP]
  MOV R8, WINPROG_STACK_FRAME.SaveParam3[RSP]
  MOV R9, WINPROG_STACK_FRAME.SaveParam4[RSP]

@Window_DefaultWindow:
  CALL DefWindowProcA
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET

@Windowx64_HandleCreate:
  XOR RAX, RAX
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET


@Windowx64_HandleKeyUp:
  
  CMP R8D, VK_ESCAPE
  JNE SHORT @Window_DefaultWindow

  CALL DestroyWindow
  
  XOR RAX, RAX
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET
  
 
@Windowx64_HandleDestroy:
@Windowx64_HandleClose:

  MOV ECX, 1
  CALL ShowCursor
  
  XOR RCX, RCX
  CALL PostQuitMessage
  
  XOR RAX, RAX  
  ADD RSP, SIZE WINPROG_STACK_FRAME
  RET

NESTED_END Windowx64_WinProc, _TEXT$00



END