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
function RndDMoveTo(p_X, p_Y, p_Z: integer): integer;
function RndMoveTo(p_X, p_Y, p_Z: integer): boolean;
// Random delay - can be configured by changing const m_intRndDelay
function RndDelay(p_Milliseconds: integer): boolean;
function FindNearestWayPoint(pWayPoints: PRecordPointArray; p_searchRange: integer; p_spotId: integer): integer;
// TODO: check how it works
function Bypass(dlg: string): boolean;
// TODO:
function Teleport(): integer;   

// When in town, move to the GK. From the point of respauning.
function MoveToGK(): integer;


implementation

function RndDMoveTo(p_X, p_Y, p_Z: integer): integer;
begin
  Result := 0;
  Engine.DMoveTo(p_X+random(2*m_intRndMove)-m_intRndMove, p_Y+random(2*m_intRndMove)-m_intRndMove, p_Z);
  RndDelay(4000);
end;

function RndMoveTo(p_X, p_Y, p_Z: integer): boolean;
begin
  Result := (Engine.MoveTo(p_X+random(2*m_intRndMove)-m_intRndMove, p_Y+random(2*m_intRndMove)-m_intRndMove, p_Z));
end;

function RndDelay(p_Milliseconds: integer): boolean;
begin
	Delay(p_Milliseconds + random(m_intRndDelay));
	Result := true;
end;

function ReadWayPointsFile(strFileName: string; pWayPoints: PRecordPointArray): integer;
var
	fileNameWayPoints, split: string;
	stringList : TStringList;
	i, count, start: Integer;
	RecordPointFirst: TRecordPoint;
	splittedString : TStringList;
begin
	stringList := TStringList.Create;
	fileNameWayPoints := './' + strFileName + '.txt';
	Print('ReadWayPointsFile: '+ fileNameWayPoints);
	
	if FileExists(fileNameWayPoints) then
	begin
		stringList.LoadFromFile(fileNameWayPoints);
		Result := 0;
	end
	else begin
	    Result := -1;
		Print('Cannot find file for hunting zone: ' + fileNameWayPoints);
		exit();
	end;

	count := stringList.Count;
	SetLength(pWayPoints^, count);
	i := 0;
	Print('Points count: ' + IntToStr(count));
	while (i < count)do
	begin
		splittedString := TStringList.Create;
		splittedString.Delimiter := ',';
		splittedString.DelimitedText := stringList[i];
		Print(stringlist[i]);
		//New(RecordPointFirst);
		RecordPointFirst.SpotId := StrToInt(splittedString[0]);
		RecordPointFirst.PointType := TPointType(StrToInt(splittedString[1]));
		RecordPointFirst.X := StrToInt(splittedString[2]);
		RecordPointFirst.Y := StrToInt(splittedString[3]);
		RecordPointFirst.Z := StrToInt(splittedString[4]);
		pWayPoints^[i] := RecordPointFirst;

		Result := RecordPointFirst.SpotId+1; // count of spots
		Inc(i);
		splittedString.Free();
	end;

	stringList.Free();
end;

function FindNearestWayPoint(pWayPoints: PRecordPointArray; p_searchRange: integer; p_spotId: integer): integer;
var
	i, indexPoint, minDistance, curDistance: integer;
	isPointFound: boolean;
begin
	Print('FindNearestWayPoint() spotId: ' + IntToStr(p_spotId));
	Result := -1;
	indexPoint := -1;
	
	if (p_spotId = -1) then // find any way point 
	begin
		minDistance := user.distto(pWayPoints^[0].X, pWayPoints^[0].Y, pWayPoints^[0].Z);
		curDistance := 0;
		indexPoint := 0;
		i := 0;
		isPointFound := false;
		while (i < high(pWayPoints^)) do
		begin
			curDistance := user.distto(pWayPoints^[i].X, pWayPoints^[i].Y, pWayPoints^[i].Z);
			if (curDistance < minDistance) then
			begin
				minDistance := curDistance;
				indexPoint := i;
			end;
			Inc(i);
		end;
		
		if (minDistance > p_searchRange) then
			indexPoint := -1;
	end else
	begin // find the way point for specific Spot Id
		minDistance := -1; // not defined yet
		curDistance := 0;
		i := 0;
		isPointFound := false;
		while (i < high(pWayPoints^)) do
		begin
			if (pWayPoints^[i].SpotId = p_spotId) then 
			begin
				if (minDistance = -1) then
				begin
					minDistance := user.distto(pWayPoints^[i].X, pWayPoints^[i].Y, pWayPoints^[i].Z);
					indexPoint := i;
				end 
				else begin 
					curDistance := user.distto(pWayPoints^[i].X, pWayPoints^[i].Y, pWayPoints^[i].Z);
					if (curDistance < minDistance) then
					begin
						minDistance := curDistance;
						indexPoint := i;
					end;
				end;
			end;
		
			Inc(i);
		end;
		
		if (minDistance > p_searchRange) then
			indexPoint := -1;
	end;
	
	if (indexPoint > -1) then
	begin
		Print('FindNearestWayPoint(): spotID:' + IntToStr(pWayPoints^[indexPoint].spotID) + '; PointType: ' + IntToStr(Ord(pWayPoints^[indexPoint].PointType)));
		Result := indexPoint;
	end;
