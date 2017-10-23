;*********************************************************
; Double Buffer Library
;
;  Written in Assembly x64
; 
;  By Toby Opferman  9/20/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include dbuffer_flags.inc
include debug_public.inc
include master.inc
include vpal_public.inc

PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveR12        dq ?
	SaveRbp        dq ?
    SaveR13        dq ?
    SaveR14        dq ?
    SaveR15        dq ?
SAVEFRAME ends

DB_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
DB_INIT_LOCALS ends

DBUFFER_HANDLE struct
     MasterContext dq ?
	 BytesPerPixel dq ?
DBUFFER_HANDLE ends

extern LocalAlloc:proc
extern LocalFree:proc

public Dbuffer_Free
public Dbuffer_UpdateScreen
public DBuffer_Create
public Dbuffer_ClearBuffer

.CODE

;*********************************************************
;   DBuffer_Create
;
;        Parameters: Master Context, bytes per pixel (1, 2, 4, 8)
;
;        Return Value: Double Buffer
;
;
;*********************************************************  
NESTED_ENTRY DBuffer_Create, _TEXT$00
  alloc_stack(SIZEOF DB_INIT_LOCALS)
  save_reg rdi, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rbp, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp
.ENDPROLOG 
  
  MOV RDI, RCX
  MOV RBP, RDX

  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
  XOR RDX, RDX
  MUL RCX
  MOV RDX, RBP
  SHR RDX, 1
  CMP RDX, 4
  JB @SkipAdjustment
  SUB RDX, 1
@SkipAdjustment:
  MOV CL, DL
  SHL RAX, CL
  MOV RDX, SIZEOF DBUFFER_HANDLE
  ADD RDX, RAX  
  MOV RCX, 040h 
  DEBUG_FUNCTION_CALL LocalAlloc
  TEST RAX, RAX
  JZ @AllocationFailed

  MOV DBUFFER_HANDLE.MasterContext[RAX], RDI
  MOV DBUFFER_HANDLE.BytesPerPixel[RAX], RBP
  ADD RAX, SIZEOF DBUFFER_HANDLE

 @AllocationFailed:
  MOV RDI, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV RBP, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp[RSP]
  ADD RSP, SIZE DB_INIT_LOCALS
  RET

NESTED_END DBuffer_Create, _TEXT$00



;*********************************************************
;  Dbuffer_Free
;
;        Parameters: Buffer 
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Dbuffer_Free, _TEXT$00
  alloc_stack(SIZEOF DB_INIT_LOCALS)
  save_reg rdi, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 

  SUB RCX, SIZEOF DBUFFER_HANDLE
  DEBUG_FUNCTION_CALL LocalFree

@DoneFreeing:
  MOV RDI, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE DB_INIT_LOCALS
  RET
NESTED_END Dbuffer_Free, _TEXT$00



;*********************************************************
;  Dbuffer_UpdateScreen
;
;        Parameters: Buffer, Virtual Pallete (optional), Flags
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Dbuffer_UpdateScreen, _TEXT$00
  alloc_stack(SIZEOF DB_INIT_LOCALS)
  save_reg rdi, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, DB_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r12, DB_INIT_LOCALS.SaveRegsFrame.SaveR12
  save_reg r13, DB_INIT_LOCALS.SaveRegsFrame.SaveR13
  save_reg r14, DB_INIT_LOCALS.SaveRegsFrame.SaveR14
  save_reg r15, DB_INIT_LOCALS.SaveRegsFrame.SaveR15
  save_reg rbp, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp
.ENDPROLOG 

  MOV R13, RCX
  SUB RCX, SIZEOF DBUFFER_HANDLE
  MOV RDI, DBUFFER_HANDLE.MasterContext[RCX]
  MOV RSI, MASTER_DEMO_STRUCT.VideoBuffer[RDI]
  MOV R15, RDX
  MOV RBP, R8

  XOR r14, r14
  XOR r12, r12

  CMP DBUFFER_HANDLE.BytesPerPixel[RCX], 1
  JE @FillScreen_1Byte

  CMP DBUFFER_HANDLE.BytesPerPixel[RCX], 2
  JE @FillScreen_2Bytes

  CMP DBUFFER_HANDLE.BytesPerPixel[RCX], 4
  JE @FillScreen_4Bytes

  CMP DBUFFER_HANDLE.BytesPerPixel[RCX], 8
  JE @FillScreen_8Bytes

  JMP @DoneUpdate
  


