;*********************************************************
; Plasma Demo 
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

extern cos:proc
extern sin:proc
extern tan:proc

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

    SaveXmm6       oword ? 
    SaveXmm7       oword ? 
    SaveXmm8       oword ? 
    SaveXmm9       oword ? 
    SaveXmm10      oword ? 
    SaveXmm11      oword ? 
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

PLASMA_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
PLASMA_DEMO_STRUCTURE ends

PLASMA_DEMO_STRUCTURE_FUNC struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
   FuncParams     FUNC_PARAMS     <?>
PLASMA_DEMO_STRUCTURE_FUNC ends


public PlasmaDemo_Init
public PlasmaDemo_Demo
public PlasmaDemo_Free



extern time:proc
extern srand:proc
extern rand:proc
extern sqrt:proc

MAX_COLORS equ <65536>
EVAL_NEW_VELOCITY  equ <256>

.DATA

DoubleBuffer   dq ?
VirtualPallete dq ?
FrameCountDown dd 7000
Red            db 0h
Blue           db 0h
Green          db 0h

RedVel          db 0h
BlueVel         db 0h
GreenVel        db 0h

AngleToRaidans mmword 0.0174532925
RadiansY       mmword ?
RadiansX       mmword ?
Variable1      mmword 0.6
Variable2      mmword 0.1
Variable1Inc   mmword 1.34
Variable2Inc   mmword 0.543

.CODE

;*********************************************************
;   PlasmaDemo_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY PlasmaDemo_Init, _TEXT$00
 alloc_stack(SIZEOF PLASMA_DEMO_STRUCTURE)
 save_reg rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12
.ENDPROLOG 
  MOV RSI, RCX

  MOV [VirtualPallete], 0

  MOV RAX,  MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  MOV R9,  MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  MUL R9
  MOV RDX, RAX
  SHL RDX, 1    ; Turn Buffer into WORD values
  MOV ECX, 040h ; LMEM_ZEROINIT
  CALL LocalAlloc
  MOV [DoubleBuffer], RAX
  TEST RAX, RAX
  JZ @PalInit_Failed

  MOV RCX, MAX_COLORS
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

  MOV RAX, EVAL_NEW_VELOCITY
  SUB RAX, 1
  TEST R12, RAX
  JE @Re_Eval_Velocity

  INC R12
  
  MOVZX AX, [Red]
  MOVSX CX, [RedVel]
  ADD AX, CX
  TEST AH, AH
  JZ @BlueColor

  NEG [RedVel]
  MOV AL, [Red]

@BlueColor:
  MOV [Red], AL
  MOVZX AX, [Blue]
  MOVSX CX, [BlueVel]
  ADD AX, CX
  TEST AH, AH
  JZ @GreenColor

  NEG [BlueVel]
  MOV AL, [Blue]
@GreenColor:
  MOV [Blue], AL
  MOVZX AX, [Green]
  MOVSX CX, [GreenVel]
  ADD AX, CX
  TEST AH, AH
  JZ @Next_loop_Check_UpdateGreen
  
  NEG [GreenVel]
  MOV AL, [Green]
@Next_loop_Check_UpdateGreen:
  MOV [Green], AL

@Next_loop_Check:

  CMP R12, MAX_COLORS           ; Fill 65536 Colors in the Pallete.  
  JB @PopulatePallete
  JMP @PaleteComplete

@Re_Eval_Velocity:
  INC R12
   
  CMP [BlueVel], 0
  JE @UpdateBlue

@CheckRedColor:
  CMP [RedVel], 0
  JE @UpdateRed

@CheckGreenColor:
  CMP [GreenVel], 0
  JNE @Next_loop_Check
  
  CALL Rand
  AND AL, 3
  SUB AL, 1
  MOV [GreenVel], AL
   
  JMP @Next_loop_Check
@UpdateBlue:
  CALL Rand
  AND AL, 3
  SUB AL, 1
  MOV [BlueVel], AL
  JMP @CheckRedColor

@UpdateRed:
  CALL Rand
  AND AL, 3
  SUB AL, 1
  MOV [RedVel], AL
  JMP @CheckGreenColor

@PaleteComplete:
  MOV RCX,  RSI
  CALL PlasmaDemo_PerformPlasma


  MOV RSI, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE PLASMA_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@PalInit_Failed:
  MOV RSI, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE PLASMA_DEMO_STRUCTURE
  XOR RAX, RAX
  RET
NESTED_END PlasmaDemo_Init, _TEXT$00






;*********************************************************
;  PlasmaDemo_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY PlasmaDemo_Demo, _TEXT$00
 alloc_stack(SIZEOF PLASMA_DEMO_STRUCTURE)
 save_reg rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR13

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
      MOV DX, WORD PTR [r13] ; Get Virtual Pallete Index
      
      XOR EAX, EAX

      MOV RCX, [VirtualPallete]
      CALL VPal_GetColorIndex 
      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX


@ContinuePLotting:
      ; Increment to the next location
      ADD RSI, 4
      Add R13, 2
  
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

  MOV RCX,  RDI
  CALL PlasmaDemo_PerformPlasma

  MOV RDX, 10
  MOV RCX,  [VirtualPallete]
  call VPal_Rotate

 
@DemoExit:
    
   MOV rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
   MOV rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
   MOV rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

   MOV r10, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
   MOV r11, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
   MOV r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
   MOV r13, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

   ADD RSP, SIZE PLASMA_DEMO_STRUCTURE
  
   DEC [FrameCountDown]
   MOV EAX, [FrameCountDown]
   RET
NESTED_END PlasmaDemo_Demo, _TEXT$00


