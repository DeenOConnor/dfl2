// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.filedialog;

private import dfl.control;
private import dfl.base;
private import dfl.drawing;
private import dfl.application;
private import dfl.commondialog;
private import dfl.event;

private import core.sys.windows.windows;
private import std.conv : to;
private import std.string : fromStringz;
private import std.stdio : File;
//private import std.path : join;

///
abstract class FileDialog: CommonDialog // docmain
{
    private this()
    {
        ofname.lStructSize = ofname.sizeof;
        ofname.lCustData = cast(typeof(ofname.lCustData))cast(void*)this;
        ofname.Flags = INIT_FLAGS;
        ofname.nFilterIndex = INIT_FILTER_INDEX;
        initInstance();
        ofname.lpfnHook = cast(typeof(ofname.lpfnHook))&ofnHookProc;
    }


    override DialogResult showDialog()
    {
        return runDialog(GetActiveWindow()) ?
            DialogResult.OK : DialogResult.CANCEL;
    }

    override DialogResult showDialog(IWindow owner)
    {
        return runDialog(owner ? owner.handle : GetActiveWindow()) ?
            DialogResult.OK : DialogResult.CANCEL;
    }


    override void reset()
    {
        ofname.Flags = INIT_FLAGS;
        ofname.lpstrFilter = null;
        ofname.nFilterIndex = INIT_FILTER_INDEX;
        ofname.lpstrDefExt = null;
        _defext = null;
        _fileNames = null;
        needRebuildFiles = false;
        _filter = null;
        ofname.lpstrInitialDir = null;
        _initDir = null;
        ofname.lpstrTitle = null;
        _title = null;
        initInstance();
    }


    private void initInstance()
    {
    }


    ///
    @property void checkFileExists(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_FILEMUSTEXIST;
        else
            ofname.Flags &= ~OFN_FILEMUSTEXIST;
    }

    /// ditto
    @property bool checkFileExists() // getter
    {
        return (ofname.Flags & OFN_FILEMUSTEXIST) != 0;
    }


    ///
    final @property void checkPathExists(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_PATHMUSTEXIST;
        else
            ofname.Flags &= ~OFN_PATHMUSTEXIST;
    }

    /// ditto
    final @property bool checkPathExists() // getter
    {
        return (ofname.Flags & OFN_PATHMUSTEXIST) != 0;
    }


    ///
    final @property void defaultExt(wstring ext) // setter
    {
        if(!ext.length)
        {
            ofname.lpstrDefExt = null;
            _defext = null;
        }
        else
        {
            if(ext.length && ext[0] == '.')
                ext = ext[1 .. ext.length];

            ofname.lpstrDefExt = ext.ptr;
            _defext = ext;
        }
    }

    /// ditto
    final @property wstring defaultExt() // getter
    {
        return _defext;
    }


    ///
    final @property void dereferenceLinks(bool byes) // setter
    {
        if(byes)
            ofname.Flags &= ~OFN_NODEREFERENCELINKS;
        else
            ofname.Flags |= OFN_NODEREFERENCELINKS;
    }

    /// ditto
    final @property bool dereferenceLinks() // getter
    {
        return (ofname.Flags & OFN_NODEREFERENCELINKS) == 0;
    }


    ///
    final @property void fileName(wstring fn) // setter
    {
        // TODO: check if correct implementation.

        if(fn.length > MAX_PATH)
            throw new DflException("Invalid file name");

        if(fileNames.length)
        {
            _fileNames = (&fn)[0 .. 1] ~ _fileNames[1 .. _fileNames.length];
        }
        else
        {
            _fileNames = new wstring[1];
            _fileNames[0] = fn;
        }
    }

    /// ditto
    final @property wstring fileName() // getter
    {
        if(fileNames.length)
            return fileNames[0];
        return null;
    }


    ///
    final @property wstring[] fileNames() // getter
    {
        if(needRebuildFiles)
            populateFiles();

        return _fileNames;
    }


