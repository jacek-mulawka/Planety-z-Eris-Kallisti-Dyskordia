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


  // Kierunki wspó³rzêdnych uk³adu g³ównego.
  //
  //     góra y
  //     przód -z
  // lewo -x
  //     ty³ z
  //

  // Start_Stop_Button.Tag = 0 - nie ma aktywnej gry.
  // Start_Stop_Button.Tag = 1 - gra jest w trakcie.

  // Przyk³adowa zale¿noœæ:
  //   planeta pojemnoœæ = planeta skala * 20.

  // Rakiety s¹ tworzone na planetach wed³ug kolejnoœci planet jako potomków a nie grup.
  // Rakiety zwalczaj¹ siê wed³ug kolejnoœci na liœcie rakiet.
  // Podczas zwalczania siê rakiet kolejnoœæ grup nie powinna preferowaæ jednych grup wzglêdem innych.

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

  {$IFDEF si_fann_u¿ywaj}
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
      id_grupa_zdobywaj¹ca_planetê,
      iloœæ_pocz¹tkowa_rakiet,
      pojemnoœæ_rakiet
        : integer;

      przejmowanie_poziom_aktualny,
      przyrost_postêp_aktualny, // W ka¿dym cyklu zwiêksza siê o przyrost_szybkoœæ i czêœæ ca³kowita zamienia siê w rakietê np.: 0 + 0,3 + 0,3 + 0,3 + 0,3 -> 1,2 = 1 rakieta i 0,2 przyrost_postêp_aktualny.
      przyrost_szybkoœæ
        : real;

      planeta_kula_gl_sphere : TGLSphere;
      losowy_obrót_gl_dummy_cube, // Aby tworzone rakiety pojawia³y siê w ro¿nych miejscach orbity.
      orbita_dla_rakiet_gl_dummy_cube
        : TGLDummyCube;

      atmosfera_gl_atmosphere : TGLAtmosphere;

      opis_gl_space_text : TGLSpaceText;

      pierœcieñ_gl_torus : TGLTorus; // Reprezentuje zajêtoœæ miejsca na orbicie planety przez rakiety.
  public
    { Public declarations }
    constructor Create();
    destructor Destroy(); override;

    procedure Przyrost_Przeliczaj();

    function Rakiety_Na_Orbicie_Iloœæ( const id_grupa_f : integer = -1 ) : integer;

    procedure Zaznaczenie_Ustaw( const zaznaczona_f : boolean );
  end;//---//TPlaneta

  TRakieta = class( TGLDummyCube )
    private
      czy_usun¹æ : boolean;

      id_planeta,
      id_grupa
        : integer;

      planeta_docelowa_wspó³rzêdne_na_orbicie : GLS.VectorTypes.TVector4f; // Wspó³rzêdne na orbicie docelowej aby rakiety nie przybywa³y wszystkie w to samo miejsce.

      planeta_docelowa : TPlaneta;

      kad³ub_gl_cone,
      silnik_g³ówny_gl_cone
        : TGLCone;
  public
    { Public declarations }
    constructor Create( planeta_f : TPlaneta );
    destructor Destroy(); override;

    function Orbita_Odleg³oœæ_Ustaw( planeta_f : TPlaneta ) : single;
    procedure Orbita_Kierunek_Ustaw();
  end;//---//TRakieta

  TWalka_Efekt = class( TGLDummyCube )
    private
      wzrost_kierunek : integer; // Znak tej wartoœci okreœla czy rozmiar efektu siê zwiêksza czy zmniejsza.

      utworzenie_czas : double;

      gl_thor_fx_manager : GLS.ThorFX.TGLThorFXManager;
  public
    { Public declarations }
    constructor Create( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
    destructor Destroy(); override;
  end;//---//TWalka_Efekt

  TFann_Zaœlepka = class
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
  end;//---//TFann_Zaœlepka

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
    Gra_Prêdkoœæ_Etykieta_Label: TLabel;
    Gra_Prêdkoœæ_SpinEdit: TSpinEdit;
    Rakiety_Iloœæ_Procent_Wys³anie_Etykieta_Label: TLabel;
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit: TSpinEdit;
    GLAtmosphere1: TGLAtmosphere;
    GLSpaceText1: TGLSpaceText;
    Test_Button: TButton;
    Pomoc_BitBtn: TBitBtn;
    Nastêpna_Misja_Button: TButton;
    Statystyki_Button: TButton;
    Planety_Opisy_CheckBox: TCheckBox;
    Wspó³rzêdne_Test_GLDummyCube: TGLDummyCube;
    Ruch_Ostatni_Ponów_Button: TButton;
    Planety_Opisy__Dodatkowe_Informacje_CheckBox: TCheckBox;
    GLTorus1: TGLTorus;
    Zajêtoœæ_Orbity_Wizualizuj_CheckBox: TCheckBox;
    SI_TabSheet: TTabSheet;
    SI_Log_Memo: TMemo;
    Informacja_GLHUDSprite: TGLHUDSprite;
    Informacja_GLHUDText: TGLHUDText;
    Informacja_GLWindowsBitmapFont: TGLWindowsBitmapFont;
    SI_Góra_Panel: TPanel;
    SI_Loguj_CheckBox: TCheckBox;
    SI_Normalne_Button: TButton;
    SI_Trudniejsze_Button: TButton;
    SI_Decyduj__Cykl_Sekundy_Etykieta_Label: TLabel;
    SI_Decyduj__Cykl_Sekundy_SpinEdit: TSpinEdit;
    Decyzje_Gracza_Zapamiêtuj_CheckBox: TCheckBox;
    Decyzje_Gracza_Zapisz_Button: TButton;
    Grupa_Fann_Decyduje_GroupBox: TGroupBox;
    Grupa_Fann_Decyduje_CheckListBox: TCheckListBox;
    Grupa_Fann_Decyduje__Zaznacz_Wszystko_Button: TButton;
    Grupa_Fann_Decyduje__Odznacz_Wszystko_Button: TButton;
    Grupa_Fann_Decyduje__Odwróæ_Zaznaczenie_Button: TButton;
    Fann_Nauka_ProgressBar: TProgressBar;
    FANN__Przygotuj_Button: TButton;
    FANN__Opcje_Dodatkowe_GroupBox: TGroupBox;
    FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_Button: TButton;
    FANN__Epoki_Iloœæ_Etykieta_Label: TLabel;
    FANN__Epoki_SpinEdit: TSpinEdit;
    FANN__Algorytm_Ucz¹cy_Etykieta_Label: TLabel;
    FANN__Algorytm_Ucz¹cy_ComboBox: TComboBox;
    FANN__Funkcja_Aktywuj¹ca_Warstw_Ukrytych_Etykieta_Label: TLabel;
    FANN__Funkcja_Aktywuj¹ca_Warstw_Ukrytych_ComboBox: TComboBox;
    FANN__Funkcja_Aktywuj¹ca_Warstwy_Wyjœcia_Etykieta_Label: TLabel;
    FANN__Funkcja_Aktywuj¹ca_Warstwy_Wyjœcia_ComboBox: TComboBox;
    FANN__Zapisz_Button: TButton;
    FANN__Wczytaj_Button: TButton;
    FANN__Plik_Nazwa_ComboBox: TComboBox;
    FANN__Zwolnij_Button: TButton;
    Neuronów_W_Warstwach_Ukrytych_Edit: TEdit;
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
    procedure Nastêpna_Misja_ButtonClick( Sender: TObject );
    procedure Ruch_Ostatni_Ponów_ButtonClick( Sender: TObject );
    procedure Statystyki_ButtonClick( Sender: TObject );
    procedure Planety_Opisy_CheckBoxClick( Sender: TObject );
    procedure SpinEditChange( Sender: TObject );
    procedure SI_Trudnoœæ_ButtonClick( Sender: TObject );
    procedure Decyzje_Gracza_Zapisz_ButtonClick( Sender: TObject );
    procedure Grupa_Fann_Decyduje__Zaznacz_ButtonClick( Sender: TObject );

    procedure FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_ButtonClick( Sender: TObject );
    procedure FANN__Przygotuj_ButtonClick( Sender: TObject );
    procedure FANN__Zwolnij_ButtonClick( Sender: TObject );
    procedure FANN__Zapisz_ButtonClick( Sender: TObject );
    procedure FANN__Wczytaj_ButtonClick( Sender: TObject );

    procedure Test_ButtonClick( Sender: TObject );
  private
    { Private declarations }
    czy_zwyciêstwo, // Czy misja zakoñczy³a siê czyimœ zwyciêstwem albo gracz przegra³.
    statystyki_wykres_liniowy_menuitem_checked_g, // Zapamiêtuje ustawienia z okna statystyk.
    statystyki_wykres_s³upkowy_menuitem_checked_g  // Zapamiêtuje ustawienia z okna statystyk.
      : boolean;

    decyzje_gracza_numer_g,
    planety_iloœæ_mapa_g, // Iloœæ planet na mapie.
    si_decyduj__cykl_sekundy_g,
    si_decyduj__cykl_sekundy__modyfikator_losowy_g
      : integer;

    przyrost__ostatnie_przeliczenie_g,
    si_decyduj__ostatnie_przeliczenie_g,
    zwalczanie_poza_orbit¹__ostatnie_przeliczenie_g,
    zwyciêstwo_sprawdŸ__ostatnie_przeliczenie_g
      : double;

    si__odleg³oœæ_najwiêksza_miêdzy_planetami_g,
    si__przyrost_szybkoœæ_planety_najwiêkszy_g,
    si__wielkoœæ_planety_najwiêksza_g
      : real;

    zaznaczanie_ruchem_myszy__opóŸnienie_data_czas, // Aby wywo³ywa³o funkcjê podczas ruchu myszy ale z pewnymi przerwami.
    zaznaczanie_ruchem_myszy__opóŸnienie__zaznacze_data_czas // Przerwa po tym jak planeta siê zaznaczy albo odznaczy.
      : TDateTime;

    decyzje_gracza_g, // Zapamiêtanie konfiguracji mapy gdy gracz wykonywa³ ruch.
    ostatni_ruch_ponów__id_planeta_z__1,
    ostatni_ruch_ponów__id_planeta_z__2,
    ostatni_ruch_ponów__id_planeta_z__3,
    ostatni_ruch_ponów__id_planeta_z__4
      : string;

    rakiety_list,
    walka_efekt_list
      : TList;

    kamera_pozycja_pocz¹tkowa_g : GLS.VectorTypes.TVector4f;

    ostatni_ruch_ponów__planeta_docelowa__1,
    ostatni_ruch_ponów__planeta_docelowa__2,
    ostatni_ruch_ponów__planeta_docelowa__3,
    ostatni_ruch_ponów__planeta_docelowa__4
      : TPlaneta;

    kolor_grupa_r_t : array of TKolor_Grupa_r; // Je¿eli pojawi siê grupa spoza zakresu przygotowanych kolorów zapamiêta tutaj wylosowany dla niej kolor.

    mapa_rozegrana_t : array of boolean; // Oznacza, ¿e na danej mapie odby³a siê ju¿ rozgrywka (ma znaczenie gdy mapy s¹ wybierane losowo). Indeks tabeli odpowiada Mapa_ComboBox.ItemIndex.

    {$IFDEF si_fann_u¿ywaj}
    fann_network : FannNetwork.TFannNetwork;
    {$ELSE si_fann_u¿ywaj}
    fann_network : TFann_Zaœlepka;
    {$ENDIF}
    function Komunikat_Wyœwietl( const text_f, caption_f : string; const flags_f : integer ) : integer;

    procedure Kamera_Ruch( delta_czasu_f : double );

    function Gra_Prêdkoœæ() : real;

    procedure Mapy_Wczytaj();
    function Mapa_Utwórz() : boolean;
    procedure Mapa_Zwolnij();

    procedure Rakiety_Utwórz_Jeden( planeta_f : TPlaneta );
    //procedure Rakiety_Zwolnij_Jeden( rakieta_f : TRakieta  );
    procedure Rakiety_Zwolnij_Wszystkie();
    procedure Rakiety_Cel_Ustaw( const id_grupa_f : integer; id_planeta_z_s_f : string; planeta_docelowa_f : TPlaneta; rakiety_iloœæ_procent_wys³anie_f : real = -1 );
    procedure Rakiety_Lot_Do_Celu( delta_czasu_f : double );

    procedure Walka_Efekt_Utwórz_Jeden( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
    procedure Walka_Efekt_Zwolnij_Jeden( walka_efekt_f : TWalka_Efekt  );
    procedure Walka_Efekt_Zwolnij_Wszystkie();

    procedure Orbita_Rakiety_Zwalczanie( const poza_orbit¹_tylko_f : boolean );

    procedure Planety_Przejmowanie_Przeliczaj();

    procedure SI_Decyduj( const id_grupa_f : integer = -1; const decyzja_gracza__planeta_docelowa__id_planeta_f : integer = -1 );
    procedure SI_Decyduj__Modyfikator_Losowy_Ustaw();

    function Zwyciêstwo_SprawdŸ( out id_grupa_wy : integer ) : boolean;
    function Przegrana_Gracza_SprawdŸ( out id_grupa_wy : integer ) : boolean;

    procedure Statystyki_Tabela_Utwórz();
    procedure Statystyki_Tabela_Wartoœci_Kolejne_Zapamiêtaj();
    procedure Statystyki_Tabela_Czyœæ();

    procedure Statystyki_Wyœwietl( const {czy_przyciski_f,} czy_zwyciêstwo_f : boolean; const id_grupa_f : integer );

    procedure Informacja_Wyœwietl( const napis_f : string );

    procedure Mapy_Losowe_Etykieta_Wylicz();

    procedure FANN_Przygotuj( const tylko_utwórz_sieæ_f : boolean = false );

    procedure FANN_Zapisane_Nazwy_Wyszukaj();
  public
    { Public declarations }
    statystyki__polecenia_iloœæ__gra,
    statystyki__polecenia_iloœæ__misja,
    statystyki__rakiet_straconych__gra,
    statystyki__rakiet_straconych__misja,
    statystyki__rakiet_utworzonych__gra,
    statystyki__rakiet_utworzonych__misja
      : integer;

    statystyki_tabela_t : array of array of integer; // Pierwsza wartoœæ oznacza id grupy, kolejne to iloœæ rakiet danej w grupy w momencie pomiaru.

    function Kolor_Grupa_Ustaw( id_grupa_f : integer ) : GLS.VectorTypes.TVector4f;
  end;

const
  id_grupa_gracza_c : integer = 1;
  id_grupa_neutralna_c : integer = 0;
  decyzje_gracza__katalog_nazwa_c : string = 'Decyzje gracza';
  przyrost__cykl_sekundy_c = 2;
  rakieta_prêdkoœæ_c : Real = 1;
  //si_decyduj__cykl_sekundy_c = 5;
  si_decyduj__planety_posiadane_procent_próg_c : real = 10; // Gdy grupa posi¹dzie zadany procent planet inaczej wartoœciuje parametry.
  fann_sieci_zapisane__katalog_nazwa_c : string = 'Sieci zapisane';
  fann_sieci_zapisane__kropka_rozszerzenie_c : string = '.sieæ_fann';
  walka_efekt__czas_trwania_sekundy_c = 5; // Po ilu sekundach znika efekt walki.
  zwalczanie_poza_orbit¹__cykl_sekundy_c = 1; // Co ile czasu nast¹pi kolejne sprawdzenie zwyciêstwa w misji.
  zwyciêstwo_sprawdŸ__cykl_sekundy_c = 10;

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
  //Self.Pickable := false; // Blokuje klikanie w kulê planety.

  Self.zaznaczona := false;
  Self.id_planeta := -1;
  Self.id_grupa := id_grupa_neutralna_c;
  Self.id_grupa_zdobywaj¹ca_planetê := id_grupa_neutralna_c;
  Self.iloœæ_pocz¹tkowa_rakiet := 0;
  Self.pojemnoœæ_rakiet := 0;
  Self.przejmowanie_poziom_aktualny := 0;
  Self.przyrost_postêp_aktualny := 0;
  Self.przyrost_szybkoœæ := 0;

  Self.planeta_kula_gl_sphere := TGLSphere.Create( Self );
  Self.planeta_kula_gl_sphere.Parent := Self;
  //Self.planeta_kula_gl_sphere.Pickable := true;

  Self.orbita_dla_rakiet_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.orbita_dla_rakiet_gl_dummy_cube.Parent := Self;
  Self.orbita_dla_rakiet_gl_dummy_cube.Pickable := false;

  Self.losowy_obrót_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.losowy_obrót_gl_dummy_cube.Parent := Self;
  Self.losowy_obrót_gl_dummy_cube.Pickable := false;

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

  Self.pierœcieñ_gl_torus := TGLTorus.Create( Self );
  Self.pierœcieñ_gl_torus.Parent := Self.planeta_kula_gl_sphere;
  Self.pierœcieñ_gl_torus.Pickable := false;
  Self.pierœcieñ_gl_torus.PitchAngle := 90;
  Self.pierœcieñ_gl_torus.MajorRadius := 0.5;
  Self.pierœcieñ_gl_torus.Scale.X := 1;
  Self.pierœcieñ_gl_torus.Scale.Y := 1;
  Self.pierœcieñ_gl_torus.Scale.Z := 0.5;
  Self.pierœcieñ_gl_torus.Material.BlendingMode := bmTransparency;
  Self.pierœcieñ_gl_torus.Material.FrontProperties.Ambient.Color := GLS.Color.clrTransparent;
  Self.pierœcieñ_gl_torus.Material.FrontProperties.Emission.Color := GLS.Color.clrTransparent;

  //Self.VisibleAtRunTime := true; //???
  //Self.ShowAxes := true; //???

  //Self.orbita_dla_rakiet_gl_dummy_cube.VisibleAtRunTime := true; //???
  //Self.losowy_obrót_gl_dummy_cube.VisibleAtRunTime := true; //???

end;//---//Konstruktor klasy TPlaneta.

//Destruktor klasy TPlaneta.
destructor TPlaneta.Destroy();
begin

  FreeAndNil( Self.atmosfera_gl_atmosphere );
  FreeAndNil( Self.pierœcieñ_gl_torus );
  FreeAndNil( Self.opis_gl_space_text );
  FreeAndNil( Self.planeta_kula_gl_sphere );
  FreeAndNil( Self.orbita_dla_rakiet_gl_dummy_cube );
  FreeAndNil( Self.losowy_obrót_gl_dummy_cube );

  inherited;

end;//---//Destruktor klasy TPlaneta.

//Funkcja Przyrost_Przeliczaj().
procedure TPlaneta.Przyrost_Przeliczaj();
var
  i,
  rakiet_nowych,
  rakiety_na_orbicie__iloœæ,
  rakiety_na_orbicie__miejsc_na_przyrost
    : integer;
begin

  if Self.przejmowanie_poziom_aktualny <= 0 then
    Exit;


  Self.przyrost_postêp_aktualny := Self.przyrost_postêp_aktualny + Self.przyrost_szybkoœæ;

  rakiet_nowych := Trunc( Self.przyrost_postêp_aktualny );

  if rakiet_nowych > 0 then
    begin

      Self.przyrost_postêp_aktualny := Self.przyrost_postêp_aktualny - rakiet_nowych;

      rakiety_na_orbicie__iloœæ := 0;

      for i := Self.orbita_dla_rakiet_gl_dummy_cube.Count - 1 downto 0 do
        if Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ] is TRakieta then
          inc( rakiety_na_orbicie__iloœæ );

      rakiety_na_orbicie__miejsc_na_przyrost := Self.pojemnoœæ_rakiet - rakiety_na_orbicie__iloœæ;

      if rakiety_na_orbicie__miejsc_na_przyrost > 0 then
        begin

          if rakiet_nowych > rakiety_na_orbicie__miejsc_na_przyrost then
            rakiet_nowych := rakiety_na_orbicie__miejsc_na_przyrost;

          for i := 1 to rakiet_nowych do
            Planety_Form.Rakiety_Utwórz_Jeden( Self );

        end;
      //---//if rakiety_na_orbicie__miejsc_na_przyrost > 0 then

    end;
  //---//if rakiet_nowych > 0 then

end;//---//Funkcja Przyrost_Przeliczaj().

//Funkcja Rakiety_Na_Orbicie_Iloœæ().
function TPlaneta.Rakiety_Na_Orbicie_Iloœæ( const id_grupa_f : integer = -1 ) : integer;
var
  i : integer;
begin

  //
  // Funkcja zlicza iloœæ rakiet na orbicie planety.
  //
  // Zwraca iloœæ rakiet na orbicie planety.
  //
  // Parametry:
  //   id_grupa_f:
  //     -1 - iloœæ wszystkich rakiet dowolnej grupy.
  //     <> -1 - iloœæ rakiet wskazanej grupy.
  //

  Result := 0;

  for i := 0 to Self.orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
    if    ( Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ] is TRakieta )
      and (
               ( id_grupa_f = -1 )
            or ( TRakieta(Self.orbita_dla_rakiet_gl_dummy_cube.Children[ i ]).id_grupa = id_grupa_f )
          ) then
      inc( Result );

