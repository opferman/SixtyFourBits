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


;*********************************************************
; Code Switches
;*********************************************************
; USE_FILES              EQU <1>
 MACHINE_GAME_DEBUG     EQU <1>

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
include audio_public.inc

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
extern SizeofResource:proc

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

;
; Types of Sprites Available in the Game
;
SPRITE_TYPE_CAR        EQU <1>
SPRITE_TYPE_FUEL       EQU <2>
SPRITE_TYPE_PART1      EQU <3>
SPRITE_TYPE_PART2      EQU <4>
SPRITE_TYPE_PART3      EQU <5>
SPRITE_TYPE_PEDESTRIAN EQU <6>
SPRITE_TYPE_EXTRA_LIFE EQU <7>
SPRITE_TYPE_HAZARD     EQU <8>

;
; Sprite Kill Points
;
SPRITE_KILLS            EQU <0FFFFFFFFFFFFFFFEh>
SPRITE_NEGATIVE_POINTS  EQU <-10000>

;
; Item and Array Counts
;
NUMBER_OF_CARS           EQU <7>  ; Maximum can only be 19 due to conversion algorithm hard coding '1' when generating the gif name.
NUMBER_OF_PEOPLE         EQU <8>
NUMBER_OF_LEVELS         EQU <4> ; If this is changed you need to update the level structure array 
NUMBER_OF_GENERIC_ITEMS  EQU <12> ; NUMBER_OF_PARTS + NUMBER_OF_FUEL + NUMBER_OF_EXTRA_LIFE + NUMBER_OF_HAZARDS
NUMBER_OF_FUEL           EQU <2>
NUMBER_OF_PARTS1         EQU <2>
NUMBER_OF_PARTS2         EQU <2>
NUMBER_OF_PARTS3         EQU <2>
NUMBER_OF_EXTRA_LIFE     EQU <1>
NUMBER_OF_HAZARDS        EQU <3>
NUMBER_OF_TREE_SCROLLING EQU <12>

;
; Tick Rate Constants
;
ESTIMATED_TICKS_PER_SECOND EQU <66>             ; Will vary on different macines.

;
; Lane Information
;
LANE_GENERATE_LEFT              EQU <1>
LANE_GENERATE_RIGHT             EQU <0>
LANE_BITMASK_0                  EQU <01h>
LANE_BITMASK_1                  EQU <02h>
LANE_BITMASK_2                  EQU <04h>
LANE_TOP_SIDEWALK_BITMASK       EQU <08h>
LANE_BOTTOM_SIDEWALK_BITMASK    EQU <010h>
LANE_BLOCKING                   EQU <1>
LANE_NOT_BLOCKING               EQU <0>

;
; Constants for Points
;
POINTS_DISPLAY_TICKS     EQU <10>       ; Ticks to display the Points
POINTS_DISPLAY_LIST_SIZE EQU <4>        ; How many points can be displayed at once
POINT_EXTRA_LIFE         EQU <0FFFFFFFFFFFFFFFFh>


;
; Hi Scores constants
;
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

;
; Screen locations and font sizes
;
TITLE_X                EQU <50>
TITLE_Y                EQU <10>
INTRO_Y                EQU <768 - 80>
INTRO_X                EQU <300>
INTRO_FONT_SIZE        EQU <3>
CREDITS_FONT_SIZE      EQU <2>
GAME_OVER_X            EQU <125>
GAME_OVER_Y            EQU <300>
GAME_OVER_SIZE         EQU <10>
WINNER_X               EQU <225>
WINNER_Y               EQU <300>
WINNER_SIZE            EQU <10>
HS_GAME_OVER_X         EQU <100>
HS_GAME_OVER_Y         EQU <300>
HS_GAME_OVER_SIZE      EQU <10>
ENTER_INITIALS_X       EQU <275>
ENTER_INITIALS_Y       EQU <400>
ENTER_INITIALS_SIZE    EQU <3>
INITIALS_X             EQU <350>
INITIALS_Y             EQU <500>
INITIALS_SIZE          EQU <10>


;
; Parallax Scrolling Constants
;
ROAD_SCROLL_X_INC      EQU <-5>
ROAD_SCROLL_Y_INC      EQU <0>
MOUNTAIN_SCROLL_X_INC  EQU <-2>
MOUNTAIN_SCROLL_Y_INC  EQU <0>
SKY_SCROLL_X_INC       EQU <-1>
SKY_SCROLL_Y_INC       EQU <0>
TREE_GENERATE_TICK     EQU <75>

;
; Game Options and Menu Constants
;

MAX_GAME_OPTIONS       EQU <3>
MAX_MENU_SELECTION     EQU <7>
MENU_MAX_TIMEOUT       EQU <30*50> ; About 22 Seconds


;
; Cached Allocation Constant
;
LARGE_GAME_ALLOCATION  EQU <1024*1024*5> ; 5 MB


;
; Level Graphics Intro Placement
;
LEVEL_NAME_Y                EQU <768/2 - 30>
LEVEL_NAME_X                EQU <50>
LEVEL_NUMBER_Y              EQU <768/2 - 30>
LEVEL_NUMBER_X              EQU <510>

;
; Player Runtime Stats Font Constants
;
PLAYER_SIDE_PANEL_FONT_SIZE EQU <2>
PLAYER_SCORE_FONT_SIZE      EQU <4>
PLAYER_SCORE_FONT_SIZE EQU <INTRO_FONT_SIZE>
PLAYER_SCORE_X         EQU <500>
PLAYER_SCORE_Y         EQU <10>


;
; Sidewalk Character Placement
;
TOP_SIDEWALK_PERSON    EQU <PLAYER_LANE_0 - 95>
BOTTOM_SIDEWALK_PERSON EQU <PLAYER_LANE_2 + 55>

;
; Player Defaults
;
 PLAYER_CAR_LENGTH      EQU <240>  ; Hard coding the sprite length.
 PLAYER_START_X         EQU <(1024/2) - (240/2)>  ; Hardcode to middle of screen
 PLAYER_START_Y         EQU <550 + 18>
 PLAYER_LANE_2          EQU <PLAYER_START_Y>
 PLAYER_LANE_1          EQU <PLAYER_START_Y - 100>
 PLAYER_LANE_0          EQU <PLAYER_LANE_1 - 100>
 PLAYER_START_MAX_VEL_X EQU <6>
 PLAYER_START_MAX_VEL_Y EQU <20>
 PLAYER_Y_DIM           EQU <111>
 PLAYER_START_LIVES     EQU <3>

;
; Reset Constants
;
 PLAYER_GAME_RESET         EQU <0>
 PLAYER_LEVEL_RESET        EQU <1>
 PLAYER_NEXT_LEVEL_RESET   EQU <2>
 PLAYER_WRAP_AROUND        EQU <3>
 LEVEL_GAME_RESET          EQU <4>
 LEVEL_LEVEL_RESET         EQU <5>
 LEVEL_NEXT_LEVEL_RESET    EQU <6>
 LEVEL_WRAP_AROUND         EQU <7>
 GLOBALS_GAME_RESET        EQU <8>
 GLOBALS_LEVEL_RESET       EQU <9>
 GLOBALS_NEXT_LEVEL_RESET  EQU <10>
 GLOBALS_WRAP_AROUND       EQU <11>





