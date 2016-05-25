unit partia;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, zegar, sqldb, odbcconn, logi;

type
  TrekordGracza = record
    id:string;
    nick:string;
    rank:string;
    zegar:TZegar;
  end;
 
  TPartia= class(TThread)
  private
    A:TrekordGracza;
    B:TrekordGracza;
    id_partii, id_turnieju:string;
    CS:TCriticalSection;
    wiadomosc:string;
    AConnection : TODBCCOnnection;
    ATransaction : TSQLTransaction;
    AQuery:TSQLQuery;
    procedure PolaczZBaza;
  protected
    procedure Execute; override;
  public                                                                                                                             
    constructor Create(Pid_partii:string; Pid_turnieju:string; Pid_A:string; Pid_B:string; PA_rank:string; PB_rank:string; PA_nick:string; PB_nick:string; DlugoscPartii:integer);
    destructor Destroy; override;
    procedure komunikat(msg:string);
  end;

implementation

uses
  ZmienneGlobalne;


constructor TPartia.Create(Pid_partii:string; Pid_turnieju:string; Pid_A:string; Pid_B:string; PA_rank:string; PB_rank:string; PA_nick:string; PB_nick:string; DlugoscPartii:integer);
begin

  inherited Create(false);

  id_partii:=Pid_partii;
  id_turnieju:=Pid_turnieju;

  A.id:=Pid_A;
  A.zegar:=TZegar.Create(DlugoscPartii);
  A.nick:=PA_nick;
  A.rank:=PA_rank;

  B.id:=Pid_B;
  B.zegar:=TZegar.Create(DlugoscPartii);
  B.nick:=PA_nick;
  B.rank:=PA_rank;

  CS:=TCriticalSection.Create;
  wiadomosc:='';

end;

destructor TPartia.Destroy;
begin
  A.zegar.Destroy;
  B.zegar.Destroy;
end;

procedure TPartia.PolaczZBaza;
begin
AConnection:=TODBCCOnnection.Create(nil);
ATransaction:=TSQLTransaction.Create(nil);
AQuery:=TSQLQuery.Create(nil);

with AConnection do
 begin
      Driver := 'MySQL ODBC 5.3 ANSI Driver';
      Params.Add('Trusted_Connection=Yes');
      Params.Add('DATABASE=chess');
      Params.Add('HostName=Mlody-Komputer');
      Params.Add('UserName=root');
      Params.Add('Password=Pawel123#pawel');
 end;

AConnection.Transaction:=ATransaction;
ATransaction.DataBase:=AConnection;
AQuery.DataBase:=AConnection;
end;

procedure TPartia.komunikat(msg:string);
begin
  CS.Enter;
  wiadomosc:=msg;
  CS.Leave;
end;

procedure TPartia.Execute;
var
  KogoRuch:string;
  koniec:boolean;
  linia,query:string;
  odczyt:TStringList;
  loger:TLogi;
