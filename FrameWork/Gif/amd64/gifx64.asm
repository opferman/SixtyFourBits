;*********************************************************
; GIF Decoder Library 
;
;  Written in Assembly x64
; 
;  By Toby Opferman  3/7/2019
;
;*********************************************************


;*********************************************************
; Assembly Options
;*********************************************************
;USE_VIRTUAL_ALLOC EQU <1>

;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include master.inc
include debug_public.inc
include paramhelp_public.inc

;*********************************************************
; External Functions
;*********************************************************
extern CloseHandle:proc
extern CreateFileA:proc
extern CreateFileMappingA:proc
extern MapViewOfFile:proc
extern LocalAlloc:proc
extern LocalFree:proc
extern VirtualAlloc:proc
extern VirtualFree:proc
extern UnmapViewOfFile:proc
extern memcpy:proc

;*********************************************************
; Constant Equates 
;*********************************************************
COLOR_MAP_SIZE       EQU <256>
PACK_BLOCK_PTR_ARRAY EQU <5000>
STRING_SIZE          EQU <4096*2>
STRING_TABLE_SIZE    EQU <4096*2>
NUMBER_OF_IMAGES     EQU <256>
LMEM_ZEROINIT        EQU <40h>
INVALID_HANDLE_VALUE EQU <-1>
FILE_MAP_READ        EQU <4>
PAGE_READONLY        EQU <2>
GENERIC_READ         EQU <080000000h>
OPEN_EXISTING        EQU <3>



;*********************************************************
; Macros  
;*********************************************************

BITS_PER_PIXEL_MASK  macro ByteInput
  AND ByteInput, 07h
endm

CR_BITS_MASK  macro ByteInput
  AND ByteInput, 070h
  SHR ByteInput, 4
endm

GLOBAL_MAP_DEFINED_MASK macro ByteInput
  AND ByteInput, 080h
  SHR ByteInput, 7
endm
  
IMAGE_IS_INTERLACED_MASK macro ByteInput
  AND ByteInput, 040h
  SHR ByteInput, 6
endm

USE_LOCAL_MAP_MASK macro ByteInput
  AND ByteInput, 080h
  SHR ByteInput, 7
endm




;*********************************************************
; Structures
;*********************************************************
LOCAL_VARIABLES struct
    LocalVar1         dq            ?
    LocalVar2         dq            ?
    LocalVar3         dq            ?
    LocalVar4         dq            ?
    LocalVar5         dq            ?
    LocalVar6         dq            ?
LOCAL_VARIABLES ends

STD_FUNCTION_LV_STACK struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    LocalVars   LOCAL_VARIABLES           <?>
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    SaveXmmRegs SAVE_REGISTERS_FRAME_XMM  <?>
    Padding     dq                         ?
STD_FUNCTION_LV_STACK ends

STD_FUNCTION_LV_STACK_FUNC struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    LocalVars   LOCAL_VARIABLES           <?>
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    SaveXmmRegs SAVE_REGISTERS_FRAME_XMM  <?>
    Padding     dq                         ?
    FuncParams  FUNCTION_PARAMETERS_FRAME <?>
STD_FUNCTION_LV_STACK_FUNC ends


GIF_HEADER struct

   Signature db 3 DUP(<?>)
   Version   db 3 DUP(<?>)
GIF_HEADER ends

SCREEN_DESCRIPTOR struct
  ScreenWidth                dw ?
  ScreenHeight               dw ?
  SpecialByte                db ?
  ScreenBackgroundColorIndex db ?
  Reserved                   db ?
SCREEN_DESCRIPTOR ends 

GIFRGB struct
  Red   db ?
  Green db ?
  Blue  db ?
GIFRGB ends

GLOBAL_COLOR_MAP struct
  GifRgbIndex GIFRGB COLOR_MAP_SIZE DUP(<?>)
GLOBAL_COLOR_MAP ends


IMAGE_DESCRIPTOR struct
  ImageSeperator db ?
  ImageStartLeft dw ?
  ImageStartTop  dw ?
  ImageWidth     dw ?
  ImageHeight    dw ?
  SpecialByte    db ?
IMAGE_DESCRIPTOR ends
  

LOCAL_COLOR_MAP struct
   GifRgbIndex GIFRGB COLOR_MAP_SIZE DUP(<?>)
LOCAL_COLOR_MAP ends

PACKED_BLOCK struct
   BlockByteCount db ?
   DataBytes      db ?   ; Variable Sized Array
PACKED_BLOCK ends


RASTER_DATA struct
   CodeSize       db ?
   NumberOfBlocks dd ?
   PackBlocksPtr  dq PACK_BLOCK_PTR_ARRAY  DUP({})
RASTER_DATA ends


IMAGE_DATA struct
  ImageDescriptorPtr dq ?
  LocalColorMapPtr   dq ?
  GraphicControlPtr  dq ?
  RasterData         RASTER_DATA <?>
IMAGE_DATA ends 


STRING_TABLE struct
   DecodeString db STRING_SIZE DUP(<?>)
   StringLength dd ?
STRING_TABLE ends

DECODE_STRING_TABLE struct
   ClearCode           dd ?
   EndOfInformation    dd ?
   FirstAvailable      dd ?
   CurrentIndex        dd ?
   CurrentCodeBits     dd ?
   Stride              dd ?
   StringTableList     STRING_TABLE STRING_TABLE_SIZE DUP({})
   LastCodeWord        dd ?
   NewCodeWord         dd ?
   BitIncrement        dd ?
   RasterDataBufferPtr dq ?
   RasterDataSize      dd ?
   CurrentPixel        dd ?
   ImageWidth          dd ?
   ImageBuffer32bppPtr dq ?
   ImagePalettePtr     dq ?
   ImageX              dd ?
   ImageY              dd ?
   ImageStartLeft      dd ? 
   ColorIndex          dd ?
DECODE_STRING_TABLE ends

GIF_GRAPHIC_CONTROL struct
  Introducer      db ?
  ExtLabel        db ?
  BlockSize       db ?
  Packed          db ?
  DelayTime       dw ?
  ColorIndex      db ?
  Terminator      db ?
GIF_GRAPHIC_CONTROL ends

GIF_INTERNAL struct
   hGifFile         dq ?
   hMemoryMapping   dq ?
   StartOfGifPtr    dq ?
   GifHeaderPtr     dq ?
   ScreenDescriptorPtr  dq ?
   GlobalColorMapPtr    dq ?
   NumberOfImages       dd ?
   ImageData            IMAGE_DATA NUMBER_OF_IMAGES DUP(<?>)
GIF_INTERNAL ends

STD_FUNCTION_STRING_LOCALS_STACK struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    FrontString STRING_TABLE              {}
    BackString  STRING_TABLE              {}
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    SaveXmmRegs SAVE_REGISTERS_FRAME_XMM  <?>
    ; Padding     dq                         ?
STD_FUNCTION_STRING_LOCALS_STACK ends




public Gif_Open
public Gif_Close
public Gif_NumberOfImages
public Gif_GetImageSize
public Gif_GetImageWidth
public Gif_GetImageHeight
public Gif_GetImage32bpp
public Gif_GetImage32bppRealTime
public Gif_GetAllImage32bpp
public Gif_InitMemory
public Gif_CloseMemory

.DATA

.CODE


;*********************************************************
;   Gif_Open
;
;        Parameters: File Name
;
;        Return Value: Gif Handle
;
;
;*********************************************************  
NESTED_ENTRY Gif_Open, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				; Gif File Name
  
ifndef USE_VIRTUAL_ALLOC  
  MOV RDX, SIZE GIF_INTERNAL
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
else
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, SIZE GIF_INTERNAL
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
endif
    
    
  CMP RAX, 0
  JE @FailureExit
  ;
  ; Open the file, create the memory mapping and verify it it as .GIF file.
  ;
  MOV RDX, RSI
  MOV RSI, RAX				; Save Gif Internal Pointer
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_OpenAndValidateFile
  CMP RAX, 0
  JE @FailureExit
  
  ;
  ;  Parse the initial file contents to split the memory map into
  ;  it's base components and determine how many images are in the 
  ;  file.
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_ParseFile
  
  CMP RAX, 0
  JE @FailureCloseFileExit
  
  MOV RAX, RSI
  JMP @SuccessExit  

