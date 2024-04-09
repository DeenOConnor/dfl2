// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.data;

private import dfl.base;
private import dfl.application;

private import core.sys.windows.com;
private import core.sys.windows.objidl;
private import core.sys.windows.shlobj;
private import core.sys.windows.winbase;
private import core.sys.windows.windows;
private import core.sys.windows.winuser;
private import core.sys.windows.wtypes;

private import std.conv : to;
private import std.string : icmp, fromStringz, toStringz;
private import std.utf : toUTF8;
private import core.exception : OutOfMemoryError;


///
class DataFormats // docmain
{
    ///
    static class Format // docmain
    {
        /// Data format ID number.
        final @property int id() // getter
        {
            return _id;
        }


        /// Data format name.
        final @property string name() // getter
        {
            return _name;
        }


        package:
        int _id;
        string _name;


        this()
        {
        }
    }


    static:

    /// Predefined data formats.
    @property string bitmap() // getter
    {
        return getFormat(CF_BITMAP).name;
    }

    /// ditto
    @property string dib() // getter
    {
        return getFormat(CF_DIB).name;
    }

    /// ditto
    @property string dif() // getter
    {
        return getFormat(CF_DIF).name;
    }

    /// ditto
    @property string enhandedMetaFile() // getter
    {
        return getFormat(CF_ENHMETAFILE).name;
    }

    /// ditto
    @property string fileDrop() // getter
    {
        return getFormat(CF_HDROP).name;
    }

    /// ditto
    @property string html() // getter
    {
        return getFormat("HTML Format").name;
    }

    /// ditto
    @property string locale() // getter
    {
        return getFormat(CF_LOCALE).name;
    }

    /// ditto
    @property string metafilePict() // getter
    {
        return getFormat(CF_METAFILEPICT).name;
    }

    /// ditto
    @property string oemText() // getter
    {
        return getFormat(CF_OEMTEXT).name;
    }

    /// ditto
    @property string palette() // getter
    {
        return getFormat(CF_PALETTE).name;
    }

    /// ditto
    @property string penData() // getter
    {
        return getFormat(CF_PENDATA).name;
    }

    /// ditto
    @property string riff() // getter
    {
        return getFormat(CF_RIFF).name;
    }

    /// ditto
    @property string rtf() // getter
    {
        return getFormat("Rich Text Format").name;
    }

    /// ditto
    @property string stringFormat() // getter
    {
        return utf8; // ?
    }

    /// ditto
    @property string utf8() // getter
    {
        return getFormat("UTF-8").name;
    }

    /// ditto
    @property string symbolicLink() // getter
    {
        return getFormat(CF_SYLK).name;
    }

    /// ditto
    @property string text() // getter
    {
        return getFormat(CF_TEXT).name;
    }

    /// ditto
    @property string tiff() // getter
    {
        return getFormat(CF_TIFF).name;
    }

    /// ditto
    @property string unicodeText() // getter
    {
        return getFormat(CF_UNICODETEXT).name;
    }

    /// ditto
    @property string waveAudio() // getter
    {
        return getFormat(CF_WAVE).name;
    }


    // Assumes _init() was already called and
    // -id- is not in -fmts-.
    private Format _didntFindId(int id)
    {
        Format result;
        result = new Format;
        result._id = id;
        result._name = getName(id);
        {
            fmts[id] = result;
        }
        return result;
    }


    ///
    Format getFormat(int id)
    {
        _init();

        if(id in fmts)
            return fmts[id];

        return _didntFindId(id);
    }

    /// ditto
    // Creates the format name if it doesn't exist.
    Format getFormat(string name)
    {
        _init();
        foreach(Format onfmt; fmts)
        {
            if(!icmp(name, onfmt.name))
                return onfmt;
        }
        // Didn't find it.
        return _didntFindId(RegisterClipboardFormatA(name.ptr));
    }

    /// ditto
    // Extra.
    Format getFormat(TypeInfo type)
    {
        return getFormatFromType(type);
    }


    private:
    Format[int] fmts; // Indexed by identifier. Must _init() before accessing!


