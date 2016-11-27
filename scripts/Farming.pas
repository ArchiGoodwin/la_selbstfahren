unit Farming;

interface

uses SysUtils, Classes, RegExpr, Moving;

var
	m_isDead: boolean = false;
	m_equippedWeaponID: integer = -1;

// TODO: create a special logic, which will detect the Character name and load appropriate custom config file with next params: 
// deagleee	
// const m_userConfig: string = 'deaglee';
// const m_HuntingZonePath: string = 'Scripts/deaglee_/scripts/HuntingZonePath001';	
	
// Hwel	
// const m_userConfig: string = 'Hwel';
// const m_HuntingZonePath: string = 'Scripts/deaglee_/scripts/HuntingHwel_Mithryl_15';	

// GythaOgg	
const m_userConfig: string = 'GythaOgg';
const m_HuntingZonePath: string = 'Scripts/deaglee_/scripts/HuntingGythaOgg_StartLoc_1';	
const m_maxSecondsOnspot: integer = 15;
const m_defaultSpotRange: integer = 1000;
	
// Init function. Can be replaced with True Class constructor
function InitializeLocalVariables(): integer;	
// TODO: fix it - it doesn't write log anywhere. Also make sense to write special function to send IM in ICQ
// Print message
function AddMsgToLog(p_strMsg: string): integer;
// Move to the point with a bit rnd range on X and Y coordinates
function Neurotic_Clicks_Thread(d: integer): integer;

// TODO: add function to check captcha
// TODO: add any other functions to check GMs
//function CheckCharDisarmed(): boolean;
// TODO: add check and fix DeBuffs
//function CheckCharDeBuffed(): boolean;
function IsOtherPlayerOnSpot(p_Range: integer): boolean;
// Check agro players:
function CheckPvpOrPk(p_Range: integer): boolean;
// Go to town if dead
function GoHomeIfDead(): integer;
// Check if character is locked in coordinates
function CheckCharIsLocked(): integer;


// Hunting zone. Sprint across the specific hunting zone.
// TODO: in ideal the algorithm is next:
// 1. Write the path with some profitable points of farming/spoiling
// 2. Save this path in file for different locations for different characters
// 3. Hunt on each part of hunting zone not so much time. Not much than 5 minutes, e.g.
// 4. If the other player is detected, move to next place.
// 5. After completing hunting on one hunting zone (e.g. in 5 spots, nit much than 30 minutes), SOE to town and go to next hunting zone.
function FarmMobsInHuntingZone(): integer;
function FarmOnSpot(pWayPoints: PRecordPointArray; p_spotId: integer; p_MaxSecondsOnSpot: integer; p_StarSpotIndex: integer): integer;
function MoveToStartPointOfSpot(pWayPoints: PRecordPointArray; p_wayPointId: integer; p_spotId: integer): integer;

implementation

function InitializeLocalVariables(): integer;
begin
	Result := 0;
	
	if (Engine.Status = lsOffline) then
	begin
		Result := -1;
	end
	else begin
		Print('InitializeLocalVariables');
		// TODO: load some special variables for current character
		// TODO: m_equippedWeaponID :=
		m_isDead := (User.HP = 0);
		//Gps.LoadBase(exepath+'\qpath.db3');  // Либо название своей базы
	end;
end;

function AddMsgToLog(p_strMsg: string): integer;
begin
  Result := 0;
  Print(p_strMsg);
end;

function Neurotic_Clicks_Thread(d: integer): integer;     // поток, имитирующий нервное кликальнье мышкой по земле рядом с персонажем
begin
  Result := 0;
  
  while RndDelay(450) do 
  begin                                                         // запускаем бесконечный цикл
		if (Engine.Status = lsOnline) then 
		begin                                        // если мы в игре, то
		  if (not User.Moved) and (not User.InCombat) and (User.Cast.EndTime = 0)       // если мы не движемся, не в бою, ничего не кастуем
		  and ((User.Target = nil) or (User.Target.Dead)) then                          // и у нас нет таргета или цель мертва, то
			if Engine.DMoveTo(User.X+random(2*d)-d, User.Y+random(2*d)-d, User.Z) then  // делаем рандомный шаг в сторону
			  Delay(1445+random(12500));                                                  // и ждем рандомное кол-во времени
		end;
  end;
