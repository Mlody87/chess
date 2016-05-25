unit partia;

{$mode objfpc}{$H+}
//                                           007|19|biale|E4|cos|cos



interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, types, StrUtils, Unit2;

type

 TKolorowanieRuchu=record
    ok:boolean;
    Z:TPoint;
    NA:TPoint;
  end;

  TKolorowanieKrola=record   //np przy szachu
    ok:boolean;
    pole:TPoint;
  end;

  TDaneBoard=record
    pole:string;
    KolorPola:string;
    X:integer;
    Y:integer;
  end;


  TBierka = class(TObject)
    public
      pole:string;
      kolor:string;
      rodzaj:string;
      obraz:TPortableNetworkGraphic;
      pozycja:TPoint;
  end;

  TRuch = record
     figura:string;
     kolor:string;
     Z:string;
     NA:string;
     uwagi:string;
   end;

  TWPrzelocie = record
     ok:boolean;
     Z:string;
     NA:string;
     bite:string;
  end;

  TMapaRuchow=array of string;

  TBoard=array[1..8,1..8] of TBierka;

  TTablicaPunktow=array of TPoint;

  { TForm3 }

  TForm3 = class(TForm)
    ECzasBiale: TEdit;
    ECzasCzarne: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    PaintBox1: TPaintBox;
    TimerCzasBiale: TTimer;
    TimerCzasCzarne: TTimer;
    Przebieg: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1Paint(Sender: TObject);
    function ZnajdzIJbyPole(pole:string):TPoint;
    function SprawdzKrola(pole:TPoint; na:string):boolean;
    function MozliweRuchy(WyjsciowePole:string):TMapaRuchow;
    function CzyLegalnyRuch(NaPole:string):boolean;
    function ZapiszRuch(Z,Na,rodzaj,kolor,Uwagi:string):boolean;
    function OdswiezPrzebieg:boolean;
    function WykonajRuch(Z,Na,Uwagi:string):boolean;
    function CzySieRuszal(polozenie:TPoint):boolean;   //do roszady
    function CzyCosAtakujePole(pozycja,rodzaj,MojKolor:string;szachownica:Pointer):boolean;//do roszady
    function CzyMat(kolor:string):boolean;  //do mata
    function CzyKrolMaGdzieUciec(K:TPoint):boolean;
    function CzyCosBroniPole(pozycja,rodzaj,MojKolor:string;szachownica:Pointer):boolean;
    function KtoAtakujePole(p:TPoint; szachownica:Pointer):TTablicaPunktow;
    function CzyMoznaZaslonic(atakowany,atakujacy:TPoint):boolean;
    function CzyCosStanieNaPolu(pozycja,MojKolor:string;szachownica:Pointer):boolean; //zasloniecie przed matem
    function CzyPat(ruch:string):boolean;
    function ZostalTylkoKrol(kolor:string):boolean;
    function CzyRemis:boolean;

  private
    { private declarations }
      GramKolorem:string;
    BialeCzas:integer;
    CzarneCzas:integer;
    KogoRuch:string;
    start:boolean;
    id_partii:integer;
    
    Board : TBoard;
  DaneBoard : array[1..8,1..8] of TDaneBoard;

  DAD:boolean;
  DadBierka:^TBierka;

  PunktPlansza,PolePlansza:TPoint;

  KogoRuch:string;
  MozliweWPrzelocie:TWPrzelocie;

  KolorowanieRuchu:TKolorowanieRuchu;
  KolorowanieKrola:TKolorowanieKrola;

  TablicaRuchow:TMapaRuchow; //lista dozwolonych ruchow na planszy dla bierki

  PrzebiegPartii:array of TRuch; //lista ruchow podczas partii


  Board : array[1..8,1..8] of TBierka;
  DaneBoard : array[1..8,1..8] of TDaneBoard;

  DAD:boolean;
  DadBierka:^TBierka;

  PunktPlansza,PolePlansza:TPoint;
  public
    { public declarations }
    procedure PrzekazDaneNaStart(linia:string);
    procedure komunikat(kom:string);
    procedure PokazForme;
  end;

  CONST

  POLA : array[1..8,1..8] of string =
    (('A8','B8','C8','D8','E8','F8','G8','H8'),
    ('A7','B7','C7','D7','E7','F7','G7','H7'),
    ('A6','B6','C6','D6','E6','F6','G6','H6'),
    ('A5','B5','C5','D5','E5','F5','G5','H5'),
    ('A4','B4','C4','D4','E4','F4','G4','H4'),
    ('A3','B3','C3','D3','E3','F3','G3','H3'),
    ('A2','B2','C2','D2','E2','F2','G2','H2'),
    ('A1','B1','C1','D1','E1','F1','G1','H1'));

  OBRAZYFIGUR : array[1..18] of string =
    ('PionBialy.png','WiezaBiala.png','SkoczekBialy.png','GoniecBialy.png','HetmanBialy.png','KrolBialy.png','GoniecBialy.png','SkoczekBialy.png','WiezaBiala.png',
     'PionCzarny.png','WiezaCzarna.png','SkoczekCzarny.png','GoniecCzarny.png','HetmanCzarny.png','KrolCzarny.png','GoniecCzarny.png','SkoczekCzarny.png','WiezaCzarna.png');

  FIGURY : array[1..9] of string =
    ('pion','wieza','skoczek','goniec','hetman','krol','goniec','skoczek','wieza');



var
  Form3: TForm3;

implementation

{$R *.lfm}
uses unit1;

{ ---- pomocnicze -----}

function ZnajdzXYbyPole(poz:string):TPoint;
var
  i,j:integer;
  punkt:TPoint;
begin

