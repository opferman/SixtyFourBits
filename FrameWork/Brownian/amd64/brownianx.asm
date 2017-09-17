;*********************************************************
; Brownian framework
;
;  Written in Assembly x64
; 
;  By Sarthak Shah  9/8/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include master.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
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

BROWNIAN_FUNC_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
BROWNIAN_FUNC_STRUCT ends

public Brownian_PlantSeed
public Brownian_FindNextPixel
public Brownian_DisplayPixel
public Brownian_GetNextXLocation
public Brownian_GetNextYLocation
public Brownian_SetupBuffer

;*********************************************************
; Data Segment
;*********************************************************
.DATA
   PlotBuffer  dq ?
   X_offset dq ?
   Y_offset dq ?
   xDirection dd 01h
   yDirection dd 01h

.CODE
;*******************************************************************************
;  Brownian_SetupBuffer
;
;        Parameters: Master Context
;        Return value: None
;
;        This routine sets up the brownian buffer.
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_SetupBuffer, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [PlotBuffer], RAX
  
  ;
  ; Initialize Random Numbers
  ;
  XOR ECX, ECX
  CALL time
  MOV ECX, EAX
  CALL srand
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_SetupBuffer, _TEXT$00


;*******************************************************************************
;  Brownian_GetNextXLocation
;
;        Parameters: None
;        Return value: X_offset
;
;        This routine returns X_offset. Call this after call to Brownian_FindNextPixel
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_GetNextXLocation, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RAX, [X_offset]
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_GetNextXLocation, _TEXT$00

;*******************************************************************************
;  Brownian_GetNextYLocation
;
;        Parameters: None
;        Return value: Y_offset
;
;        This routine returns Y_offset. Call this after call to Brownian_FindNextPixel
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_GetNextYLocation, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RAX, [Y_offset]
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_GetNextYLocation, _TEXT$00
 
;*******************************************************************************
;  Brownian_PlantSeed
;
;        Parameters: x co-ordinate, y co-ordinate.
;
;        This routine plots a single pixel in the brownian buffer which serves as a seed.
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_PlantSeed, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV r11, rcx
  MOV r12, rdx
  MOV RAX,r12
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, r11
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV AL,1
  MOV [r10], AL  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_PlantSeed, _TEXT$00

;*******************************************************************************
;  Brownian_DisplayPixel
;
;        Parameters: MASTER CONTEXT, X co-ordinate, Y co-ordinate, color.
;
;        This routine displays a pixel on the screen
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_DisplayPixel, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  MOV r12, R8
  MOV r13d, r9d
  
  MOV RAX,r12
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, r11
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL,01h
  MOV [r10], DL
  
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]
  MOV RCX, RSI
  MOV RDX, r11
  MOV r8,  r12
  CALL Brownian_PlotLocation
  ADD RDI, RAX
  
  MOV EAX, r13d
  MOV [RDI], EAX
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_DisplayPixel, _TEXT$00


;*********************************************************************************************************
;  Brownian_FindNextPixel
;
;        Parameters: left, right, top and bottom bound values.
;
;        Return Value: None

; This routine finds the next pixel to plot. It can loop infinitely so be careful with thhe bound values.
;
;
;*********************************************************************************************************


NESTED_ENTRY Brownian_FindNextPixel, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG   
  MOV rdi, rcx
  MOV rsi, rdx
  MOV rbx, r8
  MOV r13, r9
  
   
  XOR r10, r10
  XOR rcx, rcx
  
  MOV r11, rsi
  SUB r11, rdi
  MOV r12, rbx
  SUB r12, r13
  
  CALL rand
  MOV r10,r11
  DIV r10
  ADD RDX, rdi
  MOV [X_offset], RDX
  
  CALL rand
  MOV rcx,r12
  DIV rcx
  ADD RDX, r13
  MOV [Y_offset],RDX
  
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
  CMP r11, rdi
  JBE @ChangeLeft
  
  ;check right 
  CMP r11, rsi
  JAE @ChangeRight
  
  ;check top
  CMP r12, rbx
  JAE @ChangeTop
  
  ;check Bottom
  CMP r12, r13
  JBE @ChangeBottom
  
  MOV RCX, r11
  MOV RDX, r12
  CALL Brownian_CheckBounds
  CMP RAX, 0
  JE @PlotRandomInternal
  
  MOV [X_offset], r11
  MOV [Y_offset], r12
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
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
  
NESTED_END Brownian_FindNextPixel, _TEXT$00


;*********************************************************************************************************
;  Brownian_CheckBounds
;
;        Parameters: X Co-ordinate and Y Co-ordinate. 
;
;        Return Value: None

; This routine checks if the current location has a pixel next to it in all directions.
;
;
;*********************************************************************************************************






NESTED_ENTRY Brownian_CheckBounds, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  
  SUB RSI, 1  ; Check Left
  ;CMP RSI, 01h
  ;JBE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  ADD RSI, 2  ; Check Right
  ;CMP RSI, 03FEh
  ;JAE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  SUB RSI, 1   ;Check Bottom
  ADD r11, 1
  ;CMP r11, 02FEh
  ;JAE @FoundPixel
  
 MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  
  SUB r11, 2 ;Check Top
  ;CMP r11, 1
  ;JBE @FoundPixel
  
  MOV RAX,r11
  MOV RDX, 0400h
  MUL RDX
  ADD RAX, RSI
  MOV r10, PlotBuffer
  ADD r10,RAX
  MOV DL, [r10]
  CMP DL, 1
  JE @FoundPixel
  MOV RAX, 0
  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
  
  @FoundPixel:
  MOV RAX,1
  JMP @Terminate
NESTED_END Brownian_CheckBounds, _TEXT$00


;*******************************************************************************
;  Brownian_PlotLocation
;
;        Parameters: MASTER CONTEXT, X co-ordinate, Y co-ordinate.
;
;        This routine displays a pixel on the screen.
;
;
;*******************************************************************************

NESTED_ENTRY Brownian_PlotLocation, _TEXT$00
 alloc_stack(SIZEOF BROWNIAN_FUNC_STRUCT)
 save_reg rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx
 save_reg r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10
 save_reg r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11
 save_reg r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12
 save_reg r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 

  MOV RSI, RCX
  MOV r11, RDX
  MOV r12, R8
  
  
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  ADD RDI, RBX
  
  
  
  SHL r11,2
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RAX,2
  SUB RBX, RAX
  ADD RAX, RBX
  MUL r12
  ADD RAX, r11
  ;
  ; Get the Video Buffer
  ;  
  
  
  
 @Terminate:
  MOV rdi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, BROWNIAN_FUNC_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE BROWNIAN_FUNC_STRUCT
  RET
NESTED_END Brownian_PlotLocation, _TEXT$00




END
