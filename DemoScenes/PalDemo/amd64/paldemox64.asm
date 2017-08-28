;*********************************************************
; Pal Demo 
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

PAL_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
PAL_DEMO_STRUCTURE ends

PAL_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
PAL_DEMO_STRUCTURE_FUNC ends

public PalDemo_Init
public PalDemo_Demo
public PalDemo_Free

extern time:proc
extern srand:proc
extern rand:proc


.DATA

  FirstWord      db "Pure", 0
  SecondWord     db "Assembly", 0				   
  DoubleBuffer   dq  ?
  VirtualPallete dq ?
  FrameCountDown dd 7000
  Red            db  0 
  Green          db  0
  Blue           db  0FFh
  Direction      db 1

.CODE

;*********************************************************
;   PalDemo_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY PalDemo_Init, _TEXT$00
 alloc_stack(SIZEOF PAL_DEMO_STRUCTURE)
 save_reg rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12
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
  JZ @PalInit_Failed

  MOV RCX, 256
  CALL VPal_Create
  TEST RAX, RAX
  JZ @PalInit_Failed

  MOV [VirtualPallete], RAX

  XOR R12, R12

@PopulatePallete:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [Red]  
  SHL EAX, 16

  ; Green
  MOV AL, BYTE PTR [Green]
  SHL AX, 8

  ; Blue
  MOV AL, BYTE PTR [Blue]

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  DEC [Blue]
  
  INC R12
  CMP R12, 256
  JB @PopulatePallete



  ;
  ; Plot The New Pixels
  ;  
  MOV r13, [DoubleBuffer]

  XOR R9, R9
  XOR r12, r12
  XOR CL, CL    ; Start Color

@FillBackground:

      MOV BYTE PTR [r13], CL
      INC r13
      INC r12
      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
      JB @FillBackground

   ; Screen Height Increment
   ADD CL, [Direction]
   CMP CL, 0
   JNE @NextTest
   MOV [Direction], 1    

@NextTest:
    CMP CL, 0FFh
    JNE @NextLoop
    MOV [Direction], -1
@NextLoop:
  

   XOR r12, r12
   INC R9

   CMP R9, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
   JB @FillBackground
   
 
  MOV PAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 12
  LEA RDX, [FirstWord]
  MOV RCX, RSI
  MOV R8D, 50
  MOV R9D, 200
  CALL Pal_PrintWord

  MOV PAL_DEMO_STRUCTURE.ParameterFrame.Param5[RSP], 12
  LEA RDX, [SecondWord]
  MOV RCX, RSI
  MOV R8D, 20
  MOV R9D, 500
  CALL Pal_PrintWord
  
  MOV RSI, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE PAL_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@PalInit_Failed:
  MOV RSI, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE PAL_DEMO_STRUCTURE
  XOR RAX, RAX
  RET
NESTED_END PalDemo_Init, _TEXT$00



;*********************************************************
;  PalDemo_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY PalDemo_Demo, _TEXT$00
 alloc_stack(SIZEOF PAL_DEMO_STRUCTURE)
 save_reg rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, PAL_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, PAL_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, PAL_DEMO_STRUCTURE.SaveFrame.SaveR13

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

   ;
   ; Rotate the pallete by 1.  This is the only animation being performed.
   ;
   MOV RDX, 1
   MOV RCX, [VirtualPallete]
   CALL  VPal_Rotate
    
  MOV rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r10, PAL_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, PAL_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, PAL_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE PAL_DEMO_STRUCTURE
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END PalDemo_Demo, _TEXT$00



;*********************************************************
;  PalDemo_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY PalDemo_Free, _TEXT$00
 alloc_stack(SIZEOF PAL_DEMO_STRUCTURE)
 save_reg rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE PAL_DEMO_STRUCTURE
  RET
NESTED_END PalDemo_Free, _TEXT$00






;*********************************************************
;  Pal_PrintWord
;
;        Parameters: Master Context, String, X, Y, BOOL TRUE = Clear, Font Size
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Pal_PrintWord, _TEXT$00
 alloc_stack(SIZEOF PAL_DEMO_STRUCTURE)
 save_reg rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, PAL_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, PAL_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, PAL_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  MOV RDI, RCX
  MOV R10, RDX
  MOV R11, R8
  MOV R12, R9

@Pal_PrintStringLoop:

  XOR RCX, RCX
  MOV CL, [R10]
  CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured
  MOV RCX, [DoubleBuffer]
  MOV R13, RAX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  XOR RDX, RDX
  MUL R12  
  ADD RCX, RAX
  MOV RAX, R13
  XOR RDX, RDX
  ADD RCX, R11
  XOR R13, R13
  MOV RSI, PAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
@VerticleLines:
  MOV BL, 80h
@HorizontalLines:
  TEST BL, [RAX]
  JZ @SkipBit
  ; Match INFALTE_FONT
  MOV DWORD PTR [RCX+RDX],   0FFFEFDFCh 
  MOV DWORD PTR [RCX+RDX+4], 0FBFAF9F8h
  MOV DWORD PTR [RCX+RDX+8], 0F7F6F5F4h
@SkipBit:
  ADD RDX, PAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  SHR BL, 1
  TEST BL, BL
  JNZ @HorizontalLines
  XOR RDX, RDX
  ADD RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  DEC RSI
  JNZ @VerticleLines 
  MOV RSI, PAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  INC RAX
  INC R13
  CMP R13, 8
  JB @VerticleLines
  INC R10

  MOV RCX, PAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  SHL RCX, 3
  ADD R11, RCX
  ADD R11, 3
 
  CMP BYTE PTR [R10], 0 
  JNE @Pal_PrintStringLoop
  MOV EAX, 1
@ErrorOccured:
  MOV rdi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, PAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, PAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r10, PAL_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, PAL_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, PAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, PAL_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE PAL_DEMO_STRUCTURE
  RET
NESTED_END Pal_PrintWord, _TEXT$00





END