end;//---//Funkcja Rakiety_Na_Orbicie_Iloœæ().

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

  Self.czy_usun¹æ := false;

  Self.id_planeta := planeta_f.id_planeta;
  Self.id_grupa := planeta_f.id_grupa;

  Self.planeta_docelowa := nil;

  // Ustawia rakietê w planecie, losuje pozycjê i przenosi na obrotowy element.
  //Self.Parent := planeta_f;
  //Self.Position.X := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * (  0.5 + Random( 11 ) * 0.01  );
  //zt_vector := Self.AbsolutePosition;
  //Self.Parent := planeta_f.orbita_dla_rakiet_gl_dummy_cube;
  //Self.Position.AsVector := Self.Parent.AbsoluteToLocal( zt_vector );

  Self.Parent := planeta_f.losowy_obrót_gl_dummy_cube;
  Self.Position.X := Self.Orbita_Odleg³oœæ_Ustaw( planeta_f );
  planeta_f.losowy_obrót_gl_dummy_cube.Roll(  Random( 361 )  );
  //planeta_f.losowy_obrót_gl_dummy_cube.Roll( 5 );
  zt_vector := Self.AbsolutePosition;
  Self.Parent := planeta_f.orbita_dla_rakiet_gl_dummy_cube;
  Self.Position.AsVector := Self.Parent.AbsoluteToLocal( zt_vector );

  Self.Orbita_Kierunek_Ustaw();


  Self.kad³ub_gl_cone := TGLCone.Create( Self );
  Self.kad³ub_gl_cone.Parent := Self;
  Self.kad³ub_gl_cone.Scale.Scale( 0.05 );
  Self.kad³ub_gl_cone.PitchAngle := -90;

  Self.kad³ub_gl_cone.Material.FrontProperties.Diffuse.Color := Planety_Form.Kolor_Grupa_Ustaw( planeta_f.id_grupa );


  Self.silnik_g³ówny_gl_cone := TGLCone.Create( Self );
  Self.silnik_g³ówny_gl_cone.Parent := Self.kad³ub_gl_cone;
  Self.silnik_g³ówny_gl_cone.Scale.Scale( 0.5 );
  Self.silnik_g³ówny_gl_cone.Scale.Y := Self.silnik_g³ówny_gl_cone.Scale.Y * 2;
  Self.silnik_g³ówny_gl_cone.PitchAngle := 180;
  Self.silnik_g³ówny_gl_cone.Position.Y := -Self.kad³ub_gl_cone.Height;
  Self.silnik_g³ówny_gl_cone.Material.FrontProperties.Diffuse.Color := GLS.Color.clrWhite;


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

  if    ( Self.czy_usun¹æ )
    and ( Self.id_grupa = id_grupa_gracza_c ) then
    begin

      //inc( Planety_Form.statystyki__rakiet_straconych__gra );
      inc( Planety_Form.statystyki__rakiet_straconych__misja );

    end;
  //---//if    ( Self.czy_usun¹æ ) (...)


  FreeAndNil( Self.silnik_g³ówny_gl_cone );
  FreeAndNil( Self.kad³ub_gl_cone );

  inherited;

end;//---//Destruktor klasy TRakieta.

//Funkcja Orbita_Odleg³oœæ_Ustaw().
function TRakieta.Orbita_Odleg³oœæ_Ustaw( planeta_f : TPlaneta ) : single;
begin

  //
  // Funkcja ustala w jakiej odleg³oœci od planety rakieta kr¹¿y na orbicie.
  //

  if planeta_f <> nil then
    //Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * (  0.5 + Random( 11 ) * 0.01  )
    //Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * 0.5 + Random( 1501 ) * 0.001 // + od 0 do 1.5.
    Result := TGLDummyCube(planeta_f.orbita_dla_rakiet_gl_dummy_cube).CubeSize * 0.5 + Random( 1001 ) * 0.001 // + od 0 do 1.0. //???
  else//if planeta_f <> nil then
    Result := 1;

end;//---//Funkcja Orbita_Odleg³oœæ_Ustaw().

//Funkcja Orbita_Kierunek_Ustaw().
procedure TRakieta.Orbita_Kierunek_Ustaw();
var
  ztr : real;
begin

  //
  // Funkcja obraca rakietê aby na orbicie ustawi³a siê przodem w kierunku lotu.
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

//Konstruktor klasy TFann_Zaœlepka.
constructor TFann_Zaœlepka.Create( Aowner : TComponent );
begin

  //Self.Layers := TStringList.Create();

end;//---//Konstruktor klasy TFann_Zaœlepka.

//Destruktor klasy TFann_Zaœlepka.
destructor TFann_Zaœlepka.Destroy();
begin

  //FreeAndNil( Self.Layers );

end;//---//Destruktor klasy TFann_Zaœlepka.

////Funkcja Build().
//procedure TFann_Zaœlepka.Build();
//begin
//end;//---//Funkcja Build().

////Funkcja UnBuild().
//procedure TFann_Zaœlepka.UnBuild();
//begin
//end;//---//Funkcja UnBuild().

//Funkcja Train().
function TFann_Zaœlepka.Train( Input : array of single; Output: array of single ) : single;
begin
end;//---//Funkcja Train().

//Funkcja Run().
procedure TFann_Zaœlepka.Run( Inputs : array of single; var Outputs: array of single );
begin
end;//---//Funkcja Run().

////Funkcja SaveToFile().
//procedure TFann_Zaœlepka.SaveToFile( FileName : string );
//begin
//end;//---//Funkcja SaveToFile().

////Funkcja LoadFromFile().
//procedure TFann_Zaœlepka.LoadFromFile( Filename : string );
//begin
//end;//---//Funkcja LoadFromFile().


//      ***      Funkcje      ***      //

//Funkcja Komunikat_Wyœwietl().
function TPlanety_Form.Komunikat_Wyœwietl( const text_f, caption_f : string; const flags_f : integer ) : integer;
var
  czy_pauza : boolean;
begin

  czy_pauza := not GLCadencer1.Enabled;

  if not czy_pauza then
    Pauza_ButtonClick( nil );


  Result := Application.MessageBox( PChar(text_f), PChar(caption_f), flags_f );


  if not czy_pauza then
    Pauza_ButtonClick( nil );

end;//---//Funkcja Komunikat_Wyœwietl().

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

          // Sprawdza czy dla grupy spoza zakresu kolorów wylosowano ju¿ kolor.
          for i := 0 to Length( kolor_grupa_r_t ) - 1 do
            if kolor_grupa_r_t[ i ].id_grupa = id_grupa_f then
              begin

                Result := kolor_grupa_r_t[ i ].kolor_vector;
                Exit;

              end;
            //---//if kolor_grupa_r_t[ i ].id_grupa = id_grupa_f then
          //---// Sprawdza czy dla grupy spoza zakresu kolorów wylosowano ju¿ kolor.


          // Je¿eli pierwszy raz pojawi siê grupa spoza zakresu przygotowanych kolorów wylosuje dla niej nowy kolor.
          //Result := GLS.Color.clrGray80;
          Zero_GLSphere.Material.FrontProperties.Ambient.RandomColor(); // Kolory mog¹ byæ zbyt podobne. //???
          Result := Zero_GLSphere.Material.FrontProperties.Ambient.Color;

          i := Length( kolor_grupa_r_t );
          SetLength( kolor_grupa_r_t, i + 1 );

          kolor_grupa_r_t[ i ].id_grupa := id_grupa_f;
          kolor_grupa_r_t[ i ].kolor_vector := Result;
          //---// Je¿eli pierwszy raz pojawi siê grupa spoza zakresu przygotowanych kolorów wylosuje dla niej nowy kolor

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


  if GLS.Keyboard.IsKeyDown( VK_NUMPAD9 ) then // Góra.
    Gra_GLCamera.Lift( ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD3 ) then // Dó³.
    Gra_GLCamera.Lift( -ruch_c_l * delta_czasu_f );


  if GLS.Keyboard.IsKeyDown( VK_NUMPAD7 ) then // Beczka w lewo.
    Gra_GLCamera.Roll( ruch_c_l * delta_czasu_f * 10 );

  if GLS.Keyboard.IsKeyDown( VK_NUMPAD1 ) then // Beczka w prawo.
    Gra_GLCamera.Roll( -ruch_c_l * delta_czasu_f * 10 );

end;//---//Funkcja Kamera_Ruch().

//Funkcja Gra_Prêdkoœæ().
function TPlanety_Form.Gra_Prêdkoœæ() : real;
begin

  // Nie mo¿e zwracaæ zera.

  Result := Gra_Prêdkoœæ_SpinEdit.Value;

  if Result <= 0 then
    Result := 1;

  Result := Result * 0.01;

end;//---//Funkcja Gra_Prêdkoœæ().

//Funkcja Mapy_Wczytaj().
procedure TPlanety_Form.Mapy_Wczytaj();
var
  i : integer;
  zts : string;
  search_rec : TSearchRec;
begin

  //
  // Funkcja wczytuje listê schematów map.
  //


  Mapa_ComboBox.Items.Clear();

  zts := ExtractFilePath( Application.ExeName ) + 'Mapy\';

  // Je¿eli znajdzie plik zwraca 0, je¿eli nie znajdzie zwraca numer b³êdu. Na pocz¹tku znajduje '.' '..' potem listê plików.
  if FindFirst( zts + '*.xml', faAnyFile, search_rec ) = 0 then // Application potrzebuje w uses Forms.
    begin

      repeat //FindNext( search_rec ) <> 0;
        // Czasami bez begin i end nieprawid³owo rozpoznaje miejsca na umieszczenie breakpoint (linijkê za wysoko) w XE5.

        if    ( search_rec.Attr <> faDirectory )
          and ( search_rec.Name <> '.' )
          and ( search_rec.Name <> '..' ) then
          begin

            Mapa_ComboBox.Items.Add(  System.IOUtils.TPath.GetFileNameWithoutExtension( search_rec.Name )  );

          end;
        //---//if    ( search_rec.Attr <> faDirectory )


      until FindNext( search_rec ) <> 0; // Zwraca dane kolejnego pliku zgodnego z parametrami wczeœniej wywo³anej funkcji FindFirst. Je¿eli mo¿na przejœæ do nastêpnego znalezionego pliku zwraca 0.

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

