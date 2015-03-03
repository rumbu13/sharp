module internals.kernel32;

import system;
import system.runtime.interopservices;

mixin LinkLibrary!"kernel32.lib";

extern(Windows)
{
    alias LOCALE_ENUMPROCW = int function(in wchar*);
    alias LOCALE_ENUMPROCEX = int function(in wchar*, in uint, in size_t);
    alias CALINFO_ENUMPROCEXW = int function(in wchar*, in uint);
    alias CALINFO_ENUMPROCW = int function(in wchar*);
    alias CALINFO_ENUMPROCEXEX = int function(in wchar*, in uint, in wchar*, in size_t);
    alias DATEFMT_ENUMPROCEXW = int function(in wchar*, in uint);
    alias DATEFMT_ENUMPROCEXEX = int function(in wchar*, in uint, in size_t);
    alias TIMEFMT_ENUMPROCW = int function(in wchar*);
    alias TIMEFMT_ENUMPROCEX = int function(in wchar*, in size_t);
    alias CODEPAGE_ENUMPROCW = int function(in wchar*);
}

extern(Windows) nothrow @nogc:

const(void)* LoadLibraryW(in wchar* lpFileName);
int FreeLibrary(in void* hModule);
const(void)* GetProcAddress(in void* hModule, in char* lpProcName); 
void* LocalFree(void* hMem);
void* LocalAlloc(uint uFlags, size_t uBytes);
                    

uint GetLastError();
void SetLastError(in uint dwCode);

enum
{
    FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100,
    FORMAT_MESSAGE_IGNORE_INSERTS =  0x00000200,
    FORMAT_MESSAGE_FROM_STRING =     0x00000400,
    FORMAT_MESSAGE_FROM_HMODULE =    0x00000800,
    FORMAT_MESSAGE_FROM_SYSTEM =     0x00001000,
    FORMAT_MESSAGE_ARGUMENT_ARRAY =  0x00002000,
    FORMAT_MESSAGE_MAX_WIDTH_MASK =  0x000000FF,
};

uint FormatMessageW(uint dwFlags, in void* lpSource, uint dwMessageId, uint dwLanguageId, wchar* lpBuffer, uint nSize, void* *Arguments);


struct OSVERSIONINFOEXW 
{
    uint dwOSVersionInfoSize = OSVERSIONINFOEXW.sizeof;
    uint dwMajorVersion;
    uint dwMinorVersion;
    uint dwBuildNumber;
    uint dwPlatformId;
    wchar[128] szSDVersion;     
    ushort wServicePackMajor;
    ushort wServicePackMinor;
    ushort wSuiteMask;
    ubyte  wProductType;
    ubyte  wReserved;
}

struct FILETIME 
{
    uint dwLowDateTime;
    uint dwHighDateTime;
}

struct SYSTEMTIME 
{
    ushort wYear;
    ushort wMonth;
    ushort wDayOfWeek;
    ushort wDay;
    ushort wHour;
    ushort wMinute;
    ushort wSecond;
    ushort wMilliseconds;
}

enum VER_EQUAL =                       1;
enum VER_GREATER =                     2;
enum VER_GREATER_EQUAL =               3;
enum VER_LESS =                        4;
enum VER_LESS_EQUAL =                  5;
enum VER_AND =                         6;
enum VER_OR =                          7;

enum VER_CONDITION_MASK =              7;
enum VER_NUM_BITS_PER_CONDITION_MASK = 3;

enum VER_MINORVERSION =                0x0000001;
enum VER_MAJORVERSION =                0x0000002;
enum VER_BUILDNUMBER =                 0x0000004;
enum VER_PLATFORMID =                  0x0000008;
enum VER_SERVICEPACKMINOR =            0x0000010;
enum VER_SERVICEPACKMAJOR =            0x0000020;
enum VER_SUITENAME =                   0x0000040;
enum VER_PRODUCT_TYPE =                0x0000080;

enum VER_NT_WORKSTATION =              0x0000001;
enum VER_NT_DOMAIN_CONTROLLER =        0x0000002;
enum VER_NT_SERVER =                   0x0000003;

enum VER_PLATFORM_WIN32s =             0;
enum VER_PLATFORM_WIN32_WINDOWS =      1;
enum VER_PLATFORM_WIN32_NT =           2;

int GetVersionExW(ref OSVERSIONINFOEXW lpVersionInfo);

ulong VerSetConditionMask(in ulong ConditionMask, in uint TypeMask, in ubyte Condition);
int VerifyVersionInfoW(ref OSVERSIONINFOEXW lpVersionInformation, in uint dwTypeMask, in ulong dwlConditionMask);

ushort MAKELANGID(T, U)(T p, U s)    
{
    return cast(ushort)(cast(ushort)s << 10 | cast(ushort)p);
}

ushort PRIMARYLANGID(T)(T lgid)    
{
    return cast(ushort)lgid & 0x3ff;
}

ushort SUBLANGID(T)(T lgid)    
{
    return cast(ushort)lgid >> 10;
}

uint MAKELCID(T, U)(T lgid, U srtid)    
{
    return cast(uint)srtid << 16 | cast(uint)lgid;
}

uint MAKESORTLID(T, U, V)(T lgid, U srtid, V ver)    
{
    return MAKELCID(lgid, srtid) | (cast(uint)ver << 20);
}

ushort LANGIDFROMLCID(T)(T lcid)    
{
    return cast(ushort)lcid;
}

ushort SORTIDFROMLCID(T)(T lcid)    
{
    return cast(ushort)((cast(uint)lcid >> 16) & 0xf);
}

ushort SORTVERSIONFROMLCID(T)(T lcid)    
{
    return cast(ushort)((cast(uint)lcid >> 20) & 0xf);
}

enum LANG_NEUTRAL =                     0x00;
enum LANG_INVARIANT =                   0x7f;

enum LANG_AFRIKAANS =                   0x36;
enum LANG_ALBANIAN =                    0x1c;
enum LANG_ALSATIAN =                    0x84;
enum LANG_AMHARIC =                     0x5e;
enum LANG_ARABIC =                      0x01;
enum LANG_ARMENIAN =                    0x2b;
enum LANG_ASSAMESE =                    0x4d;
enum LANG_AZERI =                       0x2c;   
enum LANG_AZERBAIJANI =                 0x2c;
enum LANG_BANGLA =                      0x45;
enum LANG_BASHKIR =                     0x6d;
enum LANG_BASQUE =                      0x2d;
enum LANG_BELARUSIAN =                  0x23;
enum LANG_BENGALI =                     0x45;   
enum LANG_BRETON =                      0x7e;
enum LANG_BOSNIAN =                     0x1a;   
enum LANG_BOSNIAN_NEUTRAL =           0x781a;   
enum LANG_BULGARIAN =                   0x02;
enum LANG_CATALAN =                     0x03;
enum LANG_CENTRAL_KURDISH =             0x92;
enum LANG_CHEROKEE =                    0x5c;
enum LANG_CHINESE =                     0x04;  
enum LANG_CHINESE_SIMPLIFIED =          0x04;   
enum LANG_CHINESE_TRADITIONAL =       0x7c04;   
enum LANG_CORSICAN =                    0x83;
enum LANG_CROATIAN =                    0x1a;
enum LANG_CZECH =                       0x05;
enum LANG_DANISH =                      0x06;
enum LANG_DARI =                        0x8c;
enum LANG_DIVEHI =                      0x65;
enum LANG_DUTCH =                       0x13;
enum LANG_ENGLISH =                     0x09;
enum LANG_ESTONIAN =                    0x25;
enum LANG_FAEROESE =                    0x38;
enum LANG_FARSI =                       0x29;   
enum LANG_FILIPINO =                    0x64;
enum LANG_FINNISH =                     0x0b;
enum LANG_FRENCH =                      0x0c;
enum LANG_FRISIAN =                     0x62;
enum LANG_FULAH =                       0x67;
enum LANG_GALICIAN =                    0x56;
enum LANG_GEORGIAN =                    0x37;
enum LANG_GERMAN =                      0x07;
enum LANG_GREEK =                       0x08;
enum LANG_GREENLANDIC =                 0x6f;
enum LANG_GUJARATI =                    0x47;
enum LANG_HAUSA =                       0x68;
enum LANG_HAWAIIAN =                    0x75;
enum LANG_HEBREW =                      0x0d;
enum LANG_HINDI =                       0x39;
enum LANG_HUNGARIAN =                   0x0e;
enum LANG_ICELANDIC =                   0x0f;
enum LANG_IGBO =                        0x70;
enum LANG_INDONESIAN =                  0x21;
enum LANG_INUKTITUT =                   0x5d;
enum LANG_IRISH =                       0x3c;  
enum LANG_ITALIAN =                     0x10;
enum LANG_JAPANESE =                    0x11;
enum LANG_KANNADA =                     0x4b;
enum LANG_KASHMIRI =                    0x60;
enum LANG_KAZAK =                       0x3f;
enum LANG_KHMER =                       0x53;
enum LANG_KIHEC =                       0x86;
enum LANG_KINYARWANDA =                 0x87;
enum LANG_KONKANI =                     0x57;
enum LANG_KOREAN =                      0x12;
enum LANG_KYRGYZ =                      0x40;
enum LANG_LAO =                         0x54;
enum LANG_LATVIAN =                     0x26;
enum LANG_LITHUANIAN =                  0x27;
enum LANG_LOWER_SORBIAN =               0x2e;
enum LANG_LUXEMBOURGISH =               0x6e;
enum LANG_MACEDONIAN =                  0x2f;   
enum LANG_MALAY =                       0x3e;
enum LANG_MALAYALAM =                   0x4c;
enum LANG_MALTESE =                     0x3a;
enum LANG_MANIPURI =                    0x58;
enum LANG_MAORI =                       0x81;
enum LANG_MAPUDUNGUN =                  0x7a;
enum LANG_MARATHI =                     0x4e;
enum LANG_MOHAWK =                      0x7c;
enum LANG_MONGOLIAN =                   0x50;
enum LANG_NEPALI =                      0x61;
enum LANG_NORWEGIAN =                   0x14;
enum LANG_OCCITAN =                     0x82;
enum LANG_ODIA =                        0x48;
enum LANG_ORIYA =                       0x48;   
enum LANG_PASHTO =                      0x63;
enum LANG_PERSIAN =                     0x29;
enum LANG_POLISH =                      0x15;
enum LANG_PORTUGUESE =                  0x16;
enum LANG_PULAR =                       0x67;  
enum LANG_PUNJABI =                     0x46;
enum LANG_QUECHUA =                     0x6b;
enum LANG_ROMANIAN =                    0x18;
enum LANG_ROMANSH =                     0x17;
enum LANG_RUSSIAN =                     0x19;
enum LANG_SAKHA =                       0x85;
enum LANG_SAMI =                        0x3b;
enum LANG_SANSKRIT =                    0x4f;
enum LANG_SCOTTISH_GAELIC =             0x91;
enum LANG_SERBIAN =                     0x1a;   
enum LANG_SERBIAN_NEUTRAL =           0x7c1a;   
enum LANG_SINDHI =                      0x59;
enum LANG_SINHALESE =                   0x5b;
enum LANG_SLOVAK =                      0x1b;
enum LANG_SLOVENIAN =                   0x24;
enum LANG_SOTHO =                       0x6c;
enum LANG_SPANISH =                     0x0a;
enum LANG_SWAHILI =                     0x41;
enum LANG_SWEDISH =                     0x1d;
enum LANG_SYRIAC =                      0x5a;
enum LANG_TAJIK =                       0x28;
enum LANG_TAMAZIGHT =                   0x5f;
enum LANG_TAMIL =                       0x49;
enum LANG_TATAR =                       0x44;
enum LANG_TELUGU =                      0x4a;
enum LANG_THAI =                        0x1e;
enum LANG_TIBETAN =                     0x51;
enum LANG_TIGRIGNA =                    0x73;
enum LANG_TIGRINYA =                    0x73;  
enum LANG_TSWANA =                      0x32;
enum LANG_TURKISH =                     0x1f;
enum LANG_TURKMEN =                     0x42;
enum LANG_UIGHUR =                      0x80;
enum LANG_UKRAINIAN =                   0x22;
enum LANG_UPPER_SORBIAN =               0x2e;
enum LANG_URDU =                        0x20;
enum LANG_UZBEK =                       0x43;
enum LANG_VALENCIAN =                   0x03;
enum LANG_VIETNAMESE =                  0x2a;
enum LANG_WELSH =                       0x52;
enum LANG_WOLOF =                       0x88;
enum LANG_XHOSA =                       0x34;
enum LANG_YAKUT =                       0x85;   
enum LANG_YI =                          0x78;
enum LANG_YORUBA =                      0x6a;
enum LANG_ZULU =                        0x35;

