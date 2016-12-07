unit UserConfig;

interface

uses SysUtils, Classes;

// General constants
const m_scriptsPath: string = 'Scripts/la_selbstfahren/'; 
const m_wayPointsPath: string = 'Scripts/la_selbstfahren/paths/';
const m_configPath: string = m_scriptsPath + 'config/';

const m_maxSecondsOnspot: integer = 25;
const m_defaultSpotRange: integer = 1600;
const m_maxCountOfFailedSpots: integer = 3; // count of failed spots in a row
const m_maxLoopsOnHuntingZone: integer = 2;
const m_maxSecondsNotInCombat: integer = 4;

// TODO: move all these pathes into config files:
// deagleee	
// const m_userConfig: string = 'deaglee';
// const m_HuntingZonePath: string = m_wayPointsPath + 'HuntingDeaglee_Lake_15';	
	
// Hwel	
// const m_userConfig: string = 'Hwel';
// const m_HuntingZonePath: string =  m_wayPointsPath + 'HuntingHwel_Mithryl_15';	

// Weatherwax	
// const m_userConfig: string = 'Weatherwax';
// const m_HuntingZonePath: string =  m_wayPointsPath + 'HuntingWeatherwax_startLoc_10';	

// GythaOgg	
// const m_userConfig: string = 'GythaOgg';
// const m_HuntingZonePath: string = m_wayPointsPath + 'HuntingGythaOgg_StartLoc_8';
// const m_HuntingZonePath: string = m_wayPointsPath + 'HuntingGythaOgg_StartLoc_10';

type
TUserConfig = packed record
	UserName: string;
	IsDead: boolean;
	CurrentHuntingZone: string;
	MaxSecondsOnspot: integer;
	SpotRange: integer;
	MaxCountOfFailedSpots: integer;
	MaxLoopsOnHuntingZone: integer;
	MaxSecondsNotInCombat: integer;
	EquippedWeaponID: integer;
	// TODO: add an array of available hunting zones for current user 
end;

function LoadUserConfig(p_UserName: string): TUserConfig;

implementation

function LoadUserConfig(p_UserName: string): TUserConfig;
var
	userState: TUserConfig;
	fileName, split: string;
	i, count: integer;
	stringList : TStringList;
	splittedString : TStringList;
begin
	Print('LoadUserConfig: ' + p_UserName);

	// Init userState with default values:
	with userState do
	begin
		UserName := p_UserName;
		IsDead := false;
		CurrentHuntingZone := '';
		MaxSecondsOnspot := m_maxSecondsOnspot;
		SpotRange := m_defaultSpotRange;
		MaxCountOfFailedSpots := m_maxCountOfFailedSpots;
		MaxLoopsOnHuntingZone := m_maxLoopsOnHuntingZone;
		MaxSecondsNotInCombat := m_maxSecondsNotInCombat;
		EquippedWeaponID := -1;
	end;
	
	Result := userState;
	
	stringList := TStringList.Create;
	fileName := './' + m_configPath +p_UserName + '.csv';
	Print('ReadFile: '+ fileName);
	
	if FileExists(fileName) then
	begin
		stringList.LoadFromFile(fileName);
	end
	else begin
		Print('Cannot find file for user config: ' + fileName);
		exit();
	end;		
	
	count := stringList.Count;
	i := 0;
	while (i < count)do
	begin
		splittedString := TStringList.Create;
		splittedString.Delimiter := ',';
		splittedString.DelimitedText := stringList[i];
		//DEBUG: 
		Print(stringlist[i]);

		if (splittedString[0] = 'SPOT_CONFIG') then
		begin
			// TODO: load special variables for current character
			with userState do
			begin
				MaxSecondsOnspot := StrToInt(splittedString[1]);
				SpotRange := StrToInt(splittedString[2]);
				MaxCountOfFailedSpots := StrToInt(splittedString[3]);
				MaxLoopsOnHuntingZone := StrToInt(splittedString[4]);
				MaxSecondsNotInCombat := StrToInt(splittedString[5]);
			end;
		end else
		if (splittedString[0] = 'SPOT_NAME') then
		begin
			userState.CurrentHuntingZone := splittedString[3];
		end;

		Inc(i);
		splittedString.Free();
	end;

	Result := userState;
	
	stringList.Free();
end;

end.
