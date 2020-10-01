;*********************************************************
; Virtual Pallete Library 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  4/22/2017
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc


PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEFRAME struct
    SaveRdi        dq ?
    SaveRbx        dq ?
    SaveR15        dq ?
    SaveRsi        dq ?
    SaveR12        dq ?
SAVEFRAME ends

VPAL_INIT_LOCALS struct
   ParameterFrame PARAMFRAME <?>
   SaveRegsFrame  SAVEFRAME  <?>
VPAL_INIT_LOCALS ends

VPAL_HANDLE struct
   NumberIndexes dq  ?
   PalettePtr    dq  ?
   RotateIndex   dq  ?
VPAL_HANDLE ends

extern LocalAlloc:proc
extern LocalFree:proc

public VPal_SetColorIndex
public VPal_Create
public VPal_GetColorIndex
public VPal_Free
public VPal_Rotate
public VPal_RotateReset
public VPal_FindColorIndex
public VPal_CopyIndexRange
public VPal_MoveColorIndexes
public VPal_Transparent
public VPal_DirectAccess

.CODE

;*********************************************************
;   VPal_Create
;
;        Parameters: Number of Pallete Indexes
;
;        Return Value: Pallete Handle
;
;
;*********************************************************  
NESTED_ENTRY VPal_Create, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 
  
  MOV RDI, RCX

  MOV RDX, SIZEOF VPAL_HANDLE
  MOV RCX, 040h 
  CALL LocalAlloc
  TEST RAX, RAX
  JZ @AllocationFailed

  MOV VPAL_HANDLE.NumberIndexes[RAX], RDI
  MOV RDX, RDI
  SHL RDX, 2
  MOV RDI, RAX
  MOV RCX, 040h
  CALL LocalAlloc
  TEST RAX, RAX
  JZ @AllocationFailed2

  MOV VPAL_HANDLE.PalettePtr[RDI], RAX
  MOV RAX, RDI
  JMP @ExitCreateFunc

@AllocationFailed2:
  MOV RCX, RDI
  CALL LocalFree
@AllocationFailed:  
@ExitCreateFunc:  
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET

NESTED_END VPal_Create, _TEXT$00



;*********************************************************
;  VPal_SetColorIndex
;
;        Parameters: Palette Handle, Palette Index, DWORD Color (0RGB)
;
;       
;        return TRUE or FALSE
;
;*********************************************************  
NESTED_ENTRY VPal_SetColorIndex, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 
  
  XOR RAX, RAX
  CMP VPAL_HANDLE.NumberIndexes[RCX], RDX
  JBE @ExitFunctionSet

  MOV RCX, VPAL_HANDLE.PalettePtr[RCX]
  SHL RDX, 2
  ADD RCX, RDX
  MOV DWORD PTR [RCX], R8D
 
 @ExitFunctionSet:
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_SetColorIndex, _TEXT$00


;*********************************************************
;  VPal_GetColorIndex
;
;        Parameters: Palette Handle, Palette Index
;
;       return DWORD (0RGB)
;
;
;*********************************************************  
NESTED_ENTRY VPal_GetColorIndex, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 
  
  XOR RAX, RAX
  CMP VPAL_HANDLE.NumberIndexes[RCX], RDX
  JBE @ExitFunctionGet
  MOV RDI, RCX
  CALL VPal_GetRotatedIndex
  MOV RDX, RAX
  MOV RCX, RDI

  MOV RCX, VPAL_HANDLE.PalettePtr[RCX]
  SHL RDX, 2
  ADD RCX, RDX
  MOV EAX, DWORD PTR [RCX]
 
 @ExitFunctionGet:
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_GetColorIndex, _TEXT$00


;*********************************************************
;  VPal_CopyIndexRange
;
;        Parameters: Palette Handle, Start Index Source, Start Index Destination, Number
;
;       return None
;
;
;*********************************************************  
NESTED_ENTRY VPal_CopyIndexRange, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi
.ENDPROLOG 
  
  MOV RAX, R9
  ADD RAX, RDX
  CMP VPAL_HANDLE.NumberIndexes[RCX], RAX
  JBE @ExitFunctionGet

  MOV RAX, R9
  ADD RAX, R8
  CMP VPAL_HANDLE.NumberIndexes[RCX], RAX
  JBE @ExitFunctionGet

  MOV RSI, VPAL_HANDLE.PalettePtr[RCX]
  SHL RDX, 2
  ADD RSI, RDX

  MOV RDI, VPAL_HANDLE.PalettePtr[RCX]
  SHL R8, 2
  ADD RDI, R8
  
  MOV RCX, R9
  REP MOVSD
