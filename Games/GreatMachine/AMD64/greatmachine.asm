;*********************************************************
; The Great Machine Game
;
;  Written in Assembly x64
; 
;  By Toby Opferman  8/28/2020
;
;     AKA ChecksumError on Youtube
;     AKA BinaryBomb on Discord
;
;*********************************************************

; USE_FILES EQU <1>

;*********************************************************
; Assembly Options
;*********************************************************



;*********************************************************
; Included Files
;*********************************************************
include demoscene.inc
include dbuffer_public.inc
include font_public.inc
include input_public.inc
include gif_public.inc
include gameengine_public.inc
include primatives_public.inc

;*********************************************************
; External WIN32/C Functions
;*********************************************************
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
extern VirtualAlloc:proc
extern VirtualFree:proc

LMEM_ZEROINIT EQU <40h>





;*********************************************************
; Public Declarations
;*********************************************************
public GreatMachine_Init
public GreatMachine_Demo
public GreatMachine_Free


;*********************************************************
; Structures, Equates, Constants
;*********************************************************

;
; The Great Machine State Machine
;
GREAT_MACHINE_STATE_LOADING              EQU <0>
GREAT_MACHINE_STATE_INTRO                EQU <1>
GREAT_MACHINE_STATE_MENU                 EQU <2>
GREAT_MACHINE_GAMEPLAY                   EQU <3>
GREAT_MACHINE_HISCORE                    EQU <4>
GREAT_MACHINE_STATE_OPTIONS              EQU <5>
GREAT_MACHINE_STATE_ABOUT                EQU <6>
GREAT_MACHINE_STATE_WINSCREEN            EQU <7>
GREAT_MACHINE_END_GAME                   EQU <8>
GREAT_MACHINE_STATE_ENTER_HI_SCORE       EQU <9>
GREAT_MACHINE_LEVELS                     EQU <10>
GREAT_MACHINE_STATE_CREDITS              EQU <11>
GREAT_MACHINE_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>


SPRITE_TYPE_CAR        EQU <1>
SPRITE_TYPE_TOXIC      EQU <2>
SPRITE_TYPE_PART       EQU <3>
SPRITE_TYPE_PEDESTRIAN EQU <4>

NUMBER_OF_CAR_GIFS     EQU <1>  ; Maximum can only be 19 due to conversion algorithm hard coding '1' when generating the gif name.
NUMBER_OF_CARS         EQU <1>

SPECIAL_SPRITE_STRUCT struct
   SpriteIsActive  dq ?
   SpriteVelX      dq ?
   SpriteMaxVelX   dq ?
   SpriteX         dq ?
   SpriteY         dq ?
   SpriteType      dq ?
   SpritePoints    dq ?
   ScrollingPtr    dq ?
   ListNextPtr     dq ?
   ListBeforePtr   dq ?
SPECIAL_SPRITE_STRUCT ends


SPRITE_STRUCT  struct
   ImagePointer    dq ?   ; Sprite Basic Information
   ExplodePointer  dq ?   ; Optional Sprite Basic Information
   SpriteAlive     dq ?
   SpriteX         dq ?
   SpriteY         dq ?
   SpriteVelX      dq ?
   SpriteVelY      dq ?
   SpriteMovementDebounce dq ?
   SpriteVelMaxX   dq ?
   SpriteVelMaxY   dq ?
   SpriteVelTempX  dq ?
   SpriteVelTempY  dq ?
   SpriteOwnerPtr  dq ?
   SpriteWidth     dq ?
   SpriteHeight    dq ?
   SpritePlayerRadius dq ?
   DisplayHit      dq ?
   HitPoints       dq ?   ; Amount of damage needed to be destroyed
   MaxHp           dq ?
   PointsTimer     dq ?
   PointsGiven     dq ?
   PointsGivenX    dq ?
   PointsGivenY    dq ?
   Damage          dq ?   ; How much damage this sprite does on collsion
   pNext           dq ?
   pPrev           dq ?
   KillOffscreen   dq ?   ; If it goes off screen, it ends or should it be reset.
   SpriteInactiveListPtr dq ?
   SpriteCategory        dq ?
   SpriteBasePointsValue dq ?
   pfnSpriteMovementUpdate  dq ?                        ; Movement update function pointer
   pfnAddedBackToList    dq ?
SPRITE_STRUCT  ends 

LEVEL_INFORMATION STRUCT 
  LevelNumber                     dq ?
  LevelTimer                      dq ?
  LevelTimerRefresh               dq ?
  LevelNumberGraphic              dq ?   
  LevelStartDelay                 dq ?
  LevelStartDelayRefresh          dq ?

  ;
  ; Game Piece Configurations
  ;

  ; Cars
  NumberOfConcurrentCars          dq ?
  CarsCanBeMultipleLanes          dq ?
  TimerAfterCarsLeave             dq ?
  TimerAfterCarsLeaveRefresh      dq ?
  TimerBetweenConcurrent          dq ?
  TimerBetweenConcurrentRefresh   dq ?

  ; Pedestrians
  PedestriansCanBeInStreet        dq ?
  PesdestrianTimer                dq ?
  PesdestrianTimerRefresh         dq ?
  
  ; Toxic Waste Barrels
  LevelCompleteBarrelCount        dq ?
  CurrentLevelBarrelCount         dq ?
  BarrelGenerateTimer             dq ?
  CanHaveBadBarrels               dq ?
  BarrelGenerateTimerRefresh      dq ?

  ; Car Parts
  LevelCompleteCarPartCount       dq ?
  CurrentCarPartCount             dq ?
  CarPartGenerateTimer            dq ?
  CarPartGenerateTimerRefresh     dq ?

  ;
  ; Function Pointers
  ;
  pfnLevelReset                   dq ?
  pfnNextLevel                    dq ?
LEVEL_INFORMATION ENDS

;
; Constants for Game 
;
MAX_SCORES             EQU <5>
TITLE_X                EQU <50>
TITLE_Y                EQU <10>
INTRO_Y                EQU <768 - 80>
INTRO_X                EQU <300>
INTRO_FONT_SIZE        EQU <3>
CREDITS_FONT_SIZE      EQU <2>
MAX_GAME_OPTIONS       EQU <3>
MAX_MENU_SELECTION     EQU <7>
MENU_MAX_TIMEOUT       EQU <30*50> ; About 22 Seconds
LEVEL_TIMER_ONE        EQU <2000>
LEVEL_INFINITE         EQU <-1>
LARGE_GAME_ALLOCATION  EQU <1024*1024*20> ; 20 MB
HI_SCORE_MODE_Y        EQU <325>
HI_SCORE_MODE_X        EQU <350>
HI_SCORE_MODE_FONT     EQU <3>
HI_SCORE_Y_START       EQU <400>
HI_SCORE_Y_INC         EQU <25>
HI_SCORE_X             EQU <350>
HI_SCORE_FONT_SIZE     EQU <2>
MAX_HI_SCORES          EQU <10>
HI_SCORE_TITLE_X       EQU <275>
HI_SCORE_TITLE_Y       EQU <275>
HI_SCORE_TITLE_SIZE    EQU <5>
LEVEL_INTRO_TIMER_SIZE EQU <30*5>  
NUMBER_OF_TREE_SCROLLING EQU <12>
TREE_GENERATE_TICK     EQU <75>
LEVEL_NAME_Y           EQU <768/2 - 30>
LEVEL_NAME_X           EQU <50>
LEVEL_NUMBER_Y         EQU <768/2 - 30>
LEVEL_NUMBER_X         EQU <510>
NUMBER_OF_GENERIC_CARS  EQU <1>
NUMBER_OF_LEVELS        EQU <4> ; If this is changed you need to update the level structure array 

;
; Game Over Constants
;
GAME_OVER_X     EQU <125>
GAME_OVER_Y     EQU <300>
GAME_OVER_SIZE  EQU <10>

WINNER_X     EQU <225>
WINNER_Y     EQU <300>
WINNER_SIZE  EQU <10>

;
; High Scores Constants
;
HS_GAME_OVER_X    EQU <100>
HS_GAME_OVER_Y    EQU <300>
HS_GAME_OVER_SIZE EQU <10>

ENTER_INITIALS_X    EQU <275>
ENTER_INITIALS_Y    EQU <400>
ENTER_INITIALS_SIZE EQU <3>

INITIALS_X    EQU <350>
INITIALS_Y    EQU <500>
INITIALS_SIZE EQU <10>

PLAYER_SCORE_FONT_SIZE EQU <INTRO_FONT_SIZE>
PLAYER_SCORE_X         EQU <500>
PLAYER_SCORE_Y         EQU <10>

;
; Parallax Scrolling Constants
;
ROAD_SCROLL_X_INC EQU <-5>
ROAD_SCROLL_Y_INC EQU <0>
MOUNTAIN_SCROLL_X_INC EQU <-2>
MOUNTAIN_SCROLL_Y_INC EQU <0>
SKY_SCROLL_X_INC EQU <-1>
SKY_SCROLL_Y_INC EQU <0>

;
; Player Defaults
;
 PLAYER_CAR_LENGTH      EQU <390>  ; Hard coding the sprite length.
 PLAYER_START_X         EQU <(1024/2) - (390/2)>  ; Hardcode to middle of screen
 PLAYER_START_Y         EQU <550>
 PLAYER_LANE_1          EQU <PLAYER_START_Y>
 PLAYER_LANE_0          EQU <PLAYER_START_Y - 100>
 PLAYER_START_MAX_VEL_X EQU <6>
 PLAYER_START_MAX_VEL_Y EQU <20>
 PLAYER_X_DIM       EQU <390>
 PLAYER_Y_DIM       EQU <111>
 PLAYER_START_HP    EQU <10>
 PLAYER_DAMAGE      EQU <1>
 PLAYER_START_LIVES EQU <3>


;*********************************************************
; Macros
;*********************************************************

;
; Setup sprite list, destroys RAX, RDX, R8, R10, R11
;
SETUP_SPRITE_BASIC_LIST_MACRO MACRO BasicSprite, ExplodeSprite, NumberSprites
  LOCAL SetupSpriteLoop
  MOV R8,  OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 

  MOV R10, [SpritePointer]
  MOV R11, R10
  ADD R11, BasicSprite  * SIZEOF SPRITE_BASIC_INFORMATION
  ADD R10, ExplodeSprite * SIZEOF SPRITE_BASIC_INFORMATION

  XOR RAX, RAX
