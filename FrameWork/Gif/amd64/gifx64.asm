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


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include master.inc
include debug_public.inc
include paramhelp_public.inc

;*********************************************************
; Constant Equates 
;*********************************************************
COLOR_MAP_SIZE       EQU <256>
PACK_BLOCK_PTR_ARRAY EQU <5000>
STRING_SIZE          EQU <4096>
STRING_TABLE_SIZE    EQU <4096>
NUMBER_OF_IMAGES     EQU <256>

;*********************************************************
; Macros  
;*********************************************************

BITS_PER_PIXEL_MASK  macro ByteInput
  AND ByteInput, 03h
BITS_PER_PIXEL_MASK endm

CR_BITS_MASK  macro ByteInput
  AND ByteInput, 030h
  SHR ByteInput, 4
CR_BITS_MASK endm

GLOBAL_MAP_DEFINED_MASK macro ByteInput
  AND ByteInput, 080h
  SHR ByteInput, 7
GLOBAL_MAP_DEFINED_MASK endm
  
IMAGE_IS_INTERLACED_MASK macro ByteInput
  AND ByteInput, 040h
  SHR ByteInput, 6
IMAGE_IS_INTERLACED_MASK endm

USE_LOCAL_MAP_MASK macro ByteInput
  AND ByteInput, 080h
  SHR ByteInput, 7
USE_LOCAL_MAP_MASK endm


;*********************************************************
; Structures
;*********************************************************

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
   PackBlocksPtr  dq PACK_BLOCK_PTR_ARRAY  DUP(<?>)
RASTER_DATA ends


IMAGE_DATA struct
  ImageDescriptorPtr dq ?
  LocalColorMapPtr   db ?
  RasterData         RASTER_DATA ?
IMAGE_DATA ends 



STRING_TABLE struct
   DecodeString db STRING_SIZE DUP(<?>)
   StringLength dd ?
STRING_TABLE ends

DECODE_STRING_TABLE struct
   ClearCode         dd ?
   EndOfInformation  dd ?
   FirstAvailable    dd ?
   CurrentIndex      dd ?
   CurrentCodeBits   dd ?
   Stride            dd ?
   StringTable       STRING_TABLE STRING_TABLE_SIZE DUP(<?>)
   LastCodeWord      dd ?
   NewCodeWord       dd ?
   BitIncrement      dd ?
   RasterDataBufferPtr  dq ?
   RasterDataSize    dd ?
   CurrentPixel      dd ?
   ImageWidth        dd ?
   ImagePalettePtr   GIFRGB ?
   ImageX            dd ?
   ImageY            dd ?
   ImageStartLeft    dd ? 
DECODE_STRING_TABLE ends

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



public Gif_DecodeFile


.DATA

   

.CODE


;*********************************************************
;   Gif_DecodeFile
;
;        Parameters: File Name
;
;        Return Value: Gif Handle
;
;
;*********************************************************  
NESTED_ENTRY Gif_DecodeFile, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				; Gif File Name
  
  MOV RDX, SIZE GIF_INTERNAL
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  
  CMP RAX, 0
  JE @FailureExit
  
  MOV RDX, RSI
  MOV RSI, RAX				; Save Gif Internal Pointer
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Gif_OpenAndValidateFile
  CMP RAX, 0
  JE @FailureExit
  
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
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LocalFree
  XOR RAX, RAX  
@DoNotDeAllocate:
@SuccesExit:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
  RET

