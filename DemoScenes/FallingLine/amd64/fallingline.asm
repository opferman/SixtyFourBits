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

FALLINGLINE_FUNCTION_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
FALLINGLINE_FUNCTION_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Fallingline_Init
public Fallingline_Demo
public Fallingline_Free

MAX_FRAMES EQU <2000>

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter dd ?
   PrevFrameCounter dd ?
   GlobalRDIOffset dq ?
   ColorValue dd ?
   X_offset dq ?
   Y_offset dq ?
   xDirection dd ?
   yDirection dd ?

.CODE

;*********************************************************
;   Fallingline_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Fallingline_Init, _TEXT$00
 alloc_stack(SIZEOF FALLINGLINE_FUNCTION_STRUCT)
 save_reg rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi
.ENDPROLOG 

  MOV [FrameCounter], 0
  MOV [PrevFrameCounter], 0
  MOV [GlobalRDIOffset], 0
  MOV [ColorValue], 0FF0000h
  MOV [X_offset], 0200h
  MOV [y_offset], 0120h
  MOV [xDirection], 1
  MOV [yDirection], 1
  ;
  ; Initialize Random Numbers
  ;
  XOR ECX, ECX
  CALL time
  MOV ECX, EAX
  CALL srand

  MOV RSI, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  ADD RSP, SIZE FALLINGLINE_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Fallingline_Init, _TEXT$00



;*********************************************************
;  Fallingline_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Fallingline_Demo, _TEXT$00
 alloc_stack(SIZEOF FALLINGLINE_FUNCTION_STRUCT)
 save_reg rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 
  
  
  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ;  
  
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  



  MOV r11, [X_offset]
  MOV r12, [Y_offset] 

 @PlotRandomInternal:  

  CMP [xDirection], 0
  JE @DecrementX
  INC r11
  JMP @YCompare
  @DecrementX:
  DEC r11
  
  @Ycompare:
  CMP [yDirection], 0
  JE  @DecrementY
  INC r12
  JMP @StartBoundCheck
  @DecrementY:
  DEC r12
  
  
  @StartBoundCheck:
  ;check left
  CMP r11, 0180h
  JBE @ChangeLeft
  
  ;check right 
  CMP r11, 0280h
  JAE @ChangeRight
  
  ;check top
  CMP r12, 0200h
  JAE @ChangeTop
  
  ;check Bottom
  CMP r12, 0100h
  JBE @ChangeBottom
  
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r11
  MOV r8,  r12
  CALL Fallingline_PlotLocation
  ADD RDI, RAX
  MOV EAX, 0FF0000h
  MOV [RDI], RAX
  
  MOV [X_offset], r11
  MOV [Y_offset] , r12

  
 @Terminate:
  MOV rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE FALLINGLINE_FUNCTION_STRUCT
  RET
  
  @ChangeLeft:
  CMP [xDirection], 0
  JNE @PlotRandomInternal
  INC [xDirection]
  CALL rand
  MOV r13,10h
  DIV r13
  ADD r11, RDX
  JMP @PlotRandomInternal
  
  @ChangeRight:
  CMP [xDirection], 1
  JNE @PlotRandomInternal
  DEC [xDirection]
  CALL rand
  MOV r13,09h
  DIV r13
  SUB r11, RDX
  JMP @PlotRandomInternal
  
  @ChangeTop:
  CMP [yDirection], 1
  JNE @PlotRandomInternal
  DEC [yDirection]
  
  CALL rand
  MOV r13,20h
  DIV r13
  SUB r12, RDX
  JMP @PlotRandomInternal
  
  @ChangeBottom:
  CMP [yDirection], 0
  JNE @PlotRandomInternal
  INC [yDirection]
  
  CALL rand
  MOV r13,0fh
  DIV r13
  ADD r12, RDX
  JMP @PlotRandomInternal
NESTED_END Fallingline_Demo, _TEXT$00




NESTED_ENTRY Fallingline_PlotLocation, _TEXT$00
 alloc_stack(SIZEOF FALLINGLINE_FUNCTION_STRUCT)
 save_reg rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR13

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
  MOV rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE FALLINGLINE_FUNCTION_STRUCT
  RET
NESTED_END Fallingline_PlotLocation, _TEXT$00

;*********************************************************
;  Fallingline_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fallingline_Free, _TEXT$00
 alloc_stack(SIZEOF FALLINGLINE_FUNCTION_STRUCT)
 save_reg rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 

  ; Nothing to clean up

  MOV rdi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, FALLINGLINE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FALLINGLINE_FUNCTION_STRUCT
  RET
NESTED_END Fallingline_Free, _TEXT$00


END