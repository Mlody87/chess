unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, types;

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

  TMapaRuchow=array of string;

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
    function SprawdzKrolaBialego(pole:TPoint; na:string):boolean;
    function SprawdzKrolaCzarnego(pole:TPoint; na:string):boolean;
    function MozliweRuchy(WyjsciowePole:string):TMapaRuchow;
    function CzyLegalnyRuch(NaPole:string):boolean;
    function ZapiszRuch(Z,Na,Uwagi:string):boolean;
    function OdswiezPrzebieg:boolean;
    function WykonajRuch(Z,Na,Uwagi:string):boolean;
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

  Board : array[1..8,1..8] of TBierka;
  DaneBoard : array[1..8,1..8] of TDaneBoard;

  GramKolorem:string;

  DAD:boolean;
  DadBierka:^TBierka;

  PunktPlansza,PolePlansza:TPoint;

  KogoRuch:string;

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

Board[b.x,b.y]:=Board[a.x,a.y];

Board[b.x,b.y].pole:=Na;
Board[b.x,b.y].pozycja := ZnajdzXYbyPole(Na);

Board[a.x,a.y]:=nil;

if KogoRuch='biale' then KogoRuch:='czarne'
else KogoRuch:='biale';

KolorowanieRuchu.ok:=true;
KolorowanieRuchu.Z:=ZnajdzIJbyPole(Z);
KolorowanieRuchu.NA:=ZnajdzIJbyPole(Na);

ZapiszRuch(Z,Na,'');

PaintBox1.Invalidate;

end;

function TForm1.OdswiezPrzebieg:boolean;
var
i:integer;
begin

for i:=1 to Przebieg.RowCount-1 do
Przebieg.Rows[i].Clear;

Przebieg.RowCount:=Przebieg.RowCount+1;

for i:=0 to Length(PrzebiegPartii)-1 do
begin
    Przebieg.Cells[0,i]:=IntToStr(i+1);
    Przebieg.Cells[1,i]:=PrzebiegPartii[i].Z;
    Przebieg.Cells[2,i]:=PrzebiegPartii[i].Na;
end;

end;

function TForm1.ZapiszRuch(Z,Na,Uwagi:string):boolean;
var
pole:TPoint;
begin
pole:=ZnajdzIJbyPole(Z);

SetLength(PrzebiegPartii, Length(PrzebiegPartii)+1);
PrzebiegPartii[High(PrzebiegPartii)].figura:=Board[pole.X, pole.Y].rodzaj;
PrzebiegPartii[High(PrzebiegPartii)].figura:=Board[pole.X, pole.Y].kolor;
PrzebiegPartii[High(PrzebiegPartii)].Z:=Z;
PrzebiegPartii[High(PrzebiegPartii)].NA:=Na;
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
begin

pole:=ZnajdzIJbyPole(WyjsciowePole);
kolor:=Board[pole.X, pole.Y].kolor;
bierka:=Board[pole.X, pole.Y].rodzaj;

{SPRAWDZAMY MOZLIWE RUCHY DLA WIEZY}

if bierka = 'wieza' then
 begin

      for i:=1 to 8 do {na prawo do bierki}
         begin

               if pole.Y+i<=8 then
                begin
                     if Board[pole.X, pole.Y+i]=nil then
                      begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+i].kolor = kolor then begin Break; end
                           else
                            begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-i].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X+i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X-i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                              Break;
                            end;
                     end;
                end;
         end;

      Result:=ruchy;

 end;

{SPRAWDZAMY MOZLIWE RUCHY DLA PIONA}   //bedzie sprawdzanie tylko dla gracza na dole    !!!
                                       //ale teraz musi byc tez dla czarnych!!!!!!!
