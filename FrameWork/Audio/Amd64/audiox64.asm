;*********************************************************
; Audio Library 
;
;  Written in Assembly x64
; 
;     Audio Library
;
;
;  By Toby Opferman  2020
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
include demoscene.inc
include windowsx64_public.inc
include audio_vars.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern CoInitialize:proc
extern CreateThread:proc
extern CoCreateInstance:proc
extern DeleteCriticalSection:proc
extern Sleep:proc

;
; Audio Constants
;
CLSCTX_ALL  EQU <017h>
eRender     EQU <0>
eMultimedia EQU <1>
AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM         EQU <080000000h> 
AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY    EQU <08000000h>  
AUDCLNT_SHAREMODE_SHARED                   EQU <0> 


;*********************************************************
; Audio Structures
;*********************************************************
TOTAL_EFFECT_SLOTS     EQU <5>
UNITS_PER_SECOND       EQU <150000>
UNITS_PER_MILLISECOND  EQU <10000>


AUDIO_SOUND_CONTEXT struct
   AudioId               dq ?
   PcmData               dq ?
   PcmDataSize           dq ?
   CurrentPosition       dq ?
   pNext                 dq ?
AUDIO_SOUND_CONTEXT ends

;
; The WASAPI COM Objects and function pointer table reference.
;
IMMDEVICEENUMERATOR struct
   lpVtbl        dq ?
IMMDEVICEENUMERATOR ends

IMMDEVICEENUMERATORVTBL struct                  
   pfnQueryInterface                            dq ?
   pfnAddRef                                    dq ?
   pfnRelease                                   dq ?
   pfnEnumAudioEndpoints                        dq ?
   pfnGetDefaultAudioEndpoint                   dq ?
   pfnGetDevice                                 dq ?
   pfnRegisterEndpointNotificationCallback      dq ?
   pfnUnregisterEndpointNotificationCallback    dq ?
IMMDEVICEENUMERATORVTBL ends

IMMDEVICE struct
   lpVtbl        dq ?
IMMDEVICE ends

IMMDEVICEVTBL struct
 pfnQueryInterface    dq ?
 pfnAddRef            dq ?
 pfnRelease           dq ?
 pfnActivate          dq ?
 pfnOpenPropertyStore dq ?
 pfnGetId             dq ?
 pfnGetState          dq ?
IMMDEVICEVTBL ends


IAUDIOCLIENT struct
   lpVtbl        dq ?
IAUDIOCLIENT ends

IAUDIOCLIENTVTBL struct
   pfnQueryInterface        dq ?
   pfnAddRef                dq ?
   pfnRelease               dq ?
   pfnInitialize            dq ?
   pfnGetBufferSize         dq ?
   pfnGetStreamLatency      dq ?
   pfnGetCurrentPadding     dq ?
   pfnIsFormatSupported     dq ?
   pfnGetMixFormat          dq ?
   pfnGetDevicePeriod       dq ?
   pfnStart                 dq ?
   pfnStop                  dq ?
   pfnReset                 dq ?
   pfnSetEventHandle        dq ?
   pfnGetService            dq ?
IAUDIOCLIENTVTBL ends

IAUDIORENDERCLIENT struct
   lpVtbl        dq ?
IAUDIORENDERCLIENT ends

IAUDIORENDERCLIENTVTBL struct
    pfnQueryInterface    dq ?
    pfnAddRef            dq ?
    pfnRelease           dq ?
    pfnGetBuffer         dq ?
    pfnReleaseBuffer     dq ?
IAUDIORENDERCLIENTVTBL ends