enum SUBLANG_NEUTRAL =                             0x00;   
enum SUBLANG_DEFAULT =                             0x01;    
enum SUBLANG_SYS_DEFAULT =                         0x02;    
enum SUBLANG_CUSTOM_DEFAULT =                      0x03;    
enum SUBLANG_CUSTOM_UNSPECIFIED =                  0x04;    
enum SUBLANG_UI_CUSTOM_DEFAULT =                   0x05;    


enum SUBLANG_AFRIKAANS_SOUTH_AFRICA =              0x01;    
enum SUBLANG_ALBANIAN_ALBANIA =                    0x01;   
enum SUBLANG_ALSATIAN_FRANCE =                     0x01;    
enum SUBLANG_AMHARIC_ETHIOPIA =                    0x01;    
enum SUBLANG_ARABIC_SAUDI_ARABIA =                 0x01;    
enum SUBLANG_ARABIC_IRAQ =                         0x02;    
enum SUBLANG_ARABIC_EGYPT =                        0x03;    
enum SUBLANG_ARABIC_LIBYA =                        0x04;    
enum SUBLANG_ARABIC_ALGERIA =                      0x05;    
enum SUBLANG_ARABIC_MOROCCO =                      0x06;    
enum SUBLANG_ARABIC_TUNISIA =                      0x07;    
enum SUBLANG_ARABIC_OMAN =                         0x08;    
enum SUBLANG_ARABIC_YEMEN =                        0x09;    
enum SUBLANG_ARABIC_SYRIA =                        0x0a;    
enum SUBLANG_ARABIC_JORDAN =                       0x0b;    
enum SUBLANG_ARABIC_LEBANON =                      0x0c;    
enum SUBLANG_ARABIC_KUWAIT =                       0x0d;    
enum SUBLANG_ARABIC_UAE =                          0x0e;    
enum SUBLANG_ARABIC_BAHRAIN =                      0x0f;    
enum SUBLANG_ARABIC_QATAR =                        0x10;    
enum SUBLANG_ARMENIAN_ARMENIA =                    0x01;    
enum SUBLANG_ASSAMESE_INDIA =                      0x01;    
enum SUBLANG_AZERI_LATIN =                         0x01;    
enum SUBLANG_AZERI_CYRILLIC =                      0x02;    
enum SUBLANG_AZERBAIJANI_AZERBAIJAN_LATIN =        0x01;    
enum SUBLANG_AZERBAIJANI_AZERBAIJAN_CYRILLIC =     0x02;    
enum SUBLANG_BANGLA_INDIA =                        0x01;    
enum SUBLANG_BANGLA_BANGLADESH =                   0x02;    
enum SUBLANG_BASHKIR_RUSSIA =                      0x01;    
enum SUBLANG_BASQUE_BASQUE =                       0x01;    
enum SUBLANG_BELARUSIAN_BELARUS =                  0x01;    
enum SUBLANG_BENGALI_INDIA =                       0x01;    
enum SUBLANG_BENGALI_BANGLADESH =                  0x02;    
enum SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_LATIN =    0x05;    
enum SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_CYRILLIC = 0x08;    
enum SUBLANG_BRETON_FRANCE =                       0x01;    
enum SUBLANG_BULGARIAN_BULGARIA =                  0x01;    
enum SUBLANG_CATALAN_CATALAN =                     0x01;    
enum SUBLANG_CENTRAL_KURDISH_IRAQ =                0x01;    
enum SUBLANG_CHEROKEE_CHEROKEE =                   0x01;    
enum SUBLANG_CHINESE_TRADITIONAL =                 0x01;    
enum SUBLANG_CHINESE_SIMPLIFIED =                  0x02;    
enum SUBLANG_CHINESE_HONGKONG =                    0x03;    
enum SUBLANG_CHINESE_SINGAPORE =                   0x04;    
enum SUBLANG_CHINESE_MACAU =                       0x05;    
enum SUBLANG_CORSICAN_FRANCE =                     0x01;    
enum SUBLANG_CZECH_CZECH_REPUBLIC =                0x01;    
enum SUBLANG_CROATIAN_CROATIA =                    0x01;    
enum SUBLANG_CROATIAN_BOSNIA_HERZEGOVINA_LATIN =   0x04;    
enum SUBLANG_DANISH_DENMARK =                      0x01;    
enum SUBLANG_DARI_AFGHANISTAN =                    0x01;    
enum SUBLANG_DIVEHI_MALDIVES =                     0x01;    
enum SUBLANG_DUTCH =                               0x01;    
enum SUBLANG_DUTCH_BELGIAN =                       0x02;    
enum SUBLANG_ENGLISH_US =                          0x01;    
enum SUBLANG_ENGLISH_UK =                          0x02;    
enum SUBLANG_ENGLISH_AUS =                         0x03;    
enum SUBLANG_ENGLISH_ANC =                         0x04;    
enum SUBLANG_ENGLISH_NZ =                          0x05;    
enum SUBLANG_ENGLISH_EIRE =                        0x06;    
enum SUBLANG_ENGLISH_SOUTH_AFRICA =                0x07;    
enum SUBLANG_ENGLISH_JAMAICA =                     0x08;    
enum SUBLANG_ENGLISH_CARIBBEAN =                   0x09;    
enum SUBLANG_ENGLISH_BELIZE =                      0x0a;    
enum SUBLANG_ENGLISH_TRINIDAD =                    0x0b;    
enum SUBLANG_ENGLISH_ZIMBABWE =                    0x0c;    
enum SUBLANG_ENGLISH_PHILIPPINES =                 0x0d;    
enum SUBLANG_ENGLISH_INDIA =                       0x10;    
enum SUBLANG_ENGLISH_MALAYSIA =                    0x11;    
enum SUBLANG_ENGLISH_SINGAPORE =                   0x12;    
enum SUBLANG_ESTONIAN_ESTONIA =                    0x01;    
enum SUBLANG_FAEROESE_FAROE_ISLANDS =              0x01;    
enum SUBLANG_FILIPINO_PHILIPPINES =                0x01;    
enum SUBLANG_FINNISH_FINLAND =                     0x01;    
enum SUBLANG_FRENCH =                              0x01;    
enum SUBLANG_FRENCH_BELGIAN =                      0x02;    
enum SUBLANG_FRENCH_CANADIAN =                     0x03;    
enum SUBLANG_FRENCH_SWISS =                        0x04;    
enum SUBLANG_FRENCH_LUXEMBOURG =                   0x05;    
enum SUBLANG_FRENCH_MONACO =                       0x06;    
enum SUBLANG_FRISIAN_NETHERLANDS =                 0x01;    
enum SUBLANG_FULAH_SENEGAL =                       0x02;    
enum SUBLANG_GALICIAN_GALICIAN =                   0x01;    
enum SUBLANG_GEORGIAN_GEORGIA =                    0x01;    
enum SUBLANG_GERMAN =                              0x01;    
enum SUBLANG_GERMAN_SWISS =                        0x02;    
enum SUBLANG_GERMAN_AUSTRIAN =                     0x03;    
enum SUBLANG_GERMAN_LUXEMBOURG =                   0x04;    
enum SUBLANG_GERMAN_LIECHTENSTEIN =                0x05;    
enum SUBLANG_GREEK_GRECEE =                        0x01;    
enum SUBLANG_GREENLANDIC_GREENLAND =               0x01;    
enum SUBLANG_GUJARATI_INDIA =                      0x01;    
enum SUBLANG_HAUSA_NIGERIA_LATIN =                 0x01;    
enum SUBLANG_HAWAIIAN_US =                         0x01;    
enum SUBLANG_HEBREW_ISRAEL =                       0x01;    
enum SUBLANG_HINDI_INDIA =                         0x01;    
enum SUBLANG_HUNGARIAN_HUNGARY =                   0x01;    
enum SUBLANG_ICELANDIC_ICELAND =                   0x01;    
enum SUBLANG_IGBO_NIGERIA =                        0x01;    
enum SUBLANG_INDONESIAN_INDONESIA =                0x01;    
enum SUBLANG_INUKTITUT_CANADA =                    0x01;    
enum SUBLANG_INUKTITUT_CANADA_LATIN =              0x02;    
enum SUBLANG_IRISH_IRELAND =                       0x02;    
enum SUBLANG_ITALIAN =                             0x01;    
enum SUBLANG_ITALIAN_SWISS =                       0x02;    
enum SUBLANG_JAPANESE_JAPAN =                      0x01;    
enum SUBLANG_KANNADA_INDIA =                       0x01;    
enum SUBLANG_KASHMIRI_SASIA =                      0x02;    
enum SUBLANG_KASHMIRI_INDIA =                      0x02;    
enum SUBLANG_KAZAK_KAZAKHSTAN =                    0x01;    
enum SUBLANG_KHMER_CAMBODIA =                      0x01;    
enum SUBLANG_KICHE_GUATEMALA =                     0x01;    
enum SUBLANG_KINYARWANDA_RWANDA =                  0x01;    
enum SUBLANG_KONKANI_INDIA =                       0x01;    
enum SUBLANG_KOREAN =                              0x01;    
enum SUBLANG_KYRGYZ_KYRGYZSTAN =                   0x01;    
enum SUBLANG_LAO_LAO =                             0x01;    
enum SUBLANG_LATVIAN_LATVIA =                      0x01;    
enum SUBLANG_LITHUANIAN =                          0x01;    
enum SUBLANG_LOWER_SORBIAN_GERMANY =               0x02;    
enum SUBLANG_LUXEMBOURGISH_LUXEMBOURG =            0x01;    
enum SUBLANG_MACEDONIAN_MACEDONIA =                0x01;    
enum SUBLANG_MALAY_MALAYSIA =                      0x01;    
enum SUBLANG_MALAY_BRUNEI_DARUSSALAM =             0x02;    
enum SUBLANG_MALAYALAM_INDIA =                     0x01;    
enum SUBLANG_MALTESE_MALTA =                       0x01;    
enum SUBLANG_MAORI_NEW_ZEALAND =                   0x01;    
enum SUBLANG_MAPUDUNGUN_CHILE =                    0x01;    
enum SUBLANG_MARATHI_INDIA =                       0x01;    
enum SUBLANG_MOHAWK_MOHAWK =                       0x01;    
enum SUBLANG_MONGOLIAN_CYRILLIC_MONGOLIA =         0x01;    
enum SUBLANG_MONGOLIAN_PRC =                       0x02;    
enum SUBLANG_NEPALI_INDIA =                        0x02;    
enum SUBLANG_NEPALI_NEPAL =                        0x01;    
enum SUBLANG_NORWEGIAN_BOKMAL =                    0x01;    
enum SUBLANG_NORWEGIAN_NYNORSK =                   0x02;    
enum SUBLANG_OCCITAN_FRANCE =                      0x01;    
enum SUBLANG_ODIA_INDIA =                          0x01;    
enum SUBLANG_ORIYA_INDIA =                         0x01;    
enum SUBLANG_PASHTO_AFGHANISTAN =                  0x01;    
enum SUBLANG_PERSIAN_IRAN =                        0x01;    
enum SUBLANG_POLISH_POLAND =                       0x01;    
enum SUBLANG_PORTUGUESE =                          0x02;    
enum SUBLANG_PORTUGUESE_BRAZILIAN =                0x01;    
enum SUBLANG_PULAR_SENEGAL =                       0x02;    
enum SUBLANG_PUNJABI_INDIA =                       0x01;    
enum SUBLANG_PUNJABI_PAKISTAN =                    0x02;    
enum SUBLANG_QUECHUA_BOLIVIA =                     0x01;    
enum SUBLANG_QUECHUA_ECUADOR =                     0x02;    
enum SUBLANG_QUECHUA_PERU =                        0x03;    
enum SUBLANG_ROMANIAN_ROMANIA =                    0x01;    
enum SUBLANG_ROMANSH_SWITZERLAND =                 0x01;    
enum SUBLANG_RUSSIAN_RUSSIA =                      0x01;    
enum SUBLANG_SAKHA_RUSSIA =                        0x01;    
enum SUBLANG_SAMI_NORTHERN_NORWAY =                0x01;    
enum SUBLANG_SAMI_NORTHERN_SWEDEN =                0x02;    
enum SUBLANG_SAMI_NORTHERN_FINLAND =               0x03;    
enum SUBLANG_SAMI_LULE_NORWAY =                    0x04;    
enum SUBLANG_SAMI_LULE_SWEDEN =                    0x05;    
enum SUBLANG_SAMI_SOUTHERN_NORWAY =                0x06;    
enum SUBLANG_SAMI_SOUTHERN_SWEDEN =                0x07;    
enum SUBLANG_SAMI_SKOLT_FINLAND =                  0x08;    
enum SUBLANG_SAMI_INARI_FINLAND =                  0x09;    
enum SUBLANG_SANSKRIT_INDIA =                      0x01;    
enum SUBLANG_SCOTTISH_GAELIC =                     0x01;    
enum SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_LATIN =    0x06;    
enum SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_CYRILLIC = 0x07;    
enum SUBLANG_SERBIAN_MONTENEGRO_LATIN =            0x0b;    
enum SUBLANG_SERBIAN_MONTENEGRO_CYRILLIC =         0x0c;    
enum SUBLANG_SERBIAN_SERBIA_LATIN =                0x09;    
enum SUBLANG_SERBIAN_SERBIA_CYRILLIC =             0x0a;    
enum SUBLANG_SERBIAN_CROATIA =                     0x01;    
enum SUBLANG_SERBIAN_LATIN =                       0x02;    
enum SUBLANG_SERBIAN_CYRILLIC =                    0x03;    
enum SUBLANG_SINDHI_INDIA =                        0x01;    
enum SUBLANG_SINDHI_PAKISTAN =                     0x02;    
enum SUBLANG_SINDHI_AFGHANISTAN =                  0x02;    
enum SUBLANG_SINHALESE_SRI_LANKA =                 0x01;    
enum SUBLANG_SOTHO_NORTHERN_SOUTH_AFRICA =         0x01;    
enum SUBLANG_SLOVAK_SLOVAKIA =                     0x01;    
enum SUBLANG_SLOVENIAN_SLOVENIA =                  0x01;    
enum SUBLANG_SPANISH =                             0x01;    
enum SUBLANG_SPANISH_MEXICAN =                     0x02;    
enum SUBLANG_SPANISH_MODERN =                      0x03;    
enum SUBLANG_SPANISH_GUATEMALA =                   0x04;    
enum SUBLANG_SPANISH_COSTA_RICA =                  0x05;    
enum SUBLANG_SPANISH_PANAMA =                      0x06;    
enum SUBLANG_SPANISH_DOMINICAN_REPUBLIC =          0x07;    
enum SUBLANG_SPANISH_VENEZUELA =                   0x08;    
enum SUBLANG_SPANISH_COLOMBIA =                    0x09;    
enum SUBLANG_SPANISH_PERU =                        0x0a;    
enum SUBLANG_SPANISH_ARGENTINA =                   0x0b;    
enum SUBLANG_SPANISH_ECUADOR =                     0x0c;    
enum SUBLANG_SPANISH_CHILE =                       0x0d;    
enum SUBLANG_SPANISH_URUGUAY =                     0x0e;    
enum SUBLANG_SPANISH_PARAGUAY =                    0x0f;    
enum SUBLANG_SPANISH_BOLIVIA =                     0x10;    
enum SUBLANG_SPANISH_EL_SALVADOR =                 0x11;    
enum SUBLANG_SPANISH_HONDURAS =                    0x12;    
enum SUBLANG_SPANISH_NICARAGUA =                   0x13;    
enum SUBLANG_SPANISH_PUERTO_RICO =                 0x14;    
enum SUBLANG_SPANISH_US =                          0x15;    
enum SUBLANG_SWAHILI_KENYA =                       0x01;    
enum SUBLANG_SWEDISH =                             0x01;    
enum SUBLANG_SWEDISH_FINLAND =                     0x02;    
enum SUBLANG_SYRIAC_SYRIA =                        0x01;    
enum SUBLANG_TAJIK_TAJIKISTAN =                    0x01;    
enum SUBLANG_TAMAZIGHT_ALGERIA_LATIN =             0x02;    
enum SUBLANG_TAMAZIGHT_MOROCCO_TIFINAGH =          0x04;    
enum SUBLANG_TAMIL_INDIA =                         0x01;    
enum SUBLANG_TAMIL_SRI_LANKA =                     0x02;    
enum SUBLANG_TATAR_RUSSIA =                        0x01;    
enum SUBLANG_TELUGU_INDIA =                        0x01;    
enum SUBLANG_THAI_THAILAND =                       0x01;    
enum SUBLANG_TIBETAN_PRC =                         0x01;    
enum SUBLANG_TIGRIGNA_ERITREA =                    0x02;    
enum SUBLANG_TIGRINYA_ERITREA =                    0x02;    
enum SUBLANG_TIGRINYA_ETHIOPIA =                   0x01;    
enum SUBLANG_TSWANA_BOTSWANA =                     0x02;    
enum SUBLANG_TSWANA_SOUTH_AFRICA =                 0x01;    
enum SUBLANG_TURKISH_TURKEY =                      0x01;    
enum SUBLANG_TURKMEN_TURKMENISTAN =                0x01;    
enum SUBLANG_UIGHUR_PRC =                          0x01;    
enum SUBLANG_UKRAINIAN_UKRAINE =                   0x01;    
enum SUBLANG_UPPER_SORBIAN_GERMANY =               0x01;    
enum SUBLANG_URDU_PAKISTAN =                       0x01;    
enum SUBLANG_URDU_INDIA =                          0x02;    
enum SUBLANG_UZBEK_LATIN =                         0x01;    
enum SUBLANG_UZBEK_CYRILLIC =                      0x02;    
enum SUBLANG_VALENCIAN_VALENCIA =                  0x02;    
enum SUBLANG_VIETNAMESE_VIETNAM =                  0x01;    
enum SUBLANG_WELSH_UNITED_KINGDOM =                0x01;    
enum SUBLANG_WOLOF_SENEGAL =                       0x01;    
enum SUBLANG_XHOSA_SOUTH_AFRICA =                  0x01;    
enum SUBLANG_YAKUT_RUSSIA =                        0x01;    
enum SUBLANG_YI_PRC =                              0x01;    
enum SUBLANG_YORUBA_NIGERIA =                      0x01;    
enum SUBLANG_ZULU_SOUTH_AFRICA =                   0x01;    

