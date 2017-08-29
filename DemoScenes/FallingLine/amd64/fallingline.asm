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
   DisplayFlag db ?
   RandomColor dd ?
   ColorValue dd ?

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
  MOV [DisplayFlag], 0
  MOV [ColorValue], 0FF0000h
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
  
  MOV r11, 05000000h
  @DelayLoop:
  DEC r11
  JNZ @DelayLoop
  
  
  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ;  
  CMP [DisplayFlag], 0
  JNZ @DisplayLine
  JMP @ClearLine
  
  @DisplayLine:
  MOV [DisplayFlag], 0
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV r10, [GlobalRDIOffset]
  MOV RAX, R10
  MUL [FrameCounter]
  MOV R10, RAX
  ADD RDI, r10
  MOV RAX, [GlobalRDIOffset]
  SHR RAX, 2
  MUL MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R11, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  ADD R11, RAX
  MOV RAX, [GlobalRDIOffset]
  SHR RAX, 2
  SUB r11, RAX
  CMP RDI, r11
  JA @DemoEnd
  
  SHR [ColorValue], 16
  DEC [ColorValue]
  JNZ @SetColor
  MOV [ColorValue], 0FFh
  @SetColor:
  SHL [ColorValue], 16
  MOV EAX, [ColorValue]
 ; MOV [RandomColor],EAX
  ;MOV EAX, [RandomColor]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD
  
  
  CMP [GlobalRDIOffset],0
  JNZ @Terminate1
  ;
  ; Wrap to the next line by adjusting for stride
  ;
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R8, 2
  SUB RBX, R8
  ADD RDI, RBX
  MOV R8,MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  SUB RDI, R8
  SHL RDI, 2
  MOV [GlobalRDIOffset], RDI
  
  @Terminate1:
  XOR EAX, EAX
  MOV r10d, [FrameCounter]
  MOV [PrevFrameCounter], r10d
  INC [FrameCounter]
  MOV AL, 1
  
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
  
  
  @ClearLine:
  MOV [DisplayFlag], 1
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV r10, [GlobalRDIOffset]
  MOV RAX, R10
  MUL [PrevFrameCounter]
  MOV R10, RAX
  ADD RDI, r10
  MOV RAX, [GlobalRDIOffset]
  SHR RAX, 2
  MUL MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R11, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  ADD R11, RAX
  MOV RAX, [GlobalRDIOffset]
  SHR RAX, 2
  SUB r11, RAX
  CMP RDI, r11
  JA @DemoEnd
  MOV RAX, 0
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD
  JMP @DisplayLine
  
  @DemoEnd:  
  ;
  ; Generate new random color
  ;
  MOV [ColorValue], 0FFh
  MOV [FrameCounter], 0
  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  @ClearLoop:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MOV RAX,0
  REP STOSD
  
  ;
  ; Wrap to the next line by adjusting for stride
  ;
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R8, 2
  SUB RBX, R8
  ADD RDI, RBX 
  ;
  ; Decrement for the next line
  ;
  DEC RDX
  JNZ @ClearLoop
  MOV AL, 1
  JMP @Terminate
NESTED_END Fallingline_Demo, _TEXT$00



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