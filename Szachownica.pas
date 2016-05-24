unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, types, StrUtils, Unit2;

type

  { TForm1 }

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

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Memo1: TMemo;
    PaintBox1: TPaintBox;
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
  public
    { public declarations }
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
  Form1: TForm1;

  Board : TBoard;
  DaneBoard : array[1..8,1..8] of TDaneBoard;

  GramKolorem:string;

  DAD:boolean;
  DadBierka:^TBierka;

  PunktPlansza,PolePlansza:TPoint;

  KogoRuch:string;
  MozliweWPrzelocie:TWPrzelocie;

  KolorowanieRuchu:TKolorowanieRuchu;
  KolorowanieKrola:TKolorowanieKrola;

  TablicaRuchow:TMapaRuchow; //lista dozwolonych ruchow na planszy dla bierki

  PrzebiegPartii:array of TRuch; //lista ruchow podczas partii

implementation

{$R *.lfm}

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

          {-- bicie w przelocie dla dolu czarnych --}     {ZROBIC SPRAWDZANIE POPRAWNOSCI RUCHU PO BICIU}

     if (DaneBoard[pole.X,pole.Y].pole = 'A4') or
        (DaneBoard[pole.X,pole.Y].pole = 'B4') or
        (DaneBoard[pole.X,pole.Y].pole = 'C4') or
        (DaneBoard[pole.X,pole.Y].pole = 'D4') or
        (DaneBoard[pole.X,pole.Y].pole = 'E4') or
        (DaneBoard[pole.X,pole.Y].pole = 'F4') or
        (DaneBoard[pole.X,pole.Y].pole = 'G4') or
        (DaneBoard[pole.X,pole.Y].pole = 'H4') then
        begin
           if (DaneBoard[pole.X,pole.Y].pole = 'A4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='B2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='B4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='B3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='B4';
                  MozliweWPrzelocie.Z:='A4';
                  MozliweWPrzelocie.Na:='B3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'H4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='G2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='G4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='G3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='G4';
                  MozliweWPrzelocie.Z:='H4';
                  MozliweWPrzelocie.Na:='G3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'B4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='A2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='A4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='A3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='A4';
                  MozliweWPrzelocie.Z:='B4';
                  MozliweWPrzelocie.Na:='A3';
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='C2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='C4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='C3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='C4';
                  MozliweWPrzelocie.Z:='B4';
                  MozliweWPrzelocie.Na:='C3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'C4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='B2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='B4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='B3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='B4';
                  MozliweWPrzelocie.Z:='C4';
                  MozliweWPrzelocie.Na:='B3';
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='D2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='D4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='D3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='D4';
                  MozliweWPrzelocie.Z:='C4';
                  MozliweWPrzelocie.Na:='D3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'D4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='C2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='C4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='C3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='C4';
                  MozliweWPrzelocie.Z:='D4';
                  MozliweWPrzelocie.Na:='C3';
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='E2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='E4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='E3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='E4';
                  MozliweWPrzelocie.Z:='D4';
                  MozliweWPrzelocie.Na:='E3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'E4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='D2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='D4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='D3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='D4';
                  MozliweWPrzelocie.Z:='E4';
                  MozliweWPrzelocie.Na:='D3';
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='F2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='F4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='F3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='F4';
                  MozliweWPrzelocie.Z:='E4';
                  MozliweWPrzelocie.Na:='F3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'F4') then
              begin
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='E2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='E4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='E3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='E4';
                  MozliweWPrzelocie.Z:='F4';
                  MozliweWPrzelocie.Na:='E3';
                 end;
                 if (PrzebiegPartii[High(PrzebiegPartii)].Z='G2') and
                    (PrzebiegPartii[High(PrzebiegPartii)].NA='G4') and
                    (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                 begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:='G3';
                  MozliweWPrzelocie.ok:=true;
                  MozliweWPrzelocie.bite:='G4';
                  MozliweWPrzelocie.Z:='F4';
                  MozliweWPrzelocie.Na:='G3';
                 end;

              end;

           if (DaneBoard[pole.X,pole.Y].pole = 'G4') then
                         begin
                            if (PrzebiegPartii[High(PrzebiegPartii)].Z='F2') and
                               (PrzebiegPartii[High(PrzebiegPartii)].NA='F4') and
                               (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                            begin
                             SetLength(ruchy, Length(ruchy)+1);
                             ruchy[High(ruchy)]:='F3';
                             MozliweWPrzelocie.ok:=true;
                             MozliweWPrzelocie.bite:='F4';
                             MozliweWPrzelocie.Z:='G4';
                             MozliweWPrzelocie.Na:='F3';
                            end;
                            if (PrzebiegPartii[High(PrzebiegPartii)].Z='H2') and
                               (PrzebiegPartii[High(PrzebiegPartii)].NA='H4') and
                               (PrzebiegPartii[High(PrzebiegPartii)].figura='pion') then
                            begin
                             SetLength(ruchy, Length(ruchy)+1);
                             ruchy[High(ruchy)]:='H3';
                             MozliweWPrzelocie.ok:=true;
                             MozliweWPrzelocie.bite:='H4';
                             MozliweWPrzelocie.Z:='G4';
                             MozliweWPrzelocie.Na:='H3';
                            end;

                         end;

        end;


     result:=ruchy;
 end;

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


function TForm1.CzyCosBroniPole(pozycja,rodzaj,MojKolor:string;szachownica:Pointer):boolean;
var
p:TPoint;
i,j:integer;
wynik:boolean;
B:^TBoard;
begin
wynik:=false;
p:=ZnajdzIJbyPole(pozycja);

B:=szachownica;

//sprawdzamy na lewo od pola
   for i:=1 to 8 do
   begin
      if p.Y-i<1 then Break;

      if B^[p.X, p.Y-i]<> nil then
      begin
          if B^[p.X, p.Y-i].kolor = MojKolor then begin
             if (B^[p.X, p.Y-i].rodzaj='wieza') or (B^[p.X, p.Y-i].rodzaj='hetman') then begin wynik:=true; end;
             Break;
      end;
     end;
   end;

   //sprawdzamy na prawo od pola
      for i:=1 to 8 do
      begin
         if p.Y+i>8 then Break;

         if B^[p.X, p.Y+i]<> nil then
         begin
             if B^[p.X, p.Y+i].kolor = MojKolor then begin
                if (B^[p.X, p.Y+i].rodzaj='wieza') or (B^[p.X, p.Y+i].rodzaj='hetman') then begin wynik:=true; Break; end;
                Break;
         end;
       end;
      end;

      //sprawdzamy w gore od pola
         for i:=1 to 8 do
         begin
            if p.X-i<1 then Break;

            if B^[p.X-i, p.Y]<> nil then
            begin
                if B^[p.X-i, p.Y].kolor = MojKolor then begin
                   if (B^[p.X-i, p.Y].rodzaj='wieza') or (B^[p.X-i, p.Y].rodzaj='hetman') then begin wynik:=true; Break; end;
                   Break;
            end;
           end;
         end;

         //sprawdzamy w dol od pola
            for i:=1 to 8 do
            begin
               if p.X+i>8 then Break;

               if B^[p.X+i, p.Y]<> nil then
               begin
                   if B^[p.X+i, p.Y].kolor = MojKolor then begin
                      if (B^[p.X+i, p.Y].rodzaj='wieza') or (B^[p.X+i, p.Y].rodzaj='hetman') then begin wynik:=true; Break; end;
                      Break;
               end;
            end;
            end;

         //sprawdzamy na lewo w gore od pola
            for i:=1 to 8 do
            begin
               if (p.X-i<1) or (p.Y-i<1) then Break;

               if B^[p.X-i, p.Y-i]<> nil then
               begin
                   if B^[p.X-i, p.Y-i].kolor = MojKolor then begin
                      if (B^[p.X-i, p.Y-i].rodzaj='goniec') or (B^[p.X-i, p.Y-i].rodzaj='hetman') then
                      begin wynik:=true; Break; end;
                      Break;
               end;
               end;
            end;

            //sprawdzamy na prawo w gore od pola
               for i:=1 to 8 do
               begin
                  if (p.X-i<1) or (p.Y+i>8) then Break;

                  if B^[p.X-i, p.Y+i]<> nil then
                  begin
                      if B^[p.X-i, p.Y+i].kolor = MojKolor then begin
                         if (B^[p.X-i, p.Y+i].rodzaj='goniec') or (B^[p.X-i, p.Y+i].rodzaj='hetman') then begin wynik:=true; Break; end;
                         Break;
                  end;
                  end;
               end;

               //sprawdzamy na prawo w dol od pola
                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y+i>8) then Break;

                     if B^[p.X+i, p.Y+i]<> nil then
                     begin
                         if B^[p.X+i, p.Y+i].kolor = MojKolor then begin
                            if (B^[p.X+i, p.Y+i].rodzaj='goniec') or (B^[p.X+i, p.Y+i].rodzaj='hetman') then begin wynik:=true; Break; end;
                            Break;
                     end;
                    end;
                  end;

                  //sprawdzamy na lewo w dol od pola

                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y-i<1) then Break;

                     if B^[p.X+i, p.Y-i]<> nil then
                     begin
                         if B^[p.X+i, p.Y-i].kolor = MojKolor then begin
                            if (B^[p.X+i, p.Y-i].rodzaj='goniec') or (B^[p.X+i, p.Y-i].rodzaj='hetman') then begin wynik:=true; Break; end;
                            Break;
                         end;
                  end;
                      end;

//sprawdzamy ataki pionow

if MojKolor=GramKolorem then begin
if (p.X-1>=1) and (p.Y-1>=1) then
begin
   if B^[p.X-1, p.Y-1]<>nil then begin
     if B^[p.X-1, p.Y-1].kolor=MojKolor then
     begin
        if B^[p.x-1, p.Y-1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

if (p.X-1>=1) and (p.Y+1<=8) then
begin
   if B^[p.X-1, p.Y+1]<>nil then begin
     if B^[p.X-1, p.Y+1].kolor=MojKolor then
     begin
        if B^[p.x-1, p.Y+1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

end
else
begin

   if (p.X+1<=8) and (p.Y-1>=1) then
   begin
      if B^[p.X+1, p.Y-1]<>nil then begin
        if B^[p.X+1, p.Y-1].kolor=MojKolor then
        begin
           if B^[p.x+1, p.Y-1].rodzaj='pion' then wynik:=true;
        end;
      end;
   end;

   if (p.X+1<=8) and (p.Y+1<=8) then
   begin
      if B^[p.X+1, p.Y+1]<>nil then begin
        if B^[p.X+1, p.Y+1].kolor=MojKolor then
        begin
           if B^[p.x+1, p.Y+1].rodzaj='pion' then wynik:=true;
        end;
      end;
   end;

end;

//jezeli nie sprawdzamy roszady to sprawdzamy tez ataki konia

if rodzaj<>'roszada' then
begin

//sprawdzamy konie

   if (p.X-2>=1) and (p.Y+1<=8) then begin
if B^[p.X-2,p.Y+1]<>nil then
begin
    if B^[p.X-2,p.Y+1].kolor=MojKolor then
    begin
       if B^[p.X-2,p.Y+1].rodzaj='skoczek' then wynik:=true;
    end;
end;  end;

    if (p.X-1>=1) and (p.Y+2<=8) then begin
 if B^[p.X-1,p.Y+2]<>nil then
 begin
     if B^[p.X-1,p.Y+2].kolor=MojKolor then
     begin
        if B^[p.X-1,p.Y+2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y+2<=8) then begin
 if B^[p.X+1,p.Y+2]<>nil then
 begin
     if B^[p.X+1,p.Y+2].kolor=MojKolor then
     begin
        if B^[p.X+1,p.Y+2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y+1<=8) then begin
 if B^[p.X+2,p.Y+1]<>nil then
 begin
     if B^[p.X+2,p.Y+1].kolor=MojKolor then
     begin
        if B^[p.X+2,p.Y+1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y-1>=1) then begin
 if B^[p.X+2,p.Y-1]<>nil then
 begin
     if B^[p.X+2,p.Y-1].kolor=MojKolor then
     begin
        if B^[p.X+2,p.Y-1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y-2>=1) then begin
 if B^[p.X+1,p.Y-2]<>nil then
 begin
     if B^[p.X+1,p.Y-2].kolor=MojKolor then
     begin
        if B^[p.X+1,p.Y-2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X-1>=1) and (p.Y-2>=1) then begin
 if B^[p.X-1,p.Y-2]<>nil then
 begin
     if B^[p.X-1,p.Y-2].kolor=MojKolor then
     begin
        if B^[p.X-1,p.Y-2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X-2>=1) and (p.Y-1>=1) then begin
 if B^[p.X-2,p.Y-1]<>nil then
 begin
     if B^[p.X-2,p.Y-1].kolor=MojKolor then
     begin
        if B^[p.X-2,p.Y-1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;


end;

//sprawdzamy czy broni krol

if (p.X-1)>=1 then begin
if (B^[p.x-1,p.y]<>nil) then begin
if (B^[p.x-1,p.y].rodzaj='krol') and (B^[p.x-1,p.y].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8) then begin
if (B^[p.x+1,p.y]<>nil) then begin
if (B^[p.x+1,p.y].rodzaj='krol') and (B^[p.x+1,p.y].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.y-1)>=1 then begin
if (B^[p.x,p.y-1]<>nil) then begin
if (B^[p.x,p.y-1].rodzaj='krol') and (B^[p.x,p.y-1].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.y+1)<=8 then begin
if (B^[p.x,p.y+1]<>nil) then begin
if (B^[p.x,p.y+1].rodzaj='krol') and (B^[p.x,p.y+1].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.x-1>=1)and(p.y-1>=1) then begin
if (B^[p.x-1,p.y-1]<>nil) then begin
if (B^[p.x-1,p.y-1].rodzaj='krol') and (B^[p.x-1,p.y-1].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.x-1>=1)and(p.y+1<=8) then begin
if (B^[p.x-1,p.y+1]<>nil) then begin
if (B^[p.x-1,p.y+1].rodzaj='krol') and (B^[p.x-1,p.y+1].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8)and(p.y-1>=1) then begin
if (B^[p.x+1,p.y-1]<>nil) then begin
if (B^[p.x+1,p.y-1].rodzaj='krol') and (B^[p.x+1,p.y-1].kolor=MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8)and(p.y+1<=8) then begin
if (B^[p.x+1,p.y+1]<>nil) then begin
if (B^[p.x+1,p.y+1].rodzaj='krol') and (B^[p.x+1,p.y+1].kolor=MojKolor) then
wynik:=True;
end;
end;

      Result:=wynik; //jezeli false to nie broni

end;


function TForm1.CzyCosAtakujePole(pozycja,rodzaj,MojKolor:string;szachownica:Pointer):boolean;
var
p:TPoint;
i,j:integer;
wynik:boolean;
B:^TBoard;
begin
wynik:=false;
p:=ZnajdzIJbyPole(pozycja);

B:=szachownica;

//sprawdzamy na lewo od pola
   for i:=1 to 8 do
   begin
      if p.Y-i<1 then Break;

      if B^[p.X, p.Y-i]<> nil then
      begin
          if B^[p.X, p.Y-i].kolor = MojKolor then begin Break; end else
          begin
             if (B^[p.X, p.Y-i].rodzaj='wieza') or (B^[p.X, p.Y-i].rodzaj='hetman') then begin wynik:=true; end;
             Break;
          end;
      end;

   end;

   //sprawdzamy na prawo od pola
      for i:=1 to 8 do
      begin
         if p.Y+i>8 then Break;

         if B^[p.X, p.Y+i]<> nil then
         begin
             if B^[p.X, p.Y+i].kolor = MojKolor then begin Break; end else
             begin
                if (B^[p.X, p.Y+i].rodzaj='wieza') or (B^[p.X, p.Y+i].rodzaj='hetman') then begin wynik:=true; Break; end;
                Break;
             end;
         end;

      end;

      //sprawdzamy w gore od pola
         for i:=1 to 8 do
         begin
            if p.X-i<1 then Break;

            if B^[p.X-i, p.Y]<> nil then
            begin
                if B^[p.X-i, p.Y].kolor = MojKolor then begin Break; end else
                begin
                   if (B^[p.X-i, p.Y].rodzaj='wieza') or (B^[p.X-i, p.Y].rodzaj='hetman') then begin wynik:=true; Break; end;
                   Break;
                end;
            end;

         end;

         //sprawdzamy w dol od pola
            for i:=1 to 8 do
            begin
               if p.X+i>8 then Break;

               if B^[p.X+i, p.Y]<> nil then
               begin
                   if B^[p.X+i, p.Y].kolor = MojKolor then begin Break; end else
                   begin
                      if (B^[p.X+i, p.Y].rodzaj='wieza') or (B^[p.X+i, p.Y].rodzaj='hetman') then begin wynik:=true; Break; end;
                      Break;
                   end;
               end;

            end;

         //sprawdzamy na lewo w gore od pola
            for i:=1 to 8 do
            begin
               if (p.X-i<1) or (p.Y-i<1) then Break;

               if B^[p.X-i, p.Y-i]<> nil then
               begin
                   if B^[p.X-i, p.Y-i].kolor = MojKolor then begin Break; end else
                   begin
                      if (B^[p.X-i, p.Y-i].rodzaj='goniec') or (B^[p.X-i, p.Y-i].rodzaj='hetman') then
                      begin wynik:=true;
                          Break;
                      end;
                      Break;
                   end;
               end;

            end;

            //sprawdzamy na prawo w gore od pola
               for i:=1 to 8 do
               begin
                  if (p.X-i<1) or (p.Y+i>8) then Break;

                  if B^[p.X-i, p.Y+i]<> nil then
                  begin
                      if B^[p.X-i, p.Y+i].kolor = MojKolor then begin Break; end else
                      begin
                         if (B^[p.X-i, p.Y+i].rodzaj='goniec') or (B^[p.X-i, p.Y+i].rodzaj='hetman') then begin wynik:=true; Break; end;
                         Break;
                      end;
                  end;

               end;

               //sprawdzamy na prawo w dol od pola
                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y+i>8) then Break;

                     if B^[p.X+i, p.Y+i]<> nil then
                     begin
                         if B^[p.X+i, p.Y+i].kolor = MojKolor then begin Break; end else
                         begin
                            if (B^[p.X+i, p.Y+i].rodzaj='goniec') or (B^[p.X+i, p.Y+i].rodzaj='hetman') then
                            begin
                                wynik:=true;
                                Break;
                            end;
                            Break;
                         end;
                     end;

                  end;

                  //sprawdzamy na lewo w dol od pola

                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y-i<1) then Break;

                     if B^[p.X+i, p.Y-i]<> nil then
                     begin
                         if B^[p.X+i, p.Y-i].kolor = MojKolor then begin Break; end else
                         begin
                            if (B^[p.X+i, p.Y-i].rodzaj='goniec') or (B^[p.X+i, p.Y-i].rodzaj='hetman') then begin wynik:=true; Break; end;
                            Break;
                         end;
                     end;

                  end;

//sprawdzamy ataki pionow
if MojKolor=GramKolorem then begin
if (p.X-1>=1) and (p.Y-1>=1) then
begin
   if B^[p.X-1, p.Y-1]<>nil then begin
     if B^[p.X-1, p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.x-1, p.Y-1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

if (p.X-1>=1) and (p.Y+1<=8) then
begin
   if B^[p.X-1, p.Y+1]<>nil then begin
     if B^[p.X-1, p.Y+1].kolor<>MojKolor then
     begin
        if B^[p.x-1, p.Y+1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

end
else
begin

   if (p.X+1<=8) and (p.Y-1>=1) then
begin
   if B^[p.X+1, p.Y-1]<>nil then begin
     if B^[p.X+1, p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.x+1, p.Y-1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

if (p.X+1<=8) and (p.Y+1<=8) then
begin
   if B^[p.X+1, p.Y+1]<>nil then begin
     if B^[p.X+1, p.Y+1].kolor<>MojKolor then
     begin
        if B^[p.x+1, p.Y+1].rodzaj='pion' then wynik:=true;
     end;
   end;
end;

end;

//jezeli nie sprawdzamy roszady to sprawdzamy tez ataki konia

if rodzaj<>'roszada' then
begin

//sprawdzamy konie

   if (p.X-2>=1) and (p.Y+1<=8) then begin
if B^[p.X-2,p.Y+1]<>nil then
begin
    if B^[p.X-2,p.Y+1].kolor<>MojKolor then
    begin
       if B^[p.X-2,p.Y+1].rodzaj='skoczek' then wynik:=true;
    end;
end;  end;

    if (p.X-1>=1) and (p.Y+2<=8) then begin
 if B^[p.X-1,p.Y+2]<>nil then
 begin
     if B^[p.X-1,p.Y+2].kolor<>MojKolor then
     begin
        if B^[p.X-1,p.Y+2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y+2<=8) then begin
 if B^[p.X+1,p.Y+2]<>nil then
 begin
     if B^[p.X+1,p.Y+2].kolor<>MojKolor then
     begin
        if B^[p.X+1,p.Y+2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y+1<=8) then begin
 if B^[p.X+2,p.Y+1]<>nil then
 begin
     if B^[p.X+2,p.Y+1].kolor<>MojKolor then
     begin
        if B^[p.X+2,p.Y+1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y-1>=1) then begin
 if B^[p.X+2,p.Y-1]<>nil then
 begin
     if B^[p.X+2,p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.X+2,p.Y-1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y-2>=1) then begin
 if B^[p.X+1,p.Y-2]<>nil then
 begin
     if B^[p.X+1,p.Y-2].kolor<>MojKolor then
     begin
        if B^[p.X+1,p.Y-2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X-1>=1) and (p.Y-2>=1) then begin
 if B^[p.X-1,p.Y-2]<>nil then
 begin
     if B^[p.X-1,p.Y-2].kolor<>MojKolor then
     begin
        if B^[p.X-1,p.Y-2].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;

    if (p.X-2>=1) and (p.Y-1>=1) then begin
 if B^[p.X-2,p.Y-1]<>nil then
 begin
     if B^[p.X-2,p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.X-2,p.Y-1].rodzaj='skoczek' then wynik:=true;
     end;
 end; end;


end;

//sprawdzamy czy broni atakuje

if (p.x-1>=1) then begin
if (B^[p.x-1,p.y]<>nil) then begin
if (B^[p.x-1,p.y].rodzaj='krol') and (B^[p.x-1,p.y].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8) then begin
if (B^[p.x+1,p.y]<>nil) then begin
if (B^[p.x+1,p.y].rodzaj='krol') and (B^[p.x+1,p.y].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.y-1>=1) then begin
if (B^[p.x,p.y-1]<>nil) then begin
if (B^[p.x,p.y-1].rodzaj='krol') and (B^[p.x,p.y-1].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.y+1<=8) then begin
if (B^[p.x,p.y+1]<>nil) then begin
if (B^[p.x,p.y+1].rodzaj='krol') and (B^[p.x,p.y+1].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.x-1>=1)and(p.y-1>=1) then begin
if (B^[p.x-1,p.y-1]<>nil) then begin
if (B^[p.x-1,p.y-1].rodzaj='krol') and (B^[p.x-1,p.y-1].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.x-1>=1) and (p.y+1<=8) then begin
if (B^[p.x-1,p.y+1]<>nil) then begin
if (B^[p.x-1,p.y+1].rodzaj='krol') and (B^[p.x-1,p.y+1].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8) and (p.y-1>=1) then begin
if (B^[p.x+1,p.y-1]<>nil) then begin
if (B^[p.x+1,p.y-1].rodzaj='krol') and (B^[p.x+1,p.y-1].kolor<>MojKolor) then
wynik:=True;
end;
end;

if (p.x+1<=8)and(p.y+1<=8) then begin
if (B^[p.x+1,p.y+1]<>nil) then begin
if (B^[p.x+1,p.y+1].rodzaj='krol') and (B^[p.x+1,p.y+1].kolor<>MojKolor) then
wynik:=True;
end;
end;

      Result:=wynik; //jezeli false to nie atakuje


end;

function TForm1.KtoAtakujePole(p:TPoint; szachownica:Pointer):TTablicaPunktow;
var
i,j:integer;
wynik:array of TPoint;
B:^TBoard;
MojKolor:string;
begin

B:=szachownica;
MojKolor:=B^[p.X,p.Y].kolor;

//sprawdzamy na lewo od pola
   for i:=1 to 8 do
   begin
      if p.Y-i<1 then Break;

      if B^[p.X, p.Y-i]<> nil then
      begin
          if B^[p.X, p.Y-i].kolor = MojKolor then begin Break; end else
          begin
             if (B^[p.X, p.Y-i].rodzaj='wieza') or (B^[p.X, p.Y-i].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x,p.y-i);
		end;
             Break;
          end;
      end;

   end;

   //sprawdzamy na prawo od pola
      for i:=1 to 8 do
      begin
         if p.Y+i>8 then Break;

         if B^[p.X, p.Y+i]<> nil then
         begin
             if B^[p.X, p.Y+i].kolor = MojKolor then begin Break; end else
             begin
                if (B^[p.X, p.Y+i].rodzaj='wieza') or (B^[p.X, p.Y+i].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x,p.y+i);
		end;
                Break;
             end;
         end;

      end;

      //sprawdzamy w gore od pola
         for i:=1 to 8 do
         begin
            if p.X-i<1 then Break;

            if B^[p.X-i, p.Y]<> nil then
            begin
                if B^[p.X-i, p.Y].kolor = MojKolor then begin Break; end else
                begin
                   if (B^[p.X-i, p.Y].rodzaj='wieza') or (B^[p.X-i, p.Y].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-i,p.y);
		end;
                   Break;
                end;
            end;

         end;

         //sprawdzamy w dol od pola
            for i:=1 to 8 do
            begin
               if p.X+i>8 then Break;

               if B^[p.X+i, p.Y]<> nil then
               begin
                   if B^[p.X+i, p.Y].kolor = MojKolor then begin Break; end else
                   begin
                      if (B^[p.X+i, p.Y].rodzaj='wieza') or (B^[p.X+i, p.Y].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+i,p.y);
		end;
                      Break;
                   end;
               end;

            end;

         //sprawdzamy na lewo w gore od pola
            for i:=1 to 8 do
            begin
               if (p.X-i<1) or (p.Y-i<1) then Break;

               if B^[p.X-i, p.Y-i]<> nil then
               begin
                   if B^[p.X-i, p.Y-i].kolor = MojKolor then begin Break; end else
                   begin
                      if (B^[p.X-i, p.Y-i].rodzaj='goniec') or (B^[p.X-i, p.Y-i].rodzaj='hetman') then
                      begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-i,p.y-i);
		end;
                      Break;
                   end;
               end;

            end;

            //sprawdzamy na prawo w gore od pola
               for i:=1 to 8 do
               begin
                  if (p.X-i<1) or (p.Y+i>8) then Break;

                  if B^[p.X-i, p.Y+i]<> nil then
                  begin
                      if B^[p.X-i, p.Y+i].kolor = MojKolor then begin Break; end else
                      begin
                         if (B^[p.X-i, p.Y+i].rodzaj='goniec') or (B^[p.X-i, p.Y+i].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-i,p.y+i);
		end;
                         Break;
                      end;
                  end;

               end;

               //sprawdzamy na prawo w dol od pola
                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y+i>8) then Break;

                     if B^[p.X+i, p.Y+i]<> nil then
                     begin
                         if B^[p.X+i, p.Y+i].kolor = MojKolor then begin Break; end else
                         begin
                            if (B^[p.X+i, p.Y+i].rodzaj='goniec') or (B^[p.X+i, p.Y+i].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+i,p.y+i);
		end;
                            Break;
                         end;
                     end;

                  end;

                  //sprawdzamy na lewo w dol od pola

                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y-i<1) then Break;

                     if B^[p.X+i, p.Y-i]<> nil then
                     begin
                         if B^[p.X+i, p.Y-i].kolor = MojKolor then begin Break; end else
                         begin
                            if (B^[p.X+i, p.Y-i].rodzaj='goniec') or (B^[p.X+i, p.Y-i].rodzaj='hetman') then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+i,p.y-i);
		end;
                            Break;
                         end;
                     end;

                  end;

//sprawdzamy piony

if MojKolor=GramKolorem then begin
if (p.X-1>=1) and (p.y-1>=1) then begin
    if B^[p.X-1,p.Y-1]<>nil then
    begin
        if (B^[p.X-1,p.Y-1].rodzaj='pion') and (B^[p.X-1,p.Y-1].kolor<>MojKolor) then
        begin
	SetLength(wynik, Length(wynik)+1);
	wynik[High(wynik)]:=Point(p.x-1,p.y-1);
        end;
    end;
end;

if (p.X-1>=1) and (p.y+1<=8) then begin
    if B^[p.X-1,p.Y+1]<>nil then
    begin
        if (B^[p.X-1,p.Y+1].rodzaj='pion') and (B^[p.X-1,p.Y+1].kolor<>MojKolor) then
        begin
	SetLength(wynik, Length(wynik)+1);
	wynik[High(wynik)]:=Point(p.x-1,p.y+1);
        end;
    end;
end;

end
else
begin

   if (p.X+1<=8) and (p.y-1>=1) then begin
    if B^[p.X+1,p.Y-1]<>nil then
    begin
        if (B^[p.X+1,p.Y-1].rodzaj='pion') and (B^[p.X+1,p.Y-1].kolor<>MojKolor) then
        begin
	SetLength(wynik, Length(wynik)+1);
	wynik[High(wynik)]:=Point(p.x+1,p.y-1);
        end;
    end;
end;

if (p.X+1<=8) and (p.y+1<=8) then begin
    if B^[p.X+1,p.Y+1]<>nil then
    begin
        if (B^[p.X+1,p.Y+1].rodzaj='pion') and (B^[p.X+1,p.Y+1].kolor<>MojKolor) then
        begin
	SetLength(wynik, Length(wynik)+1);
	wynik[High(wynik)]:=Point(p.x+1,p.y+1);
        end;
    end;
end;

end;



//sprawdzamy konie

   if (p.X-2>=1) and (p.Y+1<=8) then begin
if B^[p.X-2,p.Y+1]<>nil then
begin
    if B^[p.X-2,p.Y+1].kolor<>MojKolor then
    begin
       if B^[p.X-2,p.Y+1].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-2,p.y+1);
		end;
    end;