//Funkcja Mapa_Utwórz().
function TPlanety_Form.Mapa_Utwórz() : boolean;

  //Funkcja Odczytaj_Liczbê_Z_Napisu() w Mapa_Utwórz().
  function Odczytaj_Liczbê_Z_Napisu( napis_f : string; const wartoœæ_minimalna_f : variant ) : real;
  begin

    //
    // Funkcja odczytuje liczbê z napisu.
    //
    // Zwraca odczytan¹ liczbê.
    //
    // Parametry:
    //   napis_f
    //   wartoœæ_minimalna_f - je¿eli jest ró¿na od null i wynik jest mniejszy od niej to zwraca t¹ wartoœæ.
    //   prze³¹cz_zak³adkê_f:
    //     false - nie prze³¹cza zak³adki.
    //     true - prze³¹cza zak³adkê.
    //

    napis_f := StringReplace( napis_f, '.', ',', [ rfReplaceAll ] );
    napis_f := Trim(  StringReplace( napis_f, ' ', '', [ rfReplaceAll ] )  );

    try
      Result := StrToFloat( napis_f );
    except
      on E : Exception do
        begin

          Result := 1;
          Komunikat_Wyœwietl( 'B³¹d odczytania liczby z napisu: ' + napis_f + '.' + #13 + E.Message + ' ' + IntToStr( E.HelpContext ) + #13 + #13 + #13 + 'Fehler beim Lesen der Zahl aus der Zeichenfolge.' + #13 + #13 + 'Error reading the number from the string.', 'B³¹d', MB_OK + MB_ICONEXCLAMATION  );

        end;
      //---//on E : Exception do
    end;
    //---//try

    if    ( wartoœæ_minimalna_f <> null )
      and ( Result < wartoœæ_minimalna_f ) then
      Result := wartoœæ_minimalna_f;

  end;//---//Funkcja Odczytaj_Liczbê_Z_Napisu() w Mapa_Utwórz().

var
  i,
  j,
  id_planeta_l
    : integer;
  zts : string;
  zt_xml_document : Xml.XMLDoc.TXMLDocument;
  zt_planeta : TPlaneta;
begin//Funkcja Mapa_Utwórz().

  //
  // Funkcja tworzy mapê.
  //

  Result := false;

  planety_iloœæ_mapa_g := 0;

  zts := ExtractFilePath( Application.ExeName ) + 'Mapy\' + Mapa_ComboBox.Text + '.xml';

  if not FileExists( zts ) then
    begin

      Komunikat_Wyœwietl( 'Nie odnaleziono pliku mapy:' + #13 + zts + '.' + #13 + #13 + #13 + 'Kartendatei nicht gefunden.' + #13 + #13 + 'Map file not found.', 'B³¹d', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if not FileExists( zts ) then


  zt_xml_document := Xml.XMLDoc.TXMLDocument.Create( Application );
  zt_xml_document.Options := zt_xml_document.Options + [ Xml.XMLIntf.doNodeAutoIndent ]; // Domyœlnie ma: doNodeAutoCreate, doAttrNull, doAutoPrefix, doNamespaceDecl.

  if zt_xml_document.Active then
    zt_xml_document.Active := false;

  try
    zt_xml_document.LoadFromFile( zts );
  except
    on E : Exception do
      Komunikat_Wyœwietl(  'Nieprawid³owa definicja mapy ' + zts + '.' + #13 + E.Message + ' ' + IntToStr( E.HelpContext ) + #13 + #13 + #13 + 'Ungültige Kartendefinition.' + #13 + #13 + 'Invalid map definition.', 'B³¹d', MB_OK + MB_ICONEXCLAMATION  );
  end;
  //---//try

  if zt_xml_document.Active then
    begin

      id_planeta_l := 0;
      GLS.VectorGeometry.SetVector( kamera_pozycja_pocz¹tkowa_g, 0, 0, 0 );

      for i := 0 to zt_xml_document.DocumentElement.ChildNodes.Count - 1 do
        begin

          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__x' then
            kamera_pozycja_pocz¹tkowa_g.X := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, null )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__y' then
            kamera_pozycja_pocz¹tkowa_g.Y := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, null )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'kamera_pozycja__z' then
            kamera_pozycja_pocz¹tkowa_g.Z := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].Text, 0.1 )
          else
          if zt_xml_document.DocumentElement.ChildNodes[ i ].LocalName = 'planeta' then
            begin

              zt_planeta := TPlaneta.Create();
              inc( id_planeta_l );
              zt_planeta.id_planeta := id_planeta_l;

              inc( planety_iloœæ_mapa_g );

              for j := 0 to zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes.Count - 1 do
                begin

                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'x' then
                    zt_planeta.Position.X := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, null )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'y' then
                    zt_planeta.Position.Y := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, null )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'skala' then
                    zt_planeta.planeta_kula_gl_sphere.Scale.Scale(  Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0.0001 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'id_grupa' then
                    zt_planeta.id_grupa := Round(  Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'iloœæ_pocz¹tkowa' then
                    zt_planeta.iloœæ_pocz¹tkowa_rakiet := Round(  Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'pojemnoœæ' then
                    zt_planeta.pojemnoœæ_rakiet := Round(  Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 )  )
                  else
                  if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'przyrost_szybkoœæ' then
                    zt_planeta.przyrost_szybkoœæ := Odczytaj_Liczbê_Z_Napisu( zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].Text, 0 );

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

              zt_planeta.pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Color := zt_planeta.planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;
              zt_planeta.pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.0;


              for j := 1 to zt_planeta.iloœæ_pocz¹tkowa_rakiet do
                Rakiety_Utwórz_Jeden( zt_planeta );

            end;
          //---//if zt_xml_document.DocumentElement.ChildNodes[ i ].ChildNodes[ j ].LocalName = 'planeta' then

        end;
      //---//for i := 0 to zt_xml_document.DocumentElement.ChildNodes.Count - 1 do

      Gra_GLCamera.Position.AsVector := kamera_pozycja_pocz¹tkowa_g;

    end;
  //---//if zt_xml_document.Active then

  zt_xml_document.Free();

  Statystyki_Tabela_Utwórz();

  Result := true;

  {$region 'Przyk³ad xml.'}
{
<mapa>
  <kamera_pozycja__x>0,0</kamera_pozycja__x>
  <kamera_pozycja__y>0,5</kamera_pozycja__y>
  <kamera_pozycja__z>0,0</kamera_pozycja__z>
      <!-- Wartoœci opcjonalne. -->

  <planeta>
    <x>0,0</x><!-- x = -10, y = 6 - lewo góra dla kamery x = 0,  y = 0, z = 5. -->
    <y>1,0</y>
    <skala>1,5</skala>

    <id_grupa>0</id_grupa><!-- 0 - neutralna. -->

    <iloœæ_pocz¹tkowa>0</iloœæ_pocz¹tkowa>
    <pojemnoœæ>2</pojemnoœæ>
    <przyrost_szybkoœæ>1,0</przyrost_szybkoœæ>
  </planeta>
</mapa>
}
  {$endregion 'Przyk³ad xml.'}

end;//---//Funkcja Mapa_Utwórz().

//Funkcja Mapa_Zwolnij().
procedure TPlanety_Form.Mapa_Zwolnij();
var
  i : integer;
begin

  planety_iloœæ_mapa_g := 0;

  Statystyki_Tabela_Czyœæ();


  ostatni_ruch_ponów__id_planeta_z__1 := '';
  ostatni_ruch_ponów__id_planeta_z__2 := '';
  ostatni_ruch_ponów__id_planeta_z__3 := '';
  ostatni_ruch_ponów__id_planeta_z__4 := '';

  ostatni_ruch_ponów__planeta_docelowa__1 := nil;
  ostatni_ruch_ponów__planeta_docelowa__2 := nil;
  ostatni_ruch_ponów__planeta_docelowa__3 := nil;
  ostatni_ruch_ponów__planeta_docelowa__4 := nil;


  for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Free();

end;//---//Funkcja Mapa_Zwolnij().

//Funkcja Rakiety_Utwórz_Jeden().
procedure TPlanety_Form.Rakiety_Utwórz_Jeden( planeta_f : TPlaneta );
var
  zt_rakieta : TRakieta;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  zt_rakieta := TRakieta.Create( planeta_f );

  rakiety_list.Add( zt_rakieta );

end;//---//Funkcja Rakiety_Utwórz_Jeden().

////Funkcja Rakiety_Zwolnij_Jeden().
//procedure TPlanety_Form.Rakiety_Zwolnij_Jeden( rakieta_f : TRakieta  );
//begin
//
//  // Usuwaæ tylko w jednym miejscu. !!!
//  // Wywo³anie tej funkcji w kliku miejscach mo¿e coœ zepsuæ.
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
procedure TPlanety_Form.Rakiety_Cel_Ustaw( const id_grupa_f : integer; id_planeta_z_s_f : string; planeta_docelowa_f : TPlaneta; rakiety_iloœæ_procent_wys³anie_f : real = -1 );
type
  TPlaneta_Iloœæ_Rakiet_r_l = record
    id_planeta,
    rakiety_iloœæ
      : integer;
  end;
var
  i,
  j,
  zti
    : integer;
  zt_vector : GLS.VectorTypes.TVector4f;

  planeta_iloœæ_rakiet_r_l_t : array of TPlaneta_Iloœæ_Rakiet_r_l;
begin

  // Parametry:
  //   id_grupa_f - grupa, której rakiet dotyczy polecenie.
  //   id_planeta_z_s_f - id planet, z których wys³aæ rakiety w postaci '-99, 1, 2, 3'.
  //   planeta_docelowa_f
  //   rakiety_iloœæ_procent_wys³anie_f:
  //     < 0 - u¿ywa wartoœci ustawionej w komponencie Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.
  //     >= 0 - u¿ywa wartoœci przekazanej do funkcji.

  id_planeta_z_s_f := ', ' + id_planeta_z_s_f + ',';

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  )
    or ( planeta_docelowa_f = nil ) then
    Exit;


  if id_grupa_f = id_grupa_gracza_c then
    inc( statystyki__polecenia_iloœæ__misja );


  if    ( Decyzje_Gracza_Zapamiêtuj_CheckBox.Checked )
    and ( id_grupa_f = id_grupa_gracza_c ) then
    SI_Decyduj( id_grupa_gracza_c, planeta_docelowa_f.id_planeta );


  if rakiety_iloœæ_procent_wys³anie_f < 0 then
    rakiety_iloœæ_procent_wys³anie_f := Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value * 0.01
  else//if rakiety_iloœæ_procent_wys³anie_f < 0 then
    rakiety_iloœæ_procent_wys³anie_f := rakiety_iloœæ_procent_wys³anie_f * 0.01;


  // Zlicza ile jest rakiet na orbitach poszczególnych planet i ile rakiet wys³aæ (iloœæ dzielona na 2 zaokr¹glana w dó³).
  SetLength( planeta_iloœæ_rakiet_r_l_t, 0 );

  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        zti := Length( planeta_iloœæ_rakiet_r_l_t );
        SetLength( planeta_iloœæ_rakiet_r_l_t, zti + 1 );

        planeta_iloœæ_rakiet_r_l_t[ zti ].id_planeta := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta;
        planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ := 0;

        for j := 0 to TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
          if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
            inc( planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ );

         //planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ := Ceil( planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ * 0.5 );

         if planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ > 1 then
          planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ := System.Math.Floor( planeta_iloœæ_rakiet_r_l_t[ zti ].rakiety_iloœæ * rakiety_iloœæ_procent_wys³anie_f );

      end;
    //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
  //---// Zlicza ile jest rakiet na orbitach poszczególnych planet i ile rakiet wys³aæ (iloœæ dzielona na 2 zaokr¹glana w dó³).


  for i := 0 to rakiety_list.Count - 1 do
    begin

      if    ( TRakieta(rakiety_list[ i ]).id_grupa = id_grupa_f )
        and ( TRakieta(rakiety_list[ i ]).Parent <> nil )
        and ( TRakieta(rakiety_list[ i ]).Parent.Parent <> nil )
        and ( TRakieta(rakiety_list[ i ]).Parent.Parent is TPlaneta )
        and ( TRakieta(rakiety_list[ i ]).planeta_docelowa = nil )
        and ( TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta <> planeta_docelowa_f.id_planeta ) // Planeta docelowa powinna byæ inna ni¿ planeta, na której orbicie znajduje siê rakieta.
        and (  Pos(  ', ' + IntToStr( TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta ) + ',', id_planeta_z_s_f  ) > 0  ) then
        begin

          // Po wys³aniu rakiety zmniejsza iloœæ rakiet pozosta³ych do wys³ania.
          for j := 0 to Length( planeta_iloœæ_rakiet_r_l_t ) - 1 do
            if    ( planeta_iloœæ_rakiet_r_l_t[ j ].id_planeta = TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta )
              and ( planeta_iloœæ_rakiet_r_l_t[ j ].rakiety_iloœæ > 0 ) then
              begin

                TRakieta(rakiety_list[ i ]).planeta_docelowa := planeta_docelowa_f;
                TRakieta(rakiety_list[ i ]).id_planeta := -1;


                Wspó³rzêdne_Test_GLDummyCube.Parent := planeta_docelowa_f.losowy_obrót_gl_dummy_cube;
                Wspó³rzêdne_Test_GLDummyCube.Position.X := TRakieta(rakiety_list[ i ]).Orbita_Odleg³oœæ_Ustaw( planeta_docelowa_f );
                planeta_docelowa_f.losowy_obrót_gl_dummy_cube.Roll(  Random( 361 )  );
                //planeta_docelowa_f.losowy_obrót_gl_dummy_cube.Roll( 5 );
                zt_vector := Wspó³rzêdne_Test_GLDummyCube.AbsolutePosition;
                Wspó³rzêdne_Test_GLDummyCube.Parent := Gra_GLScene.Objects;
                TRakieta(rakiety_list[ i ]).planeta_docelowa_wspó³rzêdne_na_orbicie := Wspó³rzêdne_Test_GLDummyCube.Parent.AbsoluteToLocal( zt_vector );


                zt_vector := TRakieta(rakiety_list[ i ]).AbsolutePosition;
                TRakieta(rakiety_list[ i ]).Parent := Gra_Obiekty_GLDummyCube;
                TRakieta(rakiety_list[ i ]).Position.AsVector := TRakieta(rakiety_list[ i ]).Parent.AbsoluteToLocal( zt_vector );

                dec( planeta_iloœæ_rakiet_r_l_t[ j ].rakiety_iloœæ );

              end;
            //---//if    ( planeta_iloœæ_rakiet_r_l_t[ j ].id_planeta = TPlaneta(TRakieta(rakiety_list[ i ]).Parent.Parent).id_planeta ) (...)

        end;
      //---//if    ( if    ( TRakieta(rakiety_list[ i ]).id_grupa = id_grupa_f ) (...)

    end;
  //---//for i := 0 to rakiety_list.Count - 1 do


  SetLength( planeta_iloœæ_rakiet_r_l_t, 0 );

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
        //  (   // Cel                 Obiekt celuj¹cy
        //      TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.X - TRakieta(rakiety_list[ i ]).Position.X
        //    , TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.Y - TRakieta(rakiety_list[ i ]).Position.Y
        //    , TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.Z - TRakieta(rakiety_list[ i ]).Position.Z
        //  );

        TRakieta(rakiety_list[ i ]).Direction.SetVector
          (   // Cel                 Obiekt celuj¹cy
              TRakieta(rakiety_list[ i ]).planeta_docelowa_wspó³rzêdne_na_orbicie.X - TRakieta(rakiety_list[ i ]).Position.X
            , TRakieta(rakiety_list[ i ]).planeta_docelowa_wspó³rzêdne_na_orbicie.Y - TRakieta(rakiety_list[ i ]).Position.Y
            , TRakieta(rakiety_list[ i ]).planeta_docelowa_wspó³rzêdne_na_orbicie.Z - TRakieta(rakiety_list[ i ]).Position.Z
          );

        TRakieta(rakiety_list[ i ]).Move( rakieta_prêdkoœæ_c * delta_czasu_f * Gra_Prêdkoœæ() );

        //if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.AsVector ) < TRakieta(rakiety_list[ i ]).Orbita_Odleg³oœæ_Ustaw( TRakieta(rakiety_list[ i ]).planeta_docelowa ) then
        if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa_wspó³rzêdne_na_orbicie ) < TRakieta(rakiety_list[ i ]).kad³ub_gl_cone.Scale.X then
          begin

            zt_vector := TRakieta(rakiety_list[ i ]).AbsolutePosition;
            TRakieta(rakiety_list[ i ]).Parent := TRakieta(rakiety_list[ i ]).planeta_docelowa.orbita_dla_rakiet_gl_dummy_cube;
            TRakieta(rakiety_list[ i ]).Position.AsVector := TRakieta(rakiety_list[ i ]).Parent.AbsoluteToLocal( zt_vector );

            TRakieta(rakiety_list[ i ]).id_planeta := TRakieta(rakiety_list[ i ]).planeta_docelowa.id_planeta;

            TRakieta(rakiety_list[ i ]).planeta_docelowa := nil;

            TRakieta(rakiety_list[ i ]).Orbita_Kierunek_Ustaw();

          end;
        //---//if TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ i ]).planeta_docelowa.Position.AsVector ) < TRakieta(rakiety_list[ i ]).Orbita_Odleg³oœæ_Ustaw( TRakieta(rakiety_list[ i ]).planeta_docelowa ) then

      end;
    //---//if TRakieta(rakiety_list[ i ]).planeta_docelowa <> nil then

end;//---//Funkcja Rakiety_Lot_Do_Celu().

//Funkcja Walka_Efekt_Utwórz_Jeden().
procedure TPlanety_Form.Walka_Efekt_Utwórz_Jeden( pozycja_rakieta_f : GLS.VectorTypes.TVector4f; const id_grupa_f : integer );
var
  zt_walka_efekt : TWalka_Efekt;
begin

  if   ( walka_efekt_list = nil )
    or (  not Assigned( walka_efekt_list )  ) then
    Exit;


  zt_walka_efekt := TWalka_Efekt.Create( pozycja_rakieta_f, id_grupa_f );

  walka_efekt_list.Add( zt_walka_efekt );

end;//---//Funkcja Walka_Efekt_Utwórz_Jeden().

//Funkcja Walka_Efekt_Zwolnij_Jeden().
procedure TPlanety_Form.Walka_Efekt_Zwolnij_Jeden( walka_efekt_f : TWalka_Efekt  );
begin

  // Usuwaæ tylko w jednym miejscu. !!!
  // Wywo³anie tej funkcji w kliku miejscach mo¿e coœ zepsuæ.

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
procedure TPlanety_Form.Orbita_Rakiety_Zwalczanie( const poza_orbit¹_tylko_f : boolean );
var
  i,
  j
    : integer;
begin

  //
  // Funkcja je¿eli rakiety s¹ na orbicie tej samej planety i nale¿¹ do innych grup to w wyniku walki zostaj¹ zniszczone
  // (jedna rakieta zwalcza jedn¹ rakietê i obie znikaj¹).
  //
  // Parametry:
  //   poza_orbit¹_tylko_f:
  //     false - przelicza walki wszystkich rakiet.
  //     true - przelicza tylko walki rakiet nie bêd¹cych na orbitach planet.
  //

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  for i := 0 to rakiety_list.Count - 1 do
    if not TRakieta(rakiety_list[ i ]).czy_usun¹æ then
      for j := i + 1 to rakiety_list.Count - 1 do
        if    ( not TRakieta(rakiety_list[ i ]).czy_usun¹æ ) // Ten warunek mo¿na pomin¹æ, gdy¿ jest powtórzony wy¿ej.
          and ( not TRakieta(rakiety_list[ j ]).czy_usun¹æ )
          and ( TRakieta(rakiety_list[ i ]).id_grupa <> TRakieta(rakiety_list[ j ]).id_grupa )
          and (
                   ( not poza_orbit¹_tylko_f )
                or (
                         ( poza_orbit¹_tylko_f )
                     and ( TRakieta(rakiety_list[ i ]).id_planeta = -1 ) // Rakiety poza orbit¹.
                     and ( TRakieta(rakiety_list[ j ]).id_planeta = -1 ) // Rakiety poza orbit¹.
                   )
              )
          //and ( TRakieta(rakiety_list[ i ]).id_planeta <> -1 )
          //and ( TRakieta(rakiety_list[ j ]).id_planeta <> -1 ) // Rakieta poza orbit¹.
          and (
                   ( // Rakiety na orbicie.
                         ( TRakieta(rakiety_list[ i ]).id_planeta <> -1 )
                     and ( TRakieta(rakiety_list[ j ]).id_planeta <> -1 )
                     and (  Random( 11 ) > 9  ) // Aby rakiety nie zwalcza³y siê wszystkie w jednym momencie.
                   )
                or ( // Rakieta poza orbit¹ ale przelatuj¹ blisko siebie.
                         ( TRakieta(rakiety_list[ i ]).id_planeta = -1 )
                     and ( TRakieta(rakiety_list[ j ]).id_planeta = -1 )
                     and (  TRakieta(rakiety_list[ i ]).DistanceTo( TRakieta(rakiety_list[ j ]) ) <  0.25  )
                   )
              )
          and ( TRakieta(rakiety_list[ i ]).id_planeta = TRakieta(rakiety_list[ j ]).id_planeta ) then
          begin

            Walka_Efekt_Utwórz_Jeden( TRakieta(rakiety_list[ i ]).AbsolutePosition, TRakieta(rakiety_list[ i ]).id_grupa );
            Walka_Efekt_Utwórz_Jeden( TRakieta(rakiety_list[ j ]).AbsolutePosition, TRakieta(rakiety_list[ j ]).id_grupa );

            TRakieta(rakiety_list[ i ]).czy_usun¹æ := true;
            TRakieta(rakiety_list[ j ]).czy_usun¹æ := true;

            Break;

          end;
        //---//if    ( TRakieta(rakiety_list[ i ]).czy_usun¹æ = false ) (...)


  for i := rakiety_list.Count - 1 downto 0 do
    if TRakieta(rakiety_list[ i ]).czy_usun¹æ then
      begin

        TRakieta(rakiety_list[ i ]).Free();
        rakiety_list.Delete( i );

      end;
    //---//if TRakieta(rakiety_list[ i ]).czy_usun¹æ then

end;//---//Funkcja Orbita_Rakiety_Zwalczanie().

//Funkcja Planety_Przejmowanie_Przeliczaj().
procedure TPlanety_Form.Planety_Przejmowanie_Przeliczaj();
var
  obecnoœæ_grupy_trzeciej : boolean; // Je¿eli na orbicie planety s¹ wiêcej ni¿ dwie ró¿ne grupy rakiet przejmowanie nie nastêpuje.
  i,
  j,
  id_grupa_obca,
  rakiety_iloœæ__grupa_planety,
  rakiety_iloœæ__grupa_obca
    : integer;
  ztr : real;
  zts,
  id_grupa_zmiana_planety_si_przelicz // Id grup, które w danym przeliczaniu przejê³y albo straci³y planety. Po przejêciu albo straceniu planety dana grupa SI zyskuje dodatkowe przeliczenie SI.
    : string;