enum SORT_DEFAULT =                     0x0;     

enum SORT_INVARIANT_MATH =              0x1;     

enum SORT_JAPANESE_XJIS =               0x0;     
enum SORT_JAPANESE_UNICODE =            0x1;     
enum SORT_JAPANESE_RADIALCSTROKE =      0x4;     

enum SORT_CHINESE_BIG5 =                0x0;     
enum SORT_CHINESE_PRCP =                0x0;     
enum SORT_CHINESE_UNIOCDE =             0x1;     
enum SORT_CHINESE_PRC =                 0x2;     
enum SORT_CHINESE_BOPOMOFO =            0x3;     
enum SORT_CHINESE_RADIALCSTROKE =       0x4;     

enum SORT_KOREAN_KCS =                  0x0;     
enum SORT_KOREAN_UNICODE =              0x1;     

enum SORT_GERMAN_PHONE_BOOK =           0x1;     

enum SORT_HUNGARIAN_DEFAULT =           0x0;     
enum SORT_HUNGARIAN_TECHNICAL =         0x1;     

enum SORT_GEORGIAN_TRADITIONAL =        0x0;     
enum SORT_GEORGIAN_MODERN =             0x1;     

enum LANG_SYSTEM_DEFAULT        = MAKELANGID(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT);
enum LANG_USER_DEFAULT          = MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT);
enum LOCALE_SYSTEM_DEFAULT      = MAKELCID(LANG_SYSTEM_DEFAULT, SORT_DEFAULT);
enum LOCALE_USER_DEFAULT        = MAKELCID(LANG_USER_DEFAULT, SORT_DEFAULT);
enum LOCALE_CUSTOM_DEFAULT      = MAKELCID(MAKELANGID(LANG_NEUTRAL, SUBLANG_CUSTOM_DEFAULT), SORT_DEFAULT);
enum LOCALE_CUSTOM_UNSPECIFIED  = MAKELCID(MAKELANGID(LANG_NEUTRAL, SUBLANG_CUSTOM_UNSPECIFIED), SORT_DEFAULT);
enum LOCALE_CUSTOM_UI_DEFAULT   = MAKELCID(MAKELANGID(LANG_NEUTRAL, SUBLANG_UI_CUSTOM_DEFAULT), SORT_DEFAULT);
enum LOCALE_NEUTRAL             = MAKELCID(MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL), SORT_DEFAULT);
enum LOCALE_INVARIANT           = MAKELCID(MAKELANGID(LANG_INVARIANT, SUBLANG_NEUTRAL), SORT_DEFAULT);

