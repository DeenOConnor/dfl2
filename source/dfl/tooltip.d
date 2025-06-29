// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.tooltip;


private import dfl.control;
private import dfl.base;
private import dfl.application;

private import core.memory : GC;
private import core.exception : OutOfMemoryError;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;

private import std.conv : to;
private import std.string : fromStringz;


///
class ToolTip // docmain
{
    package this(DWORD style)
    {
        _initCommonControls(ICC_TREEVIEW_CLASSES); // Includes tooltip.

        hwtt = CreateWindowExA(WS_EX_TOPMOST | WS_EX_TOOLWINDOW, _TOOLTIPS_CLASSA.ptr,
            "", style, 0, 0, 50, 50, null, null, null, null);
        if(!hwtt)
            throw new DflException("Unable to create tooltip");
    }


    this()
    {
        this(cast(DWORD)WS_POPUP);
    }


    ~this()
    {
        removeAll(); // Fixes ref count.
        DestroyWindow(hwtt);
    }


    ///
    final @property HWND handle() // getter
    {
        return hwtt;
    }


    ///
    final @property void active(bool byes) // setter
    {
        SendMessageA(hwtt, TTM_ACTIVATE, byes, 0); // ?
        _active = byes;
    }

    /// ditto
    final @property bool active() // getter
    {
        return _active;
    }


    ///
    // Sets autoPopDelay, initialDelay and reshowDelay.
    final @property void automaticDelay(DWORD ms) // setter
    {
        SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_AUTOMATIC, ms);
    }


    ///
    final @property void autoPopDelay(DWORD ms) // setter
    {
        SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_AUTOPOP, ms);
    }


    ///
    final @property void initialDelay(DWORD ms) // setter
    {
        SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_INITIAL, ms);
    }


    ///
    final @property void reshowDelay(DWORD ms) // setter
    {
        SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_RESHOW, ms);
    }


    ///
    final @property void showAlways(bool byes) // setter
    {
        LONG wl;
        wl = GetWindowLongA(hwtt, GWL_STYLE);
        if(byes)
        {
            if(wl & TTS_ALWAYSTIP)
                return;
            wl |= TTS_ALWAYSTIP;
        }
        else
        {
            if(!(wl & TTS_ALWAYSTIP))
                return;
            wl &= ~TTS_ALWAYSTIP;
        }
        SetWindowLongPtrW(hwtt, GWL_STYLE, wl);
    }

    /// ditto
    final @property bool showAlways() // getter
    {
        return (GetWindowLongA(hwtt, GWL_STYLE) & TTS_ALWAYSTIP) != 0;
    }


    ///
    // Remove all tooltip text associated with this instance.
    final void removeAll()
    {
        TOOLINFOA tool;
        tool.cbSize = TOOLINFOA.sizeof;
        while(SendMessageA(hwtt, TTM_ENUMTOOLSA, 0, cast(LPARAM)&tool))
        {
            SendMessageA(hwtt, TTM_DELTOOLA, 0, cast(LPARAM)&tool);
            Application.refCountDec(cast(void*)this);
        }
    }


    ///
    // WARNING: possible buffer overflow.
    final string getToolTip(Control ctrl)
    {
        string result;
        TOOLINFOA tool;
        tool.cbSize = TOOLINFOA.sizeof;
        tool.uFlags = TTF_IDISHWND;
        tool.hwnd = ctrl.handle;
        tool.uId = cast(UINT)ctrl.handle;

        tool.lpszText = cast(typeof(tool.lpszText))GC.malloc(MAX_TIP_TEXT_LENGTH + 1);
        if(!tool.lpszText)
            throw new OutOfMemoryError();
        scope(exit)
            GC.free(tool.lpszText);
        tool.lpszText[0] = 0;
        SendMessageA(hwtt, TTM_GETTEXTA, 0, cast(LPARAM)&tool);
        if(!tool.lpszText[0])
            result = null;
        else
            result = to!string(fromStringz(tool.lpszText)); // Assumes fromAnsiz() copies.

        return result;
    }

    /// ditto
    final void setToolTip(Control ctrl, string text)
    in
    {
        try
        {
            ctrl.createControl();
        }
        catch(Throwable o)
        {
            assert(0); // If -ctrl- is a child, make sure the parent is set before setting tool tip text.
            //throw o;
        }
    }
    do
    {
        TOOLINFOA tool;
        tool.cbSize = TOOLINFOA.sizeof;
        tool.uFlags = TTF_IDISHWND;
        tool.hwnd = ctrl.handle;
        tool.uId = cast(UINT)ctrl.handle;

        if(!text.length)
        {
            if(SendMessageA(hwtt, TTM_GETTOOLINFOA, 0, cast(LPARAM)&tool))
            {
                // Remove.
                SendMessageA(hwtt, TTM_DELTOOLA, 0, cast(LPARAM)&tool);
                Application.refCountDec(cast(void*)this);
            }
            return;
        }

        // Hack to help prevent getToolTip() overflow.
        if(text.length > MAX_TIP_TEXT_LENGTH)
            text = text[0 .. MAX_TIP_TEXT_LENGTH];

        if(SendMessageA(hwtt, TTM_GETTOOLINFOA, 0, cast(LPARAM)&tool))
        {
            // Update.
            tool.lpszText = cast(typeof(tool.lpszText))text.ptr;
            SendMessageA(hwtt, TTM_UPDATETIPTEXTA, 0, cast(LPARAM)&tool);
        }
        else
        {
            tool.uFlags |= TTF_SUBCLASS; // Not a good idea ?
            LRESULT lr;

            tool.lpszText = cast(typeof(tool.lpszText))text.ptr;
            lr = SendMessageA(hwtt, TTM_ADDTOOLA, 0, cast(LPARAM)&tool);

            if(lr)
                Application.refCountInc(cast(void*)this);
        }
    }


    private:
    enum _TOOLTIPS_CLASSA = "tooltips_class32";
    enum size_t MAX_TIP_TEXT_LENGTH = 2045;
    HWND hwtt; // Tooltip control handle.
    bool _active = true;
}

