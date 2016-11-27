Unit RecordPath;

interface

uses SysUtils, Classes, Moving;

// GythaOgg	
const m_HuntingZonePath: string = 'Scripts/deaglee_/scripts/HuntingGythaOgg_StartLoc_1';

// Functions declaration
function SaveWayPointsFile(strFileName: string; wayPoints: PRecordPointArray): integer;
function RecordWayPoints(p: pointer): integer;

implementation

function SaveWayPointsFile(strFileName: string; wayPoints: PRecordPointArray): integer;
var
	FileName: string;
	i: Integer;
	stringList: TStringList;
	wayPoint: TRecordPoint;
begin
	FileName := './' + strFileName + '.txt';
	stringList := TStringList.Create;
	Print('SaveWayPointsFile: '+ FileName);
	
	for i := 0 to Length(wayPoints^)-1 do
	begin
		wayPoint := wayPoints^[i];
		stringList.Add(IntToStr(wayPoint.SpotId)+','+IntToStr(Ord(wayPoint.PointType))+','+IntToStr(wayPoint.x)+','+IntToStr(wayPoint.y)+','+IntToStr(wayPoint.z));
	end;

	stringList.SaveToFile(FileName);
	// TODO:
	//	stringList.Free();
	Result := i;
	Print('Points count: ' + IntToStr(i));
end;

function RecordWayPoints(p: pointer): integer;
var
   wayPoints : TRecordPointArray;
   FileName : string;
   PointLast, PointNew : PPoint;
   recordPointFirst, recordPointSecond: TRecordPoint;
   spotId, index, secondsOnPoint : Integer;
   pointType : TPointType;
begin
	FileName := 'Scripts/deaglee_/scripts/HuntingGythaOgg_StartLoc_1';
	New(PointLast);
	New(PointNew);
	PointLast.X := 0;
	PointLast.Y := 0;
	PointLast.Z := 0;
	pointType := START_WAY;
	spotId := 0;
	secondsOnPoint := 0;

	if (ReadWayPointsFile(FileName, @wayPoints) <= 0) then
	begin
		SetLength(wayPoints, 256);
		index := 0;
	end else
	begin
		index := High(wayPoints);
		SetLength(wayPoints, index + 256);
		spotId := wayPoints[index].SpotId + 1;
		Inc(index);
	end;
   
	while Engine.Status = lsOnline do
	begin
		delay(500);

		PointNew.X := User.ToX;
		PointNew.Y := User.ToY;   
		PointNew.Z := User.ToZ;   
		if (PointNew.X <> PointLast.X) or (PointNew.Y <> PointLast.Y) or (PointNew.Z <> PointLast.Z)  then
		begin
			secondsOnPoint := 0;
			// Parameter _type
			// 0 - means start point of way
			// 1 - means way point
			// 2 - means start point of spot
			// x,y,z,_type,_toSpotNo
							{
			if pointType = WAY_POINT then	
			if Length(wayPoints) > 0 then
				wayPoints.Delete(wayPoints.Count - 1);
											   }
			recordPointFirst.X := PointNew.X;
			recordPointFirst.Y := PointNew.Y;
			recordPointFirst.Z := PointNew.Z;
			recordPointFirst.PointType := pointType;
			recordPointFirst.SpotId := spotId;
			wayPoints[index] := recordPointFirst;
			Print('Point: ' + IntToStr(recordPointFirst.X) +',' + IntToStr(recordPointFirst.Y) +','+IntToStr(recordPointFirst.Z));
			Inc(index);

			//	Always add the last poit to START_SPOT 
			recordPointFirst.PointType := START_SPOT;
			wayPoints[index] := recordPointFirst;
			//Inc(index);

			if pointType = START_WAY then		
				pointType := WAY_POINT;

			PointLast.X := PointNew.X;
			PointLast.Y := PointNew.Y;
			PointLast.Z := PointNew.Z;

			if (index > 256) then
				break;
		end else
		begin
			Inc(secondsOnPoint);
			If (secondsOnPoint >= 10) then // 1 secondsOnPoint == 500ms
				break;
		end;	
	end;
	
	SetLength(wayPoints, index+1);	
	SaveWayPointsFile(FileName, @wayPoints);
	//Dispose(PointLast);
	//Dispose(PointNew);
end;

begin
	Print('RecordPath script started.');
	
	// Algorithm is next
	// 1. Load character in start point - tp point og current Grounds
	// 2. Need to record N start points of ways to N start points of farm spots
	// 3. After that it should be possible to load from file all data about waypoints
	Script.NewThread(@RecordWayPoints);
end.





