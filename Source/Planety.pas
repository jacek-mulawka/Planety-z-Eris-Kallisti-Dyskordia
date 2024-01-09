unit Planety;{12.Cze.2021}

  //
  // MIT License
  //
  // Copyright (c) 2021 Jacek Mulawka
  //
  // j.mulawka@interia.pl
  //
  // https://github.com/jacek-mulawka
  //


  // Wydanie 2.0.0.0 - aktualizacja GLScene z 1.6.0.7082 na 2.2 2023.


  // Kierunki wsp�rz�dnych uk�adu g��wnego.
  //
  //     g�ra y
  //     prz�d -z
  // lewo -x
  //     ty� z
  //

  // Start_Stop_Button.Tag = 0 - nie ma aktywnej gry.
  // Start_Stop_Button.Tag = 1 - gra jest w trakcie.

  // Przyk�adowa zale�no��:
  //   planeta pojemno�� = planeta skala * 20.

  // Rakiety s� tworzone na planetach wed�ug kolejno�ci planet jako potomk�w a nie grup.
  // Rakiety zwalczaj� si� wed�ug kolejno�ci na li�cie rakiet.
  // Podczas zwalczania si� rakiet kolejno�� grup nie powinna preferowa� jednych grup wzgl�dem innych.

  // Wersja gry fann i bez fann.

{$I Definicje.inc}

interface

uses
  GLS.ThorFX,
  GLS.VectorTypes,


  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Samples.Spin, Vcl.CheckLst,

  GLS.SceneViewer, GLS.Objects, GLS.Scene, GLS.Coordinates, GLS.BaseClasses, GLS.Navigator, GLS.Cadencer, GLS.SkyDome,
  GLS.GeomObjects, GLS.Atmosphere, GLS.SpaceText, GLS.BitmapFont, GLS.WindowsFont, GLS.HUDObjects

  {$IFDEF si_fann_u�ywaj}
  , FannNetwork
  {$ENDIF}
  ;

type
  TKolor_Grupa_r = record
    id_grupa : integer;
    kolor_vector : GLS.VectorTypes.TVector4f;
  end;//---//TKolor_Grupa_r

  TPlaneta = class( TGLDummyCube )
    private
      zaznaczona : boolean;

      id_planeta,
      id_grupa,
      id_grupa_zdobywaj�ca_planet�,
      ilo��_pocz�tkowa_rakiet,
      pojemno��_rakiet
        : integer;

      przejmowanie_poziom_aktualny,
      przyrost_post�p_aktualny, // W ka�dym cyklu zwi�ksza si� o przyrost_szybko�� i cz�� ca�kowita zamienia si� w rakiet� np.: 0 + 0,3 + 0,3 + 0,3 + 0,3 -> 1,2 = 1 rakieta i 0,2 przyrost_post�p_aktualny.
      przyrost_szybko��
        : real;

      planeta_kula_gl_sphere : TGLSphere;
      losowy_obr�t_gl_dummy_cube, // Aby tworzone rakiety pojawia�y si� w ro�nych miejscach orbity.
      orbita_dla_rakiet_gl_dummy_cube
        : TGLDummyCube;

      atmosfera_gl_atmosphere : TGLAtmosphere;

      opis_gl_space_text : TGLSpaceText;

      pier�cie�_gl_torus : TGLTorus; // Reprezentuje zaj�to�� miejsca na orbicie planety przez rakiety.
  public
    { Public declarations }
    constructor Create();
    destructor Destroy(); override;

    procedure Przyrost_Przeliczaj();

    function Rakiety_Na_Orbicie_Ilo��( const id_grupa_f : integer = -1 ) : integer;

    procedure Zaznaczenie_Ustaw( const zaznaczona_f : boolean );
  end;//---//TPlaneta

  TRakieta = class( TGLDummyCube )
    private
      czy_usun�� : boolean;

      id_planeta,
      id_grupa
        : integer;

      planeta_docelowa_wsp�rz�dne_na_orbicie : GLS.VectorTypes.TVector4f; // Wsp�rz�dne na orbicie docelowej aby rakiety nie przybywa�y wszystkie w to samo miejsce.

      planeta_docelowa : TPlaneta;

      kad�ub_gl_cone,
      silnik_g��wny_gl_cone
        : TGLCone;
  public
    { Public declarations }
    constructor Create( planeta_f : TPlaneta );
    destructor Destroy(); override;

    function Orbita_Odleg�o��_Ustaw( planeta_f : TPlaneta ) : single;
    procedure Orbita_Kierunek_Ustaw();
  end;//---//TRakieta

  TWalka_Efekt = class( TGLDummyCube )
    private
      wzrost_kierunek : integer; // Znak tej warto�ci okre�la czy rozmiar efektu si� zwi�ksza czy zmniejsza.

      utworzenie_czas : double;

      gl_thor_fx_manager : GLS.ThorFX.TGLThorFXManager;
  public
    { Public declarations }
    constructor Create( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
    destructor Destroy(); override;
  end;//---//TWalka_Efekt

  TFann_Za�lepka = class
    private
    //Layers : TStrings;
  public
    { Public declarations }
    constructor Create( Aowner : TComponent );
    destructor Destroy(); override;

    //procedure Build();
    //procedure UnBuild();
    function Train( Input : array of single; Output: array of single ) : single;
    procedure Run( Inputs : array of single; var Outputs: array of single );
    //procedure SaveToFile( FileName : string );
    //procedure LoadFromFile( Filename : string );
  end;//---//TFann_Za�lepka

  TPlanety_Form = class( TForm )
    Gra_GLSceneViewer: TGLSceneViewer;
    Gra_GLScene: TGLScene;
    Gra_GLCamera: TGLCamera;
    Gra_GLLightSource: TGLLightSource;
    Zero_GLSphere: TGLSphere;
    Lewo_GLCube: TGLCube;
    GLCadencer1: TGLCadencer;
    GLNavigator1: TGLNavigator;
    GLUserInterface1: TGLUserInterface;
    PageControl1: TPageControl;
    Opcje_Splitter: TSplitter;
    Opcje_TabSheet: TTabSheet;
    O_Programie_TabSheet: TTabSheet;
    O_Programie_Label: TLabel;
    Logo_Image: TImage;
    Mapa_ComboBox: TComboBox;
    Mapa_Etykieta_Label: TLabel;
    Gra_Obiekty_GLDummyCube: TGLDummyCube;
    GLSkyDome1: TGLSkyDome;
    Start_Stop_Button: TButton;
    Pauza_Button: TButton;
    Gra_Pr�dko��_Etykieta_Label: TLabel;
    Gra_Pr�dko��_SpinEdit: TSpinEdit;
    Rakiety_Ilo��_Procent_Wys�anie_Etykieta_Label: TLabel;
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit: TSpinEdit;
    GLAtmosphere1: TGLAtmosphere;
    GLSpaceText1: TGLSpaceText;
    Test_Button: TButton;
    Pomoc_BitBtn: TBitBtn;
    Nast�pna_Misja_Button: TButton;
    Statystyki_Button: TButton;
    Planety_Opisy_CheckBox: TCheckBox;
    Wsp�rz�dne_Test_GLDummyCube: TGLDummyCube;
    Ruch_Ostatni_Pon�w_Button: TButton;
    Planety_Opisy__Dodatkowe_Informacje_CheckBox: TCheckBox;
    GLTorus1: TGLTorus;
    Zaj�to��_Orbity_Wizualizuj_CheckBox: TCheckBox;
    SI_TabSheet: TTabSheet;
    SI_Log_Memo: TMemo;
    Informacja_GLHUDSprite: TGLHUDSprite;
    Informacja_GLHUDText: TGLHUDText;
    Informacja_GLWindowsBitmapFont: TGLWindowsBitmapFont;
    SI_G�ra_Panel: TPanel;
    SI_Loguj_CheckBox: TCheckBox;
    SI_Normalne_Button: TButton;
    SI_Trudniejsze_Button: TButton;
    SI_Decyduj__Cykl_Sekundy_Etykieta_Label: TLabel;
    SI_Decyduj__Cykl_Sekundy_SpinEdit: TSpinEdit;
    Decyzje_Gracza_Zapami�tuj_CheckBox: TCheckBox;
    Decyzje_Gracza_Zapisz_Button: TButton;
    Grupa_Fann_Decyduje_GroupBox: TGroupBox;
    Grupa_Fann_Decyduje_CheckListBox: TCheckListBox;
    Grupa_Fann_Decyduje__Zaznacz_Wszystko_Button: TButton;
    Grupa_Fann_Decyduje__Odznacz_Wszystko_Button: TButton;
    Grupa_Fann_Decyduje__Odwr��_Zaznaczenie_Button: TButton;
    Fann_Nauka_ProgressBar: TProgressBar;
    FANN__Przygotuj_Button: TButton;
    FANN__Opcje_Dodatkowe_GroupBox: TGroupBox;
    FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_Button: TButton;
    FANN__Epoki_Ilo��_Etykieta_Label: TLabel;
    FANN__Epoki_SpinEdit: TSpinEdit;
    FANN__Algorytm_Ucz�cy_Etykieta_Label: TLabel;
    FANN__Algorytm_Ucz�cy_ComboBox: TComboBox;
    FANN__Funkcja_Aktywuj�ca_Warstw_Ukrytych_Etykieta_Label: TLabel;
    FANN__Funkcja_Aktywuj�ca_Warstw_Ukrytych_ComboBox: TComboBox;
    FANN__Funkcja_Aktywuj�ca_Warstwy_Wyj�cia_Etykieta_Label: TLabel;
    FANN__Funkcja_Aktywuj�ca_Warstwy_Wyj�cia_ComboBox: TComboBox;
    FANN__Zapisz_Button: TButton;
    FANN__Wczytaj_Button: TButton;
    FANN__Plik_Nazwa_ComboBox: TComboBox;
    FANN__Zwolnij_Button: TButton;
    Neuron�w_W_Warstwach_Ukrytych_Edit: TEdit;
    Grupa_Fann_Decyduje__Algorytm_Tylko_RadioButton: TRadioButton;
    Grupa_Fann_Decyduje__Fann_Tylko_RadioButton: TRadioButton;
    Grupa_Fann_Decyduje__Losuj_RadioButton: TRadioButton;
    Mapa_Wybieraj_Losowo_CheckBox: TCheckBox;
    Mapa_Losuj_BitBtn: TBitBtn;
    Mapy_Losowe_Etykieta_Label: TLabel;
    procedure FormShow( Sender: TObject );
    procedure FormClose( Sender: TObject; var Action: TCloseAction );
    procedure GLCadencer1Progress( Sender: TObject; const deltaTime, newTime: Double );
    procedure Gra_GLSceneViewerClick( Sender: TObject );
    procedure Gra_GLSceneViewerKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
    procedure Gra_GLSceneViewerMouseDown( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer );
    procedure Gra_GLSceneViewerMouseMove( Sender: TObject; Shift: TShiftState; X, Y: Integer );
    procedure Mapa_ComboBoxChange( Sender: TObject );
    procedure Mapa_Losuj_BitBtnClick( Sender: TObject );
    procedure Start_Stop_ButtonClick( Sender: TObject );
    procedure Pauza_ButtonClick( Sender: TObject );
    procedure Pomoc_BitBtnClick( Sender: TObject );
    procedure Nast�pna_Misja_ButtonClick( Sender: TObject );
    procedure Ruch_Ostatni_Pon�w_ButtonClick( Sender: TObject );
    procedure Statystyki_ButtonClick( Sender: TObject );
    procedure Planety_Opisy_CheckBoxClick( Sender: TObject );
    procedure SpinEditChange( Sender: TObject );
    procedure SI_Trudno��_ButtonClick( Sender: TObject );
    procedure Decyzje_Gracza_Zapisz_ButtonClick( Sender: TObject );
    procedure Grupa_Fann_Decyduje__Zaznacz_ButtonClick( Sender: TObject );

    procedure FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_ButtonClick( Sender: TObject );
    procedure FANN__Przygotuj_ButtonClick( Sender: TObject );
    procedure FANN__Zwolnij_ButtonClick( Sender: TObject );
    procedure FANN__Zapisz_ButtonClick( Sender: TObject );
    procedure FANN__Wczytaj_ButtonClick( Sender: TObject );

    procedure Test_ButtonClick( Sender: TObject );
  private
    { Private declarations }
    czy_zwyci�stwo, // Czy misja zako�czy�a si� czyim� zwyci�stwem albo gracz przegra�.
    statystyki_wykres_liniowy_menuitem_checked_g, // Zapami�tuje ustawienia z okna statystyk.
    statystyki_wykres_s�upkowy_menuitem_checked_g  // Zapami�tuje ustawienia z okna statystyk.
      : boolean;

    decyzje_gracza_numer_g,
    planety_ilo��_mapa_g, // Ilo�� planet na mapie.
    si_decyduj__cykl_sekundy_g,
    si_decyduj__cykl_sekundy__modyfikator_losowy_g
      : integer;

    przyrost__ostatnie_przeliczenie_g,
    si_decyduj__ostatnie_przeliczenie_g,
    zwalczanie_poza_orbit�__ostatnie_przeliczenie_g,
    zwyci�stwo_sprawd�__ostatnie_przeliczenie_g
      : double;

    si__odleg�o��_najwi�ksza_mi�dzy_planetami_g,
    si__przyrost_szybko��_planety_najwi�kszy_g,
    si__wielko��_planety_najwi�ksza_g
      : real;

    zaznaczanie_ruchem_myszy__op�nienie_data_czas, // Aby wywo�ywa�o funkcj� podczas ruchu myszy ale z pewnymi przerwami.
    zaznaczanie_ruchem_myszy__op�nienie__zaznacze_data_czas // Przerwa po tym jak planeta si� zaznaczy albo odznaczy.
      : TDateTime;

    decyzje_gracza_g, // Zapami�tanie konfiguracji mapy gdy gracz wykonywa� ruch.
    ostatni_ruch_pon�w__id_planeta_z__1,
    ostatni_ruch_pon�w__id_planeta_z__2,
    ostatni_ruch_pon�w__id_planeta_z__3,
    ostatni_ruch_pon�w__id_planeta_z__4
      : string;

    rakiety_list,
    walka_efekt_list
      : TList;

    kamera_pozycja_pocz�tkowa_g : GLS.VectorTypes.TVector4f;

    ostatni_ruch_pon�w__planeta_docelowa__1,
    ostatni_ruch_pon�w__planeta_docelowa__2,
    ostatni_ruch_pon�w__planeta_docelowa__3,
    ostatni_ruch_pon�w__planeta_docelowa__4
      : TPlaneta;

    kolor_grupa_r_t : array of TKolor_Grupa_r; // Je�eli pojawi si� grupa spoza zakresu przygotowanych kolor�w zapami�ta tutaj wylosowany dla niej kolor.

    mapa_rozegrana_t : array of boolean; // Oznacza, �e na danej mapie odby�a si� ju� rozgrywka (ma znaczenie gdy mapy s� wybierane losowo). Indeks tabeli odpowiada Mapa_ComboBox.ItemIndex.

    {$IFDEF si_fann_u�ywaj}
    fann_network : FannNetwork.TFannNetwork;
    {$ELSE si_fann_u�ywaj}
    fann_network : TFann_Za�lepka;
    {$ENDIF}
    function Komunikat_Wy�wietl( const text_f, caption_f : string; const flags_f : integer ) : integer;

    procedure Kamera_Ruch( delta_czasu_f : double );

    function Gra_Pr�dko��() : real;

    procedure Mapy_Wczytaj();
    function Mapa_Utw�rz() : boolean;
    procedure Mapa_Zwolnij();

    procedure Rakiety_Utw�rz_Jeden( planeta_f : TPlaneta );
    //procedure Rakiety_Zwolnij_Jeden( rakieta_f : TRakieta  );
    procedure Rakiety_Zwolnij_Wszystkie();
    procedure Rakiety_Cel_Ustaw( const id_grupa_f : integer; id_planeta_z_s_f : string; planeta_docelowa_f : TPlaneta; rakiety_ilo��_procent_wys�anie_f : real = -1 );
    procedure Rakiety_Lot_Do_Celu( delta_czasu_f : double );

    procedure Walka_Efekt_Utw�rz_Jeden( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
    procedure Walka_Efekt_Zwolnij_Jeden( walka_efekt_f : TWalka_Efekt  );
    procedure Walka_Efekt_Zwolnij_Wszystkie();

    procedure Orbita_Rakiety_Zwalczanie( const poza_orbit�_tylko_f : boolean );

    procedure Planety_Przejmowanie_Przeliczaj();

    procedure SI_Decyduj( const id_grupa_f : integer = -1; const decyzja_gracza__planeta_docelowa__id_planeta_f : integer = -1 );
    procedure SI_Decyduj__Modyfikator_Losowy_Ustaw();

    function Zwyci�stwo_Sprawd�( out id_grupa_wy : integer ) : boolean;
    function Przegrana_Gracza_Sprawd�( out id_grupa_wy : integer ) : boolean;

    procedure Statystyki_Tabela_Utw�rz();
    procedure Statystyki_Tabela_Warto�ci_Kolejne_Zapami�taj();
    procedure Statystyki_Tabela_Czy��();

    procedure Statystyki_Wy�wietl( const {czy_przyciski_f,} czy_zwyci�stwo_f : boolean; const id_grupa_f : integer );

    procedure Informacja_Wy�wietl( const napis_f : string );

    procedure Mapy_Losowe_Etykieta_Wylicz();

    procedure FANN_Przygotuj( const tylko_utw�rz_sie�_f : boolean = false );

    procedure FANN_Zapisane_Nazwy_Wyszukaj();
  public
    { Public declarations }
    statystyki__polecenia_ilo��__gra,
    statystyki__polecenia_ilo��__misja,
    statystyki__rakiet_straconych__gra,
    statystyki__rakiet_straconych__misja,
    statystyki__rakiet_utworzonych__gra,
    statystyki__rakiet_utworzonych__misja
      : integer;

    statystyki_tabela_t : array of array of integer; // Pierwsza warto�� oznacza id grupy, kolejne to ilo�� rakiet danej w grupy w momencie pomiaru.

    function Kolor_Grupa_Ustaw( id_grupa_f : integer ) : GLS.VectorTypes.TVector4f;
  end;

const
  id_grupa_gracza_c : integer = 1;
  id_grupa_neutralna_c : integer = 0;
  decyzje_gracza__katalog_nazwa_c : string = 'Decyzje gracza';
  przyrost__cykl_sekundy_c = 2;
  rakieta_pr�dko��_c : Real = 1;
  //si_decyduj__cykl_sekundy_c = 5;
  si_decyduj__planety_posiadane_procent_pr�g_c : real = 10; // Gdy grupa posi�dzie zadany procent planet inaczej warto�ciuje parametry.
  fann_sieci_zapisane__katalog_nazwa_c : string = 'Sieci zapisane';
  fann_sieci_zapisane__kropka_rozszerzenie_c : string = '.sie�_fann';
  walka_efekt__czas_trwania_sekundy_c = 5; // Po ilu sekundach znika efekt walki.
  zwalczanie_poza_orbit�__cykl_sekundy_c = 1; // Co ile czasu nast�pi kolejne sprawdzenie zwyci�stwa w misji.
  zwyci�stwo_sprawd�__cykl_sekundy_c = 10;

var
  Planety_Form: TPlanety_Form;

implementation

uses
  System.DateUtils,
  System.IOUtils,
  System.Math,
  Xml.XMLDoc,
  Xml.XMLIntf,

  GLS.Color,
  GLS.Keyboard,
  GLS.Material,
  GLS.VectorGeometry,

  Statystyki;

{$R *.dfm}

//Konstruktor klasy TPlaneta.
constructor TPlaneta.Create();
begin

  inherited Create( Application );

  Self.Parent := Planety_Form.Gra_Obiekty_GLDummyCube;
  //Self.Pickable := false; // Blokuje klikanie w kul� planety.

  Self.zaznaczona := false;
  Self.id_planeta := -1;
  Self.id_grupa := id_grupa_neutralna_c;
  Self.id_grupa_zdobywaj�ca_planet� := id_grupa_neutralna_c;
  Self.ilo��_pocz�tkowa_rakiet := 0;
  Self.pojemno��_rakiet := 0;
  Self.przejmowanie_poziom_aktualny := 0;
  Self.przyrost_post�p_aktualny := 0;
  Self.przyrost_szybko�� := 0;

  Self.planeta_kula_gl_sphere := TGLSphere.Create( Self );
  Self.planeta_kula_gl_sphere.Parent := Self;
  //Self.planeta_kula_gl_sphere.Pickable := true;

  Self.orbita_dla_rakiet_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.orbita_dla_rakiet_gl_dummy_cube.Parent := Self;
  Self.orbita_dla_rakiet_gl_dummy_cube.Pickable := false;

  Self.losowy_obr�t_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.losowy_obr�t_gl_dummy_cube.Parent := Self;
  Self.losowy_obr�t_gl_dummy_cube.Pickable := false;

  Self.atmosfera_gl_atmosphere := TGLAtmosphere.Create( Self );
  Self.atmosfera_gl_atmosphere.Parent := Self.planeta_kula_gl_sphere;
  Self.atmosfera_gl_atmosphere.Sun := Planety_Form.Gra_GLLightSource;
  Self.atmosfera_gl_atmosphere.PlanetRadius := Self.planeta_kula_gl_sphere.Radius;
  Self.atmosfera_gl_atmosphere.AtmosphereRadius := Self.planeta_kula_gl_sphere.Radius * 1.3;
  Self.atmosfera_gl_atmosphere.Opacity := 1.5; // 2.1
  Self.atmosfera_gl_atmosphere.Pickable := false;

  Self.opis_gl_space_text := TGLSpaceText.Create( Self );
  Self.opis_gl_space_text.Parent := Self;
  Self.opis_gl_space_text.Adjust.Horz := haCenter;
  Self.opis_gl_space_text.Adjust.Vert := vaBottom;
  Self.opis_gl_space_text.Position.Y := Self.planeta_kula_gl_sphere.Radius + Self.planeta_kula_gl_sphere.Radius * 0.25;
  Self.opis_gl_space_text.Position.Z := Self.planeta_kula_gl_sphere.Radius - Self.planeta_kula_gl_sphere.Radius * 0.5;
  Self.opis_gl_space_text.Text := '';
  Self.opis_gl_space_text.Scale.Scale( 0.4 );
  //Self.opis_gl_space_text.Visible := false;

  Self.pier�cie�_gl_torus := TGLTorus.Create( Self );
  Self.pier�cie�_gl_torus.Parent := Self.planeta_kula_gl_sphere;
  Self.pier�cie�_gl_torus.Pickable := false;
  Self.pier�cie�_gl_torus.PitchAngle := 90;
  Self.pier�cie�_gl_torus.MajorRadius := 0.5;
  Self.pier�cie�_gl_torus.Scale.X := 1;
  Self.pier�cie�_gl_torus.Scale.Y := 1;
  Self.pier�cie�_gl_torus.Scale.Z := 0.5;
  Self.pier�cie�_gl_torus.Material.BlendingMode := bmTransparency;
  Self.pier�cie�_gl_torus.Material.FrontProperties.Ambient.Color := GLS.Color.clrTransparent;
  Self.pier�cie�_gl_torus.Material.FrontProperties.Emission.Color := GLS.Color.clrTransparent;

  //Self.VisibleAtRunTime := true; //???
  //Self.ShowAxes := true; //???

  //Self.orbita_dla_rakiet_gl_dummy_cube.VisibleAtRunTime := true; //???
  //Self.losowy_obr�t_gl_dummy_cube.VisibleAtRunTime := true; //???

end;//---//Konstruktor klasy TPlaneta.

//Destruktor klasy TPlaneta.
destructor TPlaneta.Destroy();
begin

  FreeAndNil( Self.atmosfera_gl_atmosphere );
  FreeAndNil( Self.pier�cie�_gl_torus );
  FreeAndNil( Self.opis_gl_space_text );
  FreeAndNil( Self.planeta_kula_gl_sphere );
  FreeAndNil( Self.orbita_dla_rakiet_gl_dummy_cube );
  FreeAndNil( Self.losowy_obr�t_gl_dummy_cube );

  inherited;

end;//---//Destruktor klasy TPlaneta.

//Funkcja Przyrost_Przeliczaj().
procedure TPlaneta.Przyrost_Przeliczaj();
var
  i,
  rakiet_nowych,
  rakiety_na_orbicie__ilo��,
  rakiety_na_orbicie__miejsc_na_przyrost
    : integer;
begin

  if Self.przejmowanie_poziom_aktualny <= 0 then
    Exit;


  Self.przyrost_post�p_aktualny := Self.przyrost_post�p_aktualny + Self.przyrost_szybko��;

  rakiet_nowych := Trunc( Self.przyrost_post�p_aktualny );

  if rakiet_nowych > 0 then
    begin

      Self.przyrost_post�p_aktualny := Self.przyrost_post�p_aktualny - rakiet_nowych;

      rakiety_na_orbicie__ilo�� := 0;

      for i := Self.orbita_dla_rakiet_gl_dummy_cube.Count - 1 downto 0 do
        if Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ] is TRakieta then
          inc( rakiety_na_orbicie__ilo�� );

      rakiety_na_orbicie__miejsc_na_przyrost := Self.pojemno��_rakiet - rakiety_na_orbicie__ilo��;

      if rakiety_na_orbicie__miejsc_na_przyrost > 0 then
        begin

          if rakiet_nowych > rakiety_na_orbicie__miejsc_na_przyrost then
            rakiet_nowych := rakiety_na_orbicie__miejsc_na_przyrost;

          for i := 1 to rakiet_nowych do
            Planety_Form.Rakiety_Utw�rz_Jeden( Self );

        end;
      //---//if rakiety_na_orbicie__miejsc_na_przyrost > 0 then

    end;
  //---//if rakiet_nowych > 0 then

end;//---//Funkcja Przyrost_Przeliczaj().

//Funkcja Rakiety_Na_Orbicie_Ilo��().
function TPlaneta.Rakiety_Na_Orbicie_Ilo��( const id_grupa_f : integer = -1 ) : integer;
var
  i : integer;
begin

  //
  // Funkcja zlicza ilo�� rakiet na orbicie planety.
  //
  // Zwraca ilo�� rakiet na orbicie planety.
  //
  // Parametry:
  //   id_grupa_f:
  //     -1 - ilo�� wszystkich rakiet dowolnej grupy.
  //     <> -1 - ilo�� rakiet wskazanej grupy.
  //

  Result := 0;

  for i := 0 to Self.orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
    if    ( Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ] is TRakieta )
      and (
               ( id_grupa_f = -1 )
            or ( TRakieta(Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ]).id_grupa = id_grupa_f )
          ) then
      inc( Result );