AUDIO_INTERNAL_CONTEXT struct
   AudioIdCounter       dq ?
   CurrentMusic         dq ?

   ;
   ; Up to 5 concurrent effects
   ;
   CurrentEffect        dq ?
                        dq ?
                        dq ?
                        dq ?
                        dq ?
   ;
   ; Need to track 5 effect positions
   ;
   CurrentEffectPos     dq ?
                        dq ?
                        dq ?
                        dq ?
                        dq ?

   AudioMusicList       dq ?
   AudioEffectList      dq ?
   CriticalSection      CRITICAL_SECTION <?>
   WaveFormatHeader     dq ?  ; All Supplied Audio must have the same WaveFormatHeader
   hThreadHandle        dq ?
   FrameCountPerBuffer  dd ?
   ThreadIsAlive        dq ?
   pAudioBuffer         dq ?
   AudioBufferSize      dd ?
   Duration             dd ?
   NumberFramesPadding  dd ?
   ;
   ; WASAPI
   ;
   DeviceEnumeratorPtr  dq ?
   DefaultDevicePtr     dq ?
   AudioClientPtr       dq ?
   AudioRenderClientPtr dq ?
AUDIO_INTERNAL_CONTEXT ends


WAVEFORMATEX STRUCT
   wFormatTag          dw ?
   nChannels           dw ?
   nSamplesPerSec      dd ?
   nAvgBytesPerSec     dd ?
   nBlockAlign         dw ?
   wBitsPerSample      dw ?
   cbSize              dw ? 
WAVEFORMATEX  ends


;*********************************************************
; Public Declarations
;*********************************************************
public Audio_Init
public Audio_AddMusic
public Audio_AddEffect
public Audio_StopAudio
public Audio_PlayEffect
public Audio_PlayMusic

.DATA
   ; {bcde0395-e52f-467c-8e3d-c4579291692e} 95 03 de bc 2f e5 7c 46 8e 3d c4 57 92 91 69 2e
   CLSID__MMDeviceEnumerator  dd 0bcde0395h
                              dw 0e52fh
                              dw 0467ch
                              db 08eh, 03dh, 0c4h, 057h, 092h, 091h, 069h, 02eh

   ; {a95664d2-9614-4f35-a746-de8db63617e6}
   IID__IMMDeviceEnumerator   dd 0a95664d2h
                              dw 09614h
                              dw 04f35h
                              db 0a7h, 046h, 0deh, 08dh, 0b6h, 036h, 017h, 0e6h
 
   ; {1cb9ad4c-dbfa-4c32-b178-c2f568a703b2}  
   IID__IAudioClient          dd 01cb9ad4ch
                              dw 0dbfah
                              dw 04c32h
                              db 0b1h, 078h, 0c2h, 0f5h, 068h, 0a7h, 003h, 0b2h

   ; {f294acfc-3146-4483-a7bf-addca7c260e2}   
   IID__IAudioRenderClient    dd 0f294acfch
                              dw 03146h
                              dw 04483h
                              db 0a7h, 0bfh, 0adh, 0dch, 0a7h, 0c2h, 060h, 0e2h
  

.CODE

;*********************************************************
;   Audio_Init
;
;        Parameters: WaveFileHeader
;
;        Return Value: Audio Handle
;
;
;*********************************************************  
NESTED_ENTRY Audio_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDX, sizeof AUDIO_INTERNAL_CONTEXT
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  TEST RAX, RAX
  JZ @FailedToAllocate 
  MOV R15, RAX 

  MOV AUDIO_INTERNAL_CONTEXT.WaveFormatHeader[R15], RSI

  LEA RCX, AUDIO_INTERNAL_CONTEXT.CriticalSection[R15]
  DEBUG_FUNCTION_CALL InitializeCriticalSection

  XOR RCX, RCX
  DEBUG_FUNCTION_CALL CoInitialize
  
  MOV RCX, R15
  DEBUG_FUNCTION_CALL Audio_InitializeWasapi  
  CMP RAX, 0
  JNE @StartAudioThread
@FailurePath:
  LEA RCX, AUDIO_INTERNAL_CONTEXT.CriticalSection[R15]
  DEBUG_FUNCTION_CALL DeleteCriticalSection

  MOV RCX, R15
  DEBUG_FUNCTION_CALL LocalFree

  XOR RAX, RAX
  JMP @FailedToInitAudio