@FailureCloseFileExit:
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_CloseFile
  MOV RAX, RSI
@FailureExit:
  CMP RAX, 0
  JE @DoNotDeAllocate

ifndef USE_VIRTUAL_ALLOC
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL VirtualFree
endif
 
  
  XOR RAX, RAX  
@DoNotDeAllocate:
@SuccessExit:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_Open, _TEXT$00


;*********************************************************
;   Gif_InitMemory
;
;        Parameters: Gif Memory
;
;        Return Value: Gif Handle
;
;
;*********************************************************  
NESTED_ENTRY Gif_InitMemory, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				; Gif File Name
  
ifndef USE_VIRTUAL_ALLOC  
  MOV RDX, SIZE GIF_INTERNAL
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
else
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, SIZE GIF_INTERNAL
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
endif
  
  CMP RAX, 0
  JE @FailureExit

 ;
 ; Verify the Memory signature is actually a .GIF file.
 ;
  MOV GIF_INTERNAL.StartOfGifPtr[RAX], RSI
  MOV GIF_INTERNAL.GifHeaderPtr[RAX], RSI
  LEA RSI, GIF_HEADER.Signature[RSI]
  
  CMP BYTE PTR [RSI], 'G'
  JNE @FailureExit
 
  CMP BYTE PTR [RSI+1], 'I'
  JNE @FailureExit

  CMP BYTE PTR [RSI+2], 'F'
  JNE @FailureExit
  
  MOV RSI, RAX
  
  ;
  ;  Parse the initial file contents to split the memory map into
  ;  it's base components and determine how many images are in the 
  ;  file.
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_ParseFile
  
  CMP RAX, 0
  JE @FailureExitParseFile
  
  MOV RAX, RSI
  JMP @SuccessExit  

@FailureExitParseFile:
  MOV RAX, RSI
@FailureExit:
  CMP RAX, 0
  JE @DoNotDeAllocate
ifndef USE_VIRTUAL_ALLOC
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL VirtualFree
endif

  XOR RAX, RAX  
@DoNotDeAllocate:
@SuccessExit:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_InitMemory, _TEXT$00

;*********************************************************
;   Gif_CloseMemory
;
;        Parameters: Gif Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_CloseMemory, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				

ifndef USE_VIRTUAL_ALLOC
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL VirtualFree
endif

    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_CloseMemory, _TEXT$00


;*********************************************************
;   Gif_Close
;
;        Parameters: Gif Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_Close, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  
  DEBUG_FUNCTION_CALL Gif_CloseFile
  
ifndef USE_VIRTUAL_ALLOC
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL VirtualFree
endif
  
    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_Close, _TEXT$00



;*********************************************************
;   Gif_CloseFile
;
;        Parameters: Gif Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_CloseFile, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  
  ;   
  ;  Free the memory mapping address allocation
  ;
  CMP GIF_INTERNAL.StartOfGifPtr[RSI], 0
  JE @SkipFreeingMemoryMap
  MOV RAX, INVALID_HANDLE_VALUE
  CMP GIF_INTERNAL.StartOfGifPtr[RSI], RAX
  JE @SkipFreeingMemoryMap
  MOV RCX, GIF_INTERNAL.StartOfGifPtr[RSI]
  DEBUG_FUNCTION_CALL UnmapViewOfFile
  XOR RAX, RAX
  MOV GIF_INTERNAL.StartOfGifPtr[RSI], RAX

@SkipFreeingMemoryMap: 
  
  ;   
  ;  Free the memory mapping handle
  ;  
  CMP GIF_INTERNAL.hMemoryMapping[RSI], 0
  JE @SkipFreeingMemoryMapHandle
  MOV RAX, INVALID_HANDLE_VALUE
  CMP GIF_INTERNAL.hMemoryMapping[RSI], RAX
  JE @SkipFreeingMemoryMapHandle
  MOV RCX, GIF_INTERNAL.hMemoryMapping[RSI]
  DEBUG_FUNCTION_CALL CloseHandle
  XOR RAX, RAX
  MOV GIF_INTERNAL.hMemoryMapping[RSI], RAX

@SkipFreeingMemoryMapHandle: 

  ;   
  ;  Close the file handle
  ; 
  CMP GIF_INTERNAL.hGifFile[RSI], 0
  JE @SkipFreeingFileHandle
  MOV RAX, INVALID_HANDLE_VALUE
  CMP GIF_INTERNAL.hGifFile[RSI], RAX
  JE @SkipFreeingFileHandle
  MOV RCX, GIF_INTERNAL.hGifFile[RSI]
  DEBUG_FUNCTION_CALL CloseHandle
  XOR RAX, RAX
  MOV GIF_INTERNAL.hGifFile[RSI], RAX

@SkipFreeingFileHandle:
    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_CloseFile, _TEXT$00



;*********************************************************
;   Gif_OpenAndValidateFile
;
;        Parameters: Gif Handle, File Name
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_OpenAndValidateFile, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  ;   
  ;  Open the .GIF file
  ;
  MOV RSI, RCX				
  MOV RCX, RDX
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], OPEN_EXISTING
  XOR R9, R9
  XOR R8, R8
  MOV RDX, GENERIC_READ
  DEBUG_FUNCTION_CALL CreateFileA  
  
  CMP RAX, 0
  JE @FailureExit
  
  MOV RCX, INVALID_HANDLE_VALUE
  CMP RAX, RCX  
  JE @FailureExit
  
  MOV GIF_INTERNAL.hGifFile[RSI], RAX
  ;
  ; Create the File Mapping Handle
  ;
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], 0
  XOR R9, R9
  MOV R8, PAGE_READONLY
  XOR RDX, RDX  
  MOV RCX, GIF_INTERNAL.hGifFile[RSI]  
  DEBUG_FUNCTION_CALL CreateFileMappingA
    
  CMP RAX, 0
  JE @FailureExitWithCloseFile
  
  MOV RCX, INVALID_HANDLE_VALUE
  CMP RAX, RCX  
  JE @FailureExitWithCloseFile
  
  MOV GIF_INTERNAL.hMemoryMapping[RSI], RAX
  ;
  ; Create the map view of file into memory
  ;
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], 0
  XOR R9, R9
  XOR R8, R8
  MOV RDX, FILE_MAP_READ
  MOV RCX, GIF_INTERNAL.hMemoryMapping[RSI]
  DEBUG_FUNCTION_CALL MapViewOfFile
  CMP RAX, 0
  JE @FailureExitWithCloseFile
  
 ;
 ; Verify the FILE signature is actually a .GIF file.
 ;
  MOV GIF_INTERNAL.StartOfGifPtr[RSI], RAX
  MOV GIF_INTERNAL.GifHeaderPtr[RSI], RAX
  LEA RAX, GIF_HEADER.Signature[RAX]
  
  CMP BYTE PTR [RAX], 'G'
  JNE @FailureExitWithCloseFile
 
  CMP BYTE PTR [RAX+1], 'I'
  JNE @FailureExitWithCloseFile

  CMP BYTE PTR [RAX+2], 'F'
  JNE @FailureExitWithCloseFile  
  
  JMP @SuccessExit

@FailureExitWithCloseFile:
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_CloseFile
@FailureExit:
  XOR RAX, RAX
  JMP @FinalExit
@SuccessExit:
  MOV EAX, 1
  
@FinalExit: 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_OpenAndValidateFile, _TEXT$00