if bierka = 'pion' then        //dorobic potem bicie w przelocie
 begin
      {sprawdzamy ruch piona}

      if KogoRuch='biale' then
       begin

            if Board[pole.X-1, pole.Y]=nil then
            begin
                 SetLength(ruchy, Length(ruchy)+1);
                 ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
            end;

            if pole.X=7 then  //pierwszy ruch, mozna o dwa, sprawdzamy
            begin

                       if Board[pole.X-2, pole.Y]=nil then
                       begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y].pole;
                       end;

            end;

       {sprawdzamy bicie piona}
            if (pole.X-1>=1) and (pole.Y-1>=1) then    //bicie w lewo
            begin
                if Board[pole.X-1, pole.Y-1]<>nil then
                begin
                    if Board[pole.X-1, pole.Y-1].kolor<>kolor then
                    begin
                         SetLength(ruchy, Length(ruchy)+1);
                         ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
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
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
             end;
         end;
     end;

     {tymczasowo sprawdzamy dla czarnych}
     if KogoRuch='czarne' then
     begin


     if Board[pole.X+1, pole.Y]=nil then
            begin
                 SetLength(ruchy, Length(ruchy)+1);
                 ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y].pole;
            end;

            if pole.X=2 then  //pierwszy ruch, mozna o dwa, sprawdzamy
            begin

                       if Board[pole.X+2, pole.Y]=nil then
                       begin
                            SetLength(ruchy, Length(ruchy)+1);
                            ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y].pole;
                       end;

            end;

       {sprawdzamy bicie piona}
            if (pole.X+1<=8) and (pole.Y-1>=1) then    //bicie w lewo
            begin
                if Board[pole.X+1, pole.Y-1]<>nil then
                begin
                    if Board[pole.X+1, pole.Y-1].kolor<>kolor then
                    begin
                         SetLength(ruchy, Length(ruchy)+1);
                         ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-1].pole;
                    end;
                end;
            end;

     if (pole.X+1<=8) and (pole.Y+1<=8) then    //bicie w prawo
     begin
         if Board[pole.X+1, pole.Y+1]<>nil then
         begin
             if Board[pole.X+1, pole.Y+1].kolor<>kolor then
             begin
                  SetLength(ruchy, Length(ruchy)+1);
                  ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+1].pole;
             end;
         end;
     end;

     end;  //koniec sprawdzania dla czarnych

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
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
      end
      else
      begin
         if Board[pole.X-i, pole.Y-i].kolor=kolor then begin Break; end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y+i)>8) then Break;

      if Board[pole.X-i, pole.Y+i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
      end
      else
      begin
         if Board[pole.X-i, pole.Y+i].kolor=kolor then begin Break; end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w lewy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y-i)<1) then Break;

      if Board[pole.X+i, pole.Y-i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
      end
      else
      begin
         if Board[pole.X+i, pole.Y-i].kolor=kolor then begin Break end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y+i)>8) then Break;

      if Board[pole.X+i, pole.Y+i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
      end
      else
      begin
         if Board[pole.X+i, pole.Y+i].kolor=kolor then begin Break end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
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
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+2].pole;
        end
        else
        begin
           if Board[pole.X+1, pole.Y+2].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+2].pole;
           end;
        end;
    end;


    if ((pole.X-1>=1) and (pole.Y-2>=1)) then
    begin
        if Board[pole.X-1, pole.Y-2]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-2].pole;
        end
        else
        begin
           if Board[pole.X-1, pole.Y-2].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-2].pole;
           end;
        end;
    end;


    if ((pole.X+2<=8) and (pole.Y+1<=8)) then
    begin
        if Board[pole.X+2, pole.Y+1]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y+1].pole;
        end
        else
        begin
           if Board[pole.X+2, pole.Y+1].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y+1].pole;
           end;
        end;
    end;


    if ((pole.X-2>=1) and (pole.Y+1<=8)) then
    begin
        if Board[pole.X-2, pole.Y+1]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y+1].pole;
        end
        else
        begin
           if Board[pole.X-2, pole.Y+1].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y+1].pole;
           end;
        end;
    end;


    if ((pole.X+1<=8) and (pole.Y-2>=1)) then
    begin
        if Board[pole.X+1, pole.Y-2]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-2].pole;
        end
        else
        begin
           if Board[pole.X+1, pole.Y-2].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-2].pole;
           end;
        end;
    end;


    if ((pole.X-1>=1) and (pole.Y+2<=8)) then
    begin
        if Board[pole.X-1, pole.Y+2]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+2].pole;
        end
        else
        begin
           if Board[pole.X-1, pole.Y+2].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+2].pole;
           end;
        end;
    end;


    if ((pole.X+2<=8) and (pole.Y-1>=1)) then
    begin
        if Board[pole.X+2, pole.Y-1]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y-1].pole;
        end
        else
        begin
           if Board[pole.X+2, pole.Y-1].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X+2, pole.Y-1].pole;
           end;
        end;
    end;


    if ((pole.X-2>=1) and (pole.Y-1>=1))then
    begin
        if Board[pole.X-2, pole.Y-1]=nil then
        begin
            SetLength(ruchy, Length(ruchy)+1);
            ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y-1].pole;
        end
        else
        begin
           if Board[pole.X-2, pole.Y-1].kolor<>kolor then
           begin
               SetLength(ruchy, Length(ruchy)+1);
               ruchy[High(ruchy)]:=DaneBoard[pole.X-2, pole.Y-1].pole;
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
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
      end
      else
      begin
         if Board[pole.X-i, pole.Y-i].kolor=kolor then begin Break; end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y-i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy gorny rog}
   begin
      if ((pole.X-i)<1) or ((pole.Y+i)>8) then Break;

      if Board[pole.X-i, pole.Y+i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
      end
      else
      begin
         if Board[pole.X-i, pole.Y+i].kolor=kolor then begin Break; end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y+i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w lewy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y-i)<1) then Break;

      if Board[pole.X+i, pole.Y-i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
      end
      else
      begin
         if Board[pole.X+i, pole.Y-i].kolor=kolor then begin Break end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y-i].pole;
              Break;
         end;
      end;

   end;

   for i:=1 to 8 do    {w prawy dolny rog}
   begin
      if ((pole.X+i)>8) or ((pole.Y+i)>8) then Break;

      if Board[pole.X+i, pole.Y+i]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
      end
      else
      begin
         if Board[pole.X+i, pole.Y+i].kolor=kolor then begin Break end
         else
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y+i].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+i].kolor = kolor then begin Break; end
                           else
                            begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+i].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-i].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-i].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X+i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X+i, pole.Y].pole;
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
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X-i, pole.Y].kolor = kolor then begin Break; end
                           else
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X-i, pole.Y].pole;
                              Break;
                            end;
                     end;
                end;
         end;

 {------------------------}

 result:=ruchy;

   end;