for i:=1 to 8 do
    for j:=1 to 8 do
    begin
     if DaneBoard[i,j].pole=poz then
      begin
           punkt:=Point(DaneBoard[i,j].X, DaneBoard[i,j].Y);
           Result:=punkt;
           Break;
      end;
    end;
end;

function ZnajdzPolebyXY(X,Y:integer):string;
var
  a,b:integer;
begin

a:=(X div 80)+1;
b:=(Y div 80)+1;

Result:=DaneBoard[b,a].pole;
end;

function ZnajdzXYbyIJ(i,j:integer):TPoint;
begin
Result:=Point(DaneBoard[i,j].X, DaneBoard[i,j].Y);
end;

function TForm1.ZnajdzIJbyPole(pole:string):TPoint;
var
i,j:integer;
begin

for i:=1 to 8 do
for j:=1 to 8 do
  if DaneBoard[i,j].pole=pole then Result:=Point(i,j);

end;

{---------}

procedure TForm3.FormCreate(Sender: TObject);
var
  i,j,a,NumerPola,obraz:integer;
  kolor:string;
begin

//  GramKolorem := 'biale';

end;

function TForm1.WykonajRuch(Z,Na,Uwagi:string):boolean;
var
a,b:TPoint;
begin
a:=ZnajdzIJbyPole(Z);
b:=ZnajdzIJbyPole(Na);

if Board[b.x,b.y]<>nil then
 FreeAndNil(Board[b.x,b.y]);

Board[b.x,b.y]:=Board[a.x,a.y];

Board[b.x,b.y].pole:=Na;
Board[b.x,b.y].pozycja := ZnajdzXYbyPole(Na);

Board[a.x,a.y]:=nil;

KolorowanieRuchu.ok:=true;
KolorowanieRuchu.Z:=ZnajdzIJbyPole(Z);
KolorowanieRuchu.NA:=ZnajdzIJbyPole(Na);

PaintBox1.Invalidate;

end;

function TForm1.OdswiezPrzebieg:boolean;
var
i,j,licznik:integer;
s:string;
begin
//for i:=0 to Przebieg.RowCount-1 do
//Przebieg.Rows[i].Clear;

licznik:=0;

for i:=0 to Length(PrzebiegPartii)-1 do
begin
//dodajemy ruch jezeli biale
    if PrzebiegPartii[i].kolor='biale' then
    begin
         s:='';
    Przebieg.RowCount:=licznik+1;
    Przebieg.Cells[0,licznik]:=IntToStr(licznik+1);
    if PrzebiegPartii[i].figura<>'pion' then s:=UpperCase(LeftStr(PrzebiegPartii[i].figura, 1));
    Przebieg.Cells[1,licznik]:=s+''+PrzebiegPartii[i].Z+''+PrzebiegPartii[i].Na;
    end;
//dodajemy ruch jak czarne
    if PrzebiegPartii[i].kolor='czarne' then
    begin
    s:='';
    if PrzebiegPartii[i].figura<>'pion' then s:=UpperCase(LeftStr(PrzebiegPartii[i].figura, 1));
    Przebieg.Cells[2,licznik]:=s+''+PrzebiegPartii[i].Z+''+PrzebiegPartii[i].Na;
    licznik:=licznik+1;
    end;
end;

end;

function TForm1.ZapiszRuch(Z,Na,rodzaj,kolor,Uwagi:string):boolean;
begin

SetLength(PrzebiegPartii, Length(PrzebiegPartii)+1);
PrzebiegPartii[High(PrzebiegPartii)].kolor:=kolor;
if (Z='E1')and(Na='G1')and(rodzaj='krol')then    //jezeli krotka roszada bialych
begin
    PrzebiegPartii[High(PrzebiegPartii)].figura:='';
    PrzebiegPartii[High(PrzebiegPartii)].Z:='O-O';
    PrzebiegPartii[High(PrzebiegPartii)].NA:='';
end
else
begin
     if (Z='E1')and(Na='C1')and(rodzaj='krol')then    //jezeli dluga roszada bialych
     begin
          PrzebiegPartii[High(PrzebiegPartii)].figura:='';
          PrzebiegPartii[High(PrzebiegPartii)].Z:='O-O-O';
          PrzebiegPartii[High(PrzebiegPartii)].NA:='';
     end
     else
     begin
          if (Z='E8')and(Na='G8')and(rodzaj='krol') then    //jezeli krotka roszada czarnych
          begin
                   PrzebiegPartii[High(PrzebiegPartii)].figura:='';
                   PrzebiegPartii[High(PrzebiegPartii)].Z:='O-O';
                   PrzebiegPartii[High(PrzebiegPartii)].NA:='';
          end
          else
          begin
               if (Z='E8')and(Na='C8')and(rodzaj='krol') then    //jezeli dluga roszada czarnych
               begin
                       PrzebiegPartii[High(PrzebiegPartii)].figura:='';
                       PrzebiegPartii[High(PrzebiegPartii)].Z:='O-O-O';
                       PrzebiegPartii[High(PrzebiegPartii)].NA:='';
               end
               else
               begin
                       PrzebiegPartii[High(PrzebiegPartii)].figura:=rodzaj;
                       PrzebiegPartii[High(PrzebiegPartii)].Z:=Z;
                       PrzebiegPartii[High(PrzebiegPartii)].NA:=Na;
               end;
          end;
     end;
end;
PrzebiegPartii[High(PrzebiegPartii)].uwagi:=Uwagi;

OdswiezPrzebieg;

result:=true;

end;

function TForm1.CzyLegalnyRuch(NaPole:string):boolean;
var
i:integer;
ok:boolean;
begin
ok:=false;

for i:=0 to Length(TablicaRuchow)-1 do
    if NaPole = TablicaRuchow[i] then ok:=true;

Result:=ok;
end;