end;

function CheckCharIsDisarmed(): boolean;
var
// TODO: define equipped Weapon ID at the start point of the script and store it in local var.
  WeaponID: integer;//ID Itema оружия
  item: TL2Item;
begin
	Result := false;
	
	while delay(550) do begin
	  if inventory.user.byid(WeaponID, item) and not (Item.Equipped) then 
	  begin
		Delay(500);
		Engine.UseItem(WeaponID);
		Result := true;
		Delay(800);
	  end;
	end;
end;

function CheckCharIsLocked(): integer;
var
	ChekPoint: array [0..2] of Integer;  
begin 
	Result := 0;

	while true do begin
		RndDelay(1000);
		if Engine.Status = lsonline then 
		begin
			ChekPoint[0] := User.X;
			ChekPoint[1] := User.Y;
			ChekPoint[2] := User.Z;
			RndDelay(300000);
			if (ChekPoint[0] = user.x) and (ChekPoint[1] = user.y) and (ChekPoint[2] = user.z) then 
			begin
				// Character is locked
				engine.gameclose;
			end;
		end;
	end;
end;

function GoHomeIfDead(): integer;
begin
	Result := 0;
	
	if (User.HP=0) then
	begin
		m_isDead := true;
		RndDelay(500);
		Engine.GoHome;
		Engine.Facecontrol(0, False);
		RndDelay(6500);
		Print('GoHomeIfDead');
		Result := -1;
		if (User.HP>0) then 
		begin
			m_isDead := false;
			Result := 1;
		end;
	end;
end;

function CheckPvpOrPk(p_Range: integer): boolean;
var i: integer;
begin
Result:=false;
  for i:=0 to CharList.Count-1 do
  begin
  if ((CharList.Items(i).Inzone) and (not CharList.Items(i).Dead) and (Abs(CharList.Items(i).z-User.z)<1000) and (CharList.Items(i).target = user)) then
   if CharList.Items(i).Pvp or CharList.Items(i).PK then 
	   begin 
		 print('Вот он-> '+CharList.Items(i).name+' пытается нас грохнуть! Валим!');
	   Result:=true;
	   end;
   end;
end;

function IsOtherPlayerOnSpot(p_Range: integer): boolean;
var i: integer;
begin
	Result:=false;
	for i:=0 to CharList.Count-1 do
	begin
		if ((CharList.Items(i).Inzone) and (not CharList.Items(i).Dead) and (Abs(CharList.Items(i).z-User.z)<1000) and 
			(User.InRange(CharList.Items(i).X, CharList.Items(i).Y, CharList.Items(i).Z, p_Range))) then
		begin 
			print('Leaving spot because the next Char has been found: '+CharList.Items(i).name);
			Result:=true;
		end;
	end;
end;


function FarmMobsInHuntingZone(): integer;
var
	spotId, countSpot, index, countFailedSpots: integer;
	bCanToGoToNextSpot: boolean;
	fileNameWayPoints: string;
	wayPoints : TRecordPointArray;