end;//---//Funkcja Rakiety_Na_Orbicie_Ilo��().

//Funkcja Zaznaczenie_Ustaw().
procedure TPlaneta.Zaznaczenie_Ustaw( const zaznaczona_f : boolean );
begin

  Self.zaznaczona := zaznaczona_f;

  if Self.zaznaczona then
    Self.planeta_kula_gl_sphere.Material.FrontProperties.Ambient.Color := GLS.Color.clrWhite
  else//if Self.zaznaczona then
    Self.planeta_kula_gl_sphere.Material.FrontProperties.Ambient.Color := GLS.Color.clrGray20;

end;//---//Funkcja Zaznaczenie_Ustaw().

//Konstruktor klasy TRakieta.
constructor TRakieta.Create( planeta_f : TPlaneta );
var
  zt_vector : GLS.VectorTypes.TVector4f;
begin

  inherited Create( Application );

  //Self.Parent := planeta_f.orbita_dla_rakiet_gl_dummy_cube;
  Self.Pickable := false;

  Self.czy_usun�� := false;

  Self.id_planeta := planeta_f.id_planeta;
  Self.id_grupa := planeta_f.id_grupa;

  Self.planeta_docelowa := nil;

  // Ustawia rakiet� w planecie, losuje pozycj� i przenosi na obrotowy element.
  //Self.Parent := planeta_f;
  //Self.Position.X := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * (  0.5 + Random( 11 ) * 0.01  );
  //zt_vector := Self.AbsolutePosition;
  //Self.Parent := planeta_f.orbita_dla_rakiet_gl_dummy_cube;
  //Self.Position.AsVector := Self.Parent.AbsoluteToLocal( zt_vector );

  Self.Parent := planeta_f.losowy_obr�t_gl_dummy_cube;
  Self.Position.X := Self.Orbita_Odleg�o��_Ustaw( planeta_f );
  planeta_f.losowy_obr�t_gl_dummy_cube.Roll(  Random( 361 )  );
  //planeta_f.losowy_obr�t_gl_dummy_cube.Roll( 5 );
  zt_vector := Self.AbsolutePosition;
  Self.Parent := planeta_f.orbita_dla_rakiet_gl_dummy_cube;
  Self.Position.AsVector := Self.Parent.AbsoluteToLocal( zt_vector );

  Self.Orbita_Kierunek_Ustaw();


  Self.kad�ub_gl_cone := TGLCone.Create( Self );
  Self.kad�ub_gl_cone.Parent := Self;
  Self.kad�ub_gl_cone.Scale.Scale( 0.05 );
  Self.kad�ub_gl_cone.PitchAngle := -90;

  Self.kad�ub_gl_cone.Material.FrontProperties.Diffuse.Color := Planety_Form.Kolor_Grupa_Ustaw( planeta_f.id_grupa );


  Self.silnik_g��wny_gl_cone := TGLCone.Create( Self );
  Self.silnik_g��wny_gl_cone.Parent := Self.kad�ub_gl_cone;
  Self.silnik_g��wny_gl_cone.Scale.Scale( 0.5 );
  Self.silnik_g��wny_gl_cone.Scale.Y := Self.silnik_g��wny_gl_cone.Scale.Y * 2;
  Self.silnik_g��wny_gl_cone.PitchAngle := 180;
  Self.silnik_g��wny_gl_cone.Position.Y := -Self.kad�ub_gl_cone.Height;
  Self.silnik_g��wny_gl_cone.Material.FrontProperties.Diffuse.Color := GLS.Color.clrWhite;


  if Self.id_grupa = id_grupa_gracza_c then
    begin

      //inc( Planety_Form.statystyki__rakiet_utworzonych__gra );
      inc( Planety_Form.statystyki__rakiet_utworzonych__misja );

    end;
  //---//if Self.id_grupa = id_grupa_gracza_c then


  //Self.VisibleAtRunTime := true; //???
  //Self.ShowAxes := true; //???

end;//---//Konstruktor klasy TRakieta.

//Destruktor klasy TRakieta.
destructor TRakieta.Destroy();
begin

  if    ( Self.czy_usun�� )
    and ( Self.id_grupa = id_grupa_gracza_c ) then
    begin

      //inc( Planety_Form.statystyki__rakiet_straconych__gra );
      inc( Planety_Form.statystyki__rakiet_straconych__misja );

    end;
  //---//if    ( Self.czy_usun�� ) (...)


  FreeAndNil( Self.silnik_g��wny_gl_cone );
  FreeAndNil( Self.kad�ub_gl_cone );

  inherited;

end;//---//Destruktor klasy TRakieta.

//Funkcja Orbita_Odleg�o��_Ustaw().
function TRakieta.Orbita_Odleg�o��_Ustaw( planeta_f : TPlaneta ) : single;
begin

  //
  // Funkcja ustala w jakiej odleg�o�ci od planety rakieta kr��y na orbicie.
  //

  if planeta_f <> nil then
    //Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * (  0.5 + Random( 11 ) * 0.01  )
    //Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * 0.5 + Random( 1501 ) * 0.001 // + od 0 do 1.5.
    Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * 0.5 + Random( 1001 ) * 0.001 // + od 0 do 1.0. //???
  else//if planeta_f <> nil then
    Result := 1;

end;//---//Funkcja Orbita_Odleg�o��_Ustaw().

//Funkcja Orbita_Kierunek_Ustaw().
procedure TRakieta.Orbita_Kierunek_Ustaw();
var
  ztr : real;
begin

  //
  // Funkcja obraca rakiet� aby na orbicie ustawi�a si� przodem w kierunku lotu.
  //

  Self.ResetRotations();

  ztr :=
    System.Math.RadToDeg(
        GLS.VectorGeometry.AngleBetweenVectors(
           GLS.VectorGeometry.VectorMake( 1, 0, 0 ),
           Self.Position.AsVector,
           GLS.VectorGeometry.VectorMake( 0, 0, 0 )
         )
      );


  if Self.Position.Y < 0 then
    ztr := -ztr;

  Self.PitchAngle := -90;
  Self.TurnAngle := ztr;

end;//---//Funkcja Orbita_Kierunek_Ustaw().

//Konstruktor klasy TWalka_Efekt.
constructor TWalka_Efekt.Create( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
begin

  inherited Create( Application );

  Self.Parent := Planety_Form.Gra_Obiekty_GLDummyCube;
  Self.Pickable := false;
  Self.Position.AsVector := pozycja_rakieta_f;

  Self.wzrost_kierunek := 1;
  Self.utworzenie_czas := Planety_Form.GLCadencer1.CurrentTime;

  Self.gl_thor_fx_manager := GLS.ThorFX.TGLThorFXManager.Create( Self );
  Self.gl_thor_fx_manager.Cadencer := Planety_Form.GLCadencer1;
  Self.gl_thor_fx_manager.Core := false;
  //Self.gl_thor_fx_manager.Core := true; //???
  Self.gl_thor_fx_manager.Maxpoints := 2;
  Self.gl_thor_fx_manager.GlowSize := 0.05;
  Self.gl_thor_fx_manager.Target.SetPoint( 0, 0, 0);
  //Self.gl_thor_fx_manager.OuterColor.Color := Planety_Form.Kolor_Grupa_Ustaw( id_grupa_f ); //???
  //Self.gl_thor_fx_manager.OuterColor.Alpha := 0;

  TGLBThorFX(Self.AddNewEffect( TGLBThorFX )).Manager := Self.gl_thor_fx_manager;

  //Self.VisibleAtRunTime := true; //???
  //Self.ShowAxes := true; //???

end;//---//Konstruktor klasy TWalka_Efekt.

//Destruktor klasy TWalka_Efekt.
destructor TWalka_Efekt.Destroy();
begin

  FreeAndNil( Self.gl_thor_fx_manager );

  inherited;

end;//---//Destruktor klasy TWalka_Efekt.

//Konstruktor klasy TFann_Za�lepka.
constructor TFann_Za�lepka.Create( Aowner : TComponent );
begin

  //Self.Layers := TStringList.Create();

end;//---//Konstruktor klasy TFann_Za�lepka.

//Destruktor klasy TFann_Za�lepka.
destructor TFann_Za�lepka.Destroy();
begin

  //FreeAndNil( Self.Layers );

end;//---//Destruktor klasy TFann_Za�lepka.

////Funkcja Build().
//procedure TFann_Za�lepka.Build();
//begin
//end;//---//Funkcja Build().

////Funkcja UnBuild().
//procedure TFann_Za�lepka.UnBuild();
//begin
//end;//---//Funkcja UnBuild().

//Funkcja Train().
function TFann_Za�lepka.Train( Input : array of single; Output: array of single ) : single;
begin
end;//---//Funkcja Train().

//Funkcja Run().
procedure TFann_Za�lepka.Run( Inputs : array of single; var Outputs: array of single );
begin
end;//---//Funkcja Run().

////Funkcja SaveToFile().
//procedure TFann_Za�lepka.SaveToFile( FileName : string );
//begin
//end;//---//Funkcja SaveToFile().

////Funkcja LoadFromFile().
//procedure TFann_Za�lepka.LoadFromFile( Filename : string );
//begin
//end;//---//Funkcja LoadFromFile().


//      ***      Funkcje      ***      //

//Funkcja Komunikat_Wy�wietl().
function TPlanety_Form.Komunikat_Wy�wietl( const text_f, caption_f : string; const flags_f : integer ) : integer;
var
  czy_pauza : boolean;
begin

  czy_pauza := not GLCadencer1.Enabled;

  if not czy_pauza then
    Pauza_ButtonClick( nil );


  Result := Application.MessageBox( PChar(text_f), PChar(caption_f), flags_f );


  if not czy_pauza then
    Pauza_ButtonClick( nil );

end;//---//Funkcja Komunikat_Wy�wietl().

//Funkcja Kolor_Grupa_Ustaw().
function TPlanety_Form.Kolor_Grupa_Ustaw( id_grupa_f : integer ) : GLS.VectorTypes.TVector4f;
var
  i : integer;
begin

  case id_grupa_f of
      0 : Result := GLS.Color.clrGray80;
      1 : Result := GLS.Color.clrSlateBlue;
      2 : Result := GLS.Color.clrRed;
      3 : Result := GLS.Color.clrOrange;
      4 : Result := GLS.Color.clrPlum;
      5 : Result := GLS.Color.clrOldGold;
      6 : Result := GLS.Color.clrGreenYellow;
      else//case id_grupa_f of
        begin

          // Sprawdza czy dla grupy spoza zakresu kolor�w wylosowano ju� kolor.
          for i := 0 to Length( kolor_grupa_r_t ) - 1 do
            if kolor_grupa_r_t[ i ].id_grupa = id_grupa_f then
              begin

                Result := kolor_grupa_r_t[ i ].kolor_vector;
                Exit;

              end;
            //---//if kolor_grupa_r_t[ i ].id_grupa = id_grupa_f then
          //---// Sprawdza czy dla grupy spoza zakresu kolor�w wylosowano ju� kolor.


          // Je�eli pierwszy raz pojawi si� grupa spoza zakresu przygotowanych kolor�w wylosuje dla niej nowy kolor.
          //Result := GLS.Color.clrGray80;
          Zero_GLSphere.Material.FrontProperties.Ambient.RandomColor(); // Kolory mog� by� zbyt podobne. //???
          Result := Zero_GLSphere.Material.FrontProperties.Ambient.Color;

          i := Length( kolor_grupa_r_t );
          SetLength( kolor_grupa_r_t, i + 1 );

          kolor_grupa_r_t[ i ].id_grupa := id_grupa_f;
          kolor_grupa_r_t[ i ].kolor_vector := Result;
          //---// Je�eli pierwszy raz pojawi si� grupa spoza zakresu przygotowanych kolor�w wylosuje dla niej nowy kolor

        end;
    end;
  //---//case id_grupa_f of

end;//---//Funkcja Kolor_Grupa_Ustaw().

//Funkcja Kamera_Ruch().
procedure TPlanety_Form.Kamera_Ruch( delta_czasu_f : double );
const
  ruch_c_l : single = 5;
begin

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD8 ) then
    Gra_GLCamera.Move( ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD5 ) then
    Gra_GLCamera.Move( -ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD4 ) then
    Gra_GLCamera.Slide( -ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD6 ) then
    Gra_GLCamera.Slide( ruch_c_l * delta_czasu_f );


  if GLS.Keyboard.IsKeyDown( VK_NUMPAD9 ) then // G�ra.
    Gra_GLCamera.Lift( ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD3 ) then // D�.
    Gra_GLCamera.Lift( -ruch_c_l * delta_czasu_f );


  if GLS.Keyboard.IsKeyDown( VK_NUMPAD7 ) then // Beczka w lewo.
    Gra_GLCamera.Roll( ruch_c_l * delta_czasu_f * 10 );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD1 ) then // Beczka w prawo.
    Gra_GLCamera.Roll( -ruch_c_l * delta_czasu_f * 10 );

end;//---//Funkcja Kamera_Ruch().

//Funkcja Gra_Pr�dko��().
function TPlanety_Form.Gra_Pr�dko��() : real;
begin

  // Nie mo�e zwraca� zera.

  Result := Gra_Pr�dko��_SpinEdit.Value;

  if Result <= 0 then
    Result := 1;

  Result := Result * 0.01;

end;//---//Funkcja Gra_Pr�dko��().

//Funkcja Mapy_Wczytaj().
procedure TPlanety_Form.Mapy_Wczytaj();
var
  i : integer;
  zts : string;
  search_rec : TSearchRec;
begin

  //
  // Funkcja wczytuje list� schemat�w map.
  //


  Mapa_ComboBox.Items.Clear();

  zts := ExtractFilePath( Application.ExeName ) + 'Mapy\';

  // Je�eli znajdzie plik zwraca 0, je�eli nie znajdzie zwraca numer b��du. Na pocz�tku znajduje '.' '..' potem list� plik�w.
  if FindFirst( zts + '*.xml', faAnyFile, search_rec ) = 0 then // Application potrzebuje w uses Forms.
    begin

      repeat //FindNext( search_rec ) <> 0;
        // Czasami bez begin i end nieprawid�owo rozpoznaje miejsca na umieszczenie breakpoint (linijk� za wysoko) w XE5.

        if    ( search_rec.Attr <> faDirectory )
          and ( search_rec.Name <> '.' )
          and ( search_rec.Name <> '..' ) then
          begin

            Mapa_ComboBox.Items.Add(  System.IOUtils.TPath.GetFileNameWithoutExtension( search_rec.Name )  );

          end;
        //---//if    ( search_rec.Attr <> faDirectory )


      until FindNext( search_rec ) <> 0; // Zwraca dane kolejnego pliku zgodnego z parametrami wcze�niej wywo�anej funkcji FindFirst. Je�eli mo�na przej�� do nast�pnego znalezionego pliku zwraca 0.

    end;
  //---//if FindFirst( zts + '*.xml', faAnyFile, search_rec ) = 0 then

  FindClose( search_rec );


  SetLength( mapa_rozegrana_t, 0 );

  if Mapa_ComboBox.Items.Count > 0 then
    begin

      SetLength( mapa_rozegrana_t, Mapa_ComboBox.Items.Count );

      for i := 0 to Length( mapa_rozegrana_t ) - 1 do
        mapa_rozegrana_t[ i ] := false;

      Mapy_Losowe_Etykieta_Wylicz();

    end;
  //---//if Mapa_ComboBox.Items.Count > 0 then

end;//---//Funkcja Mapy_Wczytaj().