function TForm1.MozliweRuchy(WyjsciowePole:string):TMapaRuchow;
var
ruchy:TMapaRuchow;
pole:TPoint;
i,j:integer;
kolor,bierka:string;
tmp,tmp2,tmp3,PozycjaKrola:TPoint;
tmpBoard:TBoard;
begin

pole:=ZnajdzIJbyPole(WyjsciowePole);
kolor:=Board[pole.X, pole.Y].kolor;
bierka:=Board[pole.X, pole.Y].rodzaj;

for i:=1 to 8 do
for j:=1 to 8 do
  if Board[i,j]<>nil then begin if (Board[i,j].rodzaj='krol') and (Board[i,j].kolor=kolor) then PozycjaKrola:=Point(i,j); end;


{SPRAWDZAMY MOZLIWE RUCHY DLA WIEZY}

if bierka = 'wieza' then
 begin

      for i:=1 to 8 do {na prawo do bierki}
         begin

               if pole.Y+i<=8 then
                begin
                     if Board[pole.X, pole.Y+i]=nil then
                      begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X,pole.y+i]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                           end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+i].kolor = kolor then begin Break; end
                           else
                            begin
                            tmpBoard:=Board;
                            tmpBoard[pole.X,pole.y+i]:=tmpBoard[pole.X,pole.Y];
                            tmpBoard[pole.X,pole.Y]:=nil;
                            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                             begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                            end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {na lewo do bierki}
         begin


               if pole.Y-i>=1 then
                begin
                     if Board[pole.X, pole.Y-i]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X,pole.y-i]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-i].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X,pole.y-i]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {do gory bierki}
         begin


               if pole.X+i<=8 then
                begin
                     if Board[pole.X+i, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X+i,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X+i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X+i,pole.y]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {w dol bierki}
         begin

               if pole.X-i>=1 then
                begin
                     if Board[pole.X-i, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X-i,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X-i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X-i,pole.y]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

      Result:=ruchy;

 end;

{SPRAWDZAMY MOZLIWE RUCHY DLA PIONA}   //bedzie sprawdzanie tylko dla gracza na dole    !!!
                                       //ale teraz musi byc tez dla czarnych!!!!!!!
