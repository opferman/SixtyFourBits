;*********************************************************
; Worm Hole Demo
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
include master.inc
include vpal_public.inc
include font_public.inc
include soft3d_public.inc
include soft3d_funcs.inc

extern Sleep:proc
extern LocalAlloc:proc
extern LocalFree:proc
extern cos:proc
extern sin:proc

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
    SaveR10        dq ?
    SaveR11        dq ?
    SaveR12        dq ?
	SaveXmm6       xmmword ?
	SaveXmm7       xmmword ?
	SaveXmm8       xmmword ?
	SaveXmm9       xmmword ?
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
   Location        TD_POINT <?>
   RotatedLocation TD_POINT <?>
   NewRadians      mmword    ?
   Velocity        mmword    ?  
   StarOnScreen    dq        ?
   Color           db        ?
STAR_FIELD_ENTRY ends

WORM_HOLE_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
WORM_HOLE_STRUCTURE ends

WORM_HOLE_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
WORM_HOLE_STRUCTURE_FUNC ends

public WormHole_Init
public WormHole_Demo
public WormHole_Free

extern time:proc
extern srand:proc
extern rand:proc

NUMBER_STARS EQU <18000>
NUMBER_STARS_SIZE EQU <NUMBER_STARS * (SIZE STAR_FIELD_ENTRY)>

.DATA
  DoubleBuffer   dq ?
  VirtualPallete dq ?
  FrameCountDown dd 2800
;  StarEntry      STAR_FIELD_ENTRY NUMBER_STARS DUP(<>)
  StarEntryPtr    dq ?
  Soft3D          dq ?
  TwoDPlot        TD_POINT_2D <?>
  WorldLocation   TD_POINT    <?>
  StartX          mmword   10.0
  StartY          mmword   10.0
  StartZ          mmword   100.0
  VelZ            mmword   0.005
  VelZMoving      mmword   -0.05
  View_Distance   mmword   256.0
  VelocityRadians mmword   0.0872222222     ; 10.0*(3.14/180.0)
  CurrentRadians  mmword   0.0
  RadianIncrement mmword   0.00872222222  ; 0.5*(3.14/180.0)
  CurrentColor      db   255
  StarsPerColorDec  dq  72
  DoublePi        mmword  6.28
.CODE

;*********************************************************
;   WormHole_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Init, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  MOV RSI, RCX

  MOV [VirtualPallete], 0

  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @WormInit_Failed

  MOV RDX, NUMBER_STARS_SIZE
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [StarEntryPtr], RAX
  TEST RAX, RAX
  JZ @WormInit_Failed

  MOV RCX, 256
  CALL VPal_Create
  TEST RAX, RAX
  JZ @WormInit_Failed
  MOV [VirtualPallete], RAX
  

  XOR R8, R8
  XOR RDX, RDX
  MOV RCX, RSI
  CALL Soft3D_Init
  MOV [Soft3D], RAX
  TEST RAX, RAX
  JZ @WormInit_Failed


  LEA RCX, [WorldLocation]
  MOV TD_POINT.x[RCX], 0
  MOV TD_POINT.y[RCX], 0
  MOV TD_POINT.z[RCX], 0


  MOVSD xmm0, [View_Distance]
  MOVSD xmm1, xmm0
  MOV RCX, [SOft3D]
  CALL Soft3D_SetViewDistance



  XOR R12, R12

@PopulatePallete:
  MOV RAX, R12
  MOV AH, AL
  SHL RAX, 8
  MOV AL, AH

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  INC R12
  CMP R12, 256
  JB @PopulatePallete

  MOV RCX, RSI
  CALL WormHole_CreateStars
    
  MOV RSI, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  MOV EAX, 1
  RET

@WormInit_Failed:
  MOV RSI, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  XOR EAX, EAX
  RET
NESTED_END WormHole_Init, _TEXT$00



;*********************************************************
;  WormHole_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Demo, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, WORM_HOLE_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, WORM_HOLE_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, WORM_HOLE_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  MOV RDI, RCX

  ;
  ; Update the screen with the buffer
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [DoubleBuffer]

  XOR R9, R9
  XOR r12, r12