//Funkcja Mapa_Utw�rz().
function TPlanety_Form.Mapa_Utw�rz() : boolean;

  //Funkcja Odczytaj_Liczb�_Z_Napisu() w Mapa_Utw�rz().
  function Odczytaj_Liczb�_Z_Napisu( napis_f : string; const warto��_minimalna_f : variant ) : real;
  begin

    //
    // Funkcja odczytuje liczb� z napisu.
    //
    // Zwraca odczytan� liczb�.
    //
    // Parametry:
    //   napis_f
    //   warto��_minimalna_f - je�eli jest r�na od null i wynik jest mniejszy od niej to zwraca t� warto��.
    //   prze��cz_zak�adk�_f:
    //     false - nie prze��cza zak�adki.
    //     true - prze��cza zak�adk�.
    //

    napis_f := StringReplace( napis_f, '.', ',', [ rfReplaceAll ] );
    napis_f := Trim(  StringReplace( napis_f, ' ', '', [ rfReplaceAll ] )  );

    try
      Result := StrToFloat( napis_f );
    except
      on E : Exception do
        begin

          Result := 1;
          Komunikat_Wy�wietl( 'B��d odczytania liczby z napisu: ' + napis_f + '.' + #13 + E.Message + ' ' + IntToStr( E.HelpContext ) + #13 + #13 + #13 + 'Fehler beim Lesen der Zahl aus der Zeichenfolge.' + #13 + #13 + 'Error reading the number from the string.', 'B��d', MB_OK + MB_ICONEXCLAMATION  );

        end;
      //---//on E : Exception do
    end;
    //---//try

    if    ( warto��_minimalna_f <> null )
      and ( Result < warto��_minimalna_f ) then
      Result := warto��_minimalna_f;

  end;//---//Funkcja Odczytaj_Liczb�_Z_Napisu() w Mapa_Utw�rz().

var
  i,
  j,
  id_planeta_l
    : integer;
  zts : string;
  zt_xml_document : Xml.XMLDoc.TXMLDocument;
  zt_planeta : TPlaneta;
begin//Funkcja Mapa_Utw�rz().

  //
  // Funkcja tworzy map�.
  //

  Result := false;

  planety_ilo��_mapa_g := 0;

  zts := ExtractFilePath( Application.ExeName ) + 'Mapy\' + Mapa_ComboBox.Text + '.xml';

  if not FileExists( zts ) then
    begin

      Komunikat_Wy�wietl( 'Nie odnaleziono pliku mapy:' + #13 + zts + '.' + #13 + #13 + #13 + 'Kartendatei nicht gefunden.' + #13 + #13 + 'Map file not found.', 'B��d', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if not FileExists( zts ) then


  zt_xml_document := Xml.XMLDoc.TXMLDocument.Create( Application );
  zt_xml_document.Options := zt_xml_document.Options + [ Xml.XMLIntf.doNodeAutoIndent ]; // Domy�lnie ma: doNodeAutoCreate, doAttrNull, doAutoPrefix, doNamespaceDecl.

  if zt_xml_document.Active then
    zt_xml_document.Active := false;

  try
    zt_xml_document.LoadFromFile( zts );
  except
    on E : Exception do
      Komunikat_Wy�wietl(  'Nieprawid�owa definicja mapy ' + zts + '.' + #13 + E.Message + ' ' + IntToStr( E.HelpContext ) + #13 + #13 + #13 + 'Ung�ltige Kartendefinition.' + #13 + #13 + 'Invalid map definition.', 'B��d', MB_OK + MB_ICONEXCLAMATION  );
  end;
  //---//try

  if zt_xml_document.Active then
    begin

      id_planeta_l := 0;
      GLS.VectorGeometry.SetVector( kamera_pozycja_pocz�tkowa_g, 0, 0, 0 );

      for i := 0 to zt_xml_document.DocumentElement.ChildNodes.Count - 1 do
        begin

          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__x' then
            kamera_pozycja_pocz�tkowa_g.X := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, null )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__y' then
            kamera_pozycja_pocz�tkowa_g.Y := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, null )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__z' then
            kamera_pozycja_pocz�tkowa_g.Z := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, 0.1 )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'planeta' then
            begin

              zt_planeta := TPlaneta.Create();
              inc( id_planeta_l );
              zt_planeta.id_planeta := id_planeta_l;

              inc( planety_ilo��_mapa_g );

              for j := 0 to zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes.Count - 1 do
                begin

                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'x' then
                    zt_planeta.Position.X := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, null )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'y' then
                    zt_planeta.Position.Y := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, null )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'skala' then
                    zt_planeta.planeta_kula_gl_sphere.Scale.Scale(  Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0.0001 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'id_grupa' then
                    zt_planeta.id_grupa := Round(  Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'ilo��_pocz�tkowa' then
                    zt_planeta.ilo��_pocz�tkowa_rakiet := Round(  Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'pojemno��' then
                    zt_planeta.pojemno��_rakiet := Round(  Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'przyrost_szybko��' then
                    zt_planeta.przyrost_szybko�� := Odczytaj_Liczb�_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 );

                end;
              //---//for j := 0 to zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].ChildNodes.Count - 1 do


              if zt_planeta.id_grupa > id_grupa_neutralna_c then
                zt_planeta.przejmowanie_poziom_aktualny := 100;

              zt_planeta.orbita_dla_rakiet_gl_dummy_cube.CubeSize := zt_planeta.planeta_kula_gl_sphere.Scale.X * 1.3;
              zt_planeta.opis_gl_space_text.Position.Y := zt_planeta.opis_gl_space_text.Position.Y * zt_planeta.planeta_kula_gl_sphere.Scale.X;
              zt_planeta.opis_gl_space_text.Position.Z := zt_planeta.opis_gl_space_text.Position.Z * zt_planeta.planeta_kula_gl_sphere.Scale.X;
              zt_planeta.opis_gl_space_text.Visible := Planety_Opisy_CheckBox.Checked;

              zt_planeta.planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color := Kolor_Grupa_Ustaw( zt_planeta.id_grupa );

              zt_planeta.atmosfera_gl_atmosphere.HighAtmColor.Color := zt_planeta.planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;
              zt_planeta.atmosfera_gl_atmosphere.LowAtmColor.Color := zt_planeta.planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;

              zt_planeta.pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Color := zt_planeta.planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;
              zt_planeta.pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.0;


              for j := 1 to zt_planeta.ilo��_pocz�tkowa_rakiet do
                Rakiety_Utw�rz_Jeden( zt_planeta );

            end;
          //---//if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'planeta' then

        end;
      //---//for i := 0 to zt_xml_document.DocumentElement.ChildNodes.Count - 1 do

      Gra_GLCamera.Position.AsVector := kamera_pozycja_pocz�tkowa_g;

    end;
  //---//if zt_xml_document.Active then

  zt_xml_document.Free();

  Statystyki_Tabela_Utw�rz();

  Result := true;

  {$region 'Przyk�ad xml.'}
{
<mapa>
  <kamera_pozycja__x>0,0</kamera_pozycja__x>
  <kamera_pozycja__y>0,5</kamera_pozycja__y>
  <kamera_pozycja__z>0,0</kamera_pozycja__z>
      <!-- Warto�ci opcjonalne. -->

  <planeta>
    <x>0,0</x><!-- x = -10, y = 6 - lewo g�ra dla kamery x = 0,  y = 0, z = 5. -->
    <y>1,0</y>
    <skala>1,5</skala>

    <id_grupa>0</id_grupa><!-- 0 - neutralna. -->

    <ilo��_pocz�tkowa>0</ilo��_pocz�tkowa>
    <pojemno��>2</pojemno��>
    <przyrost_szybko��>1,0</przyrost_szybko��>
  </planeta>
</mapa>
}
  {$endregion 'Przyk�ad xml.'}

end;//---//Funkcja Mapa_Utw�rz().

//Funkcja Mapa_Zwolnij().
procedure TPlanety_Form.Mapa_Zwolnij();
var
  i : integer;
begin

  planety_ilo��_mapa_g := 0;

  Statystyki_Tabela_Czy��();


  ostatni_ruch_pon�w__id_planeta_z__1 := '';
  ostatni_ruch_pon�w__id_planeta_z__2 := '';
  ostatni_ruch_pon�w__id_planeta_z__3 := '';
  ostatni_ruch_pon�w__id_planeta_z__4 := '';

  ostatni_ruch_pon�w__planeta_docelowa__1 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__2 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__3 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__4 := nil;


  for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Free();

end;//---//Funkcja Mapa_Zwolnij().

//Funkcja Rakiety_Utw�rz_Jeden().
procedure TPlanety_Form.Rakiety_Utw�rz_Jeden( planeta_f : TPlaneta );
var
  zt_rakieta : TRakieta;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  zt_rakieta := TRakieta.Create( planeta_f );

  rakiety_list.Add( zt_rakieta );

end;//---//Funkcja Rakiety_Utw�rz_Jeden().

////Funkcja Rakiety_Zwolnij_Jeden().
//procedure TPlanety_Form.Rakiety_Zwolnij_Jeden( rakieta_f : TRakieta  );
//begin
//
//  // Usuwa� tylko w jednym miejscu. !!!
//  // Wywo�anie tej funkcji w kliku miejscach mo�e co� zepsu�.
//
//  if   ( rakiety_list = nil )
//    or (  not Assigned( rakiety_list )  )
//    or ( rakieta_f = nil ) then
//    Exit;
//
//
//  rakiety_list.Remove( rakieta_f );
//  FreeAndNil( rakieta_f );
//
//end;//---//Funkcja Rakiety_Zwolnij_Jeden().

//Funkcja Rakiety_Zwolnij_Wszystkie().
procedure TPlanety_Form.Rakiety_Zwolnij_Wszystkie();
var
  i : integer;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  Screen.Cursor := crHourGlass;

  for i := rakiety_list.Count - 1 downto 0 do
    begin

      TRakieta(rakiety_list[ i ]).Free();
      rakiety_list.Delete( i );

    end;
  //---//for i := rakiety_list.Count - 1 downto 0 do

  Screen.Cursor := crDefault;

end;//---//Funkcja Rakiety_Zwolnij_Wszystkie().

//Funkcja Rakiety_Cel_Ustaw().
procedure TPlanety_Form.Rakiety_Cel_Ustaw( const id_grupa_f : integer; id_planeta_z_s_f : string; planeta_docelowa_f : TPlaneta; rakiety_ilo��_procent_wys�anie_f : real = -1 );
type
  TPlaneta_Ilo��_Rakiet_r_l = record
    id_planeta,
    rakiety_ilo��
      : integer;
  end;
var
  i,
  j,
  zti
    : integer;
  zt_vector : GLS.VectorTypes.TVector4f;

  planeta_ilo��_rakiet_r_l_t : array of TPlaneta_Ilo��_Rakiet_r_l;
begin

  // Parametry:
  //   id_grupa_f - grupa, kt�rej rakiet dotyczy polecenie.
  //   id_planeta_z_s_f - id planet, z kt�rych wys�a� rakiety w postaci '-99, 1, 2, 3'.
  //   planeta_docelowa_f
  //   rakiety_ilo��_procent_wys�anie_f:
  //     < 0 - u�ywa warto�ci ustawionej w komponencie Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.
  //     >= 0 - u�ywa warto�ci przekazanej do funkcji.

  id_planeta_z_s_f := ', ' + id_planeta_z_s_f + ',';

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  )
    or ( planeta_docelowa_f = nil ) then
    Exit;


  if id_grupa_f = id_grupa_gracza_c then
    inc( statystyki__polecenia_ilo��__misja );


  if    ( Decyzje_Gracza_Zapami�tuj_CheckBox.Checked )
    and ( id_grupa_f = id_grupa_gracza_c ) then
    SI_Decyduj( id_grupa_gracza_c, planeta_docelowa_f.id_planeta );


  if rakiety_ilo��_procent_wys�anie_f < 0 then
    rakiety_ilo��_procent_wys�anie_f := Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value * 0.01
  else//if rakiety_ilo��_procent_wys�anie_f < 0 then
    rakiety_ilo��_procent_wys�anie_f := rakiety_ilo��_procent_wys�anie_f * 0.01;


  // Zlicza ile jest rakiet na orbitach poszczeg�lnych planet i ile rakiet wys�a� (ilo�� dzielona na 2 zaokr�glana w d�).
  SetLength( planeta_ilo��_rakiet_r_l_t, 0 );

  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        zti := Length( planeta_ilo��_rakiet_r_l_t );
        SetLength( planeta_ilo��_rakiet_r_l_t, zti + 1 );

        planeta_ilo��_rakiet_r_l_t[ zti ].id_planeta := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta;
        planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� := 0;

        for j := 0 to TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
          if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
            inc( planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� );

         //planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� := Ceil( planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� * 0.5 );

         if planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� > 1 then
          planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� := System.Math.Floor( planeta_ilo��_rakiet_r_l_t[ zti ].rakiety_ilo�� * rakiety_ilo��_procent_wys�anie_f );

      end;
    //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
  //---// Zlicza ile jest rakiet na orbitach poszczeg�lnych planet i ile rakiet wys�a� (ilo�� dzielona na 2 zaokr�glana w d�).


  for i := 0 to rakiety_list.Count - 1 do
    begin

      if    ( TRakieta(rakiety_list[ i ]).id_grupa = id_grupa_f )
        and ( TRakieta(rakiety_list[ i ]).Parent <> nil )
        and ( TRakieta(rakiety_list[ i ]).Parent.Parent <> nil )
        and ( TRakieta(rakiety_list[ i ]).Parent.Parent is TPlaneta )
        and ( TRakieta(rakiety_list[ i ]).planeta_docelowa = nil )
        and ( TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta <> planeta_docelowa_f.id_planeta ) // Planeta docelowa powinna by� inna ni� planeta, na kt�rej orbicie znajduje si� rakieta.
        and (  Pos(  ', ' + IntToStr( TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta ) + ',', id_planeta_z_s_f  ) > 0  ) then
        begin

          // Po wys�aniu rakiety zmniejsza ilo�� rakiet pozosta�ych do wys�ania.
          for j := 0 to Length( planeta_ilo��_rakiet_r_l_t ) - 1 do
            if    ( planeta_ilo��_rakiet_r_l_t[ j ].id_planeta = TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta )
              and ( planeta_ilo��_rakiet_r_l_t[ j ].rakiety_ilo�� > 0 ) then
              begin

                TRakieta(rakiety_list[ i ]).planeta_docelowa := planeta_docelowa_f;
                TRakieta(rakiety_list[ i ]).id_planeta := -1;


                Wsp�rz�dne_Test_GLDummyCube.Parent := planeta_docelowa_f.losowy_obr�t_gl_dummy_cube;
                Wsp�rz�dne_Test_GLDummyCube.Position.X := TRakieta(rakiety_list[ i ]).Orbita_Odleg�o��_Ustaw( planeta_docelowa_f );
                planeta_docelowa_f.losowy_obr�t_gl_dummy_cube.Roll(  Random( 361 )  );
                //planeta_docelowa_f.losowy_obr�t_gl_dummy_cube.Roll( 5 );
                zt_vector := Wsp�rz�dne_Test_GLDummyCube.AbsolutePosition;
                Wsp�rz�dne_Test_GLDummyCube.Parent := Gra_GLScene.Objects;
                TRakieta(rakiety_list[ i ]).planeta_docelowa_wsp�rz�dne_na_orbicie := Wsp�rz�dne_Test_GLDummyCube.Parent.AbsoluteToLocal( zt_vector );


                zt_vector := TRakieta(rakiety_list[ i ]).AbsolutePosition;
                TRakieta(rakiety_list[ i ]).Parent := Gra_Obiekty_GLDummyCube;
                TRakieta(rakiety_list[ i ]).Position.AsVector := TRakieta(rakiety_list[ i ]).Parent.AbsoluteToLocal( zt_vector );

                dec( planeta_ilo��_rakiet_r_l_t[ j ].rakiety_ilo�� );

              end;
            //---//if    ( planeta_ilo��_rakiet_r_l_t[ j ].id_planeta = TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta ) (...)

        end;
      //---//if    ( if    ( TRakieta(rakiety_list[ i ]).id_grupa = id_grupa_f ) (...)

    end;
  //---//for i := 0 to rakiety_list.Count - 1 do


  SetLength( planeta_ilo��_rakiet_r_l_t, 0 );

end;//---//Funkcja Rakiety_Cel_Ustaw().

//Funkcja Rakiety_Lot_Do_Celu().
procedure TPlanety_Form.Rakiety_Lot_Do_Celu( delta_czasu_f : double );
var
  i : integer;
  zt_vector : GLS.VectorTypes.TVector4f;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  for i := 0 to rakiety_list.Count - 1 do
    if TRakieta(rakiety_list[ i ]).planeta_docelowa <> nil then
      begin

        //TRakieta(rakiety_list[ i ]).Direction.SetVector
        //  (   // Cel                 Obiekt celuj�cy
        //      TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.X - TRakieta(rakiety_list[ i ]).Position.X
        //    , TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.Y - TRakieta(rakiety_list[ i ]).Position.Y
        //    , TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.Z - TRakieta(rakiety_list[ i ]).Position.Z
        //  );

        TRakieta(rakiety_list[ i ]).Direction.SetVector
          (   // Cel                 Obiekt celuj�cy
              TRakieta(rakiety_list[ i ]).planeta_docelowa_wsp�rz�dne_na_orbicie.X - TRakieta(rakiety_list[ i ]).Position.X
            , TRakieta(rakiety_list[ i ]).planeta_docelowa_wsp�rz�dne_na_orbicie.Y - TRakieta(rakiety_list[ i ]).Position.Y
            , TRakieta(rakiety_list[ i ]).planeta_docelowa_wsp�rz�dne_na_orbicie.Z - TRakieta(rakiety_list[ i ]).Position.Z
          );

        TRakieta(rakiety_list[ i ]).Move( rakieta_pr�dko��_c * delta_czasu_f * Gra_Pr�dko��() );

        //if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.AsVector ) < TRakieta(rakiety_list[ i ]).Orbita_Odleg�o��_Ustaw( TRakieta(rakiety_list[ i ]).planeta_docelowa ) then
        if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa_wsp�rz�dne_na_orbicie ) < TRakieta(rakiety_list[ i ]).kad�ub_gl_cone.Scale.X then
          begin

            zt_vector := TRakieta(rakiety_list[ i ]).AbsolutePosition;
            TRakieta(rakiety_list[ i ]).Parent := TRakieta(rakiety_list[ i ]).planeta_docelowa.orbita_dla_rakiet_gl_dummy_cube;
            TRakieta(rakiety_list[ i ]).Position.AsVector := TRakieta(rakiety_list[ i ]).Parent.AbsoluteToLocal( zt_vector );

            TRakieta(rakiety_list[ i ]).id_planeta := TRakieta(rakiety_list[ i ]).planeta_docelowa.id_planeta;

            TRakieta(rakiety_list[ i ]).planeta_docelowa := nil;

            TRakieta(rakiety_list[ i ]).Orbita_Kierunek_Ustaw();

          end;
        //---//if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.AsVector ) < TRakieta(rakiety_list[ i ]).Orbita_Odleg�o��_Ustaw( TRakieta(rakiety_list[ i ]).planeta_docelowa ) then

      end;
    //---//if TRakieta(rakiety_list[ i ]).planeta_docelowa <> nil then

end;//---//Funkcja Rakiety_Lot_Do_Celu().

//Funkcja Walka_Efekt_Utw�rz_Jeden().
procedure TPlanety_Form.Walka_Efekt_Utw�rz_Jeden( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
var
  zt_walka_efekt : TWalka_Efekt;
begin

  if   ( walka_efekt_list = nil )
    or (  not Assigned( walka_efekt_list )  ) then
    Exit;


  zt_walka_efekt := TWalka_Efekt.Create( pozycja_rakieta_f, id_grupa_f );

  walka_efekt_list.Add( zt_walka_efekt );

end;//---//Funkcja Walka_Efekt_Utw�rz_Jeden().

//Funkcja Walka_Efekt_Zwolnij_Jeden().
procedure TPlanety_Form.Walka_Efekt_Zwolnij_Jeden( walka_efekt_f : TWalka_Efekt  );
begin

  // Usuwa� tylko w jednym miejscu. !!!
  // Wywo�anie tej funkcji w kliku miejscach mo�e co� zepsu�.

  if   ( walka_efekt_list = nil )
    or (  not Assigned( walka_efekt_list )  )
    or ( walka_efekt_f = nil ) then
    Exit;


  walka_efekt_list.Remove( walka_efekt_f );
  FreeAndNil( walka_efekt_f );

end;//---//Funkcja Walka_Efekt_Zwolnij_Jeden().

//Funkcja Walka_Efekt_Zwolnij_Wszystkie().
procedure TPlanety_Form.Walka_Efekt_Zwolnij_Wszystkie();
var
  i : integer;
begin

  if   ( walka_efekt_list = nil )
    or (  not Assigned( walka_efekt_list )  ) then
    Exit;


  for i := walka_efekt_list.Count - 1 downto 0 do
    begin

      TWalka_Efekt(walka_efekt_list[ i ]).Free();
      walka_efekt_list.Delete( i );

    end;
  //---//for i := walka_efekt_list.Count - 1 downto 0 do

end;//---//Funkcja Walka_Efekt_Zwolnij_Wszystkie().

//Funkcja Orbita_Rakiety_Zwalczanie().
procedure TPlanety_Form.Orbita_Rakiety_Zwalczanie( const poza_orbit�_tylko_f : boolean );
var
  i,
  j
    : integer;
begin

  //
  // Funkcja je�eli rakiety s� na orbicie tej samej planety i nale�� do innych grup to w wyniku walki zostaj� zniszczone
  // (jedna rakieta zwalcza jedn� rakiet� i obie znikaj�).
  //
  // Parametry:
  //   poza_orbit�_tylko_f:
  //     false - przelicza walki wszystkich rakiet.
  //     true - przelicza tylko walki rakiet nie b�d�cych na orbitach planet.
  //

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  for i := 0 to rakiety_list.Count - 1 do
    if not TRakieta(rakiety_list[ i ]).czy_usun�� then
      for j := i + 1 to rakiety_list.Count - 1 do
        if    ( not TRakieta(rakiety_list[ i ]).czy_usun�� ) // Ten warunek mo�na pomin��, gdy� jest powt�rzony wy�ej.
          and ( not TRakieta(rakiety_list[ j ]).czy_usun�� )
          and ( TRakieta(rakiety_list[ i ]).id_grupa <> TRakieta(rakiety_list[ j ]).id_grupa )
          and (
                   ( not poza_orbit�_tylko_f )
                or (
                         ( poza_orbit�_tylko_f )
                     and ( TRakieta(rakiety_list[ i ]).id_planeta = -1 ) // Rakiety poza orbit�.
                     and ( TRakieta(rakiety_list[ j ]).id_planeta = -1 ) // Rakiety poza orbit�.
                   )
              )
          //and ( TRakieta(rakiety_list[ i ]).id_planeta <> -1 )
          //and ( TRakieta(rakiety_list[ j ]).id_planeta <> -1 ) // Rakieta poza orbit�.
          and (
                   ( // Rakiety na orbicie.
                         ( TRakieta(rakiety_list[ i ]).id_planeta <> -1 )
                     and ( TRakieta(rakiety_list[ j ]).id_planeta <> -1 )
                     and (  Random( 11 ) > 9  ) // Aby rakiety nie zwalcza�y si� wszystkie w jednym momencie.
                   )
                or ( // Rakieta poza orbit� ale przelatuj� blisko siebie.
                         ( TRakieta(rakiety_list[ i ]).id_planeta = -1 )
                     and ( TRakieta(rakiety_list[ j ]).id_planeta = -1 )
                     and (  TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ j ]) ) <  0.25  )
                   )
              )
          and ( TRakieta(rakiety_list[ i ]).id_planeta = TRakieta(rakiety_list[ j ]).id_planeta ) then
          begin

            Walka_Efekt_Utw�rz_Jeden( TRakieta(rakiety_list[ i ]).AbsolutePosition, TRakieta(rakiety_list[ i ]).id_grupa );
            Walka_Efekt_Utw�rz_Jeden( TRakieta(rakiety_list[ j ]).AbsolutePosition, TRakieta(rakiety_list[ j ]).id_grupa );

            TRakieta(rakiety_list[ i ]).czy_usun�� := true;
            TRakieta(rakiety_list[ j ]).czy_usun�� := true;

            Break;

          end;
        //---//if    ( TRakieta(rakiety_list[ i ]).czy_usun�� = false ) (...)


  for i := rakiety_list.Count - 1 downto 0 do
    if TRakieta(rakiety_list[ i ]).czy_usun�� then
      begin

        TRakieta(rakiety_list[ i ]).Free();
        rakiety_list.Delete( i );

      end;
    //---//if TRakieta(rakiety_list[ i ]).czy_usun�� then

end;//---//Funkcja Orbita_Rakiety_Zwalczanie().

//Funkcja Planety_Przejmowanie_Przeliczaj().
procedure TPlanety_Form.Planety_Przejmowanie_Przeliczaj();
var
  obecno��_grupy_trzeciej : boolean; // Je�eli na orbicie planety s� wi�cej ni� dwie r�ne grupy rakiet przejmowanie nie nast�puje.
  i,
  j,
  id_grupa_obca,
  rakiety_ilo��__grupa_planety,
  rakiety_ilo��__grupa_obca
    : integer;
  ztr : real;
  zts,
  id_grupa_zmiana_planety_si_przelicz // Id grup, kt�re w danym przeliczaniu przej�y albo straci�y planety. Po przej�ciu albo straceniu planety dana grupa SI zyskuje dodatkowe przeliczenie SI.
    : string;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  id_grupa_zmiana_planety_si_przelicz := '-99';


  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        obecno��_grupy_trzeciej := false;
        id_grupa_obca := -1;
        rakiety_ilo��__grupa_planety := 0;
        rakiety_ilo��__grupa_obca := 0;


        {$region 'Wariant 1.'}
        //for j := 0 to TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
        //  if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
        //    begin
        //
        //      if TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa = TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa then
        //        inc( rakiety_ilo��__grupa_planety );
        //
        //      if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
        //        and ( id_grupa_obca = -1 ) then
        //        id_grupa_obca := TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa;
        //
        //      if TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa = id_grupa_obca then
        //        inc( rakiety_ilo��__grupa_obca );
        //
        //      if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
        //        and ( id_grupa_obca <> -1 )
        //        and ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> id_grupa_obca ) then
        //        begin
        //
        //          obecno��_grupy_trzeciej := true;
        //          Break;
        //
        //        end;
        //      //---//if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) (...)
        //
        //    end;
        //  //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
        {$endregion 'Wariant 1.'}


        rakiety_ilo��__grupa_planety := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );
        rakiety_ilo��__grupa_obca := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��() - rakiety_ilo��__grupa_planety;

        if rakiety_ilo��__grupa_obca > 0 then
          begin

            for j := 0 to TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
              if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
                begin

                  if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
                    and ( id_grupa_obca = -1 ) then
                    id_grupa_obca := TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa;


                  if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
                    and ( id_grupa_obca <> -1 )
                    and ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> id_grupa_obca ) then
                    begin

                      obecno��_grupy_trzeciej := true;
                      Break;

                    end;
                  //---//if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) (...)

                end;
              //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then

          end;
        //---//if rakiety_ilo��__grupa_obca > 0 then


        ztr := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X; // Im wi�ksza planeta tym d�u�ej trwa zdobywanie.

        if ztr = 0 then
          ztr := 1;

        ztr := ztr * 3;


        if not obecno��_grupy_trzeciej then
          begin

            if rakiety_ilo��__grupa_planety <= 0 then
              begin

                // Tracenie planety.

                if rakiety_ilo��__grupa_obca > 0 then
                  begin

                    //TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                    //    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                    //  - rakiety_ilo��__grupa_obca / ztr;

                    ztr := rakiety_ilo��__grupa_obca / ztr;


                    if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_neutralna_c )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj�ca_planet� <> id_grupa_obca ) then
                      begin

                        if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > id_grupa_neutralna_c then
                          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj�ca_planet� := id_grupa_obca
                        else//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > id_grupa_neutralna_c then
                          ztr := -ztr; // Je�eli inna grupa zaczyna zdobywa� planet� musi zneutralizowa� poziom zdobycia poprzedniej zdobywaj�cej grupy.

                      end;
                    //---//if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_neutralna_c ) (...)


                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                      - ztr;


                    if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= 0 )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_neutralna_c ) then
                      begin

                        // Grupa posiadaj�ca dotychczas planet� traci j�.

                        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_gracza_c )
                          and (  Pos( ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) + ',', id_grupa_zmiana_planety_si_przelicz + ',' ) <= 0  ) then
                          id_grupa_zmiana_planety_si_przelicz := id_grupa_zmiana_planety_si_przelicz +
                            ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );


                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa := id_grupa_neutralna_c;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj�ca_planet� := id_grupa_obca;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color := Kolor_Grupa_Ustaw( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );

                        //if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona then
                        //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );

                      end;
                    //---//if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= 0 ) (...)

                    if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= -100 then
                      begin

                        // Inna grupa zdobywa planet�.

                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa := id_grupa_obca;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj�ca_planet� := id_grupa_neutralna_c;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny := 100;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color := Kolor_Grupa_Ustaw( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );

                        //if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona then
                        //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );


                        if    ( id_grupa_obca <> id_grupa_gracza_c )
                          and (  Pos( ', ' + IntToStr( id_grupa_obca ) + ',', id_grupa_zmiana_planety_si_przelicz + ',' ) <= 0  ) then
                          id_grupa_zmiana_planety_si_przelicz := id_grupa_zmiana_planety_si_przelicz +
                            ', ' + IntToStr( id_grupa_obca );

                      end;
                    //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= -100 then


                    // Dostosowuje wygl�d planety.
                    if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c then
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color :=
                        VectorScale
                          (
                            TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color,
                            Abs( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny ) * 0.01
                          )
                    else//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c then
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color :=
                        VectorScale
                          (
                            Kolor_Grupa_Ustaw( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj�ca_planet� ),
                            Abs( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny ) * 0.01
                          );

                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.LowAtmColor.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color;

                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;
                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.0;
                    //---// Dostosowuje wygl�d planety.

                  end;
                //---//if rakiety_ilo��__grupa_obca > 0 then

              end
            else//if rakiety_ilo��__grupa_planety <= 0 then
            if    ( rakiety_ilo��__grupa_obca <= 0 )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny < 100 ) then
              begin

                // Odzyskiwanie planety.

                if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny < 100 then
                  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                    + rakiety_ilo��__grupa_planety / ztr;

                if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > 100 then
                  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny := 100;


                // Dostosowuje wygl�d planety.
                TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color :=
                  VectorScale
                    (
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color,
                      Abs( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny ) * 0.01
                    );

                TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.LowAtmColor.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color;
                //---// Dostosowuje wygl�d planety.

              end;
            //---//if    ( rakiety_ilo��__grupa_obca <= 0 ) (...)

          end;
        //---//if not obecno��_grupy_trzeciej then


        // Wizualizacja zaznaczenie planety.
        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_gracza_c )
          //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��( id_grupa_gracza_c ) <= id_grupa_neutralna_c ) then
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��( id_grupa_gracza_c ) <= id_grupa_neutralna_c ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );


        if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible )
          or ( Zaj�to��_Orbity_Wizualizuj_CheckBox.Checked ) then
          begin

            if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
              or ( Zaj�to��_Orbity_Wizualizuj_CheckBox.Checked ) then
              begin

                ztr := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��( id_grupa_gracza_c );

                if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemno��_rakiet = 0 )
                  or ( ztr >= TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemno��_rakiet ) then
                  ztr := 100
                else//if ztr >= TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemno��_rakiet then
                  ztr := 100 * ztr / TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemno��_rakiet;

              end;
            //---//if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c ) (...)


            // Buduje napis opisuj�cy planet�.
            if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible then
              begin

                TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Text := Trim(  FormatFloat( '### ### ##0', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny )  );

                if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c then
                  begin

                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Text := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Text +
                      ' | ' +
                      Trim(  FormatFloat( '### ### ##0', ztr )  );

                  end;
                //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c then


                if Planety_Opisy__Dodatkowe_Informacje_CheckBox.Checked then
                  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Text := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Text +
                    ' (id ' +  Trim(  FormatFloat( '### ### ##0', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta )  ) + ';  gr. ' +
                    Trim(  FormatFloat( '### ### ##0', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )  ) + ';  poj. ' +
                    Trim(  FormatFloat( '### ### ##0', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemno��_rakiet )  ) + '; przyr. ' +
                    Trim(  FormatFloat( '### ### ##0.00', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybko�� )  ) + ')';

              end;
            //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible then
            //---// Buduje napis opisuj�cy planet�.


            // Wizualizacja zaj�to�ci orbity planety przez rakiety.
            //if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
            //  and ( Zaj�to��_Orbity_Wizualizuj_CheckBox.Checked ) then
            //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := ztr * 0.005;

            if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
              and ( Zaj�to��_Orbity_Wizualizuj_CheckBox.Checked ) then
              //if ztr >= 100 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.25
              //else//if ztr >= 100 then
              //if ztr >= 90 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.125
              //else//if ztr >= 90 then
              //if ztr >= 80 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.06
              //else//if ztr >= 80 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0;
              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.75 * ztr * 0.01;
            //---// Wizualizacja zaj�to�ci orbity planety przez rakiety.

          end;
        //---//if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible ) (...)


        // Wizualizacja zaj�to�ci orbity planety przez rakiety.
        if    ( not Zaj�to��_Orbity_Wizualizuj_CheckBox.Checked )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha <> 0 ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pier�cie�_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0;

      end;
    //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then


  if id_grupa_zmiana_planety_si_przelicz <> '-99' then
    begin

      id_grupa_zmiana_planety_si_przelicz := id_grupa_zmiana_planety_si_przelicz + ',';
      id_grupa_zmiana_planety_si_przelicz := StringReplace( id_grupa_zmiana_planety_si_przelicz, '-99, ', '', [ rfReplaceAll ] );

      i := Pos( ',', id_grupa_zmiana_planety_si_przelicz );

      while i > 0 do
        begin

          zts := Copy( id_grupa_zmiana_planety_si_przelicz, 1, i - 1 );
          Delete( id_grupa_zmiana_planety_si_przelicz, 1, i + 1 );

          try
            j := StrToInt( zts );
          except
            j := -1;
          end;
          //---//try

          if j <> -1 then
            SI_Decyduj( j );


          i := Pos( ',', id_grupa_zmiana_planety_si_przelicz );

        end;
      //---//while i > 0 do

    end;
  //---//if id_grupa_zmiana_planety_si_przelicz <> '-99' then

