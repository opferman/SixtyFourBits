;*********************************************************
; FallingLine 
;
;  Written in Assembly x64
; 
;  By Sarthak Shah
;  Template incorporated from Toby Opferman
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
include brownianx_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern time:proc
extern srand:proc
extern rand:proc

;*********************************************************
; Structures
;*********************************************************
PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR10        dq ?
    SaveR11        dq ?
	SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

BROWNIAN_FUNCTION_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
BROWNIAN_FUNCTION_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Brownian_Init
public Brownian_Demo
public Brownian_Free

MAX_FRAMES EQU <2000>

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter dd ?
   PrevFrameCounter dd ?
   GlobalRDIOffset dq ?
   ColorValue dd ?
   PlotBuffer  dq ?
   X_offset dq ?
   Y_offset dq ?
   Brownian_InitFlag dd ?
   FirstChance dd ?
   Plot_Counter dq ?
   VirtualPalleteBrownian dq ?
   VirtualColorCounter dd ?
   Temp  dd ?

.CODE

;*********************************************************
;   Brownian_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Init, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
.ENDPROLOG 

  MOV [FrameCounter], 0
  MOV [PrevFrameCounter], 0
  MOV [GlobalRDIOffset], 0
  MOV [ColorValue], 0FF0000h
  MOV [Brownian_InitFlag], 0h
  MOV [FirstChance], 0h
  MOV [Plot_Counter], 0h
  MOV [VirtualColorCounter], 0h
  ;
  ; Initialize Random Numbers
  ;
  XOR ECX, ECX
  CALL time
  MOV ECX, EAX
  CALL srand

  MOV RSI, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Brownian_Init, _TEXT$00



;*********************************************************
;  Brownian_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Demo, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ;  
  CMP [Brownian_InitFlag], 1
  JE @StartDemo
  CALL Brownian_SetupBuffer
  XOR r10, r10
  XOR r13, r13
  MOV R11, 4
  MOV R12, 100
  @FirstLine:
  MOV RCX,R12
  MOV RDX,100
  MOV R8, 000FF00h
  MOV R9, RSI
  CALL DrawSquares
  ADD R12, 200
  DEC R11
  JNZ @FirstLine
  
  MOV R11, 4
  MOV R12, 100
  @SecondLine:
  MOV RCX,R12
  MOV RDX,300
  MOV R8, 000FF00h
  MOV R9, RSI
  CALL DrawSquares
  ADD R12, 200
  DEC R11
  JNZ @SecondLine
  
  MOV R11, 4
  MOV R12, 100
  @ThirdLine:
  MOV RCX,R12
  MOV RDX,500
  MOV R8, 000FF00h
  MOV R9, RSI
  CALL DrawSquares
  ADD R12, 200
  DEC R11
  JNZ @ThirdLine
  
  XOR R11,R11
  XOR R12,R12
  MOV R11, 4
  MOV R12, 100
  @PlantFLSeed:
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,100
  MOV R10,RDX
  
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,R12
  MOV RCX,RDX
  MOV RDX,R10
  CALL Brownian_PlantSeed
  ADD R12, 200
  DEC R11
  JNZ @PlantFLSeed
  
  MOV R11, 4
  MOV R12, 100
  @PlantSLSeed:
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,300
  MOV R10,RDX
  
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,R12
  MOV RCX,RDX
  MOV RDX,R10
  CALL Brownian_PlantSeed
  ADD R12, 200
  DEC R11
  JNZ @PlantSLSeed
  
  MOV R11, 4
  MOV R12, 100
  @PlantTLSeed:
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,500
  MOV R10,RDX
  
  CALL rand
  MOV r13,150
  DIV r13
  ADD RDX,R12
  MOV RCX,RDX
  MOV RDX,R10
  CALL Brownian_PlantSeed
  ADD R12, 200
  DEC R11
  JNZ @PlantTLSeed
  
  MOV [Brownian_InitFlag], 1
  
  @StartDemo:
  
  MOV R11, 4
  MOV R12, 100
  @PlotFL: 
  MOV rcx, R12
  MOV rdx, R12
  ADD rdx, 150
  MOV r8, 250
  MOV r9, 100
  CALL Brownian_FindNextPixel 
  MOV R9,0FF0000h
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  MOV RCX, RSI
  CALL Brownian_DisplayPixel
  ADD R12, 200
  DEC R11
  JNZ @PlotFL
 
  MOV R11, 4
  MOV R12, 100
  @PlotSL: 
  MOV rcx, R12
  MOV rdx, R12
  ADD rdx, 150
  MOV r8, 450
  MOV r9, 300
  CALL Brownian_FindNextPixel 
  MOV R9,0FF0000h
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  MOV RCX, RSI
  CALL Brownian_DisplayPixel
  ADD R12, 200
  DEC R11
  JNZ @PlotSL
  
  MOV R11, 4
  MOV R12, 100
  @PlotTL: 
  MOV rcx, R12
  MOV rdx, R12
  ADD rdx, 150
  MOV r8, 650
  MOV r9, 500
  CALL Brownian_FindNextPixel 
  MOV R9,0FF0000h
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  MOV RCX, RSI
  CALL Brownian_DisplayPixel
  ADD R12, 200
  DEC R11
  JNZ @PlotTL
  
  MOV RAX,0
  INC [FrameCounter]
  CMP [FrameCounter],10000
  JAE @Terminate
  MOV RAX, 01h  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
  
NESTED_END Brownian_Demo, _TEXT$00


;*********************************************************
;  DrawSquares
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  

NESTED_ENTRY DrawSquares, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV R10,RCX
  MOV R11, RDX
  MOV R12d, R8d
  MOV RSI, R9
  
  MOV R13, 150
  @DrawLeftLine:
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r10
  MOV r8,  r11
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  MOV EAX, r12d
  MOV [RDI], EAX
  INC R11
  DEC R13
  JNZ @DrawLeftLine
  
  MOV R13,150
  @DrawBottomLine:
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r10
  MOV r8,  r11
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  MOV EAX, r12d
  MOV [RDI], EAX
  INC R10
  DEC R13
  JNZ @DrawBottomLine
  
  MOV R13,150
  @DrawRightLine:
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r10
  MOV r8,  r11
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  MOV EAX, r12d
  MOV [RDI], EAX
  DEC R11
  DEC R13
  JNZ @DrawRightLine
  
  MOV R13,150
  @DrawTopLine:
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r10
  MOV r8,  r11
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  MOV EAX, r12d
  MOV [RDI], EAX
  DEC R10
  DEC R13
  JNZ @DrawTopLine
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
NESTED_END DrawSquares, _TEXT$00


;*********************************************************
;  Brownian_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Brownian_Free, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNCTION_STRUCT)
 save_reg rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 

  ; Nothing to clean up

  MOV rdi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE BROWNIAN_FUNCTION_STRUCT
  RET
NESTED_END Brownian_Free, _TEXT$00


END