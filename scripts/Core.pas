unit Farming;

interface

uses SysUtils, Classes, Moving, UserConfig;

var
	m_userState: TUserConfig; 
	
// Init function. Can be replaced with True Class constructor
function InitializeLocalVariables(): integer;	
// TODO: fix it - it doesn't write log anywhere. Also make sense to write special function to send IM in ICQ
// Print message
function AddMsgToLog(p_strMsg: string): integer;


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
		m_userState := UserConfig.LoadUserConfig(User.Name);
		
		// StartLogSession(m_userState);
		
		// TODO: load some special variables for current character
		with m_userState do
		begin
			IsDead := (User.HP = 0);
			// CurrentPath: string; it should be changed in Hunting Zone logic
			//EquippedWeaponID : integer;
		end;
		
	end;
end;

function AddMsgToLog(p_strMsg: string): integer;
begin
  Result := 0;
  Print(p_strMsg);
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
	
	// TODO: Load Session_CharNane.csv
	// TODO: define actual activity type
	// If session was not so later:
		//define last activity
			// If current activity is ACT_HUNTING
				// TODO: need to know how much hunting zones the character has already visited and when.
				// Check if user in the hunting zone then start farming
					// FarmMobsInHuntingZone();
				// else - Need to select the next hunting zone where the char is in Town.
			// If current activity is ACT_TRADING
				// TODO: implement trading module 
		
	// else create a new session. file...
		// Use char activity priorities to define what to do next.
		// When defined, start with first activity.
		
	// Continue session until any of stop flags is true.
		// z.b. count of activities for actual session is 10 or total duration of session is 4 hours.
		
	// at the end of session save a copy of last session file.
		// log out or do nothing in town.
	
	if (GoHomeIfDead() > -1) then 
	begin
		//TODO: check if user in town then go to gk
		// MoveToGK();

	end;
	//until Engine.Status = lsOffline;
	
end.


 