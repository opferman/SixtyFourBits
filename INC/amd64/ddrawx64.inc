;****************************************
;
; Direct Draw x64 Definitions
;
;     Toby Opferman
;
;****************************************


; Function Procedures
extern DirectDrawCreate:proc

; Constants


; Structure Definitions


DDRAWDD_QueryInterface             EQU <00h>
DDRAWDD_AddRef                     EQU <08h>
DDRAWDD_Release                    EQU <10h>
DDRAWDD_Compact                    EQU <18h>
DDRAWDD_CreateClipper              EQU <20h>
DDRAWDD_CreatePalette              EQU <28h>
DDRAWDD_CreateSurface              EQU <30h>
DDRAWDD_DuplicateSurface           EQU <38h>
DDRAWDD_EnumDisplayModes           EQU <40h>
DDRAWDD_EnumSurfaces               EQU <48h>
DDRAWDD_FlipToGDISurface           EQU <50h>
DDRAWDD_GetCaps                    EQU <58h>
DDRAWDD_GetDisplayMode             EQU <60h>
DDRAWDD_GetFourCCCodes             EQU <68h>
DDRAWDD_GetGDISurface              EQU <70h>
DDRAWDD_GetMonitorFrequency        EQU <78h>
DDRAWDD_GetScanLine                EQU <80h>
DDRAWDD_GetVerticalBlankStatus     EQU <88h>
DDRAWDD_Initialize                 EQU <90h>
DDRAWDD_RestoreDisplayMode         EQU <98h>
DDRAWDD_SetCooperativeLevel        EQU <0A0h>
DDRAWDD_SetDisplayMode             EQU <0A8h>
DDRAWDD_WaitForVerticalBlank       EQU <0B0h>

;
; Offsets Into Direct Draw Surface Virtual Table
;
DDRAWDD_Surface_QueryInterface          EQU <00h>
DDRAWDD_Surface_AddRef                  EQU <08h>
DDRAWDD_Surface_Release                 EQU <10h>
DDRAWDD_Surface_AddAttachedSurface      EQU <18h>
DDRAWDD_Surface_AddOverlayDirtyRect     EQU <20h>
DDRAWDD_Surface_Blt                     EQU <28h>
DDRAWDD_Surface_BltBatch                EQU <30h>
DDRAWDD_Surface_BltFast                 EQU <38h>
DDRAWDD_Surface_DeleteAttachedSurfaces  EQU <40h>
DDRAWDD_Surface_EnumAttachedSurfaces    EQU <48h>
DDRAWDD_Surface_EnumOverlayZOrders      EQU <50h>
DDRAWDD_Surface_Flip                    EQU <58h>
DDRAWDD_Surface_GetAttachedSurface      EQU <60h>
DDRAWDD_Surface_GetBltStatus            EQU <68h>
DDRAWDD_Surface_GetCaps                 EQU <70h>
DDRAWDD_Surface_GetClipper              EQU <78h>
DDRAWDD_Surface_GetColorKey             EQU <80h>
DDRAWDD_Surface_GetDC                   EQU <88h>
DDRAWDD_Surface_GetFlipStatus           EQU <90h>
DDRAWDD_Surface_GetOverlayPosition      EQU <98h>
DDRAWDD_Surface_GetPalette              EQU <0A0h>
DDRAWDD_Surface_GetPixelFormat          EQU <0A8h>
DDRAWDD_Surface_GetSurfaceDesc          EQU <0B0h>
DDRAWDD_Surface_Initialize              EQU <0B8h>
DDRAWDD_Surface_IsLost                  EQU <0C0h>
DDRAWDD_Surface_Lock                    EQU <0C8h>
DDRAWDD_Surface_ReleaseDC               EQU <0D0h>
DDRAWDD_Surface_Restore                 EQU <0D8h>
DDRAWDD_Surface_SetClipper              EQU <0E0h>
DDRAWDD_Surface_SetColorKey             EQU <0E8h>
DDRAWDD_Surface_SetOverlayPosition      EQU <0F0h>
DDRAWDD_Surface_SetPalette                   EQU <0F8h>
DDRAWDD_Surface_Unlock                       EQU <100h>
DDRAWDD_Surface_UpdateOverlay                EQU <108h>
DDRAWDD_Surface_UpdateOverlayDisplay         EQU <110h>
DDRAWDD_Surface_UpdateOverlayZOrder          EQU <118h>