end;

function Bypass(dlg: string): boolean;
var
  RegExp: TRegExpr;
  SL: TStringList;
  i: integer;
  bps: string;
begin
  Result:= true;                                            // задаем результат по умолчанию
  RegExp:= TRegExpr.Create;                                 // инициализируем объекты для дальнейшей работы
  SL:= TStringList.Create;
  
  RegExp.Expression:= '(<a *(.+?)</a>)|(<button *(.+?)>)';  // задаем регэксп на поиск всех возможных bypass'ов 
  if RegExp.Exec(Engine.DlgText) then                       // если нашлелся нужный шаблон, то
    repeat SL.Add(RegExp.Match[0]);                         // заполняем наш список такими совпадениями
    until (not RegExp.ExecNext);                            // пока не закончатся шаблоны

  for i:= 0 to SL.Count-1 do begin                          // теперь пробегаемся по нашему списку
    if (Pos(dlg, SL[ i ]) > 0) then begin                     // если в i-ой строке нашелся искомый текст, то
      RegExp.Expression:= '"bypass -h *(.+?)"';             // ищем шаблон текста c bypass'ом
      if RegExp.Exec(SL[ i ]) then                            // и если нашли, то копирем из него интересующий нас кусок
        bps:= TrimLeft(Copy(RegExp.Match[0], 12, Length(RegExp.Match[0])-12));
    end;
  end;
  
  Print(bps);                                               // распечатываем конечный вариант bypass'а
  if (Length(bps) > 0) then Engine.BypassToServer(bps);     // если его длина > 0, то отправляем на сервер
  
  RegExp.Free;                                              // не забываем освобождать память
  SL.Free;
end;

// TODO:
function Teleport(): integer;                   
begin
	Result := 0;
   {
	if (user.buffs.byid(1204, buff)) then begin
	 Engine.MSG('Бот','Бегу к ГК' ,7237648);
	If user.inrange(83272, 148008, -3408, 5000) then begin
	engine.settarget('Global GK');
	engine.dlgopen();
	delay(500);
	bypass('Области');
	delay(500);
	bypass('Goddard');
	delay(500);
	bypass('Varka Silenos Strong.');
	delay(5000);
	Engine.MSG('Бот','Я Улетел' ,7237648);
	farm;
	end;
	end;    }
end;