enum
{
    LOCALE_NAME_USER_DEFAULT    = null,
    LOCALE_NAME_INVARIANT       = "",
    LOCALE_NAME_SYSTEM_DEFAULT  = "!x-sys-default-locale",
}

enum: uint
{
    LCID_INSTALLED       = 1,
    LCID_SUPPORTED       = 2, 
    LCID_ALTERNATE_SORTS = 4,
}

enum LOCALE_ALL =                  0;            
enum LOCALE_WINDOWS =              0x00000001;    
enum LOCALE_SUPPLEMENTAL =         0x00000002;         
enum LOCALE_ALTERNATE_SORTS =      0x00000004;           
enum LOCALE_REPLACEMENT =          0x00000008;            
enum LOCALE_NEUTRALDATA =          0x00000010;            
enum LOCALE_SPECIFCIDATA =         0x00000020; 

enum LOCALE_NOUSEROVERRIDE =         0x80000000;   // do not use user overrides
enum LOCALE_USE_CP_ACP =             0x40000000;   // use the system ACP
enum LOCALE_RETURN_NUMBER =          0x20000000;   // return number instead of string
enum LOCALE_RETURN_GENITIVE_NAMES =  0x10000000;   // Flag to return the Genitive forms of month names
enum LOCALE_ALLOW_NEUTRAL_NAMES =    0x08000000;   // Flag to allow returning neutral names/lcids for name conversion
enum LOCALE_SLOCALIZEDDISPLAYNAME =  0x00000002;   // localized name of locale, eg "German (Germany)" in UI language
enum LOCALE_SENGLISHDISPLAYNAME =    0x00000072;   // Display name (language + country/region usually) in English, eg "German (Germany)"
enum LOCALE_SNATIVEDISPLAYNAME =     0x00000073;   // Display name in native locale language, eg "Deutsch (Deutschland)
enum LOCALE_SLOCALIZEDLANGUAGENAME = 0x0000006f;   // Language Display Name for a language, eg "German" in UI language
enum LOCALE_SENGLISHLANGUAGENAME =   0x00001001;   // English name of language, eg "German"
enum LOCALE_SNATIVELANGUAGENAME =    0x00000004;   // native name of language, eg "Deutsch"
enum LOCALE_SLOCALIZEDCOUNTRYNAME =  0x00000006;   // localized name of country/region, eg "Germany" in UI language
enum LOCALE_SENGLISHCOUNTRYNAME =    0x00001002;   // English name of country/region, eg "Germany"
enum LOCALE_SNATIVECOUNTRYNAME =     0x00000008;   // native name of country/region, eg "Deutschland"
enum LOCALE_SLANGUAGE =              0x00000002;   // localized name of locale, eg "German (Germany)" in UI language
enum LOCALE_SLANGDISPLAYNAME =       0x0000006f;   // Language Display Name for a language, eg "German" in UI language
enum LOCALE_SENGLANGUAGE =           0x00001001;   // English name of language, eg "German"
enum LOCALE_SNATIVELANGNAME =        0x00000004;   // native name of language, eg "Deutsch"
enum LOCALE_SCOUNTRY =               0x00000006;   // localized name of country/region, eg "Germany" in UI language
enum LOCALE_SENGCOUNTRY =            0x00001002;   // English name of country/region, eg "Germany"
enum LOCALE_SNATIVECTRYNAME =        0x00000008;   // native name of country/region, eg "Deutschland"
enum LOCALE_ILANGUAGE =              0x00000001;   // language id, LOCALE_SNAME preferred
enum LOCALE_SABBREVLANGNAME =        0x00000003;   // arbitrary abbreviated language name, LOCALE_SISO639LANGNAME preferred
enum LOCALE_ICOUNTRY =               0x00000005;   // country/region code, eg 1, LOCALE_SISO3166CTRYNAME may be more useful.
enum LOCALE_SABBREVCTRYNAME =        0x00000007;   // arbitrary abbreviated country/region name, LOCALE_SISO3166CTRYNAME preferred
enum LOCALE_IGEOID =                 0x0000005B;   // geographical location id, eg "244"
enum LOCALE_IDEFAULTLANGUAGE =       0x00000009;   // default language id, deprecated
enum LOCALE_IDEFAULTCOUNTRY =        0x0000000A;   // default country/region code, deprecated
enum LOCALE_IDEFAULTCODEPAGE =       0x0000000B;   // default oem code page (use of Unicode is recommended instead)
enum LOCALE_IDEFAULTANSICODEPAGE =   0x00001004;   // default Ansi code page (use of Unicode is recommended instead)
enum LOCALE_IDEFAULTMACCODEPAGE =    0x00001011;   // default mac code page (use of Unicode is recommended instead)
enum LOCALE_SLIST =                  0x0000000C;   // list item separator, eg "," for "1,2,3,4"
enum LOCALE_IMEASURE =               0x0000000D;   // 0 = metric, 1 = US measurement system
enum LOCALE_SDECIMAL =               0x0000000E;   // decimal separator, eg "." for 1,234.00
enum LOCALE_STHOUSAND =              0x0000000F;   // thousand separator, eg "," for 1,234.00
enum LOCALE_SGROUPING =              0x00000010;   // digit grouping, eg "3;0" for 1,000,000
enum LOCALE_IDIGITS =                0x00000011;   // number of fractional digits eg 2 for 1.00
enum LOCALE_ILZERO =                 0x00000012;   // leading zeros for decimal, 0 for .97, 1 for 0.97
enum LOCALE_INEGNUMBER =             0x00001010;   // negative number mode, 0-4, see documentation
enum LOCALE_SNATIVEDIGITS =          0x00000013;   // native digits for 0-9, eg "0123456789"
enum LOCALE_SCURRENCY =              0x00000014;   // local monetary symbol, eg "$"
enum LOCALE_SINTLSYMBOL =            0x00000015;   // intl monetary symbol, eg "USD"
enum LOCALE_SMONDECIMALSEP =         0x00000016;   // monetary decimal separator, eg "." for $1,234.00
enum LOCALE_SMONTHOUSANDSEP =        0x00000017;   // monetary thousand separator, eg "," for $1,234.00
enum LOCALE_SMONGROUPING =           0x00000018;   // monetary grouping, eg "3;0" for $1,000,000.00
enum LOCALE_ICURRDIGITS =            0x00000019;   // # local monetary digits, eg 2 for $1.00
enum LOCALE_IINTLCURRDIGITS =        0x0000001A;   // # intl monetary digits, eg 2 for $1.00
enum LOCALE_ICURRENCY =              0x0000001B;   // positive Currency mode, 0-3, see documenation
enum LOCALE_INEGCURR =               0x0000001C;   // negative Currency mode, 0-15, see documentation
enum LOCALE_SDATE =                  0x0000001D;   // date separator (derived from LOCALE_SSHORTDATE, use that instead)
enum LOCALE_STIME =                  0x0000001E;   // time separator (derived from LOCALE_STIMEFORMAT, use that instead)
enum LOCALE_SSHORTDATE =             0x0000001F;   // short date format string, eg "MM/dd/yyyy"
enum LOCALE_SLONGDATE =              0x00000020;   // long date format string, eg "dddd, MMMM dd, yyyy"
enum LOCALE_STIMEFORMAT =            0x00001003;   // time format string, eg "HH:mm:ss"
enum LOCALE_IDATE =                  0x00000021;   // short date format ordering (derived from LOCALE_SSHORTDATE, use that instead)
enum LOCALE_ILDATE =                 0x00000022;   // long date format ordering (derived from LOCALE_SLONGDATE, use that instead)
enum LOCALE_ITIME =                  0x00000023;   // time format specifier (derived from LOCALE_STIMEFORMAT, use that instead)
enum LOCALE_ITIMEMARKPOSN =          0x00001005;   // time marker position (derived from LOCALE_STIMEFORMAT, use that instead)
enum LOCALE_ICENTURY =               0x00000024;   // century format specifier (short date, LOCALE_SSHORTDATE is preferred)
enum LOCALE_ITLZERO =                0x00000025;   // leading zeros in time field (derived from LOCALE_STIMEFORMAT, use that instead)
enum LOCALE_IDAYLZERO =              0x00000026;   // leading zeros in day field (short date, LOCALE_SSHORTDATE is preferred)
enum LOCALE_IMONLZERO =              0x00000027;   // leading zeros in month field (short date, LOCALE_SSHORTDATE is preferred)
enum LOCALE_S1159 =                  0x00000028;   // AM designator, eg "AM"
enum LOCALE_S2359 =                  0x00000029;   // PM designator, eg "PM"
enum LOCALE_ICALENDARTYPE =          0x00001009;   // type of calendar specifier, eg CAL_GREGORIAN
enum LOCALE_IOPTIONALCALENDAR =      0x0000100B;   // additional calendar types specifier, eg CAL_GREGORIAN_US
enum LOCALE_IFIRSTDAYOFWEEK =        0x0000100C;   // first day of week specifier, 0-6, 0=Monday, 6=Sunday
enum LOCALE_IFIRSTWEEKOFYEAR =       0x0000100D;   // first week of year specifier, 0-2, see documentation
enum LOCALE_SDAYNAME1 =              0x0000002A;   // long name for Monday
enum LOCALE_SDAYNAME2 =              0x0000002B;   // long name for Tuesday
enum LOCALE_SDAYNAME3 =              0x0000002C;   // long name for Wednesday
enum LOCALE_SDAYNAME4 =              0x0000002D;   // long name for Thursday
enum LOCALE_SDAYNAME5 =              0x0000002E;   // long name for Friday
enum LOCALE_SDAYNAME6 =              0x0000002F;   // long name for Saturday
enum LOCALE_SDAYNAME7 =              0x00000030;   // long name for Sunday
enum LOCALE_SABBREVDAYNAME1 =        0x00000031;   // abbreviated name for Monday
enum LOCALE_SABBREVDAYNAME2 =        0x00000032;   // abbreviated name for Tuesday
enum LOCALE_SABBREVDAYNAME3 =        0x00000033;   // abbreviated name for Wednesday
enum LOCALE_SABBREVDAYNAME4 =        0x00000034;   // abbreviated name for Thursday
enum LOCALE_SABBREVDAYNAME5 =        0x00000035;   // abbreviated name for Friday
enum LOCALE_SABBREVDAYNAME6 =        0x00000036;   // abbreviated name for Saturday
enum LOCALE_SABBREVDAYNAME7 =        0x00000037;   // abbreviated name for Sunday
enum LOCALE_SMONTHNAME1 =            0x00000038;   // long name for January
enum LOCALE_SMONTHNAME2 =            0x00000039;   // long name for February
enum LOCALE_SMONTHNAME3 =            0x0000003A;   // long name for March
enum LOCALE_SMONTHNAME4 =            0x0000003B;   // long name for April
enum LOCALE_SMONTHNAME5 =            0x0000003C;   // long name for May
enum LOCALE_SMONTHNAME6 =            0x0000003D;   // long name for June
enum LOCALE_SMONTHNAME7 =            0x0000003E;   // long name for July
enum LOCALE_SMONTHNAME8 =            0x0000003F;   // long name for August
enum LOCALE_SMONTHNAME9 =            0x00000040;   // long name for September
enum LOCALE_SMONTHNAME10 =           0x00000041;   // long name for October
enum LOCALE_SMONTHNAME11 =           0x00000042;   // long name for November
enum LOCALE_SMONTHNAME12 =           0x00000043;   // long name for December
enum LOCALE_SMONTHNAME13 =           0x0000100E;   // long name for 13th month (if exists)
enum LOCALE_SABBREVMONTHNAME1 =      0x00000044;   // abbreviated name for January
enum LOCALE_SABBREVMONTHNAME2 =      0x00000045;   // abbreviated name for February
enum LOCALE_SABBREVMONTHNAME3 =      0x00000046;   // abbreviated name for March
enum LOCALE_SABBREVMONTHNAME4 =      0x00000047;   // abbreviated name for April
enum LOCALE_SABBREVMONTHNAME5 =      0x00000048;   // abbreviated name for May
enum LOCALE_SABBREVMONTHNAME6 =      0x00000049;   // abbreviated name for June
enum LOCALE_SABBREVMONTHNAME7 =      0x0000004A;   // abbreviated name for July
enum LOCALE_SABBREVMONTHNAME8 =      0x0000004B;   // abbreviated name for August
enum LOCALE_SABBREVMONTHNAME9 =      0x0000004C;   // abbreviated name for September
enum LOCALE_SABBREVMONTHNAME10 =     0x0000004D;   // abbreviated name for October
enum LOCALE_SABBREVMONTHNAME11 =     0x0000004E;   // abbreviated name for November
enum LOCALE_SABBREVMONTHNAME12 =     0x0000004F;   // abbreviated name for December
enum LOCALE_SABBREVMONTHNAME13 =     0x0000100F;   // abbreviated name for 13th month (if exists)
enum LOCALE_SPOSITIVESIGN =          0x00000050;   // positive sign, eg ""
enum LOCALE_SNEGATIVESIGN =          0x00000051;   // negative sign, eg "-"
enum LOCALE_IPOSSIGNPOSN =           0x00000052;   // positive sign position (derived from INEGCURR)
enum LOCALE_INEGSIGNPOSN =           0x00000053;   // negative sign position (derived from INEGCURR)
enum LOCALE_IPOSSYMPRECEDES =        0x00000054;   // mon sym precedes pos amt (derived from ICURRENCY)
enum LOCALE_IPOSSEPBYSPACE =         0x00000055;   // mon sym sep by space from pos amt (derived from ICURRENCY)
enum LOCALE_INEGSYMPRECEDES =        0x00000056;   // mon sym precedes neg amt (derived from INEGCURR)
enum LOCALE_INEGSEPBYSPACE =         0x00000057;   // mon sym sep by space from neg amt (derived from INEGCURR)
enum LOCALE_FONTSIGNATURE =          0x00000058;   // font signature
enum LOCALE_SISO639LANGNAME =        0x00000059;   // ISO abbreviated language name, eg "en"
enum LOCALE_SISO3166CTRYNAME =       0x0000005A;   // ISO abbreviated country/region name, eg "US"
enum LOCALE_IDEFAULTEBCDICCODEPAGE = 0x00001012;   // default ebcdic code page (use of Unicode is recommended instead)
enum LOCALE_IPAPERSIZE =             0x0000100A;   // 1 = letter, 5 = legal, 8 = a3, 9 = a4
enum LOCALE_SENGCURRNAME =           0x00001007;   // english name of Currency, eg "Euro"
enum LOCALE_SNATIVECURRNAME =        0x00001008;   // native name of Currency, eg "euro"
enum LOCALE_SYEARMONTH =             0x00001006;   // year month format string, eg "MM/yyyy"
enum LOCALE_SSORTNAME =              0x00001013;   // sort name, usually "", eg "Dictionary" in UI Language
enum LOCALE_IDIGITSUBSTITUTION =     0x00001014;   // 0 = context, 1 = None, 2 = national
enum LOCALE_SNAME =                  0x0000005c;   // locale name (ie: en-us)
enum LOCALE_SDURATION =              0x0000005d;   // time duration format, eg "hh:mm:ss"
enum LOCALE_SKEYBOARDSTOINSTALL =    0x0000005e;   // Used internally, see GetKeyboardLayoutName() function
enum LOCALE_SSHORTESTDAYNAME1 =      0x00000060;   // Shortest day name for Monday
enum LOCALE_SSHORTESTDAYNAME2 =      0x00000061;   // Shortest day name for Tuesday
enum LOCALE_SSHORTESTDAYNAME3 =      0x00000062;   // Shortest day name for Wednesday
enum LOCALE_SSHORTESTDAYNAME4 =      0x00000063;   // Shortest day name for Thursday
enum LOCALE_SSHORTESTDAYNAME5 =      0x00000064;   // Shortest day name for Friday
enum LOCALE_SSHORTESTDAYNAME6 =      0x00000065;   // Shortest day name for Saturday
enum LOCALE_SSHORTESTDAYNAME7 =      0x00000066;   // Shortest day name for Sunday
enum LOCALE_SISO639LANGNAME2 =       0x00000067;   // 3 character ISO abbreviated language name, eg "eng"
enum LOCALE_SISO3166CTRYNAME2 =      0x00000068;   // 3 character ISO country/region name, eg "USA"
enum LOCALE_SNAN =                   0x00000069;   // Not a Number, eg "NaN"
enum LOCALE_SPOSINFINITY =           0x0000006a;   // + Infinity, eg "infinity"
enum LOCALE_SNEGINFINITY =           0x0000006b;   // - Infinity, eg "-infinity"
enum LOCALE_SSCRIPTS =               0x0000006c;   // Typical scripts in the locale: ; delimited script codes, eg "Latn;"
enum LOCALE_SPARENT =                0x0000006d;   // Fallback name for resources, eg "en" for "en-US"
enum LOCALE_SCONSOLEFALLBACKNAME =   0x0000006e;   // Fallback name for within the console for Unicode Only locales, eg "en" for bn-IN
enum LOCALE_IREADINGLAYOUT =         0x00000070;   // Returns one of the following 4 reading layout values:
enum LOCALE_INEUTRAL =               0x00000071;   // Returns 0 for specific cultures, 1 for neutral cultures.
enum LOCALE_INEGATIVEPERCENT =       0x00000074;   // Returns 0-11 for the negative percent format
enum LOCALE_IPOSITIVEPERCENT =       0x00000075;   // Returns 0-3 for the positive percent formatIPOSITIVEPERCENT
enum LOCALE_SPERCENT =               0x00000076;   // Returns the percent symbol
enum LOCALE_SPERMILLE =              0x00000077;   // Returns the permille (U+2030) symbol
enum LOCALE_SMONTHDAY =              0x00000078;   // Returns the preferred month/day format
enum LOCALE_SSHORTTIME =             0x00000079;   // Returns the preferred short time format (ie: no seconds, just h:mm)
enum LOCALE_SOPENTYPELANGUAGETAG =   0x0000007a;   // Open type language tag, eg: "latn" or "dflt"
enum LOCALE_SSORTLOCALE =            0x0000007b;   // Name of locale to use for sorting/collation/casing behavior.

