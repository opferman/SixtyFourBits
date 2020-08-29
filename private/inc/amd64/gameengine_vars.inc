;****************************************
;
; Game Engine Internals
;
;     Toby Opferman
;
;****************************************

GAME_ENGINE_FAILURE_STATE EQU <0FFFFh>

IMAGE_INFORMATION struct
   GifHandle      dq ?
   ImageListPtr   dq ?
   ImgOffsets     dq ?
   NumberOfImages dq ?
   CurrImagePtr   dq ?
   CurrentImage   dq ?
   ImageFrameNum  dq ?
   ImageMaxFrames dq ?
   ImageWidth     dq ?
   ImageHeight    dq ?
   StartX         dq ?
   StartY         dq ?
   InflateCountDown    dq ?
   InflateCountDownMax dq ?
   IncrementX          mmword ?
   IncrementY          mmword ?
IMAGE_INFORMATION ends

SPRITE_BASIC_INFORMATION struct
   SpriteListPtr           dq ?
   SpriteOffsets           dq ?
   NumberOfSprites         dq ?
   CurrSpritePtr           dq ?
   CurrentSprite           dq ?
   SpriteFrameNum          dq ?
   SpriteMaxFrames         dq ?
   SpriteWidth             dq ?
   SpriteHeight            dq ?
   SpriteTransparentColor  dd ?   
SPRITE_BASIC_INFORMATION ends

SPRITE_CONVERT struct
    ImageInformationPtr       dq ?
	SpriteBasicInformtionPtr  dq ?
	SpriteBasicAllocated      dq ?
	SpriteX                   dq ?
	SpriteY                   dq ?
	SpriteX2                  dq ?
	SpriteY2                  dq ?
	SpriteImageStart          dq ?
	SpriteNumImages           dq ?
SPRITE_CONVERT ends


GAME_ENGINE_INIT struct
   GameFunctionPtrs dq ?
   GameLoadCxt      dq ?
   GameLoadFunction dq ?
GAME_ENGINE_INIT ends

SCROLLING_GIF struct
   CurrentX         dq ?
   CurrentY         dq ?
   XIncrement       dq ?
   YIncrement       dq ?
   ImageInformation dq ?
SCROLLING_GIF ends


