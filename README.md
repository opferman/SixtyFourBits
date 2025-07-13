# SixtyFourBits

## About

The main focus of this project was for people to be able to learn assembly programming in a fun way by doing graphics.  The framework removes the burdern of learning Windows GUI and Direct X programming and setting up all the
boiler plate and just hit the ground running as with a few instructions they can see pixels being set on the screen without much effort at all.  Plus it is fun to write 1990s style graphics effects and demos.

## Build environment
1. Download the Windows 7 WDK
2. The environment to use is Windows x64 free

## Demoscene Template 
There is a template demo that you can use to create your own demo scene.  You can use this as an example by copying the code to your own demoscene directory. **\DemoScenes\YourDemo\**
All code will need to go into the **AMD64** directory as this is an **X86-64 assembly project there should not be any C or other langauges used**.  The **SOURCES** file will need modified to change the target name.
The makefile is copied but you do not modify the make file.  To build the project you use **bcz** command.  You will also need to update the **DIRS** file in order to have your applications and libraries built using BCZ from the root directories.


## Demoscene functions and Master Context
There are three functions to implement which the engine will use to call you back.
- **Init** - This function you will initialize your demo, allocate your structures and setup the demo.  Return TRUE for success and FALSE for failure.
- **Demo** - This function you will be able to draw one frame for the demo.  ALl of your graphics algorithms will be done here.  Return TRUE to mean you will continue to draw frames.  Return FALSE when you are complete drawing frames and the demo ends or migrates to the next demo scene in the list.
- **Free** - This function you will use to clean up.

## Game functions and Master Context
There are three functions to implement which the engine will use to call you back for a game.
- **Init** - This is your initialization function.  It should call the GameEngine_Init function.
- **Demo** - This function should do nothing but return FALSE.  A correctly initailized game engine will override this function.
- **Free** - This function you will use to clean up.


All of these functions are passed a single parameter which is the **MASTER_DEMO_STRUCT** as defined in **MASTER.INC** This includes the video buffer for "Demo" along with the size of the screen and some other information.

Note that the Stride is the actual length in bytes of each horizontal line in the video buffer.  It includes a hidden portion you shouldn't draw on.  So use the Width to calculate the boundaries of drawing but use
the stride to calculate how to get to the next horizontal line in the video buffer.  However, you can also use the Double Buffer library to perform your graphics and update it to the screen using the
double buffer API.

## Volatile vs. Non-Volatile registers
There are x64 volatile and non volatile registers.  You can look at them on MSDN: https://msdn.microsoft.com/en-us/library/9z1stfyw.aspx
Also, each function call will occur with RSP aligned to 0xFFFFFFFFFFFFFFF8.  If you plan to call any functions you must align the stack to 0xFFFFFFFFFFFFFFF0 as some functions will assume they can use
instructions that require alignemnt such as MOVAPS.  If the stack is not aligned you run the risk of crashing in some lower function call.

## Function Calls
Function calls in X86-64 require that there are 4 parameter locations reserved on the stack.  All stack reservations are done before .ENDPROLOG so that stack walks can work by tracking the amount of space
reserved on the stack.  The first four parameters are RCX or xmm0, RDX or xmm1, R8 or xmm2 and R9 or xmm3.  Parameters beyond 4 must be passed on the stack after the required 4 stack locations that are reserved no matter 
how many parameters are passed.  The first 4 parameters are also not populated as you use the registers to pass those parameters.  However, the space is available for use by the function being called to either save the parameters
since they are in volatile registers or use the space for saving whatever it needs.

```
Parameter N (Not Required, must be populated with Nth parameter if exists)
...
Parameter 5 (Not Required, must be populated with 5th parameter if exists)
Parameter 4 (Required, but not populated use register)
Parameter 3 (Required, but not populated use register)
Parameter 2 (Required, but not populated use register)
Parameter 1 (Required, but not populated use register)
Return Address
Save registers
Locals
Parameter Frame for Function Calls in this function.
```

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

## Directory structure
The following describes the directory structure layout.
- **public\inc\amd64** - Public header files from the framework that can be included into demos, applications, etc.
- **private\inc\amd64** - Supporting header files that should not be directly included.  These are included as dependencies from the public header files when needed.
- **Apps** - Applications built to run the demos.
- **TestApps** - Testing applications for a particular demo scene.
- **Framework** - The directory that contains the engine and framework for the demoscenes.
- **Framework\inc\amd64** - Private header files that should not be included in anything but the framework.
- **DemoScenes** - Demoscene libraries themselves which users implement.
- **DemoScenes\inc\amd64** - Header files to include to use the demo scenes.
- **DemoEffects** - TBD, Future directory to contain libraries of demo effects that can be included in your demoscene.
- **Games** - Location of where complete games should reside.