    void _init()
    {
        if(fmts.length)
            return;


        void initfmt(int id, string name)
        in
        {
            assert(!(id in fmts));
        }
        do
        {
            Format fmt;
            fmt = new Format;
            fmt._id = id;
            fmt._name = name;
            fmts[id] = fmt;
        }


        initfmt(CF_BITMAP, "Bitmap");
        initfmt(CF_DIB, "DeviceIndependentBitmap");
        initfmt(CF_DIF, "DataInterchangeFormat");
        initfmt(CF_ENHMETAFILE, "EnhancedMetafile");
        initfmt(CF_HDROP, "FileDrop");
        initfmt(CF_LOCALE, "Locale");
        initfmt(CF_METAFILEPICT, "MetaFilePict");
        initfmt(CF_OEMTEXT, "OEMText");
        initfmt(CF_PALETTE, "Palette");
        initfmt(CF_PENDATA, "PenData");
        initfmt(CF_RIFF, "RiffAudio");
        initfmt(CF_SYLK, "SymbolicLink");
        initfmt(CF_TEXT, "Text");
        initfmt(CF_TIFF, "TaggedImageFileFormat");
        initfmt(CF_UNICODETEXT, "UnicodeText");
        initfmt(CF_WAVE, "WaveAudio");

        fmts.rehash;
    }


    // Does not get the name of one of the predefined constant ones.
    string getName(int id)
    {
        char[] buf;
        int len;
        buf = new char[64];
        len = GetClipboardFormatNameA(id, buf.ptr, 64);
        if(len == 0)
            throw new DflException("Unable to get format");
        return to!string(fromStringz(buf));
    }


    package Format getFormatFromType(TypeInfo type)
    {
        if(type == typeid(ubyte[]))
            return getFormat(text);
        if(type == typeid(string))
            return getFormat(stringFormat);
        if(type == typeid(wstring))
            return getFormat(unicodeText);

        if(cast(TypeInfo_Class)type)
            throw new DflException("Unknown data format");

        return getFormat(type.toString()); // ?
    }


    private string[] getHDropStrings(void[] value)
    {
        if(value.length <= DROPFILES.sizeof)
            return null;

        string[] result;
        DROPFILES* df;
        size_t iw, startiw;

        df = cast(DROPFILES*)value.ptr;
        if(df.pFiles < DROPFILES.sizeof || df.pFiles >= value.length)
            return null;

        if(df.fWide) // Unicode.
        {
            wstring uni = cast(wstring)((value.ptr + df.pFiles)[0 .. value.length]);
            for(iw = startiw = 0;; iw++)
            {
                if(!uni[iw])
                {
                    if(startiw == iw)
                        break;
                    result ~= toUTF8((uni.ptr + startiw)[0..iw - startiw]);
                    assert(result[result.length - 1].length);
                    startiw = iw + 1;
                }
            }
        }
        else // ANSI.
        {
            string ansi = cast(string)((value.ptr + df.pFiles)[0 .. value.length]);
            for(iw = startiw = 0;; iw++)
            {
                if(!ansi[iw])
                {
                    if(startiw == iw)
                        break;
                    result ~= to!string((ansi.ptr + startiw)[0..iw - startiw]);
                    assert(result[result.length - 1].length);
                    startiw = iw + 1;
                }
            }
        }

        return result;
    }


    // Convert clipboard -value- to Data.
    Data getDataFromFormat(int id, void[] value)
    {
        switch(id)
        {
            case CF_TEXT:
                return Data(stopAtNull!(ubyte)(cast(ubyte[])value));

            case CF_UNICODETEXT:
                return Data(stopAtNull!(wchar)(cast(wchar[])value));

            case CF_HDROP:
                return Data(getHDropStrings(value));

            default:
                if(id == getFormat(stringFormat).id)
                    return Data(stopAtNull!(char)(cast(char[])value));
        }

        return Data(value); // ?
    }


    void[] getCbFileDrop(string[] fileNames)
    {
        size_t sz = DROPFILES.sizeof;
        void* p;
        DROPFILES* df;

        foreach(fn; fileNames)
        {
            sz += (fn.length + 1) << 1;
        }
        sz += 2;

        p = (new byte[sz]).ptr;
        df = cast(DROPFILES*)p;

        df.pFiles = DROPFILES.sizeof;
        df.fWide = true;

        wchar* ws = cast(wchar*)(p + DROPFILES.sizeof);
        foreach(fn; fileNames)
        {
            foreach(wchar wch; fn)
            {
                *ws++ = wch;
            }
            *ws++ = 0;
        }
        *ws++ = 0;

        return p[0 .. sz];
    }