{SPRAWDZAMY MOZLIWE RUCHY DLA KROLA}

if bierka = 'krol' then        {dorobic roszade}
 begin

  {-- ruchy wiezy - pionowo poziomo --}

               if pole.Y+1<=8 then
                begin
                     if Board[pole.X, pole.Y+1]=nil then
                      begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+1].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y+1].kolor <> kolor then
                            begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y+1].pole;
                            end;
                     end;
                end;


               if pole.Y-1>=1 then
                begin
                     if Board[pole.X, pole.Y-1]=nil then
                      begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-1].pole;
                      end
                     else
                     begin
                           if Board[pole.X, pole.Y-1].kolor <> kolor then
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X, pole.Y-1].pole;
                            end;
                     end;
                end;


               if pole.X+1<=8 then
                begin
                     if Board[pole.X+1, pole.Y]=nil then
                      begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X+1, pole.Y].kolor <> kolor then
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y].pole;
                            end;
                     end;
                end;



               if pole.X-1>=1 then
                begin
                     if Board[pole.X-1, pole.Y]=nil then
                      begin
                           SetLength(ruchy, Length(ruchy)+1);
                           ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
                      end
                     else
                     begin
                           if Board[pole.X-1, pole.Y].kolor <> kolor then
                           begin
                              SetLength(ruchy, Length(ruchy)+1);
                              ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y].pole;
                            end;
                     end;
                end;

  {-----------------------------------}

  {-- ruchy gonca - po skosie --}


      if ((pole.X-1)>=1) and ((pole.Y-1)>=1) then begin

      if Board[pole.X-1, pole.Y-1]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
      end
      else
      begin
         if Board[pole.X-1, pole.Y-1].kolor<>kolor then
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y-1].pole;
         end;
      end;
      end;


      if ((pole.X-1)>=1) and ((pole.Y+1)<=8) then begin

      if Board[pole.X-1, pole.Y+1]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
      end
      else
      begin
         if Board[pole.X-1, pole.Y+1].kolor<>kolor then
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X-1, pole.Y+1].pole;
         end;
      end;

   end;


      if ((pole.X+1)<=8) and ((pole.Y-1)>=1) then
      begin

      if Board[pole.X+1, pole.Y-1]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-1].pole;
      end
      else
      begin
         if Board[pole.X+1, pole.Y-1].kolor<>kolor then
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y-1].pole;
         end;
      end;

        end;


      if ((pole.X+1)<=8) and ((pole.Y+1)<=8) then begin

      if Board[pole.X+1, pole.Y+1]=nil then
      begin
         SetLength(ruchy, Length(ruchy)+1);
         ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+1].pole;
      end
      else
      begin
         if Board[pole.X+1, pole.Y+1].kolor<>kolor then
         begin
              SetLength(ruchy, Length(ruchy)+1);
              ruchy[High(ruchy)]:=DaneBoard[pole.X+1, pole.Y+1].pole;
         end;
      end;

   end;

  {-----------------------------------}

    result:=ruchy;

 end;