@FillScreen_1Byte:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
	  XOR EAX, EAX

      MOV AL, BYTE PTR [r13] 

	  TEST RBP, DB_FLAG_CLEAR_BUFFER 
	  JZ @SkipClearingBuffer1
	  
	  MOV BYTE PTR [R13], DL

@SkipClearingBuffer1:    

	  CMP RAX, 0
	  JNZ @SkipZeroFlagCheck1

	  TEST RBP, DB_FLAG_TRANSPARENT_ZERO 
	  JNZ @SkipPlottingPixel1

	  TEST RBP, DB_FLAG_ZERO_IGNORES_PAL 
	  JNZ @PlotPixel1

@SkipZeroFlagCheck1:
	  CMP R15, 0
	  JE @PlotPixel1

	  MOV RDX, RAX
      MOV RCX, R15
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

@PlotPixel1:
      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX
@SkipPlottingPixel1:

      ; Increment to the next location
      ADD RSI, 4
      INC r13
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen_1Byte

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen_1Byte

 JMP @DoneUpdate


@FillScreen_2Bytes:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
	  XOR EAX, EAX

      MOV AX, WORD PTR [r13] 

	  TEST RBP, DB_FLAG_CLEAR_BUFFER 
	  JZ @SkipClearingBuffer2
	  
	  MOV WORD PTR [R13], DX

@SkipClearingBuffer2:    

	  CMP RAX, 0
	  JNZ @SkipZeroFlagCheck2

	  TEST RBP, DB_FLAG_TRANSPARENT_ZERO 
	  JNZ @SkipPlottingPixel2

	  TEST RBP, DB_FLAG_ZERO_IGNORES_PAL 
	  JNZ @PlotPixel2

@SkipZeroFlagCheck2:

	  CMP R15, 0
	  JE @PlotPixel2

	  MOV RDX, RAX
      MOV RCX, R15
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

@PlotPixel2:
      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX
@SkipPlottingPixel2:

      ; Increment to the next location
      ADD RSI, 4
      ADD R13, 2
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen_2Bytes

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen_2Bytes

 JMP @DoneUpdate

 @FillScreen_4Bytes:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
	  XOR EAX, EAX

      MOV EAX, DWORD PTR [r13] 

	  TEST RBP, DB_FLAG_CLEAR_BUFFER 
	  JZ @SkipClearingBuffer4
	  
	  MOV DWORD PTR [R13], EDX

@SkipClearingBuffer4:    

	  CMP RAX, 0
	  JNZ @SkipZeroFlagCheck4

	  TEST RBP, DB_FLAG_TRANSPARENT_ZERO 
	  JNZ @SkipPlottingPixel4

	  TEST RBP, DB_FLAG_ZERO_IGNORES_PAL 
	  JNZ @PlotPixel4

@SkipZeroFlagCheck4:
	  CMP R15, 0
	  JE @PlotPixel4

	  MOV EDX, EAX
      MOV RCX, R15
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

@PlotPixel4:
      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX
@SkipPlottingPixel4:

      ; Increment to the next location
      ADD RSI, 4
      ADD R13, 4
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen_4Bytes

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen_4Bytes

 JMP @DoneUpdate

 @FillScreen_8Bytes:
      ;
      ; Get the Virtual Pallete Index for the pixel on the screen
      ;
      XOR EDX, EDX
	  XOR EAX, EAX


      MOV RAX, QWORD PTR [r13] 

	  TEST RBP, DB_FLAG_CLEAR_BUFFER 
	  JZ @SkipClearingBuffer8
	  
	  MOV QWORD PTR [R13], RDX

@SkipClearingBuffer8:    

	  CMP RAX, 0
	  JNZ @SkipZeroFlagCheck8

	  TEST RBP, DB_FLAG_TRANSPARENT_ZERO 
	  JNZ @SkipPlottingPixel8

	  TEST RBP, DB_FLAG_ZERO_IGNORES_PAL 
	  JNZ @PlotPixel8