NESTED_END Gif_DecodeFile, _TEXT$00



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
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  
  DEBUG_FUNCTION_CALL Gif_CloseFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL LocalFree
    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
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
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  
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
    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
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
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV RSI, RCX				
  MOV RCX, RDX
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], OPEN_EXISTING
  XOR R9, R9`
  XOR R8, R8
  MOV RDX, GENERIC_READ
  DEBUG_FUNCTION_CALL CreateFile  
  
  CMP RAX, 0
  JE @FailureExit
  
  MOV RCX, INVALID_HANDLE_VALUE
  CMP RAX, RCX  
  JE @FailureExit
  
  MOV GIF_INTERNAL.hGifFile[RSI], RAX
  
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], 0
  XOR R9, R9
  MOV R8, PAGE_READONLY
  XOR RDX, RDX  
  MOV RCX, GIF_INTERNAL.hGifFile[RSI]  
  DEBUG_FUNCTION_CALL CreateFileMapping
    
  CMP RAX, 0
  JE @FailureExitWithCloseFile
  
  MOV RCX, INVALID_HANDLE_VALUE
  CMP RAX, RCX  
  JE @FailureExitWithCloseFile
  
  MOV GIF_INTERNAL.hMemoryMapping[RSI], RAX
  
  MOV STD_FUNCTION_STACK_PARAMS.Parameters.Param5[RSP], 0
  XOR R9, R9
  XOR R8, R8
  MOV RDX, FILE_MAP_READ
  MOV RCX, GIF_INTERNAL.hMemoryMapping[RSI]
  DEBUG_FUNCTION_CALL MapViewOfFile
  CMP RAX, 0
  JE @FailureExitWithCloseFile
  
  MOV GIF_INTERNAL.StartOfGifPtr[RSP], RAX
  MOV GIF_INTERNAL.GifHeaderPtr[RSP], RAX
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
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
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
  alloc_stack(SIZEOF STD_FUNCTION_STACK_PARAMS)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX				
  
  DEBUG_FUNCTION_CALL Gif_CloseFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL LocalFree
    
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_PARAMS
  ADD RSP, SIZE STD_FUNCTION_STACK_PARAMS
  RET

NESTED_END Gif_ParseFile, _TEXT$00

BOOL WINAPI Gif_ParseFile(PGIF_INTERNAL pGifInternal)
{
    UINT CurrentOffset;
    UINT CurrentRasterBlock;
    BOOL bFileParseSuccessful = TRUE;
    BOOL bMoreImages;
    BOOL bMoreBlocks;

    CurrentOffset = sizeof(GIF_HEADER);
    pGifInternal->pScreenDescriptor = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PSCREEN_DESCRIPTOR);
    CurrentOffset += sizeof(SCREEN_DESCRIPTOR);

    if(pGifInternal->pScreenDescriptor->GlobalMapDefined)
    {
        pGifInternal->pGlobalColorMap = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PGLOBAL_COLOR_MAP);
        CurrentOffset += (UINT)(3*pow(2, ((int)pGifInternal->pScreenDescriptor->BitsPerPixel + 1)));
    }

    do {
        UINT CurrentIndex = pGifInternal->NumberOfImages;

        /*
         * Remove Extension Data
         */
        while(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) != ';' && *((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) != ',')
        {
            CurrentOffset += 2;
            Gif_ParsePackedBlock(pGifInternal, NULL, &CurrentOffset);
        }

        if(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) == ',')
        {
            pGifInternal->ImageData[CurrentIndex].pImageDescriptor = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PIMAGE_DESCRIPTOR);
            CurrentOffset += sizeof(IMAGE_DESCRIPTOR);
           
            if(pGifInternal->ImageData[CurrentIndex].pImageDescriptor->UseLocalMap)
            {
                pGifInternal->ImageData[CurrentIndex].pLocalColorMap = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PLOCAL_COLOR_MAP);
                CurrentOffset += (UINT)(3*pow(2, pGifInternal->ImageData[CurrentIndex].pImageDescriptor->BitsPerPixel + 1));
            }
                        
            CurrentRasterBlock = 0;
            bMoreBlocks = TRUE;

            pGifInternal->ImageData[CurrentIndex].RasterData.CodeSize = *((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset);
            CurrentOffset++;			
            pGifInternal->ImageData[CurrentIndex].RasterData.NumberOfBlocks = Gif_ParsePackedBlock(pGifInternal, pGifInternal->ImageData[CurrentIndex].RasterData.pPackBlocks, &CurrentOffset);
        }

        if(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) == ';')
        {
            bMoreImages = FALSE;
        }

        pGifInternal->NumberOfImages++;
    } while(bMoreImages);   

#if 0
    Gif_DisplayDebugInformation(pGifInternal);
#endif

    return bFileParseSuccessful;
}

END

#define HANDLE_IS_VALID(x) (x != INVALID_HANDLE_VALUE && x != NULL)
#define GET_NEXT_POINTER(x, y, z) (z)((char *)x + y)

#define DEBUGPRINT  
#define DEBUGPRINT2 

#define CREATE_RGB(x) (x.Red<<16 | x.Green<<8 | x.Blue)
#define Gif_IsClearCode(x, y) (x->ClearCode == y)
#define Gif_IsEndOfImageCode(x, y) (x->EndOfInformation == y)
#define CREATE_BIT_MASK(x) ((1<<x)-1)
#define Gif_GetPaletteColorByIndexSpecifyPalette(x, y)  CREATE_RGB(x[y])
#define CODE_TO_INDEX(x,y) (x - y->FirstAvailable)
#define INDEX_TO_CODE(x,y) (x + y->FirstAvailable)

/*********************************************************
 * Internal Functions
 *********************************************************/



void WINAPI Gif_DisplayDebugInformation(PGIF_INTERNAL pGifInternal);
void WINAPI Gif_Debug(char *pszFormatString, ...);
BOOL WINAPI Gif_OpenAndValidateFile(PGIF_INTERNAL pGifInternal, char *pszFileName);
BOOL WINAPI Gif_ParseFile(PGIF_INTERNAL pGifInternal);
UINT WINAPI Gif_ParsePackedBlock(PGIF_INTERNAL pGifInternal, PPACKED_BLOCK *pPackedBlocks, UINT *pOffset);
void WINAPI Gif_CloseFile(PGIF_INTERNAL pGifInternal);
void WINAPI Gif_InitializeStringTable(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, PDECODE_STRING_TABLE pDecodeStringTable);
DWORD WINAPI Gif_GetPaletteColorByIndex(PGIF_INTERNAL pGifInternal, UINT ImageIndex, UINT ColorIndex);
void WINAPI Gif_SetBackgroundColor(PGIF_INTERNAL pGifInternal, UINT ImageIndex, UCHAR *pImageBuffer32bpp);
void WINAPI Gif_Decode(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, UINT Stride, UCHAR *pImageBuffer32bpp);
BOOL WINAPI Gif_DecodePackedBlock(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, PDECODE_STRING_TABLE pDecodeStringTable);
UINT WINAPI Gif_RetrieveCodeWord(PDECODE_STRING_TABLE pDecodeStringTable, UINT *pBitIncrement, UCHAR *pPackedBlockBytes);
BOOL WINAPI Gif_ProcessNewCode(PDECODE_STRING_TABLE pDecodeStringTable, UINT LastCodeWord, UINT NewCodeWord);
BOOL WINAPI Gif_AddNewEntry(PDECODE_STRING_TABLE pDecodeStringTable, UINT LastCodeWord, UINT NewCodeWord);


 


 /********************************************************
  *  Gif_OpenAndValidateFile
  *
  *     
  *   
  *
  *
  ********************************************************/
/***********************************************************************
 * Gif_ParseFile
 *  
 *    Gif_ParseFile 
 *
 *    
 *
 * Parameters
 *     Gif Internal
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
BOOL WINAPI Gif_ParseFile(PGIF_INTERNAL pGifInternal)
{
    UINT CurrentOffset;
    UINT CurrentRasterBlock;
    BOOL bFileParseSuccessful = TRUE;
    BOOL bMoreImages;
    BOOL bMoreBlocks;

    CurrentOffset = sizeof(GIF_HEADER);
    pGifInternal->pScreenDescriptor = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PSCREEN_DESCRIPTOR);
    CurrentOffset += sizeof(SCREEN_DESCRIPTOR);

    if(pGifInternal->pScreenDescriptor->GlobalMapDefined)
    {
        pGifInternal->pGlobalColorMap = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PGLOBAL_COLOR_MAP);
        CurrentOffset += (UINT)(3*pow(2, ((int)pGifInternal->pScreenDescriptor->BitsPerPixel + 1)));
    }

    do {
        UINT CurrentIndex = pGifInternal->NumberOfImages;

        /*
         * Remove Extension Data
         */
        while(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) != ';' && *((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) != ',')
        {
            CurrentOffset += 2;
            Gif_ParsePackedBlock(pGifInternal, NULL, &CurrentOffset);
        }

        if(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) == ',')
        {
            pGifInternal->ImageData[CurrentIndex].pImageDescriptor = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PIMAGE_DESCRIPTOR);
            CurrentOffset += sizeof(IMAGE_DESCRIPTOR);
           
            if(pGifInternal->ImageData[CurrentIndex].pImageDescriptor->UseLocalMap)
            {
                pGifInternal->ImageData[CurrentIndex].pLocalColorMap = GET_NEXT_POINTER(pGifInternal->pStartOfGif, CurrentOffset, PLOCAL_COLOR_MAP);
                CurrentOffset += (UINT)(3*pow(2, pGifInternal->ImageData[CurrentIndex].pImageDescriptor->BitsPerPixel + 1));
            }
                        
            CurrentRasterBlock = 0;
            bMoreBlocks = TRUE;

            pGifInternal->ImageData[CurrentIndex].RasterData.CodeSize = *((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset);
            CurrentOffset++;			
            pGifInternal->ImageData[CurrentIndex].RasterData.NumberOfBlocks = Gif_ParsePackedBlock(pGifInternal, pGifInternal->ImageData[CurrentIndex].RasterData.pPackBlocks, &CurrentOffset);
        }

        if(*((UCHAR *)pGifInternal->pStartOfGif + CurrentOffset) == ';')
        {
            bMoreImages = FALSE;
        }

        pGifInternal->NumberOfImages++;
    } while(bMoreImages);   

#if 0
    Gif_DisplayDebugInformation(pGifInternal);
#endif

    return bFileParseSuccessful;
}


/***********************************************************************
 * Gif_ParsePackedBlock
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Offset
 *
 ***********************************************************************/
UINT WINAPI Gif_ParsePackedBlock(PGIF_INTERNAL pGifInternal, PPACKED_BLOCK *pPackedBlocks, UINT *pOffset)
{
    BOOL bMoreBlocks = TRUE;
    PPACKED_BLOCK pPackedBlock;
    UINT CurrentRasterBlock = 0;


    do {

        pPackedBlock = GET_NEXT_POINTER(pGifInternal->pStartOfGif, (*pOffset), PPACKED_BLOCK);
        (*pOffset) += pPackedBlock->BlockByteCount + 1;

        if(pPackedBlocks)
        {
             *pPackedBlocks = pPackedBlock;
             pPackedBlocks++;
        }

        if(pPackedBlock->BlockByteCount == 0)
        {
            bMoreBlocks = FALSE;
        }

        CurrentRasterBlock++;			
    } while(bMoreBlocks);

    return CurrentRasterBlock;
}


/***********************************************************************
 * Gif_DisplayDebugInformation
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
void WINAPI Gif_DisplayDebugInformation(PGIF_INTERNAL pGifInternal)
{
    UINT Index;

    DEBUGPRINT2("Signature (%c%c%c%c%c%c)\n", pGifInternal->pGifHeader->Signature[0], pGifInternal->pGifHeader->Signature[1], pGifInternal->pGifHeader->Signature[2],pGifInternal->pGifHeader->Version[0], pGifInternal->pGifHeader->Version[1], pGifInternal->pGifHeader->Version[2]);
    DEBUGPRINT2("Resolution (%i, %i)\n", pGifInternal->pScreenDescriptor->ScreenWidth, pGifInternal->pScreenDescriptor->ScreenHeight);
    DEBUGPRINT2("Bits Per Pixel (%i)\n", (int)(pGifInternal->pScreenDescriptor->BitsPerPixel + 1));
    DEBUGPRINT2("Global Color Map Defined (%i)\n", (int)(pGifInternal->pScreenDescriptor->GlobalMapDefined));
    DEBUGPRINT2("Background Color Index (%i)\n", pGifInternal->pScreenDescriptor->ScreenBackgroundColorIndex);

    Index = 0;
    do {
        DEBUGPRINT2("\nImage # %i\n", Index);
        DEBUGPRINT2(" Image Signature (%c)\n", pGifInternal->ImageData[Index].pImageDescriptor->ImageSeperator);
        DEBUGPRINT2(" Image Position (%i, %i)\n", pGifInternal->ImageData[Index].pImageDescriptor->ImageStartLeft, pGifInternal->ImageData[Index].pImageDescriptor->ImageStartTop);
        DEBUGPRINT2(" Image Size (%i, %i)\n", pGifInternal->ImageData[Index].pImageDescriptor->ImageWidth, pGifInternal->ImageData[Index].pImageDescriptor->ImageHeight);
        DEBUGPRINT2(" Bits Per Pixel (%i)\n", pGifInternal->ImageData[Index].pImageDescriptor->BitsPerPixel + 1);
        DEBUGPRINT2(" Image is Interlaced (%i)\n", pGifInternal->ImageData[Index].pImageDescriptor->ImageIsInterlaced);
        DEBUGPRINT2(" Image uses Local Map (%i)\n", pGifInternal->ImageData[Index].pImageDescriptor->UseLocalMap);
        DEBUGPRINT2(" Raster Data contains (%i) blocks\n", pGifInternal->ImageData[Index].RasterData.NumberOfBlocks);

        Index++;
    } while(Index < pGifInternal->NumberOfImages);

}

/***********************************************************************
 * Gif_NumberOfImages
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
UINT WINAPI Gif_NumberOfImages(HGIF hGif)
{
    PGIF_INTERNAL pGifInternal = (PGIF_INTERNAL)hGif;

    return pGifInternal->NumberOfImages;
}



/***********************************************************************
 * Gif_NumberOfImages
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
UINT WINAPI Gif_GetImageSize(HGIF hGif, UINT Index)
{
    PGIF_INTERNAL pGifInternal = (PGIF_INTERNAL)hGif;
    UINT SizeCalculation;

    SizeCalculation = pGifInternal->pScreenDescriptor->ScreenWidth*pGifInternal->pScreenDescriptor->ScreenHeight*4;

    return SizeCalculation;
}

/***********************************************************************
 * Gif_GetImageWidth
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
UINT WINAPI Gif_GetImageWidth(HGIF hGif, UINT Index)
{
    PGIF_INTERNAL pGifInternal = (PGIF_INTERNAL)hGif;

    return pGifInternal->pScreenDescriptor->ScreenWidth;
}


/***********************************************************************
 * Gif_GetImageHeight
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
UINT WINAPI Gif_GetImageHeight(HGIF hGif, UINT Index)
{
    PGIF_INTERNAL pGifInternal = (PGIF_INTERNAL)hGif;

    return pGifInternal->pScreenDescriptor->ScreenHeight;
}



/***********************************************************************
 * Gif_GetImage32bpp
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     Nothing
 *                                                   
 ***********************************************************************/
void WINAPI Gif_GetImage32bpp(HGIF hGif, UINT Index, UCHAR *pImageBuffer32bpp)
{
    PGIF_INTERNAL pGifInternal = (PGIF_INTERNAL)hGif;
    PIMAGE_DATA pImageData;
    UINT Stride;
    UINT Width;
    UINT StartOffset;

    if(Index < pGifInternal->NumberOfImages)
    {
        pImageData = &pGifInternal->ImageData[Index];
        Gif_SetBackgroundColor(pGifInternal, Index, pImageBuffer32bpp);

        StartOffset = pImageData->pImageDescriptor->ImageStartLeft + (pImageData->pImageDescriptor->ImageStartTop*pGifInternal->pScreenDescriptor->ScreenWidth);
        pImageBuffer32bpp += (StartOffset*4);

        Stride = (pGifInternal->pScreenDescriptor->ScreenWidth - pImageData->pImageDescriptor->ImageWidth);

        Gif_Decode(pGifInternal, pImageData, Stride, pImageBuffer32bpp);
    }
} 


/***********************************************************************
 * Gif_InitializeStringTable
 *  
 *    Gif_InitializeStringTable 
 *
 *    
 *
 * Parameters
 *     Gif_InitializeStringTable
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
void WINAPI Gif_InitializeStringTable(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, PDECODE_STRING_TABLE pDecodeStringTable)
{
    pDecodeStringTable->ClearCode        = (UINT)(pow(2, pImageData->RasterData.CodeSize));
    pDecodeStringTable->EndOfInformation = pDecodeStringTable->ClearCode + 1;
    pDecodeStringTable->FirstAvailable   = pDecodeStringTable->ClearCode + 2;
    pDecodeStringTable->CurrentIndex     = 0;
    pDecodeStringTable->CurrentCodeBits  = pImageData->RasterData.CodeSize + 1;
    pDecodeStringTable->ImageWidth       = pImageData->pImageDescriptor->ImageWidth;
    pDecodeStringTable->LastCodeWord     = pDecodeStringTable->ClearCode;
}

/***********************************************************************
 * Gif_Debug
 *  
 *    Debug 
 *
 *    
 *
 * Parameters
 *     Debug
 *
 * Return Value
 *     Nothing
 *
 ***********************************************************************/
 void Gif_Debug(char *pszFormatString, ...)
 {
     char DebugString[256];
     va_list vl;

     va_start(vl, pszFormatString);
     vsprintf(DebugString, pszFormatString, vl);
     va_end(vl);

     OutputDebugStringA(DebugString);
 }


/***********************************************************************
 * Gif_GetPaletteColorByIndex
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
 DWORD WINAPI Gif_GetPaletteColorByIndex(PGIF_INTERNAL pGifInternal, UINT ImageIndex, UINT ColorIndex)
 {
     DWORD Color32Bit = 0;

     if(pGifInternal->ImageData[ImageIndex].pImageDescriptor->UseLocalMap)
     {
         Color32Bit = CREATE_RGB(pGifInternal->ImageData[ImageIndex].pLocalColorMap->GifRgbIndex[ColorIndex]);
     }
     else
     {
         Color32Bit = CREATE_RGB(pGifInternal->pGlobalColorMap->GifRgbIndex[ColorIndex]);

     }

     return Color32Bit;
 }


/***********************************************************************
 * Gif_SetBackgroundColor
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
 void WINAPI Gif_SetBackgroundColor(PGIF_INTERNAL pGifInternal, UINT ImageIndex, UCHAR *pImageBuffer32bpp)
 {
     DWORD BackgroundColor;
     UINT Index;

     BackgroundColor = Gif_GetPaletteColorByIndex(pGifInternal, ImageIndex, pGifInternal->pScreenDescriptor->ScreenBackgroundColorIndex);

     Index = 0;
     while(Index < ((UINT)pGifInternal->pScreenDescriptor->ScreenWidth*(UINT)pGifInternal->pScreenDescriptor->ScreenHeight))
     {
         *((DWORD *)pImageBuffer32bpp) = BackgroundColor;
         pImageBuffer32bpp += 4;
         Index++;
     }

 }





/***********************************************************************
 * Gif_Decode
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
 void WINAPI Gif_Decode(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, UINT Stride, UCHAR *pImageBuffer32bpp)
 {
     PDECODE_STRING_TABLE pDecodeStringTable = NULL;
     UINT Index = 0;
     UCHAR *pRasterDataBuffer;

     pDecodeStringTable = (PDECODE_STRING_TABLE)LocalAlloc(LMEM_ZEROINIT, sizeof(DECODE_STRING_TABLE));

     if(pDecodeStringTable)
     {
         pDecodeStringTable->ImageX            = pImageData->pImageDescriptor->ImageStartLeft;
         pDecodeStringTable->ImageStartLeft    = pImageData->pImageDescriptor->ImageStartLeft;
         pDecodeStringTable->ImageY            = pImageData->pImageDescriptor->ImageStartTop;
         pDecodeStringTable->pImageBuffer32bpp = (DWORD *)pImageBuffer32bpp;
         pDecodeStringTable->Stride            = Stride;

         if(pImageData->pImageDescriptor->UseLocalMap)
         {
             pDecodeStringTable->pImagePalette = pImageData->pLocalColorMap->GifRgbIndex;
         }
         else
         {
             pDecodeStringTable->pImagePalette = pGifInternal->pGlobalColorMap->GifRgbIndex;
         }

         Gif_InitializeStringTable(pGifInternal, pImageData, pDecodeStringTable);
         pDecodeStringTable->BitIncrement = 0;
         pDecodeStringTable->RasterDataSize = 0;
                  
         for(Index = 0; Index < pImageData->RasterData.NumberOfBlocks; Index++)
         {
             pDecodeStringTable->RasterDataSize += pImageData->RasterData.pPackBlocks[Index]->BlockByteCount;
         }

         pDecodeStringTable->pRasterDataBuffer = (PCHAR)LocalAlloc(LMEM_ZEROINIT, pDecodeStringTable->RasterDataSize);

         if(pDecodeStringTable->pRasterDataBuffer)
         {
             pRasterDataBuffer = pDecodeStringTable->pRasterDataBuffer;
             for(Index = 0; Index < pImageData->RasterData.NumberOfBlocks; Index++)
             {
                memcpy(pRasterDataBuffer, &pImageData->RasterData.pPackBlocks[Index]->DataBytes[0], pImageData->RasterData.pPackBlocks[Index]->BlockByteCount);
                pRasterDataBuffer += pImageData->RasterData.pPackBlocks[Index]->BlockByteCount;
             }

             Gif_DecodePackedBlock(pGifInternal, pImageData, pDecodeStringTable);
             LocalFree(pDecodeStringTable->pRasterDataBuffer);
         }

         LocalFree(pDecodeStringTable);
     }
 }



 /***********************************************************************
 * Gif_Decode
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
BOOL WINAPI Gif_DecodePackedBlock(PGIF_INTERNAL pGifInternal, PIMAGE_DATA pImageData, PDECODE_STRING_TABLE pDecodeStringTable)
{
    UINT Index;
    UINT EndOfBlock;
    BOOL ContinueProcessing = TRUE;
    UCHAR *pPackedBlockBytes;
    
    EndOfBlock = pDecodeStringTable->RasterDataSize;
    pPackedBlockBytes = pDecodeStringTable->pRasterDataBuffer;

    for(Index = 0; Index < EndOfBlock && ContinueProcessing;)
    {
        pDecodeStringTable->NewCodeWord = Gif_RetrieveCodeWord(pDecodeStringTable, &pDecodeStringTable->BitIncrement, pPackedBlockBytes);

        if(Gif_IsClearCode(pDecodeStringTable, pDecodeStringTable->NewCodeWord))
        {
            Gif_InitializeStringTable(pGifInternal, pImageData, pDecodeStringTable);
        }
        else
        {
            if(Gif_IsEndOfImageCode(pDecodeStringTable, pDecodeStringTable->NewCodeWord))
            {
                DEBUGPRINT2(" EOI Command\n");
                ContinueProcessing = FALSE;
            }
            else
            {
                if(Gif_ProcessNewCode(pDecodeStringTable, pDecodeStringTable->LastCodeWord, pDecodeStringTable->NewCodeWord))
                {
                    Gif_InitializeStringTable(pGifInternal, pImageData, pDecodeStringTable);
                }
                else
                {
                    pDecodeStringTable->LastCodeWord = pDecodeStringTable->NewCodeWord;
                }
            }
        }

        while(pDecodeStringTable->BitIncrement >= 8)
        {
            pPackedBlockBytes++;
            Index++;
            pDecodeStringTable->BitIncrement = pDecodeStringTable->BitIncrement - 8;
        }
        
    }

    DEBUGPRINT2(" Processed %i of %i\n", Index, EndOfBlock);

    return ContinueProcessing;
}



 /***********************************************************************
 * Gif_ProcessNewCode
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
BOOL WINAPI Gif_ProcessNewCode(PDECODE_STRING_TABLE pDecodeStringTable, UINT LastCodeWord, UINT NewCodeWord)
{
    DWORD Pixel;
    BOOL ReinitializeStringTable = FALSE;

    if(NewCodeWord < pDecodeStringTable->ClearCode)
    {
        Pixel = Gif_GetPaletteColorByIndexSpecifyPalette(pDecodeStringTable->pImagePalette, NewCodeWord);
        pDecodeStringTable->pImageBuffer32bpp[pDecodeStringTable->CurrentPixel] = Pixel;
        pDecodeStringTable->CurrentPixel++;

        if(pDecodeStringTable->CurrentPixel >= pDecodeStringTable->ImageWidth)
        {
            pDecodeStringTable->pImageBuffer32bpp += pDecodeStringTable->Stride + pDecodeStringTable->ImageWidth;
            pDecodeStringTable->CurrentPixel = 0;
        }

        if(LastCodeWord != pDecodeStringTable->ClearCode)
        {
            ReinitializeStringTable = Gif_AddNewEntry(pDecodeStringTable, LastCodeWord, NewCodeWord);			
        }
    }
    else
    {	
        UINT PixelIndex;
        
        ReinitializeStringTable = Gif_AddNewEntry(pDecodeStringTable, LastCodeWord, NewCodeWord);		

        for(PixelIndex = 0; PixelIndex < pDecodeStringTable->StringTable[CODE_TO_INDEX(NewCodeWord, pDecodeStringTable)].Length; PixelIndex++)
        {
            Pixel = Gif_GetPaletteColorByIndexSpecifyPalette(pDecodeStringTable->pImagePalette, pDecodeStringTable->StringTable[CODE_TO_INDEX(NewCodeWord, pDecodeStringTable)].DecodeString[PixelIndex]);
            pDecodeStringTable->pImageBuffer32bpp[pDecodeStringTable->CurrentPixel] = Pixel;
            pDecodeStringTable->CurrentPixel++;
            pDecodeStringTable->ImageX++;

            
            if(pDecodeStringTable->CurrentPixel >= pDecodeStringTable->ImageWidth)
            {
                pDecodeStringTable->pImageBuffer32bpp += pDecodeStringTable->Stride + pDecodeStringTable->ImageWidth;
                pDecodeStringTable->CurrentPixel = 0;
                
                pDecodeStringTable->ImageX = pDecodeStringTable->ImageStartLeft;
                pDecodeStringTable->ImageY++;
            }
            
        }
    }

    return ReinitializeStringTable;
}


 /***********************************************************************
 * Gif_ProcessNewCode
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
BOOL WINAPI Gif_AddNewEntry(PDECODE_STRING_TABLE pDecodeStringTable, UINT LastCodeWord, UINT NewCodeWord)
{
    STRING_TABLE FrontString;
    STRING_TABLE BackString;
    BOOL ReinitializeStringTable = FALSE;

    if(NewCodeWord < pDecodeStringTable->ClearCode || CODE_TO_INDEX(NewCodeWord,pDecodeStringTable) < pDecodeStringTable->CurrentIndex)
    {
        if(NewCodeWord < pDecodeStringTable->ClearCode)
        {
            BackString.DecodeString[0] = (UCHAR)NewCodeWord;
            BackString.Length          = 1;
        }
        else
        {
            BackString.DecodeString[0] = pDecodeStringTable->StringTable[CODE_TO_INDEX(NewCodeWord, pDecodeStringTable)].DecodeString[0];
            BackString.Length          = 1;
        }

        if(LastCodeWord < pDecodeStringTable->ClearCode)
        {
            FrontString.DecodeString[0] = (UCHAR)LastCodeWord;
            FrontString.Length          = 1;
        }
        else
        {
            memcpy(&FrontString, &pDecodeStringTable->StringTable[CODE_TO_INDEX(LastCodeWord, pDecodeStringTable)], sizeof(STRING_TABLE));
        }
    }
    else
    {
        if(LastCodeWord < pDecodeStringTable->ClearCode)
        {
            BackString.DecodeString[0] = (UCHAR)LastCodeWord;
            BackString.Length          = 1;

            FrontString.DecodeString[0] = (UCHAR)LastCodeWord;
            FrontString.Length          = 1;
        }
        else
        {
            BackString.DecodeString[0] = pDecodeStringTable->StringTable[CODE_TO_INDEX(LastCodeWord, pDecodeStringTable)].DecodeString[0];
            BackString.Length          = 1;

            memcpy(&FrontString, &pDecodeStringTable->StringTable[CODE_TO_INDEX(LastCodeWord, pDecodeStringTable)], sizeof(STRING_TABLE));
        }
    }

    memcpy(pDecodeStringTable->StringTable[pDecodeStringTable->CurrentIndex].DecodeString, FrontString.DecodeString, FrontString.Length);
    memcpy(pDecodeStringTable->StringTable[pDecodeStringTable->CurrentIndex].DecodeString + FrontString.Length, BackString.DecodeString, BackString.Length);
    pDecodeStringTable->StringTable[pDecodeStringTable->CurrentIndex].Length = FrontString.Length + BackString.Length;
    
    if(pDecodeStringTable->StringTable[pDecodeStringTable->CurrentIndex].Length >= 4096)
    {
        DebugBreak();
    }

    if(INDEX_TO_CODE(pDecodeStringTable->CurrentIndex, pDecodeStringTable) == 4096)
    {
        ReinitializeStringTable = TRUE;
        DEBUGPRINT2(" Re-Initialize String Table %i %i\n", pDecodeStringTable->CurrentIndex, INDEX_TO_CODE(pDecodeStringTable->CurrentIndex, pDecodeStringTable));
    }

    pDecodeStringTable->CurrentIndex++; 

    if(INDEX_TO_CODE(pDecodeStringTable->CurrentIndex, pDecodeStringTable) == (UINT)pow(2, pDecodeStringTable->CurrentCodeBits))
    {
        if(pDecodeStringTable->CurrentCodeBits < 12)
        {
            pDecodeStringTable->CurrentCodeBits++;
        }
        DEBUGPRINT2(" Code Bits Increase %i\n", pDecodeStringTable->CurrentCodeBits);
    }

    return ReinitializeStringTable;
}




 /***********************************************************************
 * Gif_RetrieveCodeWord
 *  
 *     
 *
 *    
 *
 * Parameters
 *     
 *
 * Return Value
 *     
 *
 ***********************************************************************/
UINT WINAPI Gif_RetrieveCodeWord(PDECODE_STRING_TABLE pDecodeStringTable, UINT *pBitIncrement, UCHAR *pPackedBlockBytes)
{
    UINT CodeWord;

    CodeWord = (UINT)(*((UINT *)pPackedBlockBytes) >> *pBitIncrement) & CREATE_BIT_MASK(pDecodeStringTable->CurrentCodeBits);

    *pBitIncrement += pDecodeStringTable->CurrentCodeBits;

    return CodeWord;
}