end;


function TForm1.SprawdzKrolaBialego(pole:TPoint; na:string):boolean; //true - nie atakowany, false - atakowany
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
WszystkoOK:=true;

tmp:=tmpBoard[pole.X,pole.Y];
tmpBoard[pole.X,pole.Y]:=nil;
punkt:=znajdzIJbyPole(na);
tmpBoard[punkt.X,punkt.Y]:=tmp;

for i:=1 to 8 do
for j:=1 to 8 do
  if TmpBoard[i,j]<>nil then begin if (tmpBoard[i,j].rodzaj='krol') and (tmpBoard[i,j].kolor='biale') then PozycjaKrola:=Point(i,j); end;


for i:=1 to 8 do
begin
   if PozycjaKrola.X+i>8 then Break;

   if Board[PozycjaKrola.X+i, PozycjaKrola.Y]<>nil then
   begin
       if Board[PozycjaKrola.X+i, PozycjaKrola.Y].kolor='czarne' then
       begin
       figura:=Board[PozycjaKrola.X+i, PozycjaKrola.Y].rodzaj;

           if (figura='krol') or (figura='hetman') or (figura='wieza') then
           begin
             wszystkoOK:=false;
           end
           else
           begin
             Break;
           end;
       end
       else
       begin
           Break;
       end;
   end;

end;

for i:=1 to 8 do
begin
   if PozycjaKrola.X-i<1 then Break;

   if Board[PozycjaKrola.X-i, PozycjaKrola.Y]<>nil then
   begin
       if Board[PozycjaKrola.X-i, PozycjaKrola.Y].kolor='czarne' then
       begin
       figura:=Board[PozycjaKrola.X-i, PozycjaKrola.Y].rodzaj;

           if (figura='krol') or (figura='hetman') or (figura='wieza') then
           begin
             wszystkoOK:=false;
           end
           else
           begin
             Break;
           end;
       end
       else
       begin
           Break;
       end;
   end;

end;

for i:=1 to 8 do
begin
   if PozycjaKrola.Y-i<1 then Break;

   if Board[PozycjaKrola.X, PozycjaKrola.Y-i]<>nil then
   begin
       if Board[PozycjaKrola.X, PozycjaKrola.Y-i].kolor='czarne' then
       begin
       figura:=Board[PozycjaKrola.X, PozycjaKrola.Y-i].rodzaj;

           if (figura='krol') or (figura='hetman') or (figura='wieza') then
           begin
             wszystkoOK:=false;
           end
           else
           begin
             Break;
           end;
       end
       else
       begin
           Break;
       end;
   end;

end;