end;  end;

    if (p.X-1>=1) and (p.Y+2<=8) then begin
 if B^[p.X-1,p.Y+2]<>nil then
 begin
     if B^[p.X-1,p.Y+2].kolor<>MojKolor then
     begin
        if B^[p.X-1,p.Y+2].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-1,p.y+2);
		end;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y+2<=8) then begin
 if B^[p.X+1,p.Y+2]<>nil then
 begin
     if B^[p.X+1,p.Y+2].kolor<>MojKolor then
     begin
        if B^[p.X+1,p.Y+2].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+1,p.y+2);
		end;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y+1<=8) then begin
 if B^[p.X+2,p.Y+1]<>nil then
 begin
     if B^[p.X+2,p.Y+1].kolor<>MojKolor then
     begin
        if B^[p.X+2,p.Y+1].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+2,p.y+1);
		end;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y-1>=1) then begin
 if B^[p.X+2,p.Y-1]<>nil then
 begin
     if B^[p.X+2,p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.X+2,p.Y-1].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+2,p.y-1);
		end;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y-2>=1) then begin
 if B^[p.X+1,p.Y-2]<>nil then
 begin
     if B^[p.X+1,p.Y-2].kolor<>MojKolor then
     begin
        if B^[p.X+1,p.Y-2].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x+1,p.y-2);
		end;
     end;
 end; end;

    if (p.X-1>=1) and (p.Y-2>=1) then begin
 if B^[p.X-1,p.Y-2]<>nil then
 begin
     if B^[p.X-1,p.Y-2].kolor<>MojKolor then
     begin
        if B^[p.X-1,p.Y-2].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-1,p.y-2);
		end;
     end;
 end; end;

    if (p.X-2>=1) and (p.Y-1>=1) then begin
 if B^[p.X-2,p.Y-1]<>nil then
 begin
     if B^[p.X-2,p.Y-1].kolor<>MojKolor then
     begin
        if B^[p.X-2,p.Y-1].rodzaj='skoczek' then begin
		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-2,p.y-1);
		end;
     end;
 end; end;


    //sprawdzamy czy broni atakuje
    if (p.x-1>=1) then begin
    if (B^[p.x-1,p.y]<>nil) then begin
    if (B^[p.x-1,p.y].rodzaj='krol') and (B^[p.x-1,p.y].kolor<>MojKolor) then