if bierka = 'pion' then
 begin
      {sprawdzamy ruch piona}

     // if KogoRuch='biale' then
      if KogoRuch=GramKolorem then
       begin

            if Board[pole.X-1, pole.Y]=nil then
            begin

                tmpBoard:=Board;
                tmpBoard[pole.X-1,pole.y]:=tmpBoard[pole.X,pole.Y];
                tmpBoard[pole.X,pole.Y]:=nil;
                if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                 begin
                SetLength(ruchy, Length(ruchy)+1);
                ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
                end;
            end;

            if pole.X=7 then  //pierwszy ruch, mozna o dwa, sprawdzamy
            begin

                       if Board[pole.X-2, pole.Y]=nil then
                       begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X-2,pole.y]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y].pole;
                           end;
                       end;

            end;

       {sprawdzamy bicie piona}
            if (pole.X-1>=1) and (pole.Y-1>=1) then    //bicie w lewo
            begin
                if Board[pole.X-1, pole.Y-1]<>nil then
                begin
                    if Board[pole.X-1, pole.Y-1].kolor<>kolor then
                    begin
                        tmpBoard:=Board;
                        tmpBoard[pole.X-1,pole.y-1]:=tmpBoard[pole.X,pole.Y];
                        tmpBoard[pole.X,pole.Y]:=nil;
                        if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                         begin
                        SetLength(ruchy, Length(ruchy)+1);
                        ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
                        end;
                    end;
                end;
            end;
       end;

     if (pole.X-1>=1) and (pole.Y+1<=8) then    //bicie w prawo
     begin
         if Board[pole.X-1, pole.Y+1]<>nil then
         begin
             if Board[pole.X-1, pole.Y+1].kolor<>kolor then
             begin
                 tmpBoard:=Board;
                 tmpBoard[pole.X-1,pole.y+1]:=tmpBoard[pole.X,pole.Y];
                 tmpBoard[pole.X,pole.Y]:=nil;
                 if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                  begin
                 SetLength(ruchy, Length(ruchy)+1);
                 ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
                 end;
             end;
         end;
     end;

     {-- bicie w przelocie dla dolu bialych --}

     if (DaneBoard[pole.X,pole.Y].pole = 'A5') or
        (DaneBoard[pole.X,pole.Y].pole = 'B5') or
        (DaneBoard[pole.X,pole.Y].pole = 'C5') or
        (DaneBoard[pole.X,pole.Y].pole = 'D5') or
        (DaneBoard[pole.X,pole.Y].pole = 'E5') or
        (DaneBoard[pole.X,pole.Y].pole = 'F5') or
        (DaneBoard[pole.X,pole.Y].pole = 'G5') or
        (DaneBoard[pole.X,pole.Y].pole = 'H5') then
        begin
           if (DaneBoard[pole.X,pole.Y].pole = 'A5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='B7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='B5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                 tmpBoard:=Board;
                 tmp:=ZnajdzIJbyPole('A5');
                 tmp2:=ZnajdzIJbyPole('B6');
                 tmp3:=ZnajdzIJbyPole('B5');
                 tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                 tmpBoard[tmp.X,tmp.Y]:=nil;
                 tmpBoard[tmp3.x,tmp3.y]:=nil;
                 if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                  begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='B6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='B5';
                  MozliweWPrzelocie.Z:='A5';
                  MozliweWPrzelocie.Na:='B6';
                  end;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'H5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='G7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='G5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('H5');
                     tmp2:=ZnajdzIJbyPole('G6');
                     tmp3:=ZnajdzIJbyPole('G5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='G6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='G5';
                  MozliweWPrzelocie.Z:='H5';
                  MozliweWPrzelocie.Na:='G6';
                  end;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'B5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='A7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='A5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('B5');
                     tmp2:=ZnajdzIJbyPole('A6');
                     tmp3:=ZnajdzIJbyPole('A5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='A6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='A5';
                  MozliweWPrzelocie.Z:='B5';
                  MozliweWPrzelocie.Na:='A6';
                  END;
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='C7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='C5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('B5');
                     tmp2:=ZnajdzIJbyPole('C6');
                     tmp3:=ZnajdzIJbyPole('C5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='C6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='C5';
                  MozliweWPrzelocie.Z:='B5';
                  MozliweWPrzelocie.Na:='C6';
                  END;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'C5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='B7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='B5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('C5');
                     tmp2:=ZnajdzIJbyPole('B6');
                     tmp3:=ZnajdzIJbyPole('B5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='B6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='B5';
                  MozliweWPrzelocie.Z:='C5';
                  MozliweWPrzelocie.Na:='B6';
                  END;
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='D7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='D5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('C5');
                     tmp2:=ZnajdzIJbyPole('D6');
                     tmp3:=ZnajdzIJbyPole('D5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='D6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='D5';
                  MozliweWPrzelocie.Z:='C5';
                  MozliweWPrzelocie.Na:='D6';
                  END;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'D5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='C7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='C5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('D5');
                     tmp2:=ZnajdzIJbyPole('C6');
                     tmp3:=ZnajdzIJbyPole('C5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='C6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='C5';
                  MozliweWPrzelocie.Z:='D5';
                  MozliweWPrzelocie.Na:='C6';
                  END;
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='E7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='E5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('D5');
                     tmp2:=ZnajdzIJbyPole('E6');
                     tmp3:=ZnajdzIJbyPole('E5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='E6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='E5';
                  MozliweWPrzelocie.Z:='D5';
                  MozliweWPrzelocie.Na:='E6';
                  END;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'E5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='D7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='D5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('E5');
                     tmp2:=ZnajdzIJbyPole('D6');
                     tmp3:=ZnajdzIJbyPole('D5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='D6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='D5';
                  MozliweWPrzelocie.Z:='E5';
                  MozliweWPrzelocie.Na:='D6';
                  END;
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='F7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='F5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('E5');
                     tmp2:=ZnajdzIJbyPole('F6');
                     tmp3:=ZnajdzIJbyPole('F5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='F6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='F5';
                  MozliweWPrzelocie.Z:='E5';
                  MozliweWPrzelocie.Na:='F6';
                  END;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'F5') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='E7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='E5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('F5');
                     tmp2:=ZnajdzIJbyPole('E6');
                     tmp3:=ZnajdzIJbyPole('E5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='E6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='E5';
                  MozliweWPrzelocie.Z:='F5';
                  MozliweWPrzelocie.Na:='E6';
                  END;
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='G7') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='G5') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('F5');
                     tmp2:=ZnajdzIJbyPole('G6');
                     tmp3:=ZnajdzIJbyPole('G5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='G6';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='G5';
                  MozliweWPrzelocie.Z:='F5';
                  MozliweWPrzelocie.Na:='G6';
                  END;
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'G5') then
                         begin
                            if (PrzebiegPartii[High(PrzebiegPartii)].Z='F7') and
                               (PrzebiegPartii[High(PrzebiegPartii)].NA='F5') and
                               (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                            begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('G5');
                     tmp2:=ZnajdzIJbyPole('F6');
                     tmp3:=ZnajdzIJbyPole('F5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                             SetLength(ruchy, Length(ruchy)+1);
                             ruchy[High(ruchy)]:='F6';
                             MozliweWPrzelocie.ok:=true;
                             MozliweWPrzelocie.bite:='F5';
                             MozliweWPrzelocie.Z:='G5';
                             MozliweWPrzelocie.Na:='F6';
                             END;
                            end;
                            if (PrzebiegPartii[High(PrzebiegPartii)].Z='H7') and
                               (PrzebiegPartii[High(PrzebiegPartii)].NA='H5') and
                               (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                            begin
                     tmpBoard:=Board;
                     tmp:=ZnajdzIJbyPole('G5');
                     tmp2:=ZnajdzIJbyPole('H6');
                     tmp3:=ZnajdzIJbyPole('H5');
                     tmpBoard[tmp2.X-1,tmp2.y+1]:=tmpBoard[tmp.X,tmp.Y];
                     tmpBoard[tmp.X,tmp.Y]:=nil;
                     tmpBoard[tmp3.x,tmp3.y]:=nil;
                     if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                      begin
                             SetLength(ruchy, Length(ruchy)+1);
                             ruchy[High(ruchy)]:='H6';
                             MozliweWPrzelocie.ok:=true;
                             MozliweWPrzelocie.bite:='H5';
                             MozliweWPrzelocie.Z:='G5';
                             MozliweWPrzelocie.Na:='H6';
                             END;
                            end;

                         end;

        end;

     {-- konczymy sprawdzanie bicie w przelocie dla dolu bialych--}
     
{SPRAWDZAMY MOZLIWE RUCHY DLA GONCA}

if bierka = 'goniec' then
begin

   for i:=1 to 8 do    {w lewy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y-i)<1) then Break;

      if Board[pole.X-i, pole.Y-i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X-i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
          end;
      end
      else
      begin
         if Board[pole.X-i, pole.Y-i].kolor=kolor then begin Break; end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X-i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y+i)>8) then Break;

      if Board[pole.X-i, pole.Y+i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X-i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
          end;
      end
      else
      begin
         if Board[pole.X-i, pole.Y+i].kolor=kolor then begin Break; end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X-i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w lewy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y-i)<1) then Break;

      if Board[pole.X+i, pole.Y-i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
          end;
      end
      else
      begin
         if Board[pole.X+i, pole.Y-i].kolor=kolor then begin Break end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X+i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y+i)>8) then Break;

      if Board[pole.X+i, pole.Y+i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
          end;
      end
      else
      begin
         if Board[pole.X+i, pole.Y+i].kolor=kolor then begin Break end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X+i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
         end;
              Break;
         end;
      end;

   end;

   result:=ruchy;

end;

{SPRAWDZAMY MOZLIWE RUCHY DLA SKOCZKA}

if bierka = 'skoczek' then
begin

    if ((pole.X+1<=8) and (pole.Y+2<=8)) then
    begin
        if Board[pole.X+1, pole.Y+2]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X+1,pole.y+2]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+2].pole;
            end;
        end
        else
        begin
           if Board[pole.X+1, pole.Y+2].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X+1,pole.y+2]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+2].pole;
               end;
           end;
        end;
    end;


    if ((pole.X-1>=1) and (pole.Y-2>=1)) then
    begin
        if Board[pole.X-1, pole.Y-2]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X-1,pole.y-2]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-2].pole;
            end;
        end
        else
        begin
           if Board[pole.X-1, pole.Y-2].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X-1,pole.y-2]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-2].pole;
               end;
           end;
        end;
    end;


    if ((pole.X+2<=8) and (pole.Y+1<=8)) then
    begin
        if Board[pole.X+2, pole.Y+1]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X+2,pole.y+1]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y+1].pole;
            end;
        end
        else
        begin
           if Board[pole.X+2, pole.Y+1].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X+2,pole.y+1]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y+1].pole;
               end;
           end;
        end;
    end;


    if ((pole.X-2>=1) and (pole.Y+1<=8)) then
    begin
        if Board[pole.X-2, pole.Y+1]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X-2,pole.y+1]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y+1].pole;
            end;
        end
        else
        begin
           if Board[pole.X-2, pole.Y+1].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X-2,pole.y+1]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y+1].pole;
               end;
           end;
        end;
    end;


    if ((pole.X+1<=8) and (pole.Y-2>=1)) then
    begin
        if Board[pole.X+1, pole.Y-2]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X+1,pole.y-2]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-2].pole;
            end;
        end
        else
        begin
           if Board[pole.X+1, pole.Y-2].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X+1,pole.y-2]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-2].pole;
               end;
           end;
        end;
    end;


    if ((pole.X-1>=1) and (pole.Y+2<=8)) then
    begin
        if Board[pole.X-1, pole.Y+2]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X-1,pole.y+2]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+2].pole;
            end;
        end
        else
        begin
           if Board[pole.X-1, pole.Y+2].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X-1,pole.y+2]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+2].pole;
               end;
           end;
        end;
    end;


    if ((pole.X+2<=8) and (pole.Y-1>=1)) then
    begin
        if Board[pole.X+2, pole.Y-1]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X+2,pole.y-1]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y-1].pole;
            end;
        end
        else
        begin
           if Board[pole.X+2, pole.Y-1].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X+2,pole.y-1]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y-1].pole;
               end;
           end;
        end;
    end;


    if ((pole.X-2>=1) and (pole.Y-1>=1))then
    begin
        if Board[pole.X-2, pole.Y-1]=nil then
        begin
            tmpBoard:=Board;
            tmpBoard[pole.X-2,pole.y-1]:=tmpBoard[pole.X,pole.Y];
            tmpBoard[pole.X,pole.Y]:=nil;
            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
             begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y-1].pole;
            end;
        end
        else
        begin
           if Board[pole.X-2, pole.Y-1].kolor<>kolor then
           begin
               tmpBoard:=Board;
               tmpBoard[pole.X-2,pole.y-1]:=tmpBoard[pole.X,pole.Y];
               tmpBoard[pole.X,pole.Y]:=nil;
               if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y-1].pole;
               end;
           end;
        end;
    end;

 result:=ruchy;

