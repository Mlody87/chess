unit rejestracja;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFRejestracja }

  TFRejestracja = class(TForm)
    BRejestracja: TButton;
    EEmail: TEdit;
    EHaslo: TEdit;
    ELogin: TEdit;
    LErrorrejestracja: TLabel;
    Lemail: TLabel;
    LHaslo: TLabel;
    LLogin: TLabel;
    procedure BRejestracjaClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FRejestracja: TFRejestracja;

implementation

uses Unit1;

{$R *.lfm}

{ TFRejestracja }

procedure TFRejestracja.BRejestracjaClick(Sender: TObject);
var
s:string;
begin
  s:='002|'+ELogin.Text+'|'+EHaslo.Text+'|'+EEmail.Text+'|'+idGniazda;
    Form1.klient.SendMessage(s);

end;

end.