SetupSpriteLoop:
  MOV QWORD PTR [R8], R10
  MOV QWORD PTR [RDX], R11
  ADD R8, 8
  ADD RDX, 8
  ADD R11, SIZEOF SPRITE_BASIC_INFORMATION
  ADD R10, SIZEOF SPRITE_BASIC_INFORMATION

  INC RAX
  CMP RAX, NumberSprites
  JB SetupSpriteLoop
ENDM


;
; Setup sprite list, destroys RAX, RDX, R8, R10, R11
;
SETUP_SPRITE_BASIC_LIST_NO_EXPLODE_MACRO MACRO BasicSprite, NumberSprites
  LOCAL SetupSpriteLoop
  MOV R8,  OFFSET SpriteBasicExplodPtr
  MOV RDX, OFFSET SpriteBasicListPtr 

  MOV R10, [SpritePointer]
  MOV R11, R10
  ADD R11, BasicSprite  * SIZEOF SPRITE_BASIC_INFORMATION
  XOR R10, R10

  XOR RAX, RAX
SetupSpriteLoop:
  MOV QWORD PTR [R8], R10
  MOV QWORD PTR [RDX], R11
  ADD R8, 8
  ADD RDX, 8
  ADD R11, SIZEOF SPRITE_BASIC_INFORMATION

  INC RAX
  CMP RAX, NumberSprites
  JB SetupSpriteLoop
ENDM



;*********************************************************
; Data Segment
;*********************************************************
.DATA
    GreatMachineStateFuncPtrs dq  GreatMachine_Loading         ; GREAT_MACHINE_STATE_LOADING
                              dq  GreatMachine_IntroScreen         ; GREAT_MACHINE_STATE_INTRO
                              dq  GreatMachine_MenuScreen          ; GREAT_MACHINE_STATE_MENU
                              dq  GreatMachine_GamePlayScreen      ; GREAT_MACHINE_GAMEPLAY
                              dq  GreatMachine_HiScoreScreen       ; GREAT_MACHINE_HISCORE
                              dq  GreatMachine_OptionsScreen       ; GREAT_MACHINE_STATE_OPTIONS
                              dq  GreatMachine_AboutScreen         ; GREAT_MACHINE_STATE_ABOUT
                              dq  GreatMachine_Winner              ; GREAT_MACHINE_STATE_WINSCREEN
                              dq  GreatMachine_GameOver            ; GREAT_MACHINE_END_GAME
                              dq  GreatMachine_EnterHiScore        ; GREAT_MACHINE_STATE_ENTER_HI_SCORE
                              dq  GreatMachine_Levels              ; GREAT_MACHINE_LEVELS
                              dq  GreatMachine_Credits             ; GREAT_MACHINE_CREDITS
    CurrentTreeTick           dq  0
    ;
    ;  Graphic Resources 
    ; 
    GreatMachineCurrentState               dq ?
ifdef USE_FILES
    LoadingScreenImage              db "loadingbackground.gif", 0
    IntroImage                      db "greatmachineintro.gif", 0
    MenuImage                       db "menu.gif", 0
    GreatMachineTitle               db "GreatMachine_logo.gif", 0
    GeneralImage                    db "general.gif", 0
    RoadImage                       db "road.gif", 0
    MountainImage                   db "mountains.gif", 0
    SkyImage                        db "sky.gif", 0
    Tree1Image                      db "tree1.gif", 0
    Tree2Image                      db "tree2.gif", 0
    Tree3Image                      db "tree3.gif", 0
    Tree4Image                      db "tree4.gif", 0
    PlayerStartCarImage             db "startercar.gif", 0
    LevelNameImage                  db "levelname.gif",0
    LevelOneImage                   db "one.gif",0      
    LevelTwoImage                   db "two.gif",0      
    LevelThreeImage                 db "three.gif",0    
    LevelFourImage                  db "four.gif",0     
    GenericCarImage                 db "GenericCarxxx.gif", 0   ; change the x's to numbers and add back in ".gif", 0
else	
    GifResourceType                 db "GIFFILE", 0
    LoadingScreenImage              db "LOADING_GIF", 0
    IntroImage                      db "INTRO_GIF", 0
    MenuImage                       db "MENU_GIF", 0
    GreatMachineTitle               db "LOGO_GIF", 0
    GeneralImage                    db "GENERAL_GIF", 0
    RoadImage                       db "ROAD_GIF", 0
    MountainImage                   db "MOUNTAINS_GIF", 0
    SkyImage                        db "SKY_GIF", 0
    Tree1Image                      db "TREE1_GIF", 0
    Tree2Image                      db "TREE2_GIF", 0
    Tree3Image                      db "TREE3_GIF", 0
    Tree4Image                      db "TREE4_GIF", 0
    PlayerStartCarImage             db "PLAYER_START_GIF", 0
    LevelNameImage                  db "LEVELNAME_GIF", 0     
    LevelOneImage                   db "LEVEL_ONE_GIF", 0     
    LevelTwoImage                   db "LEVEL_TWO_GIF", 0     
    LevelThreeImage                 db "LEVEL_THREE_GIF", 0   
    LevelFourImage                  db "LEVEL_FOUR_GIF", 0   
    GenericCarImage                 db "GENERIC_CARxxx_GIF", 0    ; Change the X's to numbers 
endif	
 
    GamePlayPage                    dq 0
    GamePlayTextOne                 dq 50, 300
                                    db "Doc Green has traveled into the", 0
                                    dq 50, 350
                                    db "future and is now stuck there.  His",0
                                    dq 50, 400
                                    db "Great Machine has broken down and", 0
                                    dq 50, 450
                                    db "he needs to rebuild it.  He also",0  
                                    dq 50, 500
                                    db "needs to collect enough radioactive",0
                                    dq 50, 550
                                    db "radioactive fueld to get back home", 0 
                                    dq 50, 600
                                    db "which is radioactive waste.", 0
                                    dq 0

    GamePlayTextTwo                 dq 50, 300
                                    db "Drive along the roads collecting", 0
                                    dq 50, 350
                                    db "parts to build the Great Machine",0
                                    dq 50, 400
                                    db "and collecting toxic waste that", 0
                                    dq 50, 450
                                    db "has been left in the road. Avoid", 0   
                                    dq 50, 500
                                    db "other cars and taking on damage.", 0 
                                    dq 50, 550
                                    db "Each level has a time limit and", 0 
                                    dq 50, 600
                                    db "each level there is a minimum", 0
                                    dq 0


    GamePlayTextThree               dq 50, 300
                                    db "number of toxic waste barrels you", 0
                                    dq 50, 350
                                    db "need to collect. Collect enough",0
                                    dq 50, 400
                                    db "fuel and all the parts to build", 0
                                    dq 50, 450
                                    db "the Great Machine to get home!",0  
                                    dq 0

    GamePlayTextFour                dq 50, 300
                                    db "Use the arrow keys to move your", 0
                                    dq 50, 350
                                    db "Great Machine around the road.",0
                                    dq 50, 400
                                    db "Those are the only controls.", 0
                                    dq 0

  ;
  ; Level Support
  ;
  LevelInformationPtr  dq ?

 ;
 ;
 ;  Description for the LEVEL_INFORMATION structure seen below.
 ;
 ;
 
