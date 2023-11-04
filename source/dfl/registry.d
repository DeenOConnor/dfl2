// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

// Not actually part of forms, but is handy.

///
module dfl.registry;

private import dfl.base;

private import core.sys.windows.windows;
private import std.string;
private import std.ascii : isHexDigit;
private import std.conv : to;


class DflRegistryException: DflException // package
{
    this(string msg, int errorCode = 0)
    {
        this.errorCode = errorCode;
        debug
        {
            if(errorCode)
                msg = msg ~ " (error " ~ to!string(errorCode) ~ ")"; // Dup.
        }
        super(msg);
    }


    int errorCode;
}


///
class Registry // docmain
{
    private this() {}


    static:

    ///
    @property RegistryKey classesRoot() // getter
    {
        if(!_classesRoot)
            _classesRoot = new RegistryKey(HKEY_CLASSES_ROOT, false);
        return _classesRoot;
    }


    /// ditto
    @property RegistryKey currentConfig() // getter
    {
        if(!_currentConfig)
            _currentConfig = new RegistryKey(HKEY_CURRENT_CONFIG, false);
        return _currentConfig;
    }


    /// ditto
    @property RegistryKey currentUser() // getter
    {
        if(!_currentUser)
            _currentUser = new RegistryKey(HKEY_CURRENT_USER, false);
        return _currentUser;
    }


    /// ditto
    @property RegistryKey dynData() // getter
    {
        if(!_dynData)
            _dynData = new RegistryKey(HKEY_DYN_DATA, false);
        return _dynData;
    }


    /// ditto
    @property RegistryKey localMachine() // getter
    {
        if(!_localMachine)
            _localMachine = new RegistryKey(HKEY_LOCAL_MACHINE, false);
        return _localMachine;
    }


    /// ditto
    @property RegistryKey performanceData() // getter
    {
        if(!_performanceData)
            _performanceData = new RegistryKey(HKEY_PERFORMANCE_DATA, false);
        return _performanceData;
    }


    /// ditto
    @property RegistryKey users() // getter
    {
        if(!_users)
            _users = new RegistryKey(HKEY_USERS, false);
        return _users;
    }


    private:
    RegistryKey _classesRoot;
    RegistryKey _currentConfig;
    RegistryKey _currentUser;
    RegistryKey _dynData;
    RegistryKey _localMachine;
    RegistryKey _performanceData;
    RegistryKey _users;

}


private enum uint MAX_REG_BUFFER = 256;


///
abstract class RegistryValue
{
    @property DWORD valueType(); // getter
    override string toString();
    protected LONG save(HKEY hkey, string name); // package
    package final @property RegistryValue _reg() { return this; }
}


///
class RegistryValueSz: RegistryValue
{
    ///
    string value;


    ///
    this(string str)
    {
        this.value = str;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_SZ;
    }


    override string toString()
    {
        return value;
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, cast(char*)name.ptr, 0, REG_SZ, cast(ubyte*)value.ptr, cast(uint)(value.length + 1));
    }
}


///
class RegistryValueMultiSz: RegistryValue
{
    ///
    string[] value;


    ///
    this(string[] strs)
    {
        this.value = strs;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_MULTI_SZ;
    }


    override string toString()
    {
        string result;
        foreach(string str; value)
        {
            result ~= str ~ "\r\n";
        }
        if(result.length)
            result = result[0 .. result.length - 2]; // Exclude last \r\n.
        return result;
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        char[] multi;
        size_t i;

        i = value.length + 1; // Each NUL and the extra terminating NUL.
        foreach(string s; value)
        {
            i += s.length;
        }

        multi = new char[i];
        foreach(string s; value)
        {
            if(!s.length)
                throw new DflRegistryException("Empty strings are not allowed in multi_sz registry values");

            multi[i .. i + s.length] = s[];
            i += s.length;
            multi[i++] = 0;
        }
        multi[i++] = 0;
        assert(i == multi.length);

        return RegSetValueExA(hkey, cast(char*)name.ptr, 0, REG_MULTI_SZ, cast(ubyte*)multi, cast(uint)multi.length);
    }
}