end;//---//Funkcja Planety_Przejmowanie_Przeliczaj().

//Funkcja SI_Decyduj().
procedure TPlanety_Form.SI_Decyduj( const id_grupa_f : integer = -1; const decyzja_gracza__planeta_docelowa__id_planeta_f : integer = -1 );
var
  decyzje_gracza_zapami�tuj_obliczenia : boolean; // Obliczenia s� przeprowadzane tylko dla potrzeb zapami�tania konfiguracji mapy gdy gracz wykonywa� ruch.

  //Funkcja SI_Planeta_Decyduj() w SI_Decyduj().
  procedure SI_Planeta_Decyduj( const planeta_f : TPlaneta; const �rodek_geometryczny_planet_w_grupie_f : GLS.VectorTypes.TVector4f; const planety_posiadane_procent_f : real; const fann_decyduje_f : boolean; const rakiety_ilo��_w_grupie_f : integer = -1; id_planeta_z_s_f : string = '' );
  type
    TSI_Decyzja_r = record
      id_grupa,
      id_grupa_zdobywaj�ca_planet�,
      id_planeta,
      rakiety_na_orbicie_ilo��__obce,
      rakiety_na_orbicie_ilo��__w�asne
        : integer;

      decyzja_wsp�czynnik,
      odleg�o��,
      przejmowanie_poziom_aktualny,
      przyrost_szybko��,
      wielko��
        : real;

      planeta_docelowa : TPlaneta
    end;
    //---//TSI_Decyzja_r

  var
    przeliczanie_grupy : boolean; // false - gdy przelicza niezale�ne dla ka�dej planety osobno, true - gdy przelicza dla ca�ej grupy a nie pojedynczej planety.

    i_l,
    zti_l,
    decyzja_wsp�czynnik__indeks_tabeli, // Indeks tabeli decyzyjnej, w kt�rym jest wybrany wsp�czynnik decyzyjny.
    decyzja_wsp�czynnik__indeks_tabeli__fann
      : integer;

    ztr_l,
    decyzja_wsp�czynnik__najwi�kszy, // Warto�� decyzji najlepiej ocenionej.
    decyzja_wsp�czynnik__najwi�kszy__fann,
    modyfikator_losowy__planety_neutralnej,
    modyfikator_losowy__wielko��,
    rakiety_ilo��_procent_wys�anie__fann,
    rakiety_na_orbicie_ilo��, // Na orbicie planety, z kt�rej wysy�a� rakiety.
    rakiety_w_bitwie
      : real;

    wej�cia : array [ 0..9 ] of single;
    wyj�cia : array [ 0..1 ] of single;

    si_decyzja_r_t : array of TSI_Decyzja_r;
  begin//Funkcja SI_Planeta_Decyduj() w SI_Decyduj().

    if planeta_f = nil then
      Exit;


    przeliczanie_grupy :=
         ( rakiety_ilo��_w_grupie_f > -1 )
      or ( decyzje_gracza_zapami�tuj_obliczenia ); //???


    // Nie wysy�a rakiet z atakowanej planety.
    if not przeliczanie_grupy then
      if planeta_f.przejmowanie_poziom_aktualny < 100 then //???
        Exit;


    if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_pr�g_c then
      begin

        if Random( 2 ) = 1 then
          modyfikator_losowy__planety_neutralnej := 0.5
        else//if Random( 3 ) = 2 then
          modyfikator_losowy__planety_neutralnej := 0;

      end
    else//if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_pr�g_c then
      begin

        if Random( 2 ) = 1 then
          modyfikator_losowy__planety_neutralnej := 0.5
        else//if Random( 3 ) = 2 then
          modyfikator_losowy__planety_neutralnej := 1;

      end;
    //---//if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_pr�g_c then



    if Random( 5 ) >= 0 then
      modyfikator_losowy__wielko�� := 0.1
    else//if Random( 5 ) >= 0 then
      modyfikator_losowy__wielko�� := 1;


    SetLength( si_decyzja_r_t, 0 );

    for i_l := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      if    ( Gra_Obiekty_GLDummyCube.Children[ i_l ] is TPlaneta )
        and (
                 ( przeliczanie_grupy )
              or ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_planeta <> planeta_f.id_planeta )
            ) then
        begin

          zti_l := Length( si_decyzja_r_t );

          SetLength( si_decyzja_r_t, zti_l + 1 );

          si_decyzja_r_t[ zti_l ].id_grupa := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_grupa;
          si_decyzja_r_t[ zti_l ].id_grupa_zdobywaj�ca_planet� := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_grupa_zdobywaj�ca_planet�;
          si_decyzja_r_t[ zti_l ].id_planeta := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_planeta;
          //si_decyzja_r_t[ zti_l ].odleg�o�� := 100 * planeta_f.DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]) ) / si__odleg�o��_najwi�ksza_mi�dzy_planetami_g;
          si_decyzja_r_t[ zti_l ].planeta_docelowa := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]);
          si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).przejmowanie_poziom_aktualny;
          si_decyzja_r_t[ zti_l ].przyrost_szybko�� := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).przyrost_szybko�� / si__przyrost_szybko��_planety_najwi�kszy_g;
          si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__w�asne := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).Rakiety_Na_Orbicie_Ilo��( planeta_f.id_grupa );
          si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__obce := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).Rakiety_Na_Orbicie_Ilo��() - si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__w�asne;

          if si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__obce < 0 then
            si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__obce := 0;


          if not przeliczanie_grupy then
            begin

              id_planeta_z_s_f := IntToStr( planeta_f.id_planeta );
              si_decyzja_r_t[ zti_l ].odleg�o�� := 100 * planeta_f.DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]) ) / si__odleg�o��_najwi�ksza_mi�dzy_planetami_g;

            end
          else//if not przeliczanie_grupy then
            begin

              si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__w�asne := rakiety_ilo��_w_grupie_f;
              si_decyzja_r_t[ zti_l ].odleg�o�� := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).DistanceTo( �rodek_geometryczny_planet_w_grupie_f ) / si__odleg�o��_najwi�ksza_mi�dzy_planetami_g;

            end;
          //---//if not przeliczanie_grupy then


          si_decyzja_r_t[ zti_l ].wielko�� := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).planeta_kula_gl_sphere.Scale.X / si__wielko��_planety_najwi�ksza_g;


          si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik :=
              ( 100 - si_decyzja_r_t[ zti_l ].wielko�� ) * 0.5 * modyfikator_losowy__wielko�� // Im mniejsza tym lepiej.
            + ( 100 - si_decyzja_r_t[ zti_l ].odleg�o�� ); // Im mniejsza tym lepiej.


          // Odzyskiwanie w�asnych planet.
          if    ( si_decyzja_r_t[ zti_l ].id_grupa = planeta_f.id_grupa )
            and ( si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny < 100 ) then
            si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
              + ( 100 - si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny ) * 2;

          // Wspiera zdobycie planety.
          if si_decyzja_r_t[ zti_l ].id_grupa_zdobywaj�ca_planet� = planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
              + Abs( si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny );


          if not przeliczanie_grupy then
            rakiety_na_orbicie_ilo�� := planeta_f.Rakiety_Na_Orbicie_Ilo��( planeta_f.id_grupa )
          else//if not przeliczanie_grupy then
            rakiety_na_orbicie_ilo�� := rakiety_ilo��_w_grupie_f;

          // Stosunek rakiet tej samej grupy na orbicie analizowanej planety wraz z rakietami na orbicie planety, z kt�rej rakiety mog� by� wys�ane do rakiet wrogich na orbicie analizowanej planety.
          rakiety_w_bitwie := rakiety_na_orbicie_ilo�� + si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__w�asne + si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__obce;

          if rakiety_w_bitwie > 0 then
            begin

              ztr_l := 100 * ( si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_ilo��__w�asne + rakiety_na_orbicie_ilo�� ) / rakiety_w_bitwie;

              // Je�eli przewaga rakiet grupy wynosi ponad 50% dodaje do decyzji nadwy�k� procentu ponad 50.
              if ztr_l > 50 then
                si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
                  + ztr_l - 50;

            end;
          //---//rakiety_w_bitwie
          //---// Stosunek rakiet tej samej grupy na orbicie analizowanej planety wraz z rakietami na orbicie planety, z kt�rej rakiety mog� by� wys�ane do rakiet wrogich na orbicie analizowanej planety.


          if not przeliczanie_grupy then
            begin

              // Wsp�czynnik zape�nienia planety. //???
              if planeta_f.pojemno��_rakiet <> 0 then
                ztr_l := 100 * rakiety_na_orbicie_ilo�� / planeta_f.pojemno��_rakiet
              else//if planeta_f.pojemno��_rakiet <> 0 then
                ztr_l := 0;


              // Je�eli zape�nienia planety wynosi ponad 50% dodaje do decyzji nadwy�k� procentu ponad 50.
              if ztr_l >= 50 then
                si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
                  + ztr_l - 50;
              //---// Wsp�czynnik zape�nienia planety.

            end;
          //---//if not przeliczanie_grupy then


          // Preferowane do wys�ania rakiet s� planety neutralne, potem planety przeciwnik�w, na ko�cu w�asne.
          if si_decyzja_r_t[ zti_l ].id_grupa = id_grupa_neutralna_c then
            si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
              + 100 * modyfikator_losowy__planety_neutralnej
          else
          if si_decyzja_r_t[ zti_l ].id_grupa <> planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
              + 50
          else
          if si_decyzja_r_t[ zti_l ].id_grupa = planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik := si_decyzja_r_t[ zti_l ].decyzja_wsp�czynnik
              - 50;
          //---// Preferowane do wys�ania rakiet s� planety neutralne, potem planety przeciwnik�w, na ko�cu w�asne.

        end;
      //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i_l ] is TPlaneta ) (...)


    if not decyzje_gracza_zapami�tuj_obliczenia then
      begin

        if SI_Loguj_CheckBox.Checked then
          begin

            SI_Log_Memo.Lines.Add( '' );
            SI_Log_Memo.Lines.Add( '' );

            if przeliczanie_grupy then
              begin

                SI_Log_Memo.Lines.Add(   'Z id ' + Trim(  FormatFloat( '### ### ##0', planeta_f.id_planeta )  ) + ', planety posiadane procent ' + Trim(  FormatFloat( '### ### ##0', planety_posiadane_procent_f )  ) + ' (pr�g ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__planety_posiadane_procent_pr�g_c )  ) + ')'   );
                SI_Log_Memo.Lines.Add( '  przeliczanie grupy - tak' );

              end
            else//if przeliczanie_grupy then
              begin

                SI_Log_Memo.Lines.Add(   'Z id ' + Trim(  FormatFloat( '### ### ##0', planeta_f.id_planeta )  )   );
                SI_Log_Memo.Lines.Add( '  przeliczanie grupy - nie' );

              end;
            //---//if przeliczanie_grupy then

          end;
        //---//if SI_Loguj_CheckBox.Checked then


        decyzja_wsp�czynnik__indeks_tabeli := -99;
        decyzja_wsp�czynnik__indeks_tabeli__fann := -99;
        rakiety_ilo��_procent_wys�anie__fann := 100;


        for i_l := 0 to Length( si_decyzja_r_t ) - 1 do
          begin

            if   ( not fann_decyduje_f )
              or ( fann_network = nil ) then
              begin

                if   ( i_l = 0 ) // Pierwsze podstawienie warto�ci.
                  or (
                           ( i_l > 0 )
                       and ( decyzja_wsp�czynnik__najwi�kszy < si_decyzja_r_t[ i_l ].decyzja_wsp�czynnik )
                     ) then
                  begin

                    decyzja_wsp�czynnik__indeks_tabeli := i_l;
                    decyzja_wsp�czynnik__najwi�kszy := si_decyzja_r_t[ i_l ].decyzja_wsp�czynnik;

                  end;
                //---//if   ( i_l = 0 ) (...)


                if SI_Loguj_CheckBox.Checked then
                  begin

                    SI_Log_Memo.Lines.Add( '' );
                    SI_Log_Memo.Lines.Add(   'id ' + Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_planeta )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].decyzja_wsp�czynnik )  )   );

                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_grupa )  ) + ' id_grupa'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_grupa_zdobywaj�ca_planet� )  ) + ' id_grupa_zdobywaj�ca_planet�'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].odleg�o�� )  ) + ' odleg�o��'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny )  ) + ' przejmowanie_poziom_aktualny'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].przyrost_szybko�� )  ) + ' przyrost_szybko��'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__obce )  ) + ' rakiety_na_orbicie_ilo��__obce'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__w�asne )  ) + ' rakiety_na_orbicie_ilo��__w�asne'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].wielko�� )  ) + ' wielko��'   );

                  end;
                //---//if SI_Loguj_CheckBox.Checked then

              end
            else//if   ( not fann_decyduje_f ) (...)
              begin

                if fann_network <> nil then
                  begin

                    if si_decyzja_r_t[ i_l ].id_grupa = planeta_f.id_grupa then // planeta nale�y do gracza (0 - nie, 1 - tak).
                      wej�cia[ 0 ] := 1
                    else//if si_decyzja_r_t[ i_l ].id_grupa = planeta_f.id_grupa then
                      wej�cia[ 0 ] := 0;

                    if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj�ca_planet� = 0 then // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planet�, 2 - planet� zdobywa grupa nie gracza).
                      wej�cia[ 1 ] := 0
                    else
                    if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj�ca_planet� = id_grupa_gracza_c then
                      wej�cia[ 1 ] := 1
                    else
                      wej�cia[ 1 ] := 2;

                    wej�cia[ 2 ] := si_decyzja_r_t[ i_l ].odleg�o��;
                    wej�cia[ 3 ] := planety_ilo��_mapa_g;
                    wej�cia[ 4 ] := planety_posiadane_procent_f;
                    wej�cia[ 5 ] := si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny;
                    wej�cia[ 6 ] := si_decyzja_r_t[ i_l ].przyrost_szybko��;
                    wej�cia[ 7 ] := si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__obce;
                    wej�cia[ 8 ] := si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__w�asne;
                    wej�cia[ 9 ] := si_decyzja_r_t[ i_l ].wielko��;

                    fann_network.Run( wej�cia, wyj�cia );


                    if   ( i_l = 0 ) // Pierwsze podstawienie warto�ci.
                      or (
                               ( i_l > 0 )
                           and ( decyzja_wsp�czynnik__najwi�kszy__fann < wyj�cia[ 0 ] )
                         ) then
                      begin

                        decyzja_wsp�czynnik__indeks_tabeli__fann := i_l;
                        decyzja_wsp�czynnik__najwi�kszy__fann := wyj�cia[ 0 ];
                        rakiety_ilo��_procent_wys�anie__fann := wyj�cia[ 1 ];

                        // Po nauczaniu wychodz� mi jakie� bardzo ma�e u�amkowe warto�ci.
                        //if rakiety_ilo��_procent_wys�anie__fann < 0 then
                        //  rakiety_ilo��_procent_wys�anie__fann := 0; //???

                        if rakiety_ilo��_procent_wys�anie__fann < 10 then //???
                          rakiety_ilo��_procent_wys�anie__fann := 100; //???

                      end;
                    //---//if   ( i_l = 0 ) (...)


                    if SI_Loguj_CheckBox.Checked then
                      begin

                        SI_Log_Memo.Lines.Add(   'SI id ' + Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_planeta )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.0000', wyj�cia[ 0 ] )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.0000', wyj�cia[ 1 ] ) + '%'  )   );

                      end;
                    //---//if SI_Loguj_CheckBox.Checked then

                  end;
                //---//if fann_network <> nil then

              end;
            //---//if   ( not fann_decyduje_f ) (...)

          end;
        //---//for i_l := 0 to Length( si_decyzja_r_t ) - 1 do


        if   ( not fann_decyduje_f )
          or ( decyzja_wsp�czynnik__indeks_tabeli__fann = -99 ) then
          begin

            if    ( decyzja_wsp�czynnik__indeks_tabeli <> -99 )
              and ( decyzja_wsp�czynnik__najwi�kszy > 0 ) then
              //Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + IntToStr( planeta_f.id_planeta ) + ', -99', si_decyzja_r_t[ decyzja_wsp�czynnik__indeks_tabeli ].planeta_docelowa  );
              Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + id_planeta_z_s_f + ', -99', si_decyzja_r_t[ decyzja_wsp�czynnik__indeks_tabeli ].planeta_docelowa, 100  );

          end
        else//if   ( not fann_decyduje_f ) (...)
          begin

            if    ( fann_network <> nil )
              and ( decyzja_wsp�czynnik__indeks_tabeli__fann <> -99 ) then
              //and ( decyzja_wsp�czynnik__najwi�kszy__fann > 0 ) then //???
              Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + id_planeta_z_s_f + ', -99', si_decyzja_r_t[ decyzja_wsp�czynnik__indeks_tabeli__fann ].planeta_docelowa, rakiety_ilo��_procent_wys�anie__fann  );

          end;
        //---//if   ( not fann_decyduje_f ) (...)

      end
    else//if not decyzje_gracza_zapami�tuj_obliczenia then
      begin

        if Length( si_decyzja_r_t ) > 0 then
          begin

            inc( decyzje_gracza_numer_g );


            if decyzje_gracza_g = '' then
              decyzje_gracza_g := decyzje_gracza_g + // Za pierwszym razem wpisuje nag��wki kolumn.
                'id_planeta;' +
                'planeta jest planet� docelow�;' +
                'planeta nale�y do gracza;' +
                'id_planeta_docelowa;' +
                'grupa_zdobywaj�ca_planet�;' +
                'odleg�o��;' +
                'planety_ilo��_mapa;' +
                'planety_posiadane_procent;' +
                'przejmowanie_poziom_aktualny;' +
                'przyrost_szybko��;' +
                'rakiety_ilo��_procent_wys�anie;' +
                'rakiety_na_orbicie_ilo��__obce;' +
                'rakiety_na_orbicie_ilo��__w�asne;' +
                'wielko��;'
            else//if decyzje_gracza_g = '' then
              decyzje_gracza_g := decyzje_gracza_g + // Separuje dane przy kolejnych decyzjach.
                #13#10 +
                '--- ' + IntToStr( decyzje_gracza_numer_g ) + ' ---';

          end;
        //---//if Length( si_decyzja_r_t ) > 0 then


        for i_l := 0 to Length( si_decyzja_r_t ) - 1 do
          begin

            decyzje_gracza_g := decyzje_gracza_g + #13#10;


            decyzje_gracza_g := decyzje_gracza_g + IntToStr( si_decyzja_r_t[ i_l ].id_planeta ) + ';';

            if si_decyzja_r_t[ i_l ].id_planeta = decyzja_gracza__planeta_docelowa__id_planeta_f then
              decyzje_gracza_g := decyzje_gracza_g + '1;'
            else//if si_decyzja_r_t[ i_l ].id_planeta = decyzja_gracza__planeta_docelowa__id_planeta_f then
              decyzje_gracza_g := decyzje_gracza_g + '0;';

            if si_decyzja_r_t[ i_l ].id_grupa = id_grupa_gracza_c then
              decyzje_gracza_g := decyzje_gracza_g + '1;'
            else//if si_decyzja_r_t[ i_l ].id_grupa = id_grupa_gracza_c then
              decyzje_gracza_g := decyzje_gracza_g + '0;';

            decyzje_gracza_g := decyzje_gracza_g + IntToStr( decyzja_gracza__planeta_docelowa__id_planeta_f ) + ';';

            // Zmienia si� gdy jaka� grupa straci�a albo przej�a planet� (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planet�, 2 - planet� zdobywa grupa nie gracza).
            if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj�ca_planet� = 0 then
              decyzje_gracza_g := decyzje_gracza_g + '0;'
            else
            if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj�ca_planet� = id_grupa_gracza_c then
              decyzje_gracza_g := decyzje_gracza_g + '1;'
            else
              decyzje_gracza_g := decyzje_gracza_g + '2;';

            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].odleg�o�� )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', planety_ilo��_mapa_g )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', planety_posiadane_procent_f )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + StringReplace(   Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny )  ), ' ', '', [ rfReplaceAll ]   ) + ';'; // Warto�ci ujemne maj� minus przed spacj�.
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].przyrost_szybko�� )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__obce ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( si_decyzja_r_t[ i_l ].rakiety_na_orbicie_ilo��__w�asne ) + ';'; // W przypadku gracza s� to jego wszystkie rakiety na wszystkich orbitach (bez tych aktualnie lec�cych).
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].wielko�� )  ) + ';';

          end;
        //---//for i_l := 0 to Length( si_decyzja_r_t ) - 1 do

        //SI_Log_Memo.Lines.Add( '' );
        //SI_Log_Memo.Lines.Add( decyzje_gracza_g );

      end;
    //---//if not decyzje_gracza_zapami�tuj_obliczenia then

    SetLength( si_decyzja_r_t, 0 );

  end;//---//Funkcja SI_Planeta_Decyduj() w SI_Decyduj().

var
  grupa_fann_decyduje : boolean;
  i,
  j,
  zti,
  planeta_indeks,
  planety_ilo��_w_grupie,
  rakiety_ilo��_w_grupie
    : integer;
  planety_posiadane_procent : real; // Jaki procent wszystkich planet posiada grupa.
  id_planeta_z_s // Wszystkie planety, z kt�rych grupa wysy�a (mo�e wys�a�) rakiety.
    : string;
  �rodek_geometryczny_planet_w_grupie : GLS.VectorTypes.TVector4f;