end;

{SPRAWDZAMY MOZLIWE RUCHY DLA HETMANA}

if bierka = 'hetman' then
begin

 {ruchy gonca - po skosie}

   for i:=1 to 8 do    {w lewy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y-i)<1) then Break;

      if Board[pole.X-i, pole.Y-i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X-i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
          end;
      end
      else
      begin
         if Board[pole.X-i, pole.Y-i].kolor=kolor then begin Break; end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X-i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y+i)>8) then Break;

      if Board[pole.X-i, pole.Y+i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X-i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
          end;
      end
      else
      begin
         if Board[pole.X-i, pole.Y+i].kolor=kolor then begin Break; end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X-i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w lewy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y-i)<1) then Break;

      if Board[pole.X+i, pole.Y-i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
          end;
      end
      else
      begin
         if Board[pole.X+i, pole.Y-i].kolor=kolor then begin Break end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X+i,pole.y-i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
         end;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y+i)>8) then Break;

      if Board[pole.X+i, pole.Y+i]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
          end;
      end
      else
      begin
         if Board[pole.X+i, pole.Y+i].kolor=kolor then begin Break end
         else
         begin
         tmpBoard:=Board;
         tmpBoard[pole.X+i,pole.y+i]:=tmpBoard[pole.X,pole.Y];
         tmpBoard[pole.X,pole.Y]:=nil;
         if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
          begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
         end;
              Break;
         end;
      end;

      end;

 {-----------------------}

 {-- ruchy wiezy - poziomo pionowo --}

 for i:=1 to 8 do {na prawo do bierki}
         begin

               if pole.Y+i<=8 then
                begin
                     if Board[pole.X, pole.Y+i]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X,pole.y+i]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+i].kolor = kolor then begin Break; end
                           else
                            begin
                            tmpBoard:=Board;
                            tmpBoard[pole.X,pole.y+i]:=tmpBoard[pole.X,pole.Y];
                            tmpBoard[pole.X,pole.Y]:=nil;
                            if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                             begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                            end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {na lewo do bierki}
         begin


               if pole.Y-i>=1 then
                begin
                     if Board[pole.X, pole.Y-i]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X,pole.y-i]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-i].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X,pole.y-i]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {do gory bierki}
         begin


               if pole.X+i<=8 then
                begin
                     if Board[pole.X+i, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X+i,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X+i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X+i,pole.y]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

      for i:=1 to 8 do {w dol bierki}
         begin

               if pole.X-i>=1 then
                begin
                     if Board[pole.X-i, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X-i,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X-i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                           tmpBoard:=Board;
                           tmpBoard[pole.X-i,pole.y]:=tmpBoard[pole.X,pole.Y];
                           tmpBoard[pole.X,pole.Y]:=nil;
                           if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',kolor,@tmpBoard)=false then
                            begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                           end;
                              Break;
                            end;
                     end;
                end;
         end;

 {------------------------}

 result:=ruchy;

   end;

{SPRAWDZAMY MOZLIWE RUCHY DLA KROLA}

if bierka = 'krol' then
 begin

  {-- ruchy wiezy - pionowo poziomo --}

               if pole.Y+1<=8 then
                begin
                     if Board[pole.X, pole.Y+1]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X,pole.y+1]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[pole.X,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+1].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+1].kolor <> kolor then
                            begin
                                tmpBoard:=Board;
                                tmpBoard[pole.X,pole.y+1]:=tmpBoard[pole.X,pole.Y];
                                tmpBoard[pole.X,pole.Y]:=nil;
                                if CzyCosAtakujePole(DaneBoard[pole.X,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
                                 begin
                                SetLength(ruchy, Length(ruchy)+1);
                                ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+1].pole;
                                end;
                            end;
                     end;
                end;


               if pole.Y-1>=1 then
                begin
                     if Board[pole.X, pole.Y-1]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X,pole.y-1]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[pole.X,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-1].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-1].kolor <> kolor then
                           begin
                               tmpBoard:=Board;
                               tmpBoard[pole.X,pole.y-1]:=tmpBoard[pole.X,pole.Y];
                               tmpBoard[pole.X,pole.Y]:=nil;
                               if CzyCosAtakujePole(DaneBoard[pole.X,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
                                begin
                               SetLength(ruchy, Length(ruchy)+1);
                               ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-1].pole;
                               end;
                            end;
                     end;
                end;


               if pole.X+1<=8 then
                begin
                     if Board[pole.X+1, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X+1,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X+1, pole.Y].kolor <> kolor then
                           begin
                               tmpBoard:=Board;
                               tmpBoard[pole.X+1,pole.y]:=tmpBoard[pole.X,pole.Y];
                               tmpBoard[pole.X,pole.Y]:=nil;
                               if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y].pole,'ruch',kolor,@tmpBoard)=false then
                                begin
                               SetLength(ruchy, Length(ruchy)+1);
                               ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y].pole;
                               end;
                            end;
                     end;
                end;



               if pole.X-1>=1 then
                begin
                     if Board[pole.X-1, pole.Y]=nil then
                      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X-1,pole.y]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
                          end;
                      end
                     else
                     begin
                           if Board[pole.X-1, pole.Y].kolor <> kolor then
                           begin
                               tmpBoard:=Board;
                               tmpBoard[pole.X-1,pole.y]:=tmpBoard[pole.X,pole.Y];
                               tmpBoard[pole.X,pole.Y]:=nil;
                               if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y].pole,'ruch',kolor,@tmpBoard)=false then
                                begin
                               SetLength(ruchy, Length(ruchy)+1);
                               ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
                               end;
                            end;
                     end;
                end;

  {-----------------------------------}

  {-- ruchy gonca - po skosie --}


      if ((pole.X-1)>=1) and ((pole.Y-1)>=1) then begin

      if Board[pole.X-1, pole.Y-1]=nil then
      begin
                          tmpBoard:=Board;
                          tmpBoard[pole.X-1,pole.y-1]:=tmpBoard[pole.X,pole.Y];
                          tmpBoard[pole.X,pole.Y]:=nil;
                          if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
                           begin
                          SetLength(ruchy, Length(ruchy)+1);
                          ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
                          end;
      end
      else
      begin
         if Board[pole.X-1, pole.Y-1].kolor<>kolor then
         begin
             tmpBoard:=Board;
             tmpBoard[pole.X-1,pole.y-1]:=tmpBoard[pole.X,pole.Y];
             tmpBoard[pole.X,pole.Y]:=nil;
             if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
              begin
             SetLength(ruchy, Length(ruchy)+1);
             ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
             end;
         end;
      end;
      end;


      if ((pole.X-1)>=1) and ((pole.Y+1)<=8) then begin

      if Board[pole.X-1, pole.Y+1]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X-1,pole.y+1]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
          end;
      end
      else
      begin
         if Board[pole.X-1, pole.Y+1].kolor<>kolor then
         begin
             tmpBoard:=Board;
             tmpBoard[pole.X-1,pole.y+1]:=tmpBoard[pole.X,pole.Y];
             tmpBoard[pole.X,pole.Y]:=nil;
             if CzyCosAtakujePole(DaneBoard[pole.X-1,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
              begin
             SetLength(ruchy, Length(ruchy)+1);
             ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
             end;
         end;
      end;

   end;


      if ((pole.X+1)<=8) and ((pole.Y-1)>=1) then
      begin

      if Board[pole.X+1, pole.Y-1]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+1,pole.y-1]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-1].pole;
          end;
      end
      else
      begin
         if Board[pole.X+1, pole.Y-1].kolor<>kolor then
         begin
             tmpBoard:=Board;
             tmpBoard[pole.X+1,pole.y-1]:=tmpBoard[pole.X,pole.Y];
             tmpBoard[pole.X,pole.Y]:=nil;
             if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y-1].pole,'ruch',kolor,@tmpBoard)=false then
              begin
             SetLength(ruchy, Length(ruchy)+1);
             ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-1].pole;
             end;
         end;
      end;

        end;


      if ((pole.X+1)<=8) and ((pole.Y+1)<=8) then begin

      if Board[pole.X+1, pole.Y+1]=nil then
      begin
          tmpBoard:=Board;
          tmpBoard[pole.X+1,pole.y+1]:=tmpBoard[pole.X,pole.Y];
          tmpBoard[pole.X,pole.Y]:=nil;
          if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
           begin
          SetLength(ruchy, Length(ruchy)+1);
          ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+1].pole;
          end;
      end
      else
      begin
         if Board[pole.X+1, pole.Y+1].kolor<>kolor then
         begin
             tmpBoard:=Board;
             tmpBoard[pole.X+1,pole.y+1]:=tmpBoard[pole.X,pole.Y];
             tmpBoard[pole.X,pole.Y]:=nil;
             if CzyCosAtakujePole(DaneBoard[pole.X+1,pole.Y+1].pole,'ruch',kolor,@tmpBoard)=false then
              begin
             SetLength(ruchy, Length(ruchy)+1);
             ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+1].pole;
             end;
         end;
      end;

   end;

  {-----------------------------------}

  {-- sprawdzamy roszade --}

  if (WyjsciowePole='E1') or (WyjsciowePole='E8') then
  begin

        if WyjsciowePole='E1' then //BIALE
        begin
             //najpierw sprawdzamy czy sie krol ruszal

              if CzySieRuszal(pole)=false then //jezeli krol sie nie ruszal to sprawdzamy dalej
              begin

                   tmp:=ZnajdzIJbyPole('H1');
                   if (Board[tmp.x,tmp.y]<>nil) and (Board[tmp.x,tmp.y].rodzaj='wieza') and (Board[tmp.x,tmp.y].kolor=kolor) then
                   begin

                   if CzySieRuszal(ZnajdzIJbyPole('H1'))=false then //jezeli wieza krotka sie nie ruszala
                   begin
                      tmp:=ZnajdzIjbyPole('F1');
                      tmp2:=ZnajdzIJbyPole('G1');
                    if (Board[tmp.X,tmp.Y]=nil) and (Board[tmp2.X,tmp2.Y]=nil) then
                    begin
                        if (CzyCosAtakujePole('F1','roszada',GramKolorem,@Board)=false) and (CzyCosAtakujePole('G1', 'roszada', GramKolorem, @Board)=false) then
                        begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:='G1';
                        end;
                    end;

                   end;

                   end;

                   tmp:=ZnajdzIJbyPole('A1');
                   if (Board[tmp.x,tmp.y]<>nil) and (Board[tmp.x,tmp.y].rodzaj='wieza') and (Board[tmp.x,tmp.y].kolor=kolor) then
                   begin

                   if CzySieRuszal(ZnajdzIJbyPole('A1'))=false then //jezeli wieza dluga sie nie ruszala
                   begin

                   tmp:=ZnajdzIjbyPole('D1');
                   tmp2:=ZnajdzIJbyPole('C1');
                    if (Board[tmp.X,tmp.Y]=nil) and (Board[tmp2.X,tmp2.Y]=nil) then
                    begin
                        if (CzyCosAtakujePole('D1','roszada', GramKolorem,@Board)=false) and (CzyCosAtakujePole('C1', 'roszada', GramKolorem, @Board)=false) then
                        begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:='C1';
                        end;
                    end;

                   end;
                   end;
              end;


        end;

        {konczymy sprawdzanie roszady dla bialych}

      if DaneBoard[pole.X, pole.Y].pole='E8' then //CZARNE
      begin
           //najpierw sprawdzamy czy sie krol ruszal

            if CzySieRuszal(pole)=false then //jezeli krol sie nie ruszal to sprawdzamy dalej
            begin

                   tmp:=ZnajdzIJbyPole('H8');
                   if (Board[tmp.x,tmp.y]<>nil) and (Board[tmp.x,tmp.y].rodzaj='wieza') and (Board[tmp.x,tmp.y].kolor=kolor) then
                   begin

                 if CzySieRuszal(ZnajdzIJbyPole('H8'))=false then //jezeli wieza krotka sie nie ruszala
                 begin
                    tmp:=ZnajdzIjbyPole('F8');
                    tmp2:=ZnajdzIJbyPole('G8');
                  if (Board[tmp.X,tmp.Y]=nil) and (Board[tmp2.X,tmp2.Y]=nil) then
                  begin
                      if (CzyCosAtakujePole('F8','roszada', GramKolorem, @Board)=false) and (CzyCosAtakujePole('G8', 'roszada', GramKolorem, @Board)=false) then
                      begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:='G8';
                      end;
                  end;
                  end;

                 end;


                   tmp:=ZnajdzIJbyPole('A8');
                   if (Board[tmp.x,tmp.y]<>nil) and (Board[tmp.x,tmp.y].rodzaj='wieza') and (Board[tmp.x,tmp.y].kolor=kolor) then
                   begin
                 if CzySieRuszal(ZnajdzIJbyPole('A8'))=false then //jezeli wieza dluga sie nie ruszala
                 begin

                 tmp:=ZnajdzIjbyPole('D8');
                 tmp2:=ZnajdzIJbyPole('C8');
                  if (Board[tmp.X,tmp.Y]=nil) and (Board[tmp2.X,tmp2.Y]=nil) then
                  begin
                      if (CzyCosAtakujePole('D8','roszada', GramKolorem, @Board)=false) and (CzyCosAtakujePole('C8', 'roszada', GramKolorem, @Board)=false) then
                      begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:='C8';
                      end;
                  end;
                  end;

                 end;
            end;


      end;

