module internals.advapi32;

import system;
import system.runtime.interopservices;

import internals.kernel32;

mixin LinkLibrary!"advapi32.lib";

extern(Windows) nothrow:

enum HKEY_CLASSES_ROOT =                   cast(void*)0x80000000;
enum HKEY_CURRENT_USER =                   cast(void*)0x80000001;
enum HKEY_LOCAL_MACHINE =                  cast(void*)0x80000002;
enum HKEY_USERS =                          cast(void*)0x80000003;
enum HKEY_PERFORMANCE_DATA =               cast(void*)0x80000004;
enum HKEY_PERFORMANCE_TEXT =               cast(void*)0x80000050;
enum HKEY_PERFORMANCE_NLSTEXT =            cast(void*)0x80000060;
enum HKEY_CURRENT_CONFIG =                 cast(void*)0x80000005;
enum HKEY_DYN_DATA =                       cast(void*)0x80000006;
enum HKEY_CURRENT_USER_LOCAL_SETTINGS =    cast(void*)0x80000007;

enum REG_OPTION_RESERVED =         0x00000000; 
enum REG_OPTION_NON_VOLATILE =     0x00000000;
enum REG_OPTION_VOLATILE =         0x00000001; 
enum REG_OPTION_CREATE_LINK =      0x00000002; 
enum REG_OPTION_BACKUP_RESTORE =   0x00000004; 
enum REG_OPTION_OPEN_LINK =        0x00000008;
enum REG_LEGAL_OPTION =            REG_OPTION_RESERVED | REG_OPTION_NON_VOLATILE | REG_OPTION_VOLATILE |
                                   REG_OPTION_CREATE_LINK | REG_OPTION_BACKUP_RESTORE | REG_OPTION_OPEN_LINK;
enum REG_OPEN_LEGAL_OPTION =       REG_OPTION_RESERVED | REG_OPTION_BACKUP_RESTORE | REG_OPTION_OPEN_LINK;

enum DELETE =                           0x00010000;
enum READ_CONTROL =                     0x00020000;
enum WRITE_DAC =                        0x00040000;
enum WRITE_OWNER =                      0x00080000;
enum SYNCHRONIZE =                      0x00100000;
enum STANDARD_RIGHTS_REQUIRED =         0x000F0000;
enum STANDARD_RIGHTS_READ =             READ_CONTROL;
enum STANDARD_RIGHTS_WRITE =            READ_CONTROL;
enum STANDARD_RIGHTS_EXECUTE =          READ_CONTROL;
enum STANDARD_RIGHTS_ALL =              0x001F0000;
enum SPECIFCI_RIGHTS_ALL =              0x0000FFFF;
enum ACCESS_SYSTEM_SECURITY =           0x01000000;
enum MAXIMUM_ALLOWED =                  0x02000000;
enum GENERIC_READ =                     0x80000000;
enum GENERIC_WRITE =                    0x40000000;
enum GENERIC_EXECUTE =                  0x20000000;
enum GENERIC_ALL =                      0x10000000;

enum KEY_QUERY_VALUE =         0x0001;
enum KEY_SET_VALUE =           0x0002;
enum KEY_CREATE_SUB_KEY =      0x0004;
enum KEY_ENUMERATE_SUB_KEYS =  0x0008;
enum KEY_NOTIFY =              0x0010;
enum KEY_CREATE_LINK =         0x0020;
enum KEY_WOW64_32KEY =         0x0200;
enum KEY_WOW64_64KEY =         0x0100;
enum KEY_WOW64_RES =           0x0300;

enum KEY_READ =                STANDARD_RIGHTS_READ | KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY & ~SYNCHRONIZE;
enum KEY_WRITE =               STANDARD_RIGHTS_WRITE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY & ~SYNCHRONIZE;
enum KEY_EXECUTE =             KEY_READ & ~SYNCHRONIZE;
enum KEY_ALL_ACCESS =          STANDARD_RIGHTS_ALL | KEY_QUERY_VALUE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY | KEY_CREATE_LINK & ~SYNCHRONIZE;

enum REG_NONE =                    ( 0 );   // No value type
enum REG_SZ =                      ( 1 );   // Unicode nul terminated string
enum REG_EXPAND_SZ =               ( 2 );   // Unicode nul terminated string
enum REG_BINARY =                  ( 3 );   // Free form binary
enum REG_DWORD =                   ( 4 );   // 32-bit number
enum REG_DWORD_LITTLE_ENDIAN =     ( 4 );   // 32-bit number (same as REG_DWORD)
enum REG_DWORD_BIG_ENDIAN =        ( 5 );   // 32-bit number
enum REG_LINK =                    ( 6 );   // Symbolic Link (unicode)
enum REG_MULTI_SZ =                ( 7 );   // Multiple Unicode strings
enum REG_RESOURCE_LIST =           ( 8 );   // Resource list in the resource map
enum REG_FULL_RESOURCE_DESCRIPTOR = ( 9 );  // Resource list in the hardware description
enum REG_RESOURCE_REQUIREMENTS_LIST = ( 10 );
enum REG_QWORD =                   ( 11 );  // 64-bit number
enum REG_QWORD_LITTLE_ENDIAN =     ( 11 );  // 64-bit number (same as REG_QWORD)

int RegCloseKey(in void* hKey);
int RegFlushKey(in void* hKey);
int RegOpenKeyExW(in void* hKey, in wchar* lpSubKey, in uint options, in uint samDesired, void** phkResult);
int RegQueryValueExW(in void* hKey, in wchar* lpValueName, in uint* lpReserved, uint* lpType, void* lpData, uint* lpcbData);
int RegEnumValueW(in void* hKey, in uint dwIndex, wchar* lpValueName, uint* lpcchValueName, uint* lpReserved, uint* lpType, ubyte* lpData, uint* lpcbData);
int RegQueryInfoKeyW(in void* hKey,  wchar* lplass, uint* lpclass, uint* lpReserved, uint* lpcSubKeys,
                     uint* lpcMaxSubKeyLen, uint* lpcMaxClassLen, uint* lpcValues, uint* lpcMaxValueNameLen,
                     uint* lpcMaxValueLen, uint* lpcbSecurityDescriptor, void* lpftLastWriteTime);

int RegEnumKeyExW(in void* hKey, in uint dwIndex, wchar* lpName, uint* lpcName, uint* lpReserved, wchar* lpClass, uint* lpcClass, FILETIME* lpftLastWriteTime);
int RegLoadMUIStringW(void* hKey, in wchar* pszValue, wchar* pszOutBuf, in uint cbOutBuf, uint* pcbData, uint Flags, wchar* pszDirectory);

uint EnumDynamicTimeZoneInformation(in uint dwIndex, out DYNAMIC_TIME_ZONE_INFORMATION lpTimeZoneInformation);