// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.groupbox;

private import dfl.control;
private import dfl.base;
private import dfl.button;
private import dfl.drawing;
private import dfl.application;
private import dfl.event;

private import core.sys.windows.windows;
private import core.sys.windows.winuser;

private extern(Windows) void _initButton();


version(NO_DRAG_DROP)
    version = DFL_NO_DRAG_DROP;


///
class GroupBox: ControlSuperClass // docmain
{
    override @property Rect displayRectangle() // getter
    {
        // Should only calculate this upon setting the text ?

        int xw = GetSystemMetrics(SM_CXFRAME);
        int yw = GetSystemMetrics(SM_CYFRAME);
        return Rect(xw, yw + _textHeight, clientSize.width - xw * 2, clientSize.height - yw - _textHeight - yw);
    }


    override @property Size defaultSize() // getter
    {
        return Size(200, 100);
    }


    version(DFL_NO_DRAG_DROP) {} else
    {
        override @property void allowDrop(bool dyes) // setter
        {
            assert(!dyes, "Cannot drop on a group box");
        }

        alias Control.allowDrop allowDrop; // Overload.
    }


    this()
    {
        _initButton();

        if(DEFTEXTHEIGHT_INIT == _defTextHeight)
        {
            _recalcTextHeight(font);
            _defTextHeight = _textHeight;
        }
        _textHeight = _defTextHeight;

        wstyle |= BS_GROUPBOX;
        wclassStyle = buttonClassStyle;
        ctrlStyle |= ControlStyles.CONTAINER_CONTROL;
    }


    protected override void onFontChanged(EventArgs ea)
    {
        _dispChanged();

        super.onFontChanged(ea);
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        _dispChanged();
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        cp.className = BUTTON_CLASSNAME;
    }


    protected override void wndProc(ref Message msg)
    {
        switch(msg.msg)
        {
            case WM_NCHITTEST:
                Control._defWndProc(msg);
                break;

            default:
                super.wndProc(msg);
        }
    }


    protected override void onPaintBackground(PaintEventArgs ea)
    {
        RECT rect;
        ea.clipRectangle.getRect(&rect);
        FillRect(ea.graphics.handle, &rect, hbrBg);
    }


    protected override void prevWndProc(ref Message msg)
    {
        msg.result = CallWindowProcW(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);

        // Work around a Windows issue...
        if(WM_PAINT == msg.msg)
        {
            if(this.text.length) {
                HTHEME htd;
                if(Application.initUxTheme()) {
                    if(Application.IsAppThemed !is null && Application.IsAppThemed()) {
                        wchar[] classname = ['B', 'U', 'T', 'T', 'O', 'N', '\0'];
                        if (Application.OpenThemeData !is null) {
                            // Can be null
                            htd = Application.OpenThemeData(this.handle, classname.ptr);
                        }
                    }
                }

                HDC hdc = GetDC(this.handle());
                if (hdc !is null) {
                    scope(exit) ReleaseDC(this.handle(), hdc);
                    try {
                        scope g = new Graphics(hdc, false); // Not owned.
                        scope tfmt = new TextFormat(TextFormatFlags.SINGLE_LINE);

                        Color c;
                        COLORREF cr;
                        auto gtcState = enabled ? (1 /*PBS_NORMAL*/) : (2 /*GBS_DISABLED*/);
                        if(
                            htd !is null
                            && Application.GetThemeColor !is null
                            && 0 == Application.GetThemeColor(htd, 4 /*BP_GROUPBOX*/, gtcState, 3803 /*TMT_TEXTCOLOR*/, &cr)
                        ) {
                            c = Color.fromRgb(cr);
                            Application.CloseThemeData(htd);
                        }
                        else {
                            c = enabled ? foreColor : SystemColors.grayText; // ?
                        }

                        Size tsz = g.measureText(this.text, this.font, tfmt);

                        g.fillRectangle(backColor, 8, 0, 2 + tsz.width + 2, tsz.height + 2);
                        g.drawText(this.text, this.font, c, Rect(8 + 2, 0, tsz.width, tsz.height), tfmt);
                    } catch (Throwable e) {

                    }
                }
            }
        }
    }


    private:

    enum int DEFTEXTHEIGHT_INIT = -1;
    static int _defTextHeight = DEFTEXTHEIGHT_INIT;
    int _textHeight = -1;


    void _recalcTextHeight(Font f)
    {
        _textHeight = cast(int)f.getSize(GraphicsUnit.PIXEL);
    }


    void _dispChanged()
    {
        int old = _textHeight;
        _recalcTextHeight(font);
        if(old != _textHeight)
        {
            suspendLayout();
            resumeLayout(true);
        }
    }
}