begin
    		SetLength(wynik, Length(wynik)+1);
		wynik[High(wynik)]:=Point(p.x-1,p.y);
end;
end;
end;

    if (p.x+1<=8) then begin
    if (B^[p.x+1,p.y]<>nil) then begin
    if (B^[p.x+1,p.y].rodzaj='krol') and (B^[p.x+1,p.y].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x+1,p.y);
    end;
    end;
    end;

    if (p.y-1>=1) then begin
    if (B^[p.x,p.y-1]<>nil) then begin
    if (B^[p.x,p.y-1].rodzaj='krol') and (B^[p.x,p.y-1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x,p.y-1);
    end;
    end;
    end;

    if (p.y+1<=8) then begin
    if (B^[p.x,p.y+1]<>nil) then begin
    if (B^[p.x,p.y+1].rodzaj='krol') and (B^[p.x,p.y+1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x,p.y+1);
    end;
    end;
    end;

    if (p.x-1>=1) and (p.y-1>=1) then begin
    if (B^[p.x-1,p.y-1]<>nil) then begin
    if (B^[p.x-1,p.y-1].rodzaj='krol') and (B^[p.x-1,p.y-1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x-1,p.y-1);
    end;
    end;
    end;

    if (p.x-1>=1) and (p.y+1<=8) then begin
    if (B^[p.x-1,p.y+1]<>nil) then begin
    if (B^[p.x-1,p.y+1].rodzaj='krol') and (B^[p.x-1,p.y+1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x-1,p.y+1);
    end;
    end;
    end;

    if (p.x+1<=8) and (p.y-1>=1) then begin
    if (B^[p.x+1,p.y-1]<>nil) then begin
    if (B^[p.x+1,p.y-1].rodzaj='krol') and (B^[p.x+1,p.y-1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x+1,p.y-1);
    end;
    end;
    end;

    if (p.x+1<=8) and (p.y+1<=8) then begin
    if (B^[p.x+1,p.y+1]<>nil) then begin
    if (B^[p.x+1,p.y+1].rodzaj='krol') and (B^[p.x+1,p.y+1].kolor<>MojKolor) then
    begin
        		SetLength(wynik, Length(wynik)+1);
    		wynik[High(wynik)]:=Point(p.x+1,p.y+1);
    end;
    end;
    end;


      Result:=wynik;


end;

function TForm1.CzySieRuszal(polozenie:TPoint):boolean;
var
RuszalSie:boolean;
rodzaj,kolor:string;
i:integer;
begin
rodzaj:=Board[polozenie.X,polozenie.Y].rodzaj;
kolor:=Board[polozenie.X,polozenie.Y].kolor;

RuszalSie:=false;
for i:=0 to Length(PrzebiegPartii)-1 do
begin
   if (PrzebiegPartii[i].figura=rodzaj) and (PrzebiegPartii[i].kolor=kolor) then begin RuszalSie:=true; Break; end;
end;

Result:=RuszalSie;  //jak false to sie nie ruszal

end;

function TForm1.SprawdzKrola(pole:TPoint; na:string):boolean; //true - nie atakowany, false - atakowany
var
tmpBoard : array[1..8,1..8] of TBierka;
tmp:TBierka;
punkt:TPoint;
i,j:integer;
PozycjaKrola:TPoint;
WszystkoOK:boolean;
figura:string;
begin
tmpBoard:=Board;

tmp:=tmpBoard[pole.X,pole.Y];
tmpBoard[pole.X,pole.Y]:=nil;
punkt:=znajdzIJbyPole(na);
tmpBoard[punkt.X,punkt.Y]:=tmp;

for i:=1 to 8 do
for j:=1 to 8 do
  if TmpBoard[i,j]<>nil then begin if (tmpBoard[i,j].rodzaj='krol') and (tmpBoard[i,j].kolor=GramKolorem) then PozycjaKrola:=Point(i,j); end;

WszystkoOK:=CzyCosAtakujePole(DaneBoard[PozycjaKrola.X, PozycjaKrola.Y].pole, 'ruch', GramKolorem, @tmpBoard);

if WszystkoOK=false then
begin Result:=true end else
begin
Result:=false;
end;


end;

function TForm1.CzyKrolMaGdzieUciec(K:TPoint):boolean;
var
ma:boolean;
MojKolor,KolorPrzeciwnika:string;
begin
ma:=false;

MojKolor:=Board[K.X,K.Y].kolor;

if MojKolor='biale' then begin KolorPrzeciwnika:='czarne'; end else begin KolorPrzeciwnika:='biale'; end;

if K.x-1>=1 then begin  //do gory
   if Board[K.X-1, K.Y]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X-1,K.Y].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
   else
   begin
      if (MojKolor<>Board[K.X-1,K.Y].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X-1,K.Y].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if (K.x-1>=1) and (K.y+1<=8) then begin  //do gory w prawo
   if Board[K.X+1, K.Y+1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X-1,K.Y+1].pole, 'ruch',MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X-1,K.Y+1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X-1,K.Y+1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if (K.x-1>=1) and (K.y-1>=1) then begin  //do gory w lewo
   if Board[K.X-1, K.Y-1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X-1,K.Y-1].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X-1,K.Y-1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X-1,K.Y-1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if K.y-1>=1 then begin  //w lewo
   if Board[K.X, K.Y-1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X,K.Y-1].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X,K.Y-1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X,K.Y-1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if (K.x+1<=8) and (K.y-1>=1) then begin  //w lewo w dol
   if Board[K.X+1, K.Y-1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X+1,K.Y-1].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X+1,K.Y-1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X+1,K.Y-1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if K.x+1<=8 then begin  //w dol
   if Board[K.X+1, K.Y]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X+1,K.Y].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X+1,K.Y].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X+1,K.Y].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if K.y+1<=8 then begin  //w prawo
   if Board[K.X, K.Y+1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X,K.Y+1].pole, 'ruch', MojKolor, @Board)=false then ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X,K.Y+1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X,K.Y+1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then ma:=True;
         end;
   end;