begin

  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  id_grupa_zmiana_planety_si_przelicz := '-99';


  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        obecnoœæ_grupy_trzeciej := false;
        id_grupa_obca := -1;
        rakiety_iloœæ__grupa_planety := 0;
        rakiety_iloœæ__grupa_obca := 0;


        {$region 'Wariant 1.'}
        //for j := 0 to TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Count - 1 do
        //  if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
        //    begin
        //
        //      if TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa = TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa then
        //        inc( rakiety_iloœæ__grupa_planety );
        //
        //      if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
        //        and ( id_grupa_obca = -1 ) then
        //        id_grupa_obca := TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa;
        //
        //      if TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa = id_grupa_obca then
        //        inc( rakiety_iloœæ__grupa_obca );
        //
        //      if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa )
        //        and ( id_grupa_obca <> -1 )
        //        and ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> id_grupa_obca ) then
        //        begin
        //
        //          obecnoœæ_grupy_trzeciej := true;
        //          Break;
        //
        //        end;
        //      //---//if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) (...)
        //
        //    end;
        //  //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then
        {$endregion 'Wariant 1.'}


        rakiety_iloœæ__grupa_planety := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );
        rakiety_iloœæ__grupa_obca := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ() - rakiety_iloœæ__grupa_planety;

        if rakiety_iloœæ__grupa_obca > 0 then
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

                      obecnoœæ_grupy_trzeciej := true;
                      Break;

                    end;
                  //---//if    ( TRakieta(TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ]).id_grupa <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) (...)

                end;
              //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Children[ j ] is TRakieta then

          end;
        //---//if rakiety_iloœæ__grupa_obca > 0 then


        ztr := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X; // Im wiêksza planeta tym d³u¿ej trwa zdobywanie.

        if ztr = 0 then
          ztr := 1;

        ztr := ztr * 3;


        if not obecnoœæ_grupy_trzeciej then
          begin

            if rakiety_iloœæ__grupa_planety <= 0 then
              begin

                // Tracenie planety.

                if rakiety_iloœæ__grupa_obca > 0 then
                  begin

                    //TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                    //    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                    //  - rakiety_iloœæ__grupa_obca / ztr;

                    ztr := rakiety_iloœæ__grupa_obca / ztr;


                    if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_neutralna_c )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj¹ca_planetê <> id_grupa_obca ) then
                      begin

                        if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > id_grupa_neutralna_c then
                          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj¹ca_planetê := id_grupa_obca
                        else//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > id_grupa_neutralna_c then
                          ztr := -ztr; // Je¿eli inna grupa zaczyna zdobywaæ planetê musi zneutralizowaæ poziom zdobycia poprzedniej zdobywaj¹cej grupy.

                      end;
                    //---//if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_neutralna_c ) (...)


                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                      - ztr;


                    if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= 0 )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_neutralna_c ) then
                      begin

                        // Grupa posiadaj¹ca dotychczas planetê traci j¹.

                        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_gracza_c )
                          and (  Pos( ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) + ',', id_grupa_zmiana_planety_si_przelicz + ',' ) <= 0  ) then
                          id_grupa_zmiana_planety_si_przelicz := id_grupa_zmiana_planety_si_przelicz +
                            ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );


                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa := id_grupa_neutralna_c;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj¹ca_planetê := id_grupa_obca;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color := Kolor_Grupa_Ustaw( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa );

                        //if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona then
                        //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );

                      end;
                    //---//if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= 0 ) (...)

                    if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny <= -100 then
                      begin

                        // Inna grupa zdobywa planetê.

                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa := id_grupa_obca;
                        TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj¹ca_planetê := id_grupa_neutralna_c;
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


                    // Dostosowuje wygl¹d planety.
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
                            Kolor_Grupa_Ustaw( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa_zdobywaj¹ca_planetê ),
                            Abs( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny ) * 0.01
                          );

                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.LowAtmColor.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color;

                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color;
                    TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.0;
                    //---// Dostosowuje wygl¹d planety.

                  end;
                //---//if rakiety_iloœæ__grupa_obca > 0 then

              end
            else//if rakiety_iloœæ__grupa_planety <= 0 then
            if    ( rakiety_iloœæ__grupa_obca <= 0 )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny < 100 ) then
              begin

                // Odzyskiwanie planety.

                if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny < 100 then
                  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny :=
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny
                    + rakiety_iloœæ__grupa_planety / ztr;

                if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny > 100 then
                  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny := 100;


                // Dostosowuje wygl¹d planety.
                TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color :=
                  VectorScale
                    (
                      TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Material.FrontProperties.Diffuse.Color,
                      Abs( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przejmowanie_poziom_aktualny ) * 0.01
                    );

                TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.LowAtmColor.Color := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).atmosfera_gl_atmosphere.HighAtmColor.Color;
                //---// Dostosowuje wygl¹d planety.

              end;
            //---//if    ( rakiety_iloœæ__grupa_obca <= 0 ) (...)

          end;
        //---//if not obecnoœæ_grupy_trzeciej then


        // Wizualizacja zaznaczenie planety.
        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_gracza_c )
          //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ( id_grupa_gracza_c ) <= id_grupa_neutralna_c ) then
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ( id_grupa_gracza_c ) <= id_grupa_neutralna_c ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );


        if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible )
          or ( Zajêtoœæ_Orbity_Wizualizuj_CheckBox.Checked ) then
          begin

            if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
              or ( Zajêtoœæ_Orbity_Wizualizuj_CheckBox.Checked ) then
              begin

                ztr := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ( id_grupa_gracza_c );

                if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemnoœæ_rakiet = 0 )
                  or ( ztr >= TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemnoœæ_rakiet ) then
                  ztr := 100
                else//if ztr >= TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemnoœæ_rakiet then
                  ztr := 100 * ztr / TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemnoœæ_rakiet;

              end;
            //---//if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c ) (...)


            // Buduje napis opisuj¹cy planetê.
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
                    Trim(  FormatFloat( '### ### ##0', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pojemnoœæ_rakiet )  ) + '; przyr. ' +
                    Trim(  FormatFloat( '### ### ##0.00', TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybkoœæ )  ) + ')';

              end;
            //---//if TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible then
            //---// Buduje napis opisuj¹cy planetê.


            // Wizualizacja zajêtoœci orbity planety przez rakiety.
            //if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
            //  and ( Zajêtoœæ_Orbity_Wizualizuj_CheckBox.Checked ) then
            //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := ztr * 0.005;

            if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa = id_grupa_gracza_c )
              and ( Zajêtoœæ_Orbity_Wizualizuj_CheckBox.Checked ) then
              //if ztr >= 100 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.25
              //else//if ztr >= 100 then
              //if ztr >= 90 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.125
              //else//if ztr >= 90 then
              //if ztr >= 80 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.06
              //else//if ztr >= 80 then
              //  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0;
              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0.75 * ztr * 0.01;
            //---// Wizualizacja zajêtoœci orbity planety przez rakiety.

          end;
        //---//if   ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).opis_gl_space_text.Visible ) (...)


        // Wizualizacja zajêtoœci orbity planety przez rakiety.
        if    ( not Zajêtoœæ_Orbity_Wizualizuj_CheckBox.Checked )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha <> 0 ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).pierœcieñ_gl_torus.Material.FrontProperties.Diffuse.Alpha := 0;

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
  decyzje_gracza_zapamiêtuj_obliczenia : boolean; // Obliczenia s¹ przeprowadzane tylko dla potrzeb zapamiêtania konfiguracji mapy gdy gracz wykonywa³ ruch.

  //Funkcja SI_Planeta_Decyduj() w SI_Decyduj().
  procedure SI_Planeta_Decyduj( const planeta_f : TPlaneta; const œrodek_geometryczny_planet_w_grupie_f : GLS.VectorTypes.TVector4f; const planety_posiadane_procent_f : real; const fann_decyduje_f : boolean; const rakiety_iloœæ_w_grupie_f : integer = -1; id_planeta_z_s_f : string = '' );
  type
    TSI_Decyzja_r = record
      id_grupa,
      id_grupa_zdobywaj¹ca_planetê,
      id_planeta,
      rakiety_na_orbicie_iloœæ__obce,
      rakiety_na_orbicie_iloœæ__w³asne
        : integer;

      decyzja_wspó³czynnik,
      odleg³oœæ,
      przejmowanie_poziom_aktualny,
      przyrost_szybkoœæ,
      wielkoœæ
        : real;

      planeta_docelowa : TPlaneta
    end;
    //---//TSI_Decyzja_r

  var
    przeliczanie_grupy : boolean; // false - gdy przelicza niezale¿ne dla ka¿dej planety osobno, true - gdy przelicza dla ca³ej grupy a nie pojedynczej planety.

    i_l,
    zti_l,
    decyzja_wspó³czynnik__indeks_tabeli, // Indeks tabeli decyzyjnej, w którym jest wybrany wspó³czynnik decyzyjny.
    decyzja_wspó³czynnik__indeks_tabeli__fann
      : integer;

    ztr_l,
    decyzja_wspó³czynnik__najwiêkszy, // Wartoœæ decyzji najlepiej ocenionej.
    decyzja_wspó³czynnik__najwiêkszy__fann,
    modyfikator_losowy__planety_neutralnej,
    modyfikator_losowy__wielkoœæ,
    rakiety_iloœæ_procent_wys³anie__fann,
    rakiety_na_orbicie_iloœæ, // Na orbicie planety, z której wysy³aæ rakiety.
    rakiety_w_bitwie
      : real;

    wejœcia : array [ 0..9 ] of single;
    wyjœcia : array [ 0..1 ] of single;

    si_decyzja_r_t : array of TSI_Decyzja_r;
  begin//Funkcja SI_Planeta_Decyduj() w SI_Decyduj().

    if planeta_f = nil then
      Exit;


    przeliczanie_grupy :=
         ( rakiety_iloœæ_w_grupie_f > -1 )
      or ( decyzje_gracza_zapamiêtuj_obliczenia ); //???


    // Nie wysy³a rakiet z atakowanej planety.
    if not przeliczanie_grupy then
      if planeta_f.przejmowanie_poziom_aktualny < 100 then //???
        Exit;


    if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_próg_c then
      begin

        if Random( 2 ) = 1 then
          modyfikator_losowy__planety_neutralnej := 0.5
        else//if Random( 3 ) = 2 then
          modyfikator_losowy__planety_neutralnej := 0;

      end
    else//if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_próg_c then
      begin

        if Random( 2 ) = 1 then
          modyfikator_losowy__planety_neutralnej := 0.5
        else//if Random( 3 ) = 2 then
          modyfikator_losowy__planety_neutralnej := 1;

      end;
    //---//if planety_posiadane_procent_f > si_decyduj__planety_posiadane_procent_próg_c then



    if Random( 5 ) >= 0 then
      modyfikator_losowy__wielkoœæ := 0.1
    else//if Random( 5 ) >= 0 then
      modyfikator_losowy__wielkoœæ := 1;


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
          si_decyzja_r_t[ zti_l ].id_grupa_zdobywaj¹ca_planetê := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_grupa_zdobywaj¹ca_planetê;
          si_decyzja_r_t[ zti_l ].id_planeta := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).id_planeta;
          //si_decyzja_r_t[ zti_l ].odleg³oœæ := 100 * planeta_f.DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]) ) / si__odleg³oœæ_najwiêksza_miêdzy_planetami_g;
          si_decyzja_r_t[ zti_l ].planeta_docelowa := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]);
          si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).przejmowanie_poziom_aktualny;
          si_decyzja_r_t[ zti_l ].przyrost_szybkoœæ := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).przyrost_szybkoœæ / si__przyrost_szybkoœæ_planety_najwiêkszy_g;
          si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__w³asne := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).Rakiety_Na_Orbicie_Iloœæ( planeta_f.id_grupa );
          si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__obce := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).Rakiety_Na_Orbicie_Iloœæ() - si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__w³asne;

          if si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__obce < 0 then
            si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__obce := 0;


          if not przeliczanie_grupy then
            begin

              id_planeta_z_s_f := IntToStr( planeta_f.id_planeta );
              si_decyzja_r_t[ zti_l ].odleg³oœæ := 100 * planeta_f.DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]) ) / si__odleg³oœæ_najwiêksza_miêdzy_planetami_g;

            end
          else//if not przeliczanie_grupy then
            begin

              si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__w³asne := rakiety_iloœæ_w_grupie_f;
              si_decyzja_r_t[ zti_l ].odleg³oœæ := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).DistanceTo( œrodek_geometryczny_planet_w_grupie_f ) / si__odleg³oœæ_najwiêksza_miêdzy_planetami_g;

            end;
          //---//if not przeliczanie_grupy then


          si_decyzja_r_t[ zti_l ].wielkoœæ := 100 * TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i_l ]).planeta_kula_gl_sphere.Scale.X / si__wielkoœæ_planety_najwiêksza_g;


          si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik :=
              ( 100 - si_decyzja_r_t[ zti_l ].wielkoœæ ) * 0.5 * modyfikator_losowy__wielkoœæ // Im mniejsza tym lepiej.
            + ( 100 - si_decyzja_r_t[ zti_l ].odleg³oœæ ); // Im mniejsza tym lepiej.


          // Odzyskiwanie w³asnych planet.
          if    ( si_decyzja_r_t[ zti_l ].id_grupa = planeta_f.id_grupa )
            and ( si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny < 100 ) then
            si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
              + ( 100 - si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny ) * 2;

          // Wspiera zdobycie planety.
          if si_decyzja_r_t[ zti_l ].id_grupa_zdobywaj¹ca_planetê = planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
              + Abs( si_decyzja_r_t[ zti_l ].przejmowanie_poziom_aktualny );


          if not przeliczanie_grupy then
            rakiety_na_orbicie_iloœæ := planeta_f.Rakiety_Na_Orbicie_Iloœæ( planeta_f.id_grupa )
          else//if not przeliczanie_grupy then
            rakiety_na_orbicie_iloœæ := rakiety_iloœæ_w_grupie_f;

          // Stosunek rakiet tej samej grupy na orbicie analizowanej planety wraz z rakietami na orbicie planety, z której rakiety mog¹ byæ wys³ane do rakiet wrogich na orbicie analizowanej planety.
          rakiety_w_bitwie := rakiety_na_orbicie_iloœæ + si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__w³asne + si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__obce;

          if rakiety_w_bitwie > 0 then
            begin

              ztr_l := 100 * ( si_decyzja_r_t[ zti_l ].rakiety_na_orbicie_iloœæ__w³asne + rakiety_na_orbicie_iloœæ ) / rakiety_w_bitwie;

              // Je¿eli przewaga rakiet grupy wynosi ponad 50% dodaje do decyzji nadwy¿kê procentu ponad 50.
              if ztr_l > 50 then
                si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
                  + ztr_l - 50;

            end;
          //---//rakiety_w_bitwie
          //---// Stosunek rakiet tej samej grupy na orbicie analizowanej planety wraz z rakietami na orbicie planety, z której rakiety mog¹ byæ wys³ane do rakiet wrogich na orbicie analizowanej planety.


          if not przeliczanie_grupy then
            begin

              // Wspó³czynnik zape³nienia planety. //???
              if planeta_f.pojemnoœæ_rakiet <> 0 then
                ztr_l := 100 * rakiety_na_orbicie_iloœæ / planeta_f.pojemnoœæ_rakiet
              else//if planeta_f.pojemnoœæ_rakiet <> 0 then
                ztr_l := 0;


              // Je¿eli zape³nienia planety wynosi ponad 50% dodaje do decyzji nadwy¿kê procentu ponad 50.
              if ztr_l >= 50 then
                si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
                  + ztr_l - 50;
              //---// Wspó³czynnik zape³nienia planety.

            end;
          //---//if not przeliczanie_grupy then


          // Preferowane do wys³ania rakiet s¹ planety neutralne, potem planety przeciwników, na koñcu w³asne.
          if si_decyzja_r_t[ zti_l ].id_grupa = id_grupa_neutralna_c then
            si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
              + 100 * modyfikator_losowy__planety_neutralnej
          else
          if si_decyzja_r_t[ zti_l ].id_grupa <> planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
              + 50
          else
          if si_decyzja_r_t[ zti_l ].id_grupa = planeta_f.id_grupa then
            si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik := si_decyzja_r_t[ zti_l ].decyzja_wspó³czynnik
              - 50;
          //---// Preferowane do wys³ania rakiet s¹ planety neutralne, potem planety przeciwników, na koñcu w³asne.

        end;
      //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i_l ] is TPlaneta ) (...)


    if not decyzje_gracza_zapamiêtuj_obliczenia then
      begin

        if SI_Loguj_CheckBox.Checked then
          begin

            SI_Log_Memo.Lines.Add( '' );
            SI_Log_Memo.Lines.Add( '' );

            if przeliczanie_grupy then
              begin

                SI_Log_Memo.Lines.Add(   'Z id ' + Trim(  FormatFloat( '### ### ##0', planeta_f.id_planeta )  ) + ', planety posiadane procent ' + Trim(  FormatFloat( '### ### ##0', planety_posiadane_procent_f )  ) + ' (próg ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__planety_posiadane_procent_próg_c )  ) + ')'   );
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


        decyzja_wspó³czynnik__indeks_tabeli := -99;
        decyzja_wspó³czynnik__indeks_tabeli__fann := -99;
        rakiety_iloœæ_procent_wys³anie__fann := 100;


        for i_l := 0 to Length( si_decyzja_r_t ) - 1 do
          begin

            if   ( not fann_decyduje_f )
              or ( fann_network = nil ) then
              begin

                if   ( i_l = 0 ) // Pierwsze podstawienie wartoœci.
                  or (
                           ( i_l > 0 )
                       and ( decyzja_wspó³czynnik__najwiêkszy < si_decyzja_r_t[ i_l ].decyzja_wspó³czynnik )
                     ) then
                  begin

                    decyzja_wspó³czynnik__indeks_tabeli := i_l;
                    decyzja_wspó³czynnik__najwiêkszy := si_decyzja_r_t[ i_l ].decyzja_wspó³czynnik;

                  end;
                //---//if   ( i_l = 0 ) (...)


                if SI_Loguj_CheckBox.Checked then
                  begin

                    SI_Log_Memo.Lines.Add( '' );
                    SI_Log_Memo.Lines.Add(   'id ' + Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_planeta )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].decyzja_wspó³czynnik )  )   );

                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_grupa )  ) + ' id_grupa'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_grupa_zdobywaj¹ca_planetê )  ) + ' id_grupa_zdobywaj¹ca_planetê'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].odleg³oœæ )  ) + ' odleg³oœæ'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny )  ) + ' przejmowanie_poziom_aktualny'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].przyrost_szybkoœæ )  ) + ' przyrost_szybkoœæ'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__obce )  ) + ' rakiety_na_orbicie_iloœæ__obce'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__w³asne )  ) + ' rakiety_na_orbicie_iloœæ__w³asne'   );
                    SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.00', si_decyzja_r_t[ i_l ].wielkoœæ )  ) + ' wielkoœæ'   );

                  end;
                //---//if SI_Loguj_CheckBox.Checked then

              end
            else//if   ( not fann_decyduje_f ) (...)
              begin

                if fann_network <> nil then
                  begin

                    if si_decyzja_r_t[ i_l ].id_grupa = planeta_f.id_grupa then // planeta nale¿y do gracza (0 - nie, 1 - tak).
                      wejœcia[ 0 ] := 1
                    else//if si_decyzja_r_t[ i_l ].id_grupa = planeta_f.id_grupa then
                      wejœcia[ 0 ] := 0;

                    if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj¹ca_planetê = 0 then // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planetê, 2 - planetê zdobywa grupa nie gracza).
                      wejœcia[ 1 ] := 0
                    else
                    if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj¹ca_planetê = id_grupa_gracza_c then
                      wejœcia[ 1 ] := 1
                    else
                      wejœcia[ 1 ] := 2;

                    wejœcia[ 2 ] := si_decyzja_r_t[ i_l ].odleg³oœæ;
                    wejœcia[ 3 ] := planety_iloœæ_mapa_g;
                    wejœcia[ 4 ] := planety_posiadane_procent_f;
                    wejœcia[ 5 ] := si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny;
                    wejœcia[ 6 ] := si_decyzja_r_t[ i_l ].przyrost_szybkoœæ;
                    wejœcia[ 7 ] := si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__obce;
                    wejœcia[ 8 ] := si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__w³asne;
                    wejœcia[ 9 ] := si_decyzja_r_t[ i_l ].wielkoœæ;

                    fann_network.Run( wejœcia, wyjœcia );


                    if   ( i_l = 0 ) // Pierwsze podstawienie wartoœci.
                      or (
                               ( i_l > 0 )
                           and ( decyzja_wspó³czynnik__najwiêkszy__fann < wyjœcia[ 0 ] )
                         ) then
                      begin

                        decyzja_wspó³czynnik__indeks_tabeli__fann := i_l;
                        decyzja_wspó³czynnik__najwiêkszy__fann := wyjœcia[ 0 ];
                        rakiety_iloœæ_procent_wys³anie__fann := wyjœcia[ 1 ];

                        // Po nauczaniu wychodz¹ mi jakieœ bardzo ma³e u³amkowe wartoœci.
                        //if rakiety_iloœæ_procent_wys³anie__fann < 0 then
                        //  rakiety_iloœæ_procent_wys³anie__fann := 0; //???

                        if rakiety_iloœæ_procent_wys³anie__fann < 10 then //???
                          rakiety_iloœæ_procent_wys³anie__fann := 100; //???

                      end;
                    //---//if   ( i_l = 0 ) (...)


                    if SI_Loguj_CheckBox.Checked then
                      begin

                        SI_Log_Memo.Lines.Add(   'SI id ' + Trim(  FormatFloat( '### ### ##0', si_decyzja_r_t[ i_l ].id_planeta )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.0000', wyjœcia[ 0 ] )  ) + '; ' + Trim(  FormatFloat( '### ### ##0.0000', wyjœcia[ 1 ] ) + '%'  )   );

                      end;
                    //---//if SI_Loguj_CheckBox.Checked then

                  end;
                //---//if fann_network <> nil then

              end;
            //---//if   ( not fann_decyduje_f ) (...)

          end;
        //---//for i_l := 0 to Length( si_decyzja_r_t ) - 1 do


        if   ( not fann_decyduje_f )
          or ( decyzja_wspó³czynnik__indeks_tabeli__fann = -99 ) then
          begin

            if    ( decyzja_wspó³czynnik__indeks_tabeli <> -99 )
              and ( decyzja_wspó³czynnik__najwiêkszy > 0 ) then
              //Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + IntToStr( planeta_f.id_planeta ) + ', -99', si_decyzja_r_t[ decyzja_wspó³czynnik__indeks_tabeli ].planeta_docelowa  );
              Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + id_planeta_z_s_f + ', -99', si_decyzja_r_t[ decyzja_wspó³czynnik__indeks_tabeli ].planeta_docelowa, 100  );

          end
        else//if   ( not fann_decyduje_f ) (...)
          begin

            if    ( fann_network <> nil )
              and ( decyzja_wspó³czynnik__indeks_tabeli__fann <> -99 ) then
              //and ( decyzja_wspó³czynnik__najwiêkszy__fann > 0 ) then //???
              Rakiety_Cel_Ustaw(  planeta_f.id_grupa, '-99, ' + id_planeta_z_s_f + ', -99', si_decyzja_r_t[ decyzja_wspó³czynnik__indeks_tabeli__fann ].planeta_docelowa, rakiety_iloœæ_procent_wys³anie__fann  );

          end;
        //---//if   ( not fann_decyduje_f ) (...)

      end
    else//if not decyzje_gracza_zapamiêtuj_obliczenia then
      begin

        if Length( si_decyzja_r_t ) > 0 then
          begin

            inc( decyzje_gracza_numer_g );


            if decyzje_gracza_g = '' then
              decyzje_gracza_g := decyzje_gracza_g + // Za pierwszym razem wpisuje nag³ówki kolumn.
                'id_planeta;' +
                'planeta jest planet¹ docelow¹;' +
                'planeta nale¿y do gracza;' +
                'id_planeta_docelowa;' +
                'grupa_zdobywaj¹ca_planetê;' +
                'odleg³oœæ;' +
                'planety_iloœæ_mapa;' +
                'planety_posiadane_procent;' +
                'przejmowanie_poziom_aktualny;' +
                'przyrost_szybkoœæ;' +
                'rakiety_iloœæ_procent_wys³anie;' +
                'rakiety_na_orbicie_iloœæ__obce;' +
                'rakiety_na_orbicie_iloœæ__w³asne;' +
                'wielkoœæ;'
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

            // Zmienia siê gdy jakaœ grupa straci³a albo przejê³a planetê (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planetê, 2 - planetê zdobywa grupa nie gracza).
            if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj¹ca_planetê = 0 then
              decyzje_gracza_g := decyzje_gracza_g + '0;'
            else
            if si_decyzja_r_t[ i_l ].id_grupa_zdobywaj¹ca_planetê = id_grupa_gracza_c then
              decyzje_gracza_g := decyzje_gracza_g + '1;'
            else
              decyzje_gracza_g := decyzje_gracza_g + '2;';

            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].odleg³oœæ )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', planety_iloœæ_mapa_g )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', planety_posiadane_procent_f )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + StringReplace(   Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].przejmowanie_poziom_aktualny )  ), ' ', '', [ rfReplaceAll ]   ) + ';'; // Wartoœci ujemne maj¹ minus przed spacj¹.
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].przyrost_szybkoœæ )  ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__obce ) + ';';
            decyzje_gracza_g := decyzje_gracza_g + IntToStr( si_decyzja_r_t[ i_l ].rakiety_na_orbicie_iloœæ__w³asne ) + ';'; // W przypadku gracza s¹ to jego wszystkie rakiety na wszystkich orbitach (bez tych aktualnie lec¹cych).
            decyzje_gracza_g := decyzje_gracza_g + Trim(  FormatFloat( '### ### ##0.0000', si_decyzja_r_t[ i_l ].wielkoœæ )  ) + ';';

          end;
        //---//for i_l := 0 to Length( si_decyzja_r_t ) - 1 do

        //SI_Log_Memo.Lines.Add( '' );
        //SI_Log_Memo.Lines.Add( decyzje_gracza_g );

      end;
    //---//if not decyzje_gracza_zapamiêtuj_obliczenia then

    SetLength( si_decyzja_r_t, 0 );

  end;//---//Funkcja SI_Planeta_Decyduj() w SI_Decyduj().