## Public Framework Header File list
- **DemoScene.inc** - This is the base header file that should be included for demoscenes.
- **DBuffer_Public.inc** - Doublebuffer library.
- **font_public.inc** - Library to obtain bit-fonts.
- **frameloop_public.inc** - Library that allows callback scripting of your demo based on absolute or relative frame counts.
- **init_public.inc** - Initialization API for the framework and is included in your entry test or demo application but not in the demoscene itself.
- **soft3d_public.inc** - Software implmented 3D library structures.
- **vpal_public.inc** - Virtual Palette functions.
- **primatives_public.inc** - Basic graphic functions (i.e. Circle, etc.).
- **gameengine_public.inc** - Game engine to facilitate games.
- **gif_public.inc** - Load and decode .GIF files.
- **input_public.inc** - Get keyboard input (press/unpress).

## Available functions in the framework

The framework contains various functions you can use to accellerate your demo building by providing basic routine functionality.  

### init_public.inc
- **Initialization_Demo**
    - Description: This function is called from your entry point application to start the demo.  It doesn't return until all demos are complete.
	- Parameters: (RCX - INIT_DEMO_STRUCT)
	- Return: None

### DemoScene.inc
- **MASTER_DEMO_STRUCT**
    - Description: The data structure that contains the video buffer information.

### DBuffer_Public.inc
- **DBuffer_Create**
    - Description: Create a double buffer.
	- Parameters: (RCX - MASTER_DEMO_STRUCT, RDX - Bytes Per Pixel (1, 2, 4, 8))
	- Return: (RAX - Pointer to Double Buffer)

- **Dbuffer_UpdateScreen**
    - Description: Update the screen video buffer from the double buffer.
	- Parameters: (RCX - Double Buffer, RDX - Palette (optional), R8 - Flags)
	- Return: (None)

- **Dbuffer_ClearBuffer**
    - Description: Clear the double buffer to 0's.
	- Parameters: (RCX - Double Buffer)
	- Return: (None)
  
- **Dbuffer_Free**
    - Description: Free  double buffer.
	- Parameters: (RCX - Double Buffer)
	- Return: (None)


### DemoScene.inc (Debug_public.inc)
- **DEBUG_IS_ENABLED**
    - Description: An EQU set to 1 to enable Debug or set to 0 to disable debug.

- **DEBUG_FUNCTION_CALL**
    - Description: Performs the function call verifcation when debug is enabled as described above.

- **DEBUG_RSP_CHECK_MACRO**
    - Description: Performs the RSP verification when debug is enabled as described above.
   
- **Engine_Debug**
    - Description: Print a debug message.  This is a special function that will save even volatile registers and FLAGS so it can be used for debug.
    - Parameters: (RCX - format string (ala printf)), RDX and ... are the variable arguements like printf.
    - Return: (None)


### DemoScene.inc (math_public.inc)
- **Math_Rand**
    - Description: Returns a random number.
	- Parameters: (None)
	- Return: (RAX - Random Number)

### font_public.inc
- **Font_GetBitFont**
    - Description: Returns a pointer to an 8x8 bit font of 8 bytes.
	- Parameters: (RCX - Character)
	- Return: (RAX - Pointer to bit font for the character)

### frameloop_public.inc
- **FrameLoop_Create**
    - Description: Creates a frameloop handle.
	- Parameters: (RCX - List of FRAMELOOP_ENTRY_CB)
	- Return: (RAX - Frameloop handle)

- **FrameLoop_PerformFrame**
    - Description: Executes 1 itteration of the frame loop.
	- Parameters: (RCX - Frame Loop Handle)
	- Return: (RAX - TRUE is more frames; FALSE no more frames)

- **FrameLoop_Reset**
    - Description: Resets the frame loop to start over.
	- Parameters: (RCX - Frame loop handle)
	- Return: (None)

- **FrameLoop_Free**
    - Description: Frees the frame loop
	- Parameters: (RCX - Frame loop handle)
	- Return: (none)


### soft3d_public.inc
- **Soft3D_Init**
    - Description: Creates a 3D Handle
	- Parameters: (RCX - MASTER_DEMO_STRUCT, RDX - Flags, R8 - Pixel Callback function)
	- Return: (RAX - 3D Handle)

