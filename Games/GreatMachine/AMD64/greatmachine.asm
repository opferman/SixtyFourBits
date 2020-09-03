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
include vpal_public.inc
include soft3d_public.inc


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
GREAT_MACHINE_STATE_BOOM                 EQU <12>
GREAT_MACHINE_STATE_PAUSE                EQU <13>
GREAT_MACHINE_FAILURE_STATE              EQU <GAME_ENGINE_FAILURE_STATE>


SPRITE_TYPE_CAR        EQU <1>
SPRITE_TYPE_TOXIC      EQU <2>
SPRITE_TYPE_PART       EQU <3>
SPRITE_TYPE_PEDESTRIAN EQU <4>
SPRITE_TYPE_POINT_ITEM EQU <5>


NUMBER_OF_CAR_GIFS     EQU <7>  ; Maximum can only be 19 due to conversion algorithm hard coding '1' when generating the gif name.
NUMBER_OF_CARS         EQU <7>


SPECIAL_SPRITE_STRUCT struct
   SpriteIsActive   dq ?
   SpriteListPtr    dq ?  ; Pointer to the listhead in case we are first and need to update it.
   SpriteVelX       dq ?
   SpriteMaxVelX    dq ?
   SpriteX          dq ?
   SpriteY          dq ?
   SpriteType       dq ?
   SpritePoints     dq ?
   SpriteBias            dq ?
   SpriteBiasMask        dq ?
   SpriteDeBounce        dq ?
   SpriteDeBounceRefresh dq ?
   ScrollingPtr     dq ?
   ListNextPtr      dq ?
   ListBeforePtr    dq ?
SPECIAL_SPRITE_STRUCT ends

DISPLAY_PLAYER_POINTS struct
   PointTicks       dq ?
   NumberOfPoints   dq ?
   PointX           dq ?
   PointY           dq ?
DISPLAY_PLAYER_POINTS ends

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
  CurrrentNumberOfCars            dq ?
  CarsCanBeMultipleLanes          dq ?
  TimerAfterCarsLeave             dq ?
  TimerAfterCarsLeaveRefresh      dq ?
  TimerBetweenConcurrent          dq ?
  TimerBetweenConcurrentRefresh   dq ?
  MinAddedVelocity                dq ?
  MaxAddedVelocity                dq ?
  VelocityCanBeDynamic            dq ?
  CarCanChangeLanes               dq ?

  ; Pedestrians
  PedestriansCanBeInStreet        dq ?
  PesdestrianTimer                dq ?
  PesdestrianTimerRefresh         dq ?
  
  ; Toxic Waste Barrels
  LevelCompleteBarrelCount        dq ?
  CurrentLevelBarrelCount         dq ?
  BarrelGenerateTimerL0           dq ?
  BarrelGenerateTimerL1           dq ?
  CurrentBarrelCountL0            dq ?
  CurrentBarrelCountL1            dq ?
  BarrelGenerateTimerRefreshL0    dq ?
  BarrelGenerateTimerRefreshL1    dq ?
  BarrelPoints                    dq ?

  ; Car Parts
  LevelCompleteCarPartCount       dq ?
  CurrentCarPartCount             dq ?
  CarPartGenerateTimerL0          dq ?
  CarPartGenerateTimerL1          dq ?
  CarPartGenerateTimerRefreshL0       dq ?
  CarPartGenerateTimerRefreshL1       dq ?
  CurrentCarPartCountL0           dq ?
  CurrentCarPartCountL1           dq ?
  CarPartsPoints                  dq ?

  ;
  ; Function Pointers
  ;
  pfnLevelReset                   dq ?
  pfnNextLevel                    dq ?
LEVEL_INFORMATION ENDS

;
; Constants for Game 
;
POINTS_DISPLAY_TICKS     EQU <10>
POINTS_DISPLAY_LIST_SIZE EQU <4>

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
NUMBER_OF_GENERIC_CARS  EQU <7>
NUMBER_OF_PEOPLE_GIFS   EQU <7>
NUMBER_OF_PEOPLE        EQU <7>
NUMBER_OF_LEVELS        EQU <4> ; If this is changed you need to update the level structure array 
PLAYER_SIDE_PANEL_FONT_SIZE EQU <2>
PLAYER_SCORE_FONT_SIZE EQU <4>