    // Value the clipboard wants.
    void[] getClipboardValueFromData(int id, Data data)
    {
        if(CF_TEXT == id)
        {
            // ANSI text.
            enum ubyte[] UBYTE_ZERO = [0];
            return data.getText() ~ UBYTE_ZERO;
        }
        else if((getFormat(stringFormat).id == id) || (data.info == typeid(string)))
        {
            // UTF-8 string.
            string str;
            str = data.getString();
            return cast(void[])str[0 .. str.length + 1]; // ? Needed in D2.
        }
        else if((CF_UNICODETEXT == id) || (data.info == typeid(wstring)))
        {
            // Unicode string.
            return (data.getUnicodeText() ~ cast(wstring)"\0").dup; // Needed in D2.
        }
        else if(data.info == typeid(string))
        {
            return ((*cast(string*)data.value) ~ "\0").dup; // Needed in D2.
        }
        else if(CF_HDROP == id)
        {
            return getCbFileDrop(data.getStrings());
        }
        else if(data.info == typeid(void[]) || data.info == typeid(string)
            || data.info == typeid(ubyte[]) || data.info == typeid(byte[])) // Hack ?
        {
            return *cast(void[]*)data.value; // Save the array elements, not the reference.
        }
        else
        {
            return data.value; // ?
        }
    }
}


private template stopAtNull(T)
{
    T[] stopAtNull(T[] array)
    {
        int i;
        for(i = 0; i != array.length; i++)
        {
            if(!array[i])
                return array[0 .. i];
        }
        //return null;
        throw new DflException("Invalid data"); // ?
    }
}


/// Data structure for holding data in a raw format with type information.
struct Data // docmain
{
    /// Information about the data type.
    @property TypeInfo info() // getter
    {
        return _info;
    }


    /// The data's raw value.
    @property void[] value() // getter
    {
        return _value[0 .. _info.tsize()];
    }


    /// Construct a new Data structure.
    static Data opCall(...)
    in
    {
        assert(_arguments.length == 1);
    }
    do
    {
        Data result;
        result._info = _arguments[0];
        result._value = _argptr[0 .. result._info.tsize()].dup.ptr;
        return result;
    }


    ///
    T getValue(T)()
    {
        assert(_info.tsize == T.sizeof);
        return *cast(T*)_value;
    }

    /// ditto
    // UTF-8.
    string getString()
    {
        assert(_info == typeid(string) || _info == typeid(void[]));
        return *cast(string*)_value;
    }

    /// ditto
    alias getString getUtf8;
    /// ditto
    deprecated alias getString getUTF8;

    /// ditto
    // ANSI text.
    ubyte[] getText()
    {
        assert(_info == typeid(ubyte[]) || _info == typeid(byte[]) || _info == typeid(void[]));
        return *cast(ubyte[]*)_value;
    }

    /// ditto
    wstring getUnicodeText()
    {
        assert(_info == typeid(wstring) || _info == typeid(void[]));
        return to!wstring(_value);
    }

    /// ditto
    int getInt()
    {
        return getValue!(int)();
    }

    /// ditto
    int getUint()
    {
        return getValue!(uint)();
    }

    /// ditto
    string[] getStrings()
    {
        assert(_info == typeid(string[]));
        return *cast(string[]*)_value;
    }

    /// ditto
    Object getObject()
    {
        assert(!(cast(TypeInfo_Class)_info is null));
        return cast(Object)*cast(Object**)_value;
    }


    private:
    TypeInfo _info;
    void* _value;
}


/// Interface to a DFL data object. The data can have different formats by setting different formats.
interface IDflDataObject // docmain
{
    ///
    Data getData(string fmt);
    /// ditto
    Data getData(TypeInfo type);
    /// ditto
    Data getData(string fmt, bool doConvert);

