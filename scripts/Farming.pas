unit Farming;

interface

uses SysUtils, Classes, RegExpr, Moving;

var
	m_isDead: boolean = false;
	m_equippedWeaponID: integer = -1;

// TODO: create a special logic, which will detect the Character name and load appropriate custom config file with next params: 
const m_maxSecondsOnspot: integer = 25;
const m_defaultSpotRange: integer = 1000;
const m_maxCountOfFailedSpots: integer = 3; // count of failed spots in a row
const m_maxLoopsOnHuntingZone: integer = 2;
const m_maxSecondsNotInCombat: integer = 4;
	
// Init function. Can be replaced with True Class constructor
function InitializeLocalVariables(): integer;	
// TODO: fix it - it doesn't write log anywhere. Also make sense to write special function to send IM in ICQ
// Print message
function AddMsgToLog(p_strMsg: string): integer;

// TODO: add function to check captcha
// TODO: add any other functions to check GMs
//function CheckCharDisarmed(): boolean;
// TODO: add check and fix DeBuffs
//function CheckCharDeBuffed(): boolean;
function IsOtherPlayerOnSpot(p_Range: integer): boolean;
// Check agro players:
function IsPvpOrPkAround(p_Range: integer): boolean;
// Check that char is not in combat and make rnd step
function IsNotInCombatTooLong(var p_seconds: integer): boolean;
// Get mobs count in range
function GetMobsCountInRange(p_Range: integer = 1000): integer;
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
		//Gps.LoadBase(exepath+'\qpath.db3');  
	end;
end;

function AddMsgToLog(p_strMsg: string): integer;
begin
  Result := 0;
  Print(p_strMsg);
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
				Print('Character hasnt been moving during 30 seconds!');
				// Character is locked
				// engine.gameclose;
			end;
		end;
	end;
end;

function check_trains(mobs_count: integer = 5; R: integer = 1500; info_print: boolean = false): boolean;   // Функция, проверяющая паровозы вокруг перса в радиусе R и возвращающая true, если мобов больше чем mobs_count. info_print - распатывать инфу о паровозе или нет
var i, j, mobs_in_train: integer;
begin
  Result:= false;
  for i:= 0 to charlist.count-1 do begin
    mobs_in_train:= 0;
    if (user.distto(charlist.items(i)) < R*1.5) and (charlist.items(i).moved) then begin
      for j:= 0 to npclist.count-1 do begin
        if (npclist.items(j).target = charlist.items(i)) and (charlist.items(i).distto(npclist.items(j)) < R) then inc(mobs_in_train);
        if (mobs_in_train >= mobs_count) then begin
          Result:= true;
          if (info_print) then print('Замечен паровоз из '+inttostr(mobs_in_train)+' мобов, бегут за '+charlist.items(i).name);
          exit;
        end;
      end;
    end;
  end;
end;

function GetMobsCountInRange(p_Range: integer = 1000): integer;
var 
	i, countMobs: integer;
begin
	Result := 0;
	countMobs := 0;
	
	for i:= 0 to npclist.count-1 do
	begin
		if ((user.distto(npclist.items(i)) < p_Range) and (abs(user.z - npclist.items(i).z) < 250) and (npclist.items(i).hp > 0)) then                 
			Inc(countMobs);
	end;
	
	Print('GetMobsCountInRange: ' + IntToStr(countMobs));
			
	Result := countMobs;
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

function IsPvpOrPkAround(p_Range: integer): boolean;
var i: integer;
begin
	Result:=false;
	for i:=0 to CharList.Count-1 do
		begin
		if ((CharList.Items(i).Inzone) and (not CharList.Items(i).Dead) and (Abs(CharList.Items(i).z-User.z)<1000) and (CharList.Items(i).target = user)) then
			if CharList.Items(i).Pvp or CharList.Items(i).PK then 
			begin 
			print('This character: '+CharList.Items(i).name+' is trying to kill me!');
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

function IsNotInCombatTooLong(var p_seconds: integer): boolean;
begin
	// Check if user is not in combat during last 8 seconds
	if ((NOT User.Moved) AND (User.Cast.EndTime = 0) AND ((User.Target = nil) or (User.Target.Dead))) then
	begin	
		Inc(p_seconds);
		if (p_seconds mod 2 = 0) then //rnd step each 3 seconds
		begin
			RndDelay(50);
			RndMoveTo(User.X, User.Y, User.Z);
			Print('IsNotInCombatTooLong: seconds ' + IntToStr(p_seconds));
		end
	end else
		p_seconds := 0;
	
	Result := p_seconds > m_maxSecondsNotInCombat;
end;

function FarmMobsInHuntingZone(): integer;
var
	spotId, countSpot, index, countFailedSpots, countZoneLoops: integer;
	bCanToGoToNextSpot: boolean;
	fileNameWayPoints: string;
	wayPoints : TRecordPointArray;