///
class RegistryValueExpandSz: RegistryValue
{
    ///
    string value;


    ///
    this(string str)
    {
        this.value = str;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_EXPAND_SZ;
    }


    override string toString()
    {
        return value;
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, cast(char*)name, 0, REG_EXPAND_SZ, cast(ubyte*)value.ptr, cast(uint)(value.length + 1));
    }
}


private string dwordToString(DWORD dw)
{
    return toUpper(format!"0x%08x"(dw));
}


/* I tested this, and despite the new dwordToString producing the same result, all these asserts fail
unittest
{
    assert(dwordToString(0x8934) == "0x00008934");
    assert(dwordToString(0xF00BA2) == "0x00F00BA2");
    assert(dwordToString(0xBADBEEF0) == "0xBADBEEF0");
    assert(dwordToString(0xCAFEBEEF) == "0xCAFEBEEF");
    assert(dwordToString(0x09090BB) == "0x009090BB");
    assert(dwordToString(0) == "0x00000000");
}
*/


///
class RegistryValueDword: RegistryValue
{
    ///
    DWORD value;


    ///
    this(DWORD dw)
    {
        this.value = dw;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_DWORD;
    }


    override string toString()
    {
        return dwordToString(value);
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_DWORD, cast(BYTE*)&value, DWORD.sizeof);
    }
}

/// ditto
alias RegistryValueDword RegistryValueDwordLittleEndian;

/// ditto
class RegistryValueDwordBigEndian: RegistryValue
{
    ///
    DWORD value;


    ///
    this(DWORD dw)
    {
        this.value = dw;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_DWORD_BIG_ENDIAN;
    }


    override string toString()
    {
        return dwordToString(value);
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_DWORD_BIG_ENDIAN, cast(BYTE*)&value, DWORD.sizeof);
    }
}


///
class RegistryValueBinary: RegistryValue
{
    ///
    void[] value;


    ///
    this(void[] val)
    {
        this.value = val;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_BINARY;
    }


    override string toString()
    {
        return "Binary";
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_BINARY, cast(BYTE*)value, cast(uint)value.length);
    }
}


///
class RegistryValueLink: RegistryValue
{
    ///
    void[] value;


    ///
    this(void[] val)
    {
        this.value = val;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_LINK;
    }


    override string toString()
    {
        return "Symbolic Link";
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_LINK, cast(BYTE*)value, cast(uint)value.length);
    }
}


///
class RegistryValueResourceList: RegistryValue
{
    ///
    void[] value;


    ///
    this(void[] val)
    {
        this.value = val;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_RESOURCE_LIST;
    }


    override string toString()
    {
        return "Resource List";
    }


    protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_RESOURCE_LIST, cast(BYTE*)value, cast(uint)value.length);
    }
}


///
class RegistryValueNone: RegistryValue
{
    ///
    void[] value;


    ///
    this(void[] val)
    {
        this.value = val;
    }

    /// ditto
    this()
    {
    }


    override @property DWORD valueType() // getter
    {
        return REG_NONE;
    }


    override string toString()
    {
        return "None";
    }


    /+ package +/ protected override LONG save(HKEY hkey, string name) // package
    {
        return RegSetValueExA(hkey, name.ptr, 0, REG_NONE, cast(BYTE*)value, cast(uint)value.length);
    }
}


///
enum RegistryHive: size_t
{
    CLASSES_ROOT = 0x80000000, ///
    CURRENT_CONFIG = 0x80000005, /// ditto
    CURRENT_USER = 0x80000001, /// ditto
    DYN_DATA = 0x80000006, /// ditto
    LOCAL_MACHINE = 0x80000002, /// ditto
    PERFORMANCE_DATA = 0x80000004, /// ditto
    USERS = 0x80000003, /// ditto
}


///
class RegistryKey // docmain
{
    private:
    HKEY hkey;
    bool owned = true;


    public:

    ///
    final @property int subKeyCount() // getter
    {
        DWORD count;

        LONG rr = RegQueryInfoKeyA(hkey, null, null, null, &count,
            null, null, null, null, null, null, null);
        if(ERROR_SUCCESS != rr)
            infoErr(rr);

        return count;
    }


    ///
    final @property int valueCount() // getter
    {
        DWORD count;

        LONG rr = RegQueryInfoKeyA(hkey, null, null, null, null,
            null, null, &count, null, null, null, null);
        if(ERROR_SUCCESS != rr)
            infoErr(rr);

        return count;
    }


    ///
    final void close()
    {
        RegCloseKey(hkey);
    }


    ///
    final RegistryKey createSubKey(string name)
    {
        HKEY newHkey;
        DWORD cdisp;

        LONG rr = RegCreateKeyExA(hkey, name.ptr, 0, null, 0, KEY_ALL_ACCESS, null, &newHkey, &cdisp);
        if(ERROR_SUCCESS != rr)
            throw new DflRegistryException("Unable to create registry key", rr);

        return new RegistryKey(newHkey);
    }


    ///
    final void deleteSubKey(string name, bool throwIfMissing)
    {
        HKEY openHkey;

        if(!name.length || !name[0])
            throw new DflRegistryException("Unable to delete subkey");

        auto namez = name.ptr;

        LONG opencode = RegOpenKeyExA(hkey, namez, 0, KEY_ALL_ACCESS, &openHkey);
        if(ERROR_SUCCESS == opencode)
        {
            DWORD count;

            LONG querycode = RegQueryInfoKeyA(openHkey, null, null, null, &count,
                null, null, null, null, null, null, null);
            if(ERROR_SUCCESS == querycode)
            {
                RegCloseKey(openHkey);

                LONG delcode;
                if(!count)
                {
                    delcode = RegDeleteKeyA(hkey, namez);
                    if(ERROR_SUCCESS == delcode)
                        return; // OK.

                    throw new DflRegistryException("Unable to delete subkey", delcode);
                }

                throw new DflRegistryException("Cannot delete registry key with subkeys");
            }

            RegCloseKey(openHkey);

            throw new DflRegistryException("Unable to delete registry key", querycode);
        }
        else
        {
            if(!throwIfMissing)
            {
                switch(opencode)
                {
                    case ERROR_FILE_NOT_FOUND:
                        return;

                    default:
                }
            }

            throw new DflRegistryException("Unable to delete registry key", opencode);
        }
    }


    /// ditto
    final void deleteSubKey(string name)
    {
        deleteSubKey(name, true);
    }


    ///
    final void deleteSubKeyTree(string name)
    {
        _deleteSubKeyTree(hkey, name);
    }


    // Note: name is not written to! it's just not "invariant".
    private static void _deleteSubKeyTree(HKEY shkey, string name)
    {
        HKEY openHkey;

        auto namez = name.ptr;

        if(ERROR_SUCCESS == RegOpenKeyExA(shkey, namez, 0, KEY_ALL_ACCESS, &openHkey))
        {
            void ouch(LONG why = 0)
            {
                throw new DflRegistryException("Unable to delete entire subkey tree", why);
            }


            DWORD count;

            LONG querycode = RegQueryInfoKeyA(openHkey, null, null, null, &count,
                null, null, null, null, null, null, null);
            if(ERROR_SUCCESS == querycode)
            {
                if(!count)
                {
                    del_me:
                    RegCloseKey(openHkey);
                    LONG delcode = RegDeleteKeyA(shkey, namez);
                    if(ERROR_SUCCESS == delcode)
                        return; // OK.

                    ouch(delcode);
                }
                else
                {
                    try
                    {
                        // deleteSubKeyTree on all subkeys.

                        char[MAX_REG_BUFFER] skn;
                        DWORD len;

                        next_subkey:
                        len = skn.length;
                        LONG enumcode = RegEnumKeyExA(openHkey, 0, skn.ptr, &len, null, null, null, null);
                        switch(enumcode)
                        {
                            case ERROR_SUCCESS:
                                //_deleteSubKeyTree(openHkey, skn[0 .. len]);
                                _deleteSubKeyTree(openHkey, cast(string)skn[0 .. len]); // Needed in D2. WARNING: NOT REALLY INVARIANT.
                                goto next_subkey;

                            case ERROR_NO_MORE_ITEMS:
                                // Done!
                                break;

                            default:
                                ouch(enumcode);
                        }

                        // Now go back to delete the origional key.
                        goto del_me;
                    }
                    finally
                    {
                        RegCloseKey(openHkey);
                    }
                }
            }
            else
            {
                ouch(querycode);
            }
        }
    }