begin//Funkcja SI_Decyduj().

  // Decyduje o ruchach SI.
  // Parametry:
  //   id_grupa_f
  //     = -1 - przelicza wszystkie grupy.
  //     <> -1 - przelicza wskazan� grup�.
  //

  if   (  Length( statystyki_tabela_t ) <= 0  )
    or ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  if SI_Loguj_CheckBox.Checked then
    begin

      SI_Log_Memo.Lines.Clear();
      SI_Log_Memo.Lines.Add(   'Cz�stotliwo�� decyzji SI ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__cykl_sekundy_g )  ) + ' (~ ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__cykl_sekundy__modyfikator_losowy_g )  ) + ') sekund.'   );

    end;
  //---//if SI_Loguj_CheckBox.Checked then


  decyzje_gracza_zapami�tuj_obliczenia :=
        ( id_grupa_f = id_grupa_gracza_c )
    and ( decyzja_gracza__planeta_docelowa__id_planeta_f > -1 );


  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    begin

      if    (    (
                       ( not decyzje_gracza_zapami�tuj_obliczenia )
                   and ( statystyki_tabela_t[ i ][ 0 ] <> id_grupa_gracza_c )
                 )
              or (
                       ( decyzje_gracza_zapami�tuj_obliczenia )
                   and ( statystyki_tabela_t[ i ][ 0 ] = id_grupa_gracza_c )
                 )
            )
        and (
                 ( id_grupa_f = -1 )
              or ( id_grupa_f = statystyki_tabela_t[ i ][ 0 ] )
            ) then
        begin

          grupa_fann_decyduje := false;

          {$IFDEF si_fann_u�ywaj}
          for j := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
            if Grupa_Fann_Decyduje_CheckListBox.Items[ j ] = IntToStr( statystyki_tabela_t[ i ][ 0 ] ) then
              begin

                grupa_fann_decyduje := Grupa_Fann_Decyduje_CheckListBox.Checked[ j ];
                Break;

              end;
            //---//if Grupa_Fann_Decyduje_CheckListBox.Items[ j ] = IntToStr( statystyki_tabela_t[ i ][ 0 ] ) then
          {$ENDIF}


          planety_ilo��_w_grupie := 0;

          for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
              inc( planety_ilo��_w_grupie );


          if planety_ilo��_mapa_g <> 0 then
            planety_posiadane_procent := 100 * planety_ilo��_w_grupie / planety_ilo��_mapa_g
          else//if planety_ilo��_mapa_g <> 0 then
            planety_posiadane_procent := 0;


          zti := System.Math.Floor( planety_posiadane_procent * 0.1 ); // Im wi�cej planet (procentowo) ma grupa tym cz�ciej planety decyduj� niezale�nie aby zamiast wysy�a� jednej du�ej floty powstawa�y mniejsze floty.

          if zti >= 7 then
            zti := 6;


          if   ( decyzje_gracza_zapami�tuj_obliczenia )
            or (  Random( 11 ) <= 7 - zti  ) then
            begin

              // Decydowanie dla wszystkich planet w grupie razem.

              planeta_indeks := -99;

              �rodek_geometryczny_planet_w_grupie := GLS.VectorGeometry.VectorMake( 0, 0, 0 );
              //planety_ilo��_w_grupie := 0;
              rakiety_ilo��_w_grupie := 0;
              id_planeta_z_s := '';


              //for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
              //  if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              //    //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
              //    and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
              //    inc( planety_ilo��_w_grupie );
              //
              //
              //if planety_ilo��_mapa_g <> 0 then
              //  planety_posiadane_procent := 100 * planety_ilo��_w_grupie / planety_ilo��_mapa_g
              //else//if planety_ilo��_mapa_g <> 0 then
              //  planety_posiadane_procent := 0;


              for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
                if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
                  //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
                  and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
                  begin

                    if planeta_indeks = -99 then
                      planeta_indeks := j;

                    //inc( planety_ilo��_w_grupie );


                    zti := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).Rakiety_Na_Orbicie_Ilo��( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa );


                    if    (
                               ( planety_ilo��_w_grupie > 4 )
                            or ( planety_posiadane_procent > si_decyduj__planety_posiadane_procent_pr�g_c )
                          )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).pojemno��_rakiet <> 0 )
                      and ( 100 * zti / TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).pojemno��_rakiet >= planety_posiadane_procent ) then
                      begin

                        // Aby, gdy ma ju� troch� planet, wysy�a� rakiety w wi�kszych odst�pach czasu.

                        rakiety_ilo��_w_grupie := rakiety_ilo��_w_grupie
                          + zti;


                        if id_planeta_z_s <> '' then
                          id_planeta_z_s := id_planeta_z_s + ', ';

                        id_planeta_z_s := id_planeta_z_s + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_planeta );

                      end
                    else//if    ( (...)
                      begin

                        rakiety_ilo��_w_grupie := rakiety_ilo��_w_grupie
                          + zti;


                        if id_planeta_z_s <> '' then
                          id_planeta_z_s := id_planeta_z_s + ', ';

                        id_planeta_z_s := id_planeta_z_s + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_planeta );

                      end;
                    //---//if    ( (...)


                    �rodek_geometryczny_planet_w_grupie.X := �rodek_geometryczny_planet_w_grupie.X + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.X;
                    �rodek_geometryczny_planet_w_grupie.Y := �rodek_geometryczny_planet_w_grupie.Y + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.Y;
                    �rodek_geometryczny_planet_w_grupie.Z := �rodek_geometryczny_planet_w_grupie.Z + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.Z;

                  end;
                //---//if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta ) (...)

              if planety_ilo��_w_grupie <> 0 then
                begin

                  GLS.VectorGeometry.ScaleVector( �rodek_geometryczny_planet_w_grupie, 1 / planety_ilo��_w_grupie );

                end;
              //---//if planety_ilo��_w_grupie <> 0 then


              if planeta_indeks <> -99 then // Zapami�tany indeks planety z grupy aby w funkcji zna� id grupy.
                SI_Planeta_Decyduj( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ planeta_indeks ]), �rodek_geometryczny_planet_w_grupie, planety_posiadane_procent, grupa_fann_decyduje, rakiety_ilo��_w_grupie, id_planeta_z_s );

            end
          else//if   ( decyzje_gracza_zapami�tuj_obliczenia ) (...)
            begin

              // Decydowanie niezale�ne dla ka�dej planety osobno.

              for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
                if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
                  //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
                  and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
                  SI_Planeta_Decyduj( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]), �rodek_geometryczny_planet_w_grupie, 0, grupa_fann_decyduje );

            end;
          //---//if   ( decyzje_gracza_zapami�tuj_obliczenia ) (...)


          if    ( id_grupa_f <> -1)
            and ( id_grupa_f = statystyki_tabela_t[ i ][ 0 ] ) then
            Break;

        end;
      //---//if    ( statystyki_tabela_t[ i ][ 0 ] <> id_grupa_gracza_c ) (...)

    end;
  //---//for i := 0 to Length( statystyki_tabela_t ) - 1 do

end;//---//Funkcja SI_Decyduj().

//Funkcja SI_Decyduj__Modyfikator_Losowy_Ustaw().
procedure TPlanety_Form.SI_Decyduj__Modyfikator_Losowy_Ustaw();
begin

  si_decyduj__cykl_sekundy__modyfikator_losowy_g := System.Math.Floor( si_decyduj__cykl_sekundy_g * 0.5 );

  si_decyduj__cykl_sekundy__modyfikator_losowy_g := si_decyduj__cykl_sekundy__modyfikator_losowy_g - Random( si_decyduj__cykl_sekundy__modyfikator_losowy_g * 2 + 1 );

end;//---//Funkcja SI_Decyduj__Modyfikator_Losowy_Ustaw().

//Funkcja Zwyci�stwo_Sprawd�().
function TPlanety_Form.Zwyci�stwo_Sprawd�( out id_grupa_wy : integer ) : boolean;
var
  i : integer;
begin

  //
  // Funkcja sprawdza czy kt�ra� grupa wygra�a.
  //
  // Zwraca prawd� gdy kt�ra� grupa wygra�a.
  //
  // Parametry:
  //   id_grupa_wy - id zwyci�skiej grupy.
  //

  Result := false;


  id_grupa_wy := id_grupa_neutralna_c;

  // Sprawdza czy wszystkie planety s� neutralne b�d� w posiadaniu tylko jednej grupy.
  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        if    ( id_grupa_wy <> id_grupa_neutralna_c )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c ) // Neutralnych planet nie uwzgl�dnia podczas sprawdzania warunk�w zwyci�stwa.
          and ( id_grupa_wy <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) then
          Exit; // Planety s� w posiadaniu ro�nych nie neutralnych grup.


        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c )
          and ( id_grupa_wy = id_grupa_neutralna_c ) then
          id_grupa_wy := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa;

      end;
    //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
  //---// Sprawdza czy wszystkie planety s� neutralne b�d� w posiadaniu tylko jednej grupy.


  // Sprawdza czy wszystkie rakiety nale��ce tylko do jednej grupy.
  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;

  id_grupa_wy := id_grupa_neutralna_c; // Neutralnych rakiet nie uwzgl�dnia podczas sprawdzania warunk�w zwyci�stwa.

  for i := 0 to rakiety_list.Count - 1 do
    begin

      if    ( id_grupa_wy <> id_grupa_neutralna_c )
        and ( id_grupa_wy <> TRakieta(rakiety_list[ i ]).id_grupa ) then
        Exit; // Istniej� rakiety nale��ce do ro�nych grup.


      if id_grupa_wy = id_grupa_neutralna_c then
        id_grupa_wy := TRakieta(rakiety_list[ i ]).id_grupa;

    end;
  //---//for i := 0 to rakiety_list.Count - 1 do
  //---// Sprawdza czy wszystkie rakiety nale��ce tylko do jednej grupy.


  Result := true;

end;//---//Funkcja Zwyci�stwo_Sprawd�().

//Funkcja Przegrana_Gracza_Sprawd�().
function TPlanety_Form.Przegrana_Gracza_Sprawd�( out id_grupa_wy : integer ) : boolean;
var
  i : integer;
begin

  //
  // Funkcja sprawdza czy gracz straci� wszystkie planety i rakiety.
  //
  // Zwraca prawd� gdy gracz straci� wszystkie planety i rakiety.
  //
  // Parametry:
  //   id_grupa_wy - aby w innej funkcji ustawi� warto��, �e to nie grupa gracza wygrywa.
  //

  Result := false;


  id_grupa_wy := -id_grupa_gracza_c;


  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if   ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
     and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c ) then
     Exit; // Gracz posiada planety.


  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    begin

      Result := true;
      Exit;

    end;
  //---//if   ( rakiety_list = nil )


  for i := 0 to rakiety_list.Count - 1 do
    if TRakieta(rakiety_list[ i ]).id_grupa = id_grupa_gracza_c then
      Exit; // Gracz posiada rakiety.


  Result := true;

end;//---//Funkcja Przegrana_Gracza_Sprawd�().

//Funkcja Statystyki_Tabela_Utw�rz().
procedure TPlanety_Form.Statystyki_Tabela_Utw�rz();
var
  ztb : boolean;
  i,
  j
    : integer;
  zts : string;
begin

  // Dodaje tyle wierszy ile jest niepowtarzalnych grup.

  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_neutralna_c ) then
      begin

        ztb := false;

        for j := 0 to Length( statystyki_tabela_t ) - 1 do
          if statystyki_tabela_t[ j ][ 0 ] = TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa then
            begin

              ztb := true; // W tabeli statystyk jest ju� dana grupa.
              Break;

            end;
          //---//if statystyki_tabela_t[ j ][ 0 ] = TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa then

        if not ztb then
          begin

            j := Length( statystyki_tabela_t );
            SetLength( statystyki_tabela_t, j + 1 );
            SetLength( statystyki_tabela_t[ j ], 1 );

            statystyki_tabela_t[ j ][ 0 ] := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa;

          end;
        //---//if not ztb then

      end;
    //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)


  // Sortuje (b�belkowo) tabel� statystyk wed�ug grup.
  ztb := true;

  while ztb do
    begin

      ztb := false;

      for i := 0 to Length( statystyki_tabela_t ) - 2 do
        if statystyki_tabela_t[ i ][ 0 ] > statystyki_tabela_t[ i + 1 ][ 0 ] then
          begin

            j := statystyki_tabela_t[ i ][ 0 ];
            statystyki_tabela_t[ i ][ 0 ] := statystyki_tabela_t[ i + 1 ][ 0 ];
            statystyki_tabela_t[ i + 1 ][ 0 ] := j;

            if not ztb then
              ztb := true; // Oznacza, �e by�a zmiana kolejno�ci w tabeli.

          end;
        //---//if statystyki_tabela_t[ i ][ 0 ] > statystyki_tabela_t[ i + 1 ][ 0 ] then

    end;
  //---//while ztb do


  {$IFDEF si_fann_u�ywaj}
  // Zapami�tuje zaznaczone grupy.
  zts := ', ';

  for i := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
    if Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] then
      zts := zts + Grupa_Fann_Decyduje_CheckListBox.Items[ i ] + ', ';
  //---// Zapami�tuje zaznaczone grupy.


  Grupa_Fann_Decyduje_CheckListBox.Items.Clear();


  // Wpisuje niepowtarzalne grupy do listy wyboru sposobu podejmowania decyzji.
  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    if statystyki_tabela_t[ i ][ 0 ] <> id_grupa_gracza_c then
      Grupa_Fann_Decyduje_CheckListBox.Items.Add(  IntToStr( statystyki_tabela_t[ i ][ 0 ] )  );


  // Zaznacza poprzednio zaznaczone grupy.
  for i := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
    if Pos( ', ' + Grupa_Fann_Decyduje_CheckListBox.Items[ i ] + ',', zts ) > 0 then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := true;
  //---// Zaznacza poprzednio zaznaczone grupy.
  {$ENDIF}

end;//---//Funkcja Statystyki_Tabela_Utw�rz().

//Funkcja Statystyki_Tabela_Warto�ci_Kolejne_Zapami�taj().
procedure TPlanety_Form.Statystyki_Tabela_Warto�ci_Kolejne_Zapami�taj();
var
  i,
  j,
  zti,
  rakiety_ilo��
    : integer;