var
  grupa_fann_decyduje : boolean;
  i,
  j,
  zti,
  planeta_indeks,
  planety_iloœæ_w_grupie,
  rakiety_iloœæ_w_grupie
    : integer;
  planety_posiadane_procent : real; // Jaki procent wszystkich planet posiada grupa.
  id_planeta_z_s // Wszystkie planety, z których grupa wysy³a (mo¿e wys³aæ) rakiety.
    : string;
  œrodek_geometryczny_planet_w_grupie : GLS.VectorTypes.TVector4f;
begin//Funkcja SI_Decyduj().

  // Decyduje o ruchach SI.
  // Parametry:
  //   id_grupa_f
  //     = -1 - przelicza wszystkie grupy.
  //     <> -1 - przelicza wskazan¹ grupê.
  //

  if   (  Length( statystyki_tabela_t ) <= 0  )
    or ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  if SI_Loguj_CheckBox.Checked then
    begin

      SI_Log_Memo.Lines.Clear();
      SI_Log_Memo.Lines.Add(   'Czêstotliwoœæ decyzji SI ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__cykl_sekundy_g )  ) + ' (~ ' + Trim(  FormatFloat( '### ### ##0', si_decyduj__cykl_sekundy__modyfikator_losowy_g )  ) + ') sekund.'   );

    end;
  //---//if SI_Loguj_CheckBox.Checked then


  decyzje_gracza_zapamiêtuj_obliczenia :=
        ( id_grupa_f = id_grupa_gracza_c )
    and ( decyzja_gracza__planeta_docelowa__id_planeta_f > -1 );


  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    begin

      if    (    (
                       ( not decyzje_gracza_zapamiêtuj_obliczenia )
                   and ( statystyki_tabela_t[ i ][ 0 ] <> id_grupa_gracza_c )
                 )
              or (
                       ( decyzje_gracza_zapamiêtuj_obliczenia )
                   and ( statystyki_tabela_t[ i ][ 0 ] = id_grupa_gracza_c )
                 )
            )
        and (
                 ( id_grupa_f = -1 )
              or ( id_grupa_f = statystyki_tabela_t[ i ][ 0 ] )
            ) then
        begin

          grupa_fann_decyduje := false;

          {$IFDEF si_fann_u¿ywaj}
          for j := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
            if Grupa_Fann_Decyduje_CheckListBox.Items[ j ] = IntToStr( statystyki_tabela_t[ i ][ 0 ] ) then
              begin

                grupa_fann_decyduje := Grupa_Fann_Decyduje_CheckListBox.Checked[ j ];
                Break;

              end;
            //---//if Grupa_Fann_Decyduje_CheckListBox.Items[ j ] = IntToStr( statystyki_tabela_t[ i ][ 0 ] ) then
          {$ENDIF}


          planety_iloœæ_w_grupie := 0;

          for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
              inc( planety_iloœæ_w_grupie );


          if planety_iloœæ_mapa_g <> 0 then
            planety_posiadane_procent := 100 * planety_iloœæ_w_grupie / planety_iloœæ_mapa_g
          else//if planety_iloœæ_mapa_g <> 0 then
            planety_posiadane_procent := 0;


          zti := System.Math.Floor( planety_posiadane_procent * 0.1 ); // Im wiêcej planet (procentowo) ma grupa tym czêœciej planety decyduj¹ niezale¿nie aby zamiast wysy³aæ jednej du¿ej floty powstawa³y mniejsze floty.

          if zti >= 7 then
            zti := 6;


          if   ( decyzje_gracza_zapamiêtuj_obliczenia )
            or (  Random( 11 ) <= 7 - zti  ) then
            begin

              // Decydowanie dla wszystkich planet w grupie razem.

              planeta_indeks := -99;

              œrodek_geometryczny_planet_w_grupie := GLS.VectorGeometry.VectorMake( 0, 0, 0 );
              //planety_iloœæ_w_grupie := 0;
              rakiety_iloœæ_w_grupie := 0;
              id_planeta_z_s := '';


              //for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
              //  if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              //    //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
              //    and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
              //    inc( planety_iloœæ_w_grupie );
              //
              //
              //if planety_iloœæ_mapa_g <> 0 then
              //  planety_posiadane_procent := 100 * planety_iloœæ_w_grupie / planety_iloœæ_mapa_g
              //else//if planety_iloœæ_mapa_g <> 0 then
              //  planety_posiadane_procent := 0;


              for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
                if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
                  //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
                  and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
                  begin

                    if planeta_indeks = -99 then
                      planeta_indeks := j;

                    //inc( planety_iloœæ_w_grupie );


                    zti := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).Rakiety_Na_Orbicie_Iloœæ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa );


                    if    (
                               ( planety_iloœæ_w_grupie > 4 )
                            or ( planety_posiadane_procent > si_decyduj__planety_posiadane_procent_próg_c )
                          )
                      and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).pojemnoœæ_rakiet <> 0 )
                      and ( 100 * zti / TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).pojemnoœæ_rakiet >= planety_posiadane_procent ) then
                      begin

                        // Aby, gdy ma ju¿ trochê planet, wysy³a³ rakiety w wiêkszych odstêpach czasu.

                        rakiety_iloœæ_w_grupie := rakiety_iloœæ_w_grupie
                          + zti;


                        if id_planeta_z_s <> '' then
                          id_planeta_z_s := id_planeta_z_s + ', ';

                        id_planeta_z_s := id_planeta_z_s + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_planeta );

                      end
                    else//if    ( (...)
                      begin

                        rakiety_iloœæ_w_grupie := rakiety_iloœæ_w_grupie
                          + zti;


                        if id_planeta_z_s <> '' then
                          id_planeta_z_s := id_planeta_z_s + ', ';

                        id_planeta_z_s := id_planeta_z_s + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_planeta );

                      end;
                    //---//if    ( (...)


                    œrodek_geometryczny_planet_w_grupie.X := œrodek_geometryczny_planet_w_grupie.X + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.X;
                    œrodek_geometryczny_planet_w_grupie.Y := œrodek_geometryczny_planet_w_grupie.Y + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.Y;
                    œrodek_geometryczny_planet_w_grupie.Z := œrodek_geometryczny_planet_w_grupie.Z + TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).AbsolutePosition.Z;

                  end;
                //---//if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta ) (...)

              if planety_iloœæ_w_grupie <> 0 then
                begin

                  GLS.VectorGeometry.ScaleVector( œrodek_geometryczny_planet_w_grupie, 1 / planety_iloœæ_w_grupie );

                end;
              //---//if planety_iloœæ_w_grupie <> 0 then


              if planeta_indeks <> -99 then // Zapamiêtany indeks planety z grupy aby w funkcji znaæ id grupy.
                SI_Planeta_Decyduj( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ planeta_indeks ]), œrodek_geometryczny_planet_w_grupie, planety_posiadane_procent, grupa_fann_decyduje, rakiety_iloœæ_w_grupie, id_planeta_z_s );

            end
          else//if   ( decyzje_gracza_zapamiêtuj_obliczenia ) (...)
            begin

              // Decydowanie niezale¿ne dla ka¿dej planety osobno.

              for j := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
                if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
                  //and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa <> id_grupa_gracza_c )
                  and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] ) then
                  SI_Planeta_Decyduj( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]), œrodek_geometryczny_planet_w_grupie, 0, grupa_fann_decyduje );

            end;
          //---//if   ( decyzje_gracza_zapamiêtuj_obliczenia ) (...)


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

//Funkcja Zwyciêstwo_SprawdŸ().
function TPlanety_Form.Zwyciêstwo_SprawdŸ( out id_grupa_wy : integer ) : boolean;
var
  i : integer;
begin

  //
  // Funkcja sprawdza czy któraœ grupa wygra³a.
  //
  // Zwraca prawdê gdy któraœ grupa wygra³a.
  //
  // Parametry:
  //   id_grupa_wy - id zwyciêskiej grupy.
  //

  Result := false;


  id_grupa_wy := id_grupa_neutralna_c;

  // Sprawdza czy wszystkie planety s¹ neutralne b¹dŸ w posiadaniu tylko jednej grupy.
  for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
    if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      begin

        if    ( id_grupa_wy <> id_grupa_neutralna_c )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c ) // Neutralnych planet nie uwzglêdnia podczas sprawdzania warunków zwyciêstwa.
          and ( id_grupa_wy <> TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa ) then
          Exit; // Planety s¹ w posiadaniu ro¿nych nie neutralnych grup.


        if    ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa > id_grupa_neutralna_c )
          and ( id_grupa_wy = id_grupa_neutralna_c ) then
          id_grupa_wy := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa;

      end;
    //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
  //---// Sprawdza czy wszystkie planety s¹ neutralne b¹dŸ w posiadaniu tylko jednej grupy.


  // Sprawdza czy wszystkie rakiety nale¿¹ce tylko do jednej grupy.
  if   ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;

  id_grupa_wy := id_grupa_neutralna_c; // Neutralnych rakiet nie uwzglêdnia podczas sprawdzania warunków zwyciêstwa.

  for i := 0 to rakiety_list.Count - 1 do
    begin

      if    ( id_grupa_wy <> id_grupa_neutralna_c )
        and ( id_grupa_wy <> TRakieta(rakiety_list[ i ]).id_grupa ) then
        Exit; // Istniej¹ rakiety nale¿¹ce do ro¿nych grup.


      if id_grupa_wy = id_grupa_neutralna_c then
        id_grupa_wy := TRakieta(rakiety_list[ i ]).id_grupa;

    end;
  //---//for i := 0 to rakiety_list.Count - 1 do
  //---// Sprawdza czy wszystkie rakiety nale¿¹ce tylko do jednej grupy.


  Result := true;

end;//---//Funkcja Zwyciêstwo_SprawdŸ().

//Funkcja Przegrana_Gracza_SprawdŸ().
function TPlanety_Form.Przegrana_Gracza_SprawdŸ( out id_grupa_wy : integer ) : boolean;
var
  i : integer;
begin

  //
  // Funkcja sprawdza czy gracz straci³ wszystkie planety i rakiety.
  //
  // Zwraca prawdê gdy gracz straci³ wszystkie planety i rakiety.
  //
  // Parametry:
  //   id_grupa_wy - aby w innej funkcji ustawiæ wartoœæ, ¿e to nie grupa gracza wygrywa.
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

end;//---//Funkcja Przegrana_Gracza_SprawdŸ().

//Funkcja Statystyki_Tabela_Utwórz().
procedure TPlanety_Form.Statystyki_Tabela_Utwórz();
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

              ztb := true; // W tabeli statystyk jest ju¿ dana grupa.
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


  // Sortuje (b¹belkowo) tabelê statystyk wed³ug grup.
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
              ztb := true; // Oznacza, ¿e by³a zmiana kolejnoœci w tabeli.

          end;
        //---//if statystyki_tabela_t[ i ][ 0 ] > statystyki_tabela_t[ i + 1 ][ 0 ] then

    end;
  //---//while ztb do


  {$IFDEF si_fann_u¿ywaj}
  // Zapamiêtuje zaznaczone grupy.
  zts := ', ';

  for i := 0 to Grupa_Fann_Decyduje_CheckListBox.Items.Count - 1 do
    if Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] then
      zts := zts + Grupa_Fann_Decyduje_CheckListBox.Items[ i ] + ', ';
  //---// Zapamiêtuje zaznaczone grupy.


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

end;//---//Funkcja Statystyki_Tabela_Utwórz().

//Funkcja Statystyki_Tabela_Wartoœci_Kolejne_Zapamiêtaj().
procedure TPlanety_Form.Statystyki_Tabela_Wartoœci_Kolejne_Zapamiêtaj();
var
  i,
  j,
  zti,
  rakiety_iloœæ
    : integer;
begin

  // Dopisuje kolejn¹ kolumnê z iloœci¹ rakiet ka¿dej grupy.

  if   (  Length( statystyki_tabela_t ) <= 0  )
    or ( rakiety_list = nil )
    or (  not Assigned( rakiety_list )  ) then
    Exit;


  zti := Length( statystyki_tabela_t[ 0 ] );

  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    begin

      SetLength( statystyki_tabela_t[ i ], zti + 1 );


      rakiety_iloœæ := 0;

      for j := 0 to rakiety_list.Count - 1 do
        if TRakieta(rakiety_list[ j ]).id_grupa = statystyki_tabela_t[ i ][ 0 ] then
          inc( rakiety_iloœæ );


      statystyki_tabela_t[ i ][ zti ] := rakiety_iloœæ;

    end;
  //---//for i := 0 to Length( statystyki_tabela_t ) - 1 do

end;//---//Funkcja Statystyki_Tabela_Wartoœci_Kolejne_Zapamiêtaj().

//Funkcja Statystyki_Tabela_Czyœæ().
procedure TPlanety_Form.Statystyki_Tabela_Czyœæ();
var
  i : integer;
begin

  // Czyœci tabelê statystyk.

  for i := 0 to Length( statystyki_tabela_t ) - 1 do
    SetLength( statystyki_tabela_t[ i ], 0 );

  SetLength( statystyki_tabela_t, 0 );

end;//---//Funkcja Statystyki_Tabela_Czyœæ().

//Funkcja Statystyki_Wyœwietl().
procedure TPlanety_Form.Statystyki_Wyœwietl( const {czy_przyciski_f,} czy_zwyciêstwo_f : boolean; const id_grupa_f : integer );

  //Funkcja Statystyki_Generuj_Wartoœci_Do_Testów().
  procedure Statystyki_Generuj_Wartoœci_Do_Testów();
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

  end;//---//Funkcja Statystyki_Generuj_Wartoœci_Do_Testów().

var
  czy_pauza,
  czy_stop // Czy poleceniem okna statystyk by³ stop.
    : boolean;
  i,
  zti
    : integer;
  zt_modal_result : TModalResult;
begin//Funkcja Statystyki_Wyœwietl().

  czy_pauza := not GLCadencer1.Enabled;
  czy_stop := false;

  if not czy_pauza then
    Pauza_ButtonClick( nil );


  Statystyki_Form := TStatystyki_Form.Create( Application );

  Statystyki_Form.Zwyciêstwo_Label.Visible := czy_zwyciêstwo_f;
  //Statystyki_Form.Przyciski_Panel.Visible := czy_przyciski_f;

  Statystyki_Form.Nastêpna_Misja_Button.Enabled := Nastêpna_Misja_Button.Enabled;
  //Statystyki_Form.Pauza_Button.Enabled := not czy_pauza;
  Statystyki_Form.Stop_Button.Enabled := Start_Stop_Button.Tag = 1;

  if czy_pauza then
    Statystyki_Form.Pauza_Button.Font.Style := [ fsBold ];

  Statystyki_Form.czy_zwyciêstwo := czy_zwyciêstwo_f;
  Statystyki_Form.id_grupa_zwyciêska := id_grupa_f;

  if czy_zwyciêstwo_f then
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
            Statystyki_Form.Caption := 'Ostateczne zwyciêstwo'
          else//if id_grupa_f = id_grupa_gracza_c then
            Statystyki_Form.Caption := 'Przegrana';

          Statystyki_Form.Nastêpna_Misja_Button.Visible := false; //???

        end
      else//if   ( (...)
        if id_grupa_f = id_grupa_gracza_c then
          Statystyki_Form.Caption := 'Zwyciêstwo'
        else//if id_grupa_f = id_grupa_gracza_c then
          Statystyki_Form.Caption := 'Przegrana';

    end;
  //---//if czy_zwyciêstwo_f then


  Statystyki_Form.Zwyciêstwo_Label.Caption := Statystyki_Form.Caption;


  ////Statystyki_Form.Statystyki_Image.Canvas.Rectangle( 10, 20, 500, 700 );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut( 10, 10, 'Rakiety utworzone / stracone' );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut(   10, 30, 'w misji: ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_utworzonych__misja )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_straconych__misja )  )   );
  //Statystyki_Form.Statystyki_Image.Canvas.TextOut(   10, 50, 'w grze: ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_utworzonych__gra )  ) + ' / ' + Trim(  FormatFloat( '### ### ### ##0', statystyki__rakiet_straconych__gra )  )   );


  //Statystyki_Generuj_Wartoœci_Do_Testów(); //???


  Statystyki_Form.Wykres_Liniowy_MenuItem.Checked := statystyki_wykres_liniowy_menuitem_checked_g;
  Statystyki_Form.Wykres_S³upkowy_MenuItem.Checked := statystyki_wykres_s³upkowy_menuitem_checked_g;

  zt_modal_result := Statystyki_Form.ShowModal();

  statystyki_wykres_liniowy_menuitem_checked_g := Statystyki_Form.Wykres_Liniowy_MenuItem.Checked;
  statystyki_wykres_s³upkowy_menuitem_checked_g := Statystyki_Form.Wykres_S³upkowy_MenuItem.Checked;

  FreeAndNil( Statystyki_Form );


  if zt_modal_result = mrAll then
    begin

      // Nastêpna misja.

      if Decyzje_Gracza_Zapamiêtuj_CheckBox.Checked then
        Decyzje_Gracza_Zapisz_ButtonClick( nil );


      Nastêpna_Misja_ButtonClick( nil );

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

      statystyki__polecenia_iloœæ__gra := statystyki__polecenia_iloœæ__gra - statystyki__polecenia_iloœæ__misja;
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
    and ( not czy_stop ) then // Stop w³¹cza te¿ pauzê.
    Pauza_ButtonClick( nil );

end;//---//Funkcja Statystyki_Wyœwietl().

//Funkcja Informacja_Wyœwietl().
procedure TPlanety_Form.Informacja_Wyœwietl( const napis_f : string );
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

end;//---//Funkcja Informacja_Wyœwietl().

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
procedure TPlanety_Form.FANN_Przygotuj( const tylko_utwórz_sieæ_f : boolean = false );
type
  TFANN_Nauka_r = record
    linijka_planeta_dane : boolean;

    grupa_zdobywaj¹ca_planetê,
    planeta_nale¿y_do_gracza,
    planety_iloœæ_mapa,
    planeta_docelowa__id_planeta, // Tylko dla uczenia SI.
    rakiety_iloœæ_procent_wys³anie, // Tylko dla uczenia SI.
    rakiety_na_orbicie_iloœæ__obce,
    rakiety_na_orbicie_iloœæ__w³asne
      : integer;

    odleg³oœæ,
    planety_posiadane_procent, // Tylko dla uczenia SI.
    przejmowanie_poziom_aktualny,
    przyrost_szybkoœæ,
    wielkoœæ
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
  wartoœæ
    : string;
  œredni_b³¹d_kwadratowy : single;

  search_rec : TSearchRec;

  fann_nauka_r : TFANN_Nauka_r;

  zt_string_list : TStringList;

  wejœcia : array [ 0..9 ] of single;
  wyjœcia : array [ 0..1 ] of single;

  fann_nauka_r_t : array of TFANN_Nauka_r;
