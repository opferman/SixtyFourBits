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
include ksamd64.inc
include demovariables.inc
include master.inc
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
  JE @PlotRandom
    
  CALL Brownian_SetupBuffer

  XOR r10, r10
  XOR r13, r13
  
  
  MOV RCX, 0200h;
  MOV RDX, 0120h;
  CALL Brownian_PlantSeed
  
  MOV RCX, 0210h
  MOV RDX, 0B0h
  CALL Brownian_PlantSeed
  
  MOV RCX, 01F0h
  MOV RDX, 0100h
  CALL Brownian_PlantSeed
  
  MOV RCX, 0220h
  MOV RDX, 0150h
  CALL Brownian_PlantSeed
 
  
  MOV [Brownian_InitFlag], 1
 
  
  
  @PlotRandom: 
  CMP [Plot_Counter], 03000h
  JAE @SecondSquare
  MOV rcx, 01E7h
  MOV rdx, 0219h
  MOV r8, 0250h
  MOV r9, 0B8h
  CALL Brownian_FindNextPixel 
  CALL rand
  MOV r13,0EEEEEEh
  DIV r13
  ADD RDX,0010101h
  MOV R9,RDX
  
  
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  MOV RCX, RSI
  CALL Brownian_DisplayPixel

  CMP [Plot_Counter], 0500h
  JAE @SecondSquare
  MOV rcx, 01DDh
  MOV rdx, 0223h
  MOV r8, 0C8h
  MOV r9, 096h
  CALL Brownian_FindNextPixel
  CALL rand
  MOV r13,0EEEEEEh
  DIV r13
  ADD RDX,0010101h
  MOV R9,RDX
 
 
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  MOV RCX, RSI
  CALL Brownian_DisplayPixel
  
  @SecondSquare:
  CMP [Plot_Counter], 05000h
  JAE @LastSquare
  MOV rcx, 01ABh
  MOV rdx, 0255h
  MOV r8, 012Ch
  MOV r9, 0C8h
  CALL Brownian_FindNextPixel
  CALL rand
  MOV r13,0EEEEEEh
  DIV r13
  ADD RDX,0010101h
  MOV R9,RDX
  
  MOV RCX, RSI
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  CALL Brownian_DisplayPixel
  
  @LastSquare:
  CMP [Plot_Counter], 0A000h
  JAE @Terminate
  MOV rcx, 0160h
  MOV rdx, 02A0h
  MOV r8, 01C2h
  MOV r9, 012Ch
  CALL Brownian_FindNextPixel
  CALL rand
  MOV r13,0EEEEEEh
  DIV r13
  ADD RDX,0010101h
  MOV R9,RDX
  
  MOV RCX, RSI
  CALL Brownian_GetNextXLocation
  MOV RDX, RAX
  CALL Brownian_GetNextYLocation
  MOV r8, RAX
  CALL Brownian_DisplayPixel
  
  INC [Plot_Counter]
 @Terminate:
  MOV RAX, 01h  
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