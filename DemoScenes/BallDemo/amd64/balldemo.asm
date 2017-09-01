;*********************************************************
; Ball demo
;
;  Written in Assembly x64
;
;  By David Antler  09/12/2017
;
;*********************************************************

;*********************************************************
; Assembly Options
;*********************************************************


;*********************************************************
; Included Files
;*********************************************************
include ksamd64.inc
include demovariables.inc
include master.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
extern LocalAlloc:proc
extern LocalFree:proc
extern time:proc
extern srand:proc
extern rand:proc

;*********************************************************
; Structures
;*********************************************************
PARAMFRAME struct
    Param1         dq ?
    Param2         dq ?
    Param3         dq ?
    Param4         dq ?
PARAMFRAME ends

SAVEREGSFRAME struct
    SaveRdi        dq ?
    SaveRsi        dq ?
    SaveRbx        dq ?
    SaveR10        dq ?
    SaveR11        dq ?
    SaveR12        dq ?
    SaveR13        dq ?
SAVEREGSFRAME ends

TEMPLATE_FUNCTION_STRUCT struct
   ParameterFrame PARAMFRAME      <?>
   SaveFrame      SAVEREGSFRAME   <?>
TEMPLATE_FUNCTION_STRUCT ends

;*********************************************************
; Public Declarations
;*********************************************************
public Ball_Init
public Ball_Demo
public Ball_Free

MAX_FRAMES EQU <2000>

;*********************************************************
; Data Segment
;*********************************************************
.DATA

   FrameCounter   dd ?

.CODE

;*********************************************************
;   Ball_DrawBoxXYR
;
;        Parameters: context
;                    x coordinate of center of box
;                    y coordinate of center of box
;                    radius of box (width and height / 2)
;                    color of box
;
;        Return Value: TRUE / FALSE.  FALSE only if nothing
;                could be drawn to the screen.
;
;
;*********************************************************  
NESTED_ENTRY Ball_DrawBoxXYR, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13
.ENDPROLOG 

  ; Store parameter1 (color of box)
  MOV RSI, [RSP+8+SIZEOF TEMPLATE_FUNCTION_STRUCT]
  MOV TEMPLATE_FUNCTION_STRUCT.ParameterFrame.Param1[RSP], RSI

  MOV RSI, RCX
  ; Registers at init...
  ;   rcx = context
  ;   rdx = x coord
  ;   r8  = y coord
  ;   r9  = 'radius'
  ; rsp+8 = color

  ; Registers used....
  ;   rax = current X
  ;   rbx = current Y
  ;   r9  = radius
  ;   paramFrame  = color

  ;
  ; Params checking phase.
  ; Initialize RAX and RBX to point to the top-left corner of a box
  ; containing the circle
  ;

  ; First set up the X coordinate starting point
  MOV RAX, RDX

  ; Check if our right edge is completely off the left side of the window
  ADD RAX, R9
  JO @DrawBoxXYR_Finish  ; overflow is bad.

  ; Now lets just make sure our left edge isn't off the right side of the window
  SUB RAX, R9
  SUB RAX, R9
  MOV RDI, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  CMP RAX, RDI  ; no need to draw anything if we aren't on the screen
  JGE @DrawBoxXYR_Finish  ; error - no need to draw if we arent on screen.

  ; Make sure we draw at x= 0 if our left edge is out of bounds.
  xor R12, R12
  CMP RAX, R12
  CMOVLE RAX, R12

  ;
  ; Next set up the y coordinates
  ;
  MOV RBX, R8
  ADD RBX, R9
  CMP RBX, 0
  JLE @DrawBoxXYR_Finish  ; if bottom of box is less than zero, we give up.  Quit now!
  SHL R9, 1
  SUB RBX, R9
  MOV RDI, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  CMP RBX, RDI ; If top of box is greater than the height, we give up. Quit now!
  JAE @DrawBoxXYR_Finish

  ; Make sure we start at y=0 if the box's top edge is out of bounds
  CMP RBX, R12
  CMOVLE RBX, R12
  MOV R10, RAX

  ;
  ; Now R10 and RBX point to the top left corner.  R9 is diameter.
  ;

  MOV RDI, RAX
  SHL RDI, 2  ; first add the X coordinate in
  ADD RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI] ; setup frame buffer

  ;
  ; Calculate the starting Y coordinate into RDI (buffer location)
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RAX, 2
  IMUL RAX, RBX
  ADD RDI, RAX

  ;
  ; Set up loop params
  ;
  MOV R12, R9   ; loop counter. Number of vertical lines to try.
  ; TODO: ensure R12 doesnt loop so much that it goes off the screen


  MOV R13, RDI
  MOV RAX, TEMPLATE_FUNCTION_STRUCT.ParameterFrame.Param1[RSP] ; RAX <- Color
  
  ;
  ; Convert R9 to width of box, instead of radius. This way
  ; we will never write outside of the bounds of the buffer.
  ; Note that R10 is Xmin
  ;
  MOV R11, R10
  ADD R11, R9
  CMP R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JL  @DrawBoxXYR_DoneGettingWidth

  ; If we are outside the width, then subtract the chunk outside.
  SUB R11, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SUB R9, R11
  
  ;
  ; If R9 is zero, then maybe we got cropped!  
  ; TODO: Do one last check to make sure we dont write too much to
  ; the right of our box.
  ;