alias CAL_NOUSEROVERRIDE =        LOCALE_NOUSEROVERRIDE;   
alias CAL_USE_CP_ACP =            LOCALE_USE_CP_ACP;     
alias CAL_RETURN_NUMBER =         LOCALE_RETURN_NUMBER;       

alias CAL_RETURN_GENITIVE_NAMES = LOCALE_RETURN_GENITIVE_NAMES; 

enum CAL_ICALINTVALUE =          0x00000001;  
enum CAL_SCALNAME =              0x00000002;  
enum CAL_IYEAROFFSETRANGE =      0x00000003;  
enum CAL_SERASTRING =            0x00000004;  
enum CAL_SSHORTDATE =            0x00000005;  
enum CAL_SLONGDATE =             0x00000006;  
enum CAL_SDAYNAME1 =             0x00000007;  
enum CAL_SDAYNAME2 =             0x00000008;  
enum CAL_SDAYNAME3 =             0x00000009;  
enum CAL_SDAYNAME4 =             0x0000000a; 
enum CAL_SDAYNAME5 =             0x0000000b;  
enum CAL_SDAYNAME6 =             0x0000000c;  
enum CAL_SDAYNAME7 =             0x0000000d;  
enum CAL_SABBREVDAYNAME1 =       0x0000000e;  
enum CAL_SABBREVDAYNAME2 =       0x0000000f;  
enum CAL_SABBREVDAYNAME3 =       0x00000010;  
enum CAL_SABBREVDAYNAME4 =       0x00000011;  
enum CAL_SABBREVDAYNAME5 =       0x00000012;  
enum CAL_SABBREVDAYNAME6 =       0x00000013;  
enum CAL_SABBREVDAYNAME7 =       0x00000014;  
enum CAL_SMONTHNAME1 =           0x00000015;  
enum CAL_SMONTHNAME2 =           0x00000016; 
enum CAL_SMONTHNAME3 =           0x00000017;  
enum CAL_SMONTHNAME4 =           0x00000018;  
enum CAL_SMONTHNAME5 =           0x00000019;  
enum CAL_SMONTHNAME6 =           0x0000001a;  
enum CAL_SMONTHNAME7 =           0x0000001b; 
enum CAL_SMONTHNAME8 =           0x0000001c; 
enum CAL_SMONTHNAME9 =           0x0000001d; 
enum CAL_SMONTHNAME10 =          0x0000001e;  
enum CAL_SMONTHNAME11 =          0x0000001f;  
enum CAL_SMONTHNAME12 =          0x00000020;  
enum CAL_SMONTHNAME13 =          0x00000021;  
enum CAL_SABBREVMONTHNAME1 =     0x00000022;  
enum CAL_SABBREVMONTHNAME2 =     0x00000023; 
enum CAL_SABBREVMONTHNAME3 =     0x00000024;  
enum CAL_SABBREVMONTHNAME4 =     0x00000025;  
enum CAL_SABBREVMONTHNAME5 =     0x00000026;  
enum CAL_SABBREVMONTHNAME6 =     0x00000027;  
enum CAL_SABBREVMONTHNAME7 =     0x00000028;  
enum CAL_SABBREVMONTHNAME8 =     0x00000029;  
enum CAL_SABBREVMONTHNAME9 =     0x0000002a;  
enum CAL_SABBREVMONTHNAME10 =    0x0000002b;  
enum CAL_SABBREVMONTHNAME11 =    0x0000002c;  
enum CAL_SABBREVMONTHNAME12 =    0x0000002d;  
enum CAL_SABBREVMONTHNAME13 =    0x0000002e;  
enum CAL_SYEARMONTH =            0x0000002f;  
enum CAL_ITWODIGITYEARMAX =      0x00000030;  

