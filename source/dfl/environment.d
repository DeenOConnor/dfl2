// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

// Not actually part of forms, but is handy.

///
module dfl.environment;

private import dfl.base;
private import dfl.event;

private import core.sys.windows.winbase;
private import core.sys.windows.windows;

private import std.conv;
private import std.string;


///
final class Environment // docmain
{
    private this() {}


    static:

    ///
    @property string commandLine() // getter
    {
        return to!string(fromStringz(GetCommandLineA()));
    }


    ///
    @property void currentDirectory(string cd) // setter
    {
        if(!SetCurrentDirectoryA(cd.ptr))
            throw new DflException("Unable to set current directory");
    }

    /// ditto
    @property string currentDirectory() // getter
    {
        char[MAX_PATH] buf;
        GetCurrentDirectoryA(MAX_PATH, buf.ptr);
        return to!string(fromStringz(buf));
    }


    ///
    @property string machineName() // getter
    {
        char[] result;
        uint len;
        if(GetComputerNameA(result.ptr, &len) == 0)
            throw new DflException("Unable to obtain machine name");
        return to!string(fromStringz(result));
    }


    ///
    @property string newLine() // getter
    {
        static import std.ascii;
        return std.ascii.newline;
    }


    ///
    @property OperatingSystem osVersion() // getter
    {
        OSVERSIONINFOA osi;
        Version ver;

        osi.dwOSVersionInfoSize = osi.sizeof;
        if(!GetVersionExA(&osi))
            throw new DflException("Unable to obtain operating system version information");

        int build;

        switch(osi.dwPlatformId)
        {
            case VER_PLATFORM_WIN32_NT:
                ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion, osi.dwBuildNumber);
                break;

            case VER_PLATFORM_WIN32_WINDOWS:
                ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion, LOWORD(osi.dwBuildNumber));
                break;
            case 3: // VER_PLATFORM_X64_WINDOWS: // Idk, for some reason this just does not exist - D.O
                ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion, LOWORD(osi.dwBuildNumber));
                break;
            default:
                ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion);
        }

        return new OperatingSystem(cast(PlatformId)osi.dwPlatformId, ver);
    }


    ///
    @property string systemDirectory() // getter
    {
        char[MAX_PATH] result;
        if(GetSystemDirectoryA(result.ptr, MAX_PATH) == 0)
            throw new DflException("Unable to obtain system directory");
        return to!string(fromStringz(result));
    }


    // Should return int ?
    @property DWORD tickCount() // getter
    {
        return GetTickCount();
    }


    ///
    @property string userName() // getter
    {
        char[] result;
        uint len;
        if(GetUserNameA(result.ptr, &len) == 0)
            throw new DflException("Unable to obtain user name");
        return to!string(fromStringz(result));
    }


    ///
    void exit(int code)
    {
        // This is probably better than ExitProcess(code).
        // I'm pretty sure that C in Windows uses ExitProcess() for exit() - D.O
        ExitProcess(code);
    }


    ///
    string expandEnvironmentVariables(string str)
    {
        if(str.length == 0) {
            return str;
        }
        uint lenRequired = 0;
        lenRequired = ExpandEnvironmentStringsA(str.ptr, null, 1);

        if (lenRequired == 0)
            throw new DflException("Unable to expand environment variables");

        char[] buf;
        if (ExpandEnvironmentStringsA(str.ptr, buf.ptr, lenRequired) == 0)
            throw new DflException("Unable to expand environment variables");
        return to!string(fromStringz(buf));
    }


    ///
    string[] getCommandLineArgs()
    {
        return parseArgs(commandLine);
    }


    ///
    string getEnvironmentVariable(string name, bool throwIfMissing)
    {
        if(name.length == 0) {
            return name;
        }
        uint lenRequired = 0;
        lenRequired = GetEnvironmentVariableA(name.ptr, null, 1);

        if (lenRequired == 0) {
            if(!throwIfMissing && GetLastError() == 203) { // ERROR_ENVVAR_NOT_FOUND
                return "";
            }
            throw new DflException("Unable to obtain environment variable");
        }

        char[] buf;
        if (GetEnvironmentVariableA(name.ptr, buf.ptr, lenRequired) == 0)
            throw new DflException("Unable to obtain environment variable");
        return to!string(fromStringz(buf));
    }

    /// ditto
    string getEnvironmentVariable(string name)
    {
        return getEnvironmentVariable(name, true);
    }


    ///
    string[] getLogicalDrives()
    {
        DWORD dr = GetLogicalDrives();
        string[] result;
        int i;
        char[4] tmp = " :\\\0";

        for(i = 0; dr; i++)
        {
            if(dr & 1)
            {
                char[] s = tmp.dup[0 .. 3];
                s[0] = cast(char)('A' + i);
                result ~= cast(string)s; // Needed in D2.
            }
            dr >>= 1;
        }

        return result;
    }
}