@StartAudioThread:
  MOV AUDIO_INTERNAL_CONTEXT.ThreadIsAlive[R15], 1
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R9, R15
  LEA R8, [Audio_Thread]
  XOR RDX, RDX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL CreateThread
  CMP RAX, 0
  JE @FailurePath
  MOV AUDIO_INTERNAL_CONTEXT.hThreadHandle[R15], RAX
@ReturnHandle:
  MOV RAX, R15
@FailedToInitAudio:
@FailedToAllocate:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_Init, _TEXT$00



;*********************************************************
;   Audio_InitializeWasapi
;
;        Parameters: Audio Structure
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY Audio_InitializeWasapi, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Get the Audio Enumerator
  ;
  LEA R8, AUDIO_INTERNAL_CONTEXT.DeviceEnumeratorPtr[RSI]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R8
  XOR RDX, RDX
  LEA R8, [CLSCTX_ALL+RDX]
  LEA R9, [IID__IMMDeviceEnumerator]
  LEA RCX, [CLSID__MMDeviceEnumerator]
  DEBUG_FUNCTION_CALL CoCreateInstance
  CMP RAX, 0
  JNE @Failure

  ;
  ; Get the default Audio Device
  ;
  MOV RCX, AUDIO_INTERNAL_CONTEXT.DeviceEnumeratorPtr[RSI]
  MOV RAX, IMMDEVICEENUMERATOR.lpVtbl[RCX]
  MOV RAX, IMMDEVICEENUMERATORVTBL.pfnGetDefaultAudioEndpoint[RAX]

  LEA R9, AUDIO_INTERNAL_CONTEXT.DefaultDevicePtr[RSI]
  MOV R8D, eMultimedia
  MOV EDX, eRender
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JNE @Failure
  
  ;
  ; Get The audio Client
  ;
  LEA R9, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[RSI]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], R9
  MOV RCX, AUDIO_INTERNAL_CONTEXT.DefaultDevicePtr[RSI]
  MOV RAX, IMMDEVICE.lpVtbl[RCX]
  MOV RAX, IMMDEVICEVTBL.pfnActivate[RAX]
  LEA  RDX, [IID__IAudioClient]
  XOR R9, R9
  LEA R8, [CLSCTX_ALL + R9]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JNE @Failure

  ;
  ; Initialize the audio client
  ;
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R9, AUDIO_INTERNAL_CONTEXT.WaveFormatHeader[RSI]
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], R9
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[RSI]
  MOV RAX, IAUDIOCLIENT.lpVtbl[RCX]
  MOV RAX, IAUDIOCLIENTVTBL.pfnInitialize[RAX]
  MOV R8D, AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM or AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY
  MOV EDX, AUDCLNT_SHAREMODE_SHARED
  MOV R9D, UNITS_PER_SECOND
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JNE @Failure

  ;
  ; Get The Framecount Per Buffer
  ;
  LEA RDX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[RSI]
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[RSI]
  MOV RAX, IAUDIOCLIENT.lpVtbl[RCX]
  MOV RAX, IAUDIOCLIENTVTBL.pfnGetBufferSize[RAX]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JNE @Failure

  ;
  ; Get the Audio Render Client
  ;
  LEA R8, AUDIO_INTERNAL_CONTEXT.AudioRenderClientPtr[RSI]
  LEA RDX, [IID__IAudioRenderClient]
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[RSI]
  MOV RAX, IAUDIOCLIENT.lpVtbl[RCX]
  MOV RAX, IAUDIOCLIENTVTBL.pfnGetService[RAX]
  DEBUG_FUNCTION_CALL RAX
  CMP RAX, 0
  JNE @Failure

@Success:
  MOV EAX, 1
@Failure:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_InitializeWasapi, _TEXT$00