    ///
    bool getDataPresent(string fmt); // Check.
    /// ditto
    bool getDataPresent(TypeInfo type); // Check.
    /// ditto
    bool getDataPresent(string fmt, bool canConvert); // Check.

    ///
    string[] getFormats();
    //string[] getFormats(bool onlyNative);

    ///
    void setData(Data obj);
    /// ditto
    void setData(string fmt, Data obj);
    /// ditto
    void setData(TypeInfo type, Data obj);
    /// ditto
    void setData(string fmt, bool canConvert, Data obj);
}


///
class DataObject: IDflDataObject // docmain
{
    ///
    Data getData(string fmt)
    {
        return getData(fmt, true);
    }

    /// ditto
    Data getData(TypeInfo type)
    {
        return getData(DataFormats.getFormat(type).name);
    }

    /// ditto
    Data getData(string fmt, bool doConvert)
    {
        // doConvert ...
        int i;
        i = find(fmt);
        if(i == -1)
            throw new DflException("Data format not present");
        return all[i].obj;
    }


    ///
    bool getDataPresent(string fmt)
    {
        return getDataPresent(fmt, true);
    }

    /// ditto
    bool getDataPresent(TypeInfo type)
    {
        return getDataPresent(DataFormats.getFormat(type).name);
    }

    /// ditto
    bool getDataPresent(string fmt, bool canConvert)
    {
        // canConvert ...
        return find(fmt) != -1;
    }


    ///
    string[] getFormats()
    {
        string[] result;
        result = new string[all.length];
        foreach(i, ref string fmt; result)
        {
            fmt = all[i].fmt;
        }
        return result;
    }


    // TO-DO: remove...
    deprecated final string[] getFormats(bool onlyNative)
    {
        return getFormats();
    }


    package final void _setData(string fmt, Data obj, bool replace = true)
    {
        int i;
        i = find(fmt, false);
        if(i != -1)
        {
            if(replace)
                all[i].obj = obj;
        }
        else
        {
            Pair pair;
            pair.fmt = fmt;
            pair.obj = obj;
            all ~= pair;
        }
    }


    ///
    void setData(Data obj)
    {
        setData(DataFormats.getFormat(obj.info).name, obj);
    }


    /// ditto
    void setData(string fmt, Data obj)
    {
        setData(fmt, true, obj);
    }


    /// ditto
    void setData(TypeInfo type, Data obj)
    {
        setData(DataFormats.getFormatFromType(type).name, true, obj);
    }


    /// ditto
    void setData(string fmt, bool canConvert, Data obj)
    {
        _setData(fmt, obj);
        if(canConvert)
        {
            Data cdat;
            cdat = Data(*(cast(_DataConvert*)&obj));
            _canConvertFormats(fmt,
                (string cfmt)
                {
                    _setData(cfmt, cdat, false);
                });
        }
    }


    private:
    struct Pair
    {
        string fmt;
        Data obj;
    }


    Pair[] all;


    void fixPairEntry(ref Pair pr)
    {
        assert(pr.obj.info == typeid(_DataConvert));
        Data obj;
        void[] objv;
        objv = pr.obj.value;
        assert(objv.length == Data.sizeof);
        obj = *(cast(Data*)objv.ptr);
        pr.obj = _doConvertFormat(obj, pr.fmt);
    }


    int find(string fmt, bool fix = true)
    {
        int i;
        for(i = 0; i != all.length; i++)
        {
            if(!icmp(all[i].fmt, fmt))
            {
                if(fix && all[i].obj.info == typeid(_DataConvert))
                    fixPairEntry(all[i]);
                return i;
            }
        }
        return -1;
    }
}


private struct _DataConvert
{
    Data data;
}


package void _canConvertFormats(string fmt, void delegate(string cfmt) callback)
{
    if(!icmp(fmt, "UTF-8"))
    {
        callback(DataFormats.unicodeText);
        callback(DataFormats.text);
    }
    else if(!icmp(fmt, DataFormats.unicodeText))
    {
        callback("UTF-8");
        callback(DataFormats.text);
    }
    else if(!icmp(fmt, DataFormats.text))
    {
        callback("UTF-8");
        callback(DataFormats.unicodeText);
    }
}