NUMBER_OF_GENERIC_ITEMS EQU <8>
NUMBER_OF_FUEL          EQU <2>
NUMBER_OF_PARTS         EQU <6>

STAR_FIELD_ENTRY struct
   Location       TD_POINT <?>
   Velocity       mmword    ?  
   StarOnScreen   dq        ?
   Color          db        ?
STAR_FIELD_ENTRY ends

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
ROAD_SCROLL_X_INC     EQU <-5>
ROAD_SCROLL_Y_INC     EQU <0>
MOUNTAIN_SCROLL_X_INC EQU <-2>
MOUNTAIN_SCROLL_Y_INC EQU <0>
SKY_SCROLL_X_INC      EQU <-1>
SKY_SCROLL_Y_INC      EQU <0>

TOP_SIDEWALK_PERSON    EQU <PLAYER_LANE_0 - 95>
BOTTOM_SIDEWALK_PERSON EQU <PLAYER_LANE_1 + 55>

;
; Player Defaults
;
 PLAYER_CAR_LENGTH      EQU <240>  ; Hard coding the sprite length.
 PLAYER_START_X         EQU <(1024/2) - (240/2)>  ; Hardcode to middle of screen
 PLAYER_START_Y         EQU <550>
 PLAYER_LANE_1          EQU <PLAYER_START_Y>
 PLAYER_LANE_0          EQU <PLAYER_START_Y - 100>
 PLAYER_START_MAX_VEL_X EQU <6>
 PLAYER_START_MAX_VEL_Y EQU <20>
 PLAYER_X_DIM           EQU <240>
 PLAYER_Y_DIM           EQU <111>
 PLAYER_START_HP        EQU <10>
 PLAYER_DAMAGE          EQU <1>
 PLAYER_START_LIVES     EQU <3>

 ;
 ; Special DeBounce for Items
 ;
 SPECIAL_DEBOUNCE       EQU <200>

 ;
 ; Enable Debug Capabilities 
 ;
 MACHINE_GAME_DEBUG     EQU <0>

;*********************************************************
; Data Segment
;*********************************************************
.DATA
    GreatMachineStateFuncPtrs dq  GreatMachine_Loading             ; GREAT_MACHINE_STATE_LOADING
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
                              dq  GreatMachine_Boom                ; GREAT_MACHINE_STATE_BOOM
                              dq  GreatMachine_Pause               ; GREAT_MACHINE_STATE_PAUSE
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
    GenericPersonImage              db "Personxxx.gif", 0   ; change the x's to numbers and add back in ".gif", 0
    BoomImage                       db "boom.gif", 0
    PanelImage                      db "panel.gif", 0
    FuelImage                       db "fuel.gif", 0
    CarPart1Image                   db "carpart1.gif", 0
    CarPart2Image                   db "carpart2.gif", 0
    CarPart3Image                   db "carpart3.gif", 0
    CarSpinImage                    db "CarSpin.gif", 0
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
    GenericPersonImage              db "PERSONxxx_GIF", 0    ; Change the X's to numbers 
    BoomImage                       db "BOOM_GIF", 0
    PanelImage                      db "PANEL_GIF", 0
    FuelImage                       db "FUEL_GIF", 0
    CarPart1Image                   db "CARPART1_GIF", 0
    CarPart2Image                   db "CARPART2_GIF", 0
    CarPart3Image                   db "CARPART3_GIF", 0
    CarSpinImage                    db "CARSPIN_GIF", 0
