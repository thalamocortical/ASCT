# Diagnostyka dopasowania modelu MVAR w pakiecie MMULTAR

Rozszerzenie dokłada do obliczeń dwie standardowe kontrole jakości dopasowania
modelu MVAR: **białość reszt** (testy portmanteau) i **stabilność modelu**
(moduły wartości własnych macierzy towarzyszącej). Obie liczone są automatycznie
przy każdym dopasowaniu, wynik trafia do struktury `ARs.diag` i do pliku
`<dane>_mout.mat`, a skrót jest wypisywany w oknie komend.

## Nowe pliki

| plik | rola |
|---|---|
| `mvar_residuals.m` | reszty (błędy predykcji jednokrokowej) `e(t)=x(t)-sum_k A_k x(t-k)`; reszty liczone osobno dla każdego trialu, bez mieszania przez granice trialów |
| `mvar_stability.m` | wartości własne macierzy towarzyszącej, `max|eig|`, flaga stabilności, margines do okręgu jednostkowego |
| `mvar_whiteness.m` | testy portmanteau Li–McLeod i Hosking (wielowymiarowy Ljung–Box), jednokanałowy Ljung–Box, ACF reszt z pasmem 95%, chwilowe korelacje reszt |
| `mvar_chi2sf.m` | ogon rozkładu chi-kwadrat przez `gammainc` — **bez Statistics Toolbox** |
| `mvar_diagnostics.m` | składa powyższe w jedną strukturę i drukuje raport |
| `mvar_diag_report.m` | wydruk raportu: pojedyncze dopasowanie albo zbiorczo dla tablicy dopasowań (okna / triale) |
| `mvar_diag_fit.m` | dopasowuje model estymatorem pakietu i od razu liczy diagnostykę (do użycia samodzielnie, np. przy doborze rzędu) |
| `mvar_diag_verbose.m` | decyduje, czy raport ma iść na ekran: 1, gdy zaznaczona jest choć jedna funkcja do narysowania, 0 w przeciwnym razie |
| `test_mvar_diagnostics.m` | samotest na symulowanym procesie MVAR(3) o znanych współczynnikach |

## Zmodyfikowane pliki

- `licz_mtmvar.m` – diagnostyka po dopasowaniu, wynik w `ARs.diag`
- `licz_smtmvar.m` – diagnostyka osobno dla każdego okna, `ARs.diag` jest tablicą
  struktur (jeden element na okno) plus zbiorcze podsumowanie
- `licz_mtmvarBoots.m`, `licz_smtmvarBoots.m` – diagnostyka modelu dopasowanego do
  pełnych danych (nie do pojedynczych prób bootstrapowych), pole `ARs.diag`
- `plot_mult_ar.m`, `plot_smult_ar.m` – zapis `ARdiag` do `_mout.mat` także wtedy,
  gdy współczynniki AR nie są zapisywane (`sAR=0`); przy `sAR=1` diagnostyka jest
  już częścią zapisywanej struktury `ARs`
- `mmultar.m` – nowe pole domyślne `diagnost` (1 = licz diagnostykę).
  Kod sprawdza pole przez `isfield`, więc stare struktury `mv` (zapisane
  parametry, pliki `.cmd`) działają bez zmian — brak pola oznacza "licz".
- `multargui.m` – checkbox **Model diagnostics** w oknie dialogowym

## Checkbox w multargui

Przełącznik „Model diagnostics" siedzi w wolnym polu pod panelem wyboru funkcji
do zapisu (`uipanel8`), nad przyciskiem *Run MULTAR*, wraz z czterolinijkowym
opisem. Zaznaczenie odpowiada `mv.diagnost=1`.

Kontrolka jest tworzona **programowo** w `multargui_OpeningFcn`, a nie w GUIDE —
dzięki temu binarny plik `multargui.fig` pozostaje nietknięty i nie trzeba
otwierać GUIDE, żeby zmianę nanieść albo cofnąć. Okno ma `Units='characters'`
i `Resize='off'`, więc pozycja `[124.6 11.5 38.0 1.4]` jest stała; sprawdzone
programowo, że prostokąty nowej kontrolki i opisu nie zachodzą na żadną z 86
kontrolek zapisanych w `.fig`.

Co dokładnie doszło do `multargui.m`:

1. `multargui_OpeningFcn` – uzupełnienie `mv.diagnost=1`, gdy pole nie istnieje,
   oraz utworzenie `handles.checkbox_diagnost` i `handles.text_diagnost`;
   callback podpięty napisem w konwencji GUIDE
   (`multargui('checkbox_diagnost_Callback',gcbo,[],guidata(gcbo))`).