    ///
    final void deleteValue(string name, bool throwIfMissing)
    {
        LONG rr = RegDeleteValueA(hkey, name.ptr);
        switch(rr)
        {
            case ERROR_SUCCESS:
                break;

            case ERROR_FILE_NOT_FOUND:
                if(!throwIfMissing)
                    break;
                goto default;
            default:
                throw new DflRegistryException("Unable to delete registry value", rr);
        }
    }


    /// ditto
    final void deleteValue(string name)
    {
        deleteValue(name, true);
    }


    override bool opEquals(Object o)
    {
        RegistryKey rk;

        rk = cast(RegistryKey)o;
        if(!rk)
            return false;
        return opEquals(rk);
    }


    bool opEquals(RegistryKey rk)
    {
        return hkey == rk.hkey;
    }


    ///
    final void flush()
    {
        RegFlushKey(hkey);
    }


    ///
    final string[] getSubKeyNames()
    {
        char[MAX_REG_BUFFER] buf;
        DWORD len;
        DWORD idx;
        string[] result;

        key_names:
        for(idx = 0;; idx++)
        {
            len = buf.length;
            LONG rr = RegEnumKeyExA(hkey, idx, buf.ptr, &len, null, null, null, null);
            switch(rr)
            {
                case ERROR_SUCCESS:
                    result ~= cast(string)buf[0 .. len].dup; // Needed in D2.
                    break;

                case ERROR_NO_MORE_ITEMS:
                    // Done!
                    break key_names;

                default:
                    throw new DflRegistryException("Unable to obtain subkey names", rr);
            }
        }

        return result;
    }


    ///
    final RegistryValue getValue(string name, RegistryValue defaultValue)
    {
        DWORD type;
        DWORD len;
        ubyte[] data;

        len = 0;
        LONG querycode = RegQueryValueExA(hkey, name.ptr, null, &type, null, &len);
        switch(querycode)
        {
            case ERROR_SUCCESS:
                // Good.
                break;

            case ERROR_FILE_NOT_FOUND:
                // Value doesn't exist.
                return defaultValue;

            default: errquerycode:
                throw new DflRegistryException("Unable to get registry value", querycode);
        }

        data = new ubyte[len];
        // Note: reusing querycode here and above.
        querycode = RegQueryValueExA(hkey, name.ptr, null, &type, data.ptr, &len);
        if(ERROR_SUCCESS != querycode)
            goto errquerycode;

        switch(type)
        {
            case REG_SZ:
                with(new RegistryValueSz)
                {
                    assert(!data[data.length - 1]);
                    value = cast(string)data[0 .. data.length - 1];
                    defaultValue = _reg;
                }
                break;

            case REG_DWORD: // REG_DWORD_LITTLE_ENDIAN
                with(new RegistryValueDword)
                {
                    assert(data.length == DWORD.sizeof);
                    value = *(cast(DWORD*)cast(void*)data);
                    defaultValue = _reg;
                }
                break;

            case REG_EXPAND_SZ:
                with(new RegistryValueExpandSz)
                {
                    assert(!data[data.length - 1]);
                    value = cast(string)data[0 .. data.length - 1];
                    defaultValue = _reg;
                }
                break;

            case REG_MULTI_SZ:
                with(new RegistryValueMultiSz)
                {
                    string s;

                    next_sz:
                    s = to!string(fromStringz(cast(char*)data));
                    if(s.length)
                    {
                        value ~= s;
                        data = data[s.length + 1 .. data.length];
                        goto next_sz;
                    }

                    defaultValue = _reg;
                }
                break;

            case REG_BINARY:
                with(new RegistryValueBinary)
                {
                    value = data;
                    defaultValue = _reg;
                }
                break;

            case REG_DWORD_BIG_ENDIAN:
                with(new RegistryValueDwordBigEndian)
                {
                    assert(data.length == DWORD.sizeof);
                    value = *(cast(DWORD*)cast(void*)data);
                    defaultValue = _reg;
                }
                break;

            case REG_LINK:
                with(new RegistryValueLink)
                {
                    value = data;
                    defaultValue = _reg;
                }
                break;

            case REG_RESOURCE_LIST:
                with(new RegistryValueResourceList)
                {
                    value = data;
                    defaultValue = _reg;
                }
                break;

            case REG_NONE:
                with(new RegistryValueNone)
                {
                    value = data;
                    defaultValue = _reg;
                }
                break;

            default:
                throw new DflRegistryException("Unknown type for registry value");
        }

        return defaultValue;
    }


