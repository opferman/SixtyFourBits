;*********************************************************
; Initialization Library
;
;  Written in Assembly x64
; 
;  By Toby Opferman  4/26/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include windowsx64_public.inc
include engine.inc
include math_public.inc
include ddraw_internal.inc

;*********************************************************
; Structures
;*********************************************************
PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends


INIT_FRAME struct
   ParamFrameArea PARAMFRAME <?>
   hWnd           dq <?>
   DirectDrawCtx  dq ?
   EngineCtx      dq ?
   SaveRsi        dq ?
   SaveRdi        dq ?
INIT_FRAME ends

;
; Initialization of Demo Library
;
INIT_DEMO_STRUCT struct
      BitsPerPixel          dq ?
      ScreenWidth           dq ?
      ScreenHeight          dq ?
      pszWindowTitle        dq ?
      pszWindowClass        dq ?
      GlobalDemoStructure   dq ?
      FullScreen            dq ? 
INIT_DEMO_STRUCT ends


public Initialization_Demo
extern Engine_DebugInit:proc

.CODE
  
;*********************************************************
;  Initialization_Demo
;
;        Parameters: INIT_DEMO_STRUCT
;
;        
;
;
;*********************************************************  
NESTED_ENTRY Initialization_Demo, _TEXT$00
  alloc_stack(SIZEOF INIT_FRAME)
 save_reg rdi, INIT_FRAME.SaveRdi
 save_reg rsi, INIT_FRAME.SaveRsi
.ENDPROLOG 
  MOV RDI, RCX
  CALL Engine_DebugInit

  MOV RCX, RDI
  CALL Windowx64_Setup
  TEST RAX, RAX
  JZ @Init_Exit
  
  MOV INIT_FRAME.hWnd[RSP], RAX
  
  MOV RDX, SW_SHOWNORMAL
  MOV RCX, RAX
  CALL ShowWindow
  
  MOV RCX, INIT_FRAME.hWnd[RSP]
  CALL UpdateWindow

  MOV RCX, INIT_FRAME.hWnd[RSP]
  CALL SetFocus
  
  MOV RCX, INIT_DEMO_STRUCT.FullScreen[RdI]
  XOR RCX, 1
  CALL ShowCursor
  
  CALL Math_Init

  MOV RDX, RDI
  MOV RCX, INIT_FRAME.hWnd[RSP]
  CALL DDrawx64_Init
  
  TEST RAX, RAX
  JZ @Init_Exit
  
  MOV INIT_FRAME.DirectDrawCtx[RSP], RAX

  MOV RDX, INIT_DEMO_STRUCT.GlobalDemoStructure[RDI]
  MOV RCX, RAX
  CALL Engine_Init
  
  TEST RAX, RAX
  JZ @Init_ExitWithDirectXFree
  
  MOV INIT_FRAME.EngineCtx[RSP], RAX
      
@Init_MessageLoop:  
     
     MOV RCX, INIT_FRAME.EngineCtx[RSP]
     CALL Engine_Loop
	 CMP EAX, 0
	 JE @Init_ExitWithEngineFree
     
     CALL Windowx64_Loop
     TEST RAX, RAX
     JZ SHORT @Init_MessageLoop
          
@Init_ExitWithEngineFree: 
 MOV RCX, INIT_FRAME.EngineCtx[RSP]
 CALL Engine_Free
          
@Init_ExitWithDirectXFree:
 MOV RCX, INIT_FRAME.DirectDrawCtx[RSP]
 CALL DDrawx64_Free
 

@Init_Exit:
 MOV rdi, INIT_FRAME.SaveRdi[RSP]
 MOV rsi, INIT_FRAME.SaveRsi[RSP]
 ADD RSP, SIZEOF INIT_FRAME

 RET
  
NESTED_END Initialization_Demo, _TEXT$00



END
