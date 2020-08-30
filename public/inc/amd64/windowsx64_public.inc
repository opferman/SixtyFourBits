;
;  Windows x64 Public Header
;


;
;
; External Declarations
;
extern LocalAlloc:proc
extern LocalFree:proc
extern sqrt:proc
extern cos:proc
extern sin:proc
extern tan:proc
extern FindResourceA:proc
extern LoadResource:proc
extern sprintf:proc
extern LockResource:proc
extern GetEnvironmentVariableA:proc
extern CreateDirectoryA:proc
extern CreateFileA:proc
extern WriteFile:proc
extern ReadFile:proc
extern CloseHandle:proc
extern SizeofResource:proc
extern EnterCriticalSection:proc
extern LeaveCriticalSection:proc
extern InitializeCriticalSection:proc
extern CreateThread:proc
extern ShowWindow:proc
extern UpdateWindow:proc
extern SetFocus:proc
extern ShowCursor:proc
extern Windowx64_Setup:proc
extern Windowx64_Loop:proc
extern ExitProcess:proc

;
; Constants
;
LMEM_ZEROINIT EQU <40h>
SW_SHOWNORMAL EQU <1>
SW_SHOW       EQU <5>

;
; Structures
;
RTL_CRITICAL_SECTION STRUCT
    DebugInfo       dq ? 
    LockCount       dd ?
    RecursionCount  dd ?
    OwningThread    dq ?
    LockSemaphore   dq ?
    SpinCount       dq ?
RTL_CRITICAL_SECTION ENDS

CRITICAL_SECTION  equ  <RTL_CRITICAL_SECTION>