{---}



  end;

  {------------------------}

    result:=ruchy;
  end;

 end;     


{--------------------------------------------------------------------------}

procedure TForm3.PokazForme;
begin
 Self.Show;
end;

procedure TForm3.komunikat(kom:string);
begin

end;


procedure TForm3.PrzekazDaneNaStart(linia:string);
var
    odczyt:TStrings;
      i,j,a,NumerPola,obraz:integer;
  kolor:string;
begin
 odczyt:=TStringList.Create;
 ExtractStrings(['|'], [], PAnsiChar(linia), odczyt);

 if odczyt[4] = 'GraszBialymi' then GramKolorem:='biale' else GramKolorem:='czarne';
 BialeCzas:=StrToInt(odczyt[5]);
 CzarneCzas:=StrToInt(odczyt[5]);

 id_partii:=odczyt[1];

 KogoRuch:='biale';
 start:=false;

 ECzasBiale.Text:=odczyt[5];
 ECzasCzarne.Text:=odczyt[5];

 if GramKolorem='biale' then
begin
    for i:=1 to 8 do
        for j:=1 to 8 do
            begin
               DaneBoard[i,j].pole:=POLA[i,j];
               DaneBoard[i,j].X:=(j-1)*80;
               DaneBoard[i,j].Y:=(i-1)*80;
            end;