;*********************************************************
;   Audio_Thread
;
;        Parameters: Audio Ctx
;
;        Return Value: N/A
;
;*********************************************************  
NESTED_ENTRY Audio_Thread, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R15, RCX
  
  LEA R8, AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15]
  MOV EDX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[R15]
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioRenderClientPtr[R15]
  MOV RAX, IAUDIORENDERCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIORENDERCLIENTVTBL.pfnGetBuffer[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure

;
;  AudioSize = FrameCountPerBuffer * (pWaveFormatEx->wBitsPerSample / 8) * pWaveFormatEx->nChannels;
;  
  MOV RAX, AUDIO_INTERNAL_CONTEXT.WaveFormatHeader[R15]
  XOR R8, R8
  MOV R8W, WAVEFORMATEX.wBitsPerSample[RAX]
  SHR R8, 3
  XOR RDX, RDX
  XOR R9, R9
  MOV R9W, WAVEFORMATEX.nChannels[RAX]
  MOV EAX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[R15]
  MUL R8
  MUL R9
  
  MOV AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15], EAX
  
  MOV RCX, R15
  DEBUG_FUNCTION_CALL Audio_CopyAudioData

  XOR R8, R8
  MOV EDX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[R15]
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioRenderClientPtr[R15]
  MOV RAX, IAUDIORENDERCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIORENDERCLIENTVTBL.pfnReleaseBuffer[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure
;
; Duration = (ULONG64)((double)UNITS_PER_SECOND * pAudioContext->FrameCountPerBuffer / pAudioContext->pWaveFormatEx2->nSamplesPerSec);
;
  MOV EAX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[R15]
  MOV RCX, UNITS_PER_SECOND
  XOR RDX, RDX
  MUL RCX
  MOV RCX, AUDIO_INTERNAL_CONTEXT.WaveFormatHeader[R15]
  MOV ECX, WAVEFORMATEX.nSamplesPerSec[RCX] 
  DIV RCX

  MOV AUDIO_INTERNAL_CONTEXT.Duration[R15], EAX

  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[R15]
  MOV RAX, IAUDIOCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIOCLIENTVTBL.pfnStart[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure

@AudioLoop:
;
; Duration/UNITS_PER_MILLISECOND/2
;
  CMP AUDIO_INTERNAL_CONTEXT.ThreadIsAlive[R15], 0
  JE @ThreadTerminates

  MOV EAX, AUDIO_INTERNAL_CONTEXT.Duration[R15]
  MOV RCX, UNITS_PER_MILLISECOND
  XOR RDX, RDX
  DIV RCX
  SHR RAX, 1
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL Sleep

  LEA RDX, AUDIO_INTERNAL_CONTEXT.NumberFramesPadding[R15]
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioClientPtr[R15]
  MOV RAX, IAUDIOCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIOCLIENTVTBL.pfnGetCurrentPadding[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure

  ; FramesAvailable = pAudioContext->FrameCountPerBuffer - NumberFramesPadding;
  MOV EAX, AUDIO_INTERNAL_CONTEXT.FrameCountPerBuffer[R15]
  SUB EAX, AUDIO_INTERNAL_CONTEXT.NumberFramesPadding[R15]
  MOV RBX, RAX  

  CMP RAX, 0
  JE @AudioLoop

  MOV AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15], 0

  LEA R8, AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15]
  MOV RDX, RBX
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioRenderClientPtr[R15]
  MOV RAX, IAUDIORENDERCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIORENDERCLIENTVTBL.pfnGetBuffer[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure

  MOV RAX, AUDIO_INTERNAL_CONTEXT.WaveFormatHeader[R15]
  XOR R8, R8
  MOV R8W, WAVEFORMATEX.wBitsPerSample[RAX]
  SHR R8, 3
  XOR RDX, RDX
  XOR R9, R9
  MOV R9W, WAVEFORMATEX.nChannels[RAX]
  MOV RAX, RBX
  MUL R8
  MUL R9

  MOV AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15], EAX

  MOV RCX, R15
  DEBUG_FUNCTION_CALL Audio_CopyAudioData

  LEA R14, AUDIO_INTERNAL_CONTEXT.CurrentEffect[R15]
  LEA R13, AUDIO_INTERNAL_CONTEXT.CurrentEffectPos[R15]
  XOR R12, R12
@MixAllEffects:

  CMP R12, TOTAL_EFFECT_SLOTS
  JE @MixingDone
  MOV RSI, [R14]
  CMP RSI, 0
  JE @GoToNextSlot
  
  MOV R8, [R13]
  MOV RDX, RSI
  MOV RCX, R15
  DEBUG_FUNCTION_CALL Audio_MixEffect
  MOV [R13], RAX
  CMP RAX, 0
  JNE @GoToNextSlot
  XOR R9, R9
  MOV RAX, RSI
  LOCK CMPXCHG [R14], R9
@GoToNextSlot:
  ADD R13, 8
  ADD R14, 8
  INC R12 
  JMP @MixAllEffects
  
@MixingDone:
  XOR R8, R8
  MOV RDX, RBX
  MOV RCX, AUDIO_INTERNAL_CONTEXT.AudioRenderClientPtr[R15]
  MOV RAX, IAUDIORENDERCLIENT.lpVtbl[RCX]
  MOV R12, IAUDIORENDERCLIENTVTBL.pfnReleaseBuffer[RAX]
  DEBUG_FUNCTION_CALL R12
  CMP RAX, 0
  JNE @Failure
  JMP @AudioLoop
    

@Failure:
  INT 3
@ThreadTerminates:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_Thread, _TEXT$00


;*********************************************************
;   Audio_MixEffect
;
;        Parameters: Audio Context, Effect Ptr, Current Effect Position
;
;        Return Value: Position (0 means done)
;
;
;*********************************************************  
NESTED_ENTRY Audio_MixEffect, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RBX, RDX
  MOV R15, RCX

 ; MOV R8, AUDIO_INTERNAL_CONTEXT.CurrentEffectPos[R15]  Passed in R8 now.
  MOV RDI, AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15]

  MOV R12D, AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15]
  MOV R9, AUDIO_SOUND_CONTEXT.PcmData[RBX]
  ADD R9, R8  ; Get to the correct position.
  MOV R10, AUDIO_SOUND_CONTEXT.PcmDataSize[RBX]
  SUB R10, R8  ; Adjust the length of the audio buffer.

  XOR R12, R12