- **Soft3D_SetCameraRotation**
    - Description: Sets the radians rotation for the camera.
	- Parameters: (RCX -3D Handle, xmm1 - X Radians, xmm2 - Y Radians, xmm3 - Z radians)
	- Return: (None)

- **Soft3D_SetViewDistance**
    - Description: Sets the view distance.
	- Parameters: (RCX -3D Handle, xmm1 - View Distance)
	- Return: (None)

- **Soft3D_SetViewPoint**
    - Description: Sets the view point.
	- Parameters: (RCX -3D Handle, RDX - TD_POINT Pointer)
	- Return: (None)

- **Soft3D_SetAspectRatio**
    - Description: Sets the aspect ratio.
	- Parameters: (RCX -3D Handle, xmm1 - Aspect Ratio)
	- Return: (None)

- **Soft3D_Convert3Dto2D**
    - Description: Converts a 3D point to a projected point on the 2d screen.
	- Parameters: (RCX -3D Handle, RDX - Location TD_POINT Pointer, R8 - World Location TD_POINT pointer, R9 - Projected 2D TD_POINT_2D Pointer, Stack - Camera TD_POINT Pointer)
	- Return: (RAX - Pixel is on or off screen.)

- **Soft3D_Close**
    - Description: Closes the 3D Handle.
	- Parameters: (RCX - Software 3D Handle)
	- Return: (None)

### vpal_public.inc
- **VPal_Create**
    - Description: Creates a Virtual Palette
	- Parameters: (RCX - Number of Colors)
	- Return: (RAX - Palette Handle)

- **VPal_SetColorIndex**
    - Description: Set the RGB value for the Palette color index
	- Parameters: (RCX - Palette Handle, RDX - Palette Index, R8 - RGB)
	- Return: (None)

- **VPal_GetColorIndex**
    - Description: Get the RGB value for the Palette color index
	- Parameters: (RCX - Palette Handle, RDX - Palette Index)
	- Return: (RAX - RGB)

- **VPal_Rotate**
    - Description: Rotates the color palette
	- Parameters: (RCX - Palette Handle, RDX - Rotation Integer)
	- Return: (None)

- **VPal_RotateReset**
    - Description: Clears all rotations
	- Parameters: (RCX - Palette Handle)
	- Return: (None)

- **VPal_Free**
    - Description: Closes the palette
	- Parameters: (RCX - Palette Handle)
	- Return: (None)

### primatives_public.inc
- **Prm_DrawCircle**
    - Description: Draws a circle
	- Parameters: (RCX - Master Context, RDX - X, R8 - Y, R9 - Radius, Param5 - Plot Pixel Callback Function, Param6 - Context)
	- Return: None
        - void PlotPixelCallback(X, Y, Context, Master Context) - In order to accomodate any size buffer, the caller must draw the pixel for any primatives function.

- **Prm_DrawLine**
    - Description: Draws a line
	- Parameters: (RCX - Master Context, RDX - X, R8 - Y, R9 - X2, Param5 - Y2, Param6 - Plot Pixel Callback Function, Param7 - Context)
	- Return: None
        - void PlotPixelCallback(X, Y, Context, Master Context) - In order to accomodate any size buffer, the caller must draw the pixel for any primatives function.

### gameengine_public.inc
- **GameEngine_Init**
    - Description: Initializes the game engine.
    - Parameters: (RCX - Mater Demo Struct, RDX - GAME_ENGINE_INIT)
    - Return: TRUE on Success, FALSE on Failure.
       
- **GameEngine_PrintWord**
    - Description: Prints a word in bitfont into the double buffer.
    - Parameters: (RCX - Master Context, RDX - String, R8 - X, R9 - Y, Param5 - Font Size, Param6 - Radians if rotation, Param7 - Color)
    - Return: None

- **GameEngine_LoadGif**
    - Description: Loads a .GIF file.
    - Parameters: (RCX - File Name, RDX - IMAGE_INFORMATION)
    - Return: TRUE on Success, FALSE on Failure.

- **GameEngine_ConvertImageToSprite**
    - Description: TBD Future API
   
- **GameEngine_DisplayFullScreenAnimatedImage**
    - Description: Displays an image full screen animated on the screen based on the data in IMAGE_INFORMATION.  It can also grow an image to full screen from smaller image.
    - Parameters: (RCX - File Name, RDX - IMAGE_INFORMATION)
    - Return: None

- **GameEngine_DisplayCenteredImage**
    - Description: Centers an image on the screen based on the data in IMAGE_INFORMATION.  
    - Parameters: (RCX - File Name, RDX - IMAGE_INFORMATION)
    - Return: None