endif	
    HoldText                        db "Hold/Pause", 0
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
                                    db "fuel to get back home.  The fuel", 0 
                                    dq 50, 600
                                    db "is in radioactive barrels.", 0
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
                                    db "number of toxic waste barrels and", 0
                                    dq 50, 350
                                    db "parts you need to collect. Collect",0
                                    dq 50, 400
                                    db "enough fuel and all the parts to", 0
                                    dq 50, 450
                                    db "build the Great Machine to get home!",0  
                                    dq 0

    GamePlayTextFour                dq 50, 300
                                    db "Use the arrow keys to move your", 0
                                    dq 50, 350
                                    db "Great Machine around the road.",0
                                    dq 50, 400
                                    db "`P' toggles the game panel.", 0
                                    dq 50, 450
                                    db "`H' is 'hold' or 'pause'.", 0
                                    dq 50, 500
                                    db "Those are the only controls.", 0
                                    dq 0

  ;
  ; Level Support
  ;
  LevelInformationPtr  dq ?
  LevelStartTimer      dq ?
  TimerAdjustMs        dq ?
  GamePanel            dq ?
 ;
 ;
 ;  Description for the LEVEL_INFORMATION structure seen below.
 ;
 ;
 
; Level Number                                                               LevelNumber                                               
 ; Level Timer in milliseconds                                               LevelTimer                                
 ; Level Timer Refresh (Constant) in Milliseconds                            LevelTimerRefresh                         
 ; Level Number Graphic                                                      LevelNumberGraphic                              
 ; Level One Start Delay in Ticks (Ticks are # of screen updates)            LevelStartDelay              
 ; Level One Start Delay Refresh (Constant)                                  LevelStartDelayRefresh       
 ; Number of concurrent cars on the level (Constant)                         NumberOfConcurrentCars       
 ; Current Number of Cars on the Level                                       CurrrentNumberOfCars
 ; Can have cars in multiple lanes at the same time                          CarsCanBeMultipleLanes       
 ; In Ticks, how long before a new car can be generated                  TimerAfterCarsLeave              
 ; Refresh the tick rate for car generation (constant)                   TimerAfterCarsLeaveRefresh       
 ; Timer between concurrent car generation (if any) in ticks             TimerBetweenConcurrent           
 ; Timer between concurrent car generation (if any) in ticks (constant)  TimerBetweenConcurrentRefresh  
 ; The minimum velocity a car can have                                   MinAddedVelocity               
 ; The maximum velocity a car can have                                   MaxAddedVelocity                
 ; The velocity can change during game play                              VelocityCanBeDynamic            
 ; The car can change lanes during game play                             CarCanChangeLanes                 
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
 
;
; Easy cust and past configuration
; 
;LevelNumber                     dq ?  <1,\                   
;LevelTimer                      dq ?   1000 * 60 * 5,\                                 
;LevelTimerRefresh               dq ?   1000 * 60 * 5,\                                 
;LevelNumberGraphic              dq ?   OFFSET LevelOneGraphic,\                        
;LevelStartDelay                 dq ?   200,\                                           
;LevelStartDelayRefresh          dq ?   200,\                                           
;NumberOfConcurrentCars          dq ?   1,\                                             
;CurrrentNumberOfCars            dq ?   0,\                                             
;CarsCanBeMultipleLanes          dq ?   0,\                                             
;TimerAfterCarsLeave             dq ?   100,\                                           
;TimerAfterCarsLeaveRefresh      dq ?   100,\                                           
;TimerBetweenConcurrent          dq ?   0,\                                             
;TimerBetweenConcurrentRefresh   dq ?   0,\                                             
;MinAddedVelocity                dq ?   1,\                                             
;MaxAddedVelocity                dq ?   3,\                     
;VelocityCanBeDynamic            dq ?   0,\                     
;CarCanChangeLanes               dq ?   0,\                     
;PedestriansCanBeInStreet        dq ?   0,\                     
;PesdestrianTimer                dq ?   0,\                    
;PesdestrianTimerRefresh         dq ?   0,\                    
;LevelCompleteBarrelCount        dq ?   10,\                    
;CurrentLevelBarrelCount         dq ?   0,\                     
;BarrelGenerateTimerL0           dq ?   800,\                   
;BarrelGenerateTimerL1           dq ?   1500,\                   
;CurrentBarrelCountL0            dq ?   0,\                     
;CurrentBarrelCountL1            dq ?   0,\                     
;BarrelGenerateTimerRefreshL0    dq ?   800,\                   
;BarrelGenerateTimerRefreshL1    dq ?   1500,\                    
;BarrelPoints                    dq ?   25,\                     
;LevelCompleteCarPartCount       dq ?   5,\                     
;CurrentCarPartCount             dq ?   0,\                  
;CarPartGenerateTimerL0          dq ?   2000,\                  
;CarPartGenerateTimerL1          dq ?   1000,\                   
;CarGenerateTimerRefreshL0       dq ?   2000,\                  
;CarGenerateTimerRefreshL1       dq ?   1000,\                  
;CurrentCarPartCountL0           dq ?   0,\
;CurrentCarPartCountL1           dq ?   0,\   
; CarPartsPoints                        150 \            
;pfnLevelReset                   dq ?   OFFSET GreatMachine_ResetLevel,\                  
;pfnNextLevel                    dq ?   OFFSET GreatMachine_NextLevel>                 
                  
                  

LevelInformationEasy LEVEL_INFORMATION   <1,\
1000 * 60 * 5,\
1000 * 60 * 5,\
OFFSET LevelOneGraphic,\
200,\
200,\
1,\
0,\
0,\
100,\
100,\
0,\
0,\
1,\
3,\
0,\
0,\
0,\
15,\
15,\
10,\
0,\
800,\
1500,\
0,\
0,\
800,\
1500,\
25,\
5,\
0,\
2000,\
1000,\
2000,\
1000,\
0,\
0,\
150,\
OFFSET GreatMachine_ResetLevel,\
OFFSET GreatMachine_NextLevel>
                                  
LEVEL_INFORMATION   <2,\
265000,\
265000,\
OFFSET LevelTwoGraphic,\
200,\
200,\
1,\
0,\
0,\
75,\
75,\
0,\
0,\
2,\
4,\
0,\
0,\
0,\
50,\
50,\
20,\
0,\
500,\
800,\
0,\
0,\
500,\
800,\
50,\
10,\
0,\
1000,\
700,\
1000,\
700,\
0,\
0,\
200,\
OFFSET GreatMachine_ResetLevel,\
OFFSET GreatMachine_NextLevel>

LEVEL_INFORMATION  <3,\
(1000 * 60 * 4),\
(1000 * 60 * 4),\
OFFSET LevelThreeGraphic,\
200,\
200,\
1,\
0,\
0,\
75,\
75,\
0,\
0,\
2,\
4,\
0,\
0,\
0,\
50,\
50,\
20,\
0,\
500,\
800,\
0,\
0,\
500,\
800,\
50,\
15,\
0,\
500,\
200,\
500,\
200,\
0,\
0,\
200,\
OFFSET GreatMachine_ResetLevel,\
OFFSET GreatMachine_NextLevel>

LEVEL_INFORMATION  <4,\
(1000 * 60 * 3),\
(1000 * 60 * 3),\
OFFSET LevelFourGraphic,\
200,\
200,\
1,\
0,\
0,\
50,\
50,\
0,\
0,\
3,\
5,\
0,\
0,\
0,\
50,\
50,\
20,\
0,\
200,\
500,\
0,\
0,\
200,\
500,\
100,\
20,\
0,\
200,\
500,\
200,\
500,\
0,\
0,\
500,\
OFFSET GreatMachine_ResetLevel,\
OFFSET GreatMachine_Winner>

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
    ; Activate Boom Timer
    ;
    BoomTimerActive    dq 0
    BoomTimer          dq 0
    BoomTimerRefresh   dq 100
    BoomYLocation      dq ?
    BoomXLocation      dq ?
    ;
    ; Active Animation Lists
    ;
    TopSideWalkPtr    dq 0
    LaneZeroPtr       dq 0
    LaneOnePtr        dq 0
    BottomSideWalkPtr dq 0


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


    PointsScoreFormat               db "%I64i",0
    PointsScoreString               db 256 DUP(?)

    HiScoreFormatString             db "%s - %I64u", 0
    HiScoreString                   db "                                      ",0
    
    HiScoreLocationPtr              dq ?

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
    PlayerCurLevelText              db "Level: %I64u", 0
    PlayerLivesText                 db "Lives: %I64u",0
    PlayerBarrels                   db "%I64u of %I64u Fuel", 0
    PlayerParts                     db "%I64u of %I64u Parts", 0
    PlayerScoreFormat               db "%I64i", 0
    PlayerTimerFormat               db "%02I64u:%02I64u", 0
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
  VirtualPallete   dq ?
  StarEntryPtr     dq ?
  Soft3D           dq ?
  TwoDPlot         TD_POINT_2D <?>
  WorldLocation    TD_POINT    <?>
  View_Distance    mmword   1024.0
  ConstantZero     mmword 0.0
  CurrentVelocity  dq 1
  CameraX          mmword 0.0
  CameraY          mmword 0.0
  CameraXVel       mmword -0.00872665
  CameraYVel       mmword -0.00872665
  ConstantNeg      mmword -1.0
  DoubleBuffer     dq ?
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
    BoomGraphic        IMAGE_INFORMATION  <?>
    PanelGraphic       IMAGE_INFORMATION  <?>
    CarSpinGraphic     IMAGE_INFORMATION  <?>
    CarSpinConvert     SPRITE_CONVERT     <?>
    CarSpinSprite      SPRITE_BASIC_INFORMATION <?>

;
; Active Points Strutures Shouldn't need more than 8
;
    DisplayPointsList DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>
                      DISPLAY_PLAYER_POINTS <?>

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
; Person Graphics
;
   GenericPersonListPtr   dq ?
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

   GenericPersonSpriteList      SPECIAL_SPRITE_STRUCT      <?>
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

   GenericPersonScrollList      SCROLLING_GIF      <?>
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

   GenericPersonImageList IMAGE_INFORMATION <?>
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



   GenericItemsImagePtr  dq OFFSET FuelImage
                         dq OFFSET FuelImage 
                         dq OFFSET CarPart1Image
                         dq OFFSET CarPart2Image
                         dq OFFSET CarPart3Image
                         dq OFFSET CarPart1Image 
                         dq OFFSET CarPart2Image 
                         dq OFFSET CarPart3Image 
                         dq ? 
                         dq ? 
                         dq ? 
                         dq ? 
                         dq ? 
                         dq ? 


   FuelItemsList         dq OFFSET GenericItemsList
   CarPartsItemsList     dq OFFSET GenericItems_CarParts

   GenericItemsList          SPECIAL_SPRITE_STRUCT      <?>
                             SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_CarParts     SPECIAL_SPRITE_STRUCT      <?>
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

   GenericItemsScrollList      SCROLLING_GIF      <?>
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

   GenericItemsImageList IMAGE_INFORMATION <?>
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

    PauseGame          dq 0
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

;
; Splitting the code into multiple files the easy way.  Without having to "extern" everything into a shared header,
; instead will split them into files and just include them here.
;

include GameInit.asm              ; Entry point and early initialization
include GameLoading.asm           ; Loading graphics and initialization of the game components
include GameKeyboard.asm          ; Key Press handlers
include GameReset.asm             ; Functions to reset the game state for new games
include GameMenuEarlyScreens.asm  ; Game Menu Screens, Options Screens and Early Screens
include GameSpriteDisplay.asm     ; Displays sprites during game play
include GameScoreHandler.asm      ; Functions to handle the high scores lists
include GameLevels.asm            ; The callback handling for the levels
include GameCollision.asm         ; Handle collision detection
include GameGenericSupport.asm    ; Generic support functions for the game.
include GameLevelWinnerHandlers.asm  ; Support level reset, changing levels, winning and loosing.
include GameGeneration.asm        ; Support generation of game pieces
include GameGraphicsSupport.asm   ; Graphics support functions
include GameBackground.asm        ; Support generating the Paralax Scrolling Background

END 