@SkipZeroFlagCheck8:

	  CMP R15, 0
	  JE @PlotPixel8

	  MOV RDX, RAX
      MOV RCX, R15
      DEBUG_FUNCTION_CALL VPal_GetColorIndex 

@PlotPixel8:
      ; Plot Pixel
      MOV DWORD PTR [RSI], EAX
@SkipPlottingPixel8:	
  
      ; Increment to the next location
      ADD RSI, 4
      ADD R13, 8
  
      INC r12

      CMP r12, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
      JB @FillScreen_8Bytes

   ; Calcluate Pitch
   MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RDI]
   SHL RAX, 2
   MOV EBX, MASTER_DEMO_STRUCT.Pitch[RDI]
   SUB RBX, RAX
   ADD RSI, RBX

   ; Screen Height Increment

   XOR r12, r12
   INC r14

   CMP r14, MASTER_DEMO_STRUCT.ScreenHeight[RDI]
   JB @FillScreen_8Bytes


@DoneUpdate:
  MOV RDI, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV R15, DB_INIT_LOCALS.SaveRegsFrame.SaveR15[RSP]
  MOV R14, DB_INIT_LOCALS.SaveRegsFrame.SaveR14[RSP]
  MOV R13, DB_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
  MOV R12, DB_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  MOV RBP, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp[RSP]
  MOV RSI, DB_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  ADD RSP, SIZE DB_INIT_LOCALS
  RET
NESTED_END Dbuffer_UpdateScreen, _TEXT$00


;*********************************************************
;  Dbuffer_ClearBuffer
;
;        Parameters: Buffer
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Dbuffer_ClearBuffer, _TEXT$00
  alloc_stack(SIZEOF DB_INIT_LOCALS)
  save_reg rdi, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, DB_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r12, DB_INIT_LOCALS.SaveRegsFrame.SaveR12
  save_reg r13, DB_INIT_LOCALS.SaveRegsFrame.SaveR13
  save_reg r14, DB_INIT_LOCALS.SaveRegsFrame.SaveR14
  save_reg r15, DB_INIT_LOCALS.SaveRegsFrame.SaveR15
  save_reg rbp, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp
.ENDPROLOG 

  MOV RDI, RCX
  MOV RSI, RCX
  SUB RSI, SIZEOF DBUFFER_HANDLE
  MOV RBP, DBUFFER_HANDLE.MasterContext[RSI]

  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RBP]
  XOR RDX, RDX
  MOV RCX, MASTER_DEMO_STRUCT.ScreenHeight[RBP]
  MUL RCX
  MOV RCX, RAX
  XOR RAX, RAX

  CMP DBUFFER_HANDLE.BytesPerPixel[RSI], 1
  JE @ClearScreen

  SHL RCX, 1
  CMP DBUFFER_HANDLE.BytesPerPixel[RSI], 2
  JE @ClearScreen

  SHL RCX, 1
  CMP DBUFFER_HANDLE.BytesPerPixel[RSI], 4
  JE @ClearScreen

  SHL RCX, 1
  CMP DBUFFER_HANDLE.BytesPerPixel[RSI], 8
  JE @ClearScreen

  JMP @DoneClearBuffer
  
@ClearScreen:
  SHR RCX, 3
  REP STOSQ
  
@DoneClearBuffer:
  MOV RDI, DB_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV R15, DB_INIT_LOCALS.SaveRegsFrame.SaveR15[RSP]
  MOV R14, DB_INIT_LOCALS.SaveRegsFrame.SaveR14[RSP]
  MOV R13, DB_INIT_LOCALS.SaveRegsFrame.SaveR13[RSP]
  MOV R12, DB_INIT_LOCALS.SaveRegsFrame.SaveR12[RSP]
  MOV RBP, DB_INIT_LOCALS.SaveRegsFrame.SaveRbp[RSP]
  MOV RSI, DB_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  ADD RSP, SIZE DB_INIT_LOCALS
  RET
NESTED_END Dbuffer_ClearBuffer, _TEXT$00



END