function MoveToGK(): integer; //Координаты респа в городе
begin
	Result := 0;
    RndDelay(500);
	Print('MoveToGK');
	
	// TODO: write for each town its GK coordinates:
	// 
	
	if (User.inrange(11596, 17749, -4611, 100, 100)) then
	begin
		Print('Dark Elf village');
		RndMoveTo(11406, 16929, -4688);
		RndMoveTo(11073, 16045, -4610);
		RndMoveTo(10893, 15833, -4601);
		RndMoveTo(10830, 15602, -4568);
		RndMoveTo(10777, 15482, -4601);
		RndMoveTo(9798, 15714, -4601);
		RndMoveTo(9703, 15566, -4601);
	end;

	if (User.inrange(11191, 15983, -4611, 100, 100)) then
	begin
		Print('Dark Elf village');
		RndMoveTo(11191, 15983, -4611);
		RndMoveTo(10762, 16413, -4601);
		RndMoveTo(10476, 16829, -4611);
		RndMoveTo(10101, 16666, -4601);
		RndMoveTo(9796, 15765, -4601);
		RndMoveTo(9703, 15566, -4601);
	end;
	
	{
    if User.inrange(81376,148095,-3464, 250, 1500) then begin     
       Print('Точка1');
      Engine.MoveTo(81376,148095,-3464);
      Engine.MoveTo(81881,148025,-3467);
      Engine.MoveTo(83027,148020,-3467);
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(82292,149450,-3464, 250, 150) then begin
      Engine.MoveTo(82292,149450,-3464);
      Engine.MoveTo(82865,148876,-3467);
      Engine.MoveTo(83054,148281,-3467);      
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(81562,147782,-3464, 250, 150) then begin
      Engine.MoveTo(81562,147782,-3464);
      Engine.MoveTo(82284,148077,-3467);
      Engine.MoveTo(83077,148159,-3467);      
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(83409,148578,-3400, 250, 150) then begin
      Engine.MoveTo(83409,148578,-3400);
      Engine.MoveTo(83427,148206,-3403);
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(81440,149119,-3464, 250, 150) then begin
      Engine.MoveTo(81440,149119,-3464);
      Engine.MoveTo(82200,149222,-3467);
      Engine.MoveTo(82722,148485,-3467);
      Engine.MoveTo(83087,148101,-3467);     
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(82496,148095,-3464, 250, 150) then begin
      Engine.MoveTo(82496,148095,-3464);
      Engine.MoveTo(83092,148094,-3467);
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(83473,149223,-3400, 250, 150) then begin
      Engine.MoveTo(83473,149223,-3400);
      Engine.MoveTo(83355,148728,-3403);
      Engine.MoveTo(83358,148292,-3403);     
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(82272,147801,-3464, 250, 150) then begin
      Engine.MoveTo(82272,147801,-3464);
      Engine.MoveTo(82565,148080,-3467);
      Engine.MoveTo(83101,148099,-3467);      
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(82480,149087,-3464, 250, 150) then begin
      Engine.MoveTo(82480,149087,-3464);
      Engine.MoveTo(82623,148694,-3467);
      Engine.MoveTo(83087,148157,-3467);      
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(81637,149427,-3464, 250, 150) then begin
      Engine.MoveTo(81637,149427,-3464);
      Engine.MoveTo(82229,149197,-3467);
      Engine.MoveTo(82610,148669,-3467);
      Engine.MoveTo(83088,148170,-3467);
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(81062,148144,-3464, 250, 150) then begin
      Engine.MoveTo(81062,148144,-3464);
      Engine.MoveTo(81574,147997,-3467);
      Engine.MoveTo(82302,147975,-3467);
      Engine.MoveTo(83070,148109,-3467);      
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(83426,148835,-3400, 250, 150) then begin
      Engine.MoveTo(83426,148835,-3400);
      Engine.MoveTo(83422,148276,-3403);     
      Engine.MoveTo(83402,147946,-3403);
    end;
    if User.inrange(81033,148883,-3464, 250, 150) then begin
      Engine.MoveTo(81033,148883,-3464);
      Engine.MoveTo(81769,149191,-3467);
      Engine.MoveTo(82322,149192,-3467);
      Engine.MoveTo(82622,148656,-3467);
      Engine.MoveTo(83079,148163,-3467);     
      Engine.MoveTo(83402,147946,-3403);
    end;
	}
	
	{*
	// TODO: need to ask GK to move somewhere to the input parameter name of location
	// Check the current range 
    if User.inrange(83415,148235,-3400, 250, 150) then begin
      Engine.MoveTo(83415,148235,-3400);      
      Engine.MoveTo(83402,147946,-3403);
       kach;
      end;
         Delay(5000);
 // выделение нпц с ИД указанным в скобках,ид видны справа снизу в боте рядом с именем нпц  
          Engine.SetTarget(35061);
          // открывем диалоговое окно и прожимаем строки ( у нас сначала 2 потом 15)
          Engine.DlgOpen();
          Engine.DlgSel('Профиль');
                   Delay(500);
              Engine.DlgSel('123');    // руины страданий 
                 Delay(5000);
 
     // выделение нпц с ИД указанным в скобках,ид видны справа снизу в боте рядом с именем нпц  
          Engine.SetTarget(30832);
          // открывем диалоговое окно и прожимаем строки ( у нас сначала 2 потом 15)
          Engine.DlgOpen();
          Engine.DlgSel('Спойл зоны');
                   Delay(500);
              Engine.DlgSel(4);    // руины страданий 
                 Delay(5000);
				 }
end;

end.