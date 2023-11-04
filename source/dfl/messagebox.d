// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.messagebox;

private import dfl.base;

private import core.sys.windows.windows;


///
enum MsgBoxButtons
{
    ABORT_RETRY_IGNORE = MB_ABORTRETRYIGNORE, ///
    OK = MB_OK, /// ditto
    OK_CANCEL = MB_OKCANCEL, /// ditto
    RETRY_CANCEL = MB_RETRYCANCEL, /// ditto
    YES_NO = MB_YESNO, /// ditto
    YES_NO_CANCEL = MB_YESNOCANCEL, /// ditto
}


///
enum MsgBoxIcon
{
    NONE = 0, ///

    ASTERISK = MB_ICONASTERISK, /// ditto
    ERROR = MB_ICONERROR, /// ditto
    EXCLAMATION = MB_ICONEXCLAMATION, /// ditto
    HAND = MB_ICONHAND, /// ditto
    INFORMATION = MB_ICONINFORMATION, /// ditto
    QUESTION = MB_ICONQUESTION, /// ditto
    STOP = MB_ICONSTOP, /// ditto
    WARNING = MB_ICONWARNING, /// ditto
}


enum MsgBoxDefaultButton
{
    BUTTON1 = MB_DEFBUTTON1, ///
    BUTTON2 = MB_DEFBUTTON2, /// ditto
    BUTTON3 = MB_DEFBUTTON3, /// ditto

    // Extra.
    BUTTON4 = MB_DEFBUTTON4,
}


///
enum MsgBoxOptions
{
    DEFAULT_DESKTOP_ONLY = MB_DEFAULT_DESKTOP_ONLY, ///
    RIGHT_ALIGN = MB_RIGHT, /// ditto
    LEFT_ALIGN = MB_RTLREADING, /// ditto
    SERVICE_NOTIFICATION = MB_SERVICE_NOTIFICATION, /// ditto
}


///
DialogResult msgBox(wstring txt) // docmain
{
    return cast(DialogResult)MessageBoxW(GetActiveWindow(), txt.ptr, "\0", MB_OK);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, "\0", MB_OK);
}

/// ditto
DialogResult msgBox(wstring txt, wstring caption) // docmain
{
    return cast(DialogResult)MessageBoxW(GetActiveWindow(), txt.ptr, caption.ptr, MB_OK);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt, wstring caption) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, caption.ptr, MB_OK);
}

/// ditto
DialogResult msgBox(wstring txt, wstring caption, MsgBoxButtons buttons) // docmain
{
    return cast(DialogResult)MessageBoxW(GetActiveWindow(), txt.ptr, caption.ptr, buttons);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt, wstring caption,
    MsgBoxButtons buttons) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, caption.ptr, buttons);
}

/// ditto
DialogResult msgBox(wstring txt, wstring caption, MsgBoxButtons buttons,
    MsgBoxIcon icon) // docmain
{
    return cast(DialogResult)MessageBoxW(GetActiveWindow(), txt.ptr,
        caption.ptr, buttons | icon);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt, wstring caption, MsgBoxButtons buttons,
    MsgBoxIcon icon) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, caption.ptr, buttons | icon);
}

/// ditto
DialogResult msgBox(wstring txt, wstring caption, MsgBoxButtons buttons, MsgBoxIcon icon,
    MsgBoxDefaultButton defaultButton) // docmain
{
    return cast(DialogResult)MessageBoxW(GetActiveWindow(), txt.ptr,
        caption.ptr, buttons | icon | defaultButton);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt, wstring caption, MsgBoxButtons buttons,
    MsgBoxIcon icon, MsgBoxDefaultButton defaultButton) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, caption.ptr, buttons | icon | defaultButton);
}

/// ditto
DialogResult msgBox(IWindow owner, wstring txt, wstring caption, MsgBoxButtons buttons,
    MsgBoxIcon icon, MsgBoxDefaultButton defaultButton, MsgBoxOptions options) // docmain
{
    return cast(DialogResult)MessageBoxW(owner ? owner.handle : GetActiveWindow(),
        txt.ptr, caption.ptr, buttons | icon | defaultButton | options);
}


deprecated final class MessageBox
{
    private this() {}


    static:
    deprecated alias msgBox show;
}


deprecated alias msgBox messageBox;

deprecated alias MsgBoxOptions MessageBoxOptions;
deprecated alias MsgBoxDefaultButton MessageBoxDefaultButton;
deprecated alias MsgBoxButtons MessageBoxButtons;
deprecated alias MsgBoxIcon MessageBoxIcon;

