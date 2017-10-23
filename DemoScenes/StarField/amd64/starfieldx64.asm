;*********************************************************
; Starfield Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include vpal_public.inc
include font_public.inc
include soft3d_public.inc
include frameloop_public.inc
include dbuffer_public.inc

extern LocalAlloc:proc
extern LocalFree:proc


STAR_FIELD_ENTRY struct
   Location       TD_POINT <?>
   Velocity       mmword    ?  
   StarOnScreen   dq        ?
   Color          db        ?
STAR_FIELD_ENTRY ends


public StarDemo_Init
public StarDemo_Demo
public StarDemo_Free

extern time:proc
extern srand:proc
extern rand:proc

.DATA
  DoubleBuffer     dq ?
  VirtualPallete   dq ?
  FrameCountDown   dd 2800
  StarEntry        STAR_FIELD_ENTRY 1000 DUP(<>)
  Soft3D           dq ?
  TwoDPlot         TD_POINT_2D <?>
  WorldLocation    TD_POINT    <?>
  View_Distance    mmword   1024.0
  ConstantZero     mmword 0.0
  CurrentVelocity  dq 1
  CameraX          mmword 0.0
  CameraY          mmword 0.0
  CameraXVel       mmword -0.00872665
  CameraYVel       mmword -0.00872665
  ConstantNeg      mmword -1.0
  
  FrameLoopHandle dq ?


  FrameLoopList   FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 300, 300>
                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 10, 10>
                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 3, 3>
                  FRAMELOOP_ENTRY_CB <StarDemo_IncStarVelocity_CB, 0, RELATIVE_FROM_PREVIOUS_FRAME, 2, 2>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraYOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 5,  45>
                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 45, 45>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 45, 45>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraYOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 10,  90>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 90, 90>
                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraYVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraYOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 5,  45>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 45, 45>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraXOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 10,  50>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 50, 50>				  
                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraXVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraXOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 10,  90>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 90, 90>
                  FRAMELOOP_ENTRY_CB <StarDemo_DecCameraXVel_CB,   0, RELATIVE_FROM_PREVIOUS_FRAME, 1, 1>
                  FRAMELOOP_ENTRY_CB <StarDemo_SetCameraXOnly_CB,  0, RELATIVE_FROM_PREVIOUS_FRAME, 10,  50>
                  FRAMELOOP_ENTRY_CB <0,                           0, RELATIVE_FROM_PREVIOUS_FRAME or STOP_FRAME_SERIES, 50, 50>
                  FRAMELOOP_ENTRY_CB <0, 0, 0, 1, 1>  ; End Marker


.CODE

;*********************************************************
;   StarDemo_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_Init, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [VirtualPallete], 0
    
  MOV RDX, 1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @StarInit_Failed

  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @StarInit_Failed
  MOV [VirtualPallete], RAX
  

  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Soft3D_Init
  MOV [Soft3D], RAX
  TEST RAX, RAX
  JZ @StarInit_Failed


  LEA RCX, [WorldLocation]
  MOV TD_POINT.x[RCX], 0
  MOV TD_POINT.y[RCX], 0
  MOV TD_POINT.z[RCX], 0

  MOVSD xmm0, [View_Distance]
  MOVSD xmm1, xmm0
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_SetViewDistance

  XOR R12, R12

@PopulatePallete:
  MOV RAX, R12
  MOV AH, AL
  SHL RAX, 8
  MOV AL, AH

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  INC R12
  CMP R12, 256
  JB @PopulatePallete

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL StarDemo_CreateStars

  LEA RCX, [FrameLoopList]
  DEBUG_FUNCTION_CALL FrameLoop_Create
  MOV [FrameLoopHandle], RAX
  TEST RAX, RAX
  JZ @StarInit_Failed
    
  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  MOV EAX, 1
  RET

@StarInit_Failed:
  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  XOR EAX, EAX
  RET
NESTED_END StarDemo_Init, _TEXT$00