    ///
    // The format string is like "Text files (*.txt)|*.txt|All files (*.*)|*.*".
    final @property void filter(wstring filterString) // setter
    {
        if(!filterString.length)
        {
            ofname.lpstrFilter = null;
            _filter = null;
        }
        else
        {
            wchar[] sw;

            size_t i, starti;
            size_t nitems = 0;

            sw = new wchar[filterString.length + 2];
            sw = sw[0 .. 0];


            for(i = starti = 0; i != filterString.length; i++)
            {
                switch(filterString[i])
                {
                    case '|':
                        if(starti == i)
                            goto bad_filter;

                        sw ~= filterString[starti .. i];
                        sw ~= "\0"w;

                        starti = i + 1;
                        nitems++;
                        break;

                    case 0, '\r', '\n':
                        goto bad_filter;

                    default:
                }
            }
            if(starti == i || !(nitems % 2))
                goto bad_filter;

            sw ~= filterString[starti .. i];
            sw ~= "\0\0"w;
            ofname.lpstrFilter = sw.ptr;

            _filter = filterString;
            return;

            bad_filter:
            throw new DflException("Invalid file filter string");
        }
    }

    /// ditto
    final @property wstring filter() // getter
    {
        return _filter;
    }


    ///
    // Note: index is 1-based.
    final @property void filterIndex(int index) // setter
    {
        ofname.nFilterIndex = (index > 0) ? index : 1;
    }

    /// ditto
    final @property int filterIndex() // getter
    {
        return ofname.nFilterIndex;
    }


    ///
    final @property void initialDirectory(wstring dir) // setter
    {
        if(!dir.length)
        {
            ofname.lpstrInitialDir = null;
            _initDir = null;
        }
        else
        {
            ofname.lpstrInitialDir = dir.ptr;
            _initDir = dir;
        }
    }

    /// ditto
    final @property wstring initialDirectory() // getter
    {
        return _initDir;
    }


    // Should be instance(), but conflicts with D's old keyword.

    ///
    protected @property void inst(HINSTANCE hinst) // setter
    {
        ofname.hInstance = hinst;
    }

    /// ditto
    protected @property HINSTANCE inst() // getter
    {
        return ofname.hInstance;
    }


    ///
    protected @property DWORD options() // getter
    {
        return ofname.Flags;
    }


    ///
    final @property void restoreDirectory(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_NOCHANGEDIR;
        else
            ofname.Flags &= ~OFN_NOCHANGEDIR;
    }

    /// ditto
    final @property bool restoreDirectory() // getter
    {
        return (ofname.Flags & OFN_NOCHANGEDIR) != 0;
    }


    ///
    final @property void showHelp(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_SHOWHELP;
        else
            ofname.Flags &= ~OFN_SHOWHELP;
    }

    /// ditto
    final @property bool showHelp() // getter
    {
        return (ofname.Flags & OFN_SHOWHELP) != 0;
    }


    ///
    final @property void title(wstring newTitle) // setter
    {
        if(!newTitle.length)
        {
            ofname.lpstrTitle = null;
            _title = null;
        }
        else
        {
            ofname.lpstrTitle = newTitle.ptr;
            _title = newTitle;
        }
    }

    /// ditto
    final @property wstring title() // getter
    {
        return _title;
    }


    ///
    final @property void validateNames(bool byes) // setter
    {
        if(byes)
            ofname.Flags &= ~OFN_NOVALIDATE;
        else
            ofname.Flags |= OFN_NOVALIDATE;
    }

    /// ditto
    final @property bool validateNames() // getter
    {
        return(ofname.Flags & OFN_NOVALIDATE) == 0;
    }


    ///
    Event!(FileDialog, CancelEventArgs) fileOk;


    protected:

    override bool runDialog(HWND owner)
    {
        assert(0);
    }


    ///
    void onFileOk(CancelEventArgs ea)
    {
        fileOk(this, ea);
    }


