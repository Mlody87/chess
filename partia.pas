unit partia;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

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

  { TForm3 }

  TForm3 = class(TForm)
    ECzasBiale: TEdit;
    ECzasCzarne: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    PaintBox1: TPaintBox;
    TimerCzasBiale: TTimer;
    TimerCzasCzarne: TTimer;

  procedure FormCreate(Sender: TObject);
  procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
  procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
    Y: Integer);
  procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
  procedure PaintBox1Paint(Sender: TObject);
  function ZnajdzXYbyPole(poz:string):TPoint;
  function ZnajdzPolebyXY(X,Y:integer):string;
  function ZnajdzXYbyIJ(i,j:integer):TPoint;

  private
    { private declarations }
      GramKolorem:string;
    BialeCzas:integer;
    CzarneCzas:integer;
    KogoRuch:string;
    start:boolean;
    id_partii:integer;


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

function TForm3.ZnajdzXYbyPole(poz:string):TPoint;
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

function TForm3.ZnajdzPolebyXY(X,Y:integer):string;
var
  a,b:integer;
begin

a:=(X div 80)+1;
b:=(Y div 80)+1;

Result:=DaneBoard[b,a].pole;
end;

function TForm3.ZnajdzXYbyIJ(i,j:integer):TPoint;
begin
Result:=Point(DaneBoard[i,j].X, DaneBoard[i,j].Y);
end;

function TForm3.ZnajdzIJbyPole(pole:string):TPoint;
var
i,j:integer;
begin

for i:=1 to 8 do
for j:=1 to 8 do
  if DaneBoard[i,j].pole=pole then Return:=Point(i,j);
  
end;


{---------}

function TForm3.SprawdzRuch(Z:string, NA:string):boolean;
var
rodzaj:string;
pole:TPoint;
i,j:integer;
ok:boolean;
begin

pole:=ZnajdzIJbyPole(Z);

rodzaj:=Board[pole.X,pole.Y].rodzaj;

if rodzaj='pion' then
ok:=SprawdzRuchPiona(pole, NA);

if rodzaj='wieza' then
ok:=SprawdzRuchWiezy(pole, NA);

if rodzaj='skoczek' then
ok:=SprawdzRuchSkoczka(pole, NA);

if rodzaj='goniec' then
ok:=SprawdzRuchGonca(pole, NA);

if rodzaj='hetman' then
ok:=SprawdzRuchHetmana(pole, NA);

if rodzaj='krol' then
ok:=SprawdzRuchKrola(pole, NA);



end;

procedure TForm3.FormCreate(Sender: TObject);
var
  i,j,a,NumerPola,obraz:integer;
  kolor:string;
begin

//  GramKolorem := 'biale';


end;

procedure TForm3.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i,j:integer;
  pol:string;
begin

pol:=ZnajdzPolebyXY(X,Y);

  for i:=1 to 8 do
  for j:=1 to 8 do
  begin
   if Board[i,j]<>nil then
   begin
   if pol=Board[i,j].pole then
  begin
    DAD:=true;
    DadBierka:=@Board[i,j];
    PunktPlansza := Point(X, Y);
    PolePlansza:=Point(i,j);
    Break;
  end;

  end;

  end;

end;

procedure TForm3.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
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

procedure TForm3.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tmp:TBierka;
begin

 if DAD then
 begin


  DadBierka^.pole:=ZnajdzPolebyXY(X,Y);
  DadBierka^.pozycja := ZnajdzXYbyPole(ZnajdzPolebyXY(X,Y));

  tmp:=DadBierka^;
  Board[PolePlansza.X, PolePlansza.Y] := nil;
  Board[(Y div 80)+1,(X div 80)+1] := tmp;

//  memo1.lines.add('Ruch: '+DaneBoard[PolePlansza.X, PolePlansza.Y].pole+' na '+ZnajdzPolebyXY(X,Y));

  DAD:=false;
 end;

   PaintBox1.Invalidate;

end;

procedure TForm3.PaintBox1Paint(Sender: TObject);
var
  i,j:integer;
  Punkt:TPoint;
  white:boolean;
  t:TRect;
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

