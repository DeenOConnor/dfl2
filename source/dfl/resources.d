// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.resources;

private import dfl.base;
private import dfl.drawing;

private import core.sys.windows.windows;

private import std.string : fromStringz, toStringz;
private import std.conv : to;
private import std.utf : toUTFz;


version(DFL_NO_RESOURCES)
{
}
else
{
    ///
    class Resources // docmain
    {
        ///
        this(HINSTANCE inst, WORD language = 0, bool owned = false)
        {
            this.hinst = inst;
            this.lang = language;
            this._owned = owned;
        }
        
        /// ditto
        // Note: libName gets unloaded and may take down all its resources with it.
        this(string libName, WORD language = 0)
        {
            HINSTANCE inst;
            inst = LoadLibraryExA(libName.ptr, null, LOAD_LIBRARY_AS_DATAFILE);
            if(!inst)
                throw new DflException("Unable to load resources from '" ~ libName ~ "'");
            this(inst, language, true); // Owned.
        }
        
        /+ // Let's not depend on Application; the user can do so if they wish.
        /// ditto
        this(WORD language = 0)
        {
            this(Application.getInstance(), language);
        }
        +/
        
        
        ///
        void dispose()
        {
            assert(_owned);
            //if(hinst != Application.getInstance()) // ?
                FreeLibrary(hinst);
            hinst = null;
        }
        
        
        ///
        final @property WORD language() // getter
        {
            return lang;
        }
        
        
        ///
        final Icon getIcon(int id, bool defaultSize = true)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            /+
            HICON hi;
            hi = LoadIconA(hinst, cast(LPCSTR)cast(WORD)id);
            if(!hi)
                return null;
            return Icon.fromHandle(hi);
            +/
            HICON hi;
            hi = cast(HICON)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON,
                0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
            if(!hi)
                return null;
            return new Icon(hi, true); // Owned.
        }
        
        /// ditto
        final Icon getIcon(string name, bool defaultSize = true)
        {
            /+
            HICON hi;
            hi = LoadIconA(hinst, unsafeStringz(name));
            if(!hi)
                return null;
            return Icon.fromHandle(hi);
            +/
            HICON hi;
            hi = LoadImageA(hinst, name.ptr, IMAGE_ICON,
                0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
            if(!hi)
                return null;
            return new Icon(hi, true); // Owned.
        }
        
        /// ditto
        final Icon getIcon(int id, int width, int height)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            // Can't have size 0 (plus causes Windows to use the actual size).
            //if(width <= 0 || height <= 0)
            //    _noload("icon");
            HICON hi;
            hi = cast(HICON)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON,
                width, height, 0);
            if(!hi)
                return null;
            return new Icon(hi, true); // Owned.
        }
        
        /// ditto
        final Icon getIcon(string name, int width, int height)
        {
            // Can't have size 0 (plus causes Windows to use the actual size).
            //if(width <= 0 || height <= 0)
            //    _noload("icon");
            HICON hi;
            hi = LoadImageA(hinst, name.ptr, IMAGE_ICON,
                width, height, 0);
            if(!hi)
                return null;
            return new Icon(hi, true); // Owned.
        }
        
        deprecated alias getIcon loadIcon;
        
        
        ///
        final Bitmap getBitmap(int id)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            HBITMAP h;
            h = cast(HBITMAP)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_BITMAP,
                0, 0, 0);
            if(!h)
                return null;
            return new Bitmap(h, true); // Owned.
        }
        
        /// ditto
        final Bitmap getBitmap(string name)
        {
            HBITMAP h;
            h = LoadImageA(hinst, name.ptr, IMAGE_BITMAP,
                0, 0, 0);
            if(!h)
                return null;
            return new Bitmap(h, true); // Owned.
        }
        
        deprecated alias getBitmap loadBitmap;
        
        
        ///
        final Cursor getCursor(int id)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            HCURSOR h;
            h = cast(HCURSOR)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_CURSOR,
                0, 0, 0);
            if(!h)
                return null;
            return new Cursor(h, true); // Owned.
        }
        
        /// ditto
        final Cursor getCursor(string name)
        {
            HCURSOR h;
            h = LoadImageA(hinst, name.ptr, IMAGE_CURSOR,
                0, 0, 0);
            if(!h)
                return null;
            return new Cursor(h, true); // Owned.
        }
        
        deprecated alias getCursor loadCursor;
        
        
        ///
        final string getString(int id)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            // Not casting to wstring because a resource isn't guaranteed to be the same size.
            wchar* ws = cast(wchar*)_getData(cast(LPCWSTR)RT_STRING, cast(LPCWSTR)cast(WORD)(id / 16 + 1)).ptr;
            wstring result = to!wstring(fromStringz(ws));
            return to!string(result);
        }
        
        deprecated alias getString loastring;
        
        
        // Used internally
        // NOTE: win9x doesn't like these strings to be on the heap!
        final void[] _getData(LPCWSTR type, LPCWSTR name) // internal
        {
            HRSRC hrc;
            hrc = FindResourceExW(hinst, type, name, lang);
            if(!hrc)
                return null;
            HGLOBAL hg = LoadResource(hinst, hrc);
            if(!hg)
                return null;
            LPVOID pv = LockResource(hg);
            if(!pv)
                return null;
            return pv[0 .. SizeofResource(hinst, hrc)];
        }
        
        ///
        final void[] getData(int type, int id)
        in
        {
            assert(type >= WORD.min && type <= WORD.max);
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            return _getData(cast(LPCWSTR)type, cast(LPCWSTR)id);
        }
        
        /// ditto
        final void[] getData(string type, int id)
        in
        {
            assert(id >= WORD.min && id <= WORD.max);
        }
        do
        {
            return _getData(toUTFz!(wchar*)(type), cast(LPCWSTR)id);
        }
        
        /// ditto
        final void[] getData(int type, string name)
        in
        {
            assert(type >= WORD.min && type <= WORD.max);
        }
        do
        {
            return _getData(cast(LPCWSTR)type, toUTFz!(wchar*)(name));
        }
        
        /// ditto
        final void[] getData(string type, string name)
        {
            return _getData(toUTFz!(wchar*)(type), toUTFz!(wchar*)(name));
        }
        
        
        ~this()
        {
            if(_owned)
                dispose();
        }
        
        
        private:
        
        HINSTANCE hinst;
        WORD lang = 0;
        bool _owned = false;
        
        
        void _noload(string type)
        {
            throw new DflException("Unable to load " ~ type ~ " resource");
        }
    }
}