begin
  FreeOnTerminate := False;

  loger:=TLogi.Create;

  loger.add('ruszyla partia');

  //wysylam info o rozpoczeciu turnieju za 60 sekund
  
  //tylko w pierwszym komunikacie wysylamy id turnieju
  Clnts[A.id].gniazdo.SendMessage('010|'+id_partii+'|'+id_turnieju+'|ZarazStart|GraszBialymi|'+IntToStr(A.zegar.czas));
  Clnts[B.id].gniazdo.SendMessage('010|'+id_partii+'|'+id_turnieju+'|ZarazStart|GraszCzarnymi|'+IntToStr(B.zegar.czas));
  

  Sleep(60000); //Czekamy minute przed rozpoczeciem partii

  //wysylamy info ze biale zaczynaja
  Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|BialeStart|');
  Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|BialeStart|');

  koniec:=false;
  KogoRuch:='biale';
  A.zegar.wlacz;
  linia:='';
  
  PolaczZBaza;
  repeat
  
  if (A.zegar.czas=0) or (B.zegar.czas=0) then
  begin
    A.zegar.wylacz;
    B.zegar.wylacz;
        
        if A.zegar.czas=0 then
        begin
                Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|KoniecCzasuWygralyCzarne');
                Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|KoniecCzasuWygralyCzarne');
                
                query:='UPDATE partie SET wynik = ''czarne'' WHERE id_partii='+id_partii;
                AConnection.ExecuteDirect(query);
                ATransaction.Commit;
        
        end;
        
        if B.zegar.czas=0 then
        begin
                Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|KoniecCzasuWygralyBiale');
                Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|KoniecCzasuWygralyBiale');
                
                query:='UPDATE partie SET wynik = ''biale'' WHERE id_partii='+id_partii;
                AConnection.ExecuteDirect(query);
                ATransaction.Commit;
        
        end;
  
               query:='UPDATE partie SET przebieg = CONCAT(IFNULL(przebieg,''''), '' Koniec czasu'') WHERE id_partii='+id_partii;
               AConnection.ExecuteDirect(query);
               ATransaction.Commit;
   koniec:=true;
   
  end
  else
  begin

  CS.Enter;
  if wiadomosc<>'' then linia:=wiadomosc;
  CS.Leave;

  if linia<>'' then
  begin
     odczyt:=TStringList.Create;
     ExtractStrings(['|'], [], PChar(linia), odczyt);
     // 'P011|idPartii|gracz|ruch|czas|uwagi'

     if odczyt[2]= 'biale' then
     begin
     
        if odczyt[5] = 'mat' then
        begin
            A.zegar.wylacz;
            B.zegar.wylacz;
            
        odczyt[3]:=odczyt[3]+' +';
        query:='UPDATE partie SET przebieg = CONCAT(IFNULL(przebieg,''''), "' +odczyt[3]+ '") WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        query:='UPDATE partie SET wynik = ''biale'' WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|WygralyBiale');
        Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|WygralyBiale');
        
        koniec:=true;
        
        end
        else
        begin
     
        A.zegar.wylacz;
        Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|ZegarBiale|'+IntToStr(A.zegar.czas)); //info o zegarze bialych
        B.zegar.wlacz;
        Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|RuchBialych|'+odczyt[3]+'|'+IntToStr(A.zegar.czas)); //info dla czarnych o ruchu bialych razem z czasem
        
        query:='UPDATE partie SET przebieg = CONCAT(IFNULL(przebieg,''''), "' +odczyt[3]+ '") WHERE id_partii='+id_partii;
        loger.add(query);
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        komunikat('');
        linia:='';
        
        end;
     end;

     if odczyt[2]= 'czarne' then
     begin
     
        if odczyt[5] = 'mat' then
        begin
            A.zegar.wylacz;
            B.zegar.wylacz;
            
        odczyt[3]:=odczyt[3]+' +';
        query:='UPDATE partie SET przebieg = CONCAT(IFNULL(przebieg,''''), "' +odczyt[3]+ '") WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        query:='UPDATE partie SET wynik = ''czarne'' WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|WygralyCzarne');
        Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|Koniec|WygralyCzarne');
        
        koniec:=true;
        
        end
        else
        begin
     
        B.zegar.wylacz;
        Clnts[B.id].gniazdo.SendMessage('011|'+id_partii+'|ZegarCzarne|'+IntToStr(B.zegar.czas));
        A.zegar.wlacz;
        Clnts[A.id].gniazdo.SendMessage('011|'+id_partii+'|RuchCzarnych|'+odczyt[3]+'|'+IntToStr(B.zegar.czas));

        query := 'UPDATE partie SET przebieg = CONCAT(IFNULL(przebieg,''''), ''' +odczyt[3]+ ''') WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
        
        komunikat('');
        linia:='';
        
        end;
        
     end;
      
  end;
  
  end;

  sleep(50);
  until koniec;

        query:='UPDATE partie SET status = ''zakonczony'' WHERE id_partii='+id_partii;
        AConnection.ExecuteDirect(query);
        ATransaction.Commit;
  
  AConnection.Close;
  AQuery.Free;
  ATransaction.Free;
  AConnection.Free;


end;
  
end.