;*********************************************************
; Structures 
;*********************************************************

SPECIAL_SPRITE_STRUCT struct
   SpriteIsActive          dq ?
   SpriteListPtr           dq ?  ; Pointer to the listhead in case we are first and need to update it.
   SpriteVelX              dq ?
   SpriteMaxVelX           dq ?
   SpriteX                 dq ?
   SpriteY                 dq ?
   SpriteLaneBitmask       dq ?
   SpriteType              dq ?
   SpritePoints            dq ?
   SpriteGenerationPercent dq ?  ; 0 to 100
   SpriteDeBounce          dq ?  
   SpriteDeBounceRefresh   dq ?  ; The Debounce for this sprite
   ScrollingPtr            dq ?
   ListNextPtr             dq ?
   ListBeforePtr           dq ?
   pfnCollisionNpc         dq ?
   pfnCollisionPlayer      dq ?
   pfnSpriteOffScreen      dq ?
SPECIAL_SPRITE_STRUCT ends


GENERATE_STRUCT struct
   pfnTickDebounceUpdate  dq ?
   pfnPreGenerateCheck    dq ?
   pfnLoopCheck           dq ?
   pfnActivateSprite      dq ?
   ItemListPtr            dq ?
   NumberOfItemsOnList    dq ?
GENERATE_STRUCT ends



DISPLAY_PLAYER_POINTS struct
   PointTicks       dq ?
   NumberOfPoints   dq ?
   PointX           dq ?
   PointY           dq ?
DISPLAY_PLAYER_POINTS ends

SPRITE_STRUCT  struct
   SpriteAlive              dq ?
   SpriteX                  dq ?
   SpriteY                  dq ?
   SpriteVelX               dq ?
   SpriteVelY               dq ?
   SpriteVelMaxX            dq ?
   SpriteVelMaxY            dq ?
SPRITE_STRUCT  ends 


LEVEL_INFO STRUCT
  LevelNumber             dq ?
  LevelNumberGraphic      dq ?

;
; Number of Items settings for the level
;
  NumberOfConcurrentCars            dq ?
  CurrentNumberOfCars               dq ?
  NumberOfConcurrentFuel            dq ?
  CurrentNumberOfFuel               dq ?
  NumberOfConcurrentPartOne         dq ?
  CurrentNumberOfPartOne            dq ?
  NumberOfConcurrentPartTwo         dq ?
  CurrentNumberOfPartTwo            dq ?
  NumberOfConcurrentPartThree       dq ?
  CurrentNumberOfPartThree          dq ?
  NumberOfConcurrentBlockers        dq ?
  CurrentNumberOfBlockers           dq ?
 
;
; Tracking Required Level Completion Criteria
;
  RequiredFuelCollection            dq ?
  CurrentFuelCollection             dq ?
  RequiredPartOneCollection         dq ?
  CurrentPartOneCollection          dq ?
  RequiredPartTwoCollection         dq ?
  CurrentPartTwoCollection          dq ?
  RequiredPartThreeCollection       dq ?
  CurrentPartThreeCollection        dq ?
;
; Generation Percentage
;
  GenerateCarsPercentage            dq ?
  GenerateFuelPercentage            dq ?
  GenerateCarPartOnPercentage       dq ?
  GenerateCarPartTwoPercentage      dq ?
  GenerateCarPartThreePercentage    dq ?
  GenerateHazardsPercentage         dq ?
  GenerateExtraLifePercentage       dq ?
  GeneratePedestriansPercentage     dq ?
;
; Points
;
  FuelPoints                        dq ?
  CarPartOnePoints                  dq ?
  CarPartTwoPoints                  dq ?
  CarPartThreePoints                dq ?

;
; Sprite Debounce Refresh 
;
  CarDebounceRefresh                dq ?
  FuelDebounceRefresh               dq ?
  ExtraLifeDebounceRefresh          dq ?
  Parts1DebounceRefresh             dq ?
  Parts2DebounceRefresh             dq ?
  Parts3DebounceRefresh             dq ?
  HazardDebounceRefresh             dq ?
  PedestrianDebounceRefresh         dq ?

;
; Number Of Blocking Items Per Lane
;
  BlockingItemCountLane0            dq ?
  BlockingItemCountLane1            dq ?
  BlockingItemCountLane2            dq ?

;
; Various Settings to tweak the level
;
  MinCarVelocity                    dq ?
  MaxCarVelocity                    dq ?
  PedestriansCanBeInStreet          dq ?

;
; Timers
;
  LevelStartDelay                   dq ?
  LevelStartDelayRefresh            dq ?
  LevelTimer                        dq ?
  LevelTimerRefresh                 dq ?
  TimerBetweenConCurrentCars        dq ?
  TimerBetweenConcurrentCarsRefresh dq ?
  TimerAfterCarExitsScreen          dq ?
  TimerAfterCarExitsScreenRefresh   dq ?
  TimerForPedestrians               dq ?
  TimerForPedestriansRefresh        dq ?
  TimerForFuel                      dq ?
  TimerForFuelRefresh               dq ?
  TimerForExtraLives                dq ?
  TimerForExtraLivesRefresh         dq ?
  TimerForHazard                    dq ?
  TimerForHazardRefresh             dq ?
  TimerForParts1                    dq ?
  TimerForParts1Refresh             dq ?
  TimerForParts2                    dq ?
  TimerForParts2Refresh             dq ?
  TimerForParts3                    dq ?
  TimerForParts3Refresh             dq ?
  TimerForLane0ItemSelection        dq ?
  TimerForLane0ItemSelectionRefresh dq ?
  TimerForLane1ItemSelection        dq ?
  TimerForLane1ItemSelectionRefresh dq ?
  TimerForLane2ItemSelection        dq ?
  TimerForLane2ItemSelectionRefresh dq ?

;
; Function Pointers
;
  pfnLevelReset                   dq ?
  pfnNextLevel                    dq ?
LEVEL_INFO ENDS


STAR_FIELD_ENTRY struct
   Location       TD_POINT <?>
   Velocity       mmword    ?  
   StarOnScreen   dq        ?
   Color          db        ?