; Level Number                                                 LevelNumber                                               
 ; Level Timer in milliseconds                                  LevelTimer                                
 ; Level Timer Refresh (Constant) in Milliseconds               LevelTimerRefresh                         
 ; Level Number Graphic                                   LevelNumberGraphic                              
 ; Level One Start Delay in Ticks (Ticks are # of screen updates)            LevelStartDelay              
 ; Level One Start Delay Refresh (Constant)                                  LevelStartDelayRefresh       
 ; Number of concurrent cars on the level                                    NumberOfConcurrentCars       
 ; Can have cars in multiple lanes at the same time                          CarsCanBeMultipleLanes       
 ; In Ticks, how long before a new car can be generated                  TimerAfterCarsLeave              
 ; Refresh the tick rate for car generation (constant)                   TimerAfterCarsLeaveRefresh       
 ; Timer between concurrent car generation (if any) in ticks             TimerBetweenConcurrent           
 ; Timer between concurrent car generation (if any) in ticks (constant)  TimerBetweenConcurrentRefresh    
 ; If pedestrians can be in the street.                                  PedestriansCanBeInStreet         
 ; Tick count between generating pedestrians                             PesdestrianTimer                 
 ; refresh the tick count generating pedestrians (constant)              PesdestrianTimerRefresh          
 ; Number of barrels to complete level (constant)                        LevelCompleteBarrelCount         
 ; current barrel count                                                  CurrentLevelBarrelCount          
 ; tick count between generating barrels                                 BarrelGenerateTimer              
 ;  Can have barrels that are bad and loose points                       CanHaveBadBarrels                
 ; tick count for barrel generation refresh (Constant)                   BarrelGenerateTimerRefresh       
 ; Number of car parts you need to complete level  (Constant)            LevelCompleteCarPartCount        
 ;  Current number of car parts                                          CurrentCarPartCount              
 ; Car part generator timer in ticks                                     CarPartGenerateTimer             
 ; Car part geneerator timer refresh in ticks (Constant)                 CarPartGenerateTimerRefresh      
 ; Function pointer to reset this level.                                 pfnLevelReset                    
 ; Function pointer to go to the next levell                             pfnNextLevel                     

LevelInformationEasy LEVEL_INFORMATION      <1,\
1000 * 60 * 5,\
1000 * 60 * 5,\
OFFSET LevelOneGraphic,\
200,\ 
200,\ 
1,\   
0,\   
100,\ 
100,\ 
0,\   
0,\   
0,\   
50,\  
50,\  
10,\  
0,\   
500,\ 
0,\   
500,\ 
5,\   
0,\   
1000,\
1000,\
GreatMachine_ResetLevel,\
GreatMachine_NextLevel>                                                              


LEVEL_INFORMATION  <?>
LEVEL_INFORMATION  <?>
LEVEL_INFORMATION  <?>

    LevelInformationMedium LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>

    LevelInformationHard   LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>
                           LEVEL_INFORMATION  <?>

    LevelNameGraphic     IMAGE_INFORMATION  <?>
    LevelOneGraphic      IMAGE_INFORMATION  <?>
    LevelTwoGraphic      IMAGE_INFORMATION  <?>
    LevelThreeGraphic    IMAGE_INFORMATION  <?>
    LevelFourGraphic     IMAGE_INFORMATION  <?>

    ;
    ;  Player Support Structures
    ;
    CurrentPlayerSprite             dq ?
    PlayerFirstCarGraphic           IMAGE_INFORMATION  <?>
    PlayerFirstCarConvert           SPRITE_CONVERT     <?>         
    PlayerSprite                    SPRITE_STRUCT      <?>
    PlayerSpriteBasicInformation    SPRITE_BASIC_INFORMATION <?>
    DeBounceMovement                dq 0                        
    NextPlayerRoadLane              dd ?
    CurrentPlayerRoadLane           dd ?
    ;
    ; Hi Score File Name
    ;
    HiScoreAppData            db 1024 DUP(?)
    HiScoreAppDataDirFormat   db "%s\\GreatMachinex64", 0
    HiScoreAppDataFileFormat  db "%s\\GreatMachinex64\\GreatMachinex64.HS", 0
    HiScoreAppDataFileFormat2 db "%s\\GreatMachinex64.HS", 0
    ApplicationDataEnv        db "APPDATA",0


    ;
    ; Inactive Lists - Change the constant "TOTAL_ENEMY_LISTS" if additional are added or removed.
    ;

    ;
    ; Game Text
    ;
    GameModeSelect                  dq 0
    ModeSelectText                  dq 400, 300
                                    db "Easy Mode", 0
                                    dq 365, 350
                                    db "Medium Mode",0
                                    dq 400, 400
                                    db "Hard Mode", 0
									dq 0
	
    PressSpaceToContinue            db "<Press Spacebar>", 0
    PressEnterToContinue            db "<Press Enter>", 0
    MenuText                        dq 400, 300
                                    db "Play Game", 0
                                    dq 350, 350
                                    db "Instructions",0
                                    dq 400, 400
                                    db "Hi-Scores", 0
                                    dq 420, 450
				    db "Options",0
				    dq 420, 500
                                    db "Credits", 0
                                    dq 440, 550
                                    db "About", 0
                                    dq 445, 600
                                    db "Quit", 0
                                    dq 0

    AboutText                       dq 50, 275
                                    db "This game is a submission for the", 0
                                    dq 50, 300
                                    db "OLC CODEJAM 2020 where the theme",0
                                    dq 50, 325
                                    db "was `The Great Machine'.", 0
                                    dq 50, 375
                                    db "Written in 100% x64 x86 Assembly", 0
                                    dq 50, 400
                                    db "language by Toby Opferman.", 0
                                    dq 50, 450
                                    db "See Credits for included game", 0
                                    dq 50, 475
                                    db "assets acknowledgements.", 0
                                    dq 50, 525
                                    db "This game is open source as part", 0
                                    dq 50, 550
                                    db "of the SixtyFourBits Demo and Game", 0
                                    dq 50, 575
                                    db "framework written by Toby Opferman.", 0
                                    dq 50, 625
                                    db "Sources can be found at:", 0									
                                    dq 50, 650
                                    db "github.com/opferman/SixtyFourBits", 0
                                    dq 50, 675
                                    db "`Games\GreatMachine\AMD64'", 0
                                    dq 0

    CreditsPage                     dq 0

    CreditsText1                    dq 50, 275
                                    db "Loading Screen Animation", 0
                                    dq 50, 325
                                    db "AUTHOR: Abigail Morgan",0
                                    dq 25, 350
                                    db "www.lowgif.com/3dcb655cbee4ecd7.html", 0
                                    dq 50, 400
                                    db "Intro and Menu Images", 0
                                    dq 50, 425
                                    db "AUTHORS: ", 0
                                    dq 50, 450
                                    db "Oto Godfrey and Justin Morton", 0
                                    dq 50, 475
                                    db "This work is free and may be used", 0
                                    dq 50, 500
                                    db "by anyone for any purpose with", 0
                                    dq 50, 525
                                    db "attribution and link to License.", 0
                                    dq 50, 575
                                    db "Source: Wikipedia (Images Resized", 0
                                    dq 50, 600
                                    db "        and reduced colors)", 0
                                    dq 50, 625
                                    db "License:", 0									
                                    dq 5, 650
                                    db "creativecommons.org/licenses/by-sa", 0
                                    dq 25, 675
                                    db "/4.0/legalcode", 0
                                    dq 0

    CreditsText2                    dq 50, 275
                                    db "Menu (About) Background", 0
                                    dq 50, 325
                                    db "Crediting isn't required.",0
                                    dq 25, 350
                                    db "wallpapersafari.com/w/yURNIV", 0
                                    dq 50, 400
                                    db "Nature Parallax Background", 0
                                    dq 50, 425
                                    db "AUTHOR: Liz Molnar", 0
                                    dq 50, 450
                                    db "Allowed usage with credit.", 0
                                    dq 5, 475
                                    db "raventale.itch.io/parallax-background", 0
                                    dq 0

    CreditsText3                    dq 50, 275
                                    db "Trees", 0
                                    dq 50, 325
                                    db "Purchased from Super Game Asset",0
                                    dq 25, 350
                                    db "for use in 1 project.", 0
                                    dq 50, 400
                                    db "DeLorean Assets", 0
                                    dq 50, 450
                                    db "AUTHOR: Michael Poke Yoshi", 0
                                    dq 50, 475
                                    db "Free with credit", 0
                                    dq 5, 500
                                    db "www.deviantart.com/mike-dragon", 0
                                    dq 8, 525
                                    db "/art/DeLorean-Sprites-Sheet-158604207", 0
                                    dq 0

    CreditsText4                    dq 50, 275
                                    db "Cars and all other sprites", 0
                                    dq 50, 325
                                    db "Purchased PRO membership Eezy.",0
                                    dq 50, 350
                                    db "No credit is required.", 0
                                    dq 0
                                    									
    HighScoresText                  db "High Scores", 0
    EasyModeText                    db "Easy Mode",0
    MediumModeText                  db "Medium Mode", 0
    HardModeText                    db "Hard Mode",0


    PointsScoreFormat               db "%I64u",0
    PointsScoreString               db 256 DUP(?)

    HiScoreFormatString             db "%s - %I64u", 0
    HiScoreString                   db "                                      ",0
    
    HiScoreLocationPtr             dq ?

    ;
    ; Menu Selection 
    ;
    MenuSelection                   dq 0
    MenuToState                     dq GREAT_MACHINE_LEVELS
                                    dq GREAT_MACHINE_GAMEPLAY
                                    dq GREAT_MACHINE_HISCORE
			            dq GREAT_MACHINE_STATE_OPTIONS
                                    dq GREAT_MACHINE_STATE_CREDITS
                                    dq GREAT_MACHINE_STATE_ABOUT
                                    dq GREAT_MACHINE_FAILURE_STATE  ; Quit
    MenuIntroTimer                  dq 0
    PlayerLives                     dq 0
    PlayerScore                     dq 0
    PlayerOutputText                db 256 DUP(?)
    PlayerHpText                    db "Hit Points: %I64u",0
    PlayerLivesText                 db "Lives: %I64u",0
    PlayerBombsText                 db "Bombs: %I64u", 0
    PlayerCurLevelText              db "Level: %I64u", 0
    PlayerCurWaveText               db "Wave: %I64u", 0
    PlayerScoreFormat               db "%I64u", 0
    SpriteImageFileListAttributes   db 1, 2
    
	;
	; Game Over Data
	;
	GameOverCaptureScreen           dq ?
	GameCaptureSize                 dq ?
        WinnerText                      db "Winner!",0
	GameOverText                    db "GAME OVER",0
        HighScoreText                   db "HIGH SCORE!",0
        EnterInitials                   db "Enter your initials!",0
        InitialsConst                   db "A--", 0
        InitialsEnter                   db "   ", 0
        InitialsEnterPtr                dq ?


    ;
    ; Game Variable Structures
    ;
    LargeMemoryAllocation    dq ?
    LargeMemoryAllocationEnd dq ?
    CurrentMemoryPtr         dq ?
    SpriteConvert      SPRITE_CONVERT     <?>
    GameEngInit        GAME_ENGINE_INIT   <?>
    RoadGraphic        IMAGE_INFORMATION  <?>
    RoadScroll         SCROLLING_GIF      <?>
    MountainGraphic    IMAGE_INFORMATION  <?>
    MountainScroll     SCROLLING_GIF      <?>
    SkyGraphic         IMAGE_INFORMATION  <?>
    SkyScroll          SCROLLING_GIF      <?>
    LoadingScreen      IMAGE_INFORMATION  <?>
    IntroScreen        IMAGE_INFORMATION  <?>
    MenuScreen         IMAGE_INFORMATION  <?>
    TitleGraphic       IMAGE_INFORMATION  <?>
    GeneralGraphic     IMAGE_INFORMATION  <?>


;
; Car Graphics
;
   GenericCarListPtr   dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?
                       dq ?

   GenericCarSpriteList      SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>                       
                             SPECIAL_SPRITE_STRUCT      <?>                       
                             SPECIAL_SPRITE_STRUCT      <?>                       

   GenericCarScrollList      SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>
                             SCROLLING_GIF      <?>                       
                             SCROLLING_GIF      <?>                       
                             SCROLLING_GIF      <?>                       

   GenericCarImageList IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
                       IMAGE_INFORMATION <?>
;
; Active Animation Lists
;
        TopSideWalkPtr    dq ?
        LaneZeroPtr       dq ?
        LaneOnePtr        dq ?
        BottomSideWalkPtr dq ?

;
;  Tree Graphics
; 
    Tree1Graphic       IMAGE_INFORMATION  <?>
    Tree2Graphic       IMAGE_INFORMATION  <?>
    Tree3Graphic       IMAGE_INFORMATION  <?>
    Tree4Graphic       IMAGE_INFORMATION  <?>

    TreeScrollList     dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif
                       dq  ?  ; TRUE if Active FALSE if not.
                       dq  ?  ; Pointer to Scrolling Gif

   TreeScrollData      SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>
                       SCROLLING_GIF      <?>

    HiScoreListPtr     dq OFFSET HiScoreListConst
    HiScoreListConst   db "TEO", 0  ; Easy Mode Scores
	                   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
                       db "TEO", 0  ; Medium Mode Scores
	                   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0					   
                       db "TEO", 0  ; Hard Mode Scores
	                   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0
					   db "TEO", 0
					   dq 0					   

					   
.CODE

;*********************************************************
;   GreatMachine_Init
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Init, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_LOADING
ifdef USE_FILES
  MOV RDX, OFFSET LoadingScreen
  MOV RCX, OFFSET LoadingScreenImage
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
else  
  MOV RCX, OFFSET LoadingScreenImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGifResource
  MOV RCX, RAX

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
endif
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, OFFSET GreatMachineStateFuncPtrs
  MOV RDX, OFFSET GameEngInit
  MOV GAME_ENGINE_INIT.GameFunctionPtrs[RDX], RCX
  MOV RCX, OFFSET GreatMachine_LoadingThread
  MOV GAME_ENGINE_INIT.GameLoadFunction[RDX],RCX
  MOV GAME_ENGINE_INIT.GameLoadCxt[RDX], RSI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_Init
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, GreatMachine_SpaceBar
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease
  
  MOV RDX, GreatMachine_UpArrow
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_DownArrow
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, GreatMachine_Enter
  MOV RCX, VK_RETURN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  

  MOV RDX, GreatMachine_RightArrow
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_RightArrowPress
  MOV RCX, VK_RIGHT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_LeftArrow
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyRelease  
  
  MOV RDX, GreatMachine_LeftArrowPress
  MOV RCX, VK_LEFT
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_UpArrowPress
  MOV RCX, VK_UP
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress
  
  MOV RDX, GreatMachine_DownArrowPress
  MOV RCX, VK_DOWN
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress

  MOV RDX, GreatMachine_SpacePress
  MOV RCX, VK_SPACE
  DEBUG_FUNCTION_CALL Inputx64_RegisterKeyPress


;
; TBD: Add keys and sequences for cheat codes.
;


@SuccessExit:
  MOV EAX, 1
  JMP @ActualExit  
@FailureExit:
  XOR EAX, EAX
@ActualExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Init, _TEXT$00


;*********************************************************
;   GreatMachine_Demo
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Demo, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Demo, _TEXT$00


;*********************************************************
;   GreatMachine_Free
;
;        Parameters: Master Context
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Free, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

 

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Free, _TEXT$00



;***************************************************************************************************************************************************************************
; Key Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_SpacePress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SpacePress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SpacePress, _TEXT$00


;*********************************************************
;   GreatMachine_SpaceBar
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SpaceBar, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState],GREAT_MACHINE_GAMEPLAY
  JNE @TryNextItem
  
  INC [GamePlayPage]
  