@ExitFunctionGet:
  MOV RSI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_CopyIndexRange, _TEXT$00


;*********************************************************
;  VPal_MoveColorIndexes
;
;        Parameters: Palette Handle,  Distance Left, Index Source,  Index Destination
;
;       return None
;
;
;*********************************************************  
NESTED_ENTRY VPal_MoveColorIndexes, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r15, VPAL_INIT_LOCALS.SaveRegsFrame.SaveR15
.ENDPROLOG 
  MOV RSI, RCX
  
  ;
  ; Check indexes are in valid range.
  ;  
  CMP VPAL_HANDLE.NumberIndexes[RCX], R8
  JBE @ExitFunction
  CMP VPAL_HANDLE.NumberIndexes[RCX], R9
  JBE @ExitFunction

;
; Updating Color Indexes
;

  MOV RDI, VPAL_HANDLE.PalettePtr[RCX]
  SHL R8, 2
  LEA R10, [RDI + R8]
  SHL R9, 2
  LEA R11, [RDI + R9]
  XOR R15, R15
  MOV R9, RDX
@UpdatingColorIndex:
  XOR RCX, RCX
  XOR RDX, RDX
  MOV CL, BYTE PTR [R10 + R15] ; Target
  MOV DL, BYTE PTR [R11 + R15] ; Current
  MOV AL, CL
  SUB AL, DL

  CMP AL, -10
  JGE @CheckUpperRange
  JMP @DoUpdateInc

@CheckUpperRange:
  CMP AL, 10
  JLE @ForceUpdate
@DoUpdateInc:
  CMP CL, DL
  JB @UpdateBelow
  MOV RAX, 1
  JMP @CheckRange
@UpdateBelow:
  MOV RAX, -1
  JMP @CheckRange
@CheckRange:
  CMP R9, 10
  JA @DontForce
@ForceUpdate:
  MOV CL, BYTE PTR [R10 + R15]
  MOV BYTE PTR [R11 + R15], CL
  JMP @DoneUpdating

@DontForce:
  XOR RCX, RCX
  MOV CL, BYTE PTR [R11 + R15]
  ADD RCX, RAX
  MOV BYTE PTR [R11 + R15], CL

@SkipUpdating:
@DoneUpdating:
  INC R15
  CMP R15, 3
  JB @UpdatingColorIndex


  
