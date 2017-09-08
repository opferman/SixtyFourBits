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
include master.inc
include vpal_public.inc
include font_public.inc

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
    SaveR10        dq ?
    SaveR11        dq ?
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

			   
  DoubleBuffer   dq  ?
  VirtualPallete dq ?
  FrameCountDown dd 7000

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
  JZ @StarInit_Failed

  MOV RCX, 256
  CALL VPal_Create
  TEST RAX, RAX
  JZ @StarInit_Failed

  MOV [VirtualPallete], RAX

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
 save_reg r10, STAR_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, STAR_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, STAR_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, STAR_DEMO_STRUCTURE.SaveFrame.SaveR13

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


    
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r10, STAR_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, STAR_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
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

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, STAR_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, STAR_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE STAR_DEMO_STRUCTURE
  RET
NESTED_END StarDemo_Free, _TEXT$00











END