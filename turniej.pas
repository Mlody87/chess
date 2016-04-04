unit turniej;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids, logi;

type

  { TForm2 }

  TForm2 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    gracze_tabela: TStringGrid;
    LDystans: TLabel;
    LGracze: TLabel;
    LRundy: TLabel;
    LPula: TLabel;
    LWpisowe: TLabel;
    LNazwa: TLabel;
    LOpis: TMemo;
    Szczegoly: TGroupBox;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
        loger:TLogi;
  public
    { public declarations }
    procedure WypiszSzczegoly(idTurnieju:string);
    procedure Komunikat(kom:string);
    procedure WypiszGraczy(lis:string);
    procedure PokazForme;
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}
uses Unit1;

{ TForm2 }

procedure TForm2.PokazForme;
begin
Self.Show;
end;

procedure TForm2.WypiszGraczy(lis:string);
var
  i:integer;
  odczyt:TStrings;
begin

odczyt:=TStringList.Create;
ExtractStrings(['|'], [], PAnsiChar(lis), odczyt);

for i:=1 to (odczyt.Count div 2)-1 do
begin
gracze_tabela.RowCount:=gracze_tabela.RowCount+1;
gracze_tabela.Cells[0,i]:=odczyt[i*2];
gracze_tabela.Cells[1,i]:=odczyt[i*2+1];
gracze_tabela.Cells[2,i]:='0';
end;

end;

procedure TForm2.Komunikat(kom:string);
begin

end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  gracze_tabela.ColCount:=3;
gracze_tabela.RowCount:=1;
gracze_tabela.Cells[0,0]:='Nick';
gracze_tabela.Cells[1,0]:='Ranking';
gracze_tabela.Cells[2,0]:='Punkty';
gracze_tabela.ColWidths[0]:=120;
gracze_tabela.ColWidths[1]:=50;
gracze_tabela.ColWidths[1]:=50;

loger:=TLogi.Create;

end;

procedure TForm2.WypiszSzczegoly(IdTurnieju:string);
var
  i:integer;
begin


for i:=0 to Length(turnieje)-1 do
begin

  if IdTurnieju=turnieje[i].id then
  begin
      LNazwa.Caption:=turnieje[i].nazwa;
      LOpis.Caption:=turnieje[i].opis;
      LWpisowe.Caption:='Wpisowe: '+turnieje[i].wpisowe+' +'+turnieje[i].prowizja;
      LPula.Caption:='Pula: ';       // TO DO - policzyc pule
      LDystans.Caption:='Dystans: '+turnieje[i].dystans;
      LRundy.Caption:=turnieje[i].ile_rund+' rund';
      LGracze.Caption:='Zapisanych'; //TO DO - policzyc z kolejnych komunikatow

      //TForm2.Caption:='Turniej '+IdTurnieju+' - '+turnieje[i].nazwa;
      Break;
  end;

end;

end;

end.

