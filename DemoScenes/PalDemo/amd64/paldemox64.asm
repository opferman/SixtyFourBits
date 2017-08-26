;*********************************************************
; Pal Demo 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  2/27/2010
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

FIRE_DEMO_STRUCTURE struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
FIRE_DEMO_STRUCTURE ends

public PalDemo_Init
public PalDemo_Demo
public PalDemo_Free

extern time:proc
extern srand:proc
extern rand:proc

INFALTE_FONT EQU <12>
WORD_DELAY EQU <2>

.DATA
				   
				  DoubleBuffer   dq  ?
				  VirtualPallete dq ?

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
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
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
  JZ @FireInit_Failed

  MOV RCX, 256
  CALL VPal_Create
  TEST RAX, RAX
  JZ @FireInit_Failed

  MOV [VirtualPallete], RAX

  
@PopulatePalleteBlue:

  XOR EAX, EAX

 ; Red
  MOV AL, BYTE PTR [RDI]  
  SHL EAX, 16
  INC RDI

  ; Green
  MOV AL, BYTE PTR [RDI]
  SHL AX, 8
  INC RDI

  ; Blue
  MOV AL, BYTE PTR [RDI]
  INC RDI

  MOV R8, RAX
  MOV R12, RDX
  MOV RCX, [VirtualPallete]
  CALL VPal_SetColorIndex

  MOV RDX, R12
  INC RDX
  CMP RDX, 256
  JB @PopulatePallete

 
  MOV RCX, RSI
  CALL PalDemo_FillScreen


  MOV RSI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  MOV EAX, 1
  RET

@FireInit_Failed:
  MOV RSI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV RDI, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  XOR RAX, RAX
  RET
NESTED_END Fire_Init, _TEXT$00



;*********************************************************
;  Fire_Demo
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_Demo, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13

.ENDPROLOG 
  MOV RDI, RCX

  ;
  ; Plot The New Pixels
  ;  
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV r13, [FireBuffer]

  XOR R9, R9
  XOR r12, r12

@FillScreen:
      ;
	  ; Get the Virtual Pallete Index for the pixe on the screen
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



  MOV RCX, RDI
  CALL Fire_RandomFillBottom

  MOV RCX, RDI
  CALL Fire_MoveFire

  CMP [FrameCountDown], 0b1h
  JBE @SkipWord

  MOV RCX, [FrameNumber]
  INC RCX
  MOV [FrameNumber], RCX
  CMP RCX, WORD_DELAY
  JB @SkipWord

  LEA RDX, [TestString]
  MOV RCX, RDI
  MOV R8D, [LocationX]
  MOV R9D, [LocationY]
  CALL Fire_PrintWord

  LEA RDX, [TestString]
  MOV RCX, RDI
  MOV R8D, [LocationX2]
  MOV R9D, [LocationY2] 
  CALL Fire_PrintWord


  MOV R8D, [DirectionX]
  ADD [LocationX], R8D
  MOV R8D, [DirectionY]
  ADD [Locationy], R8D

  CMP [LocationY], 1 
  JG @NextYTest

  MOV [LocationY], 1
  NEG [DirectionY]
  INC [DirectionY]
  JMP @StartXTests
@NextYTest:
  CMP [LocationY], 655 
  Jl @StartXTests

  MOV [LocationY], 655
  INC [DirectionY]
  NEG [DirectionY]
  JMP @StartXTests  

@StartXTests:
  CMP [LocationX], 1 
  JG @NextXTest

  MOV [LocationX], 1

  NEG [DirectionX]
  INC [DirectionX]

  JMP @DoSecondSet
@NextXTest:
  CMP [LocationX], 928 
  Jl  @DoSecondSet

  MOV [LocationX], 928
  INC [DirectionX]
  NEG [DirectionX]

@DoSecondSet:

  MOV R8D, [DirectionX2]
  ADD [LocationX2], R8D
  MOV R8D, [DirectionY2]
  ADD [Locationy2], R8D

  CMP [LocationY2], 1 
  JG @NextYTest2

  MOV [LocationY2], 1
  NEG [DirectionY2]
  INC [DirectionY2]
  JMP @StartXTests2
@NextYTest2:
  CMP [LocationY2], 655 
  Jl @StartXTests2

  MOV [LocationY2], 655
  INC [DirectionY2]
  NEG [DirectionY2]
  

@StartXTests2:
  CMP [LocationX2], 1 
  JG @NextXTest2

  MOV [LocationX2], 1

  NEG [DirectionX2]
  INC [DirectionX2]

  JMP @DoFrameReset
@NextXTest2:
  CMP [LocationX2], 928 
  Jl  @DoFrameReset

  MOV [LocationX2], 928
  INC [DirectionX2]
  NEG [DirectionX2]
  
 @DoFrameReset:

  MOV [FrameNumber], 0

@SkipWord:
 
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  MOV r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  
  DEC [FrameCountDown]
  MOV EAX, [FrameCountDown]
  RET
NESTED_END Fire_Demo, _TEXT$00



;*********************************************************
;  Fire_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_Free, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
.ENDPROLOG 

 MOV RCX, [VirtualPallete]
 CALL VPal_Free

  MOV RCX, [FireBuffer]
  TEST RCX, RCX
  JZ @SkipFreeingMem

  CALL LocalFree
 @SkipFreeingMem:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_Free, _TEXT$00