begin
	Print('FarmMobsInHuntingZone');
	
	Result := 0;
	RndDelay(500);
	bCanToGoToNextSpot := true;
	countFailedSpots := 0;
	countZoneLoops := 0;
	
	// Load wayPoints from file for hunting zone
	// File should be created independently in RecordPath unit for any of hunting zone.
	fileNameWayPoints := m_HuntingZonePath;
	
	countSpot := ReadWayPointsFile(fileNameWayPoints, @wayPoints);
    if (countSpot < 1) then
	begin
		Print('No wayPoints loaded from file.');
		Exit();
	end; 
	Print('FarmMobsInHuntingZone: Count of loaded spots: ' + IntToStr(countSpot));
	
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
					Print('FarmMobsInHuntingZone: Was failed to achieve nearest START SPOT point.');
					Exit();
				end else
				begin
					// 4. Farm On current START SPOT point.
					if (FarmOnSpot(@wayPoints, spotId, m_maxSecondsOnspot, index) < 0) then
					begin
						Print('FarmMobsInHuntingZone: Something wrong with last spot. Cannot continue to farm on this spot.');
						// Add here a counter of failed spots in current hunting zone. Can use it to halt.
						Inc(countFailedSpots);
						if (countFailedSpots > m_maxCountOfFailedSpots) then 
							bCanToGoToNextSpot := false;
					end
					else begin
						Print('FarmMobsInHuntingZone: Farming on last spot was completed.');
					end;
					
					Inc(spotId);
				
					// Ended up with all spots in hunting zone
					if (bCanToGoToNextSpot AND (spotId >= countSpot)) then
					begin
						// Check if loops are allowed on hunting zone - reset zone spot Id
						Inc(countZoneLoops);
						if (countZoneLoops < m_maxLoopsOnHuntingZone) then
						begin
							spotId := wayPoints[0].SpotId;
							Print('FarmMobsInHuntingZone: completed ' + IntToStr(countZoneLoops) + ' loop of ' + IntToStr(m_maxLoopsOnHuntingZone));
						end;
					end;
				end
			end;
		end else
		begin
			Print('FarmMobsInHuntingZone: No any way point has been found near user.');
			bCanToGoToNextSpot := false;
		end;
	end;
	
	Print('FarmMobsInHuntingZone: Farm in current hunting zone is COMPLETED.');
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
	
	while ((index <= high(pWayPoints^)) and (NOT isPointFound)) do
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
	secondsOnSpot, secondsNotInCombat: integer;
	bNeedToGoToNextSpot, bIsOtherPlayerDetected, bIsNotInCombatTooLong, bIsInCombat, bIsNoMobsAround: boolean;
	spotRange : integer;
	startSpotPoint: TRecordPoint;
begin
	Print('FarmOnSpot(spotId: '+IntToStr(p_spotId)+'; max seconds on spot: '+IntToStr(p_MaxSecondsOnSpot));
	
	Result := 0;
	bNeedToGoToNextSpot := false;
	spotRange := m_defaultSpotRange;
	
	// Define startSpotPoint
	if ((p_StarSpotIndex > -1) and (p_StarSpotIndex <= high(pWayPoints^))) then
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
		secondsNotInCombat := 0;
		Print('User is on START SPOT. Start farming...');		
		Engine.Facecontrol(0, True);
		
		while (User.InRange(startSpotPoint.X, startSpotPoint.Y, startSpotPoint.Z, spotRange) and (not bNeedToGoToNextSpot)) do 
		begin  
			Delay(1000); // Always 1 second
			
			// TODO: perform some char checks here, if they are not performed in threads
			GoHomeIfDead();
			{
			if (not User.Buffs.ByID(13515,Obj) or (Obj.EndTime<30000)) then 
			begin // ИД бафа поменяй
				buff:=true;
				break;
			end;
			}
			
			// Check if user is not in combat too long and ther is no any mobs 
			bIsNotInCombatTooLong := IsNotInCombatTooLong(secondsNotInCombat);
			bIsNoMobsAround := (GetMobsCountInRange(spotRange) = 0);
			
			// Check other players/GMs on spot.
			bIsOtherPlayerDetected := IsOtherPlayerOnSpot(spotRange) or IsPvpOrPkAround(spotRange);
			if (bIsOtherPlayerDetected) then
				Result := -2;
				
			bIsInCombat := (not User.Cast.EndTime = 0) or not ((User.Target = nil) or (User.Target.Dead));	
			
			// Update spot conditions:
			Inc(secondsOnSpot);
			
			// Self hill:
			if (not bIsInCombat and bIsNoMobsAround and (User.hp < 200)) then
			begin
				Print('User hp is slow. Need to have a rest for 20 seconds.');
				Engine.Facecontrol(0, false);
				RndDelay(20000);
				Engine.Facecontrol(0, True);
			end;	
			
			bNeedToGoToNextSpot := not bIsInCombat and ((secondsOnSpot > p_MaxSecondsOnSpot) or bIsOtherPlayerDetected or bIsNoMobsAround);
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
		// Script.NewThread(@CheckCharIsLocked()); 
		// Script.NewThread(@CheckCharIsDebuffed()); 	
		FarmMobsInHuntingZone();
	end;
	//until Engine.Status = lsOffline;
	
end.
  