end;

if (K.x+1<=8) and (K.y+1<=8) then begin  //w prawo w dol
   if Board[K.X+1, K.Y+1]=nil then
   begin
      if CzyCosAtakujePole(DaneBoard[K.X+1,K.Y+1].pole, 'ruch', MojKolor, @Board)=false then
      ma:=True;
   end
      else
   begin
      if (MojKolor<>Board[K.X+1,K.Y+1].kolor) then
         begin
             if CzyCosBroniPole(DaneBoard[K.X+1,K.Y+1].pole, 'ruch', KolorPrzeciwnika, @Board)=false then
             ma:=True;
         end;
   end;
end;

Result:=ma;

end;


function TForm1.CzyCosStanieNaPolu(pozycja,MojKolor:string;szachownica:Pointer):boolean;   //podrzedne
var
p,PozycjaKrola:TPoint;
i,j:integer;
wynik:boolean;
B:^TBoard;
tmpBoard:TBoard;
tmpBierka:TBierka;
begin
wynik:=false;
p:=ZnajdzIJbyPole(pozycja);

B:=szachownica;

//szukamy pozycji krola na szachownicy
for i:=1 to 8 do
for j:=1 to 8 do
  if B^[i,j]<>nil then begin if (B^[i,j].rodzaj='krol') and (B^[i,j].kolor=MojKolor) then PozycjaKrola:=Point(i,j); end;