@PerformMixing:
  CMP R12, R10
  JAE @EffectsComplete
  CMP R12D, AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15]
  JAE @DoneMixing
  CMP WORD PTR [RDI], 0
  JL @CheckIfEffectIsNegative  
  CMP WORD PTR [R9], 0
  JGE @BothArePositive
  JMP @BothAreMixed
@CheckIfEffectIsNegative:
  CMP WORD PTR [R9], 0
  JL @BothAreNegative    
@BothAreMixed:
  MOV AX, WORD PTR [R9]
  ADD WORD PTR [RDI], AX
  ADD RDI, 2
  ADD R9, 2
  ADD R12, 2
  JMP @PerformMixing
  
  
@BothArePositive:
  MOV AX, WORD PTR [R9]
  ADD WORD PTR [RDI], AX
  CMP WORD PTR [RDI], 0
  JGE @NoIssueWithPositive
  MOV WORD PTR [RDI], 07FFFh    ; Need to truncate on overflow
@NoIssueWithPositive:
  ADD RDI, 2
  ADD R9, 2
  ADD R12, 2
  JMP @PerformMixing


@BothAreNegative:
  MOV AX, WORD PTR [R9]
  ADD WORD PTR [RDI], AX
  CMP WORD PTR [RDI], 0
  JL @NoIssueWithNegative
  MOV WORD PTR [RDI], 08000h    ; Need to truncate on overflow
@NoIssueWithNegative:
  ADD RDI, 2
  ADD R9, 2
  ADD R12, 2
  JMP @PerformMixing
@DoneMixing:
  ADD R12, R8       ; Returning new position
  MOV RAX, R12
  JMP @ExitFunction

@EffectsComplete:
  XOR RAX, RAX
@ExitFunction:
 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_MixEffect, _TEXT$00


