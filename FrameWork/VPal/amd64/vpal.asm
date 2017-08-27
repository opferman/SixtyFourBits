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
  MOV RAX, RDX
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