begin//Funkcja FANN_Przygotuj().

  Screen.Cursor := crHourGlass;

  if fann_network = nil then
    begin

      {$IFDEF si_fann_u¿ywaj}
      fann_network := TFannNetwork.Create( Application );

      fann_network.Layers.Add( '10' ); // 10 20 10 2

      //fann_network.Layers.Add( '20' ); // x 10 20 8 4
      //fann_network.Layers.Add( '10' );

      linijka := Neuronów_W_Warstwach_Ukrytych_Edit.Text + ','; // Tutaj tymczasowo jako kopia iloœci neuronów w warstwach.

      zti := Pos( ',', linijka );

      while zti > 0 do
        begin

          wartoœæ := Copy( linijka, 1, zti - 1 );
          wartoœæ := Trim( wartoœæ );
          Delete( linijka, 1, zti );

          try
            i := StrToInt( wartoœæ );
          except
            on E: Exception do
              begin

                i := -1;
                FANN__Zwolnij_ButtonClick( nil );
                Screen.Cursor := crDefault;
                Application.MessageBox(  PChar('Nie uda³o siê odczytaæ iloœci neuronów w warstwie ukrytej:' + #13 + #13 + E.Message + ' ' + IntToStr( E.HelpContext )), 'B³¹d', MB_OK + MB_ICONEXCLAMATION  );
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

      fann_network.TrainingAlgorithm := FannNetwork.TTrainingAlgorithm(FANN__Algorytm_Ucz¹cy_ComboBox.ItemIndex);
      fann_network.ActivationFunctionHidden := FannNetwork.TActivationFunction(FANN__Funkcja_Aktywuj¹ca_Warstw_Ukrytych_ComboBox.ItemIndex);
      fann_network.ActivationFunctionOutput := FannNetwork.TActivationFunction(FANN__Funkcja_Aktywuj¹ca_Warstwy_Wyjœcia_ComboBox.ItemIndex);

      fann_network.Build();
      {$ELSE si_fann_u¿ywaj}
      fann_network := TFann_Zaœlepka.Create( Application );
      {$ENDIF}


      if not Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled then
        Grupa_Fann_Decyduje__Fann_Tylko_RadioButton.Enabled := true;

      if not Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled then
        Grupa_Fann_Decyduje__Losuj_RadioButton.Enabled := true;


      if not Grupa_Fann_Decyduje__Losuj_RadioButton .Checked then
        Grupa_Fann_Decyduje__Losuj_RadioButton.Checked := true;

    end;
  //---//if fann_network = nil then


  if tylko_utwórz_sieæ_f then
    begin

      Screen.Cursor := crDefault;
      Exit;

    end;
  //---//if tylko_utwórz_sieæ_f then


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

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
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

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planeta_docelowa__id_planeta := System.Math.Floor( ztr ); // 0 - nie, 1 - tak.


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planeta_nale¿y_do_gracza := System.Math.Floor( ztr ); // 0 - nie, 1 - tak.


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            // id_planeta_docelowa


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.grupa_zdobywaj¹ca_planetê := System.Math.Floor( ztr ); // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planetê, 2 - planetê zdobywa grupa nie gracza).


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.odleg³oœæ := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planety_iloœæ_mapa := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.planety_posiadane_procent := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.przejmowanie_poziom_aktualny := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.przyrost_szybkoœæ := ztr;


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_iloœæ_procent_wys³anie := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_na_orbicie_iloœæ__obce := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.rakiety_na_orbicie_iloœæ__w³asne := System.Math.Floor( ztr );


            zti := Pos( ';', linijka );

            if zti <= 0 then
              Continue;

            wartoœæ := Copy( linijka, 1, zti - 1 );
            Delete( linijka, 1, zti );

            try
              ztr := StrToFloat( wartoœæ );
            except
              Continue;
            end;
            //---//try

            fann_nauka_r.wielkoœæ := ztr;



            if fann_nauka_r.linijka_planeta_dane then
              begin

                zti := Length( fann_nauka_r_t );
                SetLength( fann_nauka_r_t, zti + 1 );

                fann_nauka_r_t[ zti ].planeta_docelowa__id_planeta := fann_nauka_r.planeta_docelowa__id_planeta; // planeta jest planet¹ docelow¹ (na t¹ planetê gracz wysy³a³ rakiety) (0 - nie, 1 - tak).
                fann_nauka_r_t[ zti ].planeta_nale¿y_do_gracza := fann_nauka_r.planeta_nale¿y_do_gracza;

                fann_nauka_r_t[ zti ].grupa_zdobywaj¹ca_planetê := fann_nauka_r.grupa_zdobywaj¹ca_planetê; // Zmienia siê gdy jakaœ grupa straci³a albo przejê³a planetê.

                fann_nauka_r_t[ zti ].rakiety_iloœæ_procent_wys³anie := fann_nauka_r.rakiety_iloœæ_procent_wys³anie;
                fann_nauka_r_t[ zti ].rakiety_na_orbicie_iloœæ__obce := fann_nauka_r.rakiety_na_orbicie_iloœæ__obce;
                fann_nauka_r_t[ zti ].rakiety_na_orbicie_iloœæ__w³asne := fann_nauka_r.rakiety_na_orbicie_iloœæ__w³asne;

                fann_nauka_r_t[ zti ].odleg³oœæ := fann_nauka_r.odleg³oœæ;
                fann_nauka_r_t[ zti ].planety_iloœæ_mapa := fann_nauka_r.planety_iloœæ_mapa;
                fann_nauka_r_t[ zti ].planety_posiadane_procent := fann_nauka_r.planety_posiadane_procent;
                fann_nauka_r_t[ zti ].przejmowanie_poziom_aktualny := fann_nauka_r.przejmowanie_poziom_aktualny;
                fann_nauka_r_t[ zti ].przyrost_szybkoœæ := fann_nauka_r.przyrost_szybkoœæ;
                fann_nauka_r_t[ zti ].wielkoœæ := fann_nauka_r.wielkoœæ;

              end;
            //---//if fann_nauka_r.linijka_planeta_dane then

          end;
        //---//for i := 0 to zt_string_list.Count - 1 do

      until FindNext( search_rec ) <> 0; // Zwraca dane kolejnego pliku zgodnego z parametrami wczeœniej wywo³anej funkcji FindFirst. Je¿eli mo¿na przejœæ do nastêpnego znalezionego pliku zwraca 0.

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

          wejœcia[ 0 ] := fann_nauka_r_t[ i ].planeta_nale¿y_do_gracza; // 0 - nie, 1 - tak.
          wejœcia[ 1 ] := fann_nauka_r_t[ i ].grupa_zdobywaj¹ca_planetê; // (0 - nikt nie zdobywa planety, 1 - gracz zdobywa planetê, 2 - planetê zdobywa grupa nie gracza).
          wejœcia[ 2 ] := fann_nauka_r_t[ i ].odleg³oœæ;
          wejœcia[ 3 ] := fann_nauka_r_t[ i ].planety_iloœæ_mapa;
          wejœcia[ 4 ] := fann_nauka_r_t[ i ].planety_posiadane_procent;
          wejœcia[ 5 ] := fann_nauka_r_t[ i ].przejmowanie_poziom_aktualny;
          wejœcia[ 6 ] := fann_nauka_r_t[ i ].przyrost_szybkoœæ;
          wejœcia[ 7 ] := fann_nauka_r_t[ i ].rakiety_na_orbicie_iloœæ__obce;
          wejœcia[ 8 ] := fann_nauka_r_t[ i ].rakiety_na_orbicie_iloœæ__w³asne; // W przypadku gracza s¹ to jego wszystkie rakiety na wszystkich orbitach (bez tych aktualnie lec¹cych).
          wejœcia[ 9 ] := fann_nauka_r_t[ i ].wielkoœæ;

          wyjœcia[ 0 ] := fann_nauka_r_t[ i ].planeta_docelowa__id_planeta; // planeta jest planet¹ docelow¹ (na t¹ planetê gracz wysy³a³ rakiety) (0 - nie, 1 - tak).
          wejœcia[ 1 ] := fann_nauka_r_t[ i ].rakiety_iloœæ_procent_wys³anie; // Taki procent rakiet graczy wysy³a³ w danym ruchu.

          œredni_b³¹d_kwadratowy := fann_network.Train( wejœcia, wyjœcia );

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


  SI_Log_Memo.Lines.Add( 'Œredni b³¹d kwadratowy <Mittlerer quadratischer Fehler> <Mean square error>:' );
  SI_Log_Memo.Lines.Add(   Trim(  FormatFloat( '### ### ##0.0000000', œredni_b³¹d_kwadratowy )  )   ); //???

  Screen.Cursor := crDefault;

  Komunikat_Wyœwietl( 'Uczenie sieci zakoñczone.' + #13 + #13 + 'Netzwerkschulung abgeschlossen.' + #13 + #13 + 'Network training complete.', 'Informacja', MB_OK + MB_ICONINFORMATION );

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
        // Czasami bez begin i end nieprawid³owo rozpoznaje miejsca na umieszczenie breakpoint (linijkê za wysoko) w XE5.

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
  fann_sieæ_domyœlna_nazwa_c_l : string = 'Domyœlna';

var
  zts : string;
begin

  planety_iloœæ_mapa_g := 0;
  si_decyduj__cykl_sekundy_g := 10;
  si_decyduj__cykl_sekundy__modyfikator_losowy_g := 0;

  statystyki__polecenia_iloœæ__gra := 0;
  statystyki__polecenia_iloœæ__misja := 0;
  statystyki__rakiet_straconych__gra := 0;
  statystyki__rakiet_straconych__misja := 0;
  statystyki__rakiet_utworzonych__gra := 0;
  statystyki__rakiet_utworzonych__misja := 0;

  czy_zwyciêstwo := false;
  statystyki_wykres_liniowy_menuitem_checked_g := true;
  statystyki_wykres_s³upkowy_menuitem_checked_g := false;

  ostatni_ruch_ponów__id_planeta_z__1 := '';
  ostatni_ruch_ponów__id_planeta_z__2 := '';
  ostatni_ruch_ponów__id_planeta_z__3 := '';
  ostatni_ruch_ponów__id_planeta_z__4 := '';

  ostatni_ruch_ponów__planeta_docelowa__1 := nil;
  ostatni_ruch_ponów__planeta_docelowa__2 := nil;
  ostatni_ruch_ponów__planeta_docelowa__3 := nil;
  ostatni_ruch_ponów__planeta_docelowa__4 := nil;

  fann_network := nil;

  zaznaczanie_ruchem_myszy__opóŸnienie_data_czas := Now();
  zaznaczanie_ruchem_myszy__opóŸnienie__zaznacze_data_czas := zaznaczanie_ruchem_myszy__opóŸnienie_data_czas;

  GLS.VectorGeometry.SetVector( kamera_pozycja_pocz¹tkowa_g, 0, 0, 0 );


  Gra_GLSceneViewer.Align := alClient;

  PageControl1.ActivePage := Opcje_TabSheet;

  SetLength( kolor_grupa_r_t, 0 );
  SetLength( mapa_rozegrana_t, 0 );


  {$IFDEF si_fann_u¿ywaj}
  O_Programie_Label.Caption := O_Programie_Label.Caption +
    #13 +
    #13 +
    #13 +
    'W programie u¿yto komponentów <Folgende Komponenten wurden im Programm verwendet> <The following components were used in the program>:' + #13 +
    #13 +
    'TfannNetwork autorstwa Mauricio Pereira Maia' + #13 +
    'mauriciocpa@gmail.com' + #13 +
    'fann.sourceforge.net';

  FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_ButtonClick( Sender );
  {$ELSE si_fann_u¿ywaj}
  Grupa_Fann_Decyduje_GroupBox.Visible := false;
  FANN__Opcje_Dodatkowe_GroupBox.Visible := false;
  {$ENDIF}


  Randomize();


  SI_Decyduj__Modyfikator_Losowy_Ustaw();

  //GLSkyDome1.Stars.Clear();
  GLSkyDome1.Stars.AddRandomStars( 1000, clWhite ); // Iloœæ, kolor.
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


  {$IFDEF si_fann_u¿ywaj}
  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + fann_sieæ_domyœlna_nazwa_c_l + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;

  if FileExists( zts ) then
    begin

      FANN__Plik_Nazwa_ComboBox.Text := fann_sieæ_domyœlna_nazwa_c_l;

      FANN__Wczytaj_ButtonClick( Sender );

    end;
  //---//if not FileExists( zts ) then
  {$ENDIF}


  //Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo³uje siê Mapa_ComboBoxChange(). //???

end;//---//FormShow().

//FormClose().
procedure TPlanety_Form.FormClose( Sender: TObject; var Action: TCloseAction );
begin

  if Komunikat_Wyœwietl( 'Czy wyjœæ z gry?' + #13 + #13 + 'Das Spiel benden?' + #13 + #13 + 'Quit the game?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
    begin

      Action := caNone;
      Exit;

    end;
  //---//if Komunikat_Wyœwietl( 'Czy wyjœæ z gry?' + #13 + #13 + 'Das Spiel benden?' + #13 + #13 + 'Quit the game?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then


  SetLength( kolor_grupa_r_t, 0 );

  Walka_Efekt_Zwolnij_Wszystkie();
  FreeAndNil( walka_efekt_list );

  Rakiety_Zwolnij_Wszystkie();
  FreeAndNil( rakiety_list );

  Mapa_Zwolnij();

  SetLength( mapa_rozegrana_t, 0 );


  if fann_network <> nil then
    begin

      {$IFDEF si_fann_u¿ywaj}
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
  zwalczanie_poza_orbit¹__przeliczaj
    : boolean;
  i : integer;
begin

  GLUserInterface1.MouseLook();
  GLUserInterface1.MouseUpdate();
  Gra_GLSceneViewer.Invalidate();


  if Start_Stop_Button.Tag = 1 then
    przyrost__przeliczaj := GLCadencer1.CurrentTime - przyrost__ostatnie_przeliczenie_g >= przyrost__cykl_sekundy_c / Gra_Prêdkoœæ()
  else//if Start_Stop_Button.Tag = 1 then
    przyrost__przeliczaj := false;


  for i := Gra_Obiekty_GLDummyCube.Count - 1 downto 0 do
    begin

      if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
        begin

          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).orbita_dla_rakiet_gl_dummy_cube.Roll( 10 * deltaTime * Gra_Prêdkoœæ() );


          if    ( przyrost__przeliczaj )
            and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_grupa <> id_grupa_neutralna_c ) then // Na neutralnych planetach rakiety nie przyrastaj¹.
            begin

              TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Przyrost_Przeliczaj();

            end;
          //---//if    ( przyrost__przeliczaj ) (...)

        end
      else//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
      if Gra_Obiekty_GLDummyCube.Children[ i ] is TWalka_Efekt then
        begin

          if    ( TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek > 0 )
            and ( GLCadencer1.CurrentTime - TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).utworzenie_czas >= walka_efekt__czas_trwania_sekundy_c * 0.5 / Gra_Prêdkoœæ() ) then
            TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek := -TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek;


          //TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).Scale.Scale( 1.001 );
          TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).gl_thor_fx_manager.GlowSize :=
            TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).gl_thor_fx_manager.GlowSize + 0.0005 * TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).wzrost_kierunek;


          if GLCadencer1.CurrentTime - TWalka_Efekt(Gra_Obiekty_GLDummyCube.Children[ i ]).utworzenie_czas >= walka_efekt__czas_trwania_sekundy_c / Gra_Prêdkoœæ() then
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
        zwalczanie_poza_orbit¹__przeliczaj := GLCadencer1.CurrentTime - zwalczanie_poza_orbit¹__ostatnie_przeliczenie_g >= zwalczanie_poza_orbit¹__cykl_sekundy_c / Gra_Prêdkoœæ()
      else//if Start_Stop_Button.Tag = 1 then
        zwalczanie_poza_orbit¹__przeliczaj := false;

      if zwalczanie_poza_orbit¹__przeliczaj then
        begin

          Orbita_Rakiety_Zwalczanie( true );

          zwalczanie_poza_orbit¹__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

        end;
      //---//if zwalczanie_poza_orbit¹__przeliczaj then

    end;
  //---//if przyrost__przeliczaj then


  if    ( Start_Stop_Button.Tag = 1 )
    and (  GLCadencer1.CurrentTime - si_decyduj__ostatnie_przeliczenie_g >= ( si_decyduj__cykl_sekundy_g + si_decyduj__cykl_sekundy__modyfikator_losowy_g ) / Gra_Prêdkoœæ()  ) then
    begin

      SI_Decyduj();

      SI_Decyduj__Modyfikator_Losowy_Ustaw();
      si_decyduj__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

    end;
  //---//if    ( Start_Stop_Button.Tag = 1 ) (...)


  Rakiety_Lot_Do_Celu( deltaTime );


  if    ( Start_Stop_Button.Tag = 1 )
    //and ( not czy_zwyciêstwo ) //???
    and ( GLCadencer1.CurrentTime - zwyciêstwo_sprawdŸ__ostatnie_przeliczenie_g >= zwyciêstwo_sprawdŸ__cykl_sekundy_c ) then
    begin

      Statystyki_Tabela_Wartoœci_Kolejne_Zapamiêtaj();


      if    ( Start_Stop_Button.Tag = 1 )
        and ( not czy_zwyciêstwo )
        and (
                 (  Zwyciêstwo_SprawdŸ( i )  )
              or (  Przegrana_Gracza_SprawdŸ( i )  )
            ) then
        begin

          czy_zwyciêstwo := true;

          if i = id_grupa_gracza_c then
            Nastêpna_Misja_Button.Enabled := true;

          Statystyki_Wyœwietl( {true,} true, i );

        end;
      //---//if    ( Start_Stop_Button.Tag = 1 ) (...)


      zwyciêstwo_sprawdŸ__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;

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

      // Pe³ny ekran.

      if Planety_Form.BorderStyle <> bsNone then
        begin

          // Pe³ny ekran.

          // Po ustawieniu pe³nego ekranu mog¹ znikaæ elementy po³o¿one na formie (jak panel), które nie s¹ wyrównywane do boków okna..

          if Planety_Form.WindowState = wsMaximized then
            Planety_Form.Tag := 1
          else//if Planety_Form.WindowState = wsMaximized then
            Planety_Form.Tag := 0;

          Planety_Form.BorderStyle := bsNone;

          if Planety_Form.WindowState = wsMaximized then
            Planety_Form.WindowState := wsNormal; // Zmaksymalizowane okno czasami nie zas³ania paska start.

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


  if   (  GLS.Keyboard.IsKeyDown( 'P' )  ) // Pauza podczas wy³¹czania przeskakuje widokiem kamery gdy obracanie mysz¹ jest w³¹czone.
    or (  GLS.Keyboard.IsKeyDown( VK_PAUSE )  ) then
    Pauza_ButtonClick( Sender );


  if GLS.Keyboard.IsKeyDown( 'I' ) then
    Statystyki_ButtonClick( Sender );


  if GLS.Keyboard.IsKeyDown( '/' ) then
    Pomoc_BitBtnClick( Sender );


  if GLS.Keyboard.IsKeyDown( VK_F1 ) then
    Ruch_Ostatni_Ponów_ButtonClick( Sender );


  if    (  GLS.Keyboard.IsKeyDown( VK_F2 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_ponów__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_ponów__id_planeta_z__2 := ostatni_ruch_ponów__id_planeta_z__1;
      ostatni_ruch_ponów__planeta_docelowa__2 := ostatni_ruch_ponów__planeta_docelowa__1;

      Informacja_Wyœwietl( 'Zapamiêtano ruch (F2).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F2 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F2 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_ponów__id_planeta_z__2, ostatni_ruch_ponów__planeta_docelowa__2 );

  if    (  GLS.Keyboard.IsKeyDown( VK_F3 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_ponów__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_ponów__id_planeta_z__3 := ostatni_ruch_ponów__id_planeta_z__1;
      ostatni_ruch_ponów__planeta_docelowa__3 := ostatni_ruch_ponów__planeta_docelowa__1;

      Informacja_Wyœwietl( 'Zapamiêtano ruch (F3).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F3 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F3 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_ponów__id_planeta_z__3, ostatni_ruch_ponów__planeta_docelowa__3 );

  if    (  GLS.Keyboard.IsKeyDown( VK_F4 )  )
    and (  GLS.Keyboard.IsKeyDown( VK_SHIFT )  )
    and (  Trim( ostatni_ruch_ponów__id_planeta_z__1 ) <> '' ) then
    begin

      ostatni_ruch_ponów__id_planeta_z__4 := ostatni_ruch_ponów__id_planeta_z__1;
      ostatni_ruch_ponów__planeta_docelowa__4 := ostatni_ruch_ponów__planeta_docelowa__1;

      Informacja_Wyœwietl( 'Zapamiêtano ruch (F4).' );

    end
  else//if    (  GLS.Keyboard.IsKeyDown( VK_F4 )  ) (...)
    if GLS.Keyboard.IsKeyDown( VK_F4 ) then
      Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_ponów__id_planeta_z__4, ostatni_ruch_ponów__planeta_docelowa__4 );


  if GLS.Keyboard.IsKeyDown( VK_F11 ) then
    begin

      if PageControl1.Width <> 200 then
        PageControl1.Width := 200
      else//if PageControl1.Width <> 200 then
        PageControl1.Width := 1; // 1. Gdy równe 0 to po schowaniu nie da siê rozwin¹æ poprzez Splitter.

      if not Opcje_Splitter.Visible then
        Opcje_Splitter.Visible := true;

    end;
  //---//if GLS.Keyboard.IsKeyDown( VK_F12 ) then

  if GLS.Keyboard.IsKeyDown( VK_F12 ) then
    begin

      if PageControl1.Width <> 200 then
        PageControl1.Width := 200
      else//if PageControl1.Width <> 200 then
        PageControl1.Width := 0; // 1. Gdy równe 0 to po schowaniu nie da siê rozwin¹æ poprzez Splitter.

      Opcje_Splitter.Visible := PageControl1.Width > 0;

    end;
  //---//if GLS.Keyboard.IsKeyDown( VK_F12 ) then


  if not GLCadencer1.Enabled then // Gdy pauza jest aktywna.
    Kamera_Ruch( 0.03 );


  if Start_Stop_Button.Tag = 1 then // Gdy nie ma aktywnej gry nie mo¿na wydawaæ poleceñ zwi¹zanych z rozgrywk¹. //???
    begin

      if    (  GLS.Keyboard.IsKeyDown( 'A' )  )
        and (  GLS.Keyboard.IsKeyDown( VK_CONTROL )  ) then // Zaznacza planety gracza i planety, na których orbitach s¹ rakiety gracza.
        begin

          for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
              and ( not TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona )
              and (  TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Rakiety_Na_Orbicie_Iloœæ( 1 ) > 0  ) then
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
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 10;

  if GLS.Keyboard.IsKeyDown( '2' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 20;

  if GLS.Keyboard.IsKeyDown( '3' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 30;

  if GLS.Keyboard.IsKeyDown( '4' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 40;

  if GLS.Keyboard.IsKeyDown( '5' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 50;

  if GLS.Keyboard.IsKeyDown( '6' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 60;

  if GLS.Keyboard.IsKeyDown( '7' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 70;

  if GLS.Keyboard.IsKeyDown( '8' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 80;

  if GLS.Keyboard.IsKeyDown( '9' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 90;

  if GLS.Keyboard.IsKeyDown( '0' ) then
    Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 100;


  if GLS.Keyboard.IsKeyDown( 'Q' ) then
    if Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value = 100 then
      Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 50
    else//if Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value = 100 then
      Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value := 100;


  //if   (  GLS.Keyboard.IsKeyDown( 'K' )  )
  //  or (  GLS.Keyboard.IsKeyDown( VK_NUMPAD2 )  ) then
  if GLS.Keyboard.IsKeyDown( 'K' ) then
    begin

      Gra_GLCamera.ResetRotations();
      Gra_GLCamera.Direction.Z := -1;

      Gra_GLCamera.Position.SetPoint( 0, 0, 0 );

      Gra_GLCamera.Position.AsVector := kamera_pozycja_pocz¹tkowa_g;

    end;
  //---//if GLS.Keyboard.IsKeyDown( 'K' ) then


  if    (  GLS.Keyboard.IsKeyDown( VK_ADD )  )
    and ( Gra_Prêdkoœæ_SpinEdit.Value <= Gra_Prêdkoœæ_SpinEdit.MaxValue - Gra_Prêdkoœæ_SpinEdit.Increment ) then
    Gra_Prêdkoœæ_SpinEdit.Value := Gra_Prêdkoœæ_SpinEdit.Value + Gra_Prêdkoœæ_SpinEdit.Increment;

  if    (  GLS.Keyboard.IsKeyDown( VK_SUBTRACT )  )
    and ( Gra_Prêdkoœæ_SpinEdit.Value >= Gra_Prêdkoœæ_SpinEdit.MinValue + Gra_Prêdkoœæ_SpinEdit.Increment ) then
    Gra_Prêdkoœæ_SpinEdit.Value := Gra_Prêdkoœæ_SpinEdit.Value - Gra_Prêdkoœæ_SpinEdit.Increment;

  if GLS.Keyboard.IsKeyDown( VK_MULTIPLY ) then
    Gra_Prêdkoœæ_SpinEdit.Value := 100;

end;//---//Gra_GLSceneViewerKeyDown().

//Gra_GLSceneViewerMouseDown().
procedure TPlanety_Form.Gra_GLSceneViewerMouseDown( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer );
var
  //planeta_gracza_zaznaczona,
  //planeta_klikniêta_zaznaczona
  planety_zaznaczona_wiêcej_ni¿_jedna
    : boolean;
  i,
  id_planeta_zaznaczona
  //zti
    : integer;
  zts : string;
  zt_gl_base_scene_object : TGLBaseSceneObject;
begin

  if Start_Stop_Button.Tag <> 1 then // Gdy nie ma aktywnej gry nie mo¿na wydawaæ poleceñ zwi¹zanych z rozgrywk¹. //???
    Exit;


  zt_gl_base_scene_object := Gra_GLSceneViewer.Buffer.GetPickedObject( x, y );

  if    ( zt_gl_base_scene_object <> nil )
    and ( zt_gl_base_scene_object.Parent <> nil )
    and ( zt_gl_base_scene_object.Parent is TPlaneta ) then
    begin

      {$region 'Wariant 1.'}
      //// Sprawdza czy jakaœ planeta gracza jest zaznaczona.
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
      ////---// Sprawdza czy jakaœ planeta gracza jest zaznaczona.
      //
      //
      //if    ( planeta_gracza_zaznaczona )
      //  and ( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona ) then
      //  begin
      //
      //    // Wysy³a rakiety na planetê.
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
      //    // Zaznacza planetê gracza.
      //
      //    zti := TPlaneta(zt_gl_base_scene_object.Parent).id_planeta;
      //    planeta_klikniêta_zaznaczona := TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona;
      //
      //    //TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona := not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona;
      //    TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona );
      //
      //
      //    // Odznacza pozosta³e planety.
      //    if    ( not planeta_klikniêta_zaznaczona )
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

      // Sprawdza czy jakaœ planeta jest zaznaczona.
      planety_zaznaczona_wiêcej_ni¿_jedna := false;
      id_planeta_zaznaczona := -99;

      for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
        if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
          begin

            if id_planeta_zaznaczona <> -99 then
              begin

                planety_zaznaczona_wiêcej_ni¿_jedna := true;
                Break;

              end;
            //---//if id_planeta_zaznaczona <> -99 then

            if id_planeta_zaznaczona = -99 then // Zapamiêtuje tylko id pierwszej zaznaczonej planety.
              id_planeta_zaznaczona := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta;

          end;
        //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)
      //---// Sprawdza czy jakaœ planeta jest zaznaczona.


      if   ( ssShift in Shift ) // Z Shift zaznacza - odznacza klikniêt¹ planetê.
        or ( Button = TMouseButton.mbRight )
        //or (
        //         (  not ( ssShift in Shift )  )
        //     and ( id_planeta_zaznaczona = -99 ) // Gdy nie ma zaznaczonych planet to zaznacza klikniêt¹ planetê.
        //   )
        //or ( // Gdy klikniêto jedyn¹ zaznaczon¹ planetê to j¹ odznacza.
        //         (  not ( ssShift in Shift )  )
        //     and ( not planety_zaznaczona_wiêcej_ni¿_jedna )
        //     and ( TPlaneta(zt_gl_base_scene_object.Parent).id_planeta = id_planeta_zaznaczona )
        //   ) then
        or (
                 (  not ( ssShift in Shift )  )
             and (
                      ( id_planeta_zaznaczona = -99 ) // Gdy nie ma zaznaczonych planet to zaznacza klikniêt¹ planetê.
                   or ( // Gdy klikniêto jedyn¹ zaznaczon¹ planetê to j¹ odznacza.
                            ( not planety_zaznaczona_wiêcej_ni¿_jedna )
                        and ( TPlaneta(zt_gl_base_scene_object.Parent).id_planeta = id_planeta_zaznaczona )
                      )
                 )
           ) then
        begin

          // Zaznacza planetê.

          if   ( TPlaneta(zt_gl_base_scene_object.Parent).id_grupa = id_grupa_gracza_c )
            or (  TPlaneta(zt_gl_base_scene_object.Parent).Rakiety_Na_Orbicie_Iloœæ( id_grupa_gracza_c ) > id_grupa_neutralna_c  ) then
            TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona )
          else
          if   ( TPlaneta(zt_gl_base_scene_object.Parent).id_grupa <> id_grupa_gracza_c )
            or ( TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona ) then // Odznacza planetê innej grupy, na której ju¿ nie ma rakiet gracza.
            TPlaneta(zt_gl_base_scene_object.Parent).Zaznaczenie_Ustaw( false );

          zaznaczanie_ruchem_myszy__opóŸnienie__zaznacze_data_czas := Now();

        end
      else//if   ( ssShift in Shift ) (...)
      if not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona then
        begin

          // Wysy³a rakiety na planetê.

          zts := '-99';

          for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
              and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
              begin

                zts := zts +
                  ', ' + IntToStr( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).id_planeta );

              end;
            //---//if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta ) (...)


          //ostatni_ruch_ponów__id_planeta_z__4 := ostatni_ruch_ponów__id_planeta_z__3;
          //ostatni_ruch_ponów__id_planeta_z__3 := ostatni_ruch_ponów__id_planeta_z__2;
          //ostatni_ruch_ponów__id_planeta_z__2 := ostatni_ruch_ponów__id_planeta_z__1;
          ostatni_ruch_ponów__id_planeta_z__1 := zts;

          //ostatni_ruch_ponów__planeta_docelowa__4 := ostatni_ruch_ponów__planeta_docelowa__3;
          //ostatni_ruch_ponów__planeta_docelowa__3 := ostatni_ruch_ponów__planeta_docelowa__2;
          //ostatni_ruch_ponów__planeta_docelowa__2 := ostatni_ruch_ponów__planeta_docelowa__1;
          ostatni_ruch_ponów__planeta_docelowa__1 := TPlaneta(zt_gl_base_scene_object.Parent);


          Rakiety_Cel_Ustaw( id_grupa_gracza_c, zts, TPlaneta(zt_gl_base_scene_object.Parent) );

        end;
      //---//if not TPlaneta(zt_gl_base_scene_object.Parent).zaznaczona then

    end
  else//if    ( zt_gl_base_scene_object <> nil ) (...)
    if    ( Button <> TMouseButton.mbRight )
      and (  not ( ssShift in Shift )  ) then
      for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do // Klikniêcie poza planetê odznacza wszystkie planety.
        if    ( Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta )
          and ( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).zaznaczona ) then
          TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).Zaznaczenie_Ustaw( false );

end;//---//Gra_GLSceneViewerMouseDown().

//Gra_GLSceneViewerMouseMove().
procedure TPlanety_Form.Gra_GLSceneViewerMouseMove( Sender: TObject; Shift: TShiftState; X, Y: Integer );
begin

   if    ( ssRight in Shift )
     and ( System.DateUtils.MilliSecondsBetween( Now(), zaznaczanie_ruchem_myszy__opóŸnienie_data_czas ) > 300 )
     and ( System.DateUtils.MilliSecondsBetween( Now(), zaznaczanie_ruchem_myszy__opóŸnienie__zaznacze_data_czas ) > 1000 ) then
     begin

       Gra_GLSceneViewerMouseDown( Sender, TMouseButton.mbRight, Shift, X, Y );

       zaznaczanie_ruchem_myszy__opóŸnienie_data_czas := Now();

     end;
   //---//if    ( ssRight in Shift ) (...)

end;//---//Gra_GLSceneViewerMouseMove().

//Mapa_ComboBoxChange().
procedure TPlanety_Form.Mapa_ComboBoxChange( Sender: TObject );
var
  i : integer;
begin

  SetLength( kolor_grupa_r_t, 0 ); // Przy zmianie mapy czyœci tablicê wylosowanych kolorów dla grup.

  Walka_Efekt_Zwolnij_Wszystkie();
  Rakiety_Zwolnij_Wszystkie();
  Mapa_Zwolnij();
  Mapa_Utwórz();


  {$IFDEF si_fann_u¿ywaj}
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
  licznik_sprawdzeñ,
  mapa_indeks
    : integer;
begin

  if Mapa_ComboBox.Items.Count <= 0 then
    Exit;


  if Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count then
    begin

      mapa_indeks := Random( Mapa_ComboBox.Items.Count );

      licznik_sprawdzeñ := 1;

      while ( mapa_rozegrana_t[ mapa_indeks ] )
        and ( licznik_sprawdzeñ <= 1000 + Mapa_ComboBox.Items.Count * 10 ) do
        begin

          inc( licznik_sprawdzeñ );

          mapa_indeks := Random( Mapa_ComboBox.Items.Count );

        end;
      //---//while licznik_sprawdzeñ < 1000 do


      if not mapa_rozegrana_t[ mapa_indeks ] then
        begin

          mapa_rozegrana_t[ mapa_indeks ] := true; // Oznacza aby nie losowa³ tej mapy ponownie.

          Mapa_ComboBox.ItemIndex := mapa_indeks;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo³uje siê Mapa_ComboBoxChange().

        end
      else//if not mapa_rozegrana_t[ mapa_indeks ] then
        begin

          licznik_sprawdzeñ := 0;

          for mapa_indeks := 0 to Length( mapa_rozegrana_t ) - 1 do
            if mapa_rozegrana_t[ mapa_indeks ] then
              inc( licznik_sprawdzeñ );

          if licznik_sprawdzeñ = Length( mapa_rozegrana_t ) then
            begin

              //if Komunikat_Wyœwietl( 'Rozgrywano ju¿ grê na wszystkich mapach czy rozpocz¹æ losowania od pocz¹tku?' + #13 + #13 + 'Das Spiel wurde bereits auf allen Karten gespielt, möchtest du die Ziehung noch einmal beginnen?' + #13 + #13 + 'The game has already been played on all maps, do you want to start the draw all over again?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) = IDYES then
              if Komunikat_Wyœwietl( 'Wszystkie mapy zosta³y ju¿ wylosowane czy rozpocz¹æ losowania od pocz¹tku?' + #13 + #13 + 'Alle Karten wurden bereits gezeichnet, beginnen die Auslosung von vorne?' + #13 + #13 + 'All maps have already been drawn, start the draw from the beginning?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) = IDYES then
                begin

                  for mapa_indeks := 0 to Length( mapa_rozegrana_t ) - 1 do
                    mapa_rozegrana_t[ mapa_indeks ] := false;

                  Mapa_Losuj_BitBtnClick( Sender );

                end;
              //---//

            end
          else//if licznik_sprawdzeñ = Length( mapa_rozegrana_t ) then
            Komunikat_Wyœwietl( 'Nie uda³o siê wylosowaæ nowej mapy.' + #13 + #13 + 'Fehler beim Zeichnen einer neuen Karte.' + #13 + #13 + 'Failed to draw a new map.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );

        end;
      //---//if not mapa_rozegrana_t[ mapa_indeks ] then


      Mapy_Losowe_Etykieta_Wylicz();

    end;
  //---//if Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count then

end;//---//Mapa_Losuj_BitBtnClick().

//Start_Stop_ButtonClick().
procedure TPlanety_Form.Start_Stop_ButtonClick( Sender: TObject );

  //Funkcja SI_Wartoœci_Globalne_Wylicz() w Start_Stop_ButtonClick().
  procedure SI_Wartoœci_Globalne_Wylicz();
  var
    i,
    j
      : integer;
  begin

    si__odleg³oœæ_najwiêksza_miêdzy_planetami_g := -99;
    si__przyrost_szybkoœæ_planety_najwiêkszy_g := -99;
    si__wielkoœæ_planety_najwiêksza_g := -99;


    for i := 0 to Gra_Obiekty_GLDummyCube.Count - 1 do
      if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then
        begin

          if si__przyrost_szybkoœæ_planety_najwiêkszy_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybkoœæ then
            si__przyrost_szybkoœæ_planety_najwiêkszy_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).przyrost_szybkoœæ;

          if si__wielkoœæ_planety_najwiêksza_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X then
            si__wielkoœæ_planety_najwiêksza_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).planeta_kula_gl_sphere.Scale.X;



          for j := i to Gra_Obiekty_GLDummyCube.Count - 1 do
            if    ( Gra_Obiekty_GLDummyCube.Children[ j ] is TPlaneta )
              and (  si__odleg³oœæ_najwiêksza_miêdzy_planetami_g < TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]) )  ) then
              si__odleg³oœæ_najwiêksza_miêdzy_planetami_g := TPlaneta(Gra_Obiekty_GLDummyCube.Children[ i ]).DistanceTo( TPlaneta(Gra_Obiekty_GLDummyCube.Children[ j ]) );

        end;
      //---//if Gra_Obiekty_GLDummyCube.Children[ i ] is TPlaneta then


    if si__odleg³oœæ_najwiêksza_miêdzy_planetami_g <= 0 then
      si__odleg³oœæ_najwiêksza_miêdzy_planetami_g := 1;

    if si__przyrost_szybkoœæ_planety_najwiêkszy_g <= 0 then
      si__przyrost_szybkoœæ_planety_najwiêkszy_g := 1;

    if si__wielkoœæ_planety_najwiêksza_g <= 0 then
      si__wielkoœæ_planety_najwiêksza_g := 1;

  end;//---//Funkcja SI_Wartoœci_Globalne_Wylicz() w Start_Stop_ButtonClick().

var
  czy_pauza : boolean;
begin//Start_Stop_ButtonClick().

  if Start_Stop_Button.Tag = 1 then
    begin

      // Zakañcza grê.

      czy_pauza := not GLCadencer1.Enabled;

      if not czy_pauza then
        Pauza_ButtonClick( Sender );

      if Komunikat_Wyœwietl( 'Czy zakoñczyæ misjê?' + #13 + #13 + 'Die Mission benden?' + #13 + #13 + 'Finish the mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
        begin

          if not czy_pauza then
            Pauza_ButtonClick( Sender );

          Exit;

        end;
      //---//if Komunikat_Wyœwietl( 'Czy zakoñczyæ misjê?' + #13 + #13 + 'Die Mission benden?' + #13 + #13 + 'Finish the mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then


      Walka_Efekt_Zwolnij_Wszystkie();
      Rakiety_Zwolnij_Wszystkie();
      Mapa_Zwolnij();

      Mapa_Losuj_BitBtn.Enabled := true;


      //if not czy_pauza then // Stop w³¹cza te¿ pauzê.
      //  Pauza_ButtonClick( Sender );


      Start_Stop_Button.Tag := 0;
      Start_Stop_Button.Caption := 'Start';

    end
  else//if Start_Stop_Button.Tag = 1 then
    begin

      // Rozpoczyna grê.

      statystyki__polecenia_iloœæ__misja := 0;
      statystyki__rakiet_straconych__misja := 0;
      statystyki__rakiet_utworzonych__misja := 0;

      czy_zwyciêstwo := false;

      decyzje_gracza_g := '';
      decyzje_gracza_numer_g := 0;

      Nastêpna_Misja_Button.Enabled := false;
      Mapa_Losuj_BitBtn.Enabled := false;


      Walka_Efekt_Zwolnij_Wszystkie();
      Rakiety_Zwolnij_Wszystkie();
      Mapa_Zwolnij();


      if not Mapa_Utwórz() then
        begin

          Rakiety_Zwolnij_Wszystkie();
          Exit;

        end;
      //---//if not Mapa_Utwórz() then


      GLCadencer1.CurrentTime := 0;
      przyrost__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      si_decyduj__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      zwalczanie_poza_orbit¹__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;
      zwyciêstwo_sprawdŸ__ostatnie_przeliczenie_g := GLCadencer1.CurrentTime;


      Start_Stop_Button.Tag := 1;
      Start_Stop_Button.Caption := 'Stop';


      SI_Wartoœci_Globalne_Wylicz();


      if    ( Length( mapa_rozegrana_t ) = Mapa_ComboBox.Items.Count )
        and ( not mapa_rozegrana_t[ Mapa_ComboBox.ItemIndex ] ) then
        mapa_rozegrana_t[ Mapa_ComboBox.ItemIndex ] := true;

      Mapy_Losowe_Etykieta_Wylicz();


      if Informacja_GLHUDText.Visible then
        Informacja_GLHUDText.TagFloat := GLCadencer1.CurrentTime; // Gdy czas GLCadencer1 zostanie wyzerowany czas wyœwietlania komunikatu mo¿e byæ z poprzedniego odliczania.


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
  //    'Klawiatura numeryczna: Del - obrót kamery mysz¹' + #13 +
  //    'X - odznacz wszystkie planety' + #13 +
  //    'F11 - opcje zwiñ / rozwiñ' + #13 +
  //    'F12 - opcje wyœwietl / ukryj' + #13 +
  //    'P, Pause Break - pauza' + #13 +
  //    'E - pe³ny ekran' + #13 +
  //    'F1 - ponów ostatni ruch' + #13 +
  //    //'F1, F2, F3, F4 - ponów ostatnie ruchy' + #13 +
  //    'F2, F3, F4 - ponów zapamiêtany ruch' + #13 +
  //    'Shift + F2, F3, F4 - zapamiêtaj ostatni ruch' + #13 +
  //    '+, -, * - prêdkoœæ gry zwiêksz, zmniejsz, domyœlna' + #13 +
  //    'Q - przestaw procent wysy³anych rakiet z planet miêdzy 50% i 100%' + #13 +
  //    //'K, klawiatura numeryczna: 2 - resetuj kamerê' + #13 +
  //    'K - resetuj kamerê' + #13 +
  //    'Klawiatura numeryczna: 1, 3, 4, 5, 6, 7, 8, 9 - ruch kamery' + #13 +
  //    '1 .. 0 - ustaw procent wysy³anych rakiet z planet' + #13 +
  //    'Esc - wyjœcie' + #13 +
  //    'A - zaznacz wszystkie swoje planety' + #13 +
  //    '? - pomoc' + #13 +
  //    'LPM - zaznacz, odznacz planetê / wyœlij rakiety' + #13 +
  //    'Shift + LPM, PPM - zaznacz, odznacz planetê' + #13 +
  //    'PPM [trzymaj i wskazuj planety] - zaznacz, odznacz planetê' + #13 +
  //    'Ctrl + A - zaznacz wszystkie swoje planety i planety, na orbitach których masz rakiety'
  //  );

  ShowMessage
    (
      'Klawiatura numeryczna: Del - obrót kamery mysz¹' + #13 +
        '        Drehung der Kamera mit der Maus (Numerische Tastatur: Entf)' + #13 +
        '        rotation of the camera with the mouse (Numeric keyboard: Del)' + #13 +
      'X - odznacz wszystkie planety <Alle Planeten abwählen> <deselect all planets>' + #13 +
      'F11 - opcje zwiñ / rozwiñ <Optionen zuklappen / erweitern> <collapse / expand options>' + #13 +
      'F12 - opcje wyœwietl / ukryj <Optionen ein-/ausblenden> <show / hide options>' + #13 +
      'P, Pause Break - pauza <Pause> <pause>' + #13 +
      'E - pe³ny ekran <Vollbildschirm> <full screen>' + #13 +
      'F1 - ponów ostatni ruch <Wiederhole deinen letzten Zug> <redo your last move>' + #13 +
      //'F1, F2, F3, F4 - ponów ostatnie ruchy <Wiederhole deine letzten Züge> <redo your last moves>' + #13 +
      'F2, F3, F4 - ponów zapamiêtany ruch' + #13 +
        '        Wiederholen Sie die gespeicherte Bewegung' + #13 +
        '        redo the memorized movement' + #13 +
      'Shift + F2, F3, F4 - zapamiêtaj ostatni ruch' + #13 +
        '        Erinnere dich an den letzten Zug (Umschalttaste)' + #13 +
        '        remember the last move' + #13 +
      '+, -, * - prêdkoœæ gry zwiêksz, zmniejsz, domyœlna' + #13 +
        '        Spielgeschwindigkeit erhöhen, verringern, Standard' + #13 +
        '        game speed increase, decrease, default' + #13 +
      'Q - przestaw procent wysy³anych rakiet z planet miêdzy 50% i 100%' + #13 +
        '        Prozentsatz der von Planeten gesendeten Raketen zwischen 50% und 100 % wechseln' + #13 +
        '        switch percentage of rockets sent from planets between 50% and 100%' + #13 +
      //'K, klawiatura numeryczna: 2 - resetuj kamerê <Kamera zurücksetzen> <reset camera>' + #13 +
      'K - resetuj kamerê <Kamera zurücksetzen> <reset camera>' + #13 +
      'Klawiatura numeryczna: 1, 3, 4, 5, 6, 7, 8, 9 - ruch kamery' + #13 +
        '        Kamerabewegung (Numerische Tastatur)' + #13 +
        '        camera movement (Numeric keypad)' + #13 +
      '1 .. 0 - ustaw procent wysy³anych rakiet z planet' + #13 +
        '        Stellen Sie den Prozentsatz der von Planeten verschifften Raketen ein' + #13 +
        '        set the percentage of rockets sent from planets' + #13 +
      'Esc - wyjœcie <Ausgang> <Exit>' + #13 +
      'A - zaznacz wszystkie swoje planety <Wähle alle deine Planeten aus <select all your planets>' + #13 +
      '? - pomoc <Hilfe> <help>' + #13 +
      'LPM - zaznacz, odznacz planetê / wyœlij rakiety' + #13 +
        '        Planeten auswählen, abwählen / Raketen senden (LMB)' + #13 +
        '        select, deselect planet / send rockets (LMB)' + #13 +
      'Shift + LPM, PPM - zaznacz, odznacz planetê' + #13 +
        '        Planeten auswählen, abwählen (Umschalttaste + LMB, RMB)' + #13 +
        '        select, deselect planet (LMB, RMB)' + #13 +
      'PPM [trzymaj i wskazuj planety] - zaznacz, odznacz planetê' + #13 +
        '        [halte und zeige auf Planeten ] - einen Planeten auswählen, abwählen (RMB)' + #13 +
        '        [hold and indicate planets] - select, deselect a planet (RMB)' + #13 +
      'Ctrl + A - zaznacz wszystkie swoje planety i planety, na orbitach których masz rakiety' + #13 +
        '        Wählen Sie alle Ihre Planeten und Planeten aus, auf denen Sie Raketen haben (Strg)' + #13 +
        '        select all your planets and planets in which you have rockets'
    );

  if not czy_pauza then
    Pauza_ButtonClick( Sender );

end;//---//Pomoc_BitBtnClick().

//Nastêpna_Misja_ButtonClick().
procedure TPlanety_Form.Nastêpna_Misja_ButtonClick( Sender: TObject );
var
  i,
  zti
    : integer;
begin

  if Start_Stop_Button.Tag = 1 then
    Start_Stop_ButtonClick( Sender );

  if Start_Stop_Button.Tag = 1 then
    Exit; // Je¿eli nie bêdzie zezwolenia na zakoñczenie aktywnej gry.


  if not Mapa_Wybieraj_Losowo_CheckBox.Checked then
    begin

      if Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 then
        begin

          if Komunikat_Wyœwietl( 'Jest to ostatnia misja czy przejœæ do pierwszej misji?' + #13 + #13 + 'Es ist die letzte Mission, gehen zur ersten Mission?' + #13 + #13 + 'It is the last mission, go to the first mission?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
            Exit;

          Mapa_ComboBox.ItemIndex := 0;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo³uje siê Mapa_ComboBoxChange().


          for i := 0 to Length( mapa_rozegrana_t ) - 1 do
            mapa_rozegrana_t[ i ] := false;

          Mapy_Losowe_Etykieta_Wylicz();

        end
      else//if Mapa_ComboBox.ItemIndex >= Mapa_ComboBox.Items.Count - 1 then
        begin

          Mapa_ComboBox.ItemIndex := Mapa_ComboBox.ItemIndex + 1;
          Mapa_ComboBoxChange( Sender ); // Po zmianie Mapa_ComboBox.ItemIndex nie wywo³uje siê Mapa_ComboBoxChange().

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

          if Komunikat_Wyœwietl( 'Jest to ostatnia misja czy rozpocz¹æ losowania od pocz¹tku?' + #13 + #13 + 'Es ist die letzte Mission, die Auslosung noch einmal zu beginnen?' + #13 + #13 + 'It is the last mission start the draw all over again?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
            Exit;


          for i := 0 to Length( mapa_rozegrana_t ) - 1 do
            mapa_rozegrana_t[ i ] := false;

          //Mapy_Losowe_Etykieta_Wylicz(); // Jest wywo³ane w Mapa_Losuj_BitBtnClick().

        end;
      //---//if zti = Length( mapa_rozegrana_t ) then

      zti := Mapa_ComboBox.ItemIndex;

      Mapa_Losuj_BitBtnClick( Sender );

      if zti <> Mapa_ComboBox.ItemIndex then
        zti := -2 // Oznacza, ¿e wylosowano now¹ misjê.
      else//if zti <> Mapa_ComboBox.ItemIndex then
        zti := 0;

    end;
  //---//if not Mapa_Wybieraj_Losowo_CheckBox.Checked then



  statystyki__polecenia_iloœæ__gra := statystyki__polecenia_iloœæ__gra + statystyki__polecenia_iloœæ__misja;
  statystyki__rakiet_straconych__gra := statystyki__rakiet_straconych__gra + statystyki__rakiet_straconych__misja;
  statystyki__rakiet_utworzonych__gra := statystyki__rakiet_utworzonych__gra + statystyki__rakiet_utworzonych__misja;


  if   ( not Mapa_Wybieraj_Losowo_CheckBox.Checked )
    or (
             ( Mapa_Wybieraj_Losowo_CheckBox.Checked )
         and ( zti = -2 )
       ) then
    Start_Stop_ButtonClick( Sender );

end;//---//Nastêpna_Misja_ButtonClick().

//Ruch_Ostatni_Ponów_ButtonClick().
procedure TPlanety_Form.Ruch_Ostatni_Ponów_ButtonClick( Sender: TObject );
begin

  Rakiety_Cel_Ustaw( id_grupa_gracza_c, ostatni_ruch_ponów__id_planeta_z__1, ostatni_ruch_ponów__planeta_docelowa__1 );

end;//---//Ruch_Ostatni_Ponów_ButtonClick().

//Statystyki_ButtonClick().
procedure TPlanety_Form.Statystyki_ButtonClick( Sender: TObject );
begin

  Statystyki_Wyœwietl( {false,} false, id_grupa_neutralna_c );

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

      if TComponent(Sender).Name = Gra_Prêdkoœæ_SpinEdit.Name then
        zts := 'Prêdkoœæ gry ' + Trim(  FormatFloat( '### ### ##0', Gra_Prêdkoœæ_SpinEdit.Value )  ) + '%'
      else
      if TComponent(Sender).Name = Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Name then
        zts := 'Rakiety ' + Trim(  FormatFloat( '### ### ##0', Rakiety_Iloœæ_Procent_Wys³anie_SpinEdit.Value )  ) + '%';

      if zts <> '' then
        Informacja_Wyœwietl( zts );


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

//SI_Trudnoœæ_ButtonClick().
procedure TPlanety_Form.SI_Trudnoœæ_ButtonClick( Sender: TObject );
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

end;//---//SI_Trudnoœæ_ButtonClick().

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

      Komunikat_Wyœwietl( 'Brak zapamiêtanych decyzji gracza.' + #13 + #13 + 'Entscheidungen des Spielers werden nicht gespeichert.' + #13 + #13 + 'Player''s decisions are not remembered.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if Trim( decyzje_gracza_g ) = '' then


  zts := ExtractFilePath( Application.ExeName ) + decyzje_gracza__katalog_nazwa_c;

  if not DirectoryExists( zts ) then
    begin

      Komunikat_Wyœwietl( PChar('Nie odnaleziono podkatalogu ''' + decyzje_gracza__katalog_nazwa_c + '''.' + #13 + #13 + 'Unterverzeichnis nicht gefunden.' + #13 + #13 + 'Subdirectory not found.'), 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if not DirectoryExists( zts ) then


  if Komunikat_Wyœwietl( 'Czy zapisaæ dane o decyzjach gracza do pliku?' + #13 + #13 + 'Die Entscheidungsdaten des Players in einer Datei speichern?' + #13 + #13 + 'Save the decision data of the player in a file?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON1 + MB_ICONQUESTION ) <> IDYES then
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


  Komunikat_Wyœwietl( 'Zapis do pliku zakoñczony (' + zts + ').' + #13 + #13 + #13 + 'Schreiben in Datei abgeschlossen.' + #13 + #13 + 'Writing to file completed.', 'Informacja', MB_OK + MB_ICONINFORMATION );


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
    if TComponent(Sender).Name = Grupa_Fann_Decyduje__Odwróæ_Zaznaczenie_Button.Name then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := not Grupa_Fann_Decyduje_CheckListBox.Checked[ i ]
    else//if TComponent(Sender).Name = Grupa_Fann_Decyduje__Odwróæ_Zaznaczenie_Button.Name then
      Grupa_Fann_Decyduje_CheckListBox.Checked[ i ] := TComponent(Sender).Name = Grupa_Fann_Decyduje__Zaznacz_Wszystko_Button.Name;

end;//---//Grupa_Fann_Decyduje__Zaznacz_ButtonClick().

//FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_ButtonClick().
procedure TPlanety_Form.FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_ButtonClick( Sender: TObject );
begin

  if FANN__Opcje_Dodatkowe_GroupBox.Height <> 35 then
    FANN__Opcje_Dodatkowe_GroupBox.Height := 35
  else//if FANN__Opcje_Dodatkowe_GroupBox.Height <> 35 then
    FANN__Opcje_Dodatkowe_GroupBox.Height := 275; //???

end;//---//FANN__Opcje_Dodatkowe__Wysokoœæ_Zmieñ_ButtonClick().

//FANN__Przygotuj_ButtonClick().
procedure TPlanety_Form.FANN__Przygotuj_ButtonClick( Sender: TObject );
begin

  {$IFDEF si_fann_u¿ywaj}
  FANN_Przygotuj();
  {$ENDIF}

end;//---//FANN__Przygotuj_ButtonClick().

//FANN__Zwolnij_ButtonClick().
procedure TPlanety_Form.FANN__Zwolnij_ButtonClick( Sender: TObject );
begin

  {$IFDEF si_fann_u¿ywaj}
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
{$IFDEF si_fann_u¿ywaj}
var
  zts : string;
{$ENDIF}
begin

  {$IFDEF si_fann_u¿ywaj}
  if fann_network = nil then
    begin

      Komunikat_Wyœwietl( 'Sieæ FANN nie zosta³a przygotowana.' + #13 + #13 + 'Das FANN-Netzwerk ist nicht vorbereitet.' + #13 + #13 + 'The FANN network has not been prepared.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if fann_network = nil then

  if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  )
    or (  Length( FANN__Plik_Nazwa_ComboBox.Text ) < 1  ) then
    begin

      PageControl1.ActivePage := SI_TabSheet;
      FANN__Plik_Nazwa_ComboBox.SetFocus();
      Komunikat_Wyœwietl( 'Nazwa pliku nie mo¿e byæ pusta.' + #13 + #13 + 'Der Dateiname darf nicht leer sein.' + #13 + #13 + 'The file name cannot be empty.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  ) (...)


  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;


  if FileExists( zts ) then
    begin

      if Komunikat_Wyœwietl( 'Plik istnieje: ' + zts + '.' + #13 + #13 + 'Czy nadpisaæ?' + #13 + #13 + #13 + 'Die Datei existiert. Überschreiben?' + #13 + #13 + 'The file exists. Overwrite?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
        Exit;

    end
  else//if FileExists( zts ) then
    if Komunikat_Wyœwietl( 'Zapisaæ plik pod nazw¹:' + #13 + zts + #13 + '?' + #13 + #13 + #13 + 'Datei unter Namen speichern?' + #13 + #13 + 'Save the file as a name?', 'Potwierdzenie', MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
      Exit;


  fann_network.SaveToFile( PWideChar(AnsiString(zts)) );


  FANN_Zapisane_Nazwy_Wyszukaj();
  {$ENDIF}

end;//---//FANN__Zapisz_ButtonClick().

//FANN__Wczytaj_ButtonClick().
procedure TPlanety_Form.FANN__Wczytaj_ButtonClick( Sender: TObject );
{$IFDEF si_fann_u¿ywaj}
var
  zts : string;
{$ENDIF}
begin

  {$IFDEF si_fann_u¿ywaj}
  if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  )
    or (  Length( FANN__Plik_Nazwa_ComboBox.Text ) < 1  ) then
    begin

      PageControl1.ActivePage := SI_TabSheet;
      FANN__Plik_Nazwa_ComboBox.SetFocus();
      Komunikat_Wyœwietl( 'Nazwa pliku nie mo¿e byæ pusta.' + #13 + #13 + 'Der Dateiname darf nicht leer sein.' + #13 + #13 + 'The file name cannot be empty.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
      Exit;

    end;
  //---//if   (  Trim( FANN__Plik_Nazwa_ComboBox.Text ) = ''  ) (...)


  if fann_network = nil then
    FANN_Przygotuj( true );


  zts := ExtractFilePath( Application.ExeName ) + fann_sieci_zapisane__katalog_nazwa_c + '\' + FANN__Plik_Nazwa_ComboBox.Text + fann_sieci_zapisane__kropka_rozszerzenie_c;


  if not FileExists( zts ) then
    begin

      Komunikat_Wyœwietl( 'Nie odnaleziono pliku:' + #13 + zts + '.' + #13 + #13 + 'Datei nicht gefunden.' + #13 + #13 + 'File not found.', 'Informacja', MB_OK + MB_ICONEXCLAMATION );
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

  // Do testów.
  //???

end;//---//Test_ButtonClick().

end.
