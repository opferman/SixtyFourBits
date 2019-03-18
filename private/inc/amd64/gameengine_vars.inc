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

GAME_ENGINE_INIT struct
   GameFunctionPtrs dq ?
   GameLoadCxt      dq ?
   GameLoadFunction dq ?
GAME_ENGINE_INIT ends