;*********************************************************
;   Audio_CopyAudioData
;
;        Parameters: Audio Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Audio_CopyAudioData, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV R15, RCX
  MOV RBX, AUDIO_INTERNAL_CONTEXT.CurrentMusic[R15]
  CMP RBX, 0
  JE @ZeroBuffer
  MOV RDI, AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15]
  MOV R12D, AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15]

  MOV R9, AUDIO_SOUND_CONTEXT.PcmData[RBX]
  MOV R10, AUDIO_SOUND_CONTEXT.PcmDataSize[RBX]
  MOV R11, AUDIO_SOUND_CONTEXT.CurrentPosition[RBX]
  XOR R8, R8
@FillAudioBuffer:
  MOV RAX, R10
  SUB RAX, R11
  CMP RAX, R12
  JB @FillPartial
@FillTotal:
  MOV RCX, R12
  MOV RSI, R9
  ADD RSI, R11
  REP MOVSB
  ADD R11, R12
  MOV AUDIO_SOUND_CONTEXT.CurrentPosition[RBX], R11
  JMP @AudioBufferComplete

@FillPartial:
  MOV RCX, RAX
  MOV RSI, R9
  ADD RSI, R11
  REP MOVSB
  SUB R12, RAX
  XOR R11, R11
  JMP @FillAudioBuffer
@ZeroBuffer:  
  MOV RDI, AUDIO_INTERNAL_CONTEXT.pAudioBuffer[R15]
  MOV ECX, AUDIO_INTERNAL_CONTEXT.AudioBufferSize[R15]
  SHR RCX, 2
  XOR RAX, RAX
  REP STOSD
  
@AudioBufferComplete:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_CopyAudioData, _TEXT$00

;*********************************************************
;   Audio_AddMusic
;
;        Parameters: Audio Handle, Audio Sound Data Structure
;
;        Return Value: Audio ID
;
;
;*********************************************************  
NESTED_ENTRY Audio_AddMusic, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, RDX

  MOV RDX, sizeof AUDIO_SOUND_CONTEXT
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  TEST RAX, RAX
  JZ @FailedToAllocate 
  
  MOV RDX, AUDIO_SOUND_DATA.PcmData[RSI]
  MOV AUDIO_SOUND_CONTEXT.PcmData[RAX], RDX

  MOV RDX, AUDIO_SOUND_DATA.PcmDataSize[RSI]
  MOV AUDIO_SOUND_CONTEXT.PcmDataSize[RAX], RDX

  MOV AUDIO_SOUND_CONTEXT.CurrentPosition[RAX], 0

  LOCK INC AUDIO_INTERNAL_CONTEXT.AudioIdCounter[RDI]

  MOV RDX, AUDIO_INTERNAL_CONTEXT.AudioIdCounter[RDI]
  MOV AUDIO_SOUND_CONTEXT.AudioId[RAX], RDX

  MOV RDX, AUDIO_INTERNAL_CONTEXT.AudioMusicList[RDI]
  MOV AUDIO_SOUND_CONTEXT.pNext[RAX], RDX

  MOV AUDIO_INTERNAL_CONTEXT.AudioMusicList[RDI], RAX
  
;
; Return the Audio ID for reference in play selection.
;
  MOV RAX, AUDIO_SOUND_CONTEXT.AudioId[RAX]

@FailedToAllocate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_AddMusic, _TEXT$00

;*********************************************************
;   Audio_AddEffect
;
;        Parameters: Audio Handle, Audio Sound Data Structure
;
;        Return Value: Audio ID
;
;
;*********************************************************  
NESTED_ENTRY Audio_AddEffect, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, RDX

  MOV RDX, sizeof AUDIO_SOUND_CONTEXT
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL LocalAlloc
  TEST RAX, RAX
  JZ @FailedToAllocate 
  
  MOV RDX, AUDIO_SOUND_DATA.PcmData[RSI]
  MOV AUDIO_SOUND_CONTEXT.PcmData[RAX], RDX

  MOV RDX, AUDIO_SOUND_DATA.PcmDataSize[RSI]
  MOV AUDIO_SOUND_CONTEXT.PcmDataSize[RAX], RDX

  MOV AUDIO_SOUND_CONTEXT.CurrentPosition[RAX], 0

  LOCK INC AUDIO_INTERNAL_CONTEXT.AudioIdCounter[RDI]

  MOV RDX, AUDIO_INTERNAL_CONTEXT.AudioIdCounter[RDI]
  MOV AUDIO_SOUND_CONTEXT.AudioId[RAX], RDX

  MOV RDX, AUDIO_INTERNAL_CONTEXT.AudioEffectList[RDI]
  MOV AUDIO_SOUND_CONTEXT.pNext[RAX], RDX

  MOV AUDIO_INTERNAL_CONTEXT.AudioEffectList[RDI], RAX
  