STAR_FIELD_ENTRY ends

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
    FuelImage1                      db "fuel.gif", 0
    FuelImage2                      db "fuel2.gif", 0
    CarPart1Image                   db "carpart1.gif", 0
    CarPart2Image                   db "carpart2.gif", 0
    CarPart3Image                   db "carpart3.gif", 0
    CarPart4Image                   db "carpart4.gif", 0
    CarPart5Image                   db "carpart5.gif", 0
    CarPart6Image                   db "carpart6.gif", 0
    CarSpinImage                    db "CarSpin.gif", 0
    Item1Image                      db "Item1.gif", 0
    PanelIcon1                      db "fuel_icon.gif",0
    PanelIcon2                      db "CarPart1_icon.gif",0
    PanelIcon3                      db "CarPart2_icon.gif",0
    PanelIcon4                      db "CarPart3_icon.gif",0
    CarbrokeImage                   db "brokendown.gif", 0
    DeathbarrelImage                db "deathbarrel.gif", 0
    DumpsterImage                   db "dumpster.gif", 0

    TitleMusic                      db "title.audio", 0
    GameMusic                       db "game.audio", 0
    WinMusic                        db "winmusic.audio", 0
    CrashEffect                     db "crash.audio", 0
    PickupEffect                    db "pickup.audio", 0    
    CollectedEffect                 db "collectall.audio", 0
    ExtralifeEffect                 db "extralife.audio", 0
    CaritemEffect                   db "caritem.audio", 0 
    PedestrianHitEffect             db "pedestrianhit.audio", 0  
