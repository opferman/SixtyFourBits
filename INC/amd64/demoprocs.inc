;****************************************
;
; Demo Procedures
;
;     Toby Opferman
;
;****************************************

; Window Procedures
extern Windowx64_Setup:proc
extern Windowx64_Loop:proc
extern DDrawx64_Init:proc
extern DDrawx64_Free:proc
extern DDrawx64_LockSurfaceBuffer:proc
extern DDrawx64_UnLockSurfaceAndFlip:proc
extern DDrawx64_GetScreenRes:proc
extern Math_Init:proc
extern DDrawx64_PixelPlot:proc
extern DDrawx64_RestoreSurfacesIfNeeded:proc