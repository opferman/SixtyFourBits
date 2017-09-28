# SixtyFourBits

## Build environment
1. Download the Windows 7 WDK
2. The environment to use is Windows x64 free

## Demoscene Template 
There is a template demo that you can use to create your own demo scene.  You can use this as an example by copying the code to your own demoscene directory. **\DemoScenes\\<YourDemo>\**
All code will need to go into the **AMD64** directory as this is an **X86-64 assembly project there should not be any C or other langauges used**.  The **SOURCES** file will need modified to change the target name.
The makefile is copied but you do not modify the make file.  To build the project you use **bcz** command.

## Demoscene functions and Master Context
There are three functions to implement which the engine will use to call you back.
- **Init** - This function you will initialize your demo, allocate your structures and setup the demo.  Return TRUE for success and FALSE for failure.
- **Demo** - This function you will be able to draw one frame for the demo.  ALl of your graphics algorithms will be done here.  Return TRUE to mean you will continue to draw frames.  Return FALSE when you are complete drawing frames and the demo ends or migrates to the next demo scene in the list.
- **Free** - This function you will use to clean up.

All of these functions are passed a single parameter which is the **MASTER_DEMO_STRUCT** as defined in **MASTER.INC** This includes the video buffer for "Demo" along with the size of the screen and some other information.

Note that the Stride is the actual length in bytes of each horizontal line in the video buffer.  It includes a hidden portion you shouldn't draw on.  So use the Width to calculate the boundaries of drawing but use
the stride to calculate how to get to the next horizontal line in the video buffer.  However, you can also use the Double Buffer library to perform your graphics and update it to the screen using the
double buffer API.

## Volatile vs. Non-Volatile registers
There are x64 volatile and non volatile registers.  You can look at them on MSDN: https://msdn.microsoft.com/en-us/library/9z1stfyw.aspx
Also, each function call will occur with RSP aligned to 0xFFFFFFFFFFFFFFF8.  If you plan to call any functions you must align the stack to 0xFFFFFFFFFFFFFFF0 as some functions will assume they can use
instructions that require alignemnt such as MOVAPS.  If the stack is not aligned you run the risk of crashing in some lower function call.

## Adding Debug Macros
There are two debug macros in debug_public.inc, the first is DEBUG_RSP_CHECK_MACRO which does nothing if debug is not being built but when debug is built you put it directly after .ENDPROLOG and it
will check RSP that it is aligned or INT 3.  

```
.ENDPROLOG
 DEBUG_RSP_CHECK_MACRO
```

The next macro you can use is DEBUG_FUNCTION_CALL instead of using CALL instruction.  This macro is simply CALL when debug is not enabled.  When debug is enabled
it will save the non-volatile registers before your function call, then after your functoin call it will verify they are correct.  It will then corrupt all of the non-volatile registers with garbage
except for RAX/XMM0 since they can return data from the function.  The goal is that if you have assumed the volatile registers retained information this forces them to hopefully cause a crash or a bug
if you have done this.

```
;
; Generate new random color
;
DEBUG_FUNCTION_CALL Math_rand
```

## Public Framework Header File list
- **ksamd64.inc** - This is a required file to include the basic runtime for X86-64 assembly on Windows.  This is part of the WDK and not a file checked into this repository.
- **DBuffer_Public.inc** - Doublebuffer library.
- **Debug_public.inc** - Debug macro library.
- **demoprocs.inc** - Contains internal functions and the Math library.  TODO: Split this out into seperate headers for internal vs. demo.
- **font_public.inc** - Library to obtain bit-fonts.
- **frameloop_public.inc** - Library that allows callback scripting of your demo based on absolute or relative frame counts.
- **init_public.inc** - Initialization API for the framework and is included in your entry test or demo application but not in the demoscene itself.
- **master.INC** - Contains the MASTER_DEMO_STRUCT definition that is needed and passed into the demoscene callbacks (Init, Demo, Free).
- **soft3d_public.inc** - Software implmented 3D library structures.
- **soft3d_funcs.inc** - Software implmented 3D library functions.
- **demovariables.inc** - Use for constants for the demo but contains nothing today.
- **vpal_public.inc** - Virtual Palette functions.

### Internal Framework Header File list you should not include.
- **engdbg_procs.INC** - Internal header file for the engine.
- **engine.INC** - Internal header file for the engine.
- **ddrawx64.INC** - Internal header file that contains direct draw definitions. 
- **engdbg_internal.INC** - Internal header file for the engine.
- **init_vars.INC** - Included indirectly by the other header files as needed.
- **DBuffer_flags.INC** - Included indirectly by the other header files as needed.
- **frameloop_vars.inc** - Included indirectly by the other header files as needed.
- **windowsx64.inc** - Internal header file that contains information for the Windowing library.
- **Windowsx64_public.inc** - Previously publicly used in test applications, it is no longer needed to be used and has been moved to internal only.

## Available functions in the framework

The framework contains various functions you can use to accellerate your demo building by providing basic routine functionality.  

### init_public.inc
- **Initialization_Demo**

### master.INC
- **MASTER_DEMO_STRUCT**

### DBuffer_Public.inc
- **DBuffer_Create**
- **Dbuffer_UpdateScreen**
- *Dbuffer_Free**

### Debug_public.inc
- **DEBUG_IS_ENABLED**
- **DEBUG_FUNCTION_CALL**
- **DEBUG_RSP_CHECK_MACRO**

### demoprocs.inc
- **Math_Rand**

### font_public.inc
- **Font_GetBitFont**

### frameloop_public.inc
- **FrameLoop_Create**
- **FrameLoop_PerformFrame**
- **FrameLoop_Reset**
- **FrameLoop_Free**

### soft3d_public.inc
- **Soft3D_Init**
- **Soft3D_SetCameraRotation**
- **Soft3D_SetViewDistance**
- **Soft3D_SetViewPoint**
- **Soft3D_SetAspectRatio**
- **Soft3D_Convert3Dto2D**
- **Soft3D_Close**

### vpal_public.inc
- **VPal_Create**
- **VPal_SetColorIndex**
- **VPal_GetColorIndex**
- **VPal_Rotate**
- **VPal_RotateReset**
- **VPal_Free**