;*********************************************************
;  StarDemo_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_Demo, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14
 save_reg r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
 save_reg r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

  ;
  ; Update the screen with the buffer
  ;  

   MOV RCX, [DoubleBuffer]
   MOV RDX, [VirtualPallete]
   MOV R8, DB_FLAG_CLEAR_BUFFER

   CMP [FrameCountDown], 100
   JA @UpdateScreen
   XOR R8, R8
@UpdateScreen:
   DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL StarDemo_MoveStars

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL StarDemo_PlotStars

   MOV RCX, [FrameLoopHandle]
   DEBUG_FUNCTION_CALL FrameLoop_PerformFrame
   CMP RAX, 0
   JNE @SkipReset
   
   LEA RCX, [FrameLoopList]
   MOV FRAMELOOP_ENTRY_CB.EndFrame[RCX], 5
   MOV FRAMELOOP_ENTRY_CB.StartFrame[RCX], 5

   MOV RCX, [FrameLoopHandle]
   DEBUG_FUNCTION_CALL FrameLoop_Reset

@SkipReset:
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  MOV r14, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR14[RSP]
  MOV r15, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR15[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  MOV r13, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR13[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END StarDemo_Demo, _TEXT$00



;*********************************************************
;  StarDemo_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_Free, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
  save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  DEBUG_FUNCTION_CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_Free, _TEXT$00


;*********************************************************
;  StarDemo_CreateStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_CreateStars, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
  save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX
  LEA RDI, [StarEntry]
  XOR RSI, RSI

@Initialize_Stars:

  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RBX]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.x[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RBX]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.y[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  AND RAX, 0FFh
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm0

  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_ON_SCREEN

  DEBUG_FUNCTION_CALL Math_rand
  MOV STAR_FIELD_ENTRY.Color[RDI], AL

  DEBUG_FUNCTION_CALL Math_rand
  AND RAX, 3
  INC RAX
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Initialize_Stars
  
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]

  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_CreateStars, _TEXT$00



;*********************************************************
;  StarDemo_MoveStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_MoveStars, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  LEA RDI, [StarEntry]
  XOR RSI, RSI
  MOV R12, RCX
  
@Move_Stars:

  MOVSD xmm0, STAR_FIELD_ENTRY.Location.z[RDI]
  UCOMISD xmm0,  mmword ptr [ConstantZero]
  JG @CheckOffScreen
  JMP @CreateNewStar

@CheckOffScreen:
  CMP STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_OFF_SCREEN
  JE @CreateNewStar

  MOVSD xmm0, STAR_FIELD_ENTRY.Velocity[RDI]
  MOVSD xmm1, STAR_FIELD_ENTRY.Location.z[RDI]
  SUBSD xmm1, xmm0
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm1

  CMP STAR_FIELD_ENTRY.Color[RDI], 255
  JE @SkipIncrementColor

  INC STAR_FIELD_ENTRY.Color[RDI]
 @SkipIncrementColor:

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Move_Stars
  JMP @StarMoveComplete

@CreateNewStar:
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.x[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[R12]
  XOR RDX, RDX
  DIV RCX
  SHR RCX, 1
  SUB RDX, RCX
  
  cvtsi2sd xmm0, RDX
  MOVSD STAR_FIELD_ENTRY.Location.y[RDI], xmm0
  
  DEBUG_FUNCTION_CALL Math_rand
  AND RAX, 0FFh
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm0

  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_ON_SCREEN

  DEBUG_FUNCTION_CALL Math_rand
  MOV STAR_FIELD_ENTRY.Color[RDI], AL

  MOV RAX, [CurrentVelocity]
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0

  JMP  @SkipIncrementColor
@StarMoveComplete:
   
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_MoveStars, _TEXT$00

;*********************************************************
;  StarDemo_PlotStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_PlotStars, _TEXT$00
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  LEA RDI, [StarEntry]
  XOR RSI, RSI
  MOV R12, RCX
  
@Plot_Stars:
  MOV STD_FUNCTION_STACK_MIN.Parameters.Param5[RSP], 0
  LEA R9, [TwoDPlot]
  LEA R8, [WorldLocation]
  LEA RDX, STAR_FIELD_ENTRY.Location[RDI]
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_Convert3Dto2D
  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], RAX
  CMP RAX, SOFT3D_PIXEL_OFF_SCREEN
  JE @SkipPixelPlot
  
  MOV RBX, [DoubleBuffer]
  LEA R9, [TwoDPlot]

  MOV RCX, TD_POINT_2D.y[R9]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[R12]
  MUL RCX
  ADD RBX, RAX
  ADD RBX, TD_POINT_2D.x[R9]
  
  MOV AL, STAR_FIELD_ENTRY.Color[RDI]
  MOV [RBX], AL

 @SkipPixelPlot:
  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, 1000
  JB @Plot_Stars
  
  MOV rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_PlotStars, _TEXT$00

;*********************************************************
;  StarDemo_IncStarVelocity_CB
;
;        Parameters: Leaf function for updating Velocity
;
;       
;
;
;*********************************************************  
NESTED_ENTRY StarDemo_IncStarVelocity_CB, _TEXT$00
  .ENDPROLOG 
  CMP [CurrentVelocity], 5
  JAE @SkipUpdate
  INC [CurrentVelocity]
@SkipUpdate:
  RET
NESTED_END StarDemo_IncStarVelocity_CB, _TEXT$00


;*********************************************************
;  StarDemo_SetCameraYOnly_CB
;
;        Parameters: Set the Camera
;
;       
;
;
;*********************************************************    
NESTED_ENTRY StarDemo_SetCameraYOnly_CB, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
  .ENDPROLOG 
  MOVSD xmm1, [CameraX]

  MOVSD xmm0, [CameraYVel]
  MOVSD xmm2, [CameraY]
  ADDSD xmm2, xmm0
  MOVSD [CameraY], xmm2

  PXOR xmm3, xmm3
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_SetCameraRotation
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_SetCameraYOnly_CB, _TEXT$00


;*********************************************************
;  StarDemo_SetCameraXOnly_CB
;
;        Parameters: Set the Camera
;
;       
;
;
;*********************************************************    
NESTED_ENTRY StarDemo_SetCameraXOnly_CB, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
  .ENDPROLOG 
  MOVSD xmm0, [CameraXVel]
  MOVSD xmm1, [CameraX]
  ADDSD xmm1, xmm0
  MOVSD [CameraX], xmm1

  MOVSD xmm2, [CameraY]

  PXOR xmm3, xmm3
  MOV RCX, [SOft3D]
  DEBUG_FUNCTION_CALL Soft3D_SetCameraRotation
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  RET
NESTED_END StarDemo_SetCameraXOnly_CB, _TEXT$00

;*********************************************************
;  StarDemo_DecCameraYVel_CB
;
;        Parameters: Slow down Camera Y Panning
;
;       
;
;
;*********************************************************    
NESTED_ENTRY StarDemo_DecCameraYVel_CB, _TEXT$00
  .ENDPROLOG 
  MOVSD xmm0, [CameraYVel]
  MOVSD xmm1, [ConstantNeg]
  MULSD xmm0, xmm1
  MOVSD [CameraYVel], xmm0
  RET
NESTED_END StarDemo_DecCameraYVel_CB, _TEXT$00

;*********************************************************
;  StarDemo_DecCameraXVel_CB
;
;        Parameters: Slow down Camera Y Panning
;
;       
;
;
;*********************************************************    
NESTED_ENTRY StarDemo_DecCameraXVel_CB, _TEXT$00
  .ENDPROLOG 
  MOVSD xmm0, [CameraXVel]
  MOVSD xmm1, [ConstantNeg]
  MULSD xmm0, xmm1
  MOVSD [CameraXVel], xmm0
  RET
NESTED_END StarDemo_DecCameraXVel_CB, _TEXT$00


END