//sprawdzamy na lewo od pola
   for i:=1 to 8 do
   begin
      if p.Y-i<1 then Break;

      if B^[p.X, p.Y-i]<> nil then
      begin
          if B^[p.X, p.Y-i].kolor = MojKolor then begin
             if (B^[p.X, p.Y-i].rodzaj='wieza') or (B^[p.X, p.Y-i].rodzaj='hetman') then
             begin
                  tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X, p.Y-i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X, p.Y-i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
             end;
             Break;
      end;
     end;
   end;

   //sprawdzamy na prawo od pola
      for i:=1 to 8 do
      begin
         if p.Y+i>8 then Break;

         if B^[p.X, p.Y+i]<> nil then
         begin
             if B^[p.X, p.Y+i].kolor = MojKolor then begin
                if (B^[p.X, p.Y+i].rodzaj='wieza') or (B^[p.X, p.Y+i].rodzaj='hetman') then
                             begin
                  tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X, p.Y+i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X, p.Y+i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
             end;
                Break;
         end;
       end;
      end;

      //sprawdzamy w gore od pola
         for i:=1 to 8 do
         begin
            if p.X-i<1 then Break;

            if B^[p.X-i, p.Y]<> nil then
            begin
                if B^[p.X-i, p.Y].kolor = MojKolor then begin
                   if (B^[p.X-i, p.Y].rodzaj='wieza') or (B^[p.X-i, p.Y].rodzaj='hetman') then
                                begin
                  tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-i, p.Y];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-i, p.Y]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
             end;
                   Break;
            end;
           end;
         end;

         //sprawdzamy w dol od pola
            for i:=1 to 8 do
            begin
               if p.X+i>8 then Break;

               if B^[p.X+i, p.Y]<> nil then
               begin
                   if B^[p.X+i, p.Y].kolor = MojKolor then begin
                      if (B^[p.X+i, p.Y].rodzaj='wieza') or (B^[p.X+i, p.Y].rodzaj='hetman') then
                                   begin
                  tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+i, p.Y];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+i, p.Y]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
             end;
                      Break;
               end;
            end;
            end;

         //sprawdzamy na lewo w gore od pola
            for i:=1 to 8 do
            begin
               if (p.X-i<1) or (p.Y-i<1) then Break;

               if B^[p.X-i, p.Y-i]<> nil then
               begin
                   if B^[p.X-i, p.Y-i].kolor = MojKolor then begin
                      if (B^[p.X-i, p.Y-i].rodzaj='goniec') or (B^[p.X-i, p.Y-i].rodzaj='hetman') then
                      begin
                                        tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-i, p.Y-i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-i, p.Y-i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
                      end;
                      Break;
               end;
               end;
            end;

            //sprawdzamy na prawo w gore od pola
               for i:=1 to 8 do
               begin
                  if (p.X-i<1) or (p.Y+i>8) then Break;

                  if B^[p.X-i, p.Y+i]<> nil then
                  begin
                      if B^[p.X-i, p.Y+i].kolor = MojKolor then begin
                         if (B^[p.X-i, p.Y+i].rodzaj='goniec') or (B^[p.X-i, p.Y+i].rodzaj='hetman') then
                         begin
                                           tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-i, p.Y+i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-i, p.Y+i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
                         end;
                         Break;
                  end;
                  end;
               end;

               //sprawdzamy na prawo w dol od pola
                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y+i>8) then Break;

                     if B^[p.X+i, p.Y+i]<> nil then
                     begin
                         if B^[p.X+i, p.Y+i].kolor = MojKolor then begin
                            if (B^[p.X+i, p.Y+i].rodzaj='goniec') or (B^[p.X+i, p.Y+i].rodzaj='hetman') then
                            begin
                                              tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+i, p.Y+i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+i, p.Y+i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
                            end;
                            Break;
                     end;
                    end;
                  end;

                  //sprawdzamy na lewo w dol od pola

                  for i:=1 to 8 do
                  begin
                     if (p.X+i>8) or (p.Y-i<1) then Break;

                     if B^[p.X+i, p.Y-i]<> nil then
                     begin
                         if B^[p.X+i, p.Y-i].kolor = MojKolor then begin
                            if (B^[p.X+i, p.Y-i].rodzaj='goniec') or (B^[p.X+i, p.Y-i].rodzaj='hetman') then
                            begin
                                              tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+i, p.Y-i];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+i, p.Y-i]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
                            end;
                            Break;
                         end;
                  end;
                      end;

//sprawdzamy ataki pionow


if (p.X+1<=8) then
begin
   if B^[p.X-1, p.Y]<>nil then begin
     if B^[p.X-1, p.Y].kolor=MojKolor then
     begin
        if B^[p.x-1, p.Y].rodzaj='pion' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-1, p.Y];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-1, p.Y]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
   end;
end;


//sprawdzamy konie

   if (p.X-2>=1) and (p.Y+1<=8) then begin
if B^[p.X-2,p.Y+1]<>nil then
begin
    if B^[p.X-2,p.Y+1].kolor=MojKolor then
    begin
       if B^[p.X-2,p.Y+1].rodzaj='skoczek' then begin
                         tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-2, p.Y+1];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-2, p.Y+1]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
       end;
    end;
end;  end;

    if (p.X-1>=1) and (p.Y+2<=8) then begin
 if B^[p.X-1,p.Y+2]<>nil then
 begin
     if B^[p.X-1,p.Y+2].kolor=MojKolor then
     begin
        if B^[p.X-1,p.Y+2].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-1, p.Y+2];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-1, p.Y+2]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y+2<=8) then begin
 if B^[p.X+1,p.Y+2]<>nil then
 begin
     if B^[p.X+1,p.Y+2].kolor=MojKolor then
     begin
        if B^[p.X+1,p.Y+2].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+1, p.Y+2];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+1, p.Y+2]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y+1<=8) then begin
 if B^[p.X+2,p.Y+1]<>nil then
 begin
     if B^[p.X+2,p.Y+1].kolor=MojKolor then
     begin
        if B^[p.X+2,p.Y+1].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+2, p.Y+1];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+2, p.Y+1]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X+2<=8) and (p.Y-1>=1) then begin
 if B^[p.X+2,p.Y-1]<>nil then
 begin
     if B^[p.X+2,p.Y-1].kolor=MojKolor then
     begin
        if B^[p.X+2,p.Y-1].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+2, p.Y-1];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+2, p.Y-1]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X+1<=8) and (p.Y-2>=1) then begin
 if B^[p.X+1,p.Y-2]<>nil then
 begin
     if B^[p.X+1,p.Y-2].kolor=MojKolor then
     begin
        if B^[p.X+1,p.Y-2].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X+1, p.Y-2];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X+1, p.Y-2]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X-1>=1) and (p.Y-2>=1) then begin
 if B^[p.X-1,p.Y-2]<>nil then
 begin
     if B^[p.X-1,p.Y-2].kolor=MojKolor then
     begin
        if B^[p.X-1,p.Y-2].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-1, p.Y-2];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-1, p.Y-2]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;

    if (p.X-2>=1) and (p.Y-1>=1) then begin
 if B^[p.X-2,p.Y-1]<>nil then
 begin
     if B^[p.X-2,p.Y-1].kolor=MojKolor then
     begin
        if B^[p.X-2,p.Y-1].rodzaj='skoczek' then begin
                          tmpBoard:=B^;
                  tmpBierka:=tmpBoard[p.X-2, p.Y-1];
                  tmpBoard[p.X,p.Y]:=tmpBierka;
                  tmpBoard[p.X-2, p.Y-1]:=nil; //sprawdzamy czy po zaslonieciu krola nie odslaniamy innego ataku
                      if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch',MojKolor,@tmpBoard)=false then
                      Exit (True);
        end;
     end;
 end; end;



      Result:=wynik; //jezeli false to nie stanie nic