;*********************************************************
;   Gif_ParseFile
;
;        Parameters: Gif Handle
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_ParseFile, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_LV_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_LV_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; The Screen Descriptor follows the .GIF signature, save this location
  ; as a pointer.
  ;
  MOV RCX, SIZE GIF_HEADER
  ADD RCX, GIF_INTERNAL.StartOfGifPtr[RSI]
  MOV GIF_INTERNAL.ScreenDescriptorPtr[RSI], RCX
  MOV STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], SIZE GIF_HEADER + SIZE SCREEN_DESCRIPTOR

  ;
  ; The Screen Descriptor contains a byte of the following format:
  ;
  ;   Bits Per Pixel      [     XXX] 2-0
  ;   Reserved Bit        [....X...] 3
  ;   Cr Bits             [.XXX....] 6-4
  ;   Global Map Defined  [X.......] 7
  ;
  ;

  MOV AL, SCREEN_DESCRIPTOR.SpecialByte[RCX]
  GLOBAL_MAP_DEFINED_MASK AL
  CMP AL, 0
  JE @NoGlobalMap

  ;
  ; A Global Color Map was found, so save the
  ; pointer location.
  ;
  MOV RDX, GIF_INTERNAL.StartOfGifPtr[RSI]
  ADD RDX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV GIF_INTERNAL.GlobalColorMapPtr[RSI], RDX

  ;
  ; Determine the bits per pixel to offset the
  ; size of the map.
  ;
  XOR RAX, RAX
  MOV AL, SCREEN_DESCRIPTOR.SpecialByte[RCX]
  BITS_PER_PIXEL_MASK AL
  ;
  ;  3 * 2^(Bits Per Pixel + 1) = Size Of Map
  ;
  INC RAX
  MOV RCX, RAX
  MOV EAX, 3
  SHL EAX,CL           

  ADD STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], RAX
@NoGlobalMap:
@ParseGifFileLoop:
  ;
  ; Set RBX to the current position.
  ;
  MOV RBX, GIF_INTERNAL.StartOfGifPtr[RSI]
  ADD RBX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]

  ;
  ; Remove Extended Data until we hit ; or ,
  ;
@RemoveExtensionDataLoop:
  CMP BYTE PTR[RBX], ';'
  JE @CompletedExtensionRemoval
  CMP BYTE PTR[RBX], ','
  JE @CompletedExtensionRemoval

  ;
  ; Check if this is a Graphic Control Exztension
  ;
  CMP BYTE PTR[RBX], '!'
  JNE @NotGraphicControl

  CMP BYTE PTR[RBX+1], 0F9h
  JNE @NotGraphicControl
    ;
    ; Index the correct Image Data and update the pointer
    ; to the Graphic Control descriptor
    ;    
    MOV R8D,GIF_INTERNAL.NumberOfImages[RSI]
    XOR RDX, RDX
    MOV RAX, SIZE IMAGE_DATA
    MUL R8
    LEA RDX, GIF_INTERNAL.ImageData[RSI]
    ADD RDX, RAX
    MOV IMAGE_DATA.GraphicControlPtr[RDX], RBX

@NotGraphicControl:
    ;
    ; Update the current offset by 2
    ;
    ADD STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], 2
   
   
    ;
    ; Parse the packed block but we are only doing this to advance the
    ; pointer.  We are ignoring these blocks.
    ;
    LEA R8, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
    XOR RDX, RDX
    MOV RCX, RSI
    DEBUG_FUNCTION_CALL Gif_ParsePackedBlock
    
    ;
    ;  Update RBX pointer to the block with the current offset.
    ;
    MOV RBX, GIF_INTERNAL.StartOfGifPtr[RSI]
    ADD RBX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
    
  
  JMP @RemoveExtensionDataLoop
@CompletedExtensionRemoval:
  
  ;
  ; Determine if we have a block we need to process.
  ;
  CMP BYTE PTR[RBX], ','
  JNE @SkipImageData
    ;
    ; Index the correct Image Data and update the pointer
    ; to the image descriptor
    ;    
    MOV R8D,GIF_INTERNAL.NumberOfImages[RSI]
    INC GIF_INTERNAL.NumberOfImages[RSI]
    XOR RDX, RDX
    MOV RAX, SIZE IMAGE_DATA
    MUL R8
    LEA RDX, GIF_INTERNAL.ImageData[RSI]
    ADD RDX, RAX
    MOV IMAGE_DATA.ImageDescriptorPtr[RDX], RBX

    ADD STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], SIZE IMAGE_DESCRIPTOR     ; Update Local Variable Offset
    MOV RCX, RBX
    MOV R8, RDX
    ;
    ; Check if there is a local map.
    ;
    XOR RAX, RAX
    MOV AL, IMAGE_DESCRIPTOR.SpecialByte[RBX]
    USE_LOCAL_MAP_MASK AL

    CMP AL, 0
    JE @SkipLocalColorMap

        MOV RCX, RBX
        ;
        ;  Refresh RBX with current pointer offset
        ;
        MOV RBX, GIF_INTERNAL.StartOfGifPtr[RSI]
        ADD RBX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
        MOV IMAGE_DATA.LocalColorMapPtr[R8], RBX

        XOR RAX, RAX
        MOV AL, IMAGE_DESCRIPTOR.SpecialByte[RCX]
        MOV RBX, RCX
        BITS_PER_PIXEL_MASK AL
        ;
        ;  3 * 2^(Bits Per Pixel + 1) = Size Of Map
        ;
        INC RAX
        MOV RCX, RAX
        MOV EAX, 3
        SHL EAX,CL           ; 2^(BIts Per Pixel + 1
        ADD STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], RAX

@SkipLocalColorMap:
    ;
    ;  Refresh RCX with current pointer offset
    ;
    MOV RCX, GIF_INTERNAL.StartOfGifPtr[RSI]
    ADD RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]

    MOV AL, BYTE PTR [RCX]
    MOV IMAGE_DATA.RasterData.CodeSize[R8], AL
    
    ;
    ; Increment past the CodeSize byte.
    ;
    INC STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]

    MOV RBX, R8
    LEA R8, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
    LEA RDX, IMAGE_DATA.RasterData.PackBlocksPtr[RBX]
    MOV RCX, RSI
    DEBUG_FUNCTION_CALL Gif_ParsePackedBlock

    CMP EAX, PACK_BLOCK_PTR_ARRAY
    JB @NoArraySizeIssues
    
@NoArraySizeIssues:
    ;
    ; Save the number of blocks created
    ;
    MOV IMAGE_DATA.RasterData.NumberOfBlocks[RBX], EAX

@SkipImageData:

   

   MOV RBX, GIF_INTERNAL.StartOfGifPtr[RSI]
   ADD RBX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
   
   ;
   ; Terminate the parsing
   ;
   CMP BYTE PTR[RBX], ';'
   JNE @ParseGifFileLoop

@ParsingComplete:
    MOV EAX, 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_LV_STACK
  ADD RSP, SIZE STD_FUNCTION_LV_STACK
  RET

NESTED_END Gif_ParseFile, _TEXT$00


;*********************************************************
;   Gif_ParsePackedBlock
;
;        Parameters: Gif Handle, packed block, Offset
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_ParsePackedBlock, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  XOR R9, R9

@ParsingPackedBlocks:

  ;
  ; Get the current Packed Block Pointer
  ;
  MOV RCX, GIF_INTERNAL.StartOfGifPtr[RSI]
  MOV EAX, DWORD PTR [R8]
  ADD RCX, RAX
  
  ;
  ; Update the new Offset to be the block count + 1
  ;
  INC DWORD PTR [R8]
  XOR RAX, RAX
  MOV AL, PACKED_BLOCK.BlockByteCount[RCX]
  ADD DWORD PTR [R8], EAX

  ;
  ; If no pointer was passed in to save the packed block, then skip.
  ;
  CMP RDX, 0
  JE @SkipReturningPackedBlock

  MOV QWORD PTR [RDX], RCX
  ADD RDX, SIZE QWORD
  
@SkipReturningPackedBlock:

  ;
  ;  Increment the block count
  ;
  INC R9

  ;
  ; If the BLock Byte Count was 0, then there are no more blocks.
  ;
  CMP PACKED_BLOCK.BlockByteCount[RCX], 0
  JNE @ParsingPackedBlocks

  ;
  ; Return the count of blocks
  ;
  MOV RAX, R9
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END Gif_ParsePackedBlock, _TEXT$00


