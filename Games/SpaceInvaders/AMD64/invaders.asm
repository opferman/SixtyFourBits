;*********************************************************
; Space Invaders Game
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/8/2019
;
;
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include dbuffer_public.inc
include font_public.inc
include input_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc


;*********************************************************
; Structures
;*********************************************************
FIRE_STRUCT struct
   VelocityY dd ?
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
FIRE_STRUCT ends

EXPLODE_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   SpriteCountdown dd ?
   Sprite      SPRITE_STRUCT <?>
EXPLODE_STRUCT ends

SPRITE_STRUCT struct
   SpriteIndex dd ?
   SpritePtr   dq ?
   SpriteMaxX  dd ?
   SpriteMaxY  dd ?
SPRITE_STRUCT ends

ALIEN_SPRITE_STRUCT struct
   LocationX   dd ?
   LocationY   dd ?
   Sprite      SPRITE_STRUCT <?>
ALIEN_SPRITE_STRUCT ends

PLAYER_SPRITE_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
PLAYER_SPRITE_STRUCT ends

SPACE_SHIP_STRUCT struct
   LocationX dd ?
   LocationY dd ?
   Sprite      SPRITE_STRUCT <?>
SPACE_SHIP_STRUCT ends

SHEILD_SPRITE_STRUCT struct
   LocationX         dd ?
   LocationY         dd ?
   DestructCountDown dd ?
   Sprite      SPRITE_STRUCT <?>
SHEILD_SPRITE_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Invaders_Init
public Invaders_FrameStateMachine
public Invaders_Free

;
; Space Invaders State Machine
;
SPACE_INVADERS_STATE_INTRO EQU <0>
SPACE_INVADERS_STATE_MENU  EQU <1>
SPACE_INVADERS_LEVEL       EQU <2>
SPACE_INVADERS_FINAL       EQU <3>
SPACE_INVADERS_GAMEPLAY    EQU <4>
SPACE_INVADERS_HISCORE     EQU <5>


MAX_SCORES EQU  <5>
MAX_SHIELDS EQU <3>
MAX_ALIENS_PER_ROW EQU <>
MAX_ALIEN_ROWS     EQU <>

;*********************************************************
; Data Segment
;*********************************************************
.DATA
    DoubleBuffer       dq ?
    SpaceInvadersState dq ?
    SpaceCurrentLevel  dq ?

    ThePlayer          PLAYER_SPRITE_STRUCT ?
    TheSpaceShip       SPACE_SHIP_STRUCT    ?
    Aliens             ALIEN_SPRITE_STRUCT (MAX_ALIENS_PER_ROW*MAX_ALIEN_ROWS) DUP(<0>)
    TheShields         SHEILD_SPRITE_STRUCT MAX_SHIELDS DUP(<0>)
    HiScoreList        dq MAX_SCORES DUP(<0>)
.CODE

;*********************************************************
;   Invaders_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, 4
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL DBuffer_Create
  CMP EAX, 0
  JE @FailureExit
  MOV [DoubleBuffer], RAX
  DEBUG_FUNCTION_CALL Invaders_LoadSPrites
  DEBUG_FUNCTION_CALL Invaders_LoadGraphics


@SuccessExit:
  MOV EAX, 1
  JMP @ActualExit  
@FailureExit:
  XOR EAX, EAX
@ActualExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
  RET

NESTED_END Invaders_Init, _TEXT$00


;*********************************************************
;   Invaders_FrameStateMachine
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_FrameStateMachine, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
  RET

NESTED_END Invaders_FrameStateMachine, _TEXT$00


;*********************************************************
;   Invaders_Free
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Invaders_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX




  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
  RET

NESTED_END Invaders_Free, _TEXT$00



;*********************************************************
;  SpaceInvaders_PrintWord
;
;        Parameters: Master Context, String, X, Y, Font Size, Radians, Color
;
;       
;
;
;*********************************************************  
NESTED_ENTRY SpaceInvaders_PrintWord, _TEXT$00
 alloc_stack(SIZEOF FRACTAL_DEMO_STRUCTURE)
 save_reg rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi
 save_reg rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi
 save_reg rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx
 save_reg rbp, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbp
 save_reg r14, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR14
 save_reg r15, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR15
 save_reg r12, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR12
 save_reg r13, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR13
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP], xmm6
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP], xmm7
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP], xmm8
 MOVAPS FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP], xmm9
