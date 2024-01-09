unit Statystyki;{22.Cze.2021}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus, Vcl.Buttons;

type
  TStatystyki_Form = class( TForm )
    Przyciski_Panel: TPanel;
    Zwyci�stwo_Label: TLabel;
    Nast�pna_Misja_Button: TButton;
    Kontynuuj_Button: TButton;
    Pauza_Button: TButton;
    Rozegraj_Misj�_Jeszcze_Raz_Button: TButton;
    Stop_Button: TButton;
    Statystyki_Image: TImage;
    Od�wie�anie_Timer: TTimer;
    Statystyki_PopupMenu: TPopupMenu;
    Wykres_Liniowy_MenuItem: TMenuItem;
    Wykres_S�upkowy_MenuItem: TMenuItem;
    Poziomy_Splitter: TSplitter;
    Pomoc_BitBtn: TBitBtn;
    procedure FormShow( Sender: TObject );
    procedure FormResize( Sender: TObject );
    procedure Od�wie�anie_TimerTimer( Sender: TObject );
    procedure Pomoc_BitBtnClick( Sender: TObject );
  private
    { Private declarations }
    data_czas_zmiany_okna : TDateTime;
  public
    { Public declarations }
    czy_zwyci�stwo : boolean;
    id_grupa_zwyci�ska : integer;
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
  if    ( czy_zwyci�stwo )
    and ( id_grupa_zwyci�ska <> Planety.id_grupa_gracza_c ) then
    Rozegraj_Misj�_Jeszcze_Raz_Button.SetFocus();

end;//---//FormShow().

//FormResize().
procedure TStatystyki_Form.FormResize( Sender: TObject );
begin

  data_czas_zmiany_okna := Now();

  if Self.Tag = 0 then
    begin

      // Pierwsze wy�wietlenie okna od�wie�a bez op�nienia.

      Self.Tag := 1;

      data_czas_zmiany_okna := System.DateUtils.IncHour( data_czas_zmiany_okna, -1 );

      Od�wie�anie_TimerTimer( Sender );

    end
  else//if Self.Tag = 0 then
    begin

      Od�wie�anie_Timer.Enabled := true;

    end;
  //---//if Self.Tag = 0 then

end;//---//FormResize().

//Od�wie�anie_TimerTimer().
procedure TStatystyki_Form.Od�wie�anie_TimerTimer( Sender: TObject );
const
  wykres_s�upek__szeroko��_l_c : integer = 5;
var
  i,
  j,
  zti,
  blok_szeroko��, // Szeroko�� obszaru wykresu na osi x, kt�r� zajmuje jeden pomiar wszystkich grup wraz z odst�pem na ko�cu.
  bloki_ilo��_na_wykresie,
  rakiety_ilo��_najwi�ksza_warto��,
  wykres_s�upek__x
    : integer;
  wykres_skalowanie_do_wysoko�ci, // Przeskaluje warto�ci tak aby najwi�ksza warto�� odpowiada�a wysoko�ci wykresu.
  wykres_liniowy_skalowanie_do_szeroko�ci
    : real;
  //zts : string;
  kolor_grupy : TColor;