enum CAL_SSHORTESTDAYNAME1 =     0x00000031;  
enum CAL_SSHORTESTDAYNAME2 =     0x00000032;  
enum CAL_SSHORTESTDAYNAME3 =     0x00000033;  
enum CAL_SSHORTESTDAYNAME4 =     0x00000034;  
enum CAL_SSHORTESTDAYNAME5 =     0x00000035;  
enum CAL_SSHORTESTDAYNAME6 =     0x00000036;  
enum CAL_SSHORTESTDAYNAME7 =     0x00000037;  

enum CAL_SMONTHDAY =             0x00000038; 
enum CAL_SABBREVERASTRING =      0x00000039;  

enum ENUM_ALL_CALENDARS =        0xffffffff;  

enum CAL_GREGORIAN =                  1;  
enum CAL_GREGORIAN_US =               2;      
enum CAL_JAPAN =                      3;      
enum CAL_TAIWAN =                     4;      
enum CAL_KOREA =                      5;      
enum CAL_HIJRI =                      6;      
enum CAL_THAI =                       7;     
enum CAL_HEBREW =                     8;      
enum CAL_GREGORIAN_ME_FRENCH =        9;   
enum CAL_GREGORIAN_ARABIC =           10;     
enum CAL_GREGORIAN_XLIT_ENGLISH =     11;    
enum CAL_GREGORIAN_XLIT_FRENCH =      12;     
enum CAL_UMALQURA =                   23;     