else	
    GifResourceType                 db "GIFFILE", 0
    AudioResourceType               db "AUDIOFILE", 0
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
    FuelImage1                      db "FUEL_GIF", 0
    FuelImage2                      db "FUEL2_GIF", 0
    CarPart1Image                   db "CARPART1_GIF", 0
    CarPart2Image                   db "CARPART2_GIF", 0
    CarPart3Image                   db "CARPART3_GIF", 0
    CarPart4Image                   db "CARPART4_GIF", 0
    CarPart5Image                   db "CARPART5_GIF", 0
    CarPart6Image                   db "CARPART6_GIF", 0
    CarSpinImage                    db "CARSPIN_GIF", 0
    Item1Image                      db "ITEM1_GIF", 0
    PanelIcon1                      db "ICON1_GIF", 0
    PanelIcon2                      db "ICON2_GIF", 0
    PanelIcon3                      db "ICON3_GIF", 0
    PanelIcon4                      db "ICON4_GIF", 0
    CarbrokeImage                   db "CARBROKE_GIF", 0    
    DeathbarrelImage                db "DEATHBARREL_GIF", 0 
    DumpsterImage                   db "DUMPSTER_GIF", 0    

    TitleMusic                      db "TITLE_AUDIO_MUSIC", 0
    GameMusic                       db "GAME_AUDIO_MUSIC", 0
    WinMusic                        db "WIN_AUDIO_MUSIC", 0
    CrashEffect                     db "CRASH_AUDIO_EFFECT", 0
    PickupEffect                    db "PICKUP_AUDIO_EFFECT", 0    
    CollectedEffect                 db "COLLECTED_AUDIO_EFFECT", 0 
    ExtralifeEffect                 db "EXTRALIFE_AUDIO_EFFECT", 0
    CaritemEffect                   db "CARITEM_AUDIO_EFFECT", 0  
    PedestrianHitEffect             db "PEDESTRIAN_AUDIO_EFFECT", 0  
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
    ExtraLife                       db "+1 Life", 0
  ;
  ; Level Support
  ;
  LevelInformationPtr  dq ?
  LevelStartTimer      dq ?
  TimerAdjustMs        dq ?
  GamePanel            dq ?
  
  ;
  ; Options Short Cuts
  ;
  LevelInformationEasy       EQU <LevelInfo_Easy_1_LevelNumber>
  LevelInformationMedium     EQU <LevelInfo_Easy_1_LevelNumber>  
  LevelInformationHard       EQU <LevelInfo_Easy_1_LevelNumber>
   
  ;
  ; Level Data.  Structure too big to initialize directly.
  ;
  LevelInfo_Easy_1_LevelNumber                       dq 1
  LevelInfo_Easy_1_LevelNumberGraphic                dq OFFSET LevelOneGraphic
  LevelInfo_Easy_1_NumberOfConcurrentCars            dq 2
  LevelInfo_Easy_1_CurrentNumberOfCars               dq 0
  LevelInfo_Easy_1_NumberOfConcurrentFuel            dq 2
  LevelInfo_Easy_1_CurrentNumberOfFuel               dq 0
  LevelInfo_Easy_1_NumberOfConcurrentPartOne         dq 1
  LevelInfo_Easy_1_CurrentNumberOfPartOne            dq 0
  LevelInfo_Easy_1_NumberOfConcurrentPartTwo         dq 1
  LevelInfo_Easy_1_CurrentNumberOfPartTwo            dq 0
  LevelInfo_Easy_1_NumberOfConcurrentPartThree       dq 1
  LevelInfo_Easy_1_CurrentNumberOfPartThree          dq 0
  LevelInfo_Easy_1_NumberOfConcurrentBlockers        dq 1
  LevelInfo_Easy_1_CurrentNumberOfBlockers           dq 0
  LevelInfo_Easy_1_RequiredFuelCollection            dq 10
  LevelInfo_Easy_1_CurrentFuelCollection             dq 0
  LevelInfo_Easy_1_RequiredPartOneCollection         dq 5
  LevelInfo_Easy_1_CurrentPartOneCollection          dq 0
  LevelInfo_Easy_1_RequiredPartTwoCollection         dq 2
  LevelInfo_Easy_1_CurrentPartTwoCollection          dq 0
  LevelInfo_Easy_1_RequiredPartThreeCollection       dq 1
  LevelInfo_Easy_1_CurrentPartThreeCollection        dq 0
  LevelInfo_Easy_1_GenerateCarsPercentage            dq 15
  LevelInfo_Easy_1_GenerateFuelPercentage            dq 20
  LevelInfo_Easy_1_GenerateCarPartOnPercentage       dq 15
  LevelInfo_Easy_1_GenerateCarPartTwoPercentage      dq 10
  LevelInfo_Easy_1_GenerateCarPartThreePercentage    dq 2
  LevelInfo_Easy_1_GenerateHazardsPercentage         dq 10
  LevelInfo_Easy_1_GenerateExtraLifePercentage       dq 5
  LevelInfo_Easy_1_GeneratePedestriansPercentage     dq 20
  LevelInfo_Easy_1_FuelPoints                        dq 150
  LevelInfo_Easy_1_CarPartOnePoints                  dq 300
  LevelInfo_Easy_1_CarPartTwoPoints                  dq 450
  LevelInfo_Easy_1_CarPartThreePoints                dq 600
  LevelInfo_Easy_1_CarDebounceRefresh                dq 500
  LevelInfo_Easy_1_FuelDebounceRefresh               dq ESTIMATED_TICKS_PER_SECOND*3
  LevelInfo_Easy_1_ExtraLifeDebounceRefresh          dq ESTIMATED_TICKS_PER_SECOND*60*3
  LevelInfo_Easy_1_Parts1DebounceRefresh             dq ESTIMATED_TICKS_PER_SECOND*8
  LevelInfo_Easy_1_Parts2DebounceRefresh             dq ESTIMATED_TICKS_PER_SECOND*16
  LevelInfo_Easy_1_Parts3DebounceRefresh             dq ESTIMATED_TICKS_PER_SECOND*25
  LevelInfo_Easy_1_HazardDebounceRefresh             dq ESTIMATED_TICKS_PER_SECOND*3
  LevelInfo_Easy_1_PedestrianDebounceRefresh         dq 20
  LevelInfo_Easy_1_BlockingItemCountLane0            dq 0
  LevelInfo_Easy_1_BlockingItemCountLane1            dq 0
  LevelInfo_Easy_1_BlockingItemCountLane2            dq 0               ; Can only have 1 blocking item per lane.
  LevelInfo_Easy_1_MinCarVelocity                    dq 3
  LevelInfo_Easy_1_MaxCarVelocity                    dq 4
  LevelInfo_Easy_1_PedestriansCanBeInStreet          dq 1
  LevelInfo_Easy_1_LevelStartDelay                   dq 200
  LevelInfo_Easy_1_LevelStartDelayRefresh            dq 200
  LevelInfo_Easy_1_LevelTimer                        dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_1_LevelTimerRefresh                 dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_1_TimerBetweenConCurrentCars        dq ESTIMATED_TICKS_PER_SECOND
  LevelInfo_Easy_1_TimerBetweenConcurrentCarsRefresh dq 150
  LevelInfo_Easy_1_TimerAfterCarExitsScreen          dq 0
  LevelInfo_Easy_1_TimerAfterCarExitsScreenRefresh   dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForPedestrians               dq 0
  LevelInfo_Easy_1_TimerForPedestriansRefresh        dq ESTIMATED_TICKS_PER_SECOND
  LevelInfo_Easy_1_TimerForFuel                      dq 0
  LevelInfo_Easy_1_TimerForFuelRefresh               dq ESTIMATED_TICKS_PER_SECOND*10
  LevelInfo_Easy_1_TimerForExtraLives                dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForExtraLivesRefresh         dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForHazard                    dq 50
  LevelInfo_Easy_1_TimerForHazardRefresh             dq 50
  LevelInfo_Easy_1_TimerForParts1                    dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForParts1Refresh             dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForParts2                    dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForParts2Refresh             dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_1_TimerForParts3                    dq ESTIMATED_TICKS_PER_SECOND*36
  LevelInfo_Easy_1_TimerForParts3Refresh             dq ESTIMATED_TICKS_PER_SECOND*56
  LevelInfo_Easy_1_TimerForLane0ItemSelection        dq 150
  LevelInfo_Easy_1_TimerForLane0ItemSelectionRefresh dq 150
  LevelInfo_Easy_1_TimerForLane1ItemSelection        dq 250
  LevelInfo_Easy_1_TimerForLane1ItemSelectionRefresh dq 250
  LevelInfo_Easy_1_TimerForLane2ItemSelection        dq 350
  LevelInfo_Easy_1_TimerForLane2ItemSelectionRefresh dq 350
  LevelInfo_Easy_1_pfnLevelReset                     dq OFFSET GreatMachine_ResetLevel
  LevelInfo_Easy_1_pfnNextLevel                      dq OFFSET GreatMachine_NextLevel

  LevelInfo_Easy_2_LevelNumber                       dq 2
  LevelInfo_Easy_2_LevelNumberGraphic                dq OFFSET LevelTwoGraphic
  LevelInfo_Easy_2_NumberOfConcurrentCars            dq 1
  LevelInfo_Easy_2_CurrentNumberOfCars               dq 0
  LevelInfo_Easy_2_NumberOfConcurrentFuel            dq 2
  LevelInfo_Easy_2_CurrentNumberOfFuel               dq 0
  LevelInfo_Easy_2_NumberOfConcurrentPartOne         dq 1
  LevelInfo_Easy_2_CurrentNumberOfPartOne            dq 0
  LevelInfo_Easy_2_NumberOfConcurrentPartTwo         dq 1
  LevelInfo_Easy_2_CurrentNumberOfPartTwo            dq 0
  LevelInfo_Easy_2_NumberOfConcurrentPartThree       dq 1
  LevelInfo_Easy_2_CurrentNumberOfPartThree          dq 0
  LevelInfo_Easy_2_NumberOfConcurrentBlockers        dq 1
  LevelInfo_Easy_2_CurrentNumberOfBlockers           dq 0
  LevelInfo_Easy_2_RequiredFuelCollection            dq 10
  LevelInfo_Easy_2_CurrentFuelCollection             dq 0
  LevelInfo_Easy_2_RequiredPartOneCollection         dq 5
  LevelInfo_Easy_2_CurrentPartOneCollection          dq 0
  LevelInfo_Easy_2_RequiredPartTwoCollection         dq 2
  LevelInfo_Easy_2_CurrentPartTwoCollection          dq 0
  LevelInfo_Easy_2_RequiredPartThreeCollection       dq 1
  LevelInfo_Easy_2_CurrentPartThreeCollection        dq 0
  LevelInfo_Easy_2_GenerateCarsPercentage            dq 15
  LevelInfo_Easy_2_GenerateFuelPercentage            dq 35
  LevelInfo_Easy_2_GenerateCarPartOnPercentage       dq 20
  LevelInfo_Easy_2_GenerateCarPartTwoPercentage      dq 15
  LevelInfo_Easy_2_GenerateCarPartThreePercentage    dq 10
  LevelInfo_Easy_2_GenerateHazardsPercentage         dq 10
  LevelInfo_Easy_2_GenerateExtraLifePercentage       dq 5
  LevelInfo_Easy_2_GeneratePedestriansPercentage     dq 25
  LevelInfo_Easy_2_FuelPoints                        dq 150
  LevelInfo_Easy_2_CarPartOnePoints                  dq 200
  LevelInfo_Easy_2_CarPartTwoPoints                  dq 300
  LevelInfo_Easy_2_CarPartThreePoints                dq 400
  LevelInfo_Easy_2_CarDebounceRefresh                dq 500
  LevelInfo_Easy_2_FuelDebounceRefresh               dq 50
  LevelInfo_Easy_2_ExtraLifeDebounceRefresh          dq 2000
  LevelInfo_Easy_2_Parts1DebounceRefresh             dq 100
  LevelInfo_Easy_2_Parts2DebounceRefresh             dq 300
  LevelInfo_Easy_2_Parts3DebounceRefresh             dq 500
  LevelInfo_Easy_2_HazardDebounceRefresh             dq 50
  LevelInfo_Easy_2_PedestrianDebounceRefresh         dq 20
  LevelInfo_Easy_2_BlockingItemCountLane0            dq 0
  LevelInfo_Easy_2_BlockingItemCountLane1            dq 0
  LevelInfo_Easy_2_BlockingItemCountLane2            dq 0               ; Can only have 1 blocking item per lane.
  LevelInfo_Easy_2_MinCarVelocity                    dq 3
  LevelInfo_Easy_2_MaxCarVelocity                    dq 4
  LevelInfo_Easy_2_PedestriansCanBeInStreet          dq 0
  LevelInfo_Easy_2_LevelStartDelay                   dq 200
  LevelInfo_Easy_2_LevelStartDelayRefresh            dq 200
  LevelInfo_Easy_2_LevelTimer                        dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_2_LevelTimerRefresh                 dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_2_TimerBetweenConCurrentCars        dq 0
  LevelInfo_Easy_2_TimerBetweenConcurrentCarsRefresh dq 50
  LevelInfo_Easy_2_TimerAfterCarExitsScreen          dq 0
  LevelInfo_Easy_2_TimerAfterCarExitsScreenRefresh   dq 100
  LevelInfo_Easy_2_TimerForPedestrians               dq 0
  LevelInfo_Easy_2_TimerForPedestriansRefresh        dq 50
  LevelInfo_Easy_2_TimerForFuel                      dq 0
  LevelInfo_Easy_2_TimerForFuelRefresh               dq ESTIMATED_TICKS_PER_SECOND
  LevelInfo_Easy_2_TimerForExtraLives                dq 2000
  LevelInfo_Easy_2_TimerForExtraLivesRefresh         dq ESTIMATED_TICKS_PER_SECOND*120
  LevelInfo_Easy_2_TimerForHazard                    dq 50
  LevelInfo_Easy_2_TimerForHazardRefresh             dq 50
  LevelInfo_Easy_2_TimerForParts1                    dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_2_TimerForParts1Refresh             dq ESTIMATED_TICKS_PER_SECOND*5
  LevelInfo_Easy_2_TimerForParts2                    dq ESTIMATED_TICKS_PER_SECOND*7
  LevelInfo_Easy_2_TimerForParts2Refresh             dq ESTIMATED_TICKS_PER_SECOND*7
  LevelInfo_Easy_2_TimerForParts3                    dq ESTIMATED_TICKS_PER_SECOND*25
  LevelInfo_Easy_2_TimerForParts3Refresh             dq ESTIMATED_TICKS_PER_SECOND*25
  LevelInfo_Easy_2_TimerForLane0ItemSelection        dq 50
  LevelInfo_Easy_2_TimerForLane0ItemSelectionRefresh dq 50
  LevelInfo_Easy_2_TimerForLane1ItemSelection        dq 50
  LevelInfo_Easy_2_TimerForLane1ItemSelectionRefresh dq 50
  LevelInfo_Easy_2_TimerForLane2ItemSelection        dq 50
  LevelInfo_Easy_2_TimerForLane2ItemSelectionRefresh dq 50
  LevelInfo_Easy_2_pfnLevelReset                     dq OFFSET GreatMachine_ResetLevel
  LevelInfo_Easy_2_pfnNextLevel                      dq OFFSET GreatMachine_NextLevel

  LevelInfo_Easy_3_LevelNumber                       dq 3
  LevelInfo_Easy_3_LevelNumberGraphic                dq OFFSET LevelThreeGraphic
  LevelInfo_Easy_3_NumberOfConcurrentCars            dq 2
  LevelInfo_Easy_3_CurrentNumberOfCars               dq 0
  LevelInfo_Easy_3_NumberOfConcurrentFuel            dq 2
  LevelInfo_Easy_3_CurrentNumberOfFuel               dq 0
  LevelInfo_Easy_3_NumberOfConcurrentPartOne         dq 1
  LevelInfo_Easy_3_CurrentNumberOfPartOne            dq 0
  LevelInfo_Easy_3_NumberOfConcurrentPartTwo         dq 1
  LevelInfo_Easy_3_CurrentNumberOfPartTwo            dq 0
  LevelInfo_Easy_3_NumberOfConcurrentPartThree       dq 1
  LevelInfo_Easy_3_CurrentNumberOfPartThree          dq 0
  LevelInfo_Easy_3_NumberOfConcurrentBlockers        dq 1
  LevelInfo_Easy_3_CurrentNumberOfBlockers           dq 0
  LevelInfo_Easy_3_RequiredFuelCollection            dq 10
  LevelInfo_Easy_3_CurrentFuelCollection             dq 0
  LevelInfo_Easy_3_RequiredPartOneCollection         dq 5
  LevelInfo_Easy_3_CurrentPartOneCollection          dq 0
  LevelInfo_Easy_3_RequiredPartTwoCollection         dq 2
  LevelInfo_Easy_3_CurrentPartTwoCollection          dq 0
  LevelInfo_Easy_3_RequiredPartThreeCollection       dq 1
  LevelInfo_Easy_3_CurrentPartThreeCollection        dq 0
  LevelInfo_Easy_3_GenerateCarsPercentage            dq 15
  LevelInfo_Easy_3_GenerateFuelPercentage            dq 35
  LevelInfo_Easy_3_GenerateCarPartOnPercentage       dq 20
  LevelInfo_Easy_3_GenerateCarPartTwoPercentage      dq 15
  LevelInfo_Easy_3_GenerateCarPartThreePercentage    dq 10
  LevelInfo_Easy_3_GenerateHazardsPercentage         dq 10
  LevelInfo_Easy_3_GenerateExtraLifePercentage       dq 5
  LevelInfo_Easy_3_GeneratePedestriansPercentage     dq 25
  LevelInfo_Easy_3_FuelPoints                        dq 150
  LevelInfo_Easy_3_CarPartOnePoints                  dq 200
  LevelInfo_Easy_3_CarPartTwoPoints                  dq 300
  LevelInfo_Easy_3_CarPartThreePoints                dq 400
  LevelInfo_Easy_3_CarDebounceRefresh                dq 500
  LevelInfo_Easy_3_FuelDebounceRefresh               dq 50
  LevelInfo_Easy_3_ExtraLifeDebounceRefresh          dq 2000
  LevelInfo_Easy_3_Parts1DebounceRefresh             dq 100
  LevelInfo_Easy_3_Parts2DebounceRefresh             dq 300
  LevelInfo_Easy_3_Parts3DebounceRefresh             dq 500
  LevelInfo_Easy_3_HazardDebounceRefresh             dq 50
  LevelInfo_Easy_3_PedestrianDebounceRefresh         dq 20
  LevelInfo_Easy_3_BlockingItemCountLane0            dq 0
  LevelInfo_Easy_3_BlockingItemCountLane1            dq 0
  LevelInfo_Easy_3_BlockingItemCountLane2            dq 0               ; Can only have 1 blocking item per lane.
  LevelInfo_Easy_3_MinCarVelocity                    dq 3
  LevelInfo_Easy_3_MaxCarVelocity                    dq 4
  LevelInfo_Easy_3_PedestriansCanBeInStreet          dq 0
  LevelInfo_Easy_3_LevelStartDelay                   dq 200
  LevelInfo_Easy_3_LevelStartDelayRefresh            dq 200
  LevelInfo_Easy_3_LevelTimer                        dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_3_LevelTimerRefresh                 dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_3_TimerBetweenConCurrentCars        dq 0
  LevelInfo_Easy_3_TimerBetweenConcurrentCarsRefresh dq 150
  LevelInfo_Easy_3_TimerAfterCarExitsScreen          dq 0
  LevelInfo_Easy_3_TimerAfterCarExitsScreenRefresh   dq 200
  LevelInfo_Easy_3_TimerForPedestrians               dq 0
  LevelInfo_Easy_3_TimerForPedestriansRefresh        dq 50
  LevelInfo_Easy_3_TimerForFuel                      dq 0
  LevelInfo_Easy_3_TimerForFuelRefresh               dq 300
  LevelInfo_Easy_3_TimerForExtraLives                dq 2000
  LevelInfo_Easy_3_TimerForExtraLivesRefresh         dq 2000
  LevelInfo_Easy_3_TimerForHazard                    dq 50
  LevelInfo_Easy_3_TimerForHazardRefresh             dq 50
  LevelInfo_Easy_3_TimerForParts1                    dq 100
  LevelInfo_Easy_3_TimerForParts1Refresh             dq 100
  LevelInfo_Easy_3_TimerForParts2                    dq 500
  LevelInfo_Easy_3_TimerForParts2Refresh             dq 500
  LevelInfo_Easy_3_TimerForParts3                    dq 1000
  LevelInfo_Easy_3_TimerForParts3Refresh             dq 1000
  LevelInfo_Easy_3_TimerForLane0ItemSelection        dq 150
  LevelInfo_Easy_3_TimerForLane0ItemSelectionRefresh dq 150
  LevelInfo_Easy_3_TimerForLane1ItemSelection        dq 250
  LevelInfo_Easy_3_TimerForLane1ItemSelectionRefresh dq 250
  LevelInfo_Easy_3_TimerForLane2ItemSelection        dq 350
  LevelInfo_Easy_3_TimerForLane2ItemSelectionRefresh dq 350
  LevelInfo_Easy_3_pfnLevelReset                     dq OFFSET GreatMachine_ResetLevel
  LevelInfo_Easy_3_pfnNextLevel                      dq OFFSET GreatMachine_NextLevel
                 
  LevelInfo_Easy_4_LevelNumber                       dq 4
  LevelInfo_Easy_4_LevelNumberGraphic                dq OFFSET LevelFourGraphic
  LevelInfo_Easy_4_NumberOfConcurrentCars            dq 2
  LevelInfo_Easy_4_CurrentNumberOfCars               dq 0
  LevelInfo_Easy_4_NumberOfConcurrentFuel            dq 2
  LevelInfo_Easy_4_CurrentNumberOfFuel               dq 0
  LevelInfo_Easy_4_NumberOfConcurrentPartOne         dq 1
  LevelInfo_Easy_4_CurrentNumberOfPartOne            dq 0
  LevelInfo_Easy_4_NumberOfConcurrentPartTwo         dq 1
  LevelInfo_Easy_4_CurrentNumberOfPartTwo            dq 0
  LevelInfo_Easy_4_NumberOfConcurrentPartThree       dq 1
  LevelInfo_Easy_4_CurrentNumberOfPartThree          dq 0
  LevelInfo_Easy_4_NumberOfConcurrentBlockers        dq 1
  LevelInfo_Easy_4_CurrentNumberOfBlockers           dq 0
  LevelInfo_Easy_4_RequiredFuelCollection            dq 10
  LevelInfo_Easy_4_CurrentFuelCollection             dq 0
  LevelInfo_Easy_4_RequiredPartOneCollection         dq 5
  LevelInfo_Easy_4_CurrentPartOneCollection          dq 0
  LevelInfo_Easy_4_RequiredPartTwoCollection         dq 2
  LevelInfo_Easy_4_CurrentPartTwoCollection          dq 0
  LevelInfo_Easy_4_RequiredPartThreeCollection       dq 1
  LevelInfo_Easy_4_CurrentPartThreeCollection        dq 0
  LevelInfo_Easy_4_GenerateCarsPercentage            dq 15
  LevelInfo_Easy_4_GenerateFuelPercentage            dq 35
  LevelInfo_Easy_4_GenerateCarPartOnPercentage       dq 20
  LevelInfo_Easy_4_GenerateCarPartTwoPercentage      dq 15
  LevelInfo_Easy_4_GenerateCarPartThreePercentage    dq 10
  LevelInfo_Easy_4_GenerateHazardsPercentage         dq 10
  LevelInfo_Easy_4_GenerateExtraLifePercentage       dq 5
  LevelInfo_Easy_4_GeneratePedestriansPercentage     dq 25
  LevelInfo_Easy_4_FuelPoints                        dq 150
  LevelInfo_Easy_4_CarPartOnePoints                  dq 200
  LevelInfo_Easy_4_CarPartTwoPoints                  dq 300
  LevelInfo_Easy_4_CarPartThreePoints                dq 400
  LevelInfo_Easy_4_CarDebounceRefresh                dq 500
  LevelInfo_Easy_4_FuelDebounceRefresh               dq 50
  LevelInfo_Easy_4_ExtraLifeDebounceRefresh          dq 2000
  LevelInfo_Easy_4_Parts1DebounceRefresh             dq 100
  LevelInfo_Easy_4_Parts2DebounceRefresh             dq 300
  LevelInfo_Easy_4_Parts3DebounceRefresh             dq 500
  LevelInfo_Easy_4_HazardDebounceRefresh             dq 50
  LevelInfo_Easy_4_PedestrianDebounceRefresh         dq 20
  LevelInfo_Easy_4_BlockingItemCountLane0            dq 0
  LevelInfo_Easy_4_BlockingItemCountLane1            dq 0
  LevelInfo_Easy_4_BlockingItemCountLane2            dq 0               ; Can only have 1 blocking item per lane.
  LevelInfo_Easy_4_MinCarVelocity                    dq 3
  LevelInfo_Easy_4_MaxCarVelocity                    dq 4
  LevelInfo_Easy_4_PedestriansCanBeInStreet          dq 0
  LevelInfo_Easy_4_LevelStartDelay                   dq 200
  LevelInfo_Easy_4_LevelStartDelayRefresh            dq 200
  LevelInfo_Easy_4_LevelTimer                        dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_4_LevelTimerRefresh                 dq 1000 * 60 * 6  ; 6 Minutes
  LevelInfo_Easy_4_TimerBetweenConCurrentCars        dq 0
  LevelInfo_Easy_4_TimerBetweenConcurrentCarsRefresh dq 150
  LevelInfo_Easy_4_TimerAfterCarExitsScreen          dq 0
  LevelInfo_Easy_4_TimerAfterCarExitsScreenRefresh   dq 200
  LevelInfo_Easy_4_TimerForPedestrians               dq 0
  LevelInfo_Easy_4_TimerForPedestriansRefresh        dq 50
  LevelInfo_Easy_4_TimerForFuel                      dq 0
  LevelInfo_Easy_4_TimerForFuelRefresh               dq 300
  LevelInfo_Easy_4_TimerForExtraLives                dq 2000
  LevelInfo_Easy_4_TimerForExtraLivesRefresh         dq 2000
  LevelInfo_Easy_4_TimerForHazard                    dq 50
  LevelInfo_Easy_4_TimerForHazardRefresh             dq 50
  LevelInfo_Easy_4_TimerForParts1                    dq 100
  LevelInfo_Easy_4_TimerForParts1Refresh             dq 100
  LevelInfo_Easy_4_TimerForParts2                    dq 500
  LevelInfo_Easy_4_TimerForParts2Refresh             dq 500
  LevelInfo_Easy_4_TimerForParts3                    dq 1000
  LevelInfo_Easy_4_TimerForParts3Refresh             dq 1000
  LevelInfo_Easy_4_TimerForLane0ItemSelection        dq 150
  LevelInfo_Easy_4_TimerForLane0ItemSelectionRefresh dq 150
  LevelInfo_Easy_4_TimerForLane1ItemSelection        dq 250
  LevelInfo_Easy_4_TimerForLane1ItemSelectionRefresh dq 250
  LevelInfo_Easy_4_TimerForLane2ItemSelection        dq 350
  LevelInfo_Easy_4_TimerForLane2ItemSelectionRefresh dq 350
  LevelInfo_Easy_4_pfnLevelReset                     dq OFFSET GreatMachine_ResetLevel
  LevelInfo_Easy_4_pfnNextLevel                      dq OFFSET GreatMachine_NextLevel_Win

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
    Lane0Ptr          dq 0
    Lane1Ptr          dq 0
    Lane2Ptr          dq 0
    BottomSideWalkPtr dq 0

    ;
    ; Lane Selection Space
    ;
    LaneSelectionSpace  dq 0, 0
                        dq 0, 0
                        dq 0, 0
                        dq 0, 0
                        dq 0, 0


    ;
    ; Indexable Array
    ;
    Lane0YLocation    dq PLAYER_LANE_0
    Lane1YLocation    dq PLAYER_LANE_1
    Lane2YLocation    dq PLAYER_LANE_2
    
    ;
    ; Panel Item Icons
    ;
    PanelIcon1Graphic   IMAGE_INFORMATION <?>
    PanelIcon2Graphic   IMAGE_INFORMATION <?>
    PanelIcon3Graphic   IMAGE_INFORMATION <?>
    PanelIcon4Graphic   IMAGE_INFORMATION <?>

    ;                    
    ;  Player Support Structures
    ;
    CurrentPlayerSprite             dq ?
    PlayerFirstCarGraphic           IMAGE_INFORMATION  <?>
    PlayerFirstCarConvert           SPRITE_CONVERT     <?>         
    PlayerSprite                    SPRITE_STRUCT      <?>
    PlayerSpriteBasicInformation    SPRITE_BASIC_INFORMATION <?>
    NextPlayerRoadLane              dd ?
    CurrentPlayerRoadLane           dd ?
    MovingLanesDown                 dd ?
    PlayerLives                     dq 0
    PlayerScore                     dq 0
    PlayerLanePtr                   dq 0

    ;
    ; Inactive Lists - Change the constant "TOTAL_ENEMY_LISTS" if additional are added or removed.
    ;

    ;
    ; Game Text
    ;
    GameModeText                    dq OFFSET EasyMode
                                    dq OFFSET MediumMode
                                    dq OFFSET HardMode
    ;
    ; Gmae Mode Selection
    ;
    GameModeSelect                  dq 0
    ModeSelectText                  dq 400, 300
    EasyMode                        db "Easy Mode", 0
                                    dq 365, 350
    MediumMode                      db "Medium Mode",0
                                    dq 400, 400
    HardMode                        db "Hard Mode", 0
                                    dq 0
    ;
    ; Screen Text Data
    ;
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

    ;
    ; Strings
    ;                               									
    HighScoresText                  db "High Scores", 0
    EasyModeText                    db "Easy Mode",0
    MediumModeText                  db "Medium Mode", 0
    HardModeText                    db "Hard Mode",0



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

    ;
    ; Player Information and Panel
    ;
    PlayerOutputText                db 256 DUP(?)
    PlayerCurLevelText              db "Level: %I64u", 0
    PlayerLivesText                 db "Lives: %I64u",0
    PlayerBarrels                   db "%I64u of %I64u Fuel", 0
    PlayerParts                     db "%I64u of %I64u Parts", 0
    PlayerScoreFormat               db "%I64i", 0
    PlayerTimerFormat               db "%02I64u:%02I64u", 0
    
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
    ; Starfield Data
    ;
    VirtualPallete                  dq ?
    StarEntryPtr                    dq ?
    Soft3D                          dq ?
    TwoDPlot                        TD_POINT_2D <?>
    WorldLocation                   TD_POINT    <?>
    View_Distance                   mmword   1024.0
    ConstantZero                    mmword 0.0
    CurrentVelocity                 dq 1
    CameraX                         mmword 0.0
    CameraY                         mmword 0.0
    CameraXVel                      mmword -0.00872665
    CameraYVel                      mmword -0.00872665
    ConstantNeg                     mmword -1.0
    DoubleBuffer                    dq ?

     ;
     ; Game Variable Structures
     ;
     LargeMemoryAllocation          dq ?
     LargeMemoryAllocationEnd       dq ?
     CurrentMemoryPtr               dq ?
     SpriteConvert                  SPRITE_CONVERT     <?>
     GameEngInit                    GAME_ENGINE_INIT   <?>
     RoadGraphic                    IMAGE_INFORMATION  <?>
     RoadScroll                     SCROLLING_GIF      <?>
     MountainGraphic                IMAGE_INFORMATION  <?>
     MountainScroll                 SCROLLING_GIF      <?>
     SkyGraphic                     IMAGE_INFORMATION  <?>
     SkyScroll                      SCROLLING_GIF      <?>
     LoadingScreen                  IMAGE_INFORMATION  <?>
     IntroScreen                    IMAGE_INFORMATION  <?>
     MenuScreen                     IMAGE_INFORMATION  <?>
     TitleGraphic                   IMAGE_INFORMATION  <?>
     GeneralGraphic                 IMAGE_INFORMATION  <?>
     BoomGraphic                    IMAGE_INFORMATION  <?>
     PanelGraphic                   IMAGE_INFORMATION  <?>
     CarSpinGraphic                 IMAGE_INFORMATION  <?>
     CarSpinConvert                 SPRITE_CONVERT     <?>
     CarSpinSprite                  SPRITE_BASIC_INFORMATION <?>
     PauseGame                      dq 0


    ;
    ; Active Sprite lists
    ;
    DisplayPointsList               DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>
                                    DISPLAY_PLAYER_POINTS <?>

   GenericCarListPtr                dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?

   GenericCarSpriteList             SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>                             

   GenericCarScrollList             SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>

   GenericCarImageList              IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>

   GenericPersonListPtr             dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?
                                    dq ?

   GenericPersonSpriteList          SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>

   GenericPersonScrollList          SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>
                                    SCROLLING_GIF      <?>

   GenericPersonImageList           IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>
                                    IMAGE_INFORMATION <?>



   GenericItemsImagePtr             dq OFFSET FuelImage1
                                    dq OFFSET FuelImage2 
                                    dq OFFSET CarPart1Image
                                    dq OFFSET CarPart4Image
                                    dq OFFSET CarPart2Image
                                    dq OFFSET CarPart5Image 
                                    dq OFFSET CarPart3Image 
                                    dq OFFSET CarPart6Image 
                                    dq OFFSET Item1Image
                                    dq OFFSET CarbrokeImage
                                    dq OFFSET DeathbarrelImage
                                    dq OFFSET DumpsterImage


   FuelItemsList                    dq OFFSET GenericItemsList

   GenericItemsList                 SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_CarPart1            SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_CarPart2            SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_CarPart3            SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_ExtraLife           SPECIAL_SPRITE_STRUCT      <?>
   GenericItems_Hazards             SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>
                                    SPECIAL_SPRITE_STRUCT      <?>                       

   GenericItemsScrollList           SCROLLING_GIF      <?>
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

   GenericItemsImageList            IMAGE_INFORMATION <?>
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

    HazardPoints                    dq SPRITE_KILLS
                                    dq SPRITE_NEGATIVE_POINTS
                                    dq SPRITE_KILLS
    ;
    ; Generation of new items structure configuratino
    ;
    GenerateCarsStructure           GENERATE_STRUCT <GreatMachine_Cars_TickDebounceUpdate, GreatMachine_Cars_PreGenerateCheck, GreatMachine_Cars_LoopCheck, GreatMachine_Cars_ActivateSprite, OFFSET GenericCarSpriteList, NUMBER_OF_CARS>
    GenerateFuelStructure           GENERATE_STRUCT <GreatMachine_Fuel_TickDebounceUpdate, GreatMachine_Fuel_PreGenerateCheck, GreatMachine_Fuel_LoopCheck, GreatMachine_Fuel_ActivateSprite, OFFSET GenericItemsList, NUMBER_OF_FUEL>
    GeneratePart1Structure          GENERATE_STRUCT <GreatMachine_Part1_TickDebounceUpdate, GreatMachine_Part1_PreGenerateCheck, GreatMachine_Part1_LoopCheck, GreatMachine_Part1_ActivateSprite, OFFSET GenericItems_CarPart1, NUMBER_OF_PARTS1>
    GeneratePart2Structure          GENERATE_STRUCT <GreatMachine_Part2_TickDebounceUpdate, GreatMachine_Part2_PreGenerateCheck, GreatMachine_Part2_LoopCheck, GreatMachine_Part2_ActivateSprite, OFFSET GenericItems_CarPart2, NUMBER_OF_PARTS2>
    GeneratePart3Structure          GENERATE_STRUCT <GreatMachine_Part3_TickDebounceUpdate, GreatMachine_Part3_PreGenerateCheck, GreatMachine_Part3_LoopCheck, GreatMachine_Part3_ActivateSprite, OFFSET GenericItems_CarPart3, NUMBER_OF_PARTS3>
    GeneratePedestriansStructure    GENERATE_STRUCT <GreatMachine_Pedestrians_TickDebounceUpdate, GreatMachine_Pedestrians_PreGenerateCheck, GreatMachine_Pedestrians_LoopCheck, GreatMachine_Pedestrians_ActivateSprite, OFFSET GenericPersonSpriteList, NUMBER_OF_PEOPLE>
    GenerateExtraLifeStructure      GENERATE_STRUCT <GreatMachine_ExtraLife_TickDebounceUpdate, GreatMachine_ExtraLife_PreGenerateCheck, GreatMachine_ExtraLife_LoopCheck, GreatMachine_ExtraLife_ActivateSprite, OFFSET GenericItems_ExtraLife, NUMBER_OF_EXTRA_LIFE>
    GenerateHazardsStructure        GENERATE_STRUCT <GreatMachine_Hazards_TickDebounceUpdate, GreatMachine_Hazards_PreGenerateCheck, GreatMachine_Hazards_LoopCheck, GreatMachine_Hazards_ActivateSprite, OFFSET GenericItems_Hazards, NUMBER_OF_HAZARDS>

    ;
    ;  Tree Graphics Data
    ; 
    Tree1Graphic                    IMAGE_INFORMATION  <?>
    Tree2Graphic                    IMAGE_INFORMATION  <?>
    Tree3Graphic                    IMAGE_INFORMATION  <?>
    Tree4Graphic                    IMAGE_INFORMATION  <?>

    TreeScrollList                  dq  ?  ; TRUE if Active FALSE if not.
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
                                 
   TreeScrollData                   SCROLLING_GIF      <?>
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
                                 

    ;
    ; Hi Score File Name
    ;
    HiScoreAppData            db 1024 DUP(?)
    HiScoreAppDataDirFormat   db "%s\\GreatMachinex64", 0
    HiScoreAppDataFileFormat  db "%s\\GreatMachinex64\\GreatMachinex64.HS", 0
    HiScoreAppDataFileFormat2 db "%s\\GreatMachinex64.HS", 0
    ApplicationDataEnv        db "APPDATA",0

    ;
    ; High Score Data
    ;

    PointsScoreFormat               db "%I64i",0
    PointsScoreString               db 256 DUP(?)

    HiScoreFormatString             db "%s - %I64u", 0
    HiScoreString                   db "                                      ",0
    
    HiScoreLocationPtr              dq ?
    HiScoreListPtr                  dq OFFSET HiScoreListConst
    HiScoreListConst                db "TEO", 0  ; Easy Mode Scores
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


     ;
     ; Include Audio Data
     ;
     AudioFormat            db 01h, 00h, 02h, 00h, 044h, 0ach, 00h, 00h, 010h, 0b1h, 02h, 00h, 04h, 00h, 010h, 00h
     AudioHandle            dq ?
     TitleMusicData         AUDIO_SOUND_DATA <?>
     GameMusicData          AUDIO_SOUND_DATA <?>
     WinMusicData           AUDIO_SOUND_DATA <?>
     CrashEffectData        AUDIO_SOUND_DATA <?>
     CollectedEffectData    AUDIO_SOUND_DATA <?>
     PickupEffectData       AUDIO_SOUND_DATA <?>
     ExtralifeEffectData    AUDIO_SOUND_DATA <?> 
     CaritemEffectData      AUDIO_SOUND_DATA <?> 


     TitleMusicId           dq ?
     GameMusicId            dq ?
     WinMusicId             dq ?
     CrashEffectId          dq ?
     CollectEffectId        dq ?
     PickupEffectId         dq ?
     CaritemEffectId        dq ?
     ExtralifeEffectId      dq ?
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