;
; Return the Audio ID for reference in play selection.
;
  MOV RAX, AUDIO_SOUND_CONTEXT.AudioId[RAX]

@FailedToAllocate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_AddEffect, _TEXT$00



;*********************************************************
;   Audio_PlayMusic
;
;        Parameters: Audio Handle, Music Audio ID
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY Audio_PlayMusic, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  XOR EAX, EAX
  MOV R9, AUDIO_INTERNAL_CONTEXT.AudioMusicList[RSI]
@FindAudioId:
  CMP R9, 0
  JE @FailureCondition

  CMP AUDIO_SOUND_CONTEXT.AudioId[R9], RDI
  JE @FoundMusic

  MOV R9, AUDIO_SOUND_CONTEXT.pNext[R9]
  JMP @FindAudioId
  
@FoundMusic:  
@LoopUntilComplete:
  MOV RAX, AUDIO_INTERNAL_CONTEXT.CurrentMusic[RSI]
  LOCK CMPXCHG AUDIO_INTERNAL_CONTEXT.CurrentMusic[RSI], R9
  JNE @LoopUntilComplete
  MOV EAX, 1
@FailureCondition:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_PlayMusic, _TEXT$00

;*********************************************************
;   Audio_StopAudio
;
;        Parameters: Audio Handle
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY Audio_StopAudio, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_StopAudio, _TEXT$00


;*********************************************************
;   Audio_PlayEffect
;
;        Parameters: Audio Handle, Effect Audio ID
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY Audio_PlayEffect, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  XOR EAX, EAX
  MOV R9, AUDIO_INTERNAL_CONTEXT.AudioEffectList[RSI]
@FindAudioId:
  CMP R9, 0
  JE @FailureCondition

  CMP AUDIO_SOUND_CONTEXT.AudioId[R9], RDI
  JE @FoundEffect

  MOV R9, AUDIO_SOUND_CONTEXT.pNext[R9]
  JMP @FindAudioId
  
@FoundEffect:  
  XOR RDX, RDX
  LEA RSI, AUDIO_INTERNAL_CONTEXT.CurrentEffect[RSI]
  MOV RDI, RSI
@TryToFindEffectSlot:
  MOV RSI, RDI
  CMP RDX, TOTAL_EFFECT_SLOTS
  JAE @FailureCondition

  ADD RDI, 8
  INC RDX

  ;
  ; Right now we will have 1 slot.  If it is Zero, we can add the new slot,
  ; otherwise for now it gets dropped.
  ;
  XOR RAX, RAX
  LOCK CMPXCHG QWORD PTR [RSI], R9
  JNZ @TryToFindEffectSlot

  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@FailureCondition:  
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END Audio_PlayEffect, _TEXT$00