    override LRESULT hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
    {
        switch(msg)
        {
            case WM_NOTIFY:
                {
                    NMHDR* nmhdr;
                    nmhdr = cast(NMHDR*)lparam;
                    switch(nmhdr.code)
                    {
                        case CDN_FILEOK:
                            {
                                CancelEventArgs cea;
                                cea = new CancelEventArgs;
                                onFileOk(cea);
                                if(cea.cancel)
                                {
                                    SetWindowLongW(hwnd, DWL_MSGRESULT, 1);
                                    return 1;
                                }
                            }
                            break;

                        default:
                    }
                }
                break;

            default:
        }

        return super.hookProc(hwnd, msg, wparam, lparam);
    }


    private:
    /*
    union
    {
        OPENFILENAMEW ofnw;
        OPENFILENAMEA ofna;
        alias ofnw ofn;

        static assert(OPENFILENAMEW.sizeof == OPENFILENAMEA.sizeof);
        static assert(OPENFILENAMEW.Flags.offsetof == OPENFILENAMEA.Flags.offsetof);
    }
    */
    OPENFILENAMEW ofname;

    wstring[] _fileNames;
    wstring _filter;
    wstring _initDir;
    wstring _defext;
    wstring _title;
    bool needRebuildFiles = false;

    enum DWORD INIT_FLAGS = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
        OFN_ENABLEHOOK | OFN_ENABLESIZING;
    enum INIT_FILTER_INDEX = 0;
    enum FILE_BUF_LEN = 4096; // ? 12288 ? 12800 ?


    void beginOfn(HWND owner)
    {
        auto buf = new wchar[(ofname.Flags & OFN_ALLOWMULTISELECT) ? FILE_BUF_LEN : MAX_PATH];
        buf[0] = 0;

        if(fileNames.length)
        {
            wstring ts;
            ts = _fileNames[0];
            buf[0 .. ts.length] = ts[];
            buf[ts.length] = 0;
        }

        ofname.nMaxFile = cast(uint)buf.length;
        ofname.lpstrFile = buf.ptr;


        ofname.hwndOwner = owner;
    }


    // Populate -_fileNames- from -ofn.lpstrFile-.
    void populateFiles()
    in
    {
        assert(ofname.lpstrFile !is null);
    }
    do
    {
        if(ofname.Flags & OFN_ALLOWMULTISELECT)
        {
            // Nonstandard reserve.
            _fileNames = new wstring[4];
            _fileNames = _fileNames[0 .. 0];

            wchar* startp, p;
            p = startp = ofname.lpstrFile;
            for(;;)
            {
                if(!*p)
                {
                    _fileNames ~= fromStringz(startp[0 .. p - startp]).idup; // dup later.

                    p++;
                    if(!*p)
                        break;

                    startp = p;
                    continue;
                }

                p++;
            }

            assert(_fileNames.length);
            if(_fileNames.length == 1)
            {
                //_fileNames[0] = cast(string)_fileNames[0].dup; // Needed in D2.
            }
            else
            {
                wstring s;
                size_t i;
                s = _fileNames[0];

                for(i = 1; i != _fileNames.length; i++)
                {
                    // What was std.path.join that is aliased to pathJoin in dlib?
                    _fileNames[i] = s ~ _fileNames[i];
                }
                _fileNames = _fileNames[1 .. _fileNames.length];
            }
        }
        else
        {
            _fileNames = new wstring[1];
            _fileNames[0] = fromStringz(ofname.lpstrFile).idup;
        }

        needRebuildFiles = false;
    }


    // Call only if the dialog succeeded.
    void finishOfn()
    {
        if(needRebuildFiles)
            populateFiles();

        ofname.lpstrFile = null;
    }


    // Call only if dialog fail or cancel.
    void cancelOfn()
    {
        needRebuildFiles = false;

        ofname.lpstrFile = null;
        _fileNames = null;
    }
}


private extern(Windows) nothrow
{
    alias BOOL function(LPOPENFILENAMEW lpofn) GetOpenFileNameWProc;
    alias BOOL function(LPOPENFILENAMEW lpofn) GetSaveFileNameWProc;
}


///
class OpenFileDialog: FileDialog // docmain
{
    this()
    {
        super();
        ofname.Flags |= OFN_FILEMUSTEXIST;
    }


