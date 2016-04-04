unit logi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs;

type
  TLogi = class
    private
      plik:text;
    public
      procedure add(msg:string);

  end;

implementation
var
  LogiSekcja:TCriticalSection;

procedure TLogi.add(msg:string);
begin
  LogiSekcja.Enter;
  Assign(plik, 'logi.txt');
  Append(plik);
  writeLn(plik, DateTimeToStr(now)+': '+msg);
  close(plik);
  LogiSekcja.Leave;
end;

end.