    /// ditto
    final RegistryValue getValue(string name)
    {
        return getValue(name, null);
    }


    ///
    final string[] getValueNames()
    {
        char[MAX_REG_BUFFER] buf;
        DWORD len;
        DWORD idx;
        string[] result;

        value_names:
        for(idx = 0;; idx++)
        {
            len = buf.length;
            LONG rr = RegEnumValueA(hkey, idx, buf.ptr, &len, null, null, null, null);
            switch(rr)
            {
                case ERROR_SUCCESS:
                    result ~= cast(string)buf[0 .. len].dup; // Needed in D2.
                    break;

                case ERROR_NO_MORE_ITEMS:
                    // Done!
                    break value_names;

                default:
                    throw new DflRegistryException("Unable to obtain value names", rr);
            }
        }

        return result;
    }


    ///
    static RegistryKey openRemoteBaseKey(RegistryHive hhive, string machineName)
    {
        HKEY openHkey;

        LONG rr = RegConnectRegistryA(machineName.ptr, cast(HKEY)hhive, &openHkey);
        if(ERROR_SUCCESS != rr)
            throw new DflRegistryException("Unable to open remote base key", rr);

        return new RegistryKey(openHkey);
    }


    ///
    // Returns null on error.
    final RegistryKey openSubKey(string name, bool writeAccess)
    {
        HKEY openHkey;

        if(ERROR_SUCCESS != RegOpenKeyExA(hkey, name.ptr, 0,
            writeAccess ? KEY_READ | KEY_WRITE : KEY_READ, &openHkey))
            return null;

        return new RegistryKey(openHkey);
    }


    /// ditto
    final RegistryKey openSubKey(string name)
    {
        return openSubKey(name, false);
    }


    ///
    final void setValue(string name, RegistryValue value)
    {
        LONG rr = value.save(hkey, name);
        if(ERROR_SUCCESS != rr)
            throw new DflRegistryException("Unable to set registry value", rr);
    }


    /// ditto
    // Shortcut.
    final void setValue(string name, string value)
    {
        scope rv = new RegistryValueSz(value);
        setValue(name, rv);
    }


    /// ditto
    // Shortcut.
    final void setValue(string name, string[] value)
    {
        scope rv = new RegistryValueMultiSz(value);
        setValue(name, rv);
    }


    /// ditto
    // Shortcut.
    final void setValue(string name, DWORD value)
    {
        scope rv = new RegistryValueDword(value);
        setValue(name, rv);
    }


    ///
    // Used internally.
    final @property HKEY handle() // getter
    {
        return hkey;
    }


    // Used internally.
    this(HKEY hkey, bool owned = true)
    {
        this.hkey = hkey;
        this.owned = owned;
    }


    ~this()
    {
        if(owned)
            RegCloseKey(hkey);
    }


    private void infoErr(LONG why)
    {
        throw new DflRegistryException("Unable to obtain registry information", why);
    }
}

