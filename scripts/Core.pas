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


 