@DrawBoxXYR_DoneGettingWidth:

  ; TODO: Insert code to get number of vertical lines into R12 here & remove
  ; the work inside the painting loop below


  ;
  ; RDI shall contain the spot in the frame buffer we want to write to
  ;
  MOV RDI, R13

  ;
  ; Scan across each line horizontally, filling it in.
  ;
@DrawBoxXYR_BeginPaint:

  MOV RCX, R9  ;   RCX <- Width
  REP STOSD

  ;
  ; Wrap to the next line by adjusting for stride
  ;
  MOV RDX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL RDX, 2
  ADD RDI, RDX

  ;
  ; Undo the addition to RDI done by REP STOSD
  ;
  MOV RDX, R9
  SHL RDX, 2
  SUB RDI, RDX

  ;
  ; Increment for the next line
  ; TODO: Remove and put in a-priori calculation inside R12
  ;
  INC RBX
  CMP RBX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  JGE @DrawBoxXYR_Finish_Success

  ;
  ; Decrement loop counter and bail if zero
  ;
  DEC R12
  JNZ @DrawBoxXYR_BeginPaint

  ;
  ; Finish with success
  ; 
@DrawBoxXYR_Finish_Success:
  MOV RAX, 1

@DrawBoxXYR_Finish:
  MOV rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]
  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  RET
NESTED_END Ball_DrawBoxXYR, _TEXT$00


;*********************************************************
;   Ball_SetBackgroundColor
;
;        Parameters: Master Context
;                    Color
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Ball_SetBackgroundColor, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 

  MOV RSI, RCX

  ;
  ; Get the Video Buffer
  ; 
  MOV RDI, MASTER_DEMO_STRUCT.VideoBuffer[RSI]


  MOV RAX, RDX
  AND RAX, 0FFFFFFh
  MOV RDX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]

@SetBackground_PlotLineColor:
  MOV RCX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  REP STOSD

  ;
  ; Wrap to the next line by adjusting for stride
  ;
  XOR RBX, RBX
  MOV EBX, MASTER_DEMO_STRUCT.Pitch[RSI]
  MOV R8, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  SHL R8, 2
  SUB RBX, R8
  ADD RDI, RBX

  ;
  ; Decrement for the next line
  ;
  DEC RDX
  JNZ @SetBackground_PlotLineColor


  MOV RSI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV RBX, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]
  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Ball_SetBackgroundColor, _TEXT$00



;*********************************************************
;   Ball_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY Ball_Init, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
.ENDPROLOG 

  MOV [FrameCounter], 0

  ;
  ; Initialize Random Numbers
  ;
  XOR ECX, ECX
  CALL time
  MOV ECX, EAX
  CALL srand

  MOV RSI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV RDI, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  MOV EAX, 1
  RET
NESTED_END Ball_Init, _TEXT$00



;*********************************************************
;  Ball_Demo
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE    
;
;
;*********************************************************  
NESTED_ENTRY Ball_Demo, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
 save_reg r10, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR10
 save_reg r11, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR11
 save_reg r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12
 save_reg r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13

.ENDPROLOG 
  
  MOV RSI, RCX

  ;
  ; Set background color white
  ;
  MOV RAX, 0FFFFFFh
  MOV RCX, RSI
  MOV RDX, RAX
  CALL Ball_SetBackgroundColor

  ;
  ; Draw a black box
  ;
  XOR RAX, RAX
  PUSH rax
  MOV RCX, RSI
  MOV RDX, 200
  MOV R8, 200
  MOV R9, 35
  CALL Ball_DrawBoxXYR
  ADD RSP, 8

  ; Draw a red box
  PUSH 0FF1111h
  MOV RCX, RSI
  MOV RDX, 400
  MOV R8, 260
  MOV R9, 10
  call Ball_DrawBoxXYR
  ADD RSP, 8

  ;
  ; Update the frame counter and determine if the demo is complete.
  ;
  XOR EAX, EAX
  INC [FrameCounter]
  CMP [FrameCounter], MAX_FRAMES
  SETE AL
  XOR AL, 1
 
  MOV rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  MOV r10, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR10[RSP]
  MOV r11, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR11[RSP]
  MOV r12, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR12[RSP]
  MOV r13, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveR13[RSP]

  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  RET
NESTED_END Ball_Demo, _TEXT$00



;*********************************************************
;  Ball_Free
;
;        Parameters: Master Context
;
;       
;
;
;*********************************************************  
NESTED_ENTRY Ball_Free, _TEXT$00
 alloc_stack(SIZEOF TEMPLATE_FUNCTION_STRUCT)
 save_reg rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi
 save_reg rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi
 save_reg rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx
.ENDPROLOG 

  ; Nothing to clean up

  MOV rdi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRdi[RSP]
  MOV rsi, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRsi[RSP]
  MOV rbx, TEMPLATE_FUNCTION_STRUCT.SaveFrame.SaveRbx[RSP]

  ADD RSP, SIZE TEMPLATE_FUNCTION_STRUCT
  RET
NESTED_END Ball_Free, _TEXT$00


END
