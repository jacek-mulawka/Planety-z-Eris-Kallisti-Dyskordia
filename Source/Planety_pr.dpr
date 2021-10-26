program Planety_pr;

{$I Definicje.inc}

uses
  Vcl.Forms,
  {$IFDEF si_fann_u¿ywaj}
  FANN in 'FANN\FANN.pas',
  FannNetwork in 'FANN\FannNetwork.pas',
  {$ENDIF}
  Planety in 'Planety.pas' {Planety_Form},
  Statystyki in 'Statystyki.pas' {Statystyki_Form};

{$R *.res}

begin

  //???ReportMemoryLeaksOnShutdown := DebugHook <> 0;

  Application.Initialize();
  Application.MainFormOnTaskbar := True;
  Application.HintHidePause := 30000;
  Application.CreateForm( TPlanety_Form, Planety_Form );
  Application.Run();

end.
