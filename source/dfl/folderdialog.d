// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.folderdialog;

private import dfl.commondialog;
private import dfl.base;
private import dfl.application;

private import core.sys.windows.com;
private import core.sys.windows.objidl;
private import core.sys.windows.windows;
private import core.sys.windows.shlobj;

private import std.conv : to;
private import std.string : fromStringz;


private extern(Windows) nothrow
{
    alias LPITEMIDLIST function(LPBROWSEINFOW lpbi) SHBrowseForFolderWProc;
    alias BOOL function(LPCITEMIDLIST pidl, LPWSTR pszPath) SHGetPathFromIDListWProc;
}


///
class FolderBrowserDialog: CommonDialog // docmain
{
    this()
    {
        Application.ppin(cast(void*)this);

        bi.ulFlags = INIT_FLAGS;
        bi.lParam = cast(typeof(bi.lParam))cast(void*)this;
        bi.lpfn = &fbdHookProc;
    }


    ~this()
    {
    }


    override DialogResult showDialog()
    {
        if(!runDialog(GetActiveWindow()))
            return DialogResult.CANCEL;
        return DialogResult.OK;
    }


    override DialogResult showDialog(IWindow owner)
    {
        if(!runDialog(owner ? owner.handle : GetActiveWindow()))
            return DialogResult.CANCEL;
        return DialogResult.OK;
    }


    override void reset()
    {
        bi.ulFlags = INIT_FLAGS;
        _desc = null;
        _selpath = null;
    }


    ///
    final @property void description(string desc) // setter
    {
        // lpszTitle

        _desc = desc;
    }

    /// ditto
    final @property string description() // getter
    {
        return _desc;
    }


    ///
    final @property void selectedPath(string selpath) // setter
    {
        // pszDisplayName

        _selpath = selpath;
    }

    /// ditto
    final @property string selectedPath() // getter
    {
        return _selpath;
    }


    // ///
    // Currently only works for shell32.dll version 6.0+.
    final @property void showNewFolderButton(bool byes) // setter
    {
        // BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
        // Might need to enum child windows looking for window title
        // "&New Folder" and hide it, then shift "OK" and "Cancel" over.

        if(byes)
            bi.ulFlags &= ~0x0200; // BIF_NONEWFOLDERBUTTON
        else
            bi.ulFlags |= 0x0200; // BIF_NONEWFOLDERBUTTON
    }

    // /// ditto
    final @property bool showNewFolderButton() // getter
    {
        return (bi.ulFlags & 0x0200) == 0; // BIF_NONEWFOLDERBUTTON
    }


    private void _errPathTooLong()
    {
        throw new DflException("Path name is too long");
    }


    private void _errNoGetPath()
    {
        throw new DflException("Unable to obtain path");
    }


    private void _errNoShMalloc()
    {
        throw new DflException("Unable to get shell memory allocator");
    }


    protected override bool runDialog(HWND owner)
    {
        IMalloc shmalloc;

        bi.hwndOwner = owner;

        char[MAX_PATH] pdescz; // Initialize because SHBrowseForFolder() is modal.

        bia.lpszTitle = _desc.ptr;

        bia.pszDisplayName = cast(char*)pdescz;
        if(_desc.length)
        {
            string tmp; // ansi.
            tmp = _desc.dup;
            if(tmp.length >= MAX_PATH)
                _errPathTooLong();
            bia.pszDisplayName[0 .. tmp.length] = tmp[];
            bia.pszDisplayName[tmp.length] = 0;
        }
        else
        {
            bia.pszDisplayName[0] = 0;
        }

        // Show the dialog!
        LPITEMIDLIST result;
        result = SHBrowseForFolderA(&bia);

        if(!result)
        {
            bia.lpszTitle = null;
            return false;
        }

        if(NOERROR != SHGetMalloc(&shmalloc))
            _errNoShMalloc();

        char[MAX_PATH] abuf = void;
        if(!SHGetPathFromIDListA(result, abuf.ptr))
        {
            shmalloc.Free(result);
            shmalloc.Release();
            _errNoGetPath();
            assert(0);
        }

        _selpath = to!string(fromStringz(abuf.ptr)); // Assumes fromAnsiz() copies.

        shmalloc.Free(result);
        shmalloc.Release();

        bia.lpszTitle = null;

        return true;
    }


    private:

    union
    {
        BROWSEINFOW biw;
        BROWSEINFOA bia;
        alias biw bi;

        static assert(BROWSEINFOW.sizeof == BROWSEINFOA.sizeof);
        static assert(BROWSEINFOW.ulFlags.offsetof == BROWSEINFOA.ulFlags.offsetof);
    }

    string _desc;
    string _selpath;


    enum UINT INIT_FLAGS = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
}


private:

private extern(Windows) int fbdHookProc(HWND hwnd, UINT msg, LPARAM lparam, LPARAM lpData) nothrow
{
    FolderBrowserDialog fd;
    int result = 0;

    try
    {
        fd = cast(FolderBrowserDialog)cast(void*)lpData;
        if(fd)
        {
            string s;
            switch(msg)
            {
                case BFFM_INITIALIZED:
                    s = fd.selectedPath;
                    if(s.length)
                    {
                        SendMessageA(hwnd, BFFM_SETSELECTIONA, TRUE, cast(LPARAM)s.ptr);
                    }
                    break;

                default:
            }
        }
    }
    catch(Throwable e)
    {
        Application.onThreadException(e);
    }

    return result;
}