;*********************************************************
;   Gif_NumberOfImages
;
;        Parameters: Gif Handle
;
;        Return Value: Number of Images
;
;
;*********************************************************  
NESTED_ENTRY Gif_NumberOfImages, _TEXT$00
.ENDPROLOG 
  MOV EAX, GIF_INTERNAL.NumberOfImages[RCX]	
  RET
NESTED_END Gif_NumberOfImages, _TEXT$00


;*********************************************************
;   Gif_GetImageWidth
;
;        Parameters: Gif Handle
;
;        Return Value: Image Width
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetImageWidth, _TEXT$00
.ENDPROLOG 
  MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[RCX]
  MOVZX EAX, SCREEN_DESCRIPTOR.ScreenWidth[RCX]				
  RET
NESTED_END Gif_GetImageWidth, _TEXT$00

;*********************************************************
;   Gif_GetImageHeight
;
;        Parameters: Gif Handle
;
;        Return Value: Image Height
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetImageHeight, _TEXT$00
.ENDPROLOG 
  MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[RCX]
  MOVZX EAX, SCREEN_DESCRIPTOR.ScreenHeight[RCX]				
  RET
NESTED_END Gif_GetImageHeight, _TEXT$00

;*********************************************************
;   Gif_GetImageSize
;
;        Parameters: Gif Handle
;
;        Return Value: Image Size
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetImageSize, _TEXT$00
.ENDPROLOG 
  MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[RCX]
  MOVZX EAX, SCREEN_DESCRIPTOR.ScreenHeight[RCX]				
  MOVZX R8D, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
  XOR RDX, RDX
  MUL R8D
  SHL RAX, 2
  RET
NESTED_END Gif_GetImageSize, _TEXT$00


;*********************************************************
;   Gif_GetAllImage32bpp
;      Get all images up to Image Index
;        Parameters: Gif Handle, Image Index, Return Buffer
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetAllImage32bpp, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  ;
  ; Save the parameters in non-volatile registers
  ;
  MOV R15, RCX
  MOV R13, R8
  MOV RBX, RDX

  CMP EDX, GIF_INTERNAL.NumberOfImages[RCX]
  JAE @IndexTooHigh
  XOR R12, R12
@ImageLoop:
    ;
    ; Get the Image Index being created
    ;    
    XOR RDX, RDX
    MOV RAX, SIZE IMAGE_DATA
    MUL R12
    LEA R14, GIF_INTERNAL.ImageData[R15]
    ADD R14, RAX

    CMP R12, 0
    JA @SkipBackgroundColor

    MOV R9, -1
    MOV RAX, IMAGE_DATA.GraphicControlPtr[R14]
    CMP RAX, 0
    JE @NoGraphicControl
        XOR RDX, RDX
        MOV DL, GIF_GRAPHIC_CONTROL.ColorIndex[RAX]
        MOV R9, RDX
@NoGraphicControl:
    MOV RDX, R12
    MOV R8, R13
    MOV RCX, R15
    DEBUG_FUNCTION_CALL Gif_SetBackgroundColor
@SkipBackgroundColor:
    
    MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[R15]
    MOV RAX, IMAGE_DATA.ImageDescriptorPtr[R14]
    
    ;
    ; Create the Stride of ScreenWidth - ImageWidth
    ;
    MOVZX R8D, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    SUB R8W, IMAGE_DESCRIPTOR.ImageWidth[RAX]

    ;
    ; Create the Start Offset = ImageStartLeft + (ImageStartTop*ScreenWidth)
    ;   Buffer += Offset*4
    ;
    MOVZX R10D, IMAGE_DESCRIPTOR.ImageStartLeft[RAX]
    MOVZX R9D, IMAGE_DESCRIPTOR.ImageStartTop[RAX]
    MOVZX EAX, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    XOR RDX, RDX
    MUL R9
    ADD R10, RAX
    MOV R9, R13
    SHL R10, 2
    ; R8 = Stride
    ADD R9, R10    ; Image Buffer
    MOV RDX, R14   ; IMAGE_DATA     
    MOV RCX, R15   ; GIF_INTERNAL
    DEBUG_FUNCTION_CALL Gif_Decode
	
    INC R12D
    CMP R12D, EBX
    JA @Success
	
	MOV RCX, R15
    DEBUG_FUNCTION_CALL Gif_GetImageSize
	MOV RSI, R13
	ADD R13, RAX
	MOV RDI, R13
	TEST AL, 7
	JZ @QwordVersion
	TEST AL, 3
	JZ @DwordVersion
	TEST AL, 1
	JZ @WordVersion
	SHR RAX, 3
	MOV RCX, RAX
	REP MOVSB
	JMP @ImageLoop	
@QwordVersion:	
	SHR RAX, 3
	MOV RCX, RAX
	REP MOVSQ
	JMP @ImageLoop
@DwordVersion:	
	SHR RAX, 2
	MOV RCX, RAX
	REP MOVSD
	JMP @ImageLoop
@WordVersion:	
	MOV RCX, RAX
	REP MOVSD
	JMP @ImageLoop		
@Success:
  MOV EAX, 1

@IndexTooHigh:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_GetAllImage32bpp, _TEXT$00



;*********************************************************
;   Gif_GetImage32bpp
;
;        Parameters: Gif Handle, Image Index, Previous Image & Return Buffer
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetImage32bppRealTime, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  ;
  ; Save the parameters in non-volatile registers
  ;
  MOV RSI, RCX
  MOV RDI, R8
  MOV RBX, RDX
  MOV R12, RDX

  CMP EDX, GIF_INTERNAL.NumberOfImages[RCX]
  JAE @IndexTooHigh
    ;
    ; Get the Image Index being created
    ;    
    XOR RDX, RDX
    MOV RAX, SIZE IMAGE_DATA
    MUL R12
    LEA R14, GIF_INTERNAL.ImageData[RSI]
    ADD R14, RAX

    CMP R12, 0
    JA @SkipBackgroundColor

    MOV R9, -1
    MOV RAX, IMAGE_DATA.GraphicControlPtr[R14]
    CMP RAX, 0
    JE @NoGraphicControl
        XOR RDX, RDX
        MOV DL, GIF_GRAPHIC_CONTROL.ColorIndex[RAX]
        MOV R9, RDX
@NoGraphicControl:
    MOV RDX, R12
    MOV R8, RDI
    MOV RCX, RSI
    DEBUG_FUNCTION_CALL Gif_SetBackgroundColor
@SkipBackgroundColor:
    
    MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[RSI]
    MOV RAX, IMAGE_DATA.ImageDescriptorPtr[R14]
    
    ;
    ; Create the Stride of ScreenWidth - ImageWidth
    ;
    MOVZX R8D, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    SUB R8W, IMAGE_DESCRIPTOR.ImageWidth[RAX]

    ;
    ; Create the Start Offset = ImageStartLeft + (ImageStartTop*ScreenWidth)
    ;   Buffer += Offset*4
    ;
    MOVZX R10D, IMAGE_DESCRIPTOR.ImageStartLeft[RAX]
    MOVZX R9D, IMAGE_DESCRIPTOR.ImageStartTop[RAX]
    MOVZX EAX, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    XOR RDX, RDX
    MUL R9
    ADD R10, RAX
    MOV R9, RDI
    SHL R10, 2
    ; R8 = Stride
    ADD R9, R10    ; Image Buffer
    MOV RDX, R14   ; IMAGE_DATA     
    MOV RCX, RSI   ; GIF_INTERNAL
    DEBUG_FUNCTION_CALL Gif_Decode
    
@Success:
  MOV EAX, 1

@IndexTooHigh:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_GetImage32bppRealTime, _TEXT$00





;*********************************************************
;   Gif_GetImage32bpp
;
;        Parameters: Gif Handle, Image Index, Return Buffer
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetImage32bpp, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  ;
  ; Save the parameters in non-volatile registers
  ;
  MOV RSI, RCX
  MOV RDI, R8
  MOV RBX, RDX

  CMP EDX, GIF_INTERNAL.NumberOfImages[RCX]
  JAE @IndexTooHigh
  XOR R12, R12