for i:=1 to 8 do
begin
   if PozycjaKrola.Y+i>8 then Break;

   if Board[PozycjaKrola.X, PozycjaKrola.Y+i]<>nil then
   begin
       if Board[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='czarne' then
       begin
       figura:=Board[PozycjaKrola.X, PozycjaKrola.Y+i].rodzaj;

           if (figura='krol') or (figura='hetman') or (figura='wieza') then
           begin
             wszystkoOK:=false;
           end
           else
           begin
             Break;
           end;
       end
       else
       begin
           Break;
       end;
   end;

end;



{--jak goniec--}



for i:=1 to 8 do    {w lewy gorny rog}
   begin
      if ((PozycjaKrola.X-i)<1) or ((PozycjaKrola.Y-i)<1) then Break;

      if Board[PozycjaKrola.X-i, PozycjaKrola.Y-i]<>nil then
      begin
           if Board[PozycjaKrola.X-i, PozycjaKrola.Y-i].kolor='czarne' then
           begin
              figura:=Board[PozycjaKrola.X-i, PozycjaKrola.Y-i].rodzaj;

                if (figura='hetman') or (figura='goniec') or (figura='krol') then
                begin
                wszystkoOK:=false;
                end
                else
                begin
                  Break;
                end;

           end
           else
           begin
               Break;
           end;
      end;

   end;

   for i:=1 to 8 do    {w prawy gorny rog}
   begin
      if ((PozycjaKrola.X-i)<1) or ((PozycjaKrola.Y+i)>8) then Break;

      if Board[PozycjaKrola.X-i, PozycjaKrola.Y+i]<>nil then
      begin
           if Board[PozycjaKrola.X-i, PozycjaKrola.Y+i].kolor='czarne' then
           begin
              figura:=Board[PozycjaKrola.X-i, PozycjaKrola.Y+i].rodzaj;

                if (figura='hetman') or (figura='goniec') or (figura='krol') then
                begin
                wszystkoOK:=false;
                end
                else
                begin
                  Break;
                end;

           end
           else
           begin
               Break;
           end;
      end;

   end;


   for i:=1 to 8 do    {w lewy dolny rog}
   begin
      if ((PozycjaKrola.X+i)>8) or ((PozycjaKrola.Y-i)<1) then Break;

      if Board[PozycjaKrola.X+i, PozycjaKrola.Y-i]<>nil then
      begin
           if Board[PozycjaKrola.X+i, PozycjaKrola.Y-i].kolor='czarne' then
           begin
              figura:=Board[PozycjaKrola.X+i, PozycjaKrola.Y-i].rodzaj;

                if (figura='hetman') or (figura='goniec') or (figura='krol') then
                begin
                wszystkoOK:=false;
                end
                else
                begin
                  Break;
                end;

           end
           else
           begin
               Break;
           end;

      end;

   end;


   for i:=1 to 8 do    {w prawy dolny rog}
   begin
      if ((PozycjaKrola.X+i)>8) or ((PozycjaKrola.Y+i)>8) then Break;

      if Board[PozycjaKrola.X+i, PozycjaKrola.Y+i]<>nil then
      begin
           if Board[PozycjaKrola.X+i, PozycjaKrola.Y+i].kolor='czarne' then
           begin
              figura:=Board[PozycjaKrola.X+i, PozycjaKrola.Y+i].rodzaj;

                if (figura='hetman') or (figura='goniec') or (figura='krol') then
                begin
                wszystkoOK:=false;
                end
                else
                begin
                  Break;
                end;

            end
           else
           begin
               Break;
           end;

      end;

   end;

   {--sprawdzamy pionki--}

if ((PozycjaKrola.X-1)>=1) or ((PozycjaKrola.Y+1)<=8) then
begin

if Board[PozycjaKrola.X-1, PozycjaKrola.Y+1]<>nil then
begin
   if (Board[PozycjaKrola.X-1, PozycjaKrola.Y+1].rodzaj='pion') and (Board[PozycjaKrola.X-1, PozycjaKrola.Y+1].kolor='czarne') then wszystkoOK:=false;
end;

end;

if ((PozycjaKrola.X-1)>=1) or ((PozycjaKrola.Y-1)>=1) then
begin

if Board[PozycjaKrola.X-1, PozycjaKrola.Y-1]<>nil then
begin
   if (Board[PozycjaKrola.X-1, PozycjaKrola.Y-1].rodzaj='pion') and (Board[PozycjaKrola.X-1, PozycjaKrola.Y-1].kolor='czarne') then wszystkoOK:=false;
end;

end;

Result:=WszystkoOK;

end;



   function TForm1.SprawdzKrolaCzarnego(pole:TPoint; na:string):boolean;
var
tmpBoard : array[1..8,1..8] of TBierka;
tmp:TBierka;
punkt:TPoint;
i,j:integer;
PozycjaKrola:TPoint;
WszystkoOK:boolean;
begin
tmpBoard:=Board;
WszystkoOK:=true;

tmp:=tmpBoard[pole.X,pole.Y];
tmpBoard[pole.X,pole.Y]:=nil;
punkt:=znajdzIJbyPole(na);
tmpBoard[punkt.X,punkt.Y]:=tmp;

for i:=1 to 8 do
for j:=1 to 8 do
  if TmpBoard[i,j]<>nil then begin if (tmpBoard[i,j].rodzaj='krol') and (tmpBoard[i,j].kolor='czarne') then PozycjaKrola:=Point(i,j); end;


 //Sprawdzamy w pionie w gore

for i:=1 to 8 do
  begin

    if PozycjaKrola.X-i<1 then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y]<>nil then begin  if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end; //sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y].rodzaj='wieza') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

   //Sprawdzamy w pionie w dol

