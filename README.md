# SixtyFourBits

1. Download the Windows 7 WDK
2. The environment to use is Windows x64 free

There is a template that you can use to create your own demo scene, just add a new demoscene:

\DemoScenes\<YourDemo>\

The code will go under AMD64.
The SOURCES file will need modified to change the targetname.
The makefile is copied here from another project but is not modified.  

There are three functions to implement:

Init
Demo
Free

As you can see in the template.  They all get passed in a "MASTER_DEMO_STRUCT" from master.inc

This includes the video buffer for "Demo".  The purpose is:

Init - Initialize your demo but don't draw anything.
Demo - Draw 1 frame of your demo.  Return 1 meaning you are still rendering more frames.  Return 0 to state your demo is done and move to the next demo.
Free - Free the resources you allocated in your demo.

Note that the "Stride" is the actual length in bytes of each line in the demo.  It includes a hidden portion you shouldn't draw on.  So use the Width to calculate the boundaries of drawing but use
the stride to calculate how to get to the next horizontal line in the video buffer.

There are x64 volatile and non volatile registers.  You can look at them on MSDN.  
Each time a function call occurs, you must align the RSP to 0xFFFFFFFFFFFFFFF0.  It starts at 0xFFFFFFFFFFFFFFFFFFF8 since CALL just puts a return address on the stack.  So if you plan to call any functions
you should align the stack.  If this is a leaf function you don't need to align the stack but it is a good habbit.

There is a debug_public.inc that you can use to verify your volatile /non volatile and RSP stack alignment.  

After .ENDPROLOG add the DEBUG_RSP_CHECK_MACRO  You can read debug_public.inc on how to enable/disable building for debug.

.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


Instead of using "CALL" instruction dirctly, you can also use the macro "DEBUG_FUNCTION_CALL".  When debug is not enabled, this just generates a CALL instruction.  When debug is enabled, this will save all the non-volatile registers before the call.  Then after the call, it will verify the non volatile regsiters were saved approporately.  It will also corrupt all of the volatile registers except xmm0 and rax (return registers) so that if your code is relying on volatile registers across function calls they will not retain their value and hopefully should corrupt the code to where you can find and fix these assumptions.

  ;
  ; Generate new random color
  ;
  DEBUG_FUNCTION_CALL Math_rand