end;

function TForm1.CzyMoznaZaslonic(atakowany,atakujacy:TPoint):boolean;  //nadrzedne
var
i,j:integer;
CzyMozna,tmp:boolean;
a,b:TPoint;
begin
CzyMozna:=false;

if (atakowany.X-atakujacy.X<0) and (atakowany.Y-atakujacy.Y<0) then //atak po skosie z dolu z prawej
begin
  //  tmp:=false;
    for i:=1 to atakujacy.X-atakowany.X do
    begin
         if (atakowany.X+i=atakujacy.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X+i,atakowany.Y+i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X<0) and (atakowany.Y-atakujacy.Y>0) then //atak po skosie z dolu z lewej
begin
  //  tmp:=false;
    for i:=1 to atakujacy.X-atakowany.X do
    begin
         if (atakowany.X+i=atakujacy.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X+i,atakowany.Y-i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X>0) and (atakowany.Y-atakujacy.Y>0) then //atak po skosie z gory z lewej
begin
 //   tmp:=false;
    for i:=1 to atakowany.X-atakujacy.X do
    begin
         if (atakujacy.X+i=atakowany.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X-i,atakowany.Y-i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X>0) and (atakowany.Y-atakujacy.Y<0) then //atak po skosie z gory z prawej
begin
 //   tmp:=false;
    for i:=1 to atakowany.X-atakujacy.X do
    begin
         if (atakujacy.X+i=atakowany.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X-i,atakowany.Y+i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X>0) and (atakowany.Y-atakujacy.Y=0) then //atak z gory
begin
 //   tmp:=false;
    for i:=1 to atakowany.X-atakujacy.X do
    begin
         if (atakujacy.X+i=atakowany.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X-i,atakowany.Y].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X<0) and (atakowany.Y-atakujacy.Y=0) then //atak z dolu
begin
 //   tmp:=false;
    for i:=1 to atakujacy.X-atakowany.X do
    begin
         if (atakowany.X+i=atakujacy.X) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X+i,atakowany.Y].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X=0) and (atakowany.Y-atakujacy.Y>0) then //atak z lewej
begin
  //  tmp:=false;
   j:=atakowany.Y-atakujacy.Y;

    for i:=1 to j do
    begin
         if (atakujacy.Y+i=atakowany.Y) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X,atakowany.Y-i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;

if (atakowany.X-atakujacy.X=0) and (atakowany.Y-atakujacy.Y<0) then //atak z prawej
begin
 //   tmp:=false;
    for i:=1 to atakujacy.Y-atakowany.Y do
    begin
         if (atakowany.Y+i=atakujacy.Y) then Break;
         if (CzyCosStanieNaPolu(DaneBoard[atakowany.X,atakowany.Y+i].pole, Board[atakowany.X,atakowany.Y].kolor,@Board)=true) then
         Exit (true);
    end;
 //   if tmp=false then Exit (false);
end;



    Result:=CzyMozna;
end;

function TForm1.CzyMat(kolor:string):boolean;
var
PozycjaKrola:TPoint;
i,j:integer;
atakujacy:TTablicaPunktow;
KolorPrzeciwnika:string;
nie:boolean;
begin
nie:=false;

for i:=1 to 8 do
for j:=1 to 8 do
  if Board[i,j]<>nil then begin if (Board[i,j].rodzaj='krol') and (Board[i,j].kolor=kolor) then PozycjaKrola:=Point(i,j); end;

if CzyCosAtakujePole(DaneBoard[PozycjaKrola.X,PozycjaKrola.Y].pole,'ruch', kolor, @Board)=true then   //Po wykonanym ruchu sprawdzamy czy cos atakuje wskazanego krola
begin

   //sprawdzamy najpierw najblizsze pola krola czy moze uciec albo zabic
        if CzyKrolMaGdzieUciec(PozycjaKrola)=true then
        begin
        Exit (False);
        end
        else
        begin

     //jezeli krol  moze uciec lub zabic z bliska sprawdzamy liste atakujacych
            atakujacy:=KtoAtakujePole(PozycjaKrola, @Board);

            if Length(atakujacy)=0 then Exit; //brak atakujacych przeciwnikow

            for i:=0 to Length(atakujacy)-1 do
            begin
                 //najpierw sprawdzimy czy mozna zabic bierke

                if kolor='biale' then begin KolorPrzeciwnika:='czarne'; end else begin KolorPrzeciwnika:='biale'; end;

                if CzyCosAtakujePole(DaneBoard[atakujacy[i].x,atakujacy[i].y].pole, 'ruch', KolorPrzeciwnika, @Board) = true then //jezeli nie mozna zabic bierki sprawdzamy czy mozna zaslonic pola
                begin
                Exit (False);
                end
                else
                begin


                      if CzyMoznaZaslonic(PozycjaKrola, atakujacy[i])=true then
                      begin
                      Exit (False);
                      end
                      else
                      begin
                      Exit (True);
                      end;
                 end;
            end;
        end;
        end;

Result:=nie;
end;

function TForm1.CzyPat(ruch:string):boolean;
var
i,j,L:integer;
PozycjaKrola:TPoint;
begin

L:=Length(PrzebiegPartii);

if L>=12 then //sprawdzamy czy trzykrotne powtorzenie ruchow
begin
if (PrzebiegPartii[L-1].Z=PrzebiegPartii[L-3].NA) and (PrzebiegPartii[L-1].NA=PrzebiegPartii[L-3].Z) and //sprawdzamy dla pierwszego
   (PrzebiegPartii[L-3].Z=PrzebiegPartii[L-5].NA) and (PrzebiegPartii[L-3].NA=PrzebiegPartii[L-5].Z) and
   (PrzebiegPartii[L-5].Z=PrzebiegPartii[L-7].NA) and (PrzebiegPartii[L-5].NA=PrzebiegPartii[L-7].Z) and
   (PrzebiegPartii[L-7].Z=PrzebiegPartii[L-9].NA) and (PrzebiegPartii[L-7].NA=PrzebiegPartii[L-9].Z) and
   (PrzebiegPartii[L-9].Z=PrzebiegPartii[L-11].NA) and (PrzebiegPartii[L-9].NA=PrzebiegPartii[L-11].Z) and
   (PrzebiegPartii[L-2].Z=PrzebiegPartii[L-4].NA) and (PrzebiegPartii[L-2].NA=PrzebiegPartii[L-4].Z) and //sprawdzamy dla drugiego
   (PrzebiegPartii[L-4].Z=PrzebiegPartii[L-6].NA) and (PrzebiegPartii[L-4].NA=PrzebiegPartii[L-6].Z) and
   (PrzebiegPartii[L-6].Z=PrzebiegPartii[L-8].NA) and (PrzebiegPartii[L-6].NA=PrzebiegPartii[L-8].Z) and
   (PrzebiegPartii[L-8].Z=PrzebiegPartii[L-10].NA) and (PrzebiegPartii[L-8].NA=PrzebiegPartii[L-10].Z) and
   (PrzebiegPartii[L-10].Z=PrzebiegPartii[L-12].NA) and (PrzebiegPartii[L-10].NA=PrzebiegPartii[L-12].Z) then
   Exit (True); //jezeli trzykrotne powtorzenie ruchu przez kazdego gracza to remis

end;

for i:=1 to 8 do
for j:=1 to 8 do
begin
    if (Board[i,j]<>nil) then
    begin
         if Board[i,j].kolor=ruch then
         begin
              if Length(MozliweRuchy(DaneBoard[i,j].pole))>0 then
              Exit (False);
         end;
    end;
end;

Result:=True;

end;


function TForm1.ZostalTylkoKrol(kolor:string):boolean;
var
i,j:integer;
begin
for i:=1 to 8 do
for j:=1 to 8 do
begin
    if Board[i,j]<>nil then
    begin
         if Board[i,j].kolor=kolor then
         begin
              if (Board[i,j].rodzaj<> 'krol') then
              begin
                  Exit (False);
              end;
         end;
    end;
end;

Result:=True;

end;


function TForm1.CzyRemis:boolean;
var
i,j:integer;
JestGoniec,JestSkoczek:boolean;
kolor:string;
ruchy:TMapaRuchow;
begin

//najpierw sprawdzimy czy zostaly odpowiednie bierki

//tylko krole