DDRAWDD_UnInitedClipperQueryInterface        EQU <00h>
DDRAWDD_Clipper_AddRef                       EQU <08h>  
DDRAWDD_Clipper_Release						 EQU <10h>  
DDRAWDD_Clipper_GetClipList					 EQU <18h>  
DDRAWDD_Clipper_GetHWnd						 EQU <20h>  
DDRAWDD_Clipper_Initialize					 EQU <28h>  
DDRAWDD_Clipper_IsClipListChanged			 EQU <30h>  
DDRAWDD_Clipper_SetClipList					 EQU <38h>  
DDRAWDD_Clipper_SetHWnd       				 EQU <40h>

DDERR_SURFACELOST     EQU <0887601C2h>
											   
; Constants									
DDLOCK_NOSYSLOCK	    EQU <800h>
DDSCL_FULLSCREEN        EQU <1>
DDSCL_NORMAL            EQU <8>
DDSD_CAPS               EQU <1>
DDSCAPS_PRIMARYSURFACE  EQU <200h>
DDSCAPS_BACKBUFFER      EQU <4>
DDSCL_ALLOWMODEX        EQU <40h>
DDSD_BACKBUFFERCOUNT    EQU <20h>
DDSCL_EXCLUSIVE         EQU <10h>
DDSCAPS_FLIP            EQU <10h>
DDSCAPS_COMPLEX         EQU <8>
DDSCL_ALLOWREBOOT       EQU <2>
DDLOCK_SURFACEMEMORYPTR EQU <0>
DDFLIP_WAIT             EQU <1>
DDLOCK_WAIT             EQU <1> 
DDSD_HEIGHT             EQU <2>
DDSD_WIDTH              EQU <4>
DDSCAPS_OFFSCREENPLAIN  EQU <40h>
DDBLT_WAIT              EQU <01000000h>
DDBLTFAST_WAIT          EQU <10h>

; Error Code Constants
DD_OK                   EQU <0>
DDSCAPS                 EQU <dd>
LPDIRECTDRAW            EQU <dq>
LPDIRECTDRAWSURFACE     EQU <dq>
LPDIRECTBACKSURFACE     EQU <dq>
LPDIRECTDRAWCLIPPER     EQU <dq>

; Structures
DDCOLORKEY STRUCT
    dwColorSpaceLowValue   dd ?
    dwColorSpaceHighValue  dd ?
DDCOLORKEY ENDS
 
DDPIXELFORMAT STRUCT
    dwSize               dd ?
    dwFlags              dd ?
    dwFourCC             dd ?
    
    dwRGBBitCount        dd ?
    
    dwRBitMask           dd ?
    
    dwGBitMask           dd ?
    
    dwBBitMask           dd ?
    
    dwRGBAlphaBitMask    dd ?
DDPIXELFORMAT ENDS



 
DDSURFACEDESC struct  
    dwSize              dd ?
    dwFlags             dd ?
    dwHeight            dd ?
    dwWidth             dd ?
    
    lPitch              dd ?
    
    dwBackBufferCount   dd ?
    
    RefreshRate         dd ?
    
    dwAlphaBitDepth     dd ?
    dwReserved          dd ?
    dqPadding           dd ?
    lpSurface           dq ?
    
    ddckCKDestOverlay   DDCOLORKEY <?>
    ddckCKDestBlt       DDCOLORKEY <?>
    ddckCKSrcOverlay    DDCOLORKEY <?>
    ddckCKSrcBlt        DDCOLORKEY <?>
    
    ddpfPixelFormat     DDPIXELFORMAT <?>
    ddsCapsctx          DDSCAPS ?
    dqPadding2           dd ?
DDSURFACEDESC ends


DDRAW_INTERNAL_CONTEXT struct
    lpDirectDrawctx          LPDIRECTDRAW ?
    lpDirectDrawSurfacectx   LPDIRECTDRAWSURFACE ?
    lpDirectBackSurfacectx   LPDIRECTBACKSURFACE ?
	lpDirectDrawClipperCtx   LPDIRECTDRAWCLIPPER ?
    hWnd                     dq ?
    DdSurfaceDescription     DDSURFACEDESC <?>
    DSurfaceCaps             dq ?
	FullScreenMode           dq ?
    
DDRAW_INTERNAL_CONTEXT ends