begin

  // Dopisuje kolejn� kolumn� z ilo�ci� rakiet ka�dej grupy.

  if   (  Length( statystyki_tabela_t ) <= 0  )
    or ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  zti := Length( statystyki_tabela_t[ 0 ] );

  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    begin

      SetLength( statystyki_tabela_t[ i ], zti + 1 );


      rakiety_ilo�� := 0;

      for j := 0 to rakiety_list.Count - 1 do
        if TRakieta(rakiety_list[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] then
          inc( rakiety_ilo�� );


      statystyki_tabela_t[ i ][ zti ] := rakiety_ilo��;

    end;
  //---//for i := 0 to Length( statystyki_tabela_t ) - 1 do

end;//---//Funkcja Statystyki_Tabela_Warto�ci_Kolejne_Zapami�taj().

//Funkcja Statystyki_Tabela_Czy��().
procedure TPlanety_Form.Statystyki_Tabela_Czy��();
var
  i : integer;
begin

  // Czy�ci tabel� statystyk.

  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    SetLength( statystyki_tabela_t[ i ], 0 );

  SetLength( statystyki_tabela_t, 0 );

end;//---//Funkcja Statystyki_Tabela_Czy��().

//Funkcja Statystyki_Wy�wietl().
procedure TPlanety_Form.Statystyki_Wy�wietl( const {czy_przyciski_f,} czy_zwyci�stwo_f : boolean; const id_grupa_f : integer );

  //Funkcja Statystyki_Generuj_Warto�ci_Do_Test�w().
  procedure Statystyki_Generuj_Warto�ci_Do_Test�w();
  var
    i,
    j,
    zti
      : integer;
  begin

    if Length( statystyki_tabela_t ) <= 0 then
      begin

        for i := 1 to 3 do
          begin

            j := Length( statystyki_tabela_t );
            SetLength( statystyki_tabela_t, j + 1 );
            SetLength( statystyki_tabela_t[ j ], 1 );

            statystyki_tabela_t[ j ][ 0 ] := i;


          end;
        //---//for i := 1 to 3 do


        for j := 1 to 40 do
          begin

            zti := Length( statystyki_tabela_t[ 0 ] );

            for i := 0 to Length( statystyki_tabela_t ) - 1 do
              begin

                SetLength( statystyki_tabela_t[ i ], zti + 1 );

                if i = 0 then
                  statystyki_tabela_t[ i ][ zti ] := j
                else
                if i = 1 then
                  statystyki_tabela_t[ i ][ zti ] := j * 2
                else
                if i = 2 then
                  statystyki_tabela_t[ i ][ zti ] := Random( 20 ) //j * 3
                else
                  statystyki_tabela_t[ i ][ zti ] := ( i + j ) * 10;

              end;
            //---//for i := 0 to Length( statystyki_tabela_t ) - 1 do

          end;
        //---//for j := 1 to 3 do

      end;
    //---//if Length( statystyki_tabela_t ) <= 0 then

  end;//---//Funkcja Statystyki_Generuj_Warto�ci_Do_Test�w().

var
  czy_pauza,
  czy_stop // Czy poleceniem okna statystyk by� stop.
    : boolean;
  i,
  zti
    : integer;
  zt_modal_result : TModalResult;
begin//Funkcja Statystyki_Wy�wietl().

  czy_pauza := not GLCadencer1.Enabled;
  czy_stop := false;

  if not czy_pauza then
    Pauza_ButtonClick( nil );


  Statystyki_Form := TStatystyki_Form.Create( Application );

  Statystyki_Form.Zwyci�stwo_Label.Visible := czy_zwyci�stwo_f;
  //Statystyki_Form.Przyciski_Panel.Visible := czy_przyciski_f;

  Statystyki_Form.Nast�pna_Misja_Button.Enabled := Nast�pna_Misja_Button.Enabled;
  //Statystyki_Form.Pauza_Button.Enabled := not czy_pauza;
  Statystyki_Form.Stop_Button.Enabled := Start_Stop_Button.Tag = 1;

  if czy_pauza then
    Statystyki_Form.Pauza_Button.Font.Style := [ fsBold ];

  Statystyki_Form.czy_zwyci�stwo := czy_zwyci�stwo_f;
  Statystyki_Form.id_grupa_zwyci�ska := id_grupa_f;

  if czy_zwyci�stwo_f then
    begin

      if Mapa_Wybieraj_Losowo_CheckBox.Checked then
        begin

          zti := 0;


          for i := 0 to Length( mapa_rozegrana_t ) - 1 do
            if mapa_rozegrana_t[ i ] then
              inc( zti );


          if zti = Length( mapa_rozegrana_t ) then
            begin

              zti := -1;

              //for i := 0 to Length( mapa_rozegrana_t ) - 1 do
              //  mapa_rozegrana_t[ i ] := false;

              //Mapy_Losowe_Etykieta_Wylicz();

            end
          else//if zti = Length( mapa_rozegrana_t ) then
            zti := 1;

        end;
      //---//if Mapa_Wybieraj_Losowo_CheckBox.Checked then


      if   (
                 ( not Mapa_Wybieraj_Losowo_CheckBox.Checked )
             and ( Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 )
           )
        or (
                 ( Mapa_Wybieraj_Losowo_CheckBox.Checked )
             and ( zti = -1 )
           ) then
        begin

          if id_grupa_f = id_grupa_gracza_c then
            Statystyki_Form.Caption := 'Ostateczne zwyci�stwo'
          else//if id_grupa_f = id_grupa_gracza_c then
            Statystyki_Form.Caption := 'Przegrana';

          Statystyki_Form.Nast�pna_Misja_Button.Visible := false; //???

        end
      else//if   ( (...)
        if id_grupa_f = id_grupa_gracza_c then
          Statystyki_Form.Caption := 'Zwyci�stwo'
        else//if id_grupa_f = id_grupa_gracza_c then
          Statystyki_Form.Caption := 'Przegrana';

    end;
  //---//if czy_zwyci�stwo_f then


  Statystyki_Form.Zwyci�stwo_Label.Caption := Statystyki_Form.Caption;


  ////Statystyki_Form.Statystyki_Image.Canvas.Rectangle( 10, 20, 500, 700 );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut( 10, 10, 'Rakiety utworzone / stracone' );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut(   10, 30, 'w misji: ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_utworzonych__misja )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_straconych__misja )  )   );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut(   10, 50, 'w grze: ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_utworzonych__gra )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_straconych__gra )  )   );


  //Statystyki_Generuj_Warto�ci_Do_Test�w(); //???


  Statystyki_Form.Wykres_Liniowy_MenuItem.Checked := statystyki_wykres_liniowy_menuitem_checked_g;
  Statystyki_Form.Wykres_S�upkowy_MenuItem.Checked := statystyki_wykres_s�upkowy_menuitem_checked_g;

  zt_modal_result := Statystyki_Form.ShowModal();

  statystyki_wykres_liniowy_menuitem_checked_g := Statystyki_Form.Wykres_Liniowy_MenuItem.Checked;
  statystyki_wykres_s�upkowy_menuitem_checked_g := Statystyki_Form.Wykres_S�upkowy_MenuItem.Checked;

  FreeAndNil( Statystyki_Form );


  if zt_modal_result = mrAll then
    begin

      // Nast�pna misja.

      if Decyzje_Gracza_Zapami�tuj_CheckBox.Checked then
        Decyzje_Gracza_Zapisz_ButtonClick( nil );


      Nast�pna_Misja_ButtonClick( nil );

      if czy_pauza then
        czy_pauza := false;

      Exit;

    end
  else//if zt_modal_result = mrAll then
  //if    ( zt_modal_result = mrClose )
  //  and ( not czy_pauza ) then
  //  czy_pauza := true // Pauza.
  //else
  if zt_modal_result = mrClose then
    czy_pauza := not czy_pauza // Pauza.
  else
  if zt_modal_result = mrRetry then // mrTryAgain
    begin

      // Jeszcze raz.

      statystyki__polecenia_ilo��__gra := statystyki__polecenia_ilo��__gra - statystyki__polecenia_ilo��__misja;
      statystyki__rakiet_straconych__gra := statystyki__rakiet_straconych__gra - statystyki__rakiet_straconych__misja;
      statystyki__rakiet_utworzonych__gra := statystyki__rakiet_utworzonych__gra - statystyki__rakiet_utworzonych__misja;


      if Start_Stop_Button.Tag = 1 then
        Start_Stop_ButtonClick( nil );

      if Start_Stop_Button.Tag = 0 then
        Start_Stop_ButtonClick( nil );

      if not czy_pauza then
        czy_pauza := true;

    end
  else//if zt_modal_result = mrRetry then
  if    ( zt_modal_result = mrAbort )
    and ( Start_Stop_Button.Tag = 1 ) then
    begin

      czy_stop := true;
      Start_Stop_ButtonClick( nil ); // Stop.

    end;
  //---//if    ( zt_modal_result = mrAbort ) (...)


  if    ( not czy_pauza )
    and ( not czy_stop ) then // Stop w��cza te� pauz�.
    Pauza_ButtonClick( nil );

end;//---//Funkcja Statystyki_Wy�wietl().

//Funkcja Informacja_Wy�wietl().
procedure TPlanety_Form.Informacja_Wy�wietl( const napis_f : string );
begin

  Informacja_GLHUDText.Text := napis_f;
  Informacja_GLWindowsBitmapFont.EnsureString( Informacja_GLHUDText.Text );

  Informacja_GLHUDText.TagFloat := GLCadencer1.CurrentTime;

  if not Informacja_GLHUDText.Visible then
    begin

      Informacja_GLHUDText.Visible := true;
      Informacja_GLHUDSprite.Visible := Informacja_GLHUDText.Visible;

    end;
  //---//if not Informacja_GLHUDText.Visible then

end;//---//Funkcja Informacja_Wy�wietl().

//Funkcja Mapy_Losowe_Etykieta_Wylicz().
procedure TPlanety_Form.Mapy_Losowe_Etykieta_Wylicz();
var
  i,
  zti
    : integer;
begin

  zti := 0;

  for i := 0 to Length( mapa_rozegrana_t ) - 1 do
    if mapa_rozegrana_t[ i ] then
      inc( zti );

  Mapy_Losowe_Etykieta_Label.Caption := Trim(  FormatFloat( '### ### ##0', zti )  ) + ' / ' + Trim(   FormatFloat(  '### ### ##0', Length( mapa_rozegrana_t )  )   );

end;//---//Funkcja Mapy_Losowe_Etykieta_Wylicz().

//Funkcja FANN_Przygotuj().
procedure TPlanety_Form.FANN_Przygotuj( const tylko_utw�rz_sie�_f : boolean = false );
type
  TFANN_Nauka_r = record
    linijka_planeta_dane : boolean;

    grupa_zdobywaj�ca_planet�,
    planeta_nale�y_do_gracza,
    planety_ilo��_mapa,
    planeta_docelowa__id_planeta, // Tylko dla uczenia SI.
    rakiety_ilo��_procent_wys�anie, // Tylko dla uczenia SI.
    rakiety_na_orbicie_ilo��__obce,
    rakiety_na_orbicie_ilo��__w�asne
      : integer;

    odleg�o��,
    planety_posiadane_procent, // Tylko dla uczenia SI.
    przejmowanie_poziom_aktualny,
    przyrost_szybko��,
    wielko��
      : real;
  end;//---//TFANN_Nauka_r

var
  i,
  zti,
  epoki
    : integer;
  ztr : real;
  adres,
  linijka,
  warto��
    : string;
  �redni_b��d_kwadratowy : single;

  search_rec : TSearchRec;

  fann_nauka_r : TFANN_Nauka_r;

  zt_string_list : TStringList;

  wej�cia : array [ 0..9 ] of single;
  wyj�cia : array [ 0..1 ] of single;

  fann_nauka_r_t : array of TFANN_Nauka_r;
begin//Funkcja FANN_Przygotuj().

  Screen.Cursor := crHourGlass;

  if fann_network = nil then
    begin

      {$IFDEF si_fann_u�ywaj}
      fann_network := TFannNetwork.Create( Application );

      fann_network.Layers.Add( '10' ); // 10 20 10 2

      //fann_network.Layers.Add( '20' ); // x 10 20 8 4
      //fann_network.Layers.Add( '10' );

      linijka := Neuron�w_W_Warstwach_Ukrytych_Edit.Text + ','; // Tutaj tymczasowo jako kopia ilo�ci neuron�w w warstwach.

      zti := Pos( ',', linijka );

      while zti > 0 do
        begin

          warto�� := Copy( linijka, 1, zti - 1 );
          warto�� := Trim( warto�� );
          Delete( linijka, 1, zti );

          try
            i := StrToInt( warto�� );
          except
            on E: Exception do
              begin

                i := -1;
                FANN__Zwolnij_ButtonClick( nil );
                Screen.Cursor := crDefault;
                Application.MessageBox(  PChar('Nie uda�o si� odczyta� ilo�ci neuron�w w warstwie ukrytej:' + #13 + #13 + E.Message + ' ' + IntToStr( E.HelpContext )), 'B��d', MB_OK + MB_ICONEXCLAMATION  );
                Exit;

              end;
            //---//on E: Exception do
          end;
          //---//try

          if i > 0 then
            fann_network.Layers.Add(  IntToStr( i )  );

          zti := Pos( ',', linijka );

        end;
      //---//while zti > 0 do


      fann_network.Layers.Add( '2' );

      //fann_network.TrainingAlgorithm := FannNetwork.taFANN_TRAIN_RPROP;
      //fann_network.ActivationFunctionHidden := FannNetwork.afFANN_SIGMOID;
      //fann_network.ActivationFunctionOutput := FannNetwork.afFANN_SIGMOID;

      fann_network.TrainingAlgorithm := FannNetwork.TTrainingAlgorithm(FANN__Algorytm_Ucz�cy_ComboBox.ItemIndex);
      fann_network.ActivationFunctionHidden := FannNetwork.TActivationFunction(FANN__Funkcja_Aktywuj�ca_Warstw_Ukrytych_ComboBox.ItemIndex);
      fann_network.ActivationFunctionOutput := FannNetwork.TActivationFunction(FANN__Funkcja_Aktywuj�ca_Warstwy_Wyj�cia_ComboBox.ItemIndex);

      fann_network.Build();
      {$ELSE si_fann_u�ywaj}
      fann_network := TFann_Za�lepka.Create( Application );
      {$ENDIF}


      if not Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled then
        Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled := true;

      if not Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled then
        Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled := true;


      if not Grupa_Fann_Decyduje__Losuj_RadioButton .Checked then
        Grupa_Fann_Decyduje__Losuj_RadioButton.Checked := true;

    end;
  //---//if fann_network = nil then


  if tylko_utw�rz_sie�_f then
    begin

      Screen.Cursor := crDefault;
      Exit;

    end;
  //---//if tylko_utw�rz_sie�_f then


  SetLength( fann_nauka_r_t, 0 );

  {$region 'Odczytuje dane z pliku.'}
  zt_string_list := TStringList.Create();

  adres := ExtractFilePath( Application.ExeName ) + decyzje_gracza__katalog_nazwa_c + '\';

  if FindFirst( adres + '*.csv', faAnyFile, search_rec ) = 0 then
    begin

      repeat //FindNext( search_rec ) <> 0;

        zt_string_list.LoadFromFile( adres + search_rec.Name );

        for i := 0 to zt_string_list.Count - 1 do
          begin

            linijka := zt_string_list[ i ];

            if Pos( '---', linijka ) > 0 then
              Continue; // Wiersz z numerem ruchu.


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
              fann_nauka_r.linijka_planeta_dane := System.Math.Floor( ztr ) > 0;
            except
              fann_nauka_r.linijka_planeta_dane := false;
              Continue;
            end;
            //---//try

            // id_planeta


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planeta_docelowa__id_planeta := System.Math.Floor( ztr ); // 0 - nie, 1 - tak.


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planeta_nale�y_do_gracza := System.Math.Floor( ztr ); // 0 - nie, 1 - tak.


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            // id_planeta_docelowa


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.grupa_zdobywaj�ca_planet� := System.Math.Floor( ztr ); // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planet�, 2 - planet� zdobywa grupa nie gracza).


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.odleg�o�� := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planety_ilo��_mapa := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planety_posiadane_procent := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.przejmowanie_poziom_aktualny := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.przyrost_szybko�� := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_ilo��_procent_wys�anie := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_na_orbicie_ilo��__obce := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_na_orbicie_ilo��__w�asne := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            warto�� := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( warto�� );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.wielko�� := ztr;



            if fann_nauka_r.linijka_planeta_dane then
              begin

                zti := Length( fann_nauka_r_t );
                SetLength( fann_nauka_r_t, zti + 1 );

                fann_nauka_r_t[ zti ].planeta_docelowa__id_planeta := fann_nauka_r.planeta_docelowa__id_planeta; // planeta jest planet� docelow� (na t� planet� gracz wysy�a� rakiety) (0 - nie, 1 - tak).
                fann_nauka_r_t[ zti ].planeta_nale�y_do_gracza := fann_nauka_r.planeta_nale�y_do_gracza;

                fann_nauka_r_t[ zti ].grupa_zdobywaj�ca_planet� := fann_nauka_r.grupa_zdobywaj�ca_planet�; // Zmienia si� gdy jaka� grupa straci�a albo przej�a planet�.

                fann_nauka_r_t[ zti ].rakiety_ilo��_procent_wys�anie := fann_nauka_r.rakiety_ilo��_procent_wys�anie;
                fann_nauka_r_t[ zti ].rakiety_na_orbicie_ilo��__obce := fann_nauka_r.rakiety_na_orbicie_ilo��__obce;
                fann_nauka_r_t[ zti ].rakiety_na_orbicie_ilo��__w�asne := fann_nauka_r.rakiety_na_orbicie_ilo��__w�asne;

                fann_nauka_r_t[ zti ].odleg�o�� := fann_nauka_r.odleg�o��;
                fann_nauka_r_t[ zti ].planety_ilo��_mapa := fann_nauka_r.planety_ilo��_mapa;
                fann_nauka_r_t[ zti ].planety_posiadane_procent := fann_nauka_r.planety_posiadane_procent;
                fann_nauka_r_t[ zti ].przejmowanie_poziom_aktualny := fann_nauka_r.przejmowanie_poziom_aktualny;
                fann_nauka_r_t[ zti ].przyrost_szybko�� := fann_nauka_r.przyrost_szybko��;
                fann_nauka_r_t[ zti ].wielko�� := fann_nauka_r.wielko��;

              end;
            //---//if fann_nauka_r.linijka_planeta_dane then

          end;
        //---//for i := 0 to zt_string_list.Count - 1 do

      until FindNext( search_rec ) <> 0; // Zwraca dane kolejnego pliku zgodnego z parametrami wcze�niej wywo�anej funkcji FindFirst. Je�eli mo�na przej�� do nast�pnego znalezionego pliku zwraca 0.

    end;
  //---//if FindFirst( adres + '*.csv', faAnyFile, search_rec ) = 0 then

  FindClose( search_rec ); // SysUtils.


  FreeAndNil( zt_string_list );
  {$endregion 'Odczytuje dane z pliku.'}


  Fann_Nauka_ProgressBar.Position := 0;
  Fann_Nauka_ProgressBar.Max := FANN__Epoki_SpinEdit.Value;
  Fann_Nauka_ProgressBar.Visible := true;

  adres := Self.Caption; // Tutaj tymczasowo jako kopia etykiety okna.


  for epoki := 1 to FANN__Epoki_SpinEdit.Value do // 30000.
    begin

      for i := 0 to Length( fann_nauka_r_t ) - 1 do
        begin

          wej�cia[ 0 ] := fann_nauka_r_t[ i ].planeta_nale�y_do_gracza; // 0 - nie, 1 - tak.
          wej�cia[ 1 ] := fann_nauka_r_t[ i ].grupa_zdobywaj�ca_planet�; // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planet�, 2 - planet� zdobywa grupa nie gracza).
          wej�cia[ 2 ] := fann_nauka_r_t[ i ].odleg�o��;
          wej�cia[ 3 ] := fann_nauka_r_t[ i ].planety_ilo��_mapa;
          wej�cia[ 4 ] := fann_nauka_r_t[ i ].planety_posiadane_procent;
          wej�cia[ 5 ] := fann_nauka_r_t[ i ].przejmowanie_poziom_aktualny;
          wej�cia[ 6 ] := fann_nauka_r_t[ i ].przyrost_szybko��;
          wej�cia[ 7 ] := fann_nauka_r_t[ i ].rakiety_na_orbicie_ilo��__obce;
          wej�cia[ 8 ] := fann_nauka_r_t[ i ].rakiety_na_orbicie_ilo��__w�asne; // W przypadku gracza s� to jego wszystkie rakiety na wszystkich orbitach (bez tych aktualnie lec�cych).
          wej�cia[ 9 ] := fann_nauka_r_t[ i ].wielko��;

          wyj�cia[ 0 ] := fann_nauka_r_t[ i ].planeta_docelowa__id_planeta; // planeta jest planet� docelow� (na t� planet� gracz wysy�a� rakiety) (0 - nie, 1 - tak).
          wej�cia[ 1 ] := fann_nauka_r_t[ i ].rakiety_ilo��_procent_wys�anie; // Taki procent rakiet graczy wysy�a� w danym ruchu.

          �redni_b��d_kwadratowy := fann_network.Train( wej�cia, wyj�cia );

        end;
      //---//for i := 0 to Length( fann_nauka_r_t ) - 1 do

      Fann_Nauka_ProgressBar.StepIt();

      if Fann_Nauka_ProgressBar.Max <> 0 then
        Self.Caption := '[' + Trim(  FormatFloat( '### ### ##0', Fann_Nauka_ProgressBar.Position * 100 / Fann_Nauka_ProgressBar.Max )  ) + '%] ' + adres;

      if epoki mod 5 = 0 then // 50
        Application.ProcessMessages();

    end;
  //---//for epoki := 1 to FANN__Epoki_SpinEdit.Value do


  Self.Caption := adres;

  SetLength( fann_nauka_r_t, 0 );


  Fann_Nauka_ProgressBar.Visible := false;


  SI_Log_Memo.Lines.Add( '�redni b��d kwadratowy <Mittlerer quadratischer Fehler> <Mean square error>:' );
  SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.0000000', �redni_b��d_kwadratowy )  )   ); //???

  Screen.Cursor := crDefault;

  Komunikat_Wy�wietl( 'Uczenie sieci zako�czone.' + #13 + #13 + 'Netzwerkschulung abgeschlossen.' + #13 + #13 + 'Network training complete.', 'Informacja', MB_OK + MB_ICONINFORMATION );

end;//---//Funkcja FANN_Przygotuj().

//Funkcja FANN_Zapisane_Nazwy_Wyszukaj().
procedure TPlanety_Form.FANN_Zapisane_Nazwy_Wyszukaj();
var
  i : integer;
  zts : string;
  search_rec : TSearchRec;
begin

  zts := FANN__Plik_Nazwa_ComboBox.Text;
  FANN__Plik_Nazwa_ComboBox.Items.Clear();


  if FindFirst(  ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\*' + fann_sieci_zapisane__kropka_rozszerzenie_c, faAnyFile, search_rec  ) = 0 then
    begin

      repeat //FindNext( search_rec ) <> 0;
        // Czasami bez begin i end nieprawid�owo rozpoznaje miejsca na umieszczenie breakpoint (linijk� za wysoko) w XE5.

        FANN__Plik_Nazwa_ComboBox.Items.Add(  System.IOUtils.TPath.GetFileNameWithoutExtension( search_rec.Name )  );

      until FindNext( search_rec ) <> 0;

    end;
  //---//if FindFirst(  ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\*' + fann_sieci_zapisane__kropka_rozszerzenie_c, faAnyFile, search_rec  ) = 0 then

  FindClose( search_rec );


  for i := 0 to FANN__Plik_Nazwa_ComboBox.Items.Count - 1 do
    if FANN__Plik_Nazwa_ComboBox.Items[ i ] = zts then
      begin

        FANN__Plik_Nazwa_ComboBox.ItemIndex := i;
        Break;

      end;
    //---//if FANN__Plik_Nazwa_ComboBox.Items[ i ] = zts then

end;//---//Funkcja FANN_Zapisane_Nazwy_Wyszukaj().

//---//      ***      Funkcje      ***      //---//


//FormShow().
procedure TPlanety_Form.FormShow( Sender: TObject );
const
  fann_sie�_domy�lna_nazwa_c_l : string = 'Domy�lna';

var
  zts : string;
begin

  planety_ilo��_mapa_g := 0;
  si_decyduj__cykl_sekundy_g := 10;
  si_decyduj__cykl_sekundy__modyfikator_losowy_g := 0;

  statystyki__polecenia_ilo��__gra := 0;
  statystyki__polecenia_ilo��__misja := 0;
  statystyki__rakiet_straconych__gra := 0;
  statystyki__rakiet_straconych__misja := 0;
  statystyki__rakiet_utworzonych__gra := 0;
  statystyki__rakiet_utworzonych__misja := 0;

  czy_zwyci�stwo := false;
  statystyki_wykres_liniowy_menuitem_checked_g := true;
  statystyki_wykres_s�upkowy_menuitem_checked_g := false;

  ostatni_ruch_pon�w__id_planeta_z__1 := '';
  ostatni_ruch_pon�w__id_planeta_z__2 := '';
  ostatni_ruch_pon�w__id_planeta_z__3 := '';
  ostatni_ruch_pon�w__id_planeta_z__4 := '';

  ostatni_ruch_pon�w__planeta_docelowa__1 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__2 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__3 := nil;
  ostatni_ruch_pon�w__planeta_docelowa__4 := nil;

  fann_network := nil;

  zaznaczanie_ruchem_myszy__op�nienie_data_czas := Now();
  zaznaczanie_ruchem_myszy__op�nienie__zaznacze_data_czas := zaznaczanie_ruchem_myszy__op�nienie_data_czas;

  GLS.VectorGeometry.SetVector( kamera_pozycja_pocz�tkowa_g, 0, 0, 0 );


  Gra_GLSceneViewer.Align := alClient;

  PageControl1.ActivePage := Opcje_TabSheet;

  SetLength( kolor_grupa_r_t, 0 );
  SetLength( mapa_rozegrana_t, 0 );


  {$IFDEF si_fann_u�ywaj}
  O_Programie_Label.Caption := O_Programie_Label.Caption +
    #13 +
    #13 +
    #13 +
    'W programie u�yto komponent�w <Folgende Komponenten wurden im Programm verwendet> <The following components were used in the program>:' + #13 +
    #13 +
    'TfannNetwork autorstwa Mauricio Pereira Maia' + #13 +
    'mauriciocpa@gmail.com' + #13 +
    'fann.sourceforge.net';

  FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_ButtonClick( Sender );
  {$ELSE si_fann_u�ywaj}
  Grupa_Fann_Decyduje_GroupBox.Visible := false;
  FANN__Opcje_Dodatkowe_GroupBox.Visible := false;
  {$ENDIF}


  Randomize();


  SI_Decyduj__Modyfikator_Losowy_Ustaw();

  //GLSkyDome1.Stars.Clear();
  GLSkyDome1.Stars.AddRandomStars( 1000, clWhite ); // Ilo��, kolor.
  //GLSkyDome1.Options := [ sdoTwinkle ];


  //Zero_GLSphere.Visible := false; //???
  //Lewo_GLCube.Visible := false; //???


  rakiety_list := TList.Create();
  walka_efekt_list := TList.Create();


  Mapy_Wczytaj();

  FANN_Zapisane_Nazwy_Wyszukaj();


  Gra_GLSceneViewer.SetFocus();


  Planety_Form.WindowState := wsMaximized;
  Mapa_ComboBox.ItemIndex := 0;


  Pauza_ButtonClick( Sender );


  {$IFDEF si_fann_u�ywaj}
  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + fann_sie�_domy�lna_nazwa_c_l + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;

  if FileExists( zts ) then
    begin

      FANN__Plik_Nazwa_ComboBox.Text := fann_sie�_domy�lna_nazwa_c_l;

      FANN__Wczytaj_ButtonClick( Sender );

    end;
  //---//if not FileExists( zts ) then
  {$ENDIF}


  //Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo�uje si� Mapa_ComboBoxChange(). //???

end;//---//FormShow().

//FormClose().
procedure TPlanety_Form.FormClose( Sender: TObject; var Action: TCloseAction );
begin

  if Komunikat_Wy�wietl( 'Czy wyj�� z gry?' + #13 + #13 + 'Das Spiel benden?' + #13 + #13 + 'Quit the game?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
    begin

      Action := caNone;
      Exit;

    end;
  //---//if Komunikat_Wy�wietl( 'Czy wyj�� z gry?' + #13 + #13 + 'Das Spiel benden?' + #13 + #13 + 'Quit the game?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then


  SetLength( kolor_grupa_r_t, 0 );

  Walka_Efekt_Zwolnij_Wszystkie();
  FreeAndNil( walka_efekt_list );

  Rakiety_Zwolnij_Wszystkie();
  FreeAndNil( rakiety_list );

  Mapa_Zwolnij();

  SetLength( mapa_rozegrana_t, 0 );


  if fann_network <> nil then
    begin

      {$IFDEF si_fann_u�ywaj}
      fann_network.UnBuild();
      {$ENDIF}

      FreeAndNil( fann_network );

    end;
  //---//if fann_network <> nil then

end;//---//FormClose().

//GLCadencer1Progress().
procedure TPlanety_Form.GLCadencer1Progress( Sender: TObject; const deltaTime, newTime: Double );
var
  przyrost__przeliczaj,
  zwalczanie_poza_orbit�__przeliczaj
    : boolean;
  i : integer;
begin

  GLUserInterface1.MouseLook();
  GLUserInterface1.MouseUpdate();
  Gra_GLSceneViewer.Invalidate();


  if Start_Stop_Button.Tag = 1 then
    przyrost__przeliczaj := GLCadencer1.CurrentTime - przyrost__ostatnie_przeliczenie_g >= przyrost__cykl_sekundy_c / Gra_Pr�dko��()
  else//if Start_Stop_Button.Tag = 1 then
    przyrost__przeliczaj := false;


  for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do
    begin

      if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
        begin

          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Roll( 10 * deltaTime * Gra_Pr�dko��() );


          if    ( przyrost__przeliczaj )
            and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_neutralna_c ) then // Na neutralnych planetach rakiety nie przyrastaj�.
            begin

              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Przyrost_Przeliczaj();

            end;
          //---//if    ( przyrost__przeliczaj ) (...)

        end
      else//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      if Gra_Obiekty_GLDummyCube.Children[ i ] is TWalka_Efekt then
        begin

          if    ( TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek > 0 )
            and ( GLCadencer1.CurrentTime - TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).utworzenie_czas >= walka_efekt__czas_trwania_sekundy_c * 0.5 / Gra_Pr�dko��() ) then
            TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek := -TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek;


          //TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).Scale.Scale( 1.001 );
          TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).gl_thor_fx_manager.GlowSize :=
            TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).gl_thor_fx_manager.GlowSize + 0.0005 * TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek;


          if GLCadencer1.CurrentTime - TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).utworzenie_czas >= walka_efekt__czas_trwania_sekundy_c / Gra_Pr�dko��() then
            Walka_Efekt_Zwolnij_Jeden( TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]) );

        end;
      //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TWalka_Efekt then

    end;
  //---//for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do


  if przyrost__przeliczaj then
    begin

      Orbita_Rakiety_Zwalczanie( false );

      Planety_Przejmowanie_Przeliczaj();

      przyrost__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

    end
  else//if przyrost__przeliczaj then
    begin

      if Start_Stop_Button.Tag = 1 then
        zwalczanie_poza_orbit�__przeliczaj := GLCadencer1.CurrentTime - zwalczanie_poza_orbit�__ostatnie_przeliczenie_g >= zwalczanie_poza_orbit�__cykl_sekundy_c / Gra_Pr�dko��()
      else//if Start_Stop_Button.Tag = 1 then
        zwalczanie_poza_orbit�__przeliczaj := false;

      if zwalczanie_poza_orbit�__przeliczaj then
        begin

          Orbita_Rakiety_Zwalczanie( true );

          zwalczanie_poza_orbit�__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

        end;
      //---//if zwalczanie_poza_orbit�__przeliczaj then

    end;
  //---//if przyrost__przeliczaj then


  if    ( Start_Stop_Button.Tag = 1 )
    and (  GLCadencer1.CurrentTime - si_decyduj__ostatnie_przeliczenie_g >= ( si_decyduj__cykl_sekundy_g + si_decyduj__cykl_sekundy__modyfikator_losowy_g ) / Gra_Pr�dko��()  ) then
    begin

      SI_Decyduj();

      SI_Decyduj__Modyfikator_Losowy_Ustaw();
      si_decyduj__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

    end;
  //---//if    ( Start_Stop_Button.Tag = 1 ) (...)


  Rakiety_Lot_Do_Celu( deltaTime );


  if    ( Start_Stop_Button.Tag = 1 )
    //and ( not czy_zwyci�stwo ) //???
    and ( GLCadencer1.CurrentTime - zwyci�stwo_sprawd�__ostatnie_przeliczenie_g >= zwyci�stwo_sprawd�__cykl_sekundy_c ) then
    begin

      Statystyki_Tabela_Warto�ci_Kolejne_Zapami�taj();


      if    ( Start_Stop_Button.Tag = 1 )
        and ( not czy_zwyci�stwo )
        and (
                 (  Zwyci�stwo_Sprawd�( i )  )
              or (  Przegrana_Gracza_Sprawd�( i )  )
            ) then
        begin

          czy_zwyci�stwo := true;

          if i = id_grupa_gracza_c then
            Nast�pna_Misja_Button.Enabled := true;

          Statystyki_Wy�wietl( {true,} true, i );

        end;
      //---//if    ( Start_Stop_Button.Tag = 1 ) (...)


      zwyci�stwo_sprawd�__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

    end;
  //---//if    ( Start_Stop_Button.Tag = 1 ) (...)


  if Gra_GLSceneViewer.Focused then
    Kamera_Ruch( deltaTime );


  if    ( Informacja_GLHUDText.Visible )
    and ( GLCadencer1.CurrentTime - Informacja_GLHUDText.TagFloat >= 3 ) then // Sekundy.
    begin

      Informacja_GLHUDText.Visible := false;
      Informacja_GLHUDSprite.Visible := Informacja_GLHUDText.Visible;
      Informacja_GLHUDText.Text := '';

    end;
  //---//if    ( Informacja_GLHUDText.Visible ) (...)

end;//---//GLCadencer1Progress().

//Gra_GLSceneViewerClick().
procedure TPlanety_Form.Gra_GLSceneViewerClick( Sender: TObject );
begin

  Gra_GLSceneViewer.SetFocus();

end;//---//Gra_GLSceneViewerClick().

//Gra_GLSceneViewerKeyDown().
procedure TPlanety_Form.Gra_GLSceneViewerKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
const
  ruch_c_l : single = 5;