@ImageLoop:
    ;
    ; Get the Image Index being created
    ;    
    XOR RDX, RDX
    MOV RAX, SIZE IMAGE_DATA
    MUL R12
    LEA R14, GIF_INTERNAL.ImageData[RSI]
    ADD R14, RAX
    
    CMP R12, 0
    JA @SkipBackgroundColor

    MOV R9, -1
    MOV RAX, IMAGE_DATA.GraphicControlPtr[R14]
    CMP RAX, 0
    JE @NoGraphicControl
        XOR RDX, RDX
        MOV DL, GIF_GRAPHIC_CONTROL.ColorIndex[RAX]
        MOV R9, RDX
@NoGraphicControl:
    MOV RDX, R12
    MOV R8, RDI
    MOV RCX, RSI
    DEBUG_FUNCTION_CALL Gif_SetBackgroundColor
@SkipBackgroundColor:
    
    MOV RCX, GIF_INTERNAL.ScreenDescriptorPtr[RSI]
    MOV RAX, IMAGE_DATA.ImageDescriptorPtr[R14]
    
    ;
    ; Create the Stride of ScreenWidth - ImageWidth
    ;
    MOVZX R8D, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    SUB R8W, IMAGE_DESCRIPTOR.ImageWidth[RAX]

    ;
    ; Create the Start Offset = ImageStartLeft + (ImageStartTop*ScreenWidth)
    ;   Buffer += Offset*4
    ;
    MOVZX R10D, IMAGE_DESCRIPTOR.ImageStartLeft[RAX]
    MOVZX R9D, IMAGE_DESCRIPTOR.ImageStartTop[RAX]
    MOVZX EAX, SCREEN_DESCRIPTOR.ScreenWidth[RCX]
    XOR RDX, RDX
    MUL R9
    ADD R10, RAX
    MOV R9, RDI
    SHL R10, 2
    ; R8 = Stride
    ADD R9, R10    ; Image Buffer
    MOV RDX, R14   ; IMAGE_DATA     
    MOV RCX, RSI   ; GIF_INTERNAL
    DEBUG_FUNCTION_CALL Gif_Decode
    
    INC R12D
    CMP R12D, EBX
    JBE @ImageLoop
@Success:
  MOV EAX, 1

@IndexTooHigh:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_GetImage32bpp, _TEXT$00

;*********************************************************
;   Gif_SetBackgroundColor
;
;        Parameters: Gif Handle, Image Index, Return Buffer, Transparent Color
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_SetBackgroundColor, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV R14, RDX
  MOV R13, R8
  MOV R12, GIF_INTERNAL.ScreenDescriptorPtr[RCX]
  XOR R8, R8
  MOVZX R8W, SCREEN_DESCRIPTOR.ScreenBackgroundColorIndex[R12]
  CMP R9W, R8W
  JE @BackgroundIsTransparent
  DEBUG_FUNCTION_CALL Gif_GetPaletteColorByIndex

  MOV RCX, RAX                                     ; Save Background Color Value

  MOVZX EAX, SCREEN_DESCRIPTOR.ScreenWidth[R12]
  MOVZX EBX, SCREEN_DESCRIPTOR.ScreenHeight[R12]
  XOR RDX, RDX
  MUL EBX                                          ; Assume Screen Height * Screen Width != 0

  XOR R8, R8
@SetBackgroundColor:    
  MOV DWORD PTR [R13], ECX                         ; Update Background Color
  ADD R13, 4                                       ; 32-bit pixels
  INC R8
  CMP R8, RAX                                      ; Test if we filled the entire image yet
  JB @SetBackgroundColor
@BackgroundIsTransparent:
@BackgroundComplete:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_SetBackgroundColor, _TEXT$00


;*********************************************************
;   Gif_GetPaletteColorByIndex
;
;        Parameters: Gif Handle, Image Index, Color Index
;
;        Return Value: Color 32 bit
;
;
;*********************************************************  
NESTED_ENTRY Gif_GetPaletteColorByIndex, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  LEA R9, GIF_INTERNAL.ImageData[RCX]
  MOV RBX, RDX
  
  XOR RDX, RDX
  MOV RAX, SIZE IMAGE_DATA
  MUL RBX
  ADD R9, RAX
  MOV R10, IMAGE_DATA.ImageDescriptorPtr[R9]
  MOV AL, IMAGE_DESCRIPTOR.SpecialByte[R10]
  ;
  ; The Image Descriptor contains a byte of the following format:
  ;
  ;   Bits Per Pixel      [     XXX] 2-0
  ;   Reserved Bits       [..XXX...] 5-3
  ;   Image Is Interlaced [.X......] 6
  ;   Use Local Map       [X.......] 7
  ;
  ;
  USE_LOCAL_MAP_MASK AL

  CMP AL, 0
  JE @UseGlobalColorTable
@UseLocalColorTable:
  MOV RDX, IMAGE_DATA.LocalColorMapPtr[R9]
  JMP @ReturnColor
@UseGlobalColorTable:
  MOV RDX, GIF_INTERNAL.GlobalColorMapPtr[RCX]
@ReturnColor:
  ADD RDX, RBX
  SHL RBX, 1
  ADD RDX, RBX                        ; Trick to 3*n + Address where n + n<<1 + Address.  
                                        ;  2^0 = 1   2^1 = 2 = 1+2 = 3
  XOR RAX, RAX
  MOV AL, BYTE PTR [RDX]              ; Red
  SHL EAX, 16
  MOV AL, BYTE PTR [RDX+1]            ; Green
  SHL AX, 8
  MOV AL, BYTE PTR [RDX+2]            ; Blue

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_GetPaletteColorByIndex, _TEXT$00


;*********************************************************
;   Gif_InitializeStringTable
;
;        Parameters: Gif Handle, Image Data, Decode String Table
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_InitializeStringTable, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RBX, R8
  MOV DECODE_STRING_TABLE.ColorIndex[RBX], -1
  CMP IMAGE_DATA.GraphicControlPtr[RDI], 0
  JE @NoGraphicControl
  XOR RCX, RCX
  MOV RAX, IMAGE_DATA.GraphicControlPtr[RDI]
  MOV CL, GIF_GRAPHIC_CONTROL.ColorIndex[RAX]
  MOV DECODE_STRING_TABLE.ColorIndex[RBX], ECX
@NoGraphicControl:

  MOV CL, IMAGE_DATA.RasterData.CodeSize[RDI]
  MOV EAX, 1
  SHL EAX, CL
  MOV DECODE_STRING_TABLE.ClearCode[RBX], EAX

  MOV DECODE_STRING_TABLE.LastCodeWord[RBX], EAX

  INC EAX
  MOV DECODE_STRING_TABLE.EndOfInformation[RBX], EAX

  INC EAX
  MOV DECODE_STRING_TABLE.FirstAvailable[RBX], EAX

  MOV DECODE_STRING_TABLE.CurrentIndex[RBX], 0

  XOR RAX, RAX
  MOV AL, IMAGE_DATA.RasterData.CodeSize[RDI]
  INC EAX
  MOV DECODE_STRING_TABLE.CurrentCodeBits[RBX], EAX

  MOV RCX, IMAGE_DATA.ImageDescriptorPtr[RDI]
  MOVZX EAX, IMAGE_DESCRIPTOR.ImageWidth[RCX]
  MOV DECODE_STRING_TABLE.ImageWidth[RBX], EAX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_InitializeStringTable, _TEXT$00

;*********************************************************
;   Gif_Decode
;
;        Parameters: Gif Handle, Image Data, Stride, Image Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_Decode, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_LV_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_LV_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX                                                                  ; RSI = GIF_INTERNAL
  MOV RDI, RDX                                                                  ; RDI = IMAGE_DATA
  MOV RBX, R9                                                                   ; RBX = Image Buffer
  MOV R12, R8                                                                   ; R12 = Stride
  MOV R14, IMAGE_DATA.ImageDescriptorPtr[RDI]                                   ; R14 = IMAGE_DESCRIPTOR


