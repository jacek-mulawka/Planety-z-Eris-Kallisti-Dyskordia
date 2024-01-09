unit Statystyki;{22.Cze.2021}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus, Vcl.Buttons;

type
  TStatystyki_Form = class( TForm )
    Przyciski_Panel: TPanel;
    Zwyciêstwo_Label: TLabel;
    Nastêpna_Misja_Button: TButton;
    Kontynuuj_Button: TButton;
    Pauza_Button: TButton;
    Rozegraj_Misjê_Jeszcze_Raz_Button: TButton;
    Stop_Button: TButton;
    Statystyki_Image: TImage;
    Odœwie¿anie_Timer: TTimer;
    Statystyki_PopupMenu: TPopupMenu;
    Wykres_Liniowy_MenuItem: TMenuItem;
    Wykres_S³upkowy_MenuItem: TMenuItem;
    Poziomy_Splitter: TSplitter;
    Pomoc_BitBtn: TBitBtn;
    procedure FormShow( Sender: TObject );
    procedure FormResize( Sender: TObject );
    procedure Odœwie¿anie_TimerTimer( Sender: TObject );
    procedure Pomoc_BitBtnClick( Sender: TObject );
  private
    { Private declarations }
    data_czas_zmiany_okna : TDateTime;
  public
    { Public declarations }
    czy_zwyciêstwo : boolean;
    id_grupa_zwyciêska : integer;
  end;

var
  Statystyki_Form: TStatystyki_Form;

implementation

uses
  System.DateUtils,
  System.Math,

  Planety;

{$R *.dfm}

//FormShow().
procedure TStatystyki_Form.FormShow( Sender: TObject );
begin

  //if    ( Statystyki_Form.Przyciski_Panel.Visible )
  if    ( czy_zwyciêstwo )
    and ( id_grupa_zwyciêska <> Planety.id_grupa_gracza_c ) then
    Rozegraj_Misjê_Jeszcze_Raz_Button.SetFocus();

end;//---//FormShow().

//FormResize().
procedure TStatystyki_Form.FormResize( Sender: TObject );
begin

  data_czas_zmiany_okna := Now();

  if Self.Tag = 0 then
    begin

      // Pierwsze wyœwietlenie okna odœwie¿a bez opóŸnienia.

      Self.Tag := 1;

      data_czas_zmiany_okna := System.DateUtils.IncHour( data_czas_zmiany_okna, -1 );

      Odœwie¿anie_TimerTimer( Sender );

    end
  else//if Self.Tag = 0 then
    begin

      Odœwie¿anie_Timer.Enabled := true;

    end;
  //---//if Self.Tag = 0 then

end;//---//FormResize().

//Odœwie¿anie_TimerTimer().
procedure TStatystyki_Form.Odœwie¿anie_TimerTimer( Sender: TObject );
const
  wykres_s³upek__szerokoœæ_l_c : integer = 5;
var
  i,
  j,
  zti,
  blok_szerokoœæ, // Szerokoœæ obszaru wykresu na osi x, któr¹ zajmuje jeden pomiar wszystkich grup wraz z odstêpem na koñcu.
  bloki_iloœæ_na_wykresie,
  rakiety_iloœæ_najwiêksza_wartoœæ,
  wykres_s³upek__x
    : integer;
  wykres_skalowanie_do_wysokoœci, // Przeskaluje wartoœci tak aby najwiêksza wartoœæ odpowiada³a wysokoœci wykresu.
  wykres_liniowy_skalowanie_do_szerokoœci
    : real;
  //zts : string;
  kolor_grupy : TColor;