;*********************************************************
;  PlasmaDemo_PerformPlasma
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY PlasmaDemo_PerformPlasma, _TEXT$00
 alloc_stack(SIZEOF PLASMA_DEMO_STRUCTURE)
 save_reg rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR13 
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP], xmm6
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP], xmm7
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP], xmm8
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP], xmm9
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm10[RSP], xmm10
 MOVAPS PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm11[RSP], xmm11
 .ENDPROLOG 

  MOV RDI, RCX

  MOV RSI, [DoubleBuffer]
  XOR R12, R12
  
 @Plasma_LoopForHeight:  
    
    XOR R13, R13

    MOVSD xmm0, [AngleToRaidans]
    cvtsi2sd xmm1,R12

    MULSD xmm0, xmm1
    MOVSD [RadiansY], xmm0

    
   @Plasma_LoopForWidth:


       MOVSD xmm0, [AngleToRaidans]  
       cvtsi2sd xmm1,R13 
       MULSD xmm0, xmm1
       MOVSD [RadiansX], xmm0
              
  	   CMP [FrameCountDown], 4500
	   JB @NewPath2

       MOVSD xmm0, [RadiansY]
       ADDSD xmm0, [Variable2]
       CALL cos
       MOVSD xmm6, xmm0

	   CMP [FrameCountDown], 5000
	   JB @NewPath2

       MOVSD xmm0, [RadiansX]
       ADDSD xmm0, [Variable1]
       CALL sin
       ADDSD xmm6, xmm0

       MOVSD xmm0, [RadiansX]
       ADDSD xmm0, [Variable2]
       CALL cos
       ADDSD xmm6, xmm0 

       MOVSD xmm0, [RadiansY]
       ADDSD xmm0, [Variable1]
       CALL sin
       ADDSD xmm6, xmm0

	   CMP [FrameCountDown], 6500
	   JB @NewPath

       MOVSD xmm0, [RadiansX]
       ADDSD xmm0, [Variable1]
       CALL cos
       ADDSD xmm6, xmm0

       MOVSD xmm0, [RadiansY]
       ADDSD xmm0, [Variable2]
       CALL sin
       ADDSD xmm6, xmm0

       MOVSD xmm0, [RadiansY]
       ADDSD xmm0, [RadiansX]
       CALL cos
       ADDSD xmm6, xmm0


	   JMP @Skip_Update

@NewPath2:
      MOVSD xmm0, [RadiansY]
	  ADDSD xmm0, [Variable1]
	  CALL sin
	  MULSD xmm0, [RadiansX]
	  ADDSD xmm6, xmm0

      MOVSD xmm0, [RadiansX]
	  ADDSD xmm0, [Variable2]
	  CALL cos
	  MULSD xmm0, [RadiansY]
	  ADDSD xmm6, xmm0
	  	   JMP @Skip_Update
@NewPath:

       MOVSD xmm0, [RadiansY]
	   ADDSD xmm0, [RadiansX]
       CALL cos
       ADDSD xmm6, xmm0


@Skip_Update:

	   cvttsd2si RAX, xmm6
       ADD [RSI], AX

@ContinuePlasma:
       ADD RSI, 2
          
       INC R13
       CMP R13, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
       JB @Plasma_LoopForWidth

   INC R12
   CMP R12, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @Plasma_LoopForHeight


   MOVSD xmm0, [Variable1Inc]
   MOVSD xmm1, [Variable1]
   ADDSD xmm0, xmm1
   MOVSD [Variable1], xmm0

   MOVSD xmm0, [Variable2Inc]
   MOVSD xmm1, [Variable2]
   ADDSD xmm0, xmm1
   MOVSD [Variable2], xmm0

   MOVSD xmm0, [Variable2Inc]
   MOVSD xmm1, [Variable1Inc]
   SUBSD xmm0, xmm1
   ADDSD xmm1, xmm0
   MOVSD [Variable2Inc], xmm1
   MOVSD [Variable1Inc], xmm0

   MOV EAX,[FrameCountDown]
   AND EAX, 0FFh
   CMP EAX, 0
   JNE @NoUpate
   cvttsd2si RAX, [Variable2Inc]
   cvtsi2sd xmm0, RAX
   MOVSD xmm1, [Variable2Inc]
   SUBSD xmm1, xmm0
   MOVSD [Variable2Inc], xmm1

   cvttsd2si RAX, [Variable1Inc]
   cvtsi2sd xmm0, RAX
   MOVSD xmm1, [Variable1Inc]
   SUBSD xmm1, xmm0
   MOVSD [Variable1Inc], xmm1

   NEG  [Variable2Inc]
   NEG  [Variable1Inc]

@NoUpate:

   MOV rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
   MOV rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
   MOV rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

   MOV r10, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
   MOV r11, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
   MOV r12, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
   MOV r13, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

   MOVAPS xmm6, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP]
   MOVAPS xmm7, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP]
   MOVAPS xmm8, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP]
   MOVAPS xmm9, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP]
   MOVAPS xmm10, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm10[RSP]
   MOVAPS xmm11, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveXmm11[RSP]
      

  ADD RSP, SIZE PLASMA_DEMO_STRUCTURE
  RET
NESTED_END PlasmaDemo_PerformPlasma, _TEXT$00


;*********************************************************
;  PlasmaDemo_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY PlasmaDemo_Free, _TEXT$00
 alloc_stack(SIZEOF PLASMA_DEMO_STRUCTURE)
 save_reg rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [DoubleBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, PLASMA_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE PLASMA_DEMO_STRUCTURE
  RET
NESTED_END PlasmaDemo_Free, _TEXT$00









END