for i:=1 to 8 do
  begin

    if PozycjaKrola.X+i>8 then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y]<>nil then begin  if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end; //sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y]<>nil then begin  if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y].rodzaj='wieza') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y]<>nil then begin  if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;


//Sprawdzamy w Poziomie w Prawo

for i:=1 to 8 do
  begin

    if PozycjaKrola.Y+i>8 then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i]<>nil then begin  if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end; //sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i]<>nil then begin  if (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].rodzaj='wieza') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i]<>nil then begin  if (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

//Sprawdzamy w Poziomie w Lewo

for i:=1 to 8 do
  begin

    if PozycjaKrola.Y-i<1 then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i]<>nil then begin  if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end;//sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i].rodzaj='wieza') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y-i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

  //Sprawdzamy po skosie w dol w prawo

for i:=1 to 8 do
  begin

    if (PozycjaKrola.X+i>8) or (PozycjaKrola.Y+i>8) then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i]<>nil then begin  if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end;//sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i]<>nil then begin  if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i].rodzaj='goniec') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i]<>nil then begin if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y+i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

    //Sprawdzamy po skosie w gore w prawo

for i:=1 to 8 do
  begin

    if (PozycjaKrola.X-i<1) or (PozycjaKrola.Y+i>8) then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i]<>nil then begin  if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end;//sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i].rodzaj='goniec') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y+i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

      //Sprawdzamy po skosie w dol w lewo

for i:=1 to 8 do
  begin

    if (PozycjaKrola.X+i>8) or (PozycjaKrola.Y-i<1) then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i]<>nil then begin  if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end;//sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i].rodzaj='goniec') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X+i, PozycjaKrola.Y-i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

        //Sprawdzamy po skosie w gore w lewo

for i:=1 to 8 do
  begin

    if (PozycjaKrola.X-i<1) or (PozycjaKrola.Y-i<1) then begin Break; end
    else
    begin

    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i]<>nil then begin  if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i].rodzaj='krol' then begin WszystkoOK:=false; Break; end; end;//sprawdzamy czy wchodzi pod krola
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i].rodzaj='goniec') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    if tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i]<>nil then begin  if (tmpBoard[PozycjaKrola.X-i, PozycjaKrola.Y-i].rodzaj='hetman') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; Break; end; end;
    end;

  end;

//sprawdzamy czy nie atakuje skoczek