ifndef USE_VIRTUAL_ALLOC  
  MOV RDX, SIZE DECODE_STRING_TABLE
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
else
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, SIZE DECODE_STRING_TABLE
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
endif

  CMP RAX, 0
  JE @Failed
  MOV STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], RAX                       ; Save the String Decode in a Local Variable

  ;
  ; Initialize the String Decode Table
  ;
  MOVZX ECX, IMAGE_DESCRIPTOR.ImageStartLeft[R14]
  MOV DECODE_STRING_TABLE.ImageX[RAX], ECX
  MOV DECODE_STRING_TABLE.ImageStartLeft[RAX], ECX

  MOVZX ECX, IMAGE_DESCRIPTOR.ImageStartTop[R14]
  MOV DECODE_STRING_TABLE.ImageY[RAX], ECX

  MOV DECODE_STRING_TABLE.ImageBuffer32bppPtr[RAX], RBX

  MOV DECODE_STRING_TABLE.Stride[RAX], R12D

  ;
  ; Determine Color Map to use
  ;
  MOV AL, IMAGE_DESCRIPTOR.SpecialByte[R14]
  USE_LOCAL_MAP_MASK AL
  CMP AL, 0
  JE @UseGlobalMap
  MOV RCX, IMAGE_DATA.LocalColorMapPtr[RDI]
  JMP @UpdateColorMap
@UseGlobalMap:
  MOV RCX, GIF_INTERNAL.GlobalColorMapPtr[RSI]
@UpdateColorMap:
  MOV R8,STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV DECODE_STRING_TABLE.ImagePalettePtr[R8], RCX
  MOV RDX,RDI
  MOV RCX,RSI
  DEBUG_FUNCTION_CALL Gif_InitializeStringTable

  MOV RAX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV DECODE_STRING_TABLE.BitIncrement[RAX], 0
  MOV DECODE_STRING_TABLE.RasterDataSize[RAX], 0

  ;
  ; Build the Raster Block Size
  ;
  XOR R8, R8
  LEA RDX, IMAGE_DATA.RasterData.PackBlocksPtr[RDI]

@NextRasterBlockSize:
  CMP R8D, IMAGE_DATA.RasterData.NumberOfBlocks[RDI]
  JAE @FinishedRasterBlocks
  MOV R9, QWORD PTR [RDX]
  MOVZX ECX, PACKED_BLOCK.BlockByteCount[R9]
  ADD DECODE_STRING_TABLE.RasterDataSize[RAX], ECX
  ADD RDX, 8
  INC R8
  JMP @NextRasterBlockSize
@FinishedRasterBlocks:

  
ifndef USE_VIRTUAL_ALLOC  
  MOV EDX, DECODE_STRING_TABLE.RasterDataSize[RAX]
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
else
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV EDX, DECODE_STRING_TABLE.RasterDataSize[RAX]
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
endif

  CMP RAX, 0
  JE @DeallocateStringTableDecode

  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV DECODE_STRING_TABLE.RasterDataBufferPtr[RCX], RAX

  XOR R13, R13     ; Non-Volatile Counter
  XOR R14, R14
                               
  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV R15, DECODE_STRING_TABLE.RasterDataBufferPtr[RCX]                 ; R15 = Raster Table
@MemoryCopyUpdater:
  CMP R13D, IMAGE_DATA.RasterData.NumberOfBlocks[RDI]
  JAE @CopyComplete
    
  MOV RCX, R15

  MOV R9, R13
  SHL R9, 3
  LEA RDX, IMAGE_DATA.RasterData.PackBlocksPtr[RDI]
  ADD RDX, R9
  MOV RDX, QWORD PTR [RDX]
  XOR R8, R8
  MOVZX R8D, PACKED_BLOCK.BlockByteCount[RDX]
  LEA RDX, PACKED_BLOCK.DataBytes[RDX]
  ADD R12, R8
  ADD R15, R8
  DEBUG_FUNCTION_CALL memcpy

  INC R13
  JMP @MemoryCopyUpdater
  
@CopyComplete:
  MOV R8, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV EAX, DECODE_STRING_TABLE.RasterDataSize[R8]
  ADD RAX, DECODE_STRING_TABLE.RasterDataBufferPtr[R8]
  CMP RAX, R15
  JAE @PassesTheTest
  INT 3   ; Overflow.
@PassesTheTest:
  MOV R8, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_DecodePackedBlock

@DeallocateRasterdataBuffer:
ifndef USE_VIRTUAL_ALLOC
  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV RCX, DECODE_STRING_TABLE.RasterDataBufferPtr[RCX]
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  MOV RCX, DECODE_STRING_TABLE.RasterDataBufferPtr[RCX]
  DEBUG_FUNCTION_CALL VirtualFree
endif



@DeallocateStringTableDecode:
@DeallocateStringDecode:
ifndef USE_VIRTUAL_ALLOC
  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  DEBUG_FUNCTION_CALL LocalFree
else
  MOV R8, 08000h  ; MEM_RELEASE
  XOR RDX, RDX
  MOV RCX, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  DEBUG_FUNCTION_CALL VirtualFree
endif

@Failed:
  RESTORE_ALL_STD_REGS STD_FUNCTION_LV_STACK
  ADD RSP, SIZE STD_FUNCTION_LV_STACK
  RET
NESTED_END Gif_Decode, _TEXT$00





;*********************************************************
;   Gif_DecodePackedBlock
;
;        Parameters: Gif Handle, Image Data, Decode String Table
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Gif_DecodePackedBlock, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_LV_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_LV_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX   ; GIF_INTERNAL        (RSI)
  MOV RDI, RDX   ; IMAGE DATA          (RDI)
  MOV RBX, R8    ; DECODE STRING TABLE (RBX)

  MOV RAX, DECODE_STRING_TABLE.RasterDataBufferPtr[RBX]
  MOV STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP], RAX

  XOR R12, R12
@DecodePackedBlockLoop:
  CMP R12D, DECODE_STRING_TABLE.RasterDataSize[RBX]
  JAE @FinishedDecoding
  
  MOV R8, STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  LEA RDX, DECODE_STRING_TABLE.BitIncrement[RBX]
  MOV RCX, RBX
  DEBUG_FUNCTION_CALL Gif_RetrieveCodeWord
  MOV DECODE_STRING_TABLE.NewCodeWord[RBX], EAX
  
  CMP EAX, DECODE_STRING_TABLE.ClearCode[RBX]
  JNE @NotAClearCode
  
  MOV R8, RBX
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_InitializeStringTable
  JMP  @DoneProcessingNewCode
@NotAClearCode:
  CMP EAX, DECODE_STRING_TABLE.EndOfInformation[RBX]
  JE @BitIncrementLoop

  MOV R9, RDI
  MOV R8, RAX
  MOV EDX, DECODE_STRING_TABLE.LastCodeWord[RBX]
  MOV RCX, RBX
  DEBUG_FUNCTION_CALL Gif_ProcessNewCode
   
  CMP RAX, 0
  JE @UpdateLastWord

  MOV R8, RBX
  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL Gif_InitializeStringTable

  JMP @DoneProcessingNewCode
@UpdateLastWord:
  
  MOV EAX, DECODE_STRING_TABLE.NewCodeWord[RBX]
  MOV DECODE_STRING_TABLE.LastCodeWord[RBX], EAX
@DoneProcessingNewCode:
@BitIncrementLoop:  
  CMP DECODE_STRING_TABLE.BitIncrement[RBX], 8
  JB @CompleteBitIncrementLoop
  INC R12
  INC STD_FUNCTION_LV_STACK.LocalVars.LocalVar1[RSP]
  SUB DECODE_STRING_TABLE.BitIncrement[RBX], 8
  JMP @BitIncrementLoop
@CompleteBitIncrementLoop:
  JMP @DecodePackedBlockLoop
@FinishedDecoding:

  RESTORE_ALL_STD_REGS STD_FUNCTION_LV_STACK
  ADD RSP, SIZE STD_FUNCTION_LV_STACK
  RET
NESTED_END Gif_DecodePackedBlock, _TEXT$00