;*********************************************************
;  Fire_RandomFillBottom
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_RandomFillBottom, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
  save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  MOV RDI, RCX
    
  MOV R11, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  SUB RAX, 2
  MUL R11
  SHL R11, 1

  MOV R10, [FireBuffer]
  ADD R10, RAX

  CMP [FrameCountDown], 045h
  JBE @BlackOut

@FillBottomRow:
  CALL rand
  MOV RCX, 256
  DIV RCX
  
  MOV BYTE PTR [R10], DL  ; Remainder
  INC R10
  DEC R11
  JNZ @FillBottomRow  

@ExitFunction:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
@BlackOut:

 
  MOV BYTE PTR [R10], 0 ; Blackout
  INC R10
  DEC R11
  JNZ @BlackOut

  JMP @ExitFunction

NESTED_END Fire_RandomFillBottom, _TEXT$00


;*********************************************************
;  Fire_PrintWord
;
;        Parameters: Master Context, String, X, Y, BOOL TRUE = Clear
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_PrintWord, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  MOV RDI, RCX
  MOV R10, RDX
  MOV R11, R8
  MOV R12, R9

@Fire_PrintStringLoop:

  XOR RCX, RCX
  MOV CL, [R10]
  CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured
  MOV RCX, [FireBuffer]
  MOV R13, RAX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  XOR RDX, RDX
  MUL R12  
  ADD RCX, RAX
  MOV RAX, R13
  XOR RDX, RDX
  ADD RCX, R11
  XOR R13, R13
  MOV RSI, INFALTE_FONT
@VerticleLines:
  MOV BL, 80h
@HorizontalLines:
  TEST BL, [RAX]
  JZ @SkipBit
  ; Match INFALTE_FONT
  MOV DWORD PTR [RCX+RDX],   0FEFFCFFFh  
  MOV DWORD PTR [RCX+RDX+4], 0FFCFFFFEh
  MOV DWORD PTR [RCX+RDX+8], 0F6FEFFDFh  
@SkipBit:
  ADD RDX, INFALTE_FONT
  SHR BL, 1
  TEST BL, BL
  JNZ @HorizontalLines
  XOR RDX, RDX
  ADD RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  DEC RSI
  JNZ @VerticleLines 
  MOV RSI, INFALTE_FONT
  INC RAX
  INC R13
  CMP R13, 8
  JB @VerticleLines
  INC R10
  ADD R11, INFALTE_FONT * 8 + 3
  CMP BYTE PTR [R10], 0 
  JNE @Fire_PrintStringLoop
  MOV EAX, 1
@ErrorOccured:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_PrintWord, _TEXT$00




;*********************************************************
;  Fire_MoveFire
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Fire_MoveFire, _TEXT$00
 alloc_stack(SIZEOF FIRE_DEMO_STRUCTURE)
 save_reg rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10
 save_reg r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11
 save_reg r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13
.ENDPROLOG 
  MOV RDI, RCX

  ;
  ; Start from the second to bottom row
  ;    
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  SUB RAX, 2
 
  ;
  ; Start at the second pixel inward.
  ;
  MOV R10, [FireBuffer]
  ADD R10, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  INC R10

  MOV R11, RAX
  MOV RBX, RCX

  XOR R8, R8

@MoveFireUp:
	  XOR RDX, RDX
	  CALL rand
	  MOV RCX, 3
	  DIV RCX

	  MOV [TopWind], DL
	  
	  CALL rand
	  MOV RCX, 3
	  DIV RCX

	  XOR ECX, ECX
	  XOR EAX, EAX
	  	      
	  ;
	  ; Get the pixels to determine the fire.  
	  ;      
	  ;  The algorithm is (P+P+P+P/4 = N-1)
	  ;
	  ;  Two Wind Options.
	  ;
	  ;             N     N      N
	  ;            PPP    PPP  PPP
	  ;             P       P  P



	  MOV CL, [R10]
	  MOV AL, CL
  
	  MOV CL, [R10+1]
	  ADD EAX, ECX
  
	  MOV CL, [R10-1]
	  ADD EAX, ECX

	  ;
	  ; Update for Wind
	  ;
	  DEC RDX
	  ADD RDX, RBX
	  MOV CL, [R10+RDX]

	  ADD EAX, ECX
	  SHR EAX, 2

	  OR AL, AL
	  JZ @PlotPixel

	  DEC AL     ; Decay Pixels

@PlotPixel:
	  ;
	  ; Plot New Pixel
	  ;
	  MOV R12, R10
	  SUB R12, RBX

	  ;
	  ; Implement the Top Wind.
	  ;
	  XOR EDX, EDX
	  MOV DL, [TopWind]
	  DEC RDX
	  ADD R12, RDX       

	  ;
	  ; Plot the pixel
	  ;
	  MOV BYTE PTR [R12], AL

	  INC R10
	  INC R8
	  MOV RCX, RBX
	  DEC RCX
	  CMP R8, RCX
	  JB @MoveFireUp 

  XOR R8, R8
  ;
  ; Start at the second pixel inward.
  ;

  MOV RBX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  INC R10
  
  DEC R11
  JNZ  @MoveFireUp


 @SkipFreeingMem:
  MOV rdi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FIRE_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV r10, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR10[RSP]
  MOV r11, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR11[RSP]
  MOV r12, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FIRE_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FIRE_DEMO_STRUCTURE
  RET
NESTED_END Fire_MoveFire, _TEXT$00
END