if (ZostalTylkoKrol('biale') and ZostalTylkoKrol('czarne')) then
Exit (True);


//sprawdzamy biale
for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='biale') and (Board[i,j].rodzaj<> 'krol') then
begin
    if (Board[i,j].rodzaj='pion') then //jezeli pion to czy moze sie ruszyc
    begin
        if Board[i-1,j]=nil then
        begin
        Exit (False);
        end
        else
        begin
            if (Board[i-1,j].rodzaj<>'pion') then
            Exit (False);
        end;
    end;

    if (Board[i,j].rodzaj='wieza') or (Board[i,j].rodzaj='hetman') then
    Exit (False);

end;

end;

//sprawdzamy czy sa tylko dwa gonce

JestGoniec:=false;

for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='biale') and (Board[i,j].rodzaj<> 'krol') then
begin
    if Board[i,j].rodzaj='goniec' then
    begin
        if (JestGoniec=true) then begin
        if DaneBoard[i,j].KolorPola<>kolor then
        Exit (False);
        end;

        JestGoniec:=true;
        kolor:=DaneBoard[i,j].KolorPola;
    end;
end;
end;

//sprawdzamy czy sa goniec i skoczek

JestSkoczek:=false;
JestGoniec:=false;

for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='biale') and (Board[i,j].rodzaj<>'krol') then
begin
    if Board[i,j].rodzaj='skoczek' then
    begin
        if JestGoniec=true then
        Exit (False);
        JestGoniec:=true;
    end;

    if Board[i,j].rodzaj='goniec' then
    begin
        if JestSkoczek=true then
        Exit (False);
        JestSkoczek:=true;
    end;
end;
end;


//sprawdzamy czarne {wiem wiem, mozna to zrobic w jednej funkcji... }
for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='czarne') and (Board[i,j].rodzaj<> 'krol') then
begin
    if (Board[i,j].rodzaj='pion') then //jezeli pion to czy moze sie ruszyc
    begin
        if Board[i-1,j]=nil then
        begin
        Exit (False);
        end
        else
        begin
            if (Board[i-1,j].rodzaj<>'pion') then
            Exit (False);
        end;
    end;

    if (Board[i,j].rodzaj='wieza') or (Board[i,j].rodzaj='hetman') then
    Exit (False);

end;

end;

//sprawdzamy czy sa tylko dwa gonce

JestGoniec:=false;

for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='czarne') and (Board[i,j].rodzaj<> 'krol') then
begin
    if Board[i,j].rodzaj='goniec' then
    begin
        if JestGoniec=true then
        Exit (False);

        JestGoniec:=true;
    end;
end;
end;

//sprawdzamy czy sa goniec i skoczek

JestSkoczek:=false;
JestGoniec:=false;

for i:=1 to 8 do
for j:=1 to 8 do
begin
if (Board[i,j]<>nil) and (Board[i,j].kolor='czarne') and (Board[i,j].rodzaj<>'krol') then
begin
    if Board[i,j].rodzaj='skoczek' then
    begin
        if JestGoniec=true then
        Exit (False);
        JestGoniec:=true;
    end;

    if Board[i,j].rodzaj='goniec' then
    begin
        if JestSkoczek=true then
        Exit (False);
        JestSkoczek:=true;
    end;
end;
end;



Result:=True;
end;

{--------------------------------------------------------------------------------------}

procedure TForm1.FormCreate(Sender: TObject);
var
  i,j,a,NumerPola,obraz:integer;
  kolor:string;
  white:boolean;
begin

KolorowanieRuchu.ok:=false;
KolorowanieKrola.ok:=false;
KogoRuch:='biale';
MozliweWPrzelocie.ok:=false;

  GramKolorem := 'biale';

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

         {jezeli gramy czarny odwracamy krola i hetmana}
        if GramKolorem='czarne' then
        begin

          Board[4,4]:=Board[1,4];
          Board[1,4]:=Board[1,5];
          Board[1,5]:=Board[4,4];
          Board[4,4]:=nil;

          Board[1,4].pole:=DaneBoard[1,4].pole;
          Board[1,4].pozycja:=Point(DaneBoard[1,4].X, DaneBoard[1,4].Y);
          Board[1,5].pole:=DaneBoard[1,5].pole;
          Board[1,5].pozycja:=Point(DaneBoard[1,5].X, DaneBoard[1,5].Y);

          Board[4,4]:=Board[8,4];
          Board[8,4]:=Board[8,5];
          Board[8,5]:=Board[4,4];
          Board[4,4]:=nil;

          Board[8,4].pole:=DaneBoard[8,4].pole;
          Board[8,4].pozycja:=Point(DaneBoard[8,4].X, DaneBoard[8,4].Y);
          Board[8,5].pole:=DaneBoard[8,5].pole;
          Board[8,5].pozycja:=Point(DaneBoard[8,5].X, DaneBoard[8,5].Y);

        end;

        white:=false;
        for i:=1 to 8 do begin
           if white=true then begin white:=false; end else begin white:=true; end;
        for j:=1 to 8 do begin
        	if white=true then begin
        	DaneBoard[i,j].KolorPola:='biale';
        	end
        	else
        	begin
        	DaneBoard[i,j].KolorPola:='czarne';
        	end;

        	if white=true then begin white:=false; end else begin white:=true; end;
        end;
        end;


         PaintBox1.Enabled:=True;
        end;



procedure TForm1.Button1Click(Sender: TObject);
var
  i,j:integer;
    l:string;
begin
Memo1.lines.add('--------------');

for i:=1 to 8 do
begin
for j:=1 to 8 do
begin
if Board[i,j]<>nil then
     l:=l+'+'+ LeftStr(Board[i,j].rodzaj, 1);
end;
    Memo1.lines.add(l);
    l:='';
end;

end;

procedure TForm1.Button2Click(Sender: TObject);
var
    x:TPoint;
begin
x:=ZnajdzIJbyPole(Edit2.Text);
  WykonajRuch(Edit1.Text,Edit2.Text,Edit3.Text);
  ZapiszRuch(Edit1.Text,Edit2.Text,Board[x.x,x.y].rodzaj,Board[x.x,x.y].kolor,'');

 if KogoRuch='biale' then KogoRuch:='czarne'
else KogoRuch:='biale';


end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i,j:integer;
  pol:string;
  tmp:TPoint;
begin

pol:=ZnajdzPolebyXY(X,Y);
Memo1.Lines.add(pol);
memo1.lines.add('X: '+inttostr(X)+', Y: '+inttostr(Y));
tmp:=znajdzIjbyPole(pol);
memo1.Lines.Add('kolor pola: '+DaneBoard[tmp.x,tmp.y].KolorPola);

  for i:=1 to 8 do
  for j:=1 to 8 do
  begin
   if Board[i,j]<>nil then
   begin
   if pol=Board[i,j].pole then
  begin
    if Board[i,j].kolor=KogoRuch then begin
    DAD:=true;
    DadBierka:=@Board[i,j];
    PunktPlansza := Point(X, Y);
    PolePlansza:=Point(i,j);
    memo1.lines.add('I: '+inttostr(i)+', J: '+inttostr(j));
    SetLength(TablicaRuchow, 0);
    TablicaRuchow:=MozliweRuchy(Board[i,j].pole);
    Break;
    end;
  end;

  end;

  end;

end;

procedure TForm1.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if (DAD) then
         begin


         if X>PunktPlansza.X then
         begin
              DADBierka^.pozycja.X   := DADBierka^.pozycja.X+(X-PunktPlansza.x);
              PunktPlansza.X:=X;
         end;
         if X<PunktPlansza.X then
         begin
         DADBierka^.pozycja.X   := DADBierka^.pozycja.X-(PunktPlansza.x-X);
         PunktPlansza.X:=X;
         end;
         if Y<PunktPlansza.Y then
         begin
              DADBierka^.pozycja.Y    := DADBierka^.pozycja.Y-(PunktPlansza.Y-Y);
              PunktPlansza.y:=Y;
         end;
         if Y>PunktPlansza.Y then
         begin
              DADBierka^.pozycja.Y    := DADBierka^.pozycja.Y+(Y-PunktPlansza.Y);
              PunktPlansza.Y:=Y;
         end;

         PaintBox1.Invalidate;
         end;
end;

procedure TForm1.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tmp,tmpWieza:TBierka;
  okKrol,okRuch:boolean;
  z,i,TMPx, TMPy:TPoint;
  tlo:TPortableNetworkGraphic;
begin
okKrol:=true;
okRuch:=false;

 if DAD then
 begin

 if ZnajdzPolebyXY(X,Y)=DaneBoard[PolePlansza.X,PolePlansza.Y].pole then
begin
  DadBierka^.pole:=DaneBoard[PolePlansza.X, PolePlansza.Y].pole;
  DadBierka^.pozycja := ZnajdzXYbyPole(DadBierka^.pole);
  DAD:=false;
  SetLength(TablicaRuchow, 0);
  PaintBox1.Invalidate;
  Exit;
end;


  DadBierka^.pole:=ZnajdzPolebyXY(X,Y);
  DadBierka^.pozycja := ZnajdzXYbyPole(ZnajdzPolebyXY(X,Y));

   okKrol:=SprawdzKrola(PolePlansza, ZnajdzPolebyXY(X,Y));

okRuch:=CzyLegalnyRuch(ZnajdzPolebyXY(X,Y));

if (okKrol=true) and (okRuch=true) then
begin