;*********************************************************
;   Gif_RetrieveCodeWord
;
;        Parameters: Decode String Table, Bit Increment Ptr, Packed Block Bytes Ptr
;
;        Return Value: Code Word
;
;
;*********************************************************  
NESTED_ENTRY Gif_RetrieveCodeWord, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STRING_LOCALS_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STRING_LOCALS_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV ECX, DWORD PTR [RDX]
  MOV R9D, DWORD PTR [R8]
  SHR R9D, CL          ; PackedBlock >> BitIncrement

  MOV R11D, DECODE_STRING_TABLE.CurrentCodeBits[RSI]
  MOV ECX, R11D
  MOV EAX, 1
  SHL EAX, CL
  SUB EAX,1             ; ((1<<CurrentCodeBits)-1)


  AND EAX, R9D          ; New Code Word  = ((1<<CurrentCodeBits)-1) & (PackedBlock >>BitIncrmenet)

  MOV ECX, [RDX]
  MOV STD_FUNCTION_STRING_LOCALS_STACK.Parameters.Param3[RSP], RCX
  ADD DWORD PTR [RDX], R11D


  RESTORE_ALL_STD_REGS STD_FUNCTION_STRING_LOCALS_STACK
  ADD RSP, SIZE STD_FUNCTION_STRING_LOCALS_STACK
  RET
NESTED_END Gif_RetrieveCodeWord, _TEXT$00


 
;***********************************
;   Gif_ProcessNewCode
;
;        Parameters: Decode String Table, LastCodeWord, NewCodeWord, Image Control
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_ProcessNewCode, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RCX          ; RBX is Decode String Table
  MOV R13, R9


  CMP R8D, DECODE_STRING_TABLE.ClearCode[RBX]
  JA @NewCodeWord_EqualOrGreater ; TEO: Was JA

     MOV RCX, DECODE_STRING_TABLE.ImagePalettePtr[RBX]

     MOV R10, R8
     SHL R10, 1
     ADD R10, R8                        ; 2^0 + 2^1 = 3*n
     ADD RCX, R10

     CMP DECODE_STRING_TABLE.ColorIndex[RBX], R8D
     JE @TransparentColor

     XOR RAX, RAX                       ; Create Pixel
     MOV AL, BYTE PTR [RCX]
     SHL EAX, 16
     MOV AL, BYTE PTR [RCX+1]
     SHL AX, 8
     MOV AL, BYTE PTR [RCX+2]

     ;
     ; Update Pixel On Screen and Increment Current Pixel
     ;
     MOV RCX, DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX]
     MOV R10D, DECODE_STRING_TABLE.CurrentPixel[RBX]
     SHL R10D, 2                                                ; Need to Multiply by 4* to get to DWORD
     ADD RCX, R10
     MOV DWORD PTR [RCX], EAX
@TransparentColor:

     INC DECODE_STRING_TABLE.CurrentPixel[RBX]

     MOV R10D, DECODE_STRING_TABLE.ImageWidth[RBX]

     CMP DECODE_STRING_TABLE.CurrentPixel[RBX], R10D
     JB @SkipStrideUpdateWidth

     ;
     ; Update Image Buffer to point to the next screen line. and reset pixel counter
     ;
     MOV RCX, DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX]
     MOV R11D, DECODE_STRING_TABLE.Stride[RBX]
     ADD R10, R11
     SHL R10, 2                                 ; Need to multiply by 4 since this is 32 bit color
     ADD RCX, R10
     MOV DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX], RCX
     MOV DECODE_STRING_TABLE.CurrentPixel[RBX], 0

@SkipStrideUpdateWidth:

     XOR RAX, RAX                                       ; Return FALSE unless updated below
     ;
     ;  Compare Last Code word with Clear Code.
     ;
     CMP EDX, DECODE_STRING_TABLE.ClearCode[RBX]
     JE @ExitFunction

     ;
     ; R8 and RDX should be preserved so pass them through.
     ;
     MOV RCX, RBX
     DEBUG_FUNCTION_CALL Gif_AddNewEntry

     ;
     ; Return RAX to caller.
     ;
     JMP @ExitFunction
;
; Else Code Path
;
@NewCodeWord_EqualOrGreater:
     ;
     ; Need to preserve NewCodeWord
     ;
     MOV R12, R8
     ;
     ; Pass through paramters have not been modified yet.
     ;
     DEBUG_FUNCTION_CALL Gif_AddNewEntry
     ;
     ; Preserve RAX to return to caller!
     ;
     MOV R8, RAX
     
     MOV EDX, DECODE_STRING_TABLE.FirstAvailable[RBX]
     MOV R10, R12
     SUB R10, RDX                               ; NewCode - First Available
     MOV RAX, SIZE STRING_TABLE
     XOR RDX, RDX
     MUL R10
     LEA RSI, DECODE_STRING_TABLE.StringTableList[RBX]
     ADD RSI, RAX
     MOV RAX, R8
     XOR R8, R8
     ;
     ; RSI = STRING_TABLE[Index]
     ;
     ; DO NOT MODIFY RAX it is the return value!
     ;
@PixelUpdateScreenLoop:
     CMP R8D, STRING_TABLE.StringLength[RSI]
     JAE @ExitFunction

     ;
     ; Get Pixel from Look up Table
     ;
     LEA RDX, STRING_TABLE.DecodeString[RSI]
     ADD RDX, R8
     XOR RCX, RCX
     MOV CL, BYTE PTR [RDX]

     CMP DECODE_STRING_TABLE.ColorIndex[RBX], ECX
     JE @TransparentColor2

     MOV R10, DECODE_STRING_TABLE.ImagePalettePtr[RBX]
     ADD R10, RCX
     SHL RCX, 1
     ADD R10, RCX
     XOR RCX, RCX
     MOV CL, BYTE PTR [R10]
     SHL ECX, 16
     MOV CL, BYTE PTR [R10+1]
     SHL CX, 8
     MOV CL, BYTE PTR [R10+2]

     CMP ECX, 0726681h
     JNE @NotValue
     int 3
@NotValue:
     AND ECX, 0FFFFFFh
     CMP ECX, 0726681h
     JNE @NotValue2
     int 3
@NotValue2:
     ;
     ; Update Pixel On Screen 
     ;
     MOV R9, DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX]
     MOV R10D, DECODE_STRING_TABLE.CurrentPixel[RBX]
     SHL R10, 2                                         ; Need to multiply by 4 to get correct 32 bit color
     ADD R9, R10

     MOV DWORD PTR [R9], ECX
@TransparentColor2:
     ;
     ; Increment Current Pixel
     ;

     INC DECODE_STRING_TABLE.CurrentPixel[RBX]
     INC DECODE_STRING_TABLE.ImageX[RBX]
     INC R8                                     ; Incremet Current Index for next itteration

     ;
     ; Check Pixel Bounds
     ;
     MOV R10D, DECODE_STRING_TABLE.ImageWidth[RBX]
     CMP DECODE_STRING_TABLE.CurrentPixel[RBX], R10D
     JB @PixelUpdateScreenLoop

     ;
     ; Our Pixel Location is now out of bounds, so we need to fix it up.
     ;
     MOV RCX, DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX]
     MOV R11D, DECODE_STRING_TABLE.Stride[RBX]
     ADD R10, R11
     SHL R10, 2                                         ; Needt to mulitpy by 4 to get correct color.
     ADD RCX, R10
     MOV DECODE_STRING_TABLE.CurrentPixel[RBX], 0
     MOV DECODE_STRING_TABLE.ImageBuffer32bppPtr[RBX], RCX
     
     MOV ECX, DECODE_STRING_TABLE.ImageStartLeft[RBX]
     MOV DECODE_STRING_TABLE.ImageX[RBX], ECX

     INC DECODE_STRING_TABLE.ImageY[RBX]
     
     JMP @PixelUpdateScreenLoop

@ExitLoopComplete:
@ExitFunction:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Gif_ProcessNewCode, _TEXT$00