package Data _doConvertFormat(Data dat, string toFmt)
{
    Data result;
    if(!icmp(toFmt, "UTF-8"))
    {
        if(typeid(wstring) == dat.info)
        {
            result = Data(to!string(dat.getUnicodeText()));
        }
        else if(typeid(ubyte[]) == dat.info)
        {
            ubyte[] ubs;
            ubs = dat.getText();
            result = Data(to!string(fromStringz(cast(char[])ubs)));
        }
    }
    else if(!icmp(toFmt, DataFormats.unicodeText))
    {
        if(typeid(string) == dat.info)
        {
            result = Data(to!wstring(dat.getString()));
        }
        else if(typeid(ubyte[]) == dat.info)
        {
            ubyte[] ubs;
            ubs = dat.getText();
            result = Data(to!string(fromStringz(cast(char[])ubs)));
        }
    }
    else if(!icmp(toFmt, DataFormats.text))
    {
        if(typeid(string) == dat.info)
        {
            result = Data(cast(ubyte[])dat.getString());
        }
        else if(typeid(wstring) == dat.info)
        {
            wstring wcs;
            wcs = dat.getUnicodeText();
            result = Data(cast(ubyte[])to!string(wcs));
        }
    }
    return result;
}


class ComToDdataObject: IDflDataObject // package
{
    this(IDataObject dataObj)
    {
        this.dataObj = dataObj;
        dataObj.AddRef();
    }


    ~this()
    {
        dataObj.Release(); // Must get called...
    }


    private Data _getData(int id)
    {
        FORMATETC fmte;
        STGMEDIUM stgm;
        void[] mem;
        void* plock;

        fmte.cfFormat = cast(CLIPFORMAT)id;
        fmte.ptd = null;
        fmte.dwAspect = DVASPECT.DVASPECT_CONTENT; // ?
        fmte.lindex = -1;
        fmte.tymed = TYMED.TYMED_HGLOBAL; // ?

        if(S_OK != dataObj.GetData(&fmte, &stgm))
            throw new DflException("Unable to get data");


        void release()
        {
            if(stgm.pUnkForRelease)
                stgm.pUnkForRelease.Release();
            else
                GlobalFree(stgm.hGlobal);
        }


        plock = GlobalLock(stgm.hGlobal);
        if(!plock)
        {
            release();
            throw new DflException("Error obtaining data");
        }

        mem = new ubyte[GlobalSize(stgm.hGlobal)];
        mem[] = plock[0 .. mem.length];
        GlobalUnlock(stgm.hGlobal);
        release();

        return DataFormats.getDataFromFormat(id, mem);
    }


    Data getData(string fmt)
    {
        return _getData(DataFormats.getFormat(fmt).id);
    }


    Data getData(TypeInfo type)
    {
        return _getData(DataFormats.getFormatFromType(type).id);
    }


    Data getData(string fmt, bool doConvert)
    {
        return getData(fmt); // ?
    }


    private bool _getDataPresent(int id)
    {
        FORMATETC fmte;

        fmte.cfFormat = cast(CLIPFORMAT)id;
        fmte.ptd = null;
        fmte.dwAspect = DVASPECT.DVASPECT_CONTENT; // ?
        fmte.lindex = -1;
        fmte.tymed = TYMED.TYMED_HGLOBAL; // ?

        return S_OK == dataObj.QueryGetData(&fmte);
    }


    bool getDataPresent(string fmt)
    {
        return _getDataPresent(DataFormats.getFormat(fmt).id);
    }


    bool getDataPresent(TypeInfo type)
    {
        return _getDataPresent(DataFormats.getFormatFromType(type).id);
    }


    bool getDataPresent(string fmt, bool canConvert)
    {
        return getDataPresent(fmt); // ?
    }


    string[] getFormats()
    {
        IEnumFORMATETC fenum;
        FORMATETC fmte;
        string[] result;
        ULONG nfetched = 1; // ?

        if(S_OK != dataObj.EnumFormatEtc(1, &fenum))
            throw new DflException("Unable to get formats");

        fenum.AddRef(); // ?
        for(;;)
        {
            if(S_OK != fenum.Next(1, &fmte, &nfetched))
                break;
            if(!nfetched)
                break;
            result ~= DataFormats.getFormat(fmte.cfFormat).name;
        }
        fenum.Release(); // ?

        return result;
    }