2. `values_update` – ustawianie stanu checkboxa z `mv.diagnost` (przez `isfield`,
   więc wczytanie starego pliku parametrów daje stan „zaznaczony").
3. `checkbox_diagnost_Callback` – nowa podfunkcja zapisująca stan do
   `handles.multdata.diagnost`.
4. `pushbutton5_Callback` (Load) – uzupełnienie `mv.diagnost` dla starych plików
   `.mat` z parametrami, tak samo jak jest to już robione dla `userange`
   i `pautoflag`.

Zapis parametrów (*Save*) zachowuje pole automatycznie, bo zapisuje całą
strukturę `mv`. Kopia zapasowa GUI `multarguikopia.m`/`.fig` nie była ruszana —
`mmultar.m` uruchamia `multargui`.

Aby wyłączyć diagnostykę: odznaczyć checkbox w oknie albo ustawić `mv.diagnost=0`
w trybie wsadowym.

## Kiedy raport trafia na ekran

Wydruk raportu idzie za oknami wyników: jeżeli nie jest zaznaczona **żadna**
funkcja do narysowania (wszystkie flagi `pSpect`, `pCohs`, `pDTF`, `pNDTF`,
`pdDTF`, `pPDC`, `pffDTF` są zerowe — przebiegi wsadowe, przebiegi „tylko
zapis"), diagnostyka jest nadal liczona i zapisywana w `ARs.diag` / `ARdiag`,
ale w oknie komend nie pojawia się nic. Reguła siedzi w jednym miejscu,
`mvar_diag_verbose.m`, i jest używana przez wszystkie cztery ścieżki obliczeń.

Są to dwa niezależne przełączniki:

| | `mv.diagnost=1` | `mv.diagnost=0` |
|---|---|---|
| **jakakolwiek flaga `p*` włączona** | liczone + raport na ekranie | nie liczone |
| **wszystkie flagi `p*` wyłączone** | liczone, zapisane, bez wydruku | nie liczone |

Sprawdzone na `sym3k.dat` (p=4): przy rysowaniu włączonym i wyłączonym
`ARs.diag` zawiera te same wartości (`max|eig| = 0.7984`, Li-McLeod `p = 0.7217`),
a w drugim przypadku na ekran nie idzie ani jedna linia — tak samo w trybie
krótkoczasowym, gdzie wszystkie 4 okna są policzone, a podsumowanie zbiorcze
pominięte.

## Co jest raportowane

```
--- MVAR diagnostics sym3k.dat p=4 ---
  model     : p=4, channels=3, 1026 point(s) x 1 trial(s), 36 coefficients,
              28.5 data points per coefficient
  stability : max|eig(companion)|=0.7984  ->  STABLE (margin 0.2016, 0 eigenvalue(s) outside)
  whiteness : lags h=20, df=144, N=1022 residual points
              Li-McLeod Q=133.6, p=0.7217  ->  white residuals (H0 not rejected) at alpha=0.05
              Hosking   Q=133.3, p=0.7276
              acf values outside +-0.0613 band: 1.7% (expected ~5%)
              max |instantaneous residual correlation| = 0.081
  VERDICT   : model acceptable - stable and residuals indistinguishable from white noise.
```

Pola struktury `ARs.diag`:

- `stability.max_modulus`, `.stable`, `.margin`, `.eigenvalues`, `.n_outside`
- `whiteness.LiMcLeod`, `.p_LiMcLeod`, `.Hosking`, `.p_Hosking`, `.df`, `.h`, `.N`,
  `.white`, `.LB_chan`, `.p_LB_chan`, `.chan_nonwhite`, `.acf`, `.acf_band`,
  `.frac_out`, `.V`, `.Rinst`, `.max_abs_inst`
- `V_res` – macierz kowariancji reszt policzona z reszt (porównywalna z `ARs.V`)
- `pts_per_param` – liczba punktów danych na współczynnik (powinna być >> 10)
- `ok` – 1 gdy model jest stabilny **i** białość reszt nie została odrzucona

## Podstawy

Model: `x(t) = sum_{k=1..p} A_k x(t-k) + e(t)`, konwencja zgodna z `mult_ar_calc.m`.

**Stabilność.** Macierz towarzysząca `F = [A_1 ... A_p; I 0 ... 0; ...]`;
model jest stabilny (stacjonarny), gdy wszystkie `|eig(F)| < 1`. `max|eig|`
bliskie 1 oznacza model na granicy niestacjonarności — widmo, DTF i PDC z takiego
modelu są niewiarygodne.

**Białość.** `C_l = (1/N) sum_t e_t e_{t-l}'`;
statystyka Box–Pierce'a `Q = N sum_l tr(C_l' C_0^-1 C_l C_0^-1)`,
poprawka Li–McLeoda `Q_LM = Q + k^2 h(h+1)/(2N)`, wariant Hoskinga
(typu Ljung–Box) `Q_H = N^2 sum_l tr(...)/(N-l)`; obie porównywane z rozkładem
chi-kwadrat o `k^2(h-p)` stopniach swobody. Domyślnie `h = min(max(2p,20), N/4)`.
Statystyka jest niezmiennicza względem odwracalnych przekształceń liniowych
reszt, więc wynik jest identyczny dla modelu z członem chwilowym i bez niego
(`instant_caus_sub1.m`).

Literatura: Hosking (1980) JASA 75:602; Li & McLeod (1981) JRSS B 43:231;
Lütkepohl, *New Introduction to Multiple Time Series Analysis*, rozdz. 4.4.

## Weryfikacja

`test_mvar_diagnostics` symuluje znany stabilny proces MVAR(3)
(`|z|_max = 0.95`) i sprawdza, że: prawdziwy układ jest rozpoznany jako
stabilny, układ zaburzony jako niestabilny, model dopasowany przy poprawnym
rzędzie przechodzi test białości, model niedopasowany (`p=1`) go nie przechodzi,
kowariancja reszt zgadza się z `V` z estymatora, a `mvar_chi2sf` odtwarza
tablicowe kwantyle chi-kwadrat. Wszystkie testy przechodzą.

**Zachowanie w skończonej próbie.** Estymator korelacyjny (Yule–Walker, domyślny
w pakiecie) jest w krótkich odcinkach lekko obciążony, co zostawia resztkową
korelację w resztach i czyni test nieco liberalnym. Symulacja (40 realizacji
znanego MVAR(3)): przy 4000 punktach na kanał odsetek odrzuceń przy
`alpha = 0.05` wyniósł ok. 0.12, przy 16000 punktach ok. 0.075. Graniczne `p` w
krótkim oknie należy traktować jako nierozstrzygające, nie jako dowód złego modelu.

## Poprawka: wybór metody estymacji nie działał

W 12 plikach pakietu powtarzał się idiom

```matlab
METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end
```

Funkcje te przyjmują 2–4 argumenty, więc `nargin<6` było **zawsze** prawdziwe
i `meth_num` zawsze wynosiło 1 — wybór metody estymacji (`mv.method`, radiobuttony
w GUI) nie miał żadnego wpływu na obliczenia. Cały blok `if` zastąpiony został
jedną linią:

```matlab
meth_num = METHODS(method);
```

Poprawione pliki (katalog główny pakietu): `estimateModelOrder.m`,
`licz_mtmvar.m`, `licz_mtmvarBaseln.m`, `licz_mtmvarBoots.m`,
`licz_mtmvarBoots_diff.m`, `licz_mtmvarBoots_diff2.m`, `licz_mtmvar_c.m`,
`licz_smtmvar.m`, `licz_smtmvarBaseln.m`, `licz_smtmvarBoots.m`,
`licz_smtmvarBoots_diff2.m`, `licz_smtmvar_varlen.m`.

Zmienna `method` jest we wszystkich tych plikach zdefiniowana wcześniej
(`method=mv.method;`, a w `estimateModelOrder.m` jako argument funkcji), więc
usunięcie gałęzi zapasowej nie tworzy nowej ścieżki błędu. Zniknęło natomiast
ciche podstawianie wartości domyślnej: przy `mv.method` pustym lub spoza zakresu
1–4 `METHODS(method)` zgłosi teraz błąd indeksu, zamiast po cichu policzyć
metodą 1.

Kopie tych plików w podkatalogach `pakiet/`, `pakiet/3/`, `pakiet/4/`, `testgui/`
i `Nowy folder z rzeczami/` **nie** były ruszane — to archiwalne wersje pakietu.

### Skutek dla wyników

Domyślna metoda to 1, a `METHODS(1)=1`, więc **wyniki liczone dotąd z ustawieniem
domyślnym nie zmieniają się**. Sprawdzone na `sym3k.dat` (p=4): przy `mv.method=1`
`max|eig| = 0.798417` i Li-McLeod `p = 0.7217`, czyli dokładnie te same liczby co
przed poprawką. Zmieniają się tylko wyniki tych analiz, w których w GUI wybrano
metodę 2, 3 albo 4 — wcześniej taki wybór był ignorowany.

Po poprawce cztery metody dają faktycznie różne estymaty (`sym3k.dat`, p=4):

| `mv.method` | `iwhat` | estymator | `max\|eig\|` | Li-McLeod p | `relerr(V_est, V_reszt)` |
|---|---|---|---|---|---|
| 1 | 1 | korelacyjny (Yule–Walker) | 0.798417 | 0.7217 | 0.0063 |
| 2 | 2 | zmodyfikowany korelacyjny | 0.799198 | 0.7219 | 0.0043 |
| 3 | 4 | kowariancyjny | 0.798263 | 0.7316 | 1.1e-15 |
| 4 | 8 | zmodyfikowany kowariancyjny | 0.802992 | 7.7e-09 | 0.080 |

### Poprawka: `countCorrSav` nie normalizował danych

`countCorrSav.m` miało sygnaturę `(x,ip,iwhat)` i w ogóle nie normalizowało
danych, podczas gdy jego odpowiednik `countCorr.m` przyjmuje `mv` i stosuje
flagi `norm0`/`norm1`/`norm2`. Dwa miejsca w pakiecie
(`licz_smtmvarBoots.m`, `licz_mtmvarBoots_diff.m`) wołały je mimo to
z czwartym argumentem `mv`, co w MATLAB-ie kończyło się błędem
„Too many input arguments" — krótkoczasowy bootstrap z metodą korelacyjną
wywracał się na pierwszym oknie.

Sygnatura to teraz `countCorrSav(x,ip,iwhat,mv)` z tym samym blokiem
normalizacji co w `countCorr`, a wszystkie pięć miejsc wywołania przekazuje
`mv`. Jedna różnica wobec `countCorr`: pętle normalizacji chodzą po faktycznym
rozmiarze `x`, a nie po `mv.chans` / `mv.recl`. Wynik jest identyczny, gdy `x`
to cały zapis, natomiast w trybie krótkoczasowym — gdzie `x` jest pojedynczym
oknem krótszym niż `mv.recl` — wersja z `mv.recl` wychodziłaby poza zakres.

### Poprawka: `norm2` w `countCorr.m` wychodziło poza zakres okna

Ten sam błąd granicy pętli siedział w `countCorr.m`. Blok `norm2` (dzielenie
przez średnią po realizacjach) biegł `for nn=1:mv.recl` i `for cc=1:lc`, gdzie
`lc=mv.chans`, podczas gdy w trybie krótkoczasowym `x` jest pojedynczym oknem
krótszym niż `mv.recl`. Granice pochodzą teraz z faktycznego rozmiaru `x`
(`m` kanałów, `n` punktów), wyliczanego i tak na początku funkcji:

```matlab
for nn=1:n
    for cc=1:m
```

Co to zmienia — sprawdzone na oknie 150 punktów z zapisu 342-punktowego,
3 kanały × 3 triale, `norm2=1`:

1. Wywołanie z `mv.recl=342` (dokładnie tak, jak przekazuje `licz_smtmvar`)
   przechodzi; wcześniej kończyło się błędem indeksu — kontrolnie odtworzona
   stara pętla zgłasza `y(_,151,_): out of bound 150`.
2. Wynik nie zależy już od `mv.recl`: macierze z `mv.recl=342` i `mv.recl=150`
   są identyczne co do bitu.
3. Zachowanie na pełnym zapisie się nie zmieniło: `countCorr` z `norm2=1` daje
   dokładnie to samo co ta sama funkcja z `norm2=0` nakarmiona danymi
   znormalizowanymi z zewnątrz.

Bloki `norm0` i `norm1` nadal używają `lc=mv.chans`. W żywym pipelinie
`mv.chans` zawsze równa się `size(x,1)` (kanały są wybierane w `multar1m`
przed wywołaniem), więc nie ma tam skutku — ale to ten sam idiom i można go
wyrównać do `m`, jeśli chcesz.

`countCovSav` zostawiony bez zmian — jego odpowiednik `countCov` też nie
przyjmuje `mv` i nie normalizuje.

Sprawdzenie równoważności (3 kanały × 342 punkty × 3 triale, do każdego kanału
i trialu dodana stała, żeby `norm0` nie był operacją pustą):

| `iwhat` | `rleft` | `rright` | `r` |
|---|---|---|---|
| 1 | 0 | 0 | 0 |
| 2 | 0 | 0 | 0 |

— względna różnica między `mean(countCorrSav(...),3)` a `countCorr(...)` jest
dokładnie zerowa, czyli obie drogi liczą teraz z tych samych danych. Kontrolnie,
przy wyłączonej normalizacji w `countCorrSav` ta sama różnica wynosi 284, więc
poprawka jest istotna, a nie kosmetyczna.

Po obu poprawkach przechodzą do końca ścieżki, które wcześniej się wywracały:
`licz_smtmvarBoots` z metodą 1 i 2 (3 okna, wszystkie stabilne, białość
nieodrzucona) oraz `licz_mtmvarBoots`.

### Poprawka: wczesne wyjścia nie przypisywały wyjścia `ARs`

Pięć gałęzi wczesnego wyjścia przypisywało nazwy sprzed refaktoryzacji
(`fun`, `AR_tot`, `H_tot`), ale nigdy zadeklarowanego wyjścia `ARs`:

| plik | linia | warunek |
|---|---|---|
| `licz_mtmvarBoots.m` | 22 | `trials==1`, `errordlg('Only one trial available for bootstrap')` |
| `licz_smtmvar.m` | 28, 39 | `'Illegal window length'`, `'Illegal number of windows'` |
| `licz_smtmvarBoots.m` | 31, 42 | jak wyżej |

Sygnatury deklarują `[s,h,a,ARs]` albo `[fun,ARs]`, więc zamiast komunikatu
i spokojnego powrotu do GUI MATLAB zgłaszał „Output argument ARs ... not
assigned". W każdym z pięciu miejsc dopisane zostało `ARs=[];`. Zmiana nie
dotyka żadnych obliczeń — nazwy `AR_tot` i `H_tot` zostawione bez zmian, bo
w dalszej części tych funkcji są normalnymi zmiennymi roboczymi.

Sprawdzone: wszystkie pięć ścieżek wywołanych z kompletem argumentów
wyjściowych wraca teraz bez błędu, z pustym `ARs`.

### Poprawka: `prctile(V_boot,...)` liczyło percentyle wzdłuż złego wymiaru

`V_boot` jest wszędzie deklarowane jako `zeros(chans,chans,bootnum)`, więc
wymiarem bootstrapowym jest **3**. Czwórka jest poprawna dla `AR_boot`
(`chans × chans × p × bootnum`) i `H_boot` (`chans × chans × FRQPMAX × bootnum`),
ale nie dla `V_boot`; docelowe `V_tot` oczekuje percentyli w wymiarze 3.
Zmienione na `prctile(V_boot,plev,3)` w czterech miejscach:

| plik | linia |
|---|---|
| `licz_mtmvarBoots.m` | 112 |
| `licz_mtmvarBoots_diff.m` | 108 |
| `licz_mtmvarBoots_diff2.m` | 127 |
| `licz_smtmvarBoots.m` | 126 |

Zakomentowane wywołanie w `licz_smtmvarBoots_diff2.m` (linia 156) zostawione
bez zmian. Pozostałe wywołania `prctile` w tych plikach (`fun_boot` po wymiarze
5, `AR_boot` i `H_boot` po 4) były i są poprawne.

Sprawdzone przy `mv.sAR=1`, 3 kanały × 3 triale, `plev = [5 50 95]`:

- `licz_smtmvarBoots` → `size(ARs.V) = [3 3 3 2]`, czyli
  `chans × chans × length(plev) × winnum` zgodnie z deklaracją;
- `licz_mtmvarBoots` → `size(ARs.V) = [3 3 3]`;
- percentyle są uporządkowane (5% ≤ 95% element po elemencie) w obu wariantach;
- arytmetyka kształtów dla `V_boot` o rozmiarze `3×3×10`: wymiar 3 daje `[3 3 3]`
  i pasuje do gniazda, wymiar 4 dawał `[3 3 10 3]`, czyli zachowywał wszystkie
  10 prób bootstrapowych zamiast je podsumować.

Zastrzeżenie: bazowy Octave nie ma `prctile`, więc powyższe rozmiary pochodzą
z mojej implementacji zastępczej odtwarzającej udokumentowaną semantykę
`prctile(X,p,dim)`, a nie z samego MATLAB-a.

### Rozstrzygnięte: metoda 4 jest zaimplementowana poprawnie, ale źle dobrana

Sprawdzone bezpośrednio. `countCov.m` odtwarza równania normalne zbudowane
jawnie z macierzy planu **co do precyzji maszynowej**, dla obu wariantów
(3 kanały, 400 punktów, p=3, względne różnice):

| `iwhat` | `rleft` | `rright` | `r` | współczynniki | `V` |
|---|---|---|---|---|---|
| 4 (kowariancyjny) | 2.1e-16 | 4.1e-16 | 2.0e-16 | 2.1e-16 | 1.0e-16 |
| 8 (zmod. kowariancyjny) | 2.1e-16 | 1.0e-16 | 2.1e-16 | 5.4e-16 | 4.0e-16 |

Referencja: wiersz `t` macierzy planu to `[x(t-1)' ... x(t-p)']` z celem `x(t)'`
dla `t = p+1..n` (część „w przód") oraz `[x(t+1)' ... x(t+p)']` z celem `x(t)'`
dla `t = 1..n-p` (część „wstecz"); dla `iwhat=8` oba zestawy są sumowane.
Zgadzają się też zakresy sumowania (rozbite w kodzie na rdzeń
`t = p+1..n-p` plus poprawki brzegowe) i skalowanie: `1/(n-p)` dla wariantu
w przód i `1/(2(n-p))` dla forward-backward, czyli przez liczbę równań.

**Problemem jest założenie metody, nie kod.** Wariant `iwhat=8` używa do
predykcji wstecz **tych samych** macierzy `A_k` co do predykcji w przód. Dla
jednowymiarowego procesu AR o rzeczywistych współczynnikach to jest prawdą,
ale dla procesu wielowymiarowego współczynniki w przód i wstecz pokrywają się
tylko wtedy, gdy `R(k) = R(k)^T` dla każdego opóźnienia, czyli gdy proces jest
odwracalny w czasie. Układ z kierunkowym sprzężeniem — a właśnie takie bada się
w MMULTAR przez DTF i PDC — odwracalny nie jest.

Eksperyment potwierdzający, dwa znane układy MVAR(3), po 8000 punktów na kanał:

| układ | asymetria `max|R(k)-R(k)^T|/max|R|` | estymator | Li-McLeod p | `max|A-A_prawdziwe|` |
|---|---|---|---|---|
| kierunkowy `x1→x2`, `x1→x3` | 1.102 | 3 (w przód) | 0.74 | 0.035 |
| | | 4 (fwd+bwd) | 0 | **0.395** |
| diagonalny (odwracalny) | 0.017 | 3 (w przód) | 0.86 | 0.032 |
| | | 4 (fwd+bwd) | 0.74 | **0.016** |

Na układzie odwracalnym metoda 4 jest **lepsza** od metody 3 — błąd
współczynników o połowę mniejszy, bo korzysta z dwukrotnie większej liczby
równań. Na układzie kierunkowym jest o rząd wielkości gorsza i całkowicie
oblewa test białości reszt. To dokładnie tłumaczy obserwację z `sym3k.dat`
(plik symulujący układ z przepływami kierunkowymi).

**Wniosek praktyczny:** do analiz połączeń kierunkowych nie używać metody 4.
Jeśli potrzebny jest estymator forward-backward dla danych wielokanałowych,
właściwe są algorytmy utrzymujące **osobne** współczynniki w przód i wstecz —
Vieira-Morf albo Nuttall-Strand. Pakiet zawiera `viemo.m` (Vieira-Morf,
z osobnymi `ef`/`eb` i `A`/`B`) oraz `lwr.m` (Levinson-Wiggins-Robinson), ale
żaden z nich nie jest podpięty do głównego potoku obliczeń.

Kodu nie zmieniałem — nie ma w nim błędu do poprawienia.

#### Metoda 4 to teraz LWR

Metoda 4 w GUI nie liczy już zmodyfikowanego estymatora kowariancyjnego, tylko
**wielokanałowy algorytm kratowy LWR** (Levinson–Wiggins–Robinson / Morf),
który utrzymuje **osobne** predyktory w przód i wstecz, więc nie zakłada
odwracalności procesu w czasie.

Punktem wyjścia był `lwr.m` z pakietu. W stanie zastanym nie działał: na znanym
układzie MVAR(3) (3000 punktów na kanał) dawał błąd współczynników 0.5102 przy
0.0525 metody 3, a dla jednego kanału w ogóle się wywracał. Poprawione zostały
cztery rzeczy:

1. Aktualizacja predyktora wstecz liczyła `B_k − ρ' · B_{n+1−k}`; rekurencja
   Morfa wymaga tu `A_{n+1−k}`, czyli macierzy w przód.
2. Usunięty został blok przeliczania współczynników odbicia na parametry AR,
   który używał mnożenia **elementowego** (`.*`, `.^2`) — wzorów
   jednowymiarowego Levinsona. Jest zbędny: rekurencja i tak utrzymuje
   znormalizowany predyktor w przód, więc współczynniki wynikają z niego wprost,
   `Ahat_k = −A₀⁻¹ A^{(p)}_k`, a kowariancja reszt z `V = A₀⁻¹ A₀⁻ᵀ`.
3. Normalizacja startowa dzieli teraz sumy kwadratów przez liczbę składników.
   Współczynniki odbicia są niewrażliwe na skalę, ale `V` nie jest — bez tego
   wychodziła zawyżona o czynnik rzędu liczby próbek (zmierzone: 4152 zamiast
   1.038).
4. Pętla kończy się na `n = p−1`, a nie `p` — rekurencja budowała o jeden rząd
   za dużo. `xcorr` zastąpione iloczynem `y*y'`, więc nie trzeba Signal
   Processing Toolbox. Funkcja zwraca `[Ahat,V]` w orientacji
   `chans × chans × p`, zgodnej z resztą pakietu, i obsługuje jeden kanał.

Nowy plik `mvar_estimate.m` zbiera dyspozytor estymatorów w jednym miejscu
(`[A,V]=mvar_estimate(dat,p,meth_num,mv)`): kody 1, 2 i 4 idą przez
`countCorr`/`countCov` i równania normalne, kod 8 do `lwr`. Zastąpił powtórzony
blok `countCorr → linsolve → DGEMM_symul` w `licz_mtmvar.m`, `licz_smtmvar.m`,
`licz_mtmvarBaseln.m`, `licz_smtmvarBaseln.m`, `estimateModelOrder.m` i
`mvar_diag_fit.m` — dzięki temu dobór rzędu też podąża za wybraną metodą,
zamiast liczyć po swojemu.

Współczynniki odbicia liczone są teraz bezpośrednimi iloczynami macierzowymi
(`EF'*EF`), nie przez `mycorr2`, które sumowało iloczyny zewnętrzne w pętli po
próbkach. `mycorr2.m` tym samym wypadło z zestawu plików używanych przez pakiet
— zostaje w katalogu, bo korzysta z niego `viemo.m`.

Gałąź `iwhat==8` w `countCov.m` została w pliku (jest poprawna, tylko nie nadaje
się do danych kierunkowych), ale nie jest już osiągalna z potoku obliczeń.
Etykieta czwartego przycisku w GUI zmieniana jest programowo w
`multargui_OpeningFcn` na „LWR (lattice)", tą samą techniką co checkbox
diagnostyki, żeby nie ruszać binarnego `multargui.fig`.

**Dane wielotrialowe.** LWR dopasowuje jeden model do wszystkich realizacji:
macierze kowariancji innowacji wchodzące do współczynników odbicia są
akumulowane po trialach, a iloczyny nigdy nie przekraczają granicy trialu.
Wewnętrzna pętla po próbkach została przy okazji zwektoryzowana
(`ef(:,1+k:end) += A_k*y(:,1:end-k)` zamiast pętli po `t`), bo w wersji
punkt-po-punkcie wielotrialowe dopasowanie byłoby nie do użycia. Normalizacja
(`norm0`, `norm1`, `norm2`) jest stosowana w `mvar_estimate` dokładnie tak, jak
robi to wewnętrznie `countCorr`, więc wszystkie metody widzą te same dane.

**Bootstrap.** Dla metod 1–4 bootstrap wylicza raz macierze korelacyjne
poszczególnych triali i w kolejnych losowaniach już tylko je uśrednia. LWR nie
ma takiej reprezentacji, więc jego rekurencja jest **przeliczana od nowa dla
każdego losowania**, na trialach wskazanych przez wylosowane indeksy
(`mvar_estimate(dat(:,:,ix),p,meth_num,mv)`). Losowanie jest dokładnie to samo
co dla pozostałych metod — `ix=m_randint(1,bootnum,[1 bootsiz])`, czyli `bootnum`
indeksów z puli `[1, bootsiz]`, a powtórzenia w `ix` dają trialom odpowiednio
większą wagę, tak samo jak przy uśrednianiu macierzy. Różnica jest wyłącznie
w koszcie: pełne przeliczenie rekurencji zamiast uśrednienia gotowych macierzy
jest zauważalnie wolniejsze.

Sprawdzone na 6 trialach po 200 punktów, `p=2`, 8 losowań, poziomy
`[5 50 95]`:

| procedura | `size(fun)` | `size(ARs.coefs)` | `size(ARs.V)` | czas |
|---|---|---|---|---|
| `licz_mtmvarBoots`, metoda 4 | `[3 3 10 2 3]` | `[3 3 2 3]` | `[3 3 3]` | 1.9 s |
| `licz_smtmvarBoots`, metoda 4, 3 okna | `[3 3 10 2 3 3]` | `[3 3 2 3 3]` | `[3 3 3 3]` | 3.7 s |

Percentyle wychodzą uporządkowane (5% ≤ 95% element po elemencie), mediana
losowań różni się od dopasowania do pełnych danych o 0.0352, a od prawdziwych
współczynników o 0.0644. Metody 1–3 w trybie bootstrap zwracają tablice
o niezmienionych rozmiarach.

Tym samym LWR nie ma już żadnych ograniczeń w stosunku do pozostałych metod.

**Weryfikacja.** Jeden kanał, AR(2) o współczynnikach `[0.600 −0.300]` i `var(e)=1`:

| | współczynniki | V |
|---|---|---|
| metoda 3 | `[+0.6006 −0.3043]` | 1.0383 |
| LWR | `[+0.6005 −0.3043]` | 1.0384 |

Trzy kanały, układ kierunkowy `x1→x2`, `x1→x3`:

| test | metoda 3 | metoda 4 (LWR) |
|---|---|---|
| `max\|A−A_prawdziwe\|`, 3000 pkt, wywołanie bezpośrednie | 0.0525 | 0.0524 |
| `max\|A−A_prawdziwe\|`, 2000 pkt, przez `licz_mtmvar` | 0.0489 | 0.0483 |
| `max\|eig\|` | 0.9466 | 0.9466 |
| Li-McLeod p | 0.908 | 0.906 |

`V` z LWR zgadza się z kowariancją reszt policzoną z dopasowanego modelu
w granicach 0.24%.

Tryb krótkoczasowy, 4 okna po 500 punktów, metoda 4: `ARs.coefs` ma rozmiar
`3×3×3×4`, `ARs.V` — `3×3×4`, diagnostyka policzona dla wszystkich czterech
okien, wszystkie stabilne (`max|eig|` od 0.944 do 0.964), reszty białe
(`p` od 0.43 do 0.88), błąd współczynników od 0.086 do 0.155 — tyle, ile wynika
z długości okna.

Dane wielotrialowe, ten sam materiał (łącznie 3000 punktów) w różnych podziałach:

| podział | metoda 3 | metoda 4 (LWR) |
|---|---|---|
| 1 × 3000 pkt | 0.0336 | 0.0336 |
| 5 × 600 pkt | 0.0508 | 0.0506 |
| 20 × 150 pkt | 0.0489 | 0.0483 |

Przy 20 × 400 punktów: `max|A−A_prawdziwe| = 0.0257`, `max|eig| = 0.9472`,
Li-McLeod `p = 0.59`, a `V` zgadza się z kowariancją reszt w granicach 0.11%.
To samo przez potok: `licz_mtmvar` z 20 trialami daje identyczne liczby,
a `licz_smtmvar` z 20 trialami i 3 oknami zwraca `coefs` o rozmiarze `3×3×3×3`
i `V` o rozmiarze `3×3×3`, wszystkie okna stabilne.

Regresja: dla pojedynczej realizacji (ten sam materiał co przed zmianą)
wynik jest **identyczny** — `max|A−A_prawdziwe| = 0.0524` i rozbieżność `V`
z kowariancją reszt 0.00236, co do wypisanych cyfr tyle samo, co przed
rozszerzeniem na wiele triali.

Sprawdzone też: dane wielotrialowe i tryb bootstrap kończą się opisanymi wyżej
komunikatami, wszystkie 91 plików funkcyjnych pakietu parsuje się bez błędu,
a `test_mvar_diagnostics` nadal przechodzi.

#### `viemo.m` nadal nieużywalny

Vieira-Morf zostaje poza potokiem. Na tym samym układzie dawał
`max|A−A_prawdziwe| = 1.3435`, równe całej wartości dominującego współczynnika —
ten współczynnik w ogóle nie zostaje wypełniony. Przyczyna jest w indeksowaniu:
w etapie `p` nowy współczynnik trafia do `A(p+1,p+1,…)`, a wcześniejsze do
`A(p+1,1:p−1,…)`, więc indeks `p` pozostaje zerowy, a końcowe
`ar=squeeze(A(P+1,2:P+1,:,:))` pomija z kolei indeks 1. Wymaga uporządkowania
konwencji, zanim cokolwiek z tej procedury da się użyć.

### Drobiazgi zostawione świadomie

- `lc=mv.chans` w blokach `norm0` i `norm1` w `countCorr.m` (linie 20 i 29) —
  ten sam idiom co w naprawionym `norm2`, ale bez skutku, bo `mv.chans` zawsze
  równa się `size(x,1)` po wyborze kanałów w `multar1m`.
- Martwy `if nargin<6` w 43 plikach w podkatalogach archiwalnych `pakiet/`,
  `pakiet/3/`, `pakiet/4/`, `testgui/` i „Nowy folder z rzeczami/".
- Zakomentowane kopie starych pętli w `countCorr_multdat.m` i `multar2m.m`.