begin

  //if System.DateUtils.SecondsBetween( Now(), data_czas_zmiany_okna ) < 1 then
  if System.DateUtils.MilliSecondsBetween( Now(), data_czas_zmiany_okna ) < Odœwie¿anie_Timer.Interval then
    Exit;

  Odœwie¿anie_Timer.Enabled := false;


  Statystyki_Image.Picture := nil;



  rakiety_iloœæ_najwiêksza_wartoœæ := 0;

  for i := 0 to Length( Planety_Form.statystyki_tabela_t ) - 1 do
    for j := 1 to Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1 do
      if rakiety_iloœæ_najwiêksza_wartoœæ < Planety_Form.statystyki_tabela_t[ i ][ j ] then
        rakiety_iloœæ_najwiêksza_wartoœæ := Planety_Form.statystyki_tabela_t[ i ][ j ];


  if Length( Planety_Form.statystyki_tabela_t ) > 0 then
    bloki_iloœæ_na_wykresie := Length( Planety_Form.statystyki_tabela_t[ 0 ] ) - 1 // Pierwsza wartoœæ to numer grupy.
  else//if    (  Length( Planety_Form.statystyki_tabela_t ) > 0 ) (...)
    bloki_iloœæ_na_wykresie := 0;


  if rakiety_iloœæ_najwiêksza_wartoœæ <> 0 then
    wykres_skalowanie_do_wysokoœci := ( Statystyki_Image.Height - 20 ) / rakiety_iloœæ_najwiêksza_wartoœæ
  else//if rakiety_iloœæ_najwiêksza_wartoœæ <> 0 then
    wykres_skalowanie_do_wysokoœci := 1;

  if wykres_skalowanie_do_wysokoœci < 0 then
    wykres_skalowanie_do_wysokoœci := 1;



  if bloki_iloœæ_na_wykresie <> 0 then
    wykres_liniowy_skalowanie_do_szerokoœci := ( Statystyki_Image.Width - 20 ) / bloki_iloœæ_na_wykresie
  else//if bloki_iloœæ_na_wykresie <> 0 then
    wykres_liniowy_skalowanie_do_szerokoœci := 1;

  if wykres_liniowy_skalowanie_do_szerokoœci < 0 then
    wykres_liniowy_skalowanie_do_szerokoœci := 1;



  Statystyki_Image.Canvas.Pen.Color := clWhite;
  Statystyki_Image.Canvas.Brush.Color := clRed;


  blok_szerokoœæ :=
    + wykres_s³upek__szerokoœæ_l_c * ( Length( Planety_Form.statystyki_tabela_t ) - 0  ) // Przesuniêcie bloku pomiarów zale¿nie od iloœci grup na liœcie.
    //+ wykres_s³upek__szerokoœæ_l_c; // Odstêp miêdzy pomiarami.
    + Round( wykres_s³upek__szerokoœæ_l_c * 0.5 ); // Odstêp miêdzy pomiarami.


  // Ile bloków zmieœci siê na wykresie.
  if blok_szerokoœæ <> 0 then
    i := System.Math.Floor( Statystyki_Image.Width / blok_szerokoœæ )
  else//if blok_szerokoœæ <> 0 then
    i := 1;


  if bloki_iloœæ_na_wykresie <= i then
    zti := 0 // Wszystkie bloki danych zmieszcz¹ siê na wykresie.
  else//if bloki_iloœæ_na_wykresie <= i then
    begin

      // Nie wszystkie bloki danych zmieszcz¹ siê na wykresie.

      zti := System.Math.Floor( bloki_iloœæ_na_wykresie / i );

    end;
  //---//if bloki_iloœæ_na_wykresie <= i then


  for i := 0 to Length( Planety_Form.statystyki_tabela_t ) - 1 do
    begin

      //Statystyki_Image.Canvas.Brush.Color :=
      kolor_grupy :=
           Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).X * 255 )
        or (  Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).Y * 255 ) shl 8  )
        or (  Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).Z * 255 ) shl 16  );

      //zts := 'grupa id ';

      wykres_s³upek__x :=
          10 // Margines z lewej strony.
        + i * wykres_s³upek__szerokoœæ_l_c; // Przesuniêcie pierwszego s³upka zale¿nie od kolejnoœci grup na liœcie.

      for j := 0 to Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1 do
        begin

          if j = 0 then
            begin

              //zts := zts + IntToStr( Planety_Form.statystyki_tabela_t[ i ][ j ] ) + ':';

              Statystyki_Image.Canvas.MoveTo( 10, Statystyki_Image.Height - 10 ); // Margines z lewej strony.

            end
          else//if j = 0 then
            begin

              //if j > 1 then
              //  zts := zts +
              //    ',';
              //
              //zts := zts +
              //  ' ' + IntToStr( Planety_Form.statystyki_tabela_t[ i ][ j ] );


              if    ( Wykres_S³upkowy_MenuItem.Checked )
                and ( Planety_Form.statystyki_tabela_t[ i ][ j ] > 0 ) then //???
                if   ( zti = 0 )
                  or (
                           ( zti <> 0 )
                       and (
                                ( j = 1 ) // Pierwszy i ostatni blok zawsze wyœwietla.
                             or (  j = Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1  ) // Pierwszy i ostatni blok zawsze wyœwietla.
                             or ( j mod zti = 0 )
                           )
                     ) then
                  begin

                    Statystyki_Image.Canvas.Brush.Color := kolor_grupy;

                    Statystyki_Image.Canvas.Rectangle( wykres_s³upek__x, Statystyki_Image.Height - 10, wykres_s³upek__x + wykres_s³upek__szerokoœæ_l_c, Statystyki_Image.Height - 10 - System.Math.Floor( Planety_Form.statystyki_tabela_t[ i ][ j ] * wykres_skalowanie_do_wysokoœci )  ); // % wzgldem najwiekszego pomiaru i wysokoœci rysowania //???


                    wykres_s³upek__x := wykres_s³upek__x + blok_szerokoœæ;

                  end;
                //---//if   ( zti = 0 ) (...)


              if    ( Wykres_Liniowy_MenuItem.Checked )
                and (
                         ( Planety_Form.statystyki_tabela_t[ i ][ j ] > 0 )
                      or ( // Aby dorysowaæ koniec linii do poziomu zera.
                               ( j > 2 )
                           and ( Planety_Form.statystyki_tabela_t[ i ][ j ] = 0 )
                           and ( Planety_Form.statystyki_tabela_t[ i ][ j - 1 ] > 0 )
                         )
                    ) then
                begin

                  Statystyki_Image.Canvas.Pen.Color := kolor_grupy;
                  Statystyki_Image.Canvas.Pen.Width := 3;
                  Statystyki_Image.Canvas.Brush.Color := clWhite;

                  Statystyki_Image.Canvas.LineTo(   10 + System.Math.Floor(  ( j - 0 ) * wykres_liniowy_skalowanie_do_szerokoœci  ), Statystyki_Image.Height - 10 - System.Math.Floor( Planety_Form.statystyki_tabela_t[ i ][ j ] * wykres_skalowanie_do_wysokoœci )   );

                  Statystyki_Image.Canvas.Pen.Color := clWhite;
                  Statystyki_Image.Canvas.Pen.Width := 1;

                end;
              //---//if    ( Wykres_Liniowy_MenuItem.Checked ) (...)

            end;
          //---//if j = 0 then

        end;
      //---//for j := 0 to Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1 do

      //Statystyki_Image.Canvas.Brush.Color := kolor_grupy;
      //Statystyki_Form.Statystyki_Image.Canvas.TextOut(  10, 50 + 20 * ( i + 1 ), zts  );
      //Statystyki_Form.Statystyki_Image.Canvas.TextOut(  10, 50 + 20 * ( i + 1 ), 'gr. nr: ' + IntToStr( Planety_Form.statystyki_tabela_t[ i ][ 0 ] )  );

    end;
  //---//for i := 0 to Length( Planety_Form.statystyki_tabela_t ) - 1 do


  Statystyki_Image.Canvas.Pen.Color := clBlack;
  Statystyki_Image.Canvas.Brush.Color := clWhite;

  Statystyki_Image.Canvas.TextOut( 25, 15, '      Rakiety utworzone / stracone | polecenia wydane' );
  Statystyki_Image.Canvas.TextOut(   25, 35, '      w misji: ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_utworzonych__misja )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_straconych__misja )  ) + ' | ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__polecenia_iloœæ__misja )  )   );
  Statystyki_Image.Canvas.TextOut(   25, 55, '      w grze: ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_utworzonych__gra )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_straconych__gra )  ) + ' | ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__polecenia_iloœæ__gra )  )   );


  // Wartoœci na osi Y z lewej strony.
  Statystyki_Image.Canvas.TextOut(   10, 10, Trim(  FormatFloat( '### ### ### ##0', rakiety_iloœæ_najwiêksza_wartoœæ )  )   );

  if rakiety_iloœæ_najwiêksza_wartoœæ > 3 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.25  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_iloœæ_najwiêksza_wartoœæ * 0.75 )  )   );

  if rakiety_iloœæ_najwiêksza_wartoœæ > 1 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.5  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_iloœæ_najwiêksza_wartoœæ * 0.5 )  )   );

  if rakiety_iloœæ_najwiêksza_wartoœæ > 3 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.75  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_iloœæ_najwiêksza_wartoœæ * 0.25 )  )   );

  Statystyki_Image.Canvas.TextOut( 10, Statystyki_Image.Height - 15, '0' );

  //Statystyki_Image.Canvas.TextOut(   10, 250, 'rakiety_iloœæ_najwiêksza_wartoœæ: ' + Trim(  FormatFloat( '### ### ### ##0', rakiety_iloœæ_najwiêksza_wartoœæ )  )   ); //???