begin
	Print('FarmMobsInHuntingZone');
	
	Result := 0;
	RndDelay(500);
	bCanToGoToNextSpot := true;
	countFailedSpots := 0;
	
	// Load wayPoints from file for hunting zone
	// File should be created independently in RecordPath unit for any of hunting zone.
	fileNameWayPoints := m_HuntingZonePath;
	
	countSpot := ReadWayPointsFile(fileNameWayPoints, @wayPoints);
    if (countSpot < 1) then
	begin
		Print('No wayPoints loaded from file.');
		Exit();
	end; 
	Print('Count of loaded spots: ' + IntToStr(countSpot));
	
	spotId := wayPoints[0].SpotId;
	Engine.LoadConfig(m_userConfig);    

	// Check the start point of farming from the array of way points
	while ((spotId < countSpot) and bCanToGoToNextSpot) do 
	begin
		RndDelay(500);
		GoHomeIfDead();		
		// TODO: it makes sense to add DoBuff() here
		
		// 1. Find nearest waypoint
		index := FindNearestWayPoint(@wayPoints, m_defaultSpotRange, spotId);
		
		if (index = -1) then // didn't find the waypoint for specific spot, try to find any waypoint
			index := FindNearestWayPoint(@wayPoints, m_defaultSpotRange, -1);
		
		if ((index > -1) and (index < high(wayPoints))) then 
		begin
			// 2. Check that the next SpotId is greater then previos SpotId
			if (wayPoints[index].SpotId >= spotId) then
				spotId := wayPoints[index].SpotId
			else 
				bCanToGoToNextSpot := false; 
			
			if (bCanToGoToNextSpot) then
			begin
				// 3. MoveToStartPointOfSpot
				index := MoveToStartPointOfSpot(@wayPoints, index, spotId);
				if (index = -1) then
				begin
					Print('Was failed to achieve nearest START SPOT point.');
					Exit();
				end else
				begin
					// 4. Farm On current START SPOT point.
					if (FarmOnSpot(@wayPoints, spotId, m_maxSecondsOnspot, index) < 0) then
					begin
						Print('Something wrong with last spot. Cannot continue to farm on this spot.');
						// Add here a counter of failed spots in current hunting zone. Can use it to halt.
						Inc(countFailedSpots);
						if (countFailedSpots > 2) then 
							bCanToGoToNextSpot := false;
					end
					else begin
						Print('Farming on last spot was completed.');
					end;
					
					Inc(spotId);
				end
			end;
		end else
		begin
			Print('No any way point has been found near user.');
			bCanToGoToNextSpot := false;
		end;
	end;
	
	Print('Farm in current hunting zone is COMPLETED.');
end;

function MoveToStartPointOfSpot(pWayPoints: PRecordPointArray; p_wayPointId: integer; p_spotId: integer): integer;
var
	index: integer;
	isPointFound: boolean;
begin
	Print('MoveToStartPointOfSpot(wayPointId: ' + IntToStr(p_wayPointId) + '; spotId: ' + IntToStr(p_spotId));
	RndDelay(500);
	Result := -1;
	isPointFound := false;
	index := p_wayPointId;
	
	while ((index < high(pWayPoints^)) and (NOT isPointFound)) do
	begin
		// Debug 
		Print('Index:' + IntToStr(index) + '; PointType: ' + IntToStr(Ord(pWayPoints^[index].PointType)));
		if ((pWayPoints^[index].spotId = p_spotId)) then
		begin
			if (RndMoveTo(pWayPoints^[index].X, pWayPoints^[index].Y, pWayPoints^[index].Z)) then
			begin
				isPointFound := (pWayPoints^[index].PointType = START_SPOT);
				if (isPointFound) then
				begin
					Result := index;
					Print('MoveToStartPointOfSpot - on START_POINT point');
					break;
				end;
			end;	
		end;
		
		Inc(index);
	end;
end;

function FarmOnSpot(pWayPoints: PRecordPointArray; p_spotId: integer; p_MaxSecondsOnSpot: integer; p_StarSpotIndex: integer): integer;
var
	secondsOnSpot: integer;
	bNeedToGoToNextSpot, bIsOtherPlayerDetected: boolean;
	spotRange : integer;
	startSpotPoint: TRecordPoint;