@FillScreen:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
      MOV DL, BYTE PTR [r13] ; Get Virtual Pallete Index
	  MOV BYTE PTR [r13], 0   ; Clear Video Buffer
      MOV RCX, [VirtualPallete]
      CALL VPal_GetColorIndex 

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
   INC R9

   CMP R9, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen

   MOV RCX, RDI
   CALL WormHole_MoveStars

   MOV RCX, RDI
   CALL WormHole_PlotStars

   XOR RDX, RDX
   MOV RCX,15
   CALL Sleep
    
  MOV rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r10, WORM_HOLE_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, WORM_HOLE_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, WORM_HOLE_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END WormHole_Demo, _TEXT$00



;*********************************************************
;  WormHole_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_Free, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  RET
NESTED_END WormHole_Free, _TEXT$00


;*********************************************************
;  WormHole_CreateStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_CreateStars, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm6[RSP], xmm6
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm7[RSP], xmm7
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm8[RSP], xmm8
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm9[RSP], xmm9
.ENDPROLOG 
  MOV RBX, RCX
  ;LEA RDI, [StarEntry]
  MOV RDI, [StarEntryPtr]
  XOR RSI, RSI

  MOVSD xmm6, [StartX]
  MOVSD xmm7, [StartY]
  MOVSD xmm8, [StartZ]

@Initialize_Stars:

  MOVSD STAR_FIELD_ENTRY.Location.x[RDI], xmm6
  MOVSD STAR_FIELD_ENTRY.Location.y[RDI], xmm7
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm8
  
 ; MOVSD STAR_FIELD_ENTRY.RotatedLocation.x[RDI], xmm6
 ; MOVSD STAR_FIELD_ENTRY.RotatedLocation.y[RDI], xmm7
 ; MOVSD STAR_FIELD_ENTRY.RotatedLocation.z[RDI], xmm8
  
  MOVSD xmm0, [VelZ]
  ADDSD xmm8, xmm0


  ;
  ; cos(r)*x - sin(r)*y
  ;
  MOVSD xmm0, [CurrentRadians]
  CALL Cos
  MULSD xmm0, xmm6
  MOVSD xmm9, xmm0

  MOVSD xmm0, [CurrentRadians]
  CALL Sin
  MULSD xmm0, xmm7

  SUBSD xmm9, xmm0

  ;
  ; (sin(r)*x + cos(r)*y)
  ;
  MOVSD xmm0, [CurrentRadians]
  CALL Sin
  MULSD xmm0, xmm6
  MOVSD xmm6, xmm9
  MOVSD xmm9, xmm0

  MOVSD xmm0, [CurrentRadians]
  CALL Cos
  MULSD xmm0, xmm7
  ADDSD xmm0, xmm9
  MOVSD xmm7, xmm0
  
  MOVSD xmm0, [RadianIncrement]
  MOVSD xmm1, [CurrentRadians]
  ADDSD XMM0, XMM1
  MOVSD  [CurrentRadians], xmm0

  UCOMISD xmm0,  mmword ptr [DoublePi]
  JL @SkipUpdateRadians1
  
  MOVSD xmm1, mmword ptr [DoublePi]
  SUBSD XMM0, XMM1
  MOVSD [CurrentRadians], xmm0

@SkipUpdateRadians1:



  MOV STAR_FIELD_ENTRY.StarOnScreen[RDI], SOFT3D_PIXEL_ON_SCREEN
  MOVSD xmm0, [VelocityRadians]
  MOVSD STAR_FIELD_ENTRY.Velocity[RDI], xmm0
  MOVSD STAR_FIELD_ENTRY.NewRadians[RDI], xmm0

  MOV AL, [CurrentColor]
  MOV STAR_FIELD_ENTRY.Color[RDI], AL
  
  XOR RDX, RDX
  MOV RAX, RSI
  MOV RCX, [StarsPerColorDec]
  DIV RCX
  
  CMP RDX, 0
  JNE @NextStar
  
  DEC [CurrentColor]
@NextStar:

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, NUMBER_STARS
  JB @Initialize_Stars
  
   MOVAPS xmm6,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm6[RSP]
 MOVAPS xmm7,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm7[RSP]
 MOVAPS xmm8,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm8[RSP]
 MOVAPS xmm9,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm9[RSP]
  MOV rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  RET
NESTED_END WormHole_CreateStars, _TEXT$00