end;//---//Odœwie¿anie_TimerTimer().

//Pomoc_BitBtnClick().
procedure TStatystyki_Form.Pomoc_BitBtnClick( Sender: TObject );
begin

  ShowMessage
    (
      'Zwyciêstwo' + #13 +
      'Ostateczne zwyciêstwo' + #13 +
      'Przegrana' + #13 +
      #13 +
      'Sieg' + #13 +
      'Endgültiger Sieg' + #13 +
      'Verlust' + #13 +
      #13 +
      'Victory' + #13 +
      'Final victory' + #13 +
      'Defeat' + #13 +
      #13 +
      #13 +
      #13 +
      'Rakiety utworzone / stracone | polecenia wydane' + #13 +
      'w misji' + #13 +
      'w grze' + #13 +
      #13 +
      'Raketen erstellt / verloren | ausgegebene Befehle' + #13 +
      'im Auftrag' + #13 +
      'im Spiel' + #13 +
      #13 +
      'Rockets created / lost | commands issued' + #13 +
      'in mission' + #13 +
      'in the game' + #13 +
      #13 +
      #13 +
      #13 +
      'Wykres liniowy' + #13 +
      'Wykres s³upkowy' + #13 +
      #13 +
      'Liniendiagramm' + #13 +
      'Line graph' + #13 +
      #13 +
      'Ein Balkendiagramm' + #13 +
      'A bar graph'
    );

end;//---//Pomoc_BitBtnClick().

end.