begin
	Print('FarmOnSpot(spotId: '+IntToStr(p_spotId)+'; max seconds on spot: '+IntToStr(p_MaxSecondsOnSpot));
	
	Result := 0;
	bNeedToGoToNextSpot := false;
	spotRange := m_defaultSpotRange;
		
	{
	while ((index < high(pWayPoints^)) and (NOT isPointFound)) do
	begin
		isPointFound := (pWayPoints^[index].spotId = p_spotId) AND (pWayPoints^[index].PointType = START_WAY);
		if (isPointFound) then
		begin
			startWayPoint := pWayPoints^[index];
			indexStartWayPoint := index;
			Print('StartWayPoint Index: ' + IntToStr(index));
		end;
		Inc(index);
	end;
	
	// Check that user is on the start point of Way to next spot
	if (User.InRange(startWayPoint.X, startWayPoint.Y, startWayPoint.Z, 600)) then 
	begin		
		Print('User is on the start WAY point of spot');

		index := MoveToStartPointOfSpot(pWayPoints, indexStartWayPoint, p_spotId);
		
		if (index > -1) then
		begin
			startSpotPoint := pWayPoints^[index]
		end
		else begin
			Print('Start SPOT point has not been found.');
			Result := -2;
			Exit();
		end;	
	end else
	begin
		Print('User is OUT of start way point of spot.');
		Result := -2;
		Exit();

	end;
	}
	
	// Define startSpotPoint
	if ((p_StarSpotIndex > -1) and (p_StarSpotIndex < high(pWayPoints^))) then
	begin
		if (pWayPoints^[p_StarSpotIndex].spotId = p_spotId) AND (pWayPoints^[p_StarSpotIndex].PointType = START_SPOT) then
			startSpotPoint := pWayPoints^[p_StarSpotIndex]
		else
		begin
			bNeedToGoToNextSpot := true;
			Result := -1;
		end;
	end;	
		
	// TODO: may be add max seconds on spot into path file?
	// TODO: may be add spot range into path file?

	
	// Check that the user is on the start point of spot
	if (User.InRange(startSpotPoint.X, startSpotPoint.Y, startSpotPoint.Z, spotRange) and not bNeedToGoToNextSpot) then
	begin
		// On the start point of Spot
		bNeedToGoToNextSpot := false;
		secondsOnSpot := 0;
		Print('User is on START SPOT. Start farming...');		
		Engine.Facecontrol(0, True);
		
		while (User.InRange(startSpotPoint.X, startSpotPoint.Y, startSpotPoint.Z, spotRange) and (not bNeedToGoToNextSpot)) do 
		begin  
			Delay(1000); // Always 1 second
			
			// TODO: perform some char checks here, if they are not performed in threads
			GoHomeIfDead();
			// TODO: buffs
			{
			if (not User.Buffs.ByID(13515,Obj) or (Obj.EndTime<30000)) then 
			begin // ИД бафа поменяй
				buff:=true;
				break;
			end;
			}
			
			// Check other players/GMs on spot.
			bIsOtherPlayerDetected := IsOtherPlayerOnSpot(spotRange);
			if (bIsOtherPlayerDetected) then
				Result := -2;
			
			// Update spot conditions:
			Inc(secondsOnSpot);
			bNeedToGoToNextSpot := (secondsOnSpot > p_MaxSecondsOnSpot) or bIsOtherPlayerDetected;
			//Print('seconds on spot: ' + String(secondsOnSpot));
		end;	

		// Need to come back to the start point of sport to continue moving throw the path
		if (User.InRange(startSpotPoint.X, startSpotPoint.Y, startSpotPoint.Z, spotRange)) then
			if (RndMoveTo(startSpotPoint.X, startSpotPoint.Y, startSpotPoint.Z)) then
				RndDelay(1000);
	end else
	begin
		Print('User is OUT of START SPOT point.');
		Result := -1;
	end;
			
	Engine.Facecontrol(0, false);
	Print('Finished farming on current spot.');	
	
	Result := 0;
end;


// ------------------------------------
// Main body
begin
	Print('Start script.');
	RndDelay(1500);

	// Try to init vars
	if (InitializeLocalVariables() = -1) then
	begin
		Print('Cannot initialize character.');
		Exit();
	end;
	
	if (GoHomeIfDead() > -1) then 
	begin
		//TODO: check if user in town then go to gk
		// MoveToGK();

		// TODO: need to know how much hunting zones the character has already visited.
		// Need to save into special log the list of these zones.
		// Need to select the next hunting zone where the char is in Town.
			
		// Check if user in the hunting zone then start farming
		// Init successfully, start boting process
		// List of checks in threads
		// Script.NewThread(@Neurotic_Clicks_Thread(40));    
		// Script.NewThread(@CheckCharIsLocked()); 
		// Script.NewThread(@CheckCharIsDebuffed()); 	
		FarmMobsInHuntingZone();
	end;
	//until Engine.Status = lsOffline;
	
end.
  