;
;;*********************************************************
;;   Audio_LoadWaveFileInMemory
;;
;;        Parameters: Wave File In Memory, Size
;;
;;        Return Value: Wave File Handle
;;
;;
;;*********************************************************  
;NESTED_ENTRY Audio_LoadWaveFileInMemory, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
;  DEBUG_RSP_CHECK_MACRO
;  MOV RSI, RCX
;  MOV RDI, RDX
;
;  CMP WAVE_FILE_INFORMATION.ChunkId_R[RCX], 'R'
;  JNE @InvalidWaveFile
;
;  CMP WAVE_FILE_INFORMATION.ChunkId_I[RCX], 'I'
;  JNE @InvalidWaveFile
;
;  CMP WAVE_FILE_INFORMATION.ChunkId_F1[RCX], 'F'
;  JNE @InvalidWaveFile
;
;  CMP WAVE_FILE_INFORMATION.ChunkId_F2[RCX], 'F'
;  JNE @InvalidWaveFile
;
;  MOV RDX, sizeof WAVEFILE_INTERNAL_CONTEXT
;  MOV RCX, LMEM_ZEROINIT
;  DEBUG_FUNCTION_CALL LocalAlloc
;  TEST RAX, RAX
;  JZ @FailedToAllocate
;
;  MOV WAVEFILE_INTERNAL_CONTEXT.RawBuffer[RAX], RSI
;  MOV WAVEFILE_INTERNAL_CONTEXT.DataBufferSize[RAX], RDI
;
;  LEA RCX, WAVE_FILE_INFORMATION.AudioFormat[RSI]
;  MOV WAVEFILE_INTERNAL_CONTEXT.WaveFileFormat[RAX], RCX
;
;  LEA RCX, WAVE_FILE_INFORMATION.AudioData[RSI]
;  MOV WAVEFILE_INTERNAL_CONTEXT.WaveFileData[RAX], RCX
;
;  LEA RCX, WAVE_FILE_INFORMATION.SubChunk2Size[RSI]
;  MOV WAVEFILE_INTERNAL_CONTEXT.WaveFileDataSize[RAX], RCX
;
;@InvalidWaveFile:
;@FailedToAllocate:  
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END Audio_LoadWaveFileInMemory, _TEXT$00
;
;
;;*********************************************************
;;   Audio_LoadWaveFile
;;
;;        Parameters: Master Context, File String
;;
;;        Return Value: Wave File Handle
;;
;;
;;*********************************************************  
;NESTED_ENTRY Audio_LoadWaveFile, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
;  DEBUG_RSP_CHECK_MACRO
;  ; Not Yet Implemented - TBD
;  XOR RAX, RAX
;  
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END Audio_LoadWaveFile, _TEXT$00
;
;
;;*********************************************************
;;   Audio_LoadWaveFileByResourceId
;;
;;        Parameters: hInstance, Resource ID, Resource Type
;;
;;        Return Value: Wave File Handle
;;
;;
;;*********************************************************  
;NESTED_ENTRY Audio_LoadWaveFileByResourceId, _TEXT$00
;  alloc_stack(SIZEOF STD_FUNCTION_STACK)
;  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
;.ENDPROLOG 
;  DEBUG_RSP_CHECK_MACRO
;  ; Resource Type (R8)
;
;  MOV RSI, RCX  ; hIntance (RCX)
;  MOV RDI, RDX  ; Resource Name (RDX)
;  DEBUG_FUNCTION_CALL FindResourceA
;  
;  TEST RAX, RAX
;  JZ @NotFound
;  MOV R12, RAX
;
;  MOV RDX, RAX
;  MOV RCX, RSI
;  DEBUG_FUNCTION_CALL LoadResource
;  MOV R13, RAX
;
;  MOV RCX, RAX
;  DEBUG_FUNCTION_CALL LockResource  
;  MOV R14, RAX
;
;  MOV RDX, R12
;  MOV RCX, RSI
;  DEBUG_FUNCTION_CALL SizeofResource  
;  
;  MOV RDX, RAX
;  MOV RCX, R14
;  DEBUG_FUNCTION_CALL Audio_LoadWaveFileInMemory
;  TEST RAX, RAX
;  JZ @FailedToCreateHandle
;  
;  MOV WAVEFILE_INTERNAL_CONTEXT.IsResource[RAX], 1
;  MOV WAVEFILE_INTERNAL_CONTEXT.HRSRC[RAX], R12
;  MOV WAVEFILE_INTERNAL_CONTEXT.HGLOBAL[RAX], R13
;  
;  JMP @Success
;@FailedToCreateHandle:
;  ; Perform Any Cleanup -- TBD
;@NotFound:  
;@Success:
;  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
;  ADD RSP, SIZE STD_FUNCTION_STACK
;  RET
;NESTED_END Audio_LoadWaveFileByResourceId, _TEXT$00
;


END