- **GameEngine_Free**
    - Description: Frees the game engine.
    - Parameters: None
    - Return: None
        
### input_public.inc
- **Inputx64_RegisterKeyPress**
    - Description: Registers a callback function on keypress
    - Parameters: (RCX - Key, RDX - Function Pointer to Handler)
    - Return: TRUE on Success, FALSE on Failure.
        - void Handler(void);
       
- **Inputx64_RegisterKeyRelease**
    - Description: Registers a callback function on keyrelease
    - Parameters: (RCX - Key, RDX - Function Pointer to Handler)
    - Return: TRUE on Success, FALSE on Failure.
        - void Handler(void);

### gif_public.inc
- **Gif_Open**
    - Description: Opens a GIF and initializes the file handle.
    - Parameters: (RCX - File Name)
    - Return: GIF Handle
       
- **Gif_Close**
    - Description: Closes a gif.
    - Parameters: (RCX - Gif Handle)
    - Return: None

- **Gif_NumberOfImages**
    - Description: Determines the number of images in a .GIF file
    - Parameters: (RCX - Gif Handle)
    - Return: Number of images in the file.

- **Gif_GetImageSize**
    - Description: Returns the buffer size for a 32-bit image.
    - Parameters: (RCX - Gif Handle)
    - Return: Number of images in the file.
   
- **Gif_GetImageWidth**
    - Description: Returns the image width.
    - Parameters: (RCX - Gif Handle)
    - Return: Image width

- **Gif_GetImageHeight**
    - Description: Returns the image height.
    - Parameters: (RCX - Gif Handle)
    - Return: Image height

- **Gif_GetImage32bpp**
    - Description: Returns the selected frame from scratch.
    - Parameters: (RCX - Gif Handle, RDX - Image Number, R8 - Return Buffer must be preallocated)
    - Return: TRUE or FALSE
    
- **Gif_GetImage32bppRealTime**
    - Description: Returns the selected frame from the input previous frame..
    - Parameters: (RCX - Gif Handle, RDX - Image Number, R8 - Return Buffer must contain the previous frame)
    - Return: TRUE or FALSE

- **Gif_GetAllImage32bpp**
    - Description: Returns the selected frame from scratch.
    - Parameters: (RCX - Gif Handle, RDX - Image Number, R8 - Return Buffer must be preallocated to include a sequential buffer of all images)
    - Return: TRUE or FALSE
   

### audio_public.inc
- **Audio_Init**
    - Description: Initializes WASAPI
    - Parameters: (RCX - Wave File Header)
    - Return: Audio Handle

- **Audio_AddMusic**
    - Description: Adds a music stream that can be played.
    - Parameters: (RCX - Audio Handle, RDX - Audio Sound Structure)
    - Return: Audio ID

- **Audio_AddEffect**
    - Description: Adds an effect that can be played over the music.
    - Parameters: (RCX - Audio Handle, RDX - Audio Sound Structure)
    - Return: Audio ID

- **Audio_TogglePauseEffects**
    - Description: Pauses or enables effects
    - Parameters: (RCX - Audio Handle)
    - Return: None

- **Audio_TogglePauseMusic**
    - Description: Pauses or enables music
    - Parameters: (RCX - Audio Handle)
    - Return: None

- **Audio_PlayEffect**
    - Description: Sets an effect to be played.
    - Parameters: (RCX - Audio Handle, RDX - Effect ID to be played)
    - Return: TRUE/FASE

- **Audio_PlayMusic**
    - Description: Sets audio to be played.
    - Parameters: (RCX - Audio Handle, RDX - Audio ID to be played)
    - Return: TRUE/FASE
 
- **Audio_SetVolume**
    - Description: Sets the volumne
    - Parameters: (RCX - Audio Handle, RDX - Volumne 0 - 1000)
    - Return: Error Code

# Programming Guide (Examples)

The following are coding examples of how to use some of the library and framework functionality in your demo.

## Creating and using the Virtual Palette 

The creation of the palette is simple, you just supply the number of colors and save the return address as the palette handle.

```
  MOV RCX, 256
  DEBUG_FUNCTION_CALL VPal_Create
  TEST RAX, RAX
  JZ @Failure_Exit
  MOV [VirtualPallete], RAX
```

You can then generate the colors for each color index.  The below example creates an increasing white palette.  If you are using the double buffer API, it can take the palette handle and populate the video buffer with the appropraite colors.