;*********************************************************
;   Gif_AddNewEntry
;
;        Parameters: Decode String Table, LastCodeWord, NewCodeWord
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Gif_AddNewEntry, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STRING_LOCALS_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STRING_LOCALS_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR R12, R12                                  ; R12 will hold the return value of TRUE or FALSE

  MOV RBX, RCX                                  ; RBX will hold the DECODE_STRING_TABLE
  MOV RSI, RDX                                  ; RSI will hold the LastCOdeWord
  MOV RDI, R8                                   ; RDI will hold the NewCOdeWord

  MOV STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP], 0
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP], 0
  
  CMP EDI, DECODE_STRING_TABLE.ClearCode[RBX]   
  JBE @CreateBackStringWIthNewCode  ; TEO: Was JBE
    
  ;
  ;  Translate NewCode to an Index
  ; 
  MOV ECX, EDI                                          ; Move New Code
  SUB ECX, DECODE_STRING_TABLE.FirstAvailable[RBX]      ; New Code - FirstAvailable
  CMP ECX, DECODE_STRING_TABLE.CurrentIndex[RBX] 
  JAE @CheckLastCodeWord

  ;
  ; Use the index to the string table to update the Back String decode.
  ; 
  MOV EAX, SIZE STRING_TABLE
  XOR RDX, RDX
  MUL ECX
  LEA RDX, DECODE_STRING_TABLE.StringTableList[RBX]
  ADD RDX, RAX

  MOV CL, STRING_TABLE.DecodeString[RDX]
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP], 1
  JMP @CheckClearAndLastCode
  
@CreateBackStringWIthNewCode:
  ;
  ; Update BackString with newCodeword
  ;
  MOV RCX, RDI
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP], 1

@CheckClearAndLastCode:
   
  ;
  ; Check if LastCodeWord and ClearCode.
  ;
  CMP ESI, DECODE_STRING_TABLE.ClearCode[RBX]  
  JA @PerformMemCopyToFrontString  ; TEO: Was JA

  MOV RCX, RSI
  MOV STD_FUNCTION_STRING_LOCALS_STACK.FrontString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP], 1

  JMP @UpdateStringDecodeBuffersWithMemCopy
@PerformMemCopyToFrontString:
   ;
   ; Copy Last Word Index String Table to FrontString.
   ;   
   LEA RCX, STD_FUNCTION_STRING_LOCALS_STACK.FrontString[RSP]
   MOV R8, SIZE STRING_TABLE

   ;
   ; Get the Index into the string table to get the right string to copy.
   ; 
   MOV R9D, ESI                                          
   SUB R9D, DECODE_STRING_TABLE.FirstAvailable[RBX] 

   MOV EAX, SIZE STRING_TABLE
   XOR RDX, RDX
   MUL R9D
   LEA RDX, DECODE_STRING_TABLE.StringTableList[RBX]
   ADD RDX, RAX

   DEBUG_FUNCTION_CALL memcpy

  JMP @UpdateStringDecodeBuffersWithMemCopy
;
; This is the ELSE routine.
;
@CheckLastCodeWord:
  ;
  ; Check if LastCodeWord and ClearCode.
  ;
  CMP ESI, DECODE_STRING_TABLE.ClearCode[RBX]  
  JA @UpdateBackStringAndMemCpy  ; Was JAE

  ;
  ;  Update Front and Back string to use Last Code Word
  ;
  MOV ECX, ESI
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP], 1
  MOV STD_FUNCTION_STRING_LOCALS_STACK.FrontString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP], 1

  JMP @UpdateStringDecodeBuffersWithMemCopy
@UpdateBackStringAndMemCpy:
  
;
; Get the index for the string (LastCodeWord - FirstAvailable)*SIZE STRING_TABLE
;
;  CMP ESI, DECODE_STRING_TABLE.ClearCode[RBX]
;  JNE @Skip
;  MOV ESI, DECODE_STRING_TABLE.FirstAvailable[RBX]
;@Skip:

  MOV RAX, RSI
  MOV EDX, DECODE_STRING_TABLE.FirstAvailable[RBX]
  SUB RAX, RDX 
  MOV RCX, SIZE STRING_TABLE
  XOR RDX, RDX
  MUL RCX

  LEA RDX, DECODE_STRING_TABLE.StringTableList[RBX]
  ADD RDX, RAX

  ;
  ; Copy 1 byte to backstring
  ;
  MOV CL, STRING_TABLE.DecodeString[RDX]
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.DecodeString[RSP], CL
  MOV STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP], 1

  ;
  ; Copy Entire String in RDX to Front String
  ;
  LEA RCX, STD_FUNCTION_STRING_LOCALS_STACK.FrontString[RSP]
  MOV R8, SIZE STRING_TABLE
  
  DEBUG_FUNCTION_CALL memcpy

@UpdateStringDecodeBuffersWithMemCopy:

  ;
  ; Set the size to the Front String length.
  ;
  MOV R8D, STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP]

  
  ;
  ; Get the Current StringTable Index
  ;
  XOR RDX, RDX
  MOV R9, SIZE STRING_TABLE
  MOV EAX, DECODE_STRING_TABLE.CurrentIndex[RBX]
  MUL R9
  
  ;
  ; Perform the indexing into the table and get the address
  ;
  LEA RCX, DECODE_STRING_TABLE.StringTableList[RBX]
  ADD RCX, RAX
  LEA RCX, STRING_TABLE.DecodeString[RCX]
  ;
  ; Save RCX for the next round.
  ;
  MOV R14, RCX

  ;
  ; Set the Front String to be copied.
  ;
  LEA RDX, STD_FUNCTION_STRING_LOCALS_STACK.FrontString.DecodeString[RSP]

  DEBUG_FUNCTION_CALL memcpy
  
  ;
  ; Setup advance of String and then set BackString to be copied.
  ;  
  MOV RCX, R14
  MOV R15, R14
  MOV R14D, STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP]
  ADD RCX, R14
  MOV R8D, STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP]
  LEA RDX, STD_FUNCTION_STRING_LOCALS_STACK.BackString.DecodeString[RSP]
  DEBUG_FUNCTION_CALL memcpy

  ;
  ;  Set the current string size
  ;

  MOV EAX, STD_FUNCTION_STRING_LOCALS_STACK.FrontString.StringLength[RSP]
  ADD EAX, STD_FUNCTION_STRING_LOCALS_STACK.BackString.StringLength[RSP]
  MOV STRING_TABLE.StringLength[R15], EAX

  CMP RAX, STRING_SIZE
  JB @NoOutOfBounds

  INT 3                         ; Need to increase the static array size.

@NoOutOfBounds:

  MOV ECX, DECODE_STRING_TABLE.CurrentIndex[RBX]
  ADD ECX, DECODE_STRING_TABLE.FirstAvailable[RBX]
  CMP ECX, STRING_TABLE_SIZE
  JNE @StringTableWithinBounds
int 3
  MOV R12, 1                           ; need to re-initialize string tabel

@StringTableWithinBounds:

  INC DECODE_STRING_TABLE.CurrentIndex[RBX]

  MOV ECX, DECODE_STRING_TABLE.CurrentIndex[RBX]
  ADD ECX, DECODE_STRING_TABLE.FirstAvailable[RBX]

  MOV ECX, DECODE_STRING_TABLE.CurrentCodeBits[RBX]
  MOV EDX, 1
  SHL EDX, CL

  MOV ECX, DECODE_STRING_TABLE.CurrentIndex[RBX]
  ADD ECX, DECODE_STRING_TABLE.FirstAvailable[RBX]

  CMP ECX, EDX
  JNE @ExitFunction

  CMP DECODE_STRING_TABLE.CurrentCodeBits[RBX], 12
  JAE @ExitFunction

  INC DECODE_STRING_TABLE.CurrentCodeBits[RBX]

@ExitFunction:
  MOV RAX, R12
  RESTORE_ALL_STD_REGS STD_FUNCTION_STRING_LOCALS_STACK
  ADD RSP, SIZE STD_FUNCTION_STRING_LOCALS_STACK
  RET
NESTED_END Gif_AddNewEntry, _TEXT$00





END

