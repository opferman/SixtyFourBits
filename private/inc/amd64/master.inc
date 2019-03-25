;****************************************
;
; Master Demo Structure
;
;     Toby Opferman
;
;****************************************

; Structure Definitions
DEMO_STRUCT struct
     InitFunction dq ?
     DemoFunction dq ?
     FreeFunction dq ?
DEMO_STRUCT ends

;
; All data for demos goes in here
;
MASTER_DEMO_STRUCT struct
      CurrentDemoStruct  dq ?
      VideoBuffer        dq ?
      Pitch              dd ?
      Padding            dd ?
      ScreenWidth        dq ?
      ScreenHeight       dq ?	
      BitsPerPixel       dq ?
      DirectDrawCtx      dq ?
;      FullScreen         dq ? ; TBD if needed 
MASTER_DEMO_STRUCT ends

IFNDEF ENGINE_INCLUDE
extern Engine_CreateThread:proc
ENDIF