begin

  //if System.DateUtils.SecondsBetween( Now(), data_czas_zmiany_okna ) < 1 then
  if System.DateUtils.MilliSecondsBetween( Now(), data_czas_zmiany_okna ) < Od�wie�anie_Timer.Interval then
    Exit;

  Od�wie�anie_Timer.Enabled := false;


  Statystyki_Image.Picture := nil;



  rakiety_ilo��_najwi�ksza_warto�� := 0;

  for i := 0 to Length( Planety_Form.statystyki_tabela_t ) - 1 do
    for j := 1 to Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1 do
      if rakiety_ilo��_najwi�ksza_warto�� < Planety_Form.statystyki_tabela_t[ i ][ j ] then
        rakiety_ilo��_najwi�ksza_warto�� := Planety_Form.statystyki_tabela_t[ i ][ j ];


  if Length( Planety_Form.statystyki_tabela_t ) > 0 then
    bloki_ilo��_na_wykresie := Length( Planety_Form.statystyki_tabela_t[ 0 ] ) - 1 // Pierwsza warto�� to numer grupy.
  else//if    (  Length( Planety_Form.statystyki_tabela_t ) > 0 ) (...)
    bloki_ilo��_na_wykresie := 0;


  if rakiety_ilo��_najwi�ksza_warto�� <> 0 then
    wykres_skalowanie_do_wysoko�ci := ( Statystyki_Image.Height - 20 ) / rakiety_ilo��_najwi�ksza_warto��
  else//if rakiety_ilo��_najwi�ksza_warto�� <> 0 then
    wykres_skalowanie_do_wysoko�ci := 1;

  if wykres_skalowanie_do_wysoko�ci < 0 then
    wykres_skalowanie_do_wysoko�ci := 1;



  if bloki_ilo��_na_wykresie <> 0 then
    wykres_liniowy_skalowanie_do_szeroko�ci := ( Statystyki_Image.Width - 20 ) / bloki_ilo��_na_wykresie
  else//if bloki_ilo��_na_wykresie <> 0 then
    wykres_liniowy_skalowanie_do_szeroko�ci := 1;

  if wykres_liniowy_skalowanie_do_szeroko�ci < 0 then
    wykres_liniowy_skalowanie_do_szeroko�ci := 1;



  Statystyki_Image.Canvas.Pen.Color := clWhite;
  Statystyki_Image.Canvas.Brush.Color := clRed;


  blok_szeroko�� :=
    + wykres_s�upek__szeroko��_l_c * ( Length( Planety_Form.statystyki_tabela_t ) - 0  ) // Przesuni�cie bloku pomiar�w zale�nie od ilo�ci grup na li�cie.
    //+ wykres_s�upek__szeroko��_l_c; // Odst�p mi�dzy pomiarami.
    + Round( wykres_s�upek__szeroko��_l_c * 0.5 ); // Odst�p mi�dzy pomiarami.


  // Ile blok�w zmie�ci si� na wykresie.
  if blok_szeroko�� <> 0 then
    i := System.Math.Floor( Statystyki_Image.Width / blok_szeroko�� )
  else//if blok_szeroko�� <> 0 then
    i := 1;


  if bloki_ilo��_na_wykresie <= i then
    zti := 0 // Wszystkie bloki danych zmieszcz� si� na wykresie.
  else//if bloki_ilo��_na_wykresie <= i then
    begin

      // Nie wszystkie bloki danych zmieszcz� si� na wykresie.

      zti := System.Math.Floor( bloki_ilo��_na_wykresie / i );

    end;
  //---//if bloki_ilo��_na_wykresie <= i then


  for i := 0 to Length( Planety_Form.statystyki_tabela_t ) - 1 do
    begin

      //Statystyki_Image.Canvas.Brush.Color :=
      kolor_grupy :=
           Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).X * 255 )
        or (  Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).Y * 255 ) shl 8  )
        or (  Round( Planety_Form.Kolor_Grupa_Ustaw( Planety_Form.statystyki_tabela_t[ i ][ 0 ] ).Z * 255 ) shl 16  );

      //zts := 'grupa id ';

      wykres_s�upek__x :=
          10 // Margines z lewej strony.
        + i * wykres_s�upek__szeroko��_l_c; // Przesuni�cie pierwszego s�upka zale�nie od kolejno�ci grup na li�cie.

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


              if    ( Wykres_S�upkowy_MenuItem.Checked )
                and ( Planety_Form.statystyki_tabela_t[ i ][ j ] > 0 ) then //???
                if   ( zti = 0 )
                  or (
                           ( zti <> 0 )
                       and (
                                ( j = 1 ) // Pierwszy i ostatni blok zawsze wy�wietla.
                             or (  j = Length( Planety_Form.statystyki_tabela_t[ i ] ) - 1  ) // Pierwszy i ostatni blok zawsze wy�wietla.
                             or ( j mod zti = 0 )
                           )
                     ) then
                  begin

                    Statystyki_Image.Canvas.Brush.Color := kolor_grupy;

                    Statystyki_Image.Canvas.Rectangle( wykres_s�upek__x, Statystyki_Image.Height - 10, wykres_s�upek__x + wykres_s�upek__szeroko��_l_c, Statystyki_Image.Height - 10 - System.Math.Floor( Planety_Form.statystyki_tabela_t[ i ][ j ] * wykres_skalowanie_do_wysoko�ci )  ); // % wzgldem najwiekszego pomiaru i wysoko�ci rysowania //???


                    wykres_s�upek__x := wykres_s�upek__x + blok_szeroko��;

                  end;
                //---//if   ( zti = 0 ) (...)


              if    ( Wykres_Liniowy_MenuItem.Checked )
                and (
                         ( Planety_Form.statystyki_tabela_t[ i ][ j ] > 0 )
                      or ( // Aby dorysowa� koniec linii do poziomu zera.
                               ( j > 2 )
                           and ( Planety_Form.statystyki_tabela_t[ i ][ j ] = 0 )
                           and ( Planety_Form.statystyki_tabela_t[ i ][ j - 1 ] > 0 )
                         )
                    ) then
                begin

                  Statystyki_Image.Canvas.Pen.Color := kolor_grupy;
                  Statystyki_Image.Canvas.Pen.Width := 3;
                  Statystyki_Image.Canvas.Brush.Color := clWhite;

                  Statystyki_Image.Canvas.LineTo(   10 + System.Math.Floor(  ( j - 0 ) * wykres_liniowy_skalowanie_do_szeroko�ci  ), Statystyki_Image.Height - 10 - System.Math.Floor( Planety_Form.statystyki_tabela_t[ i ][ j ] * wykres_skalowanie_do_wysoko�ci )   );

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
  Statystyki_Image.Canvas.TextOut(   25, 35, '      w misji: ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_utworzonych__misja )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_straconych__misja )  ) + ' | ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__polecenia_ilo��__misja )  )   );
  Statystyki_Image.Canvas.TextOut(   25, 55, '      w grze: ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_utworzonych__gra )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__rakiet_straconych__gra )  ) + ' | ' + Trim(  FormatFloat( '### ### ### ##0', Planety_Form.statystyki__polecenia_ilo��__gra )  )   );


  // Warto�ci na osi Y z lewej strony.
  Statystyki_Image.Canvas.TextOut(   10, 10, Trim(  FormatFloat( '### ### ### ##0', rakiety_ilo��_najwi�ksza_warto�� )  )   );

  if rakiety_ilo��_najwi�ksza_warto�� > 3 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.25  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_ilo��_najwi�ksza_warto�� * 0.75 )  )   );

  if rakiety_ilo��_najwi�ksza_warto�� > 1 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.5  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_ilo��_najwi�ksza_warto�� * 0.5 )  )   );

  if rakiety_ilo��_najwi�ksza_warto�� > 3 then
    Statystyki_Image.Canvas.TextOut(   10, Round(  ( Statystyki_Image.Height - 20 ) * 0.75  ), Trim(  FormatFloat( '### ### ### ##0', rakiety_ilo��_najwi�ksza_warto�� * 0.25 )  )   );

  Statystyki_Image.Canvas.TextOut( 10, Statystyki_Image.Height - 15, '0' );

  //Statystyki_Image.Canvas.TextOut(   10, 250, 'rakiety_ilo��_najwi�ksza_warto��: ' + Trim(  FormatFloat( '### ### ### ##0', rakiety_ilo��_najwi�ksza_warto�� )  )   ); //???

end;//---//Od�wie�anie_TimerTimer().

//Pomoc_BitBtnClick().
procedure TStatystyki_Form.Pomoc_BitBtnClick( Sender: TObject );
begin

  ShowMessage
    (
      'Zwyci�stwo' + #13 +
      'Ostateczne zwyci�stwo' + #13 +
      'Przegrana' + #13 +
      #13 +
      'Sieg' + #13 +
      'Endg�ltiger Sieg' + #13 +
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
      'Wykres s�upkowy' + #13 +
      #13 +
      'Liniendiagramm' + #13 +
      'Line graph' + #13 +
      #13 +
      'Ein Balkendiagramm' + #13 +
      'A bar graph'
    );

end;//---//Pomoc_BitBtnClick().

end.