end
else
begin
     for i:=1 to 8 do
         for j:=1 to 8 do
            begin
              DaneBoard[i,j].pole:=POLA[9-i,9-j];
              DaneBoard[i,j].X:=(j-1)*80;
              DaneBoard[i,j].Y:=(i-1)*80;
            end;
end;

  if GramKolorem='biale' then
  begin
   kolor:='czarne';
   obraz:=10;
  end
  else
  begin
    kolor:='biale';
    obraz:=1;
  end;


         for i:=1 to 2 do
             for j:=1 to 8 do
             begin
                if i=1 then  {ustawiamy figury}
                begin
                  Board[i,j]:=TBierka.Create;
                  Board[i,j].pole:=DaneBoard[i,j].pole;
                  Board[i,j].kolor:=kolor;
                  Board[i,j].rodzaj:=FIGURY[j+1];
                  Board[i,j].obraz:=TPortableNetworkGraphic.Create;
                  Board[i,j].obraz.LoadFromFile('img/'+OBRAZYFIGUR[obraz+j]);
                  Board[i,j].obraz.Width:=70;
                  Board[i,j].obraz.Height:=70;
                  //Board[i,j].pozycja:=ZnajdzXY(Board[i,j].pole);
                  Board[i,j].pozycja:=Point(DaneBoard[i,j].X, DaneBoard[i,j].Y);
                end
                else
                begin
                   for a:=1 to 8 do    {ustawiamy piony}
                   begin
                  Board[i,a]:=TBierka.Create;
                  Board[i,a].pole:=DaneBoard[i,a].pole;
                  Board[i,a].kolor:=kolor;
                  Board[i,a].rodzaj:='pion';
                  Board[i,a].obraz:=TPortableNetworkGraphic.Create;
                  Board[i,a].obraz.LoadFromFile('img/'+OBRAZYFIGUR[obraz]);
                  Board[i,a].obraz.Width:=70;
                  Board[i,a].obraz.Height:=70;
                 // Board[i,a].pozycja:=ZnajdzXY(Board[i,a].pole);
                  Board[i,a].pozycja:=Point(DaneBoard[i,a].X, DaneBoard[i,a].Y);
                   end;
                end;
             end;