@TryNextItem:   
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_CREDITS
  JE @CreditsPage
   
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions

  CMP [GreatMachineCurrentState], GREAT_MACHINE_HISCORE
  JE @GoToMenu
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ABOUT
  JE @GoToMenu
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  JNE @CheckOtherState

@GoToMenu:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  MOV RCX, GREAT_MACHINE_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@GoToIntro:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@CheckOtherState:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @NotOnMenu
  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL GreatMachine_ResetGame

  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

@NotOnMenu:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JNE @NotHighScore

  INC QWORD PTR [InitialsEnterPtr]
  MOV RAX, [InitialsEnterPtr]
  MOV AL, BYTE PTR [RAX]

  CMP AL, 0
  JNE @NotDoneEnteringYet

  ;
  ; Done entering high score, Update Hi Score File
  ; and go to Intro.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_UpdateHighScore
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  JMP @DoneWithEnteringScore
@NotDoneEnteringYet:
  MOV RAX, [InitialsEnterPtr]
  MOV BYTE PTR [RAX], 'A'
@NotHighScore:
@DoneWithEnteringScore:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  MOV RCX, GREAT_MACHINE_STATE_MENU
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@CreditsPage:
  INC [CreditsPage]
  MOV RAX, GREAT_MACHINE_STATE_CREDITS
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SpaceBar, _TEXT$00


