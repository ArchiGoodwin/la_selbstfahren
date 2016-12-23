unit DetectAnomaly;

interface

uses SysUtils, Classes, UserConfig;

var
	// m_logList: TStringList; 
	m_fileStream: TFileStream;
	m_writer: TWriter;
	m_timeStamp : TDateTime;
	m_bSessionStarted: boolean;


function StartLogSession(p_userConfig: TUserConfig): integer;
function ReadLogFile(strFileName: string): integer;
function StopLogSession():integer;
function AddToLog(p_text: string): integer;

implementation

{
function StartLogSession(p_userConfig: TUserConfig): integer;
var
	fileNameLog: string;
	stringList : TStringList;
	timeStamp : TDateTime;
begin
	Result := 0;
	stringList := TStringList.Create;
	timeStamp := Now;
	fileNameLog := './' + p_userConfig.UserName + '_' + FormatDateTime('mm-dd-yy_hh:nn:ss', timeStamp) + '.txt';
	Print('StartLogSession: '+ fileNameLog);
	
	if (NOT FileExists(fileNameLog)) then
	begin
		stringList.Add('######_LOG4_' + p_userConfig.UserName);
		stringList.SaveToFile(FileName);	
		
		stringList.LoadFromFile(fileNameLog);
		Result := 0;
	end
	
	
  try
    if FileExists(FileName) then
      strList.LoadFromFile(FileName);

    strList.Add('My new line');

    strList.SaveToFile(FileName);

	
	stringList.Free();
end;}

function StopLogSession():integer;
begin
	//if (m_fileStream.Size = 0) then 
	if (not m_bSessionStarted) then
	begin
		//if (m_writer.instanceSize() = 0) then
		begin
			//m_writer.WriteListEnd();
			m_writer.Destroy;
		end;
		
		m_fileStream.Destroy;
	end;
end;


function StartLogSession(p_userConfig: TUserConfig): integer;
var
	I: Integer;
	fileNameLog: string;
begin
	Result := 0;
	m_timeStamp := Now;
	fileNameLog := './' + p_userConfig.UserName + '_' + FormatDateTime('mm-dd-yy_hh:nn:ss', m_timeStamp) + '.txt';
	Print('StartLogSession: '+ fileNameLog);
	
	StopLogSession();
	
	m_fileStream := TFileStream.Create(fileNameLog, fmCreate or fmOpenWrite or fmShareDenyNone);
	m_writer := TWriter.Create(m_fileStream, $FF);
	m_writer.WriteListBegin();
	m_bSessionStarted := true;
	m_writer.WriteString('######_LOG4_' + p_userConfig.UserName);
end;


function AddToLog(p_text: string): integer;
begin
	Result := 0;
	
	if (m_bSessionStarted) then
	//if ((m_fileStream <> NULL) and (m_writer <> NULL)) then
	begin
		m_timeStamp := Now;
		m_writer.WriteString(FormatDateTime('hh:nn:ss.zzz', m_timeStamp) + p_text);
	end;
end;


function ReadLogFile(strFileName: string): integer;
var
	fileNameLog: string;
	stringList : TStringList;
	count: Integer;
begin
	stringList := TStringList.Create;
	fileNameLog := './' + strFileName + '.txt';
	Print('ReadLogFile: '+ fileNameLog);
	
	if FileExists(fileNameLog) then
	begin
		stringList.LoadFromFile(fileNameLog);
		Result := 0;
	end
	else begin
	    Result := -1;
		Print('Cannot find file: ' + fileNameLog);
		exit();
	end;

	count := stringList.Count;
	Print('Lines in log loaded: ' + IntToStr(count));

	stringList.Free();
end;

end.