package string[] parseArgs(string args)
{
    string[] result;
    uint i;
    bool inQuote = false;
    bool findStart = true;
    uint startIndex = 0;

    for(i = 0;; i++)
    {
        if(i == args.length)
        {
            if(findStart)
                startIndex = i;
            break;
        }

        if(findStart)
        {
            if(args[i] == ' ' || args[i] == '\t')
                continue;
            findStart = false;
            startIndex = i;
        }

        if(args[i] == '"')
        {
            inQuote = !inQuote;
            if(!inQuote) //matched quotes
            {
                result.length = result.length + 1;
                result[result.length - 1] = args[startIndex .. i];
                findStart = true;
            }
            else //starting quote
            {
                if(startIndex != i) //must be a quote stuck to another word, separate them
                {
                    result.length = result.length + 1;
                    result[result.length - 1] = args[startIndex .. i];
                    startIndex = i + 1;
                }
                else
                {
                    startIndex++; //exclude the quote
                }
            }
        }
        else if(!inQuote)
        {
            if(args[i] == ' ' || args[i] == '\t')
            {
                result.length = result.length + 1;
                result[result.length - 1] = args[startIndex .. i];
                findStart = true;
            }
        }
    }

    if(startIndex != i)
    {
        result.length = result.length + 1;
        result[result.length - 1] = args[startIndex .. i];
    }

    return result;
}


unittest
{
    string[] args;

    args = parseArgs(`"foo" bar`);
    assert(args.length == 2);
    assert(args[0] == "foo");
    assert(args[1] == "bar");

    args = parseArgs(`"environment"`);
    assert(args.length == 1);
    assert(args[0] == "environment");
}


///
// Any version, not just the operating system.
class Version // docmain ?
{
    private:
    int _major = 0, _minor = 0;
    int _build = -1, _revision = -1;


    public:

    ///
    this()
    {
    }


    final:

    /// ditto
    // A string containing "major.minor.build.revision".
    // 2 to 4 parts expected.
    this(string str)
    {
        string[] stuff = split(str, ".");

        try {
            switch(stuff.length)
            {
                case 4:
                    _revision = to!int(stuff[3]);
                    goto case 3;
                case 3:
                    _build = to!int(stuff[2]);
                    goto case 2;
                case 2:
                    _minor = to!int(stuff[1]);
                    _major = to!int(stuff[0]);
                    break;
                default:
                    throw new DflException("Invalid version parameter");
            }
        } catch (ConvException ex) {
            throw new DflException("Version parameter is not an integer");
        }
    }

    /// ditto
    this(int major, int minor)
    {
        _major = major;
        _minor = minor;
    }

    /// ditto
    this(int major, int minor, int build)
    {
        _major = major;
        _minor = minor;
        _build = build;
    }

    /// ditto
    this(int major, int minor, int build, int revision)
    {
        _major = major;
        _minor = minor;
        _build = build;
        _revision = revision;
    }


    ///
    override string toString()
    {
        string result;

        result = to!string(_major) ~ "." ~ to!string(_minor);
        if(_build != -1)
            result ~= "." ~ to!string(_build);
        if(_revision != -1)
            result ~= "." ~ to!string(_revision);

        return result;
    }


    ///
    @property int major() // getter
    {
        return _major;
    }

    /// ditto
    @property int minor() // getter
    {
        return _minor;
    }

    /// ditto
    // -1 if no build.
    @property int build() // getter
    {
        return _build;
    }

    /// ditto
    // -1 if no revision.
    @property int revision() // getter
    {
        return _revision;
    }
}


///
enum PlatformId: uint
{
    WIN_CE = cast(DWORD)-1,
    WIN32s = VER_PLATFORM_WIN32s,
    WIN32_WINDOWS = VER_PLATFORM_WIN32_WINDOWS,
    WIN32_NT = VER_PLATFORM_WIN32_NT,
    WIN64_WINDOWS = 3, // VER_PLATFORM_X64_WINDOWS, // Again, for some reason this specific one is missing - D.O
}


///
final class OperatingSystem // docmain
{
    final
    {
        ///
        this(PlatformId platId, Version ver)
        {
            this.platId = platId;
            this.vers = ver;
        }


        ///
        override string toString()
        {
            string result;

            // DMD 0.92 says error: cannot implicitly convert uint to PlatformId
            switch(platId)
            {
                case PlatformId.WIN64_WINDOWS:
                    result = "Microsoft Windows (64-bit) ";
                break;
                case PlatformId.WIN32_NT:
                    result = "Microsoft Windows NT ";
                    break;

                case PlatformId.WIN32_WINDOWS:
                    result = "Microsoft Windows 95 ";
                    break;

                case PlatformId.WIN32s:
                    result = "Microsoft Win32s ";
                    break;

                case PlatformId.WIN_CE:
                    result = "Microsoft Windows CE ";
                    break;


                default:
                    throw new DflException("Unknown platform ID");
            }

            result ~= vers.toString();
            return result;
        }


        ///
        @property PlatformId platform() // getter
        {
            return platId;
        }


        ///
        // Should be version() :p
        @property Version ver() // getter
        {
            return vers;
        }
    }


    private:
    PlatformId platId;
    Version vers;
}