.ENDPROLOG 
 DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX ; Master Context
  MOV R15, RDX ; String
  MOV R14, R8  ; X Location
  MOV R12, R9  ; Y Location
  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param3[RSP], R12

@Plasma_PrintStringLoop:
  ;
  ; Get the Bit Font
  ;
  XOR RCX, RCX
  MOV CL, [R15]
  DEBUG_FUNCTION_CALL Font_GetBitFont
  TEST RAX, RAX
  JZ @ErrorOccured

  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP], RAX
  MOV RSI, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  MOV FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 8


@VerticleLines:
       MOV BL, 80h
       MOV R13, R14

@HorizontalLines:
           MOV RAX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
           TEST BL, [RAX]
           JZ @NoPixelToPlot 

           MOV  FRACTAL_DEMO_STRUCTURE_FUNC.LocalVariables.LocalVar1[RSP], RBX

           ;
           ; Let's get the Font Size in R9
           ;
           MOV R9, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
		   

@PlotRotatedPixel:
              MOV  FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param4[RSP], R9

			  MOV RAX, R14 ; X
			  MOV  R8, R12  ; Y


			  JMP @PlotPixel
			  ;
			  ; Rotate
			  ;
			  ;
			  ; cos(r)*x - sin(r)*y
			  ;
			  CVTSI2SD xmm6, R14 ; X
			  CVTSI2SD xmm7, R12 ; Y

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  SUBSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  SUBSD xmm6, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL cos
			  MULSD xmm0, xmm6
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm7
			  SUBSD xmm9, xmm0

			  ;
			  ; (sin(r)*x + cos(r)*y)
			  ;
			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL Sin
			  MULSD xmm0, xmm6
			  MOVSD xmm6, xmm9
			  MOVSD xmm9, xmm0

			  MOVSD xmm0, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param6[RSP]
			  DEBUG_FUNCTION_CALL cos
			  MULSD xmm0, xmm7
			  ADDSD xmm0, xmm9
			  MOVSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  ADDSD xmm7, xmm0

			  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHR RAX, 1
			  CVTSI2SD xmm0, RAX
			  ADDSD xmm6, xmm0

			  CVTTSD2SI RAX, xmm6 ; X
			  CVTTSD2SI R8, xmm7  ; Y

@PlotPixel:

			  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  JAE @PixelOffScreen

			  CMP R8, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
			  JAE @PixelOffScreen

			  MOV RCX, R8
			  IMUL RCX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
			  SHL RAX, 2
			  SHL RCX, 2
			  ADD RCX, RAX
			  ADD RCX, [DoubleBuffer]
                          MOV RAX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param7[RSP]
			  MOV DWORD PTR [RCX], EAX

@PixelOffScreen:
			INC R14
			MOV  RBX, FRACTAL_DEMO_STRUCTURE_FUNC.LocalVariables.LocalVar1[RSP]
			MOV  R9, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param4[RSP]
			DEC R9
			JNZ @PlotRotatedPixel
			JMP @DonePlottingPixel

@NoPixelToPlot:
        ADD R14, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
@DonePlottingPixel:
    SHR BL, 1
    TEST BL, BL
    JNZ @HorizontalLines

  MOV R14, R13
  INC R12
  DEC RSI
  JNZ @VerticleLines
  
  MOV RSI, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  INC FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param1[RSP]
  DEC FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP]
  CMP FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param2[RSP], 0
  JA @VerticleLines

  MOV R12, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param3[RSP]
  

  INC R15

  MOV RCX, FRACTAL_DEMO_STRUCTURE_FUNC.FuncParams.Param5[RSP]
  SHL RCX, 3
  ADD R14, RCX
  ADD R14, 3
 
  CMP BYTE PTR [R15], 0 
  JNE @Plasma_PrintStringLoop


  MOV EAX, 1
@ErrorOccured:
 MOVAPS xmm6,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm6[RSP]
 MOVAPS xmm7,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm7[RSP]
 MOVAPS xmm8,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm8[RSP]
 MOVAPS xmm9,  FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveXmm9[RSP]
  MOV rdi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRdi[RSP]
  MOV rsi, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRsi[RSP]
  MOV rbx, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbx[RSP]
  MOV rbp, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveRbp[RSP]
  MOV r14, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR14[RSP]
  MOV r15, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR15[RSP]
  MOV r12, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR12[RSP]
  MOV r13, FRACTAL_DEMO_STRUCTURE.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE FRACTAL_DEMO_STRUCTURE
  RET
NESTED_END SpaceInvaders_PrintWord, _TEXT$00





END