;*********************************************************
;  WormHole_MoveStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_MoveStars, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm6[RSP], xmm6
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm7[RSP], xmm7
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm8[RSP], xmm8
 MOVAPS WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm9[RSP], xmm9
.ENDPROLOG 
   
  ;LEA RDI, [StarEntry]
  MOV RDI, [StarEntryPtr]
  XOR RSI, RSI
  MOV R12, RCX
  
@Move_Stars:
  


  MOVSD xmm6, STAR_FIELD_ENTRY.Location.x[RDI]
  MOVSD xmm7, STAR_FIELD_ENTRY.Location.y[RDI]
  MOVSD xmm0, STAR_FIELD_ENTRY.Location.z[RDI]
  MOVSD STAR_FIELD_ENTRY.RotatedLocation.z[RDI], xmm0
  MOVSD xmm1, [VelZMoving]
  ADDSD XMM0, XMM1
  MOVSD STAR_FIELD_ENTRY.Location.z[RDI], xmm0

  ;
  ; cos(r)*x - sin(r)*y
  ;
  MOVSD xmm0, STAR_FIELD_ENTRY.NewRadians[RDI]
  CALL Cos
  MULSD xmm0, xmm6
  MOVSD xmm9, xmm0

  MOVSD xmm0, STAR_FIELD_ENTRY.NewRadians[RDI]
  CALL Sin
  MULSD xmm0, xmm7

  SUBSD xmm9, xmm0

  ;
  ; (sin(r)*x + cos(r)*y)
  ;
  MOVSD xmm0, STAR_FIELD_ENTRY.NewRadians[RDI]
  CALL Sin
  MULSD xmm0, xmm6
  MOVSD xmm6, xmm9
  MOVSD xmm9, xmm0

  MOVSD xmm0, STAR_FIELD_ENTRY.NewRadians[RDI]
  CALL Cos
  MULSD xmm0, xmm7
  ADDSD xmm0, xmm9
  MOVSD xmm7, xmm0

  MOVSD STAR_FIELD_ENTRY.RotatedLocation.x[RDI], xmm6
  MOVSD STAR_FIELD_ENTRY.RotatedLocation.y[RDI], xmm7

  MOVSD xmm1, STAR_FIELD_ENTRY.Velocity[RDI]
  MOVSD xmm0, STAR_FIELD_ENTRY.NewRadians[RDI]
  ADDSD xmm0, xmm1
  UCOMISD xmm0,  mmword ptr [DoublePi]
  JL @SkipAdjustRadians
  
  MOVSD xmm1, mmword ptr [DoublePi]
  SUBSD XMM0, XMM1

@SkipAdjustRadians:
  MOVSD STAR_FIELD_ENTRY.NewRadians[RDI], xmm0

  ADD RDI, SIZE STAR_FIELD_ENTRY
  INC RSI
  CMP RSI, NUMBER_STARS
  JB @Move_Stars
@StarMoveComplete:
   

  
 MOVAPS xmm6,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm6[RSP]
 MOVAPS xmm7,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm7[RSP]
 MOVAPS xmm8,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm8[RSP]
 MOVAPS xmm9,  WORM_HOLE_STRUCTURE.SaveFrame.SaveXmm9[RSP]

  MOV rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  RET
NESTED_END WormHole_MoveStars, _TEXT$00

;*********************************************************
;  WormHole_PlotStars
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY WormHole_PlotStars, _TEXT$00
 alloc_stack(SIZEOF WORM_HOLE_STRUCTURE)
 save_reg rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx
 save_reg r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
   
  ;LEA RDI, [StarEntry]
  MOV RDI, [StarEntryPtr]
  XOR RSI, RSI
  MOV R12, RCX
  
@Plot_Stars:
  MOV WORM_HOLE_STRUCTURE.ParameterFrame.Param5[RSP], 0
  LEA R9, [TwoDPlot]
  LEA R8, [WorldLocation]
  LEA RDX, STAR_FIELD_ENTRY.RotatedLocation[RDI]
  MOV RCX, [SOft3D]
  CALL Soft3D_Convert3Dto2D
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
  CMP RSI, NUMBER_STARS
  JB @Plot_Stars
  
  MOV rdi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, WORM_HOLE_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, WORM_HOLE_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, WORM_HOLE_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE WORM_HOLE_STRUCTURE
  RET
NESTED_END WormHole_PlotStars, _TEXT$00



END