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
  ;JE @PlotRandom
  XOR r10, r10
  XOR r13, r13
  
  CALL rand
  MOV r10,0FFh
  DIV r10
  ADD RDX, 0180h
  MOV [X_offset],RDX
  
  CALL rand
  MOV r13,0FFh
  DIV r13
  ADD RDX, 0100h
  MOV [Y_offset],RDX
  

  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [PlotBuffer], RAX
  
  MOV RAX,[Y_offset]
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, [X_offset]
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV RDX,1
  MOV [r10], RDX
  ;MOV [X_offset], 0
  ;MOV [Y_offset], 0
  ;@FillBuffer:
  ;MOV RAX,[Y_offset]
  ;MOV RDX, 0400h
  ;MUL RDX
  ;ADD RAX, [X_offset]
  ;MOV r10, PlotBuffer
  ;ADD r10,RAX
  ;MOV RDX,1
  ;MOV [r10], RDX
  ;INC X_offset
  ;CMP X_offset, 0400h
  ;JB @FillBuffer
  ;INC Y_offset
  ;MOV [X_offset], 0
  ;CMP Y_offset, 02FFh
  ;JBE @FillBuffer 
  
  
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, [X_offset]
  MOV r8, [Y_offset]
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  MOV EAX, 0D0D0D0h
  MOV [RDI], RAX
  MOV [Brownian_InitFlag], 1
  
  
  
  ;@PlotRandom:
 ; XOR r10, r10
 ; XOR r13, r13
  
 ; CALL rand
 ; MOV r10,0FFh
 ; DIV r10
 ; ADD RDX, 0180h
 ; MOV [X_offset],RDX
  
 ; CALL rand
 ; MOV r13,0FFh
 ; DIV r13
 ; ADD RDX, 0100h
 ; MOV [Y_offset],RDX
  
  
  
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



NESTED_ENTRY Brownian_PlotLocation, _TEXT$00
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
  MOV r11, RDX
  MOV r12, R8
  
  SHL r11,2
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RAX,2
  MUL r12
  ADD RAX, r11
  ;
  ; Get the Video Buffer
  ;  
  
  
  
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
NESTED_END Brownian_PlotLocation, _TEXT$00



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