enum DATE_SHORTDATE =            0x00000001;  
enum DATE_LONGDATE =             0x00000002;  
enum DATE_USE_ALT_CALENDAR =     0x00000004;  
enum DATE_YEARMONTH =            0x00000008;  
enum DATE_LTRREADING =           0x00000010;  
enum DATE_RTLREADING =           0x00000020; 
enum DATE_AUTOLAYOUT =           0x00000040;  

enum TIME_NOMINUTESORSECONDS =   0x00000001;  
enum TIME_NOSECONDS =            0x00000002;  
enum TIME_NOTIMEMARKER =         0x00000004;  
enum TIME_FORCE24HOURFORMAT =    0x00000008;  

enum LOCALE_NAME_MAX_LENGTH = 85;

enum LCMAP_LOWERCASE =           0x00000100;  
enum LCMAP_UPPERCASE =           0x00000200; 
enum LCMAP_TITLECASE =           0x00000300; 
enum LCMAP_SORTKEY =             0x00000400;  
enum LCMAP_BYTEREV =             0x00000800;  
enum LCMAP_HIRAGANA =            0x00100000;  
enum LCMAP_KATAKANA =            0x00200000;  
enum LCMAP_HALFWIDTH =           0x00400000; 
enum LCMAP_FULLWIDTH =           0x00800000;  
enum LCMAP_LINGUISTIC_CASING =   0x01000000;  
enum LCMAP_SIMPLIFIED_CHINESE =  0x02000000; 
enum LCMAP_TRADITIONAL_CHINESE = 0x04000000; 

enum SORT_STRINGSORT =           0x00001000;  
enum SORT_DIGITSASNUMBERS =      0x00000008;  

enum STR_LESS_THAN =            1;           
enum STR_EQUAL =                2;           
enum STR_GREATER_THAN =         3;           

enum NORM_IGNORECASE =           0x00000001;  
enum NORM_IGNORENONSPACE =       0x00000002;  
enum NORM_IGNORESYMBOLS =        0x00000004; 

enum LINGUISTIC_IGNORECASE =      0x00000010;  
enum LINGUISTIC_IGNOREDIACRITIC = 0x00000020;  

enum NORM_IGNOREKANATYPE =       0x00010000;  
enum NORM_IGNOREWIDTH =          0x00020000;  
enum NORM_LINGUISTIC_CASING =    0x08000000;

enum FIND_STARTSWITH =           0x00100000; 
enum FIND_ENDSWITH =             0x00200000;
enum FIND_FROMSTART =            0x00400000;
enum FIND_FROMEND =              0x00800000; 

enum COMPARE_STRING =  0x0001;

struct NLSVERSIONINFO
{		
    uint dwNLSVersionInfoSize = NLSVERSIONINFO.sizeof;
    uint dwNLSVersion;
    uint dwDefinedVersion;         
}

struct NLSVERSIONINFOEX
{
    uint dwNLSVersionInfoSize = NLSVERSIONINFOEX.sizeof;
    uint dwNLSVersion;
    uint dwDefinedVersion;         
    uint dwEffectiveId; 
    Guid guidCustomVersion;
}

int GetDateFormatW(in uint locale, in uint dwFlags, in SYSTEMTIME* lpDate, in wchar* lpFormat, wchar* lpDateStr, in int cchDate);
int GetDateFormatEx(in wchar* locale, in uint dwFlags, in SYSTEMTIME* lpDate, in wchar* lpFormat, wchar* lpDateStr, in int cchDate, in wchar* lpCalendar);

int GetNLSVersion(in uint Function, in uint lcid, ref NLSVERSIONINFO lpVersionInformation);
int GetNLSVersionEx(in uint Function, in wchar* lpLocaleName, ref NLSVERSIONINFOEX lpVersionInformation);

int LCMapStringW(in uint Locale, in uint dwMapFlags, in wchar* lpSrcStr, in int cchSrc, wchar* lpDestStr, in int cchDest);
int LCMapStringEx(in wchar* lpLocaleName, in uint dwMapFlags, in wchar* lpSrcStr, in int cchSrc, wchar* lpDestStr, in int cchDest, in void* lpVersionInformation, in void* lpReserved, in ptrdiff_t lParam);
int CompareStringW(in uint Locale, in uint dwMapFlags, in wchar* lpString1, in int cchount1, in wchar* lpString2, in int cchount2);
int CompareStringEx(in wchar* lpLocaleName, in uint dwMapFlags, in wchar* lpString1, in int cchount1, in wchar* lpString2, in int cchount2, in void* lpVersionInformation, in void* lpReserved, in ptrdiff_t lParam);
int FindNLSString(in uint Locale, in uint dwFindNLSStringFlags, in wchar* lpStringSource, in int cchSource, in wchar* lpStringValue, in int cchValue, int* pcchFound);
int FindNLSStringEx(in wchar* lpLocaleName, in uint dwFindNLSStringFlags, in wchar* lpStringSource, in int cchSource, in wchar* lpStringValue, in int cchValue, int* pcchFound, in void* lpVersionInformation, in void* lpReserved, in ptrdiff_t lParam);


int GetLocaleInfoEx(in wchar* lpLocaleName, in uint lcType, wchar* lpLData, in int cchData);
int GetLocaleInfoW(in uint lcid, in uint lcType, wchar* lpLData, in int cchData);
int GetUserDefaultLocaleName(wchar* lpLocaleName, in int cchLocaleName);
int GetSystemDefaultLocaleName(wchar* lpLocaleName, in int cchLocaleName);
uint GetUserDefaultLCID();
uint GetSystemDefaultLCID();
uint GetUserDefaultUILanguage();
int GetCalendarInfoW(in uint Locale, in uint Calendar, in int alType, wchar* lpalData, int cchData, uint* lpValue);
int GetCalendarInfoEx(in wchar* lpLocaleName, in uint Calendar, wchar* lpReserved, in int alType, wchar* lpalData, int cchData, uint* lpValue);
int LCIDToLocaleName(in uint Locale, wchar* lpName, in int cchName, in uint dwFlags);
uint LocaleNameToLCID(in wchar* lpName, in uint dwFlags);
int IsValidLocale(in uint locale, in uint dwFlags);
int IsValidLocaleName(in wchar* lpLocaleName);

int EnumSystemLocalesW(in LOCALE_ENUMPROCW proc, in uint dwFlags);
int EnumSystemLocalesEx(in LOCALE_ENUMPROCEX proc, in uint dwFlags, in size_t lParam, in void* lpReserved);
int EnumCalendarInfoW(in CALINFO_ENUMPROCW proc, in uint locale, in uint calendar, in uint calType);
int EnumCalendarInfoExW(in CALINFO_ENUMPROCEXW proc, in uint locale, in uint calendar, in uint calType);
int EnumCalendarInfoExEx(in CALINFO_ENUMPROCEXEX proc, in wchar* locale, in uint calendar, in wchar* lpReserved, in uint calType, size_t lParam);
int EnumDateFormatsExW(in DATEFMT_ENUMPROCEXW proc, in uint locale, in uint dwFlags);
int EnumDateFormatsExEx(in DATEFMT_ENUMPROCEXEX proc, in wchar* locale, in uint dwFlags, in size_t lParam); 
int EnumTimeFormatsW(in TIMEFMT_ENUMPROCW proc, in uint locale, in uint dwFlags);
int EnumTimeFormatsEx(in TIMEFMT_ENUMPROCEX proc, in wchar* locale, in uint dwFlags, in size_t lParam);
int EnumSystemCodePagesW(in CODEPAGE_ENUMPROCW lpodePageEnumProc, in uint dwFlags);

wchar* lstrcatW(wchar* lpString1, in wchar* lpString2);
int lstrcmpW(in wchar* lpString1, in wchar* lpString2);
int lstrcmpiW(in wchar* lpString1, in wchar* lpString2);
wchar* lstrcpyW(wchar* lpString1, in wchar* lpString2);
wchar* lstrcpynW(wchar* lpString1, in wchar* lpString2, int iMaxLength);
int lstrlenW(in wchar* lpString);