//sprawdzamy czy biale zrobily roszade krotka
if (DaneBoard[PolePlansza.X,PolePlansza.y].pole='E1')and(ZnajdzPolebyXY(X,Y)='G1')
and (DadBierka^.rodzaj='krol') then
begin
    WykonajRuch('H1','F1','roszada');
end;

//sprawdzamy czy biale zrobily roszade dluga
if (DaneBoard[PolePlansza.X,PolePlansza.y].pole='E1')and(ZnajdzPolebyXY(X,Y)='C1')
and (DadBierka^.rodzaj='krol') then
begin
    WykonajRuch('A1','D1','roszada');
end;

//sprawdzamy czy czarne zrobily roszade krotka
if (DaneBoard[PolePlansza.X,PolePlansza.y].pole='E8')and(ZnajdzPolebyXY(X,Y)='G8')
and (DadBierka^.rodzaj='krol') then
begin
    WykonajRuch('H8','F8','roszada');
end;

//sprawdzamy czy czarne zrobily roszade dluga
if (DaneBoard[PolePlansza.X,PolePlansza.y].pole='E8')and(ZnajdzPolebyXY(X,Y)='C8')
and (DadBierka^.rodzaj='krol') then
begin
    WykonajRuch('A8','D8','roszada');
end;

//wykonujemy ruch
if Board[(Y div 80)+1,(X div 80)+1]<> nil then
FreeAndNil(Board[(Y div 80)+1,(X div 80)+1]);

     tmp:=DadBierka^;
     Board[PolePlansza.X, PolePlansza.Y] := nil;
     Board[(Y div 80)+1,(X div 80)+1] := tmp;



     //sprawdzamy czy pionek doszedl do konca planszy
     if tmp.rodzaj='pion' then
     begin
          i:=ZnajdzIJByPole(tmp.pole);

          if (tmp.kolor='biale')and(i.x=1)then
          begin
              Form2.ShowModal;
                  if Form2.wybor='hetman' then
                  begin
                  Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/HetmanBialy.png');
                  Board[(Y div 80)+1,(X div 80)+1].rodzaj:='hetman';
                  end;
                  if Form2.wybor='wieza' then
                  begin
                  Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/WiezaBiala.png');
                  Board[(Y div 80)+1,(X div 80)+1].rodzaj:='wieza';
                  end;
                  if Form2.wybor='goniec' then
                  begin
                  Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/GoniecBialy.png');
                  Board[(Y div 80)+1,(X div 80)+1].rodzaj:='goniec';
                  end;
                  if Form2.wybor='skoczek' then
                  begin
                  Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/SkoczekBialy.png');
                  Board[(Y div 80)+1,(X div 80)+1].rodzaj:='skoczek';
                  end;
          end;
             if (tmp.kolor='czarne')and(i.x=1)then
             begin
                 Form2.ShowModal;
                     if Form2.wybor='hetman' then
                     begin
                     Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/HetmanCzarny.png');
                     Board[(Y div 80)+1,(X div 80)+1].rodzaj:='hetman';
                     end;
                     if Form2.wybor='wieza' then
                     begin
                     Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/WiezaCzarna.png');
                     Board[(Y div 80)+1,(X div 80)+1].rodzaj:='wieza';
                     end;
                     if Form2.wybor='goniec' then
                     begin
                     Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/GoniecCzarny.png');
                     Board[(Y div 80)+1,(X div 80)+1].rodzaj:='goniec';
                     end;
                     if Form2.wybor='skoczek' then
                     begin
                     Board[(Y div 80)+1,(X div 80)+1].obraz.LoadFromFile('img/SkoczekCzarny.png');
                     Board[(Y div 80)+1,(X div 80)+1].rodzaj:='skoczek';
                     end;
             end;

     end;


        if KogoRuch='biale' then KogoRuch:='czarne'
        else KogoRuch:='biale';

     KolorowanieRuchu.ok:=true;
     KolorowanieRuchu.Z:=PolePlansza;
     KolorowanieRuchu.NA:=Point((Y div 80)+1,(X div 80)+1);

     if MozliweWPrzelocie.ok then
     begin
         if (MozliweWPrzelocie.Z=DaneBoard[PolePlansza.X, PolePlansza.Y].pole) and
            (MozliweWPrzelocie.NA=ZnajdzPolebyXY(X,Y)) then
            begin
               z:=ZnajdzIJbyPole(MozliweWPrzelocie.bite);
               Board[z.x,z.y]:=nil;
            end;
         MozliweWPrzelocie.ok:=false;
     end;

    ZapiszRuch(DaneBoard[PolePlansza.X, PolePlansza.Y].pole, ZnajdzPolebyXY(X,Y), Board[KolorowanieRuchu.Na.x,KolorowanieRuchu.Na.y].rodzaj, Board[KolorowanieRuchu.Na.x,KolorowanieRuchu.Na.y].kolor, '');

    //sprawdzamy czy mat albo pat !!!!!!!!!!!!!!!!!
    if CzyMat(KogoRuch)=true then
       begin
          ShowMessage('MAT');
       end;

    if CzyPat(KogoRuch)=true then
    begin
       ShowMessage('PAT');
    end;

    if CzyRemis=true then
    begin
       ShowMessage('REMIS!');
    end;

end
else
begin

     DadBierka^.pole:=DaneBoard[PolePlansza.X, PolePlansza.Y].pole;
     DadBierka^.pozycja := ZnajdzXYbyPole(DadBierka^.pole);

end;

  memo1.lines.add('Ruch: '+DaneBoard[PolePlansza.X, PolePlansza.Y].pole+' na '+ZnajdzPolebyXY(X,Y));



  DAD:=false;
  SetLength(TablicaRuchow, 0);

 end;

   PaintBox1.Invalidate;

end;



{-----  PREZENTACJA  -----}

procedure TForm1.PaintBox1Paint(Sender: TObject);
var
  i,j,a:integer;
  Punkt:TPoint;
  white:boolean;
  t:TRect;
  pole:TPoint;
begin


{--- rysowanie planszy ---}

white:=false;

 PaintBox1.Canvas.Pen.Color := clWhite;


for i:=0 to 7 do
begin

          if white then
          begin
              white:=false;
          end
          else
          begin
               white:=true;
          end;

                    for j:=0 to 7 do
                    begin

                         t.Left:=(80*j);
                         t.Top:=(80*i);
                         t.Right:=(80*j)+81;
                         t.Bottom:=(80*i)+81;

                                              if white then
                                              begin
                                                PaintBox1.Canvas.brush.Color := cl3DLight;
                                              end
                                              else
                                              begin
                                                PaintBox1.Canvas.brush.Color := clAppWorkspace;
                                               end;

                          PaintBox1.Canvas.rectangle(t);

                          if white then
                          begin
                          white:=false;
                          end
                          else
                          begin
                          white:=true;
                          end;


                    end;
end;


{ --- kolorujemy ostatni ruch na planszy --- }

if KolorowanieRuchu.ok then
begin

 PaintBox1.Canvas.brush.Color:=clMoneyGreen;

 t.Left:=(80*(KolorowanieRuchu.Z.y-1));
 t.Top:=(80*(KolorowanieRuchu.Z.x-1));
 t.Right:=(80*(KolorowanieRuchu.Z.y-1))+81;
 t.Bottom:=(80*(KolorowanieRuchu.Z.x-1))+81;

 PaintBox1.Canvas.rectangle(t);

  PaintBox1.Canvas.brush.Color:=$009FCA9F;   //clGreen;

 t.Left:=(80*(KolorowanieRuchu.NA.y-1));
 t.Top:=(80*(KolorowanieRuchu.NA.x-1));             //optymalizacja - zrobic to odejmowanie
 t.Right:=(80*(KolorowanieRuchu.NA.y-1))+81;         //przy tworzeniu KolorowanieRuchu
 t.Bottom:=(80*(KolorowanieRuchu.NA.x-1))+81;

 PaintBox1.Canvas.rectangle(t);

end;

{--- rysujemy mozliwe ruchy jezeli takie sa---}

if Length(TablicaRuchow)>0 then
begin

     for a:=0 to Length(TablicaRuchow)-1 do
     begin
           pole:=ZnajdzIJbyPole(TablicaRuchow[a]);

           PaintBox1.Canvas.brush.Color:=$00AAFFFF;

            t.Left:=(80*(pole.y-1));
            t.Top:=(80*(pole.x-1));
            t.Right:=(80*(pole.y-1))+81;
            t.Bottom:=(80*(pole.x-1))+81;

             PaintBox1.Canvas.rectangle(t);
     end;

end;

PaintBox1.Canvas.Pen.Color := clBlack;

     PaintBox1.Canvas.MoveTo(0,0);
     PaintBox1.Canvas.LineTo(640,0);

     PaintBox1.Canvas.MoveTo(640,0);
     PaintBox1.Canvas.LineTo(640,640);

     PaintBox1.Canvas.MoveTo(0,0);
     PaintBox1.Canvas.LineTo(0,640);

     PaintBox1.Canvas.MoveTo(0,640);
     PaintBox1.Canvas.LineTo(640,640);


{----    rysowanie figur -----}

      with PaintBox1.Canvas do
   begin
   for i:=1 to 8 do
   begin
       for j:=1 to 8 do
       begin
       if Board[i,j]<>nil then begin
             Draw(Board[i,j].pozycja.X+5, Board[i,j].pozycja.Y+5, Board[i,j].obraz);
       end;
       end;
       end;
   end;


end;


end.
