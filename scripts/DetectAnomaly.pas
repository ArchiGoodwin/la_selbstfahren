unit Moving;

interface

uses SysUtils, Classes, RegExpr;

// Constants - they can be moved to a config file
const m_intRndMove: integer = 60;
const m_intRndDelay: integer = 100;

type
TPoint = packed record
   X: Integer;
   Y: Integer;
   Z: Integer;
end;
PPoint = ^TPoint;

TPointType = (
		START_WAY = 0,
		WAY_POINT = 1,
		START_SPOT = 2
	);
	
TRecordPoint = packed record
	X: Integer;
	Y: Integer;
	Z: Integer;
	PointType: TPointType;
	SpotId: Integer;
end;

TRecordPointArray = array of TRecordPoint;
PRecordPointArray = ^TRecordPointArray;


function ReadWayPointsFile(strFileName: string; pWayPoints: PRecordPointArray): integer;
// Move to the point with a bit rnd range on X and Y coordinates