    // TO-DO: remove...
    deprecated final string[] getFormats(bool onlyNative)
    {
        return getFormats();
    }


    private void _setData(int id, Data obj)
    {
        // Don't set stuff in someone else's data object.
        // Everything will probably break without this method, but there's no point in having it
        // TODO : Remove entirely
    }


    void setData(Data obj)
    {
        _setData(DataFormats.getFormatFromType(obj.info).id, obj);
    }


    void setData(string fmt, Data obj)
    {
        _setData(DataFormats.getFormat(fmt).id, obj);
    }


    void setData(TypeInfo type, Data obj)
    {
        _setData(DataFormats.getFormatFromType(type).id, obj);
    }


    void setData(string fmt, bool canConvert, Data obj)
    {
        setData(fmt, obj); // ?
    }


    final bool isSameDataObject(IDataObject dataObj)
    {
        return dataObj is this.dataObj;
    }


    private:
    IDataObject dataObj;
}


package class EnumDataObjectFORMATETC: ComObject, IEnumFORMATETC
{
    this(IDflDataObject dataObj, string[] fmts, ULONG start)
    {
        this.dataObj = dataObj;
        this.fmts = fmts;
        idx = start;
    }


    this(IDflDataObject dataObj)
    {
        this(dataObj, dataObj.getFormats(), 0);
    }


    extern(Windows):
    override HRESULT QueryInterface(IID* riid, void** ppv)
    {
        if(*riid == IID_IEnumFORMATETC)
        {
            *ppv = cast(void*)cast(IEnumFORMATETC)this;
            AddRef();
            return S_OK;
        }
        else if(*riid == IID_IUnknown)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        else
        {
            *ppv = null;
            return E_NOINTERFACE;
        }
    }


    HRESULT Next(ULONG celt, FORMATETC* rgelt, ULONG* pceltFetched)
    {
        HRESULT result;

        try
        {
            if(idx < fmts.length)
            {
                ULONG end;
                end = idx + celt;
                if(end > fmts.length)
                {
                    result = S_FALSE; // ?
                    end = cast(uint)fmts.length;

                    if(pceltFetched)
                        *pceltFetched = end - idx;
                }
                else
                {
                    result = S_OK;

                    if(pceltFetched)
                        *pceltFetched = celt;
                }

                for(; idx != end; idx++)
                {
                    rgelt.cfFormat = cast(CLIPFORMAT)DataFormats.getFormat(fmts[idx]).id;
                    rgelt.ptd = null;
                    rgelt.dwAspect = DVASPECT.DVASPECT_CONTENT; // ?
                    rgelt.lindex = -1;
                    rgelt.tymed = TYMED.TYMED_HGLOBAL;

                    rgelt++;
                }
            }
            else
            {
                if(pceltFetched)
                    *pceltFetched = 0;
                result = S_FALSE;
            }
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    HRESULT Skip(ULONG celt)
    {
        idx += celt;
        return (idx > fmts.length) ? S_FALSE : S_OK;
    }


    HRESULT Reset()
    {
        HRESULT result;

        try
        {
            idx = 0;
            fmts = dataObj.getFormats();

            result = S_OK;
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    HRESULT Clone(IEnumFORMATETC* ppenum)
    {
        HRESULT result;

        try
        {
            *ppenum = new EnumDataObjectFORMATETC(dataObj, fmts, idx);
            result = S_OK;
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    extern(D):

    private:
    IDflDataObject dataObj;
    string[] fmts;
    ULONG idx;
}


class DtoComDataObject: ComObject, IDataObject // package
{
    this(IDflDataObject dataObj)
    {
        this.dataObj = dataObj;
    }


    extern(Windows):

    override HRESULT QueryInterface(IID* riid, void** ppv)
    {
        if(*riid == IID_IDataObject)
        {
            *ppv = cast(void*)cast(IDataObject)this;
            AddRef();
            return S_OK;
        }
        else if(*riid == IID_IUnknown)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        else
        {
            *ppv = null;
            return E_NOINTERFACE;
        }
    }


    HRESULT GetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
    {
        string fmt;
        HRESULT result = S_OK;
        Data data;

        try
        {
            if(pFormatetc.lindex != -1)
            {
                result = DV_E_LINDEX;
            }
            else if(!(pFormatetc.tymed & TYMED.TYMED_HGLOBAL))
            {
                // Unsupported medium type.
                result = DV_E_TYMED;
            }
            else if(!(pFormatetc.dwAspect & DVASPECT.DVASPECT_CONTENT))
            {
                // What about the other aspects?
                result = DV_E_DVASPECT;
            }
            else
            {
                DataFormats.Format dfmt;
                dfmt = DataFormats.getFormat(pFormatetc.cfFormat);
                fmt = dfmt.name;
                data = dataObj.getData(fmt, true); // Should this be convertable?

                HGLOBAL hg;
                void* pmem;
                void[] src;

                src = DataFormats.getClipboardValueFromData(dfmt.id, data);
                hg = GlobalAlloc(0, cast(uint)src.length);
                if(!hg)
                {
                    result = STG_E_MEDIUMFULL;
                }
                else
                {
                    pmem = GlobalLock(hg);
                    if(!hg)
                    {
                        result = E_UNEXPECTED;
                        GlobalFree(hg);
                    }
                    else
                    {
                        pmem[0 .. src.length] = src[];
                        GlobalUnlock(hg);

                        pmedium.tymed = TYMED.TYMED_HGLOBAL;
                        pmedium.hGlobal = hg;
                        pmedium.pUnkForRelease = null; // ?
                    }
                }
            }
        }
        catch(DflException e)
        {
            result = DV_E_FORMATETC;
        }
        catch(OutOfMemoryError e)
        {
            Application.onThreadException(e);

            result = E_OUTOFMEMORY;
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    HRESULT GetDataHere(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
    {
        return E_UNEXPECTED; // TODO: finish.
    }


    HRESULT QueryGetData(FORMATETC* pFormatetc)
    {
        string fmt;
        HRESULT result = S_OK;

        try
        {
            if(pFormatetc.lindex != -1)
            {
                result = DV_E_LINDEX;
            }
            else if(!(pFormatetc.tymed & TYMED.TYMED_HGLOBAL))
            {
                // Unsupported medium type.
                result = DV_E_TYMED;
            }
            else if(!(pFormatetc.dwAspect & DVASPECT.DVASPECT_CONTENT))
            {
                // What about the other aspects?
                result = DV_E_DVASPECT;
            }
            else
            {
                fmt = DataFormats.getFormat(pFormatetc.cfFormat).name;

                if(!dataObj.getDataPresent(fmt))
                    result = S_FALSE; // ?
            }
        }
        catch(DflException e)
        {
            result = DV_E_FORMATETC;
        }
        catch(OutOfMemoryError e)
        {
            Application.onThreadException(e);

            result = E_OUTOFMEMORY;
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatetcIn, FORMATETC* pFormatetcOut)
    {
        // TODO: finish.

        pFormatetcOut.ptd = null;
        return E_NOTIMPL;
    }


    HRESULT SetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium, BOOL fRelease)
    {
        return E_UNEXPECTED; // TODO: finish.
    }


    HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppenumFormatetc)
    {
        HRESULT result;

        try
        {
            if(dwDirection == DATADIR.DATADIR_GET)
            {
                *ppenumFormatetc = new EnumDataObjectFORMATETC(dataObj);
                result = S_OK;
            }
            else
            {
                result = E_NOTIMPL;
            }
        }
        catch(Throwable e)
        {
            Application.onThreadException(e);

            result = E_UNEXPECTED;
        }

        return result;
    }


    HRESULT DAdvise(FORMATETC* pFormatetc, DWORD advf, IAdviseSink pAdvSink, DWORD* pdwConnection)
    {
        return E_UNEXPECTED; // TODO: finish.
    }


    HRESULT DUnadvise(DWORD dwConnection)
    {
        return E_UNEXPECTED; // TODO: finish.
    }


    HRESULT EnumDAdvise(IEnumSTATDATA* ppenumAdvise)
    {
        return E_UNEXPECTED; // TODO: finish.
    }


    extern(D):

    private:
    IDflDataObject dataObj;
}