if kolor='biale' then
begin
kolor:='czarne';
obraz:=10;
end
else
begin
kolor:='biale';
obraz:=1;
end;

         for i:=7 to 8 do
             for j:=1 to 8 do
             begin
                if i=8 then  {ustawiamy figury u gory}
                begin
                  Board[i,j]:=TBierka.Create;
                  Board[i,j].pole:=DaneBoard[i,j].pole;
                  Board[i,j].kolor:=kolor;
                  Board[i,j].rodzaj:=FIGURY[j+1];
                  Board[i,j].obraz:=TPortableNetworkGraphic.Create;
                  Board[i,j].obraz.LoadFromFile('img/'+OBRAZYFIGUR[obraz+j]);
                  Board[i,j].obraz.Width:=70;
                  Board[i,j].obraz.Height:=70;
                //  Board[i,j].pozycja:=ZnajdzXY(Board[i,j].pole);
                  Board[i,j].pozycja:=Point(DaneBoard[i,j].X, DaneBoard[i,j].Y);
                end
                else
                begin
                   for a:=1 to 8 do    {ustawiamy piony u gory}
                   begin
                  Board[i,a]:=TBierka.Create;
                  Board[i,a].pole:=DaneBoard[i,a].pole;
                  Board[i,a].kolor:=kolor;
                  Board[i,a].rodzaj:='pion';
                  Board[i,a].obraz:=TPortableNetworkGraphic.Create;
                  Board[i,a].obraz.LoadFromFile('img/'+OBRAZYFIGUR[obraz]);
                  Board[i,a].obraz.Width:=70;
                  Board[i,a].obraz.Height:=70;
             //     Board[i,a].pozycja:=ZnajdzXY(Board[i,a].pole);
                  Board[i,a].pozycja:=Point(DaneBoard[i,a].X, DaneBoard[i,a].Y);
                   end;
                end;
             end;
         PaintBox1.Enabled:=True;

end;

end.