var
  i : integer;
begin

  if GLS.Keyboard.IsKeyDown( VK_ESCAPE ) then
    Close();

  if GLS.Keyboard.IsKeyDown( VK_DECIMAL ) then
    GLUserInterface1.MouseLookActive := not GLUserInterface1.MouseLookActive;


  //if GLS.Keyboard.IsKeyDown( VK_RETURN ) then
  if GLS.Keyboard.IsKeyDown( 'E' ) then
    begin

      // Pe�ny ekran.

      if Planety_Form.BorderStyle <> bsNone then
        begin

          // Pe�ny ekran.

          // Po ustawieniu pe�nego ekranu mog� znika� elementy po�o�one na formie (jak panel), kt�re nie s� wyr�wnywane do bok�w okna..

          if Planety_Form.WindowState = wsMaximized then
            Planety_Form.Tag := 1
          else//if Planety_Form.WindowState = wsMaximized then
            Planety_Form.Tag := 0;

          Planety_Form.BorderStyle := bsNone;

          if Planety_Form.WindowState = wsMaximized then
            Planety_Form.WindowState := wsNormal; // Zmaksymalizowane okno czasami nie zas�ania paska start.

          Planety_Form.WindowState := wsMaximized;

          Planety_Form.BringToFront();

        end
      else//if Planety_Form.BorderStyle <> bsNone then
        begin

          // Normalny ekran.

          Planety_Form.BorderStyle := bsSizeable;

          if Planety_Form.Tag = 1 then
            Planety_Form.WindowState := wsMaximized
          else//if Planety_Form.Tag = 1 then
            Planety_Form.WindowState := wsNormal;

        end;
      //---//if Planety_Form.BorderStyle <> bsNone then

    end;
  //---//if GLS.Keyboard.IsKeyDown( EM' ) then


  if   (  GLS.Keyboard.IsKeyDown( 'P' )  ) // Pauza podczas wy��czania przeskakuje widokiem kamery gdy obracanie mysz� jest w��czone.
    or (  GLS.Keyboard.IsKeyDown( VK_PAUSE )  ) then
    Pauza_ButtonClick( Sender );


  if GLS.Keyboard.IsKeyDown( 'I' ) then
    Statystyki_ButtonClick( Sender );


  if GLS.Keyboard.IsKeyDown( '/' ) then
    Pomoc_BitBtnClick( Sender );


  if GLS.Keyboard.IsKeyDown( VK_F1 ) then
    Ruch_Ostatni_Pon�w_ButtonClick( Sender );


  if    (  GLS.Keyboard.IsKeyDown( VK_F2 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_pon�w__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_pon�w__id_planeta_z__2 := ostatni_ruch_pon�w__id_planeta_z__1;
      ostatni_ruch_pon�w__planeta_docelowa__2 := ostatni_ruch_pon�w__planeta_docelowa__1;

      Informacja_Wy�wietl( 'Zapami�tano ruch (F2).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F2 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F2 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_pon�w__id_planeta_z__2, ostatni_ruch_pon�w__planeta_docelowa__2 );

  if    (  GLS.Keyboard.IsKeyDown( VK_F3 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_pon�w__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_pon�w__id_planeta_z__3 := ostatni_ruch_pon�w__id_planeta_z__1;
      ostatni_ruch_pon�w__planeta_docelowa__3 := ostatni_ruch_pon�w__planeta_docelowa__1;

      Informacja_Wy�wietl( 'Zapami�tano ruch (F3).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F3 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F3 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_pon�w__id_planeta_z__3, ostatni_ruch_pon�w__planeta_docelowa__3 );

  if    (  GLS.Keyboard.IsKeyDown( VK_F4 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_pon�w__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_pon�w__id_planeta_z__4 := ostatni_ruch_pon�w__id_planeta_z__1;
      ostatni_ruch_pon�w__planeta_docelowa__4 := ostatni_ruch_pon�w__planeta_docelowa__1;

      Informacja_Wy�wietl( 'Zapami�tano ruch (F4).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F4 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F4 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_pon�w__id_planeta_z__4, ostatni_ruch_pon�w__planeta_docelowa__4 );


  if GLS.Keyboard.IsKeyDown( VK_F11 ) then
    begin

      if PageControl1.Width <> 200 then
        PageControl1.Width := 200
      else//if PageControl1.Width <> 200 then
        PageControl1.Width := 1; // 1. Gdy r�wne 0 to po schowaniu nie da si� rozwin�� poprzez Splitter.

      if not Opcje_Splitter.Visible then
        Opcje_Splitter.Visible := true;

    end;
  //---//if GLS.Keyboard.IsKeyDown( VK_F12 ) then

  if GLS.Keyboard.IsKeyDown( VK_F12 ) then
    begin

      if PageControl1.Width <> 200 then
        PageControl1.Width := 200
      else//if PageControl1.Width <> 200 then
        PageControl1.Width := 0; // 1. Gdy r�wne 0 to po schowaniu nie da si� rozwin�� poprzez Splitter.

      Opcje_Splitter.Visible := PageControl1.Width > 0;

    end;
  //---//if GLS.Keyboard.IsKeyDown( VK_F12 ) then


  if not GLCadencer1.Enabled then // Gdy pauza jest aktywna.
    Kamera_Ruch( 0.03 );


  if Start_Stop_Button.Tag = 1 then // Gdy nie ma aktywnej gry nie mo�na wydawa� polece� zwi�zanych z rozgrywk�. //???
    begin

      if    (  GLS.Keyboard.IsKeyDown( 'A' )  )
        and (  GLS.Keyboard.IsKeyDown( VK_CONTROL )  ) then // Zaznacza planety gracza i planety, na kt�rych orbitach s� rakiety gracza.
        begin

          for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
              and ( not TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
              and (  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Ilo��( 1 ) > 0  ) then
              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( true );

        end
      else//if    (  GLS.Keyboard.IsKeyDown( 'A' )  ) (...)
        if GLS.Keyboard.IsKeyDown( 'A' ) then // Zaznacza planety gracza.
          for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
              and ( not TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c ) then
              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( true );

      if GLS.Keyboard.IsKeyDown( 'X' ) then
        for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
          if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
            and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
            TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );

    end;
  //---//if Start_Stop_Button.Tag = 1 then


  if GLS.Keyboard.IsKeyDown( '1' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 10;

  if GLS.Keyboard.IsKeyDown( '2' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 20;

  if GLS.Keyboard.IsKeyDown( '3' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 30;

  if GLS.Keyboard.IsKeyDown( '4' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 40;

  if GLS.Keyboard.IsKeyDown( '5' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 50;

  if GLS.Keyboard.IsKeyDown( '6' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 60;

  if GLS.Keyboard.IsKeyDown( '7' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 70;

  if GLS.Keyboard.IsKeyDown( '8' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 80;

  if GLS.Keyboard.IsKeyDown( '9' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 90;

  if GLS.Keyboard.IsKeyDown( '0' ) then
    Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 100;


  if GLS.Keyboard.IsKeyDown( 'Q' ) then
    if Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value = 100 then
      Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 50
    else//if Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value = 100 then
      Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value := 100;


  //if   (  GLS.Keyboard.IsKeyDown( 'K' )  )
  //  or (  GLS.Keyboard.IsKeyDown( VK_NUMPAD2 )  ) then
  if GLS.Keyboard.IsKeyDown( 'K' ) then
    begin

      Gra_GLCamera.ResetRotations();
      Gra_GLCamera.Direction.Z := -1;

      Gra_GLCamera.Position.SetPoint( 0, 0, 0 );

      Gra_GLCamera.Position.AsVector := kamera_pozycja_pocz�tkowa_g;

    end;
  //---//if GLS.Keyboard.IsKeyDown( 'K' ) then


  if    (  GLS.Keyboard.IsKeyDown( VK_ADD )  )
    and ( Gra_Pr�dko��_SpinEdit.Value <= Gra_Pr�dko��_SpinEdit.MaxValue - Gra_Pr�dko��_SpinEdit.Increment ) then
    Gra_Pr�dko��_SpinEdit.Value := Gra_Pr�dko��_SpinEdit.Value + Gra_Pr�dko��_SpinEdit.Increment;

  if    (  GLS.Keyboard.IsKeyDown( VK_SUBTRACT )  )
    and ( Gra_Pr�dko��_SpinEdit.Value >= Gra_Pr�dko��_SpinEdit.MinValue + Gra_Pr�dko��_SpinEdit.Increment ) then
    Gra_Pr�dko��_SpinEdit.Value := Gra_Pr�dko��_SpinEdit.Value - Gra_Pr�dko��_SpinEdit.Increment;

  if GLS.Keyboard.IsKeyDown( VK_MULTIPLY ) then
    Gra_Pr�dko��_SpinEdit.Value := 100;

end;//---//Gra_GLSceneViewerKeyDown().

//Gra_GLSceneViewerMouseDown().
procedure TPlanety_Form.Gra_GLSceneViewerMouseDown( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer );
var
  //planeta_gracza_zaznaczona,
  //planeta_klikni�ta_zaznaczona
  planety_zaznaczona_wi�cej_ni�_jedna
    : boolean;
  i,
  id_planeta_zaznaczona
  //zti
    : integer;
  zts : string;
  zt_gl_base_scene_object : TGLBaseSceneObject;
begin

  if Start_Stop_Button.Tag <> 1 then // Gdy nie ma aktywnej gry nie mo�na wydawa� polece� zwi�zanych z rozgrywk�. //???
    Exit;


  zt_gl_base_scene_object := Gra_GLSceneViewer.Buffer.GetPickedObject( x, y );

  if    ( zt_gl_base_scene_object <> nil )
    and ( zt_gl_base_scene_object.Parent <> nil )
    and ( zt_gl_base_scene_object.Parent is TPlaneta ) then
    begin

      {$region 'Wariant 1.'}
      //// Sprawdza czy jaka� planeta gracza jest zaznaczona.
      //planeta_gracza_zaznaczona := false;
      //
      //if not ( ssShift in Shift ) then
      //  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      //    if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
      //      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
      //      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
      //      begin
      //
      //        planeta_gracza_zaznaczona := true;
      //        Break;
      //
      //      end;
      //    //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)
      ////---// Sprawdza czy jaka� planeta gracza jest zaznaczona.
      //
      //
      //if    ( planeta_gracza_zaznaczona )
      //  and ( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona ) then
      //  begin
      //
      //    // Wysy�a rakiety na planet�.
      //
      //    zts := '-99';
      //
      //    for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      //      if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
      //        and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
      //        and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
      //        begin
      //
      //          zts := zts +
      //            ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta );
      //
      //        end;
      //      //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)
      //
      //    Rakiety_Cel_Ustaw( zts, TPlaneta(zt_gl_base_scene_object.Parent) );
      //
      //  end
      //else//if    ( planeta_gracza_zaznaczona )
      //if TPlaneta(zt_gl_base_scene_object.Parent).id_grupa = id_grupa_gracza_c then
      //  begin
      //
      //    // Zaznacza planet� gracza.
      //
      //    zti := TPlaneta(zt_gl_base_scene_object.Parent).id_planeta;
      //    planeta_klikni�ta_zaznaczona := TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona;
      //
      //    //TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona := not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona;
      //    TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona );
      //
      //
      //    // Odznacza pozosta�e planety.
      //    if    ( not planeta_klikni�ta_zaznaczona )
      //      and (  not ( ssShift in Shift )  ) then
      //      for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      //        if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
      //          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
      //          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta <> zti ) then
      //          //TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona := false;
      //          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );
      //
      //  end;
      ////---//if    ( not planeta_gracza_zaznaczona ) (...)
      {$endregion 'Wariant 1.'}

      // Sprawdza czy jaka� planeta jest zaznaczona.
      planety_zaznaczona_wi�cej_ni�_jedna := false;
      id_planeta_zaznaczona := -99;

      for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
        if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
          begin

            if id_planeta_zaznaczona <> -99 then
              begin

                planety_zaznaczona_wi�cej_ni�_jedna := true;
                Break;

              end;
            //---//if id_planeta_zaznaczona <> -99 then

            if id_planeta_zaznaczona = -99 then // Zapami�tuje tylko id pierwszej zaznaczonej planety.
              id_planeta_zaznaczona := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta;

          end;
        //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)
      //---// Sprawdza czy jaka� planeta jest zaznaczona.


      if   ( ssShift in Shift ) // Z Shift zaznacza - odznacza klikni�t� planet�.
        or ( Button = TMouseButton.mbRight )
        //or (
        //         (  not ( ssShift in Shift )  )
        //     and ( id_planeta_zaznaczona = -99 ) // Gdy nie ma zaznaczonych planet to zaznacza klikni�t� planet�.
        //   )
        //or ( // Gdy klikni�to jedyn� zaznaczon� planet� to j� odznacza.
        //         (  not ( ssShift in Shift )  )
        //     and ( not planety_zaznaczona_wi�cej_ni�_jedna )
        //     and ( TPlaneta(zt_gl_base_scene_object.Parent).id_planeta = id_planeta_zaznaczona )
        //   ) then
        or (
                 (  not ( ssShift in Shift )  )
             and (
                      ( id_planeta_zaznaczona = -99 ) // Gdy nie ma zaznaczonych planet to zaznacza klikni�t� planet�.
                   or ( // Gdy klikni�to jedyn� zaznaczon� planet� to j� odznacza.
                            ( not planety_zaznaczona_wi�cej_ni�_jedna )
                        and ( TPlaneta(zt_gl_base_scene_object.Parent).id_planeta = id_planeta_zaznaczona )
                      )
                 )
           ) then
        begin

          // Zaznacza planet�.

          if   ( TPlaneta(zt_gl_base_scene_object.Parent).id_grupa = id_grupa_gracza_c )
            or (  TPlaneta(zt_gl_base_scene_object.Parent).Rakiety_Na_Orbicie_Ilo��( id_grupa_gracza_c ) > id_grupa_neutralna_c  ) then
            TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona )
          else
          if   ( TPlaneta(zt_gl_base_scene_object.Parent).id_grupa <> id_grupa_gracza_c )
            or ( TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona ) then // Odznacza planet� innej grupy, na kt�rej ju� nie ma rakiet gracza.
            TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( false );

          zaznaczanie_ruchem_myszy__op�nienie__zaznacze_data_czas := Now();

        end
      else//if   ( ssShift in Shift ) (...)
      if not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona then
        begin

          // Wysy�a rakiety na planet�.

          zts := '-99';

          for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
              begin

                zts := zts +
                  ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta );

              end;
            //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)


          //ostatni_ruch_pon�w__id_planeta_z__4 := ostatni_ruch_pon�w__id_planeta_z__3;
          //ostatni_ruch_pon�w__id_planeta_z__3 := ostatni_ruch_pon�w__id_planeta_z__2;
          //ostatni_ruch_pon�w__id_planeta_z__2 := ostatni_ruch_pon�w__id_planeta_z__1;
          ostatni_ruch_pon�w__id_planeta_z__1 := zts;

          //ostatni_ruch_pon�w__planeta_docelowa__4 := ostatni_ruch_pon�w__planeta_docelowa__3;
          //ostatni_ruch_pon�w__planeta_docelowa__3 := ostatni_ruch_pon�w__planeta_docelowa__2;
          //ostatni_ruch_pon�w__planeta_docelowa__2 := ostatni_ruch_pon�w__planeta_docelowa__1;
          ostatni_ruch_pon�w__planeta_docelowa__1 := TPlaneta(zt_gl_base_scene_object.Parent);


          Rakiety_Cel_Ustaw( id_grupa_gracza_c, zts, TPlaneta(zt_gl_base_scene_object.Parent) );

        end;
      //---//if not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona then

    end
  else//if    ( zt_gl_base_scene_object <> nil ) (...)
    if    ( Button <> TMouseButton.mbRight )
      and (  not ( ssShift in Shift )  ) then
      for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do // Klikni�cie poza planet� odznacza wszystkie planety.
        if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );

end;//---//Gra_GLSceneViewerMouseDown().

//Gra_GLSceneViewerMouseMove().
procedure TPlanety_Form.Gra_GLSceneViewerMouseMove( Sender: TObject; Shift: TShiftState; X, Y: Integer );
begin

   if    ( ssRight in Shift )
     and ( System.DateUtils.MilliSecondsBetween( Now(), zaznaczanie_ruchem_myszy__op�nienie_data_czas ) > 300 )
     and ( System.DateUtils.MilliSecondsBetween( Now(), zaznaczanie_ruchem_myszy__op�nienie__zaznacze_data_czas ) > 1000 ) then
     begin

       Gra_GLSceneViewerMouseDown( Sender, TMouseButton.mbRight, Shift, X, Y );

       zaznaczanie_ruchem_myszy__op�nienie_data_czas := Now();

     end;
   //---//if    ( ssRight in Shift ) (...)

end;//---//Gra_GLSceneViewerMouseMove().

//Mapa_ComboBoxChange().
procedure TPlanety_Form.Mapa_ComboBoxChange( Sender: TObject );
var
  i : integer;
begin

  SetLength( kolor_grupa_r_t, 0 ); // Przy zmianie mapy czy�ci tablic� wylosowanych kolor�w dla grup.

  Walka_Efekt_Zwolnij_Wszystkie();
  Rakiety_Zwolnij_Wszystkie();
  Mapa_Zwolnij();
  Mapa_Utw�rz();


  {$IFDEF si_fann_u�ywaj}
  for i := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
    if Grupa_Fann_Decyduje__Algorytm_Tylko_RadioButton.Checked then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := false
    else
    if Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Checked then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := true
    else
    if Grupa_Fann_Decyduje__Losuj_RadioButton.Checked then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := Random( 2 ) = 1;
  {$ENDIF}

end;//---//Mapa_ComboBoxChange().

//Mapa_Losuj_BitBtnClick().
procedure TPlanety_Form.Mapa_Losuj_BitBtnClick( Sender: TObject );
var
  licznik_sprawdze�,
  mapa_indeks
    : integer;
begin

  if Mapa_ComboBox.Items.Count <= 0 then
    Exit;


  if Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count then
    begin

      mapa_indeks := Random( Mapa_ComboBox.Items.Count );

      licznik_sprawdze� := 1;

      while ( mapa_rozegrana_t[ mapa_indeks ] )
        and ( licznik_sprawdze� <= 1000 + Mapa_ComboBox.Items.Count * 10 ) do
        begin

          inc( licznik_sprawdze� );

          mapa_indeks := Random( Mapa_ComboBox.Items.Count );

        end;
      //---//while licznik_sprawdze� < 1000 do


      if not mapa_rozegrana_t[ mapa_indeks ] then
        begin

          mapa_rozegrana_t[ mapa_indeks ] := true; // Oznacza aby nie losowa� tej mapy ponownie.

          Mapa_ComboBox.ItemIndex := mapa_indeks;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo�uje si� Mapa_ComboBoxChange().

        end
      else//if not mapa_rozegrana_t[ mapa_indeks ] then
        begin

          licznik_sprawdze� := 0;

          for mapa_indeks := 0 to Length( mapa_rozegrana_t ) - 1 do
            if mapa_rozegrana_t[ mapa_indeks ] then
              inc( licznik_sprawdze� );

          if licznik_sprawdze� = Length( mapa_rozegrana_t ) then
            begin

              //if Komunikat_Wy�wietl( 'Rozgrywano ju� gr� na wszystkich mapach czy rozpocz�� losowania od pocz�tku?' + #13 + #13 + 'Das Spiel wurde bereits auf allen Karten gespielt, m�chtest du die Ziehung noch einmal beginnen?' + #13 + #13 + 'The game has already been played on all maps, do you want to start the draw all over again?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) = IDYES then
              if Komunikat_Wy�wietl( 'Wszystkie mapy zosta�y ju� wylosowane czy rozpocz�� losowania od pocz�tku?' + #13 + #13 + 'Alle Karten wurden bereits gezeichnet, beginnen die Auslosung von vorne?' + #13 + #13 + 'All maps have already been drawn, start the draw from the beginning?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) = IDYES then
                begin

                  for mapa_indeks := 0 to Length( mapa_rozegrana_t ) - 1 do
                    mapa_rozegrana_t[ mapa_indeks ] := false;

                  Mapa_Losuj_BitBtnClick( Sender );

                end;
              //---//

            end
          else//if licznik_sprawdze� = Length( mapa_rozegrana_t ) then
            Komunikat_Wy�wietl( 'Nie uda�o si� wylosowa� nowej mapy.' + #13 + #13 + 'Fehler beim Zeichnen einer neuen Karte.' + #13 + #13 + 'Failed to draw a new map.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );

        end;
      //---//if not mapa_rozegrana_t[ mapa_indeks ] then


      Mapy_Losowe_Etykieta_Wylicz();

    end;
  //---//if Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count then

end;//---//Mapa_Losuj_BitBtnClick().

//Start_Stop_ButtonClick().
procedure TPlanety_Form.Start_Stop_ButtonClick( Sender: TObject );

  //Funkcja SI_Warto�ci_Globalne_Wylicz() w Start_Stop_ButtonClick().
  procedure SI_Warto�ci_Globalne_Wylicz();
  var
    i,
    j
      : integer;
  begin

    si__odleg�o��_najwi�ksza_mi�dzy_planetami_g := -99;
    si__przyrost_szybko��_planety_najwi�kszy_g := -99;
    si__wielko��_planety_najwi�ksza_g := -99;


    for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
        begin

          if si__przyrost_szybko��_planety_najwi�kszy_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybko�� then
            si__przyrost_szybko��_planety_najwi�kszy_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybko��;

          if si__wielko��_planety_najwi�ksza_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X then
            si__wielko��_planety_najwi�ksza_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X;



          for j := i to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              and (  si__odleg�o��_najwi�ksza_mi�dzy_planetami_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]) )  ) then
              si__odleg�o��_najwi�ksza_mi�dzy_planetami_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]) );

        end;
      //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then


    if si__odleg�o��_najwi�ksza_mi�dzy_planetami_g <= 0 then
      si__odleg�o��_najwi�ksza_mi�dzy_planetami_g := 1;

    if si__przyrost_szybko��_planety_najwi�kszy_g <= 0 then
      si__przyrost_szybko��_planety_najwi�kszy_g := 1;

    if si__wielko��_planety_najwi�ksza_g <= 0 then
      si__wielko��_planety_najwi�ksza_g := 1;

  end;//---//Funkcja SI_Warto�ci_Globalne_Wylicz() w Start_Stop_ButtonClick().

var
  czy_pauza : boolean;
begin//Start_Stop_ButtonClick().

  if Start_Stop_Button.Tag = 1 then
    begin

      // Zaka�cza gr�.

      czy_pauza := not GLCadencer1.Enabled;

      if not czy_pauza then
        Pauza_ButtonClick( Sender );

      if Komunikat_Wy�wietl( 'Czy zako�czy� misj�?' + #13 + #13 + 'Die Mission benden?' + #13 + #13 + 'Finish the mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
        begin

          if not czy_pauza then
            Pauza_ButtonClick( Sender );

          Exit;

        end;
      //---//if Komunikat_Wy�wietl( 'Czy zako�czy� misj�?' + #13 + #13 + 'Die Mission benden?' + #13 + #13 + 'Finish the mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then


      Walka_Efekt_Zwolnij_Wszystkie();
      Rakiety_Zwolnij_Wszystkie();
      Mapa_Zwolnij();

      Mapa_Losuj_BitBtn.Enabled := true;


      //if not czy_pauza then // Stop w��cza te� pauz�.
      //  Pauza_ButtonClick( Sender );


      Start_Stop_Button.Tag := 0;
      Start_Stop_Button.Caption := 'Start';

    end
  else//if Start_Stop_Button.Tag = 1 then
    begin

      // Rozpoczyna gr�.

      statystyki__polecenia_ilo��__misja := 0;
      statystyki__rakiet_straconych__misja := 0;
      statystyki__rakiet_utworzonych__misja := 0;

      czy_zwyci�stwo := false;

      decyzje_gracza_g := '';
      decyzje_gracza_numer_g := 0;

      Nast�pna_Misja_Button.Enabled := false;
      Mapa_Losuj_BitBtn.Enabled := false;


      Walka_Efekt_Zwolnij_Wszystkie();
      Rakiety_Zwolnij_Wszystkie();
      Mapa_Zwolnij();


      if not Mapa_Utw�rz() then
        begin

          Rakiety_Zwolnij_Wszystkie();
          Exit;

        end;
      //---//if not Mapa_Utw�rz() then


      GLCadencer1.CurrentTime := 0;
      przyrost__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      si_decyduj__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      zwalczanie_poza_orbit�__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      zwyci�stwo_sprawd�__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;


      Start_Stop_Button.Tag := 1;
      Start_Stop_Button.Caption := 'Stop';


      SI_Warto�ci_Globalne_Wylicz();


      if    ( Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count )
        and ( not mapa_rozegrana_t[ Mapa_ComboBox.ItemIndex ] ) then
        mapa_rozegrana_t[ Mapa_ComboBox.ItemIndex ] := true;

      Mapy_Losowe_Etykieta_Wylicz();


      if Informacja_GLHUDText.Visible then
        Informacja_GLHUDText.TagFloat := GLCadencer1.CurrentTime; // Gdy czas GLCadencer1 zostanie wyzerowany czas wy�wietlania komunikatu mo�e by� z poprzedniego odliczania.


      if not GLCadencer1.Enabled then
        Pauza_ButtonClick( Sender );

    end;
  //---//if Start_Stop_Button.Tag = 1 then


  Mapa_ComboBox.Enabled := Start_Stop_Button.Tag = 0;

end;//---//Start_Stop_ButtonClick().

//Pauza_ButtonClick().
procedure TPlanety_Form.Pauza_ButtonClick( Sender: TObject );
begin

  GLCadencer1.Enabled := not GLCadencer1.Enabled;

  if not GLCadencer1.Enabled then
    begin

      Pauza_Button.Font.Style := Pauza_Button.Font.Style + [ fsBold ];

      if GLSkyDome1.Bands.Count > 1 then
        begin

          GLSkyDome1.Bands[ 0 ].StartColor.Color := GLS.Color.clrGray40;
          GLSkyDome1.Bands[ 0 ].StopColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;
          GLSkyDome1.Bands[ 1 ].StartColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;
          GLSkyDome1.Bands[ 1 ].StopColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;

        end;
      //---//if GLSkyDome1.Bands.Count > 1 then

    end
  else//if not GLCadencer1.Enabled then
    begin

      Pauza_Button.Font.Style := Pauza_Button.Font.Style - [ fsBold ];

      if GLSkyDome1.Bands.Count > 1 then
        begin

          GLSkyDome1.Bands[ 0 ].StartColor.Color := GLS.Color.clrBlack;
          GLSkyDome1.Bands[ 0 ].StopColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;
          GLSkyDome1.Bands[ 1 ].StartColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;
          GLSkyDome1.Bands[ 1 ].StopColor.Color := GLSkyDome1.Bands[ 0 ].StartColor.Color;

        end;
      //---//if GLSkyDome1.Bands.Count > 1 then

    end;
  //---//if not GLCadencer1.Enabled then

end;//---//Pauza_ButtonClick().

//Pomoc_BitBtnClick().
procedure TPlanety_Form.Pomoc_BitBtnClick( Sender: TObject );
var
  czy_pauza : boolean;
begin

  czy_pauza := not GLCadencer1.Enabled;

  if not czy_pauza then
    Pauza_ButtonClick( Sender );

  //ShowMessage
  //  (
  //    'Klawiatura numeryczna: Del - obr�t kamery mysz�' + #13 +
  //    'X - odznacz wszystkie planety' + #13 +
  //    'F11 - opcje zwi� / rozwi�' + #13 +
  //    'F12 - opcje wy�wietl / ukryj' + #13 +
  //    'P, Pause Break - pauza' + #13 +
  //    'E - pe�ny ekran' + #13 +
  //    'F1 - pon�w ostatni ruch' + #13 +
  //    //'F1, F2, F3, F4 - pon�w ostatnie ruchy' + #13 +
  //    'F2, F3, F4 - pon�w zapami�tany ruch' + #13 +
  //    'Shift + F2, F3, F4 - zapami�taj ostatni ruch' + #13 +
  //    '+, -, * - pr�dko�� gry zwi�ksz, zmniejsz, domy�lna' + #13 +
  //    'Q - przestaw procent wysy�anych rakiet z planet mi�dzy 50% i 100%' + #13 +
  //    //'K, klawiatura numeryczna: 2 - resetuj kamer�' + #13 +
  //    'K - resetuj kamer�' + #13 +
  //    'Klawiatura numeryczna: 1, 3, 4, 5, 6, 7, 8, 9 - ruch kamery' + #13 +
  //    '1 .. 0 - ustaw procent wysy�anych rakiet z planet' + #13 +
  //    'Esc - wyj�cie' + #13 +
  //    'A - zaznacz wszystkie swoje planety' + #13 +
  //    '? - pomoc' + #13 +
  //    'LPM - zaznacz, odznacz planet� / wy�lij rakiety' + #13 +
  //    'Shift + LPM, PPM - zaznacz, odznacz planet�' + #13 +
  //    'PPM [trzymaj i wskazuj planety] - zaznacz, odznacz planet�' + #13 +
  //    'Ctrl + A - zaznacz wszystkie swoje planety i planety, na orbitach kt�rych masz rakiety'
  //  );

  ShowMessage
    (
      'Klawiatura numeryczna: Del - obr�t kamery mysz�' + #13 +
        '        Drehung der Kamera mit der Maus (Numerische Tastatur: Entf)' + #13 +
        '        rotation of the camera with the mouse (Numeric keyboard: Del)' + #13 +
      'X - odznacz wszystkie planety <Alle Planeten abw�hlen> <deselect all planets>' + #13 +
      'F11 - opcje zwi� / rozwi� <Optionen zuklappen / erweitern> <collapse / expand options>' + #13 +
      'F12 - opcje wy�wietl / ukryj <Optionen ein-/ausblenden> <show / hide options>' + #13 +
      'P, Pause Break - pauza <Pause> <pause>' + #13 +
      'E - pe�ny ekran <Vollbildschirm> <full screen>' + #13 +
      'F1 - pon�w ostatni ruch <Wiederhole deinen letzten Zug> <redo your last move>' + #13 +
      //'F1, F2, F3, F4 - pon�w ostatnie ruchy <Wiederhole deine letzten Z�ge> <redo your last moves>' + #13 +
      'F2, F3, F4 - pon�w zapami�tany ruch' + #13 +
        '        Wiederholen Sie die gespeicherte Bewegung' + #13 +
        '        redo the memorized movement' + #13 +
      'Shift + F2, F3, F4 - zapami�taj ostatni ruch' + #13 +
        '        Erinnere dich an den letzten Zug (Umschalttaste)' + #13 +
        '        remember the last move' + #13 +
      '+, -, * - pr�dko�� gry zwi�ksz, zmniejsz, domy�lna' + #13 +
        '        Spielgeschwindigkeit erh�hen, verringern, Standard' + #13 +
        '        game speed increase, decrease, default' + #13 +
      'Q - przestaw procent wysy�anych rakiet z planet mi�dzy 50% i 100%' + #13 +
        '        Prozentsatz der von Planeten gesendeten Raketen zwischen 50% und 100 % wechseln' + #13 +
        '        switch percentage of rockets sent from planets between 50% and 100%' + #13 +
      //'K, klawiatura numeryczna: 2 - resetuj kamer� <Kamera zur�cksetzen> <reset camera>' + #13 +
      'K - resetuj kamer� <Kamera zur�cksetzen> <reset camera>' + #13 +
      'Klawiatura numeryczna: 1, 3, 4, 5, 6, 7, 8, 9 - ruch kamery' + #13 +
        '        Kamerabewegung (Numerische Tastatur)' + #13 +
        '        camera movement (Numeric keypad)' + #13 +
      '1 .. 0 - ustaw procent wysy�anych rakiet z planet' + #13 +
        '        Stellen Sie den Prozentsatz der von Planeten verschifften Raketen ein' + #13 +
        '        set the percentage of rockets sent from planets' + #13 +
      'Esc - wyj�cie <Ausgang> <Exit>' + #13 +
      'A - zaznacz wszystkie swoje planety <W�hle alle deine Planeten aus <select all your planets>' + #13 +
      '? - pomoc <Hilfe> <help>' + #13 +
      'LPM - zaznacz, odznacz planet� / wy�lij rakiety' + #13 +
        '        Planeten ausw�hlen, abw�hlen / Raketen senden (LMB)' + #13 +
        '        select, deselect planet / send rockets (LMB)' + #13 +
      'Shift + LPM, PPM - zaznacz, odznacz planet�' + #13 +
        '        Planeten ausw�hlen, abw�hlen (Umschalttaste + LMB, RMB)' + #13 +
        '        select, deselect planet (LMB, RMB)' + #13 +
      'PPM [trzymaj i wskazuj planety] - zaznacz, odznacz planet�' + #13 +
        '        [halte und zeige auf Planeten ] - einen Planeten ausw�hlen, abw�hlen (RMB)' + #13 +
        '        [hold and indicate planets] - select, deselect a planet (RMB)' + #13 +
      'Ctrl + A - zaznacz wszystkie swoje planety i planety, na orbitach kt�rych masz rakiety' + #13 +
        '        W�hlen Sie alle Ihre Planeten und Planeten aus, auf denen Sie Raketen haben (Strg)' + #13 +
        '        select all your planets and planets in which you have rockets'
    );

  if not czy_pauza then
    Pauza_ButtonClick( Sender );

end;//---//Pomoc_BitBtnClick().

//Nast�pna_Misja_ButtonClick().
procedure TPlanety_Form.Nast�pna_Misja_ButtonClick( Sender: TObject );
var
  i,
  zti
    : integer;
begin

  if Start_Stop_Button.Tag = 1 then
    Start_Stop_ButtonClick( Sender );

  if Start_Stop_Button.Tag = 1 then
    Exit; // Je�eli nie b�dzie zezwolenia na zako�czenie aktywnej gry.


  if not Mapa_Wybieraj_Losowo_CheckBox.Checked then
    begin

      if Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 then
        begin

          if Komunikat_Wy�wietl( 'Jest to ostatnia misja czy przej�� do pierwszej misji?' + #13 + #13 + 'Es ist die letzte Mission, gehen zur ersten Mission?' + #13 + #13 + 'It is the last mission, go to the first mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
            Exit;

          Mapa_ComboBox.ItemIndex := 0;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo�uje si� Mapa_ComboBoxChange().


          for i := 0 to Length( mapa_rozegrana_t ) - 1 do
            mapa_rozegrana_t[ i ] := false;

          Mapy_Losowe_Etykieta_Wylicz();

        end
      else//if Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 then
        begin

          Mapa_ComboBox.ItemIndex := Mapa_ComboBox.ItemIndex + 1;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo�uje si� Mapa_ComboBoxChange().

        end;
      //---//if Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 then

    end
  else//if not Mapa_Wybieraj_Losowo_CheckBox.Checked then
    begin

      zti := 0;


      for i := 0 to Length( mapa_rozegrana_t ) - 1 do
        if mapa_rozegrana_t[ i ] then
          inc( zti );


      if zti = Length( mapa_rozegrana_t ) then
        begin

          if Komunikat_Wy�wietl( 'Jest to ostatnia misja czy rozpocz�� losowania od pocz�tku?' + #13 + #13 + 'Es ist die letzte Mission, die Auslosung noch einmal zu beginnen?' + #13 + #13 + 'It is the last mission start the draw all over again?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
            Exit;


          for i := 0 to Length( mapa_rozegrana_t ) - 1 do
            mapa_rozegrana_t[ i ] := false;

          //Mapy_Losowe_Etykieta_Wylicz(); // Jest wywo�ane w Mapa_Losuj_BitBtnClick().

        end;
      //---//if zti = Length( mapa_rozegrana_t ) then

      zti := Mapa_ComboBox.ItemIndex;

      Mapa_Losuj_BitBtnClick( Sender );

      if zti <> Mapa_ComboBox.ItemIndex then
        zti := -2 // Oznacza, �e wylosowano now� misj�.
      else//if zti <> Mapa_ComboBox.ItemIndex then
        zti := 0;

    end;
  //---//if not Mapa_Wybieraj_Losowo_CheckBox.Checked then



  statystyki__polecenia_ilo��__gra := statystyki__polecenia_ilo��__gra + statystyki__polecenia_ilo��__misja;
  statystyki__rakiet_straconych__gra := statystyki__rakiet_straconych__gra + statystyki__rakiet_straconych__misja;
  statystyki__rakiet_utworzonych__gra := statystyki__rakiet_utworzonych__gra + statystyki__rakiet_utworzonych__misja;


  if   ( not Mapa_Wybieraj_Losowo_CheckBox.Checked )
    or (
             ( Mapa_Wybieraj_Losowo_CheckBox.Checked )
         and ( zti = -2 )
       ) then
    Start_Stop_ButtonClick( Sender );

end;//---//Nast�pna_Misja_ButtonClick().

//Ruch_Ostatni_Pon�w_ButtonClick().
procedure TPlanety_Form.Ruch_Ostatni_Pon�w_ButtonClick( Sender: TObject );
begin

  Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_pon�w__id_planeta_z__1, ostatni_ruch_pon�w__planeta_docelowa__1 );

end;//---//Ruch_Ostatni_Pon�w_ButtonClick().

//Statystyki_ButtonClick().
procedure TPlanety_Form.Statystyki_ButtonClick( Sender: TObject );
begin

  Statystyki_Wy�wietl( {false,} false, id_grupa_neutralna_c );

end;//---//Statystyki_ButtonClick().

//Planety_Opisy_CheckBoxClick().
procedure TPlanety_Form.Planety_Opisy_CheckBoxClick( Sender: TObject );
var
  i : integer;
begin

  Planety_Opisy__Dodatkowe_Informacje_CheckBox.Enabled := Planety_Opisy_CheckBox.Enabled;


  for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible := Planety_Opisy_CheckBox.Checked;

end;//---//Planety_Opisy_CheckBoxClick().

//SpinEditChange().
procedure TPlanety_Form.SpinEditChange( Sender: TObject );
var
  zts : string;
begin

  if    ( Sender <> nil )
    and ( Sender is TSpinEdit ) then
    begin

      zts := '';

      if TComponent(Sender).Name = Gra_Pr�dko��_SpinEdit.Name then
        zts := 'Pr�dko�� gry ' + Trim(  FormatFloat( '### ### ##0', Gra_Pr�dko��_SpinEdit.Value )  ) + '%'
      else
      if TComponent(Sender).Name = Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Name then
        zts := 'Rakiety ' + Trim(  FormatFloat( '### ### ##0', Rakiety_Ilo��_Procent_Wys�anie_SpinEdit.Value )  ) + '%';

      if zts <> '' then
        Informacja_Wy�wietl( zts );


      if TComponent(Sender).Name = SI_Decyduj__Cykl_Sekundy_SpinEdit.Name then
        begin

          si_decyduj__cykl_sekundy_g := SI_Decyduj__Cykl_Sekundy_SpinEdit.Value;

          if si_decyduj__cykl_sekundy_g < SI_Decyduj__Cykl_Sekundy_SpinEdit.MinValue then
            si_decyduj__cykl_sekundy_g := SI_Decyduj__Cykl_Sekundy_SpinEdit.MinValue
          else//if si_decyduj__cykl_sekundy_g < SI_Decyduj__Cykl_Sekundy_SpinEdit.MinValue then
          if si_decyduj__cykl_sekundy_g > SI_Decyduj__Cykl_Sekundy_SpinEdit.MaxValue then
            si_decyduj__cykl_sekundy_g := SI_Decyduj__Cykl_Sekundy_SpinEdit.MaxValue;

          SI_Decyduj__Modyfikator_Losowy_Ustaw();

        end;
      //---//if TComponent(Sender).Name = SI_Decyduj__Cykl_Sekundy_SpinEdit.Name then

    end;
  //---//if    ( Sender <> nil ) (...)

end;//---//SpinEditChange().

//SI_Trudno��_ButtonClick().
procedure TPlanety_Form.SI_Trudno��_ButtonClick( Sender: TObject );
begin

  if    ( Sender <> nil )
    and ( Sender is TButton ) then
    begin

      //if TComponent(Sender).Name = SI_Normalne_Button.Name then
      //  SI_Decyduj__Cykl_Sekundy_SpinEdit.Value := 10
      if TComponent(Sender).Name = SI_Trudniejsze_Button.Name then
        SI_Decyduj__Cykl_Sekundy_SpinEdit.Value := 5
      else//if TComponent(Sender).Name = SI_Trudniejsze_Button.Name then
        SI_Decyduj__Cykl_Sekundy_SpinEdit.Value := 10;

    end;
  //---//if    ( Sender <> nil ) (...)

end;//---//SI_Trudno��_ButtonClick().

//Decyzje_Gracza_Zapisz_ButtonClick().
procedure TPlanety_Form.Decyzje_Gracza_Zapisz_ButtonClick( Sender: TObject );
var
  czy_pauza : boolean;
  zts,
  data_czas
    : string;
  zt_string_list : TStringList;
begin

  if Trim( decyzje_gracza_g ) = '' then
    begin

      Komunikat_Wy�wietl( 'Brak zapami�tanych decyzji gracza.' + #13 + #13 + 'Entscheidungen des Spielers werden nicht gespeichert.' + #13 + #13 + 'Player''s decisions are not remembered.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if Trim( decyzje_gracza_g ) = '' then


  zts := ExtractFilePath( Application.ExeName ) + decyzje_gracza__katalog_nazwa_c;

  if not DirectoryExists( zts ) then
    begin

      Komunikat_Wy�wietl( PChar('Nie odnaleziono podkatalogu ''' + decyzje_gracza__katalog_nazwa_c + '''.' + #13 + #13 + 'Unterverzeichnis nicht gefunden.' + #13 + #13 + 'Subdirectory not found.'), 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if not DirectoryExists( zts ) then


  if Komunikat_Wy�wietl( 'Czy zapisa� dane o decyzjach gracza do pliku?' + #13 + #13 + 'Die Entscheidungsdaten des Players in einer Datei speichern?' + #13 + #13 + 'Save the decision data of the player in a file?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON1 + MB_ICONQUESTION ) <> IDYES then
    Exit;


  czy_pauza := not GLCadencer1.Enabled;

  if not czy_pauza then
    Pauza_ButtonClick( Sender );


  DateTimeToString( data_czas, 'yyyy-mm-dd hh mm ss', Now() );
  zts := zts + '\' + data_czas + ' ' + Mapa_ComboBox.Text + '.csv';

  zt_string_list := TStringList.Create();
  zt_string_list.Add( decyzje_gracza_g );
  zt_string_list.SaveToFile( zts );
  FreeAndNil( zt_string_list );


  Komunikat_Wy�wietl( 'Zapis do pliku zako�czony (' + zts + ').' + #13 + #13 + #13 + 'Schreiben in Datei abgeschlossen.' + #13 + #13 + 'Writing to file completed.', 'Informacja', MB_OK + MB_ICONINFORMATION );


  if not czy_pauza then
    Pauza_ButtonClick( Sender );

end;//---//Decyzje_Gracza_Zapisz_ButtonClick().

//Grupa_Fann_Decyduje__Zaznacz_ButtonClick().
procedure TPlanety_Form.Grupa_Fann_Decyduje__Zaznacz_ButtonClick( Sender: TObject );
var
  i : integer;
begin

  if   ( Sender = nil )
    or (  not ( Sender is TButton )  ) then
    Exit;



  for i := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
    if TComponent(Sender).Name = Grupa_Fann_Decyduje__Odwr��_Zaznaczenie_Button.Name then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := not Grupa_Fann_Decyduje_CheckListBox.Checked[ i ]
    else//if TComponent(Sender).Name = Grupa_Fann_Decyduje__Odwr��_Zaznaczenie_Button.Name then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := TComponent(Sender).Name = Grupa_Fann_Decyduje__Zaznacz_Wszystko_Button.Name;

end;//---//Grupa_Fann_Decyduje__Zaznacz_ButtonClick().

//FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_ButtonClick().
procedure TPlanety_Form.FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_ButtonClick( Sender: TObject );
begin

  if FANN__Opcje_Dodatkowe_GroupBox.Height <> 35 then
    FANN__Opcje_Dodatkowe_GroupBox.Height := 35
  else//if FANN__Opcje_Dodatkowe_GroupBox.Height <> 35 then
    FANN__Opcje_Dodatkowe_GroupBox.Height := 275; //???

end;//---//FANN__Opcje_Dodatkowe__Wysoko��_Zmie�_ButtonClick().

//FANN__Przygotuj_ButtonClick().
procedure TPlanety_Form.FANN__Przygotuj_ButtonClick( Sender: TObject );
begin

  {$IFDEF si_fann_u�ywaj}
  FANN_Przygotuj();
  {$ENDIF}

end;//---//FANN__Przygotuj_ButtonClick().

//FANN__Zwolnij_ButtonClick().
procedure TPlanety_Form.FANN__Zwolnij_ButtonClick( Sender: TObject );
begin

  {$IFDEF si_fann_u�ywaj}
  if fann_network <> nil then
    FreeAndNil( fann_network );


  if Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled then
    Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled := false;

  if Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled then
    Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled := false;


  if not Grupa_Fann_Decyduje__Algorytm_Tylko_RadioButton.Checked then
    Grupa_Fann_Decyduje__Algorytm_Tylko_RadioButton.Checked := true;


  Grupa_Fann_Decyduje__Zaznacz_ButtonClick( Grupa_Fann_Decyduje__Odznacz_Wszystko_Button );
  {$ENDIF}

end;//---//FANN__Zwolnij_ButtonClick().

//FANN__Zapisz_ButtonClick().
procedure TPlanety_Form.FANN__Zapisz_ButtonClick( Sender: TObject );
{$IFDEF si_fann_u�ywaj}
var
  zts : string;
{$ENDIF}
begin

  {$IFDEF si_fann_u�ywaj}
  if fann_network = nil then
    begin

      Komunikat_Wy�wietl( 'Sie� FANN nie zosta�a przygotowana.' + #13 + #13 + 'Das FANN-Netzwerk ist nicht vorbereitet.' + #13 + #13 + 'The FANN network has not been prepared.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if fann_network = nil then

  if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  )
    or (  Length( FANN__Plik_Nazwa_ComboBox.Text ) < 1  ) then
    begin

      PageControl1.ActivePage := SI_TabSheet;
      FANN__Plik_Nazwa_ComboBox.SetFocus();
      Komunikat_Wy�wietl( 'Nazwa pliku nie mo�e by� pusta.' + #13 + #13 + 'Der Dateiname darf nicht leer sein.' + #13 + #13 + 'The file name cannot be empty.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  ) (...)


  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;


  if FileExists( zts ) then
    begin

      if Komunikat_Wy�wietl( 'Plik istnieje: ' + zts + '.' + #13 + #13 + 'Czy nadpisa�?' + #13 + #13 + #13 + 'Die Datei existiert. �berschreiben?' + #13 + #13 + 'The file exists. Overwrite?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
        Exit;

    end
  else//if FileExists( zts ) then
    if Komunikat_Wy�wietl( 'Zapisa� plik pod nazw�:' + #13 + zts + #13 + '?' + #13 + #13 + #13 + 'Datei unter Namen speichern?' + #13 + #13 + 'Save the file as a name?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
      Exit;


  fann_network.SaveToFile( PWideChar(AnsiString(zts)) );


  FANN_Zapisane_Nazwy_Wyszukaj();
  {$ENDIF}

end;//---//FANN__Zapisz_ButtonClick().

//FANN__Wczytaj_ButtonClick().
procedure TPlanety_Form.FANN__Wczytaj_ButtonClick( Sender: TObject );
{$IFDEF si_fann_u�ywaj}
var
  zts : string;
{$ENDIF}
begin

  {$IFDEF si_fann_u�ywaj}
  if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  )
    or (  Length( FANN__Plik_Nazwa_ComboBox.Text ) < 1  ) then
    begin

      PageControl1.ActivePage := SI_TabSheet;
      FANN__Plik_Nazwa_ComboBox.SetFocus();
      Komunikat_Wy�wietl( 'Nazwa pliku nie mo�e by� pusta.' + #13 + #13 + 'Der Dateiname darf nicht leer sein.' + #13 + #13 + 'The file name cannot be empty.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  ) (...)


  if fann_network = nil then
    FANN_Przygotuj( true );


  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;


  if not FileExists( zts ) then
    begin

      Komunikat_Wy�wietl( 'Nie odnaleziono pliku:' + #13 + zts + '.' + #13 + #13 + 'Datei nicht gefunden.' + #13 + #13 + 'File not found.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if not FileExists( zts ) then


  fann_network.LoadFromFile( PWideChar(AnsiString(zts)) );
  {$ENDIF}

end;//---//FANN__Wczytaj_ButtonClick().

//Test_ButtonClick().
procedure TPlanety_Form.Test_ButtonClick( Sender: TObject );
//var
//  i : integer;
begin

  // Do test�w.
  //???

end;//---//Test_ButtonClick().

end.