if (tmpBoard[PozycjaKrola.X+1, PozycjaKrola.Y+2]<>nil) then begin if (tmpBoard[PozycjaKrola.X+1, PozycjaKrola.Y+2].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X-1, PozycjaKrola.Y-2]<>nil) then begin if (tmpBoard[PozycjaKrola.X-1, PozycjaKrola.Y+2].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X+2, PozycjaKrola.Y+1]<>nil) then begin if (tmpBoard[PozycjaKrola.X+2, PozycjaKrola.Y+1].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X-2, PozycjaKrola.Y+1]<>nil) then begin if (tmpBoard[PozycjaKrola.X-2, PozycjaKrola.Y+1].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X+1, PozycjaKrola.Y-2]<>nil) then begin if (tmpBoard[PozycjaKrola.X+1, PozycjaKrola.Y-2].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X-1, PozycjaKrola.Y-2]<>nil) then begin if (tmpBoard[PozycjaKrola.X-1, PozycjaKrola.Y-2].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X+2, PozycjaKrola.Y-1]<>nil) then begin if (tmpBoard[PozycjaKrola.X+2, PozycjaKrola.Y-1].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;
if (tmpBoard[PozycjaKrola.X-2, PozycjaKrola.Y-1]<>nil) then begin if (tmpBoard[PozycjaKrola.X-2, PozycjaKrola.Y-1].rodzaj='skoczek') and (tmpBoard[PozycjaKrola.X, PozycjaKrola.Y+i].kolor='biale') then begin WszystkoOK:=false; end; end;

Result:=WszystkoOK;
//stworzenie roboczej tabeli i sprawdzenie czy po nowym ruchu nie bedzie atakowany czarny krol po ruchu czarnych
end;


{--------------------------------------------------------------------------------------}

procedure TForm1.FormCreate(Sender: TObject);
var
  i,j,a,NumerPola,obraz:integer;
  kolor:string;
begin

KolorowanieRuchu.ok:=false;
KolorowanieKrola.ok:=false;
KogoRuch:='biale';

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
begin
  WykonajRuch(Edit1.Text,Edit2.Text,Edit3.Text);
end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i,j:integer;
  pol:string;
begin

pol:=ZnajdzPolebyXY(X,Y);
Memo1.Lines.add(pol);
memo1.lines.add('X: '+inttostr(X)+', Y: '+inttostr(Y));

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
  tmp:TBierka;
  okKrol,okRuch:boolean;
begin
okKrol:=true;
okRuch:=false;

 if DAD then
 begin


  DadBierka^.pole:=ZnajdzPolebyXY(X,Y);
  DadBierka^.pozycja := ZnajdzXYbyPole(ZnajdzPolebyXY(X,Y));


if KogoRuch='biale' then
   okKrol:=SprawdzKrolaBialego(PolePlansza, ZnajdzPolebyXY(X,Y));

okRuch:=CzyLegalnyRuch(ZnajdzPolebyXY(X,Y));

if (okKrol=true) and (okRuch=true) then
begin

     tmp:=DadBierka^;
     Board[PolePlansza.X, PolePlansza.Y] := nil;
     Board[(Y div 80)+1,(X div 80)+1] := tmp;

     if KogoRuch='biale' then KogoRuch:='czarne'
     else KogoRuch:='biale';

     KolorowanieRuchu.ok:=true;
     KolorowanieRuchu.Z:=PolePlansza;
     KolorowanieRuchu.NA:=Point((Y div 80)+1,(X div 80)+1);


end
else
begin

     DadBierka^.pole:=DaneBoard[PolePlansza.X, PolePlansza.Y].pole;
     DadBierka^.pozycja := ZnajdzXYbyPole(DadBierka^.pole);

end;

  memo1.lines.add('Ruch: '+DaneBoard[PolePlansza.X, PolePlansza.Y].pole+' na '+ZnajdzPolebyXY(X,Y));

  ZapiszRuch(DaneBoard[PolePlansza.X, PolePlansza.Y].pole, ZnajdzPolebyXY(X,Y), '');

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

if GramKolorem='biale' then
begin
white:=false;
end
else
begin
white:=true;
end;


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