    override void reset()
    {
        super.reset();
        ofname.Flags |= OFN_FILEMUSTEXIST;
    }


    ///
    final @property void multiselect(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_ALLOWMULTISELECT;
        else
            ofname.Flags &= ~OFN_ALLOWMULTISELECT;
    }

    /// ditto
    final @property bool multiselect() // getter
    {
        return (ofname.Flags & OFN_ALLOWMULTISELECT) != 0;
    }


    ///
    final @property void readOnlyChecked(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_READONLY;
        else
            ofname.Flags &= ~OFN_READONLY;
    }

    /// ditto
    final @property bool readOnlyChecked() // getter
    {
        return (ofname.Flags & OFN_READONLY) != 0;
    }


    ///
    final @property void showReadOnly(bool byes) // setter
    {
        if(byes)
            ofname.Flags &= ~OFN_HIDEREADONLY;
        else
            ofname.Flags |= OFN_HIDEREADONLY;
    }

    /// ditto
    final @property bool showReadOnly() // getter
    {
        return (ofname.Flags & OFN_HIDEREADONLY) == 0;
    }

    ///
    final File openFile(string mode = "rb")
    {
        // TODO : Test if this actually works by studying old versions of the library
        return File(fileName(), mode);
    }


    protected:

    override bool runDialog(HWND owner)
    {
        if(!_runDialog(owner))
        {
            if(!CommDlgExtendedError())
                return false;
            _cantrun();
        }
        return true;
    }


    private BOOL _runDialog(HWND owner)
    {
        BOOL result = 0;

        beginOfn(owner);

        result = GetOpenFileNameW(&ofname);

        if(result)
        {
            finishOfn();
            return result;
        }

        cancelOfn();
        return result;
    }
}


///
class SaveFileDialog: FileDialog // docmain
{
    this()
    {
        super();
        ofname.Flags |= OFN_OVERWRITEPROMPT;
    }


    override void reset()
    {
        super.reset();
        ofname.Flags |= OFN_OVERWRITEPROMPT;
    }


    ///
    final @property void createPrompt(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_CREATEPROMPT;
        else
            ofname.Flags &= ~OFN_CREATEPROMPT;
    }

    /// ditto
    final @property bool createPrompt() // getter
    {
        return (ofname.Flags & OFN_CREATEPROMPT) != 0;
    }


    ///
    final @property void overwritePrompt(bool byes) // setter
    {
        if(byes)
            ofname.Flags |= OFN_OVERWRITEPROMPT;
        else
            ofname.Flags &= ~OFN_OVERWRITEPROMPT;
    }

    /// ditto
    final @property bool overwritePrompt() // getter
    {
        return (ofname.Flags & OFN_OVERWRITEPROMPT) != 0;
    }

    ///
    // Opens and creates with read and write access.
    // Warning: if file exists, it's truncated. // Is it really? Needs testing - D.O
    final File openFile(string mode = "w+b")
    {
        return File(fileName(), mode);
    }


    protected:

    override bool runDialog(HWND owner)
    {
        beginOfn(owner);

        if(GetSaveFileNameW(&ofname))
        {
            finishOfn();
            return true;
        }

        cancelOfn();
        return false;
    }
}


private extern(Windows) LRESULT ofnHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
    enum PROP_STR = "DFL_FileDialog"w;
    FileDialog fd;
    LRESULT result = 0;

    try
    {
        if(msg == WM_INITDIALOG)
        {
            OPENFILENAMEW* ofn;
            ofn = cast(OPENFILENAMEW*)lparam;
            SetPropW(hwnd, PROP_STR.ptr, cast(HANDLE)ofn.lCustData);
            fd = cast(FileDialog)cast(void*)ofn.lCustData;
        }
        else
        {
            fd = cast(FileDialog)cast(void*)GetPropW(hwnd, PROP_STR.ptr);
        }

        if(fd)
        {
            fd.needRebuildFiles = true;
            result = fd.hookProc(hwnd, msg, wparam, lparam);
        }
    }
    catch(Throwable e)
    {
        Application.onThreadException(e);
    }

    return result;
}

