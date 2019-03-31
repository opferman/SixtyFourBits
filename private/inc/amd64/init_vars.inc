;****************************************
;
; Initialization Library
;
;     Toby Opferman
;
;****************************************



;
; Initialization of Demo Library
;
INIT_DEMO_STRUCT struct
      BitsPerPixel          dq ?
      ScreenWidth           dq ?
      ScreenHeight          dq ?
      pszWindowTitle        dq ?
      pszWindowClass        dq ?
      GlobalDemoStructure   dq ?
      FullScreen            dq ? 
      EmulateVRTrace        dq ?
      DisableEscapeExit     dq ?
      PaddingReserved       dq ?
      PaddingReserved2      dq ?
INIT_DEMO_STRUCT ends