@ExitFunction:
  MOV RSI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV R15, VPAL_INIT_LOCALS.SaveRegsFrame.SaveR15[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_MoveColorIndexes, _TEXT$00



;*********************************************************
;  VPal_Transparent
;
;        Parameters: Palette Handle, Background, Foreground,  Index Destination
;
;       return None
;
;
;*********************************************************  
NESTED_ENTRY VPal_Transparent, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rsi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi
  save_reg r15, VPAL_INIT_LOCALS.SaveRegsFrame.SaveR15
.ENDPROLOG 
  MOV RSI, RCX
  
  ;
  ; Check indexes are in valid range.
  ;  
  CMP VPAL_HANDLE.NumberIndexes[RCX], RDX
  JBE @ExitFunction
  CMP VPAL_HANDLE.NumberIndexes[RCX], R8
  JBE @ExitFunction
  CMP VPAL_HANDLE.NumberIndexes[RCX], R9
  JBE @ExitFunction

;
; Updating Color Indexes
;

  MOV RDI, VPAL_HANDLE.PalettePtr[RCX]
  SHL R8, 2
  LEA R8, [RDI + R8]
  SHL R9, 2
  LEA R9, [RDI + R9]
  SHL RDX, 2
  LEA RDX, [RDI + RDX]

  XOR R15, R15
@UpdatingColorIndex:
  XOR RCX, RCX
  XOR RAX, RAX
  MOV CL, BYTE PTR [RDX + R15] ; Background
  MOV AL, BYTE PTR [R8 + R15] ; Foreground
 ; SHR CL, 1  ; Adjust for transparency settings
  ADD AX, CX
  CMP AX, 255
  JBE @NoNeedToTruncate
  MOV AX, 255
@NoNeedToTruncate:  
  MOV [R15 + R9], AL

  INC R15
  CMP R15, 3
  JB @UpdatingColorIndex


  
@ExitFunction:
  MOV RSI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRsi[RSP]
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV R15, VPAL_INIT_LOCALS.SaveRegsFrame.SaveR15[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_Transparent, _TEXT$00


;*********************************************************
;  VPal_FindColorIndex
;
;        Parameters: Palette Handle, Color, Rotated TRUE or FALSE
;
;       return DWORD (0RGB)
;
;
;*********************************************************  
NESTED_ENTRY VPal_FindColorIndex, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
  save_reg rbx, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRbx
.ENDPROLOG 
  XOR RAX, RAX
  MOV RBX, RDX
  LEA RDI, VPAL_HANDLE.PalettePtr[RCX]

@FindColorIndexLoop:
  MOV EDX, DWORD PTR [RDI]
  CMP EBX, EDX
  JE @FoundColor
  ADD RDI, 4
  INC RAX
  CMP RAX, VPAL_HANDLE.NumberIndexes[RCX]
  JB @FindColorIndexLoop

  XOR RAX, RAX
  NOT RAX
  JMP @ExitFunction

@FoundColor:
  CMP R8, 0
  JE @ExitFunction

  MOV RDX, RAX
  CALL VPal_GetRotatedIndex

@ExitFunction:
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  MOV RBX, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRbx[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_FindColorIndex, _TEXT$00

;*********************************************************
;  VPal_DirectAccess
;
;        Parameters: Palette Handle
;
;       return Palette Array
;
;
;*********************************************************  
NESTED_ENTRY VPal_DirectAccess, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
.ENDPROLOG 
  MOV RAX, VPAL_HANDLE.PalettePtr[RCX]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_DirectAccess, _TEXT$00


;*********************************************************
;  VPal_Rotate
;
;        Parameters: Palette Handle, Rotate Index
;
;       return None
;
;
;*********************************************************  
NESTED_ENTRY VPal_Rotate, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 

  ADD VPAL_HANDLE.RotateIndex[RCX], RDX

@SanatizeRotationIndex:
  MOV RDX, VPAL_HANDLE.RotateIndex[RCX]

  CMP RDX, VPAL_HANDLE.NumberIndexes[RCX]
  JGE @SantizeGreaterPositive

  MOV RAX,  VPAL_HANDLE.NumberIndexes[RCX]
  NEG RAX
  CMP RDX, RAX
  JLE @SantizeLessNegative

  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET

@SantizeGreaterPositive:
  SUB RDX, VPAL_HANDLE.NumberIndexes[RCX]
  MOV VPAL_HANDLE.RotateIndex[RCX], RDX
  JMP @SanatizeRotationIndex

@SantizeLessNegative:
  ADD RDX, VPAL_HANDLE.NumberIndexes[RCX]
  MOV VPAL_HANDLE.RotateIndex[RCX], RDX
  JMP @SanatizeRotationIndex
  
NESTED_END VPal_Rotate, _TEXT$00



;*********************************************************
;  VPal_RotateReset
;
;        Parameters: Palette Handle
;
;       return None
;
;
;*********************************************************  
NESTED_ENTRY VPal_RotateReset, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 

  MOV VPAL_HANDLE.RotateIndex[RCX], 0

  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
  
NESTED_END VPal_RotateReset, _TEXT$00

;*********************************************************
;  VPal_GetRotatedIndex
;
;        Parameters: Palette Handle, Index
;
;       Return Rotated Index
;
;
;*********************************************************  
NESTED_ENTRY VPal_GetRotatedIndex, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 

  CMP VPAL_HANDLE.RotateIndex[RCX], 0
  JE @CompleteRotate

  ADD RDX, VPAL_HANDLE.RotateIndex[RCX]

  CMP RDX, 0
  JL @FixRotateLess

  CMP RDX, VPAL_HANDLE.NumberIndexes[RCX]
  JGE @FixRotateGreater

@CompleteRotate:
  MOV RAX, RDX

  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET

@FixRotateLess:
  ADD RDX, VPAL_HANDLE.NumberIndexes[RCX]
  JMP @CompleteRotate

@FixRotateGreater:
  SUB RDX, VPAL_HANDLE.NumberIndexes[RCX]
  JMP @CompleteRotate


NESTED_END VPal_GetRotatedIndex, _TEXT$00

;*********************************************************
;  VPal_Free
;
;        Parameters: Palette Handle
;
;       
;
;
;*********************************************************  
NESTED_ENTRY VPal_Free, _TEXT$00
  alloc_stack(SIZEOF VPAL_INIT_LOCALS)
  save_reg rdi, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi
.ENDPROLOG 

  TEST RCX, RCX
  JZ @DoneFreeing
    
  MOV RDI, VPAL_HANDLE.PalettePtr[RCX]
  CALL LocalFree
  MOV RCX, RDI
  CALL LocalFree

@DoneFreeing:
  MOV RDI, VPAL_INIT_LOCALS.SaveRegsFrame.SaveRdi[RSP]
  ADD RSP, SIZE VPAL_INIT_LOCALS
  RET
NESTED_END VPal_Free, _TEXT$00

END