struct TIME_ZONE_INFORMATION 
{
    int Bias;
    wchar StandardName[ 32 ];
    SYSTEMTIME StandardDate;
    int StandardBias;
    wchar DaylightName[ 32 ];
    SYSTEMTIME DaylightDate;
    int DaylightBias;
}

struct DYNAMIC_TIME_ZONE_INFORMATION 
{
    int Bias;
    wchar StandardName[ 32 ];
    SYSTEMTIME StandardDate;
    int StandardBias;
    wchar DaylightName[ 32 ];
    SYSTEMTIME DaylightDate;
    int DaylightBias;
    wchar TimeZoneKeyName[ 128 ];
    ubyte DynamicDaylightTimeDisabled;
}

struct REG_TZI_FORMAT
{
    int Bias;
    int StandardBias;
    int DaylightBias;
    SYSTEMTIME StandardDate;
    SYSTEMTIME DaylightDate;
}

union ULARGE_INTEGER 
{
    struct 
    {
        uint LowPart;
        uint HighPart;
    }
    ulong QuadPart;
}

enum TIME_ZONE_ID_INVALID = 0xFFFFFFFF;
enum TIME_ZONE_ID_UNKNOWN =  0;
enum TIME_ZONE_ID_STANDARD = 1;
enum TIME_ZONE_ID_DAYLIGHT = 2;

uint GetTimeZoneInformation(ref TIME_ZONE_INFORMATION lpTimeZoneInformation);
uint GetDynamicTimeZoneInformation(out DYNAMIC_TIME_ZONE_INFORMATION pTimeZoneInformation);

int TzSpecificLocalTimeToSystemTime(TIME_ZONE_INFORMATION* lpTimeZone, ref SYSTEMTIME lpLocalTime, out SYSTEMTIME lpUniversalTime);
int SystemTimeToTzSpecificLocalTime(TIME_ZONE_INFORMATION* lpTimeZone, ref SYSTEMTIME lpUniversalTime, out SYSTEMTIME lpLocalTime);

void GetLocalTime(out SYSTEMTIME lpSystemTime);
void GetSystemTime(out SYSTEMTIME lpSystemTime);
int FileTimeToLocalFileTime(const ref FILETIME lpFileTime, out FILETIME lpLocalFileTime);
int LocalFileTimeToFileTime(const ref FILETIME lpLocalFileTime, out FILETIME lpFileTime);

uint ExpandEnvironmentStringsW(wchar* lpSrc, wchar* lpDst, uint nSize);

struct MEMORYSTATUSEX 
{
    uint  dwLength = MEMORYSTATUSEX.sizeof;
    ulong dwMemoryLoad;
    ulong ullTotalPhys;
    ulong ullAvailPhys;
    ulong ullTotalPageFile;
    ulong ullAvailPageFile;
    ulong ullTotalVirtual;
    ulong ullAvailVirtual;
    ulong ullAvailExtendedVirtual;
}

int GlobalMemoryStatusEx(ref MEMORYSTATUSEX memory);


int EnumSystemCodePagesW(in CODEPAGE_ENUMPROCW lpCodePageEnumProc, in uint dwFlags);

enum MAX_PATH =                  260;
enum MAX_LEADBYTES =             12;
enum MAX_DEFAULTCHAR =           2;

struct CPINFOEXW
{
    uint   MaxCharSize;
    ubyte  DefaultChar[MAX_DEFAULTCHAR];
    ubyte  LeadByte[MAX_LEADBYTES];
    wchar  UnicodeDefaultChar;
    uint   CodePage;
    wchar  CodePageName[MAX_PATH];
}

int GetCPInfoExW(uint CodePage, in uint dwFlags, out CPINFOEXW lpPInfoEx);
uint GetACP();

enum CP_ACP =                    0;           // default to ANSI code page
enum CP_OEMCP =                  1;           // default to OEM  code page
enum CP_MACCP =                  2;           // default to MAC  code page
enum CP_THREAD_ACP =             3;           // current thread's ANSI code page
enum CP_SYMBOL =                 42;          // SYMBOL translations
enum CP_UTF7 =                   65000;       // UTF-7 translation
enum CP_UTF8 =                   65001;       // UTF-8 translation

enum CP_INSTALLED =              0x00000001;
enum CP_SUPPORTED =              0x00000002;

enum MB_PRECOMPOSED =            0x00000001;  // use precomposed chars
enum MB_COMPOSITE =              0x00000002;  // use composite chars
enum MB_USEGLYPHCHARS =          0x00000004;  // use glyph chars, not ctrl chars
enum MB_ERR_INVALID_CHARS =      0x00000008;  // error for invalid chars
enum WC_COMPOSITECHECK =         0x00000200;  // convert composite to precomposed
enum WC_DISCARDNS =              0x00000010;  // discard non-spacing chars
enum WC_SEPCHARS =               0x00000020;  // generate separate chars
enum WC_DEFAULTCHAR =            0x00000040;  // replace w/ default char
enum WC_ERR_INVALID_CHARS =      0x00000080;  // error for invalid chars
enum WC_NO_BEST_FIT_CHARS =      0x00000400;  // do not use best fit chars



int MultiByteToWideChar(in uint codePage, in uint dwFlags, in char* lpMultiByteStr, in int cchMultiByte, wchar* lpWideCharStr, in int cchWideChar);
int WideCharToMultiByte(in uint codePage, in uint dwFlags, in wchar* lpWideCharStr, in int cchWideChar, char* lpMultiByteStr, in int cchMultiByte, char* lpDefaultChar, bool* lpUsedDefaultChar);


 struct COORD 
 {
    short X;
    short Y;
}

 struct SMALL_RECT 
 {
     short Left;
     short Top;
     short Right;
     short Bottom;
 }

 struct CONSOLE_SCREEN_BUFFER_INFO 
 {
     COORD dwSize;
     COORD dwCursorPosition;
     short  wAttributes;
     SMALL_RECT srWindow;
     COORD dwMaximumWindowSize;
 }

 enum FOREGROUND_BLUE =      0x0001; // text color contains blue.
 enum FOREGROUND_GREEN =     0x0002; // text color contains green.
 enum FOREGROUND_RED =       0x0004; // text color contains red.
 enum FOREGROUND_INTENSITY = 0x0008; // text color is intensified.
 enum BACKGROUND_BLUE =      0x0010; // background color contains blue.
 enum BACKGROUND_GREEN =     0x0020; // background color contains green.
 enum BACKGROUND_RED =       0x0040; // background color contains red.
 enum BACKGROUND_INTENSITY = 0x0080; // background color is intensified.

int Beep(in uint dwFreq, in uint dwDuration);
void* GetStdHandle(in uint nStdHandle);
int GetConsoleScreenBufferInfo(in void* hConsoleOutput, out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
int FillConsoleOutputCharacterW(in void* hConsoleOutput, in wchar cCharacter, in uint nLength, in COORD dwWriteCoord, out uint lpNumberOfCharsWritten);
int SetConsoleCursorPosition(in void* hConsoleOutput, in COORD dwCursorPosition);
int SetConsoleTextAttribute(in void* hConsoleOutput, in ushort wAttributes);

enum STD_INPUT_HANDLE =    cast(uint)-10;
enum STD_OUTPUT_HANDLE =   cast(uint)-11;
enum STD_ERROR_HANDLE =    cast(uint)-12;

enum FILE_TYPE_UNKNOWN =   0x0000;
enum FILE_TYPE_DISK =      0x0001;
enum FILE_TYPE_CHAR =      0x0002;
enum FILE_TYPE_PIPE =      0x0003;
enum FILE_TYPE_REMOTE =    0x8000;

version(Win32)
    alias ULONG_PTR = int;
else
    alias ULONG_PTR = ulong;


struct OVERLAPPED 
{
    ULONG_PTR Internal;
    ULONG_PTR InternalHigh;
    union 
    {
        struct 
        {
            uint Offset;
            uint OffsetHigh;
        }
        void* Pointer;
    }
    void* hEvent;
}

struct CONSOLE_READCONSOLE_CONTROL 
{
    uint nLength;
    uint nInitialChars;
    uint dwCtrlWakeupMask;
    uint dwControlKeyState;
}

int ReadFile(in void* hFile, void* lpBuffer, in uint nNumberOfBytesToRead, uint* lpNumberOfBytesRead, OVERLAPPED* lpOverlapped);
int WriteFile(in void* hFile, in void* lpBuffer, in uint nNumberOfBytesToWrite, uint* lpNumberOfBytesWritten, OVERLAPPED* lpOverlapped);
uint GetFileType(in void* hFile);

int ReadConsoleW(in void* hConsoleInput, void* lpBuffer, uint nNumberOfCharsToRead, uint* lpNumberOfCharsRead, CONSOLE_READCONSOLE_CONTROL* pInputControl);
int WriteConsoleW(in void* hConsoleOutput, in void* lpBuffer, uint nNumberOfCharsToWrite, uint* lpNumberOfCharsWritten, void* lpReserved);
int GetConsoleMode(in void* hConsoleHandle, out uint lpMode);
uint GetConsoleCP();
uint GetConsoleOutputCP();
int SetConsoleCP(in uint wCodePageID);
int SetConsoleOutputCP(in uint wCodePageID);