```
@CreateWhitePalette:
  MOV RAX, R12
  MOV AH, AL
  SHL RAX, 8
  MOV AL, AH

  MOV R8, RAX
  MOV RDX, R12
  MOV RCX, [VirtualPallete]
  DEBUG_FUNCTION_CALL VPal_SetColorIndex

  INC R12
  CMP R12, 256
  JB @CreateWhitePalette
```

## Creating and using the Double Buffer

The creation of the double buffer is simple using the API as defined below.
```
  MOV RDX, 1		; 1 Byte Per pixels
  MOV RCX, RSI		; MASTER_DEMO_STRUCT
  DEBUG_FUNCTION_CALL DBuffer_Create
  MOV [DoubleBufferPointer], RAX
  TEST RAX, RAX
  JZ @Failure_Exit
```

The returned pointer can be directly accessed as the screen height x width based on the pixel size specified.  
```
  MOV RCX, [DoubleBufferPointer]
  MOV BYTE PTR [RCX], 10h
```

The screen can then be updated by a single function call.

```
  ;
  ; Update the screen with the buffer
  ;

   MOV RCX, [DoubleBufferPointer]
   MOV RDX, [VirtualPallete]
   MOV R8, DB_FLAG_CLEAR_BUFFER
   DEBUG_FUNCTION_CALL Dbuffer_UpdateScreen
```


## Register saving, parameter passing and parameter accessing

There are macros and structures included in the **demoscene.inc** by **paramhelp_public.inc** that provide a fast and easy way to setup the local stack frame.  One thing to remember is that stack
space is really free these days, so reserving stack space you don't need in this simple demo framework is going to save some time than tailoring each stack specifically to the space you need.  However, you
can limit the execution time by only saving the registers you actually plan to use.  There are macros in the header file to help with this by providing you structures and macros to reserve and save your
registers.  If you need to use local variables you will need to create your own additional structures and if you want to only save a few registers you may need to save those manually as well as the macros 
only go so far and save all registers or a few specific registers.

The **STD_FUNCTION_STACK_MIN** is defined as all non-volatile general purpose registers and 8 parameters for function calls.  The example below shows using it to save only a few required GP registers.

```
 alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
 save_reg rdi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi
 save_reg rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx
 save_reg rsi, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi
 save_reg r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ...  Function Code ...

  MOV RSI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRsi[RSP]
  MOV RDI, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRdi[RSP]
  MOV rbx, STD_FUNCTION_STACK_MIN.SaveRegs.SaveRbx[RSP]
  MOV r12, STD_FUNCTION_STACK_MIN.SaveRegs.SaveR12[RSP]
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  MOV EAX, 1
  RET  
```

However, there is a macro that allows you to just save and restore ALL the GP registers.  An example of this is shown below.


```
  alloc_stack(SIZEOF STD_FUNCTION_STACK_MIN)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK_MIN
  .ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  ...  Function Code ...

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK_MIN
  ADD RSP, SIZE STD_FUNCTION_STACK_MIN
  MOV EAX, 1
  RET  
```


The below shows the definitions of the minimum and there are always two versions.  The first is the stack allocation for the current function and the second includes access to the stack parameters passed to it from the caller.
```
STD_FUNCTION_STACK_MIN struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    Padding     dq                         ?
STD_FUNCTION_STACK_MIN ends

STD_FUNCTION_STACK_MIN_PARAMS struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    Padding     dq                         ?
    FuncParams  FUNCTION_PARAMETERS_FRAME <?>
STD_FUNCTION_STACK_MIN_PARAMS ends
```

There is also a version that includes XMM registers as well as a macro to save and restore all XMM registers.  However, none of these standard structures have local variables.  If you need to define local variables though, these are 
great structures to start out with and then add your local variables.  I would add your local variables either where the "Padding" variable is or between the the parameters and the save registers structure as shown in the below example.
If you are adding local variables you can use the padding position it doesn't need to be kept.  It is in there to maintain alignment but you can arrange your local variables to make up for the alignment issue, just ensure that you do
not trap on MOVAPS when saving XMM registers and use the DEBUG_RSP_CHECK_MACRO to ensure stack alignment is maintained.  You will need to run with debug EQU enabled to have the macro test enforcement. 

```
DEMO_FUNCTION_STACK_MIN_PARAMS struct
    Parameters  LOCAL_PARAMETER_FRAME8    <?>
    ; Local Variables Here
    SaveRegs    SAVE_REGISTERS_FRAME      <?>
    ; Or Local Variables Here
    FuncParams  FUNCTION_PARAMETERS_FRAME <?>
DEMO_FUNCTION_STACK_MIN_PARAMS ends
```