;*********************************************************
;   GreatMachine_Enter
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Enter, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  JE @WinnerScreen

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  DEBUG_FUNCTION_CALL GreatMachine_ResetGame
  ;
  ; Implement Menu Selection
  ;
  MOV RDX, [MenuSelection]
  MOV RCX, OFFSET MenuToState
  SHL RDX, 3
  ADD RCX, RDX
  MOV RCX, QWORD PTR [RCX]
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:
  MOV RCX, GREAT_MACHINE_STATE_MENU
  MOV [GreatMachineCurrentState], RCX
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
@CheckOtherState:
  CMP [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
  JNE @NotOnEndGame
  
  ;
  ;  Let's reset the level here to remove the active list.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_ResetLevel

  CMP [HiScoreLocationPtr], 0
  JE @GoToIntro
   
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  MOV RCX, GREAT_MACHINE_STATE_ENTER_HI_SCORE
  DEBUG_FUNCTION_CALL GameEngine_ChangeState  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GoToIntro:
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RCX, GREAT_MACHINE_STATE_INTRO
  DEBUG_FUNCTION_CALL GameEngine_ChangeState
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@NotOnEndGame:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@WinnerScreen:

  CMP [GameModeSelect], 1
  JAE @MediumOrHard
  ;MOV RCX, OFFSET EasyLevel1
  JMP @LevelResetComplete
@MediumOrHard:
  CMP [GameModeSelect], 1
  JA @HardMode  
  ;MOV RCX, OFFSET MediumLevel1
  JMP @LevelResetComplete
@HardMode:  
  ;MOV RCX, OFFSET HardLevel1
@LevelResetComplete:

  ;MOV [CurrentLevelInformationPtr], RCX

  DEBUG_FUNCTION_CALL GreatMachine_ResetLevel

  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  MOV RCX, GREAT_MACHINE_LEVELS
  DEBUG_FUNCTION_CALL GameEngine_ChangeState

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_Enter, _TEXT$00


;*********************************************************
;   GreatMachine_LeftArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LeftArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  ;DEC [DeBounceMovement]       ; TBD if we want to implement debounce
  ;CMP [DeBounceMovement], 0
  ;JGE @SkipUpate
  ;MOV [DeBounceMovement], MOVEMENT_DEBOUNCE

  MOV RAX, [PlayerSprite.SpriteVelMaxX]
  NEG RAX
  MOV [PlayerSprite.SpriteVelX], RAX
@SkipAdjustment:
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LeftArrowPress, _TEXT$00





;*********************************************************
;   GreatMachine_RightArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RightArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  ;DEC [DeBounceMovement]       ; TBD if we want to implement debounce
  ;CMP [DeBounceMovement], 0
  ;JGE @SkipUpate
  ;MOV [DeBounceMovement], MOVEMENT_DEBOUNCE

  MOV RAX, [PlayerSprite.SpriteVelMaxX]
  MOV [PlayerSprite.SpriteVelX], RAX

@SkipAdjustment:
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RightArrowPress, _TEXT$00

;*********************************************************
;   GreatMachine_LeftArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LeftArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead
  MOV [PlayerSprite.SpriteVelX], 0
  ; MOV [DeBounceMovement], 0
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LeftArrow, _TEXT$00




;*********************************************************
;   GreatMachine_RightArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_RightArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  MOV [PlayerSprite.SpriteVelX], 0
; MOV [DeBounceMovement], 0
@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_RightArrow, _TEXT$00






;*********************************************************
;   GreatMachine_DownArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DownArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead
  
  MOV [NextPlayerRoadLane], 1  

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@UpdateHighScore:

  MOV AL, 1
  DEBUG_FUNCTION_CALL GreatMachine_HiScoreEnterUpdate
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DownArrowPress, _TEXT$00






;*********************************************************
;   GreatMachine_UpArrowPress
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpArrowPress, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JE @UpdateHighScore

  CMP [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  JB @GameNotActive
  CMP [PlayerSprite.SpriteAlive], 0
  JE @PlayerIsDead

  MOV [NextPlayerRoadLane], 0

@GameNotActive:
@PlayerIsDead:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@UpdateHighScore:

  MOV AL, -1
  DEBUG_FUNCTION_CALL GreatMachine_HiScoreEnterUpdate  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_UpArrowPress, _TEXT$00




;*********************************************************
;   GreatMachine_DownArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DownArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @OptionsMenu

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState
  MOV [MenuIntroTimer], 0
  INC QWORD PTR [MenuSelection]
  
  CMP QWORD PTR [MenuSelection], MAX_MENU_SELECTION
  JB @NoResetToStart
  MOV [MenuSelection], 0

@NoResetToStart:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@OptionsMenu:
  INC QWORD PTR [GameModeSelect]
  
  CMP QWORD PTR [GameModeSelect], MAX_GAME_OPTIONS
  JB @NoResetToStart
  MOV [GameModeSelect], 0  
@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DownArrow, _TEXT$00


;*********************************************************
;   GreatMachine_UpArrow
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpArrow, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [DeBounceMovement], 0

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  JE @GameOptions
  
  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JNE @CheckOtherState

  MOV [MenuIntroTimer], 0

  CMP QWORD PTR [MenuSelection], 0
  JA @Decrement
  MOV [MenuSelection], MAX_MENU_SELECTION
@Decrement:
  DEC QWORD PTR [MenuSelection]
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
@GameOptions:  
  CMP QWORD PTR [GameModeSelect], 0 
  JA @PerformSelectionDecrement  
  MOV [GameModeSelect], MAX_GAME_OPTIONS
@PerformSelectionDecrement:
  DEC [GameModeSelect]
  
@CheckOtherState:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_UpArrow, _TEXT$00




;***************************************************************************************************************************************************************************
; Initialization & Support Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_AllocateMemory
;
;        Parameters: Ignored, RDX is the size.
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AllocateMemory, _TEXT$00
.ENDPROLOG
  MOV RAX, [CurrentMemoryPtr]
  ADD [CurrentMemoryPtr], RDX

  MOV RDX, [LargeMemoryAllocationEnd]
  CMP [CurrentMemoryPtr], RDX
  JAE @OutOfMemory
  RET
@OutOfMemory:
  INT 3
  RET

NESTED_END GreatMachine_AllocateMemory, _TEXT$00



ifndef USE_FILES
;*********************************************************
;   GreatMachine_LoadGifResource
;
;        Parameters: Resource Name
;
;        Return Value: Memory
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGifResource, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV R8, OFFSET GifResourceType         ; Resource Type
  MOV RDX, RSI                           ; Resource Name
  XOR RCX, RCX                           ; Use process module
  DEBUG_FUNCTION_CALL FindResourceA

  MOV RDX, RAX
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL LoadResource
  
  MOV RCX, RAX
  DEBUG_FUNCTION_CALL LockResource

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGifResource, _TEXT$00
endif

;*********************************************************
;   GreatMachine_SetupHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SetupHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 03h  ; OPEN_EXISTING
  MOV R9, 0
  MOV R8, 03h   	; File Share Read / Write
  MOV RDX, 01h   ; File Read Data
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; File exists, read in the Hi-Scores
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120*3				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL ReadFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation: 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailedToOpenAttemptToCreate:

  DEBUG_FUNCTION_CALL GreatMachine_CreateHiScores
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_SetupHiScores, _TEXT$00



;*********************************************************
;   GreatMachine_CreateHiScores
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CreateHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataDirFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  XOR RDX, RDX
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateDirectoryA
 
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat2
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 02h  ; CREATE_ALWAYS
  MOV R9, 0
  MOV R8, 3h   	; File Share Read/Write
  MOV RDX, 2h    ; File write
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; Write out the initial high scores list.
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120*3				; File Size is fixed to 120 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL WriteFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation:
@FailedToOpenAttemptToCreate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_CreateHiScores, _TEXT$00





;*********************************************************
;   GreatMachine_InitializeTrees
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_InitializeTrees, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV R10, 350

  XOR RDI, RDI
  XOR R8, R8
  LEA RDX, [TreeScrollData]
  LEA R9, [TreeScrollList]
@InitializeScrollList:

  MOV QWORD PTR [R9], 0
  LEA RAX, [RDX]
  MOV QWORD PTR [R9 + 8], RAX


  CMP RDI, 0
  JNE @TryTree2
  LEA RAX, [Tree1Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate
@TryTree2:
  CMP RDI, 1
  JNE @TryTree3
  LEA RAX, [Tree2Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate
@TryTree3:
  CMP RDI, 2
  JNE @DoTree4
  LEA RAX, [Tree3Graphic]

  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  JMP @EndOfLoopUpdate

@DoTree4:
  XOR RDI, RDI
  LEA RAX, [Tree4Graphic]
  MOV RCX, R10
  SUB RCX, IMAGE_INFORMATION.ImageHeight[RAX]
  MOV SCROLLING_GIF.CurrentY[RDX], RCX

  ADD R10, 45
  JMP @SkipIncRdi
@EndOfLoopUpdate:
  INC RDI
@SkipIncRdi:
  MOV SCROLLING_GIF.ImageInformation[RDX], RAX
  MOV SCROLLING_GIF.CurrentX[RDX], 1023
  
  MOV SCROLLING_GIF.XIncrement[RDX], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[RDX], ROAD_SCROLL_Y_INC
  ADD R9, 16
  ADD RDX, SIZE SCROLLING_GIF
  INC R8
  CMP R8, NUMBER_OF_TREE_SCROLLING
  JB @InitializeScrollList
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_InitializeTrees, _TEXT$00




;*********************************************************
;   GreatMachine_LoadAndCreatePlayerSprite
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadAndCreatePlayerSprite, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET PlayerFirstCarGraphic
  MOV RCX, OFFSET PlayerStartCarImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  LEA RCX, [PlayerFirstCarConvert]
  LEA RDX, [PlayerFirstCarGraphic]
  MOV SPRITE_CONVERT.ImageInformationPtr[RCX], RDX
  LEA RDX, [PlayerSpriteBasicInformation]
  MOV SPRITE_CONVERT.SpriteBasicInformtionPtr[RCX], RDX
  MOV SPRITE_CONVERT.SpriteImageStart[RCX], 0
  MOV SPRITE_CONVERT.SpriteNumImages[RCX], 2
  MOV SPRITE_CONVERT.SpriteX[RCX], 0
  MOV SPRITE_CONVERT.SpriteY[RCX], 0
  MOV R8, [PlayerFirstCarGraphic.ImageWidth]
  MOV SPRITE_CONVERT.SpriteX2[RCX], R8
  MOV R8, [PlayerFirstCarGraphic.ImageHeight]
  MOV SPRITE_CONVERT.SpriteY2[RCX], R8
  DEBUG_FUNCTION_CALL GameEngine_ConvertImageToSprite
  LEA RAX, [PlayerSpriteBasicInformation]
  MOV [CurrentPlayerSprite], RAX

@FailureExit:  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LoadAndCreatePlayerSprite, _TEXT$00







;*********************************************************
;   GreatMachine_SetupMemoryAllocations
;
;        Parameters: None
;
;        Return Value: TRUE / FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_SetupMemoryAllocations, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  
  MOV R9, 4         ; PAGE_READWRITE
  MOV R8, 03000h    ; MEM_COMMIT | MEM_RESERVE
  MOV RDX, LARGE_GAME_ALLOCATION
  XOR RCX, RCX
  DEBUG_FUNCTION_CALL VirtualAlloc
  CMP RAX, 0
  JE @Failure
  MOV [LargeMemoryAllocation], RAX
  MOV [LargeMemoryAllocationEnd], RAX
  ADD [LargeMemoryAllocationEnd],LARGE_GAME_ALLOCATION
  MOV [CurrentMemoryPtr], RAX
  MOV EAX, 1
@Failure:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_SetupMemoryAllocations, _TEXT$00



;*********************************************************
;   GreatMachine_LoadingThread
;
;        Parameters: Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadingThread, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  ;
  ; Large Memory Allocation
  ;
  DEBUG_FUNCTION_CALL GreatMachine_SetupMemoryAllocations
  CMP RAX, 0
  JE @FailureExit
  
  ;
  ; Game Over Capture Screen; create a buffer
  ; as large as the screen to capture it.
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  XOR RDX, RDX
  MUL MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SHL RAX, 2
  
  MOV [GameCaptureSize], RAX
  MOV RDX, RAX
  MOV RCX, LMEM_ZEROINIT
  DEBUG_FUNCTION_CALL GreatMachine_AllocateMemory
  CMP RAX, 0
  JE @FailureExit
  
  MOV [GameOverCaptureScreen], RAX
  
  ;
  ; Determine Hi Scores
  ;
  DEBUG_FUNCTION_CALL GreatMachine_SetupHiScores

  ;    
  ; Load the player sprites
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadAndCreatePlayerSprite
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the Level Name Graphics
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadLevelNameGraphics
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the Tree Graphics and Initialize Trees
  ;
  DEBUG_FUNCTION_CALL GreatMachine_LoadTreeGraphics
  CMP RAX, 0
  JE @FailureExit

  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_InitializeTrees
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the Background Graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadBackgroundGraphics
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Load the General Background Graphics for Screens (Menu, Credits, etc.)
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadGeneralScreenGraphics
  CMP RAX, 0
  JE @FailureExit  

  ;
  ; Load the Generic Car Graphics
  ;
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_LoadCarGraphics
  CMP RAX, 0
  JE @FailureExit 

  MOV EAX, 1
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@FailureExit:
  XOR RAX, RAX
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_LoadingThread, _TEXT$00


;*********************************************************
;   GreatMachine_LoadTreeGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadTreeGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET Tree1Graphic
  MOV RCX, OFFSET Tree1Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree2Graphic
  MOV RCX, OFFSET Tree2Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree3Graphic
  MOV RCX, OFFSET Tree3Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET Tree4Graphic
  MOV RCX, OFFSET Tree4Image
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadTreeGraphics, _TEXT$00


;*********************************************************
;   GreatMachine_LoadGeneralScreenGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGeneralScreenGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET GeneralGraphic
  MOV RCX, OFFSET GeneralImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET TitleGraphic
  MOV RCX, OFFSET GreatMachineTitle
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET MenuScreen
  MOV RCX, OFFSET MenuImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET IntroScreen
  MOV RCX, OFFSET IntroImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGeneralScreenGraphics, _TEXT$00


;*********************************************************
;   GreatMachine_LoadBackgroundGraphics
;
;        Parameters: Master Structure
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadBackgroundGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV RDX, OFFSET RoadGraphic
  MOV RCX, OFFSET RoadImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Road
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [RoadGraphic.ImageHeight]

  MOV [RoadScroll.CurrentX], 0
  MOV [RoadScroll.CurrentY], RAX
  MOV [RoadScroll.XIncrement], ROAD_SCROLL_X_INC
  MOV [RoadScroll.YIncrement], ROAD_SCROLL_Y_INC
  LEA RAX, [RoadGraphic]
  MOV [RoadScroll.ImageInformation], RAX

  MOV RDX, OFFSET MountainGraphic
  MOV RCX, OFFSET MountainImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Mountain
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [MountainGraphic.ImageHeight]
  SUB RAX, [RoadGraphic.ImageHeight]

  MOV [MountainScroll.CurrentX], 0
  MOV [MountainScroll.CurrentY], RAX
  MOV [MountainScroll.XIncrement], MOUNTAIN_SCROLL_X_INC
  MOV [MountainScroll.YIncrement], MOUNTAIN_SCROLL_Y_INC
  LEA RAX, [MountainGraphic]
  MOV [MountainScroll.ImageInformation], RAX

  MOV RDX, OFFSET SkyGraphic
  MOV RCX, OFFSET SkyImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  ;
  ; Setup Scrolling Structure for Sky
  ;
  MOV RAX, MASTER_DEMO_STRUCT.ScreenHeight[RSI]
  SUB RAX, [SkyGraphic.ImageHeight]
  SUB RAX, [MountainGraphic.ImageHeight]
  SUB RAX, [RoadGraphic.ImageHeight]
  MOV [SkyScroll.CurrentX], 0
  MOV [SkyScroll.CurrentY], RAX
  MOV [SkyScroll.XIncrement], SKY_SCROLL_X_INC
  MOV [SkyScroll.YIncrement], SKY_SCROLL_Y_INC
  LEA RAX, [SkyGraphic]
  MOV [SkyScroll.ImageInformation], RAX


@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadBackgroundGraphics, _TEXT$00




;*********************************************************
;   GreatMachine_LoadCarGraphics
;
;        Parameters: Master Structure
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadCarGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  XOR RBX, RBX
  MOV R15, OFFSET GenericCarImageList
  MOV R14, OFFSET GenericCarScrollList
  MOV R13, OFFSET GenericCarSpriteList
  MOV R12, OFFSET GenericCarListPtr
@LoadCarGraphics:
  CMP RBX, NUMBER_OF_CAR_GIFS   ; This way you can disable the cars by setting the equates to 0
  JE @CarsComplete
  INC RBX

ifdef USE_FILES
  MOV RCX, OFFSET GenericCarImage
  ADD RCX, 10
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '.'
  INC RCX
  MOV BYTE PTR [RCX], 'g'
  INC RCX
  MOV BYTE PTR [RCX], 'i'
  INC RCX
  MOV BYTE PTR [RCX], 'f'
  INC RCX
  MOV BYTE PTR [RCX], 0
else
  MOV RCX, OFFSET GenericCarImage
  ADD RCX, 11
  MOV DL, BL
  CMP DL, 10
  JB @Perform1sConversion
  MOV DL, '0'
  ADD DL, BL
  JMP @AddDotGifNull
  MOV BYTE PTR [RCX], '1'
  INC RCX
  SUB DL, 10
@Perform1sConversion:
  ADD DL, '0'
  MOV BYTE PTR [RCX], DL
  INC RCX
@AddDotGifNull:
  MOV BYTE PTR [RCX], '_'
  INC RCX
  MOV BYTE PTR [RCX], 'G'
  INC RCX
  MOV BYTE PTR [RCX], 'I'
  INC RCX
  MOV BYTE PTR [RCX], 'F'
  INC RCX
  MOV BYTE PTR [RCX], 0
endif

  MOV RDX, R15                          ; Car Image List Entry
  MOV RCX, OFFSET GenericCarImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV SCROLLING_GIF.CurrentX[R14], 0
  MOV SCROLLING_GIF.CurrentY[R14], 0
  MOV SCROLLING_GIF.XIncrement[R14], ROAD_SCROLL_X_INC
  MOV SCROLLING_GIF.YIncrement[R14], ROAD_SCROLL_Y_INC
  MOV SCROLLING_GIF.ImageInformation[R14], R15

  MOV SPECIAL_SPRITE_STRUCT.SpriteIsActive[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteMaxVelX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteX[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteY[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpriteType[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.SpritePoints[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ScrollingPtr[R13], R14
  MOV SPECIAL_SPRITE_STRUCT.SpriteType[R13], SPRITE_TYPE_CAR
  MOV SPECIAL_SPRITE_STRUCT.ListNextPtr[R13], 0
  MOV SPECIAL_SPRITE_STRUCT.ListBeforePtr[R13], 0

  ADD R12, 8
  ADD R13, SIZE SPECIAL_SPRITE_STRUCT
  ADD R14, SIZE SCROLLING_GIF
  ADD R15, SIZE IMAGE_INFORMATION
  JMP @LoadCarGraphics
@CarsComplete:
  MOV EAX, 1
@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadCarGraphics, _TEXT$00

;*********************************************************
;   GreatMachine_LoadLevelNameGraphics
;
;        Parameters: None
;
;        Return Value: TRUE/FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadLevelNameGraphics, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET LevelNameGraphic
  MOV RCX, OFFSET LevelNameImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelOneGraphic
  MOV RCX, OFFSET LevelOneImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelTwoGraphic
  MOV RCX, OFFSET LevelTwoImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelThreeGraphic
  MOV RCX, OFFSET LevelThreeImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

  MOV RDX, OFFSET LevelFourGraphic
  MOV RCX, OFFSET LevelFourImage
  DEBUG_FUNCTION_CALL GreatMachine_LoadGraphicsImage
  CMP RAX, 0
  JE @FailureExit

@FailureExit:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadLevelNameGraphics, _TEXT$00


       
;*********************************************************
;   GreatMachine_LoadGraphicsImage
;
;        Parameters: Pointer to Image (Resource or File depending on USE_FILES define), Graphics Pointer
;
;        Return Value: TRUE or FALSE
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_LoadGraphicsImage, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
        
ifdef USE_FILES
  DEBUG_FUNCTION_CALL GameEngine_LoadGif
else
  DEBUG_FUNCTION_CALL GreatMachine_LoadGifResource
  MOV RCX, RAX
  MOV RDX, RDI
  DEBUG_FUNCTION_CALL GameEngine_LoadGifMemory
endif
  CMP RAX, 0
  JE @FailureExit

  MOV IMAGE_INFORMATION.StartX[RDI], 0
  MOV IMAGE_INFORMATION.StartY[RDI], 0
  MOV IMAGE_INFORMATION.InflateCountDown[RDI], 0
  MOV IMAGE_INFORMATION.InflateCountDownMax[RDI], 0
  PXOR XMM0, XMM0
  MOVSD IMAGE_INFORMATION.IncrementX[RDI], XMM0
  MOVSD IMAGE_INFORMATION.IncrementY[RDI], XMM0        

  MOV RAX, 1
@FailureExit:       
                       
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_LoadGraphicsImage, _TEXT$00         
          
    



;***************************************************************************************************************************************************************************
; Game Reset Functions
;***************************************************************************************************************************************************************************




;*********************************************************
;   GreatMachine_ResetGame
;                This will reset the game for level 1.
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetGame, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  ;
  ; Setup Game Level information
  ;
  CMP [GameModeSelect], 1
  JAE @MediumOrHard
  MOV RAX, OFFSET LevelInformationEasy  
  JMP @GameModeSelectionComplete
@MediumOrHard:
  CMP [GameModeSelect], 1
  JA @HardMode  
  MOV RAX, OFFSET LevelInformationMedium
  JMP @GameModeSelectionComplete
@HardMode:  
  MOV RAX, OFFSET LevelInformationHard
  
  ;
  ; Refresh Game Level Data
  ;
@GameModeSelectionComplete:
  MOV [LevelInformationPtr], RAX
  MOV RCX, LEVEL_INFORMATION.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelStartDelay[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.LevelTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelTimer[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.TimerAfterCarsLeaveRefresh[RAX]
  MOV LEVEL_INFORMATION.TimerAfterCarsLeave[RAX], 0

  MOV RCX, LEVEL_INFORMATION.TimerBetweenConcurrentRefresh[RAX]
  MOV LEVEL_INFORMATION.TimerBetweenConcurrent[RAX], RCX

  MOV RCX, LEVEL_INFORMATION.PesdestrianTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.PesdestrianTimer[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentLevelBarrelCount[RAX], 0

  MOV RCX, LEVEL_INFORMATION.BarrelGenerateTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.BarrelGenerateTimer[RAX], RCX

  MOV LEVEL_INFORMATION.CurrentCarPartCount[RAX], 0

  MOV RCX, LEVEL_INFORMATION.CarPartGenerateTimerRefresh[RAX]
  MOV LEVEL_INFORMATION.CarPartGenerateTimer[RAX], RCX

  ;
  ; Reset Player
  ; 
  MOV [PlayerSprite.ImagePointer], 0
  MOV [PlayerSprite.ExplodePointer], 0
  MOV [PlayerSprite.SpriteAlive], 1
  MOV [PlayerSprite.SpriteX], PLAYER_START_X
  MOV [PlayerSprite.SpriteY], PLAYER_START_Y
  MOV [PlayerSprite.SpriteVelX], 0
  MOV [PlayerSprite.SpriteVelY], 0
  MOV [PlayerSprite.SpriteVelMaxX], PLAYER_START_MAX_VEL_X
  MOV [PlayerSprite.SpriteVelMaxY], PLAYER_START_MAX_VEL_Y
  MOV [PlayerSprite.SpriteWidth], PLAYER_X_DIM
  MOV [PlayerSprite.SpriteHeight], PLAYER_Y_DIM
  MOV [PlayerSprite.HitPoints], PLAYER_START_HP
  MOV [PlayerSprite.MaxHp], PLAYER_START_HP
  MOV [PlayerSprite.Damage], PLAYER_DAMAGE
  MOV [PlayerLives], PLAYER_START_LIVES     
  MOV [NextPlayerRoadLane], 1
  MOV [CurrentPlayerRoadLane], 1

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_ResetGame, _TEXT$00




;***************************************************************************************************************************************************************************
; Graphics Support Functions
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_DisplayScrollText
;
;        Parameters: Master Context, Text, Highlight Index
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayScrollText, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RBX, R8

  XOR R12, R12

@DisplayMenuText:
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  CMP R12, RBX
  JNE @SkipColorChange
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FF0000h

@SkipColorChange:
  
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE

  MOV R8, QWORD PTR [RDI]
  ADD RDI, 8
  MOV R9, QWORD PTR [RDI]
  ADD RDI, 8

  MOV RDX, RDI
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
@FindEnd:
  INC RDI
  CMP BYTE PTR [RDI], 0
  JNZ @FindEnd

  INC R12

  INC RDI
  CMP QWORD PTR [RDI], 0
  JNE @DisplayMenuText

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayScrollText, _TEXT$00


;*********************************************************
;   GreatMachine_AnimateBackground
;
;        Parameters: Master Context
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AnimateBackground, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDX, OFFSET RoadScroll
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif
  
  MOV RDX, OFFSET MountainScroll
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif

  MOV RDX, OFFSET SkyScroll
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingGif

  XOR R12, R12
  LEA R15, [TreeScrollList]
@TreeSpriteLoop:
  CMP R12, NUMBER_OF_TREE_SCROLLING
  JE @TreeLoopComplete
     CMP QWORD PTR [R15], 0
     JE @SkipTree

     MOV RDX, QWORD PTR [R15 + 8]
     MOV RCX, RSI
     DEBUG_FUNCTION_CALL GameEngine_DisplaySideScrollingSprite
     MOV QWORD PTR [R15], RAX

@SkipTree:
     ADD R15, 16
     INC R12
     JMP @TreeSpriteLoop
@TreeLoopComplete:
  INC [CurrentTreeTick]
  CMP [CurrentTreeTick], TREE_GENERATE_TICK
  JB @SkipCheck

  XOR R12, R12
  LEA R15, [TreeScrollList]
@TreeSpriteLoop2:
  CMP R12, NUMBER_OF_TREE_SCROLLING
  JE @SkipCheck
     CMP QWORD PTR [R15], 0
     JNE @SkipTree2

     CALL Math_Rand
     AND EAX, 0Fh
     CMP EAX, 4
     JA @SkipTree2

     MOV [CurrentTreeTick], 0
     
     MOV QWORD PTR [R15], 1
     MOV RDX, [R15 + 8]
     MOV SCROLLING_GIF.CurrentX[RDX], 1023
     JMP @SkipCheck
     
@SkipTree2:
     ADD R15, 16
     INC R12
     JMP @TreeSpriteLoop2

@SkipCheck:
  
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_AnimateBackground, _TEXT$00




;***************************************************************************************************************************************************************************
; Non-Level Screens
;***************************************************************************************************************************************************************************


;*********************************************************
;   GreatMachine_Loading
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value:State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Loading, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RDX, OFFSET LoadingScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV RAX, GREAT_MACHINE_STATE_LOADING
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Loading, _TEXT$00



;*********************************************************
;   GreatMachine_IntroScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_IntroScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET IntroScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  MOV RAX, GREAT_MACHINE_STATE_INTRO
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_IntroScreen, _TEXT$00



;*********************************************************
;   GreatMachine_Credits
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Credits, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_CREDITS
  MOV R12, OFFSET CreditsText1
  CMP [CreditsPage], 0
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText2
  CMP [CreditsPage], 1
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText3
  CMP [CreditsPage], 2
  JE @DisplayCreditsPage
  MOV R12, OFFSET CreditsText4
  CMP [CreditsPage], 3
  JE @DisplayCreditsPage
  
  MOV [CreditsPage], 0
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JMP @GoToMenu


@DisplayCreditsPage:

  MOV RDX, OFFSET GeneralGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, 20
  MOV RDX, R12
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], CREDITS_FONT_SIZE
  MOV R9, INTRO_Y + 40
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  JMP @CompleteDisplayingPage


@CompleteDisplayingPage:
@GoToMenu:  
@ScreenDrawComplete:
  MOV RAX, [GreatMachineCurrentState] 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Credits, _TEXT$00



;*********************************************************
;   GreatMachine_AboutScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_AboutScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, 20
  MOV RDX, OFFSET AboutText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y + 40
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ABOUT
  MOV RAX, GREAT_MACHINE_STATE_ABOUT
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_AboutScreen, _TEXT$00



;*********************************************************
;   GreatMachine_GameOver
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GameOver, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], GAME_OVER_SIZE
  MOV R9, GAME_OVER_Y
  MOV R8, GAME_OVER_X
  MOV RDX, OFFSET GameOverText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_END_GAME
  MOV RAX, GREAT_MACHINE_END_GAME
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GameOver, _TEXT$00

;*********************************************************
;   GreatMachine_Winner
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Winner, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX


;  MOV RDX, OFFSET WinnerGraphic
;  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Game Over Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], WINNER_SIZE
  MOV R9, WINNER_Y
  MOV R8, WINNER_X
  MOV RDX, OFFSET WinnerText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressEnterToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_WINSCREEN
  MOV RAX, GREAT_MACHINE_STATE_WINSCREEN
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Winner, _TEXT$00




;*********************************************************
;   GreatMachine_EnterHiScore
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_EnterHiScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV RDI, RDX
  MOV RCX, RDI
  DEBUG_FUNCTION_CALL GreatMachine_ScreenBlast
  
  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display High Score with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HS_GAME_OVER_SIZE
  MOV R9, HS_GAME_OVER_Y
  MOV R8, HS_GAME_OVER_X
  MOV RDX, OFFSET HighScoreText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], ENTER_INITIALS_SIZE
  MOV R9, ENTER_INITIALS_Y
  MOV R8, ENTER_INITIALS_X
  MOV RDX, OFFSET EnterInitials
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INITIALS_SIZE
  MOV R9, INITIALS_Y
  MOV R8, INITIALS_X
  MOV RDX, OFFSET InitialsEnter
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  MOV RAX, GREAT_MACHINE_STATE_ENTER_HI_SCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_EnterHiScore, _TEXT$00




;*********************************************************
;   GreatMachine_HiScoreScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_HiScoreScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  ;
  ; Display Hi-Score Title with random color
  ;
  DEBUG_FUNCTION_CALL Math_Rand
  MOV ECX, EAX
  SHR EAX, 8
  SHL ECX, 8
  OR EAX, ECX
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], RAX
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_TITLE_SIZE
  MOV R9, HI_SCORE_TITLE_Y
  MOV R8, HI_SCORE_TITLE_X
  MOV RDX, OFFSET HighScoresText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_MODE_FONT
  MOV R9, HI_SCORE_MODE_Y
  MOV R8, HI_SCORE_MODE_X
  CMP [GameModeSelect], 0
  JNE @ItsNotEasy
  MOV RDX, OFFSET EasyModeText
  MOV RDI, [HiScoreListPtr]
  JMP @PrintTheMode
@ItsNotEasy:
  CMP [GameModeSelect], 1
  JNE @ItsHard
  MOV RDI, [HiScoreListPtr]
  ADD RDI, 120
  MOV RDX, OFFSET MediumModeText
  JMP @PrintTheMode
@ItsHard:
  MOV RDI, [HiScoreListPtr]
  ADD RDI, 120*2
  MOV RDX, OFFSET HardModeText    
@PrintTheMode:
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord


  
  XOR RBX, RBX
  MOV R12, HI_SCORE_Y_START
@DisplayHighScoreLoop:
  
  MOV R9, QWORD PTR [RDI+4]
  MOV R8, RDI
  MOV RDX, OFFSET HiScoreFormatString
  MOV RCX, OFFSET HiScoreString
  DEBUG_FUNCTION_CALL sprintf
  ADD RDI, 4+8		; 3 Initials + NULL + QWORD
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], HI_SCORE_FONT_SIZE
  MOV R9, R12
  ADD R12, HI_SCORE_Y_INC
  MOV R8, HI_SCORE_X
  MOV RDX, OFFSET HiScoreString
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord
  
  INC RBX
  CMP RBX, MAX_HI_SCORES
  JB @DisplayHighScoreLoop

  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0FFFFFFh
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], INTRO_FONT_SIZE
  MOV R9, INTRO_Y
  MOV R8, INTRO_X
  MOV RDX, OFFSET PressSpaceToContinue
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_PrintWord

  MOV [GreatMachineCurrentState], GREAT_MACHINE_HISCORE
  MOV RAX, GREAT_MACHINE_HISCORE
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_HiScoreScreen, _TEXT$00





;*********************************************************
;   GreatMachine_OptionsScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_OptionsScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, [GameModeSelect]
  MOV RDX, OFFSET ModeSelectText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_OPTIONS
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_OptionsScreen, _TEXT$00



;*********************************************************
;   GreatMachine_MenuScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_MenuScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET MenuScreen
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R8, [MenuSelection]
  MOV RDX, OFFSET MenuText
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU

  INC [MenuIntroTimer]
  MOV RAX, [MenuIntroTimer]
  CMP RAX, MENU_MAX_TIMEOUT
  JB @KeepOnMenu

  MOV [MenuIntroTimer], 0
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_INTRO
  
@KeepOnMenu:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_MenuScreen, _TEXT$00


;*********************************************************
;   GreatMachine_GamePlayScreen
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_GamePlayScreen, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  
  MOV RDX, OFFSET GeneralGraphic
  DEBUG_FUNCTION_CALL GameEngine_DisplayFullScreenAnimatedImage

  MOV R9, TITLE_Y
  MOV R8, TITLE_X
  MOV RDX, OFFSET TitleGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage
  
  MOV [GreatMachineCurrentState], GREAT_MACHINE_GAMEPLAY
  
  CMP [GamePlayPage], 0
  JE @GamePlayPageOne
  CMP [GamePlayPage], 1
  JE @GamePlayPageTwo
  CMP [GamePlayPage], 2
  JE @GamePlayPageThree
  CMP [GamePlayPage], 3
  JE @GamePlayPageFour
  
  MOV [GamePlayPage], 0
  
  MOV [GreatMachineCurrentState], GREAT_MACHINE_STATE_MENU
  JMP @GoToMenu
  
@GamePlayPageOne:
  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextOne
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

JMP @ScreenDrawComplete

@GamePlayPageTwo:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextTwo
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

  JMP @ScreenDrawComplete
@GamePlayPageThree:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextThree
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText
  JMP @ScreenDrawComplete
@GamePlayPageFour:

  MOV R8, 50
  MOV RDX, OFFSET GamePlayTextFour
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayScrollText

@GoToMenu:  
@ScreenDrawComplete:
  MOV RAX, [GreatMachineCurrentState] 
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_GamePlayScreen, _TEXT$00


;***************************************************************************************************************************************************************************
; Levels
;***************************************************************************************************************************************************************************

;*********************************************************
;   GreatMachine_Levels
;
;        Parameters: Master Context, Double Buffer
;
;        Return Value: State
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_Levels, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  MOV [GreatMachineCurrentState], GREAT_MACHINE_LEVELS
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_AnimateBackground

  MOV RAX, [LevelInformationPtr]
  CMP LEVEL_INFORMATION.LevelStartDelay[RAX], 0
  JE @LevelPlay

  MOV R9, LEVEL_NAME_Y
  MOV R8, LEVEL_NAME_X
  MOV RDX, OFFSET LevelNameGraphic
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV R9, LEVEL_NUMBER_Y
  MOV R8, LEVEL_NUMBER_X
  MOV RAX, [LevelInformationPtr]
  MOV RDX, LEVEL_INFORMATION.LevelNumberGraphic[RAX]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplayTransparentImage

  MOV RAX, [LevelInformationPtr]
  DEC LEVEL_INFORMATION.LevelStartDelay[RAX]
  JMP @LevelDelay

@LevelPlay:

  ;**************************************************************
  ; Level Action - Section One - New Game Pieces
  ;**************************************************************
  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_DispatchGamePieces 

  ;**************************************************************
  ; Level Action - Section Two - Detection
  ;**************************************************************

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_CollisionPlayer

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_CollisionNPC

  ;**************************************************************
  ; Level Action - Section Three - Display Graphics and Sprites
  ;**************************************************************
  MOV R12D, [CurrentPlayerRoadLane]
  MOV EAX, [NextPlayerRoadLane]
  CMP R12, RAX
  JE @NotBetweenLanes
  MOV R12, 3                    ; Signal we are between lanes.
@NotBetweenLanes:
  ;
  ; Top Sidewalk First
  ;

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_DisplayzLevelSprites

  ;
  ; Lane 0
  ;
  CMP R12, 0
  JNE @SkipPlayerUpdateForLane0
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForLane0:

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_DisplayzLevelSprites

  ;
  ; Character transition between lanes
  ;
  CMP R12, 3
  JNE @SkipPlayerUpdateForBetweenLanes
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForBetweenLanes:

  ;
  ; Lane 1
  ;
  CMP R12, 1
  JNE @SkipPlayerUpdateForLane1
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GreatMachine_DisplayPlayer
@SkipPlayerUpdateForLane1:
  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_DisplayzLevelSprites

  ;
  ; Bottom Sidewalk
  ;

  ;MOV RDX, RBX
  ;MOV RCX, RSI
  ;DEBUG_FUNCTION_CALL GreatMachine_DisplayzLevelSprites



@LevelDelay:
  MOV RAX, [GreatMachineCurrentState]
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_Levels, _TEXT$00


;***************************************************************************************************************************************************************************
; Generic Support Functions
;***************************************************************************************************************************************************************************


  
;*********************************************************
;   GreatMachine_UpdateHighScore
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateHighScore, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  ;
  ; No Error Checking, assume this is all correct.
  ;
  MOV RDX, [HiScoreListPtr]
  CMP [GameModeSelect], 0
  JE @EasyMode
  ADD RDX, 120
  CMP [GameModeSelect], 1
  JE @MediumMode
  ADD RDX, 120
@MediumMode:
@EasyMode:
  ADD RDX, (120-12)          ; Set it to the last entry

@MoveAllScores:
  CMP RDX, [HiScoreLocationPtr]
  JE @FoundLocation
  
  MOV RAX, QWORD PTR [RDX-12]
  MOV QWORD PTR [RDX], RAX
  MOV EAX, DWORD PTR [RDX-4]
  MOV DWORD PTR [RDX+8], EAX
  SUB RDX, 12
  JMP @MoveAllScores

@FoundLocation:
  ;
  ; Update Hi-Scores
  ;
  MOV RCX, OFFSET InitialsEnter
  MOV EAX, DWORD PTR [RCX]
  MOV DWORD PTR [RDX], EAX
  MOV RCX, [PlayerScore]
  MOV QWORD PTR [RDX + 4], RCX
  MOV [InitialsEnterPtr], RCX
        
  MOV [HiScoreLocationPtr], 0
  
  ;  
  ; Save the scores in the file.
  ;
  DEBUG_FUNCTION_CALL GreatMachine_UpdateHiScores

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_UpdateHighScore, _TEXT$00


;*********************************************************
;   GreatMachine_HiScoreEnterUpdate
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_HiScoreEnterUpdate, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 

  CMP [GreatMachineCurrentState], GREAT_MACHINE_STATE_ENTER_HI_SCORE
  JNE @NoScoreUpdate

  MOV RCX, [InitialsEnterPtr]
  ADD BYTE PTR [RCX], AL

  CMP BYTE PTR [RCX], 'A'
  JAE @CheckAbove

  MOV BYTE PTR [RCX], 'Z'

@CheckAbove:
  CMP BYTE PTR [RCX], 'Z'
  JBE @CompleteandDone

  MOV BYTE PTR [RCX], 'A'

@CompleteandDone:
@NoScoreUpdate:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_HiScoreEnterUpdate, _TEXT$00


;*********************************************************
;   GreatMachine_ScreenCapture
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ScreenCapture, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO 
  MOV RSI, RCX
  MOV RDI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_ScreenCapture, _TEXT$00


;*********************************************************
;   GreatMachine_ScreenBlast
;
;        Parameters: Double Buffer
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ScreenBlast, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RDI, RCX
  MOV RSI, [GameOverCaptureScreen]
  MOV RCX, [GameCaptureSize]
  TEST CL, 7
  JZ @QwordCapture

  TEST CL, 3
  JZ @DwordCapture

  TEST CL, 1
  JZ @WordCapture

  REP MOVSB
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

@WordCapture:
  SHR RCX, 1
  REP MOVSW
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  

  
@DwordCapture:
  SHR RCX, 2
  REP MOVSD
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET  
@QwordCapture:
  SHR RCX, 3
  REP MOVSQ
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_ScreenBlast, _TEXT$00


;*********************************************************
;   GreatMachine_UpdateHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_UpdateHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  MOV R8, 1024
  MOV RDX, OFFSET HiScoreAppData
  MOV RCX, OFFSET ApplicationDataEnv
  DEBUG_FUNCTION_CALL GetEnvironmentVariableA
  CMP RAX, 0
  JZ @CannotGetAppDataLocation
  
  MOV R8, OFFSET HiScoreAppData
  MOV RDX, OFFSET HiScoreAppDataFileFormat
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL sprintf
  
  MOV STD_FUNCTION_STACK.Parameters.Param7[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param6[RSP], 0
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 03h  ; OPEN_EXISTING
  MOV R9, 0
  MOV R8, 3h   	 ; File Share Read/Write
  MOV RDX, 2h    ; File write
  MOV RCX, OFFSET HiScoreAppData
  DEBUG_FUNCTION_CALL CreateFileA
  
  CMP EAX, 0FFFFFFFFh   ; INVALID_HANDLE_VALUE
  JE @FailedToOpenAttemptToCreate
  
  ;
  ; Write out the initial high scores list.
  ;
  LEA R9, STD_FUNCTION_STACK.Parameters.Param7[RSP]
  MOV STD_FUNCTION_STACK.Parameters.Param5[RSP], 0
  MOV R8, 120*3				; File Size is fixed to 120*3 bytes.
  MOV RDX, [HiScoreListPtr]
  MOV RSI, RAX
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL WriteFile
  
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL CloseHandle  
 
@CannotGetAppDataLocation:
@FailedToOpenAttemptToCreate:

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
  
NESTED_END GreatMachine_UpdateHiScores, _TEXT$00


;*********************************************************
;   GreatMachine_CheckHiScores
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CheckHiScores, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  ;
  ;   Reset High Scores
  ;
  MOV RAX, OFFSET InitialsConst
  MOV EAX, [RAX]
  MOV RCX, OFFSET InitialsEnter
  MOV [RCX], EAX
  MOV [InitialsEnterPtr], RCX
        
  MOV RDX, [HiScoreListPtr]
  CMP [GameModeSelect], 0
  JE @EasyMode
  ADD RDX, 120
  CMP [GameModeSelect], 1
  JE @MediumMode
  ADD RDX, 120
@MediumMode:
@EasyMode:
  XOR R8, R8
  MOV RCX, [PlayerScore]
  
  
  MOV [HiScoreLocationPtr], 0

@CheckNextScore:
  CMP RCX, QWORD PTR [RDX + 4]
  JA @NewHighScore

  ADD RDX, 12
  INC R8
  CMP R8, MAX_HI_SCORES
  JB @CheckNextScore
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

@NewHighScore:
  MOV [HiScoreLocationPtr], RDX                 ; Update New High Score Location!
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_CheckHiScores, _TEXT$00


;***************************************************************************************************************************************************************************
; Level Resets & Maintaince
;***************************************************************************************************************************************************************************


;*********************************************************
;   GreatMachine_ResetLevel
;
;        Parameters: None
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_ResetLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  MOV RAX, [LevelInformationPtr]
  MOV RCX, LEVEL_INFORMATION.LevelStartDelayRefresh[RAX]
  MOV LEVEL_INFORMATION.LevelStartDelay[RAX], RCX

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_ResetLevel, _TEXT$00


;*********************************************************
;   GreatMachine_NextLevel
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel, _TEXT$00

;*********************************************************
;   GreatMachine_NextLevel_New
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel_New, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel_New, _TEXT$00


;*********************************************************
;   GreatMachine_NextLevel_Win
;
;        Parameters: Level Information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_NextLevel_Win, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  

  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_NextLevel_Win, _TEXT$00




;***************************************************************************************************************************************************************************
; Creating Game Pieces
;***************************************************************************************************************************************************************************




;***************************************************************************************************************************************************************************
; Colission Detection Functions
;***************************************************************************************************************************************************************************







;*********************************************************
;   GreatMachine_CollisionPlayer
;
;        Parameters: Master Context, Level information
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_CollisionPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_CollisionPlayer, _TEXT$00

;***************************************************************************************************************************************************************************
; Sprite Movement & Callback  Functions
;***************************************************************************************************************************************************************************









;***************************************************************************************************************************************************************************
; Display Graphics Functions
;***************************************************************************************************************************************************************************



;*********************************************************
;   GreatMachine_DisplayPlayer
;
;        Parameters: Master Context
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayPlayer, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO
  MOV RSI, RCX
  CMP [PlayerSprite.SpriteAlive], 0
  JE @SpriteIsDead

  CMP [PlayerSprite.SpriteVelX], 0
  JE @SkipUpdateOfX
  MOV RAX, [PlayerSprite.SpriteVelX]
  ADD [PlayerSprite.SpriteX], RAX
  CMP [PlayerSprite.SpriteX], 0
  JGE @TestOtherEnd
  MOV [PlayerSprite.SpriteX], 0
  JMP @DoneUpdatingX
@TestOtherEnd:
  MOV RAX, [PlayerSprite.SpriteX]
  ADD RAX, PLAYER_CAR_LENGTH
  CMP RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  JB @DoneUpdatingX
  MOV RAX, MASTER_DEMO_STRUCT.ScreenWidth[RSI]
  DEC RAX
  SUB RAX, PLAYER_CAR_LENGTH
  MOV [PlayerSprite.SpriteX], RAX
@DoneUpdatingX:
@SkipUpdateOfX:
  MOV EAX, [NextPlayerRoadLane]
  CMP [CurrentPlayerRoadLane], EAX
  JE @SkipPlayerMovementToNewLane
  CMP EAX, 1
  JE @MoveDown
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  NEG RAX
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_0
  JA @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 0
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_0
  JMP @DoneUpdatingMovement
@MoveDown:
  MOV RAX, [PlayerSprite.SpriteVelMaxY]
  ADD [PlayerSprite.SpriteY], RAX
  CMP [PlayerSprite.SpriteY], PLAYER_LANE_1
  JB @DoneUpdatingMovement
  MOV [CurrentPlayerRoadLane], 1
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
  JMP @DoneUpdatingMovement
@SkipPlayerMovementToNewLane:
  ;
  ; Unfortunately, we need to do this quick fix up rather than add more complicated
  ; code to deal with someone pressing both up and down at the same time and getting the
  ; car stuck in the middle of the road.
  ;
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_0
  CMP [CurrentPlayerRoadLane], 0
  JE @DoneUpdatingMovement
  MOV [PlayerSprite.SpriteY], PLAYER_LANE_1
@DoneUpdatingMovement:

  MOV R9, [PlayerSprite.SpriteY]
  MOV R8, [PlayerSprite.SpriteX]
  MOV RDX, [CurrentPlayerSprite]
  MOV RCX, RSI
  DEBUG_FUNCTION_CALL GameEngine_DisplaySprite  

@SpriteIsDead:
  XOR RAX, RAX
@ExitDisplayPlayer:
  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET
NESTED_END GreatMachine_DisplayPlayer, _TEXT$00









;*********************************************************
;   GreatMachine_DisplayGamePanel
;
;        Parameters: Master Context Level Info
;
;        Return Value: None
;
;
;*********************************************************  
NESTED_ENTRY GreatMachine_DisplayGamePanel, _TEXT$00
  alloc_stack(SIZEOF STD_FUNCTION_STACK)
  SAVE_ALL_STD_REGS STD_FUNCTION_STACK
.ENDPROLOG 
  DEBUG_RSP_CHECK_MACRO


  RESTORE_ALL_STD_REGS STD_FUNCTION_STACK
  ADD RSP, SIZE STD_FUNCTION_STACK
  RET

NESTED_END GreatMachine_DisplayGamePanel, _TEXT$00








END 