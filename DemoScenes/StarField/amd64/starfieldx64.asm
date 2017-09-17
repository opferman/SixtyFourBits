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
include ksamd64.inc
include demovariables.inc
include demoprocs.inc
include master.inc
include vpal_public.inc
include font_public.inc
include soft3d_public.inc
include soft3d_funcs.inc
include debug_public.inc

extern LocalAlloc:proc
extern LocalFree:proc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR14        dq ?
    SaveR15        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

FUNC_PARAMS struct
    ReturnAddress  dq ?
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
    Param5         dq ?
    Param6         dq ?
    Param7         dq ?
FUNC_PARAMS ends

STAR_FIELD_ENTRY struct
   Location       TD_POINT <?>
   Velocity       mmword    ?  
   StarOnScreen   dq        ?
   Color          db        ?
STAR_FIELD_ENTRY ends

STAR_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
STAR_DEMO_STRUCTURE ends

STAR_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
STAR_DEMO_STRUCTURE_FUNC ends

public StarDemo_Init
public StarDemo_Demo
public StarDemo_Free

extern time:proc
extern srand:proc
extern rand:proc


.DATA
  DoubleBuffer   dq ?
  VirtualPallete dq ?
  FrameCountDown dd 2800
  StarEntry      STAR_FIELD_ENTRY 1000 DUP(<>)
  Soft3D         dq ?
  TwoDPlot        TD_POINT_2D <?>
  WorldLocation   TD_POINT    <?>
  View_Distance   mmword   256.0
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [VirtualPallete], 0

  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
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
    
  MOV RSI, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE STAR_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@StarInit_Failed:
  MOV RSI, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE STAR_DEMO_STRUCTURE
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r14, STAR_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, STAR_DEMO_STRUCTURE.SaveFrame.SaveR15
 save_reg r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, STAR_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX

  ;
  ; Update the screen with the buffer
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [DoubleBuffer]

  XOR r14, r14
  XOR r12, r12

@FillScreen:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
      MOV DL, BYTE PTR [r13] ; Get Virtual Pallete Index
	  MOV BYTE PTR [r13], 0   ; Clear Video Buffer
      MOV RCX, [VirtualPallete]
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX

      ; Increment to the next location
      ADD RSI, 4
      INC r13
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL StarDemo_MoveStars

   MOV RCX, RDI
   DEBUG_FUNCTION_CALL StarDemo_PlotStars

    
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r14, STAR_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, STAR_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  MOV r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, STAR_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE STAR_DEMO_STRUCTURE
  
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
 MOV RCX, [VirtualPallete]
 DEBUG_FUNCTION_CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  DEBUG_FUNCTION_CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE STAR_DEMO_STRUCTURE
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
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
  
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE STAR_DEMO_STRUCTURE
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  LEA RDI, [StarEntry]
  XOR RSI, RSI
  MOV R12, RCX
  
@Move_Stars:
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

  ;DEBUG_FUNCTION_CALL Math_rand
  ;AND RAX, 3
  ;INC RAX
  MOV RAX, 1
  cvtsi2sd xmm0, rax
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0

  JMP  @SkipIncrementColor
@StarMoveComplete:
   
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE STAR_DEMO_STRUCTURE
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
 alloc_stack(SIZEOF STAR_DEMO_STRUCTURE)
 save_reg rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  LEA RDI, [StarEntry]
  XOR RSI, RSI
  MOV R12, RCX
  
@Plot_Stars:
  MOV STAR_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 0
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
  
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE STAR_DEMO_STRUCTURE
  RET
NESTED_END StarDemo_PlotStars, _TEXT$00



END