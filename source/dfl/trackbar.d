// Written by Deen O'Connor

module dfl.trackbar;

private import dfl.application;
private import dfl.base;
private import dfl.control;
private import dfl.event;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;


// Application._initTrackBar();
private extern(Windows) void _initTrackBar();

class TrackBar : ControlSuperClass {

    this()
    {
        _initTrackBar();
        wstyle &= ~WS_CLIPCHILDREN & ~WS_CLIPSIBLINGS;
        wstyle |= TBS_AUTOTICKS | TBS_ENABLESELRANGE | TBS_REVERSED;// | TBS_BOTH| this.orient;
        wclassStyle = trackbarClassStyle;
        super();
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        // TODO : Fix
        // If i use TRACKBAR_CLASSNAME, then CreateWindowEx fails for no obvious reason
        // I checked how Rayerd made it, and apparently his code is more or less the same
        // Simply changing the window class somehow fixes the issue, and it works fine
        cp.className = "msctls_trackbar32"w;//TRACKBAR_CLASSNAME;
        //cp.style |= TBS_TOOLTIPS | TBS_BOTH | this.orient;
    }


    protected override void onReflectedMessage(ref Message m)
    {
        // Placeholder
        switch(m.msg)
        {
            case WM_HSCROLL:
            case WM_VSCROLL:
                if (cast(uint)m.wParam == TB_THUMBTRACK) {
                    int oldval = this.val;
                    this.val = cast(int)(m.wParam >>> 32);
                    valueChanged(this, new ValueChangedEventArgs(this.val, this.val));
                }
                break;
            default:
        }

        super.onReflectedMessage(m);
    }


    protected override void wndProc(ref Message m)
    {
        // Placeholder
        switch(m.msg)
        {
            case WM_HSCROLL:
            case WM_VSCROLL:
                if (cast(uint)m.wParam == TB_THUMBTRACK) {
                    int oldval = this.val;
                    this.val = cast(int)(m.wParam >>> 32);
                    valueChanged(this, new ValueChangedEventArgs(this.val, this.val));
                }
                break;
            default:
        }

        super.wndProc(m);
    }


    protected override void prevWndProc(ref Message m)
    {
        CallWindowProcW(trackbarPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        SendMessageA(this.hwnd, TBM_SETRANGEMIN, 0, this.minVal);
        // No need to redraw twice
        SendMessageA(this.hwnd, TBM_SETRANGEMAX, 1, this.maxVal);
    }


    @property public void showTicks(bool byes) // setter
    {
        this.ticks = byes;
        // Clear and reapply the style
        wstyle &= ~TBS_AUTOTICKS & ~TBS_NOTICKS;
        wstyle |= TBS_AUTOTICKS*byes | TBS_NOTICKS*(!byes);
        recreateHandle();
    }

    @property public bool showTicks() // getter
    {
        return this.ticks;
    }


    @property public void showTip(bool byes) // setter
    {
        this.tip = byes;
        // Clear and reapply the style
        wstyle &= ~TBS_TOOLTIPS;
        wstyle |= TBS_TOOLTIPS*byes;
        recreateHandle();
    }

    @property public bool showTip() // getter
    {
        return this.tip;
    }


    @property public void min(int val) // setter
    {
        this.minVal = val;
        SendMessageA(this.hwnd, TBM_SETRANGEMIN, 1, this.minVal);
    }

    @property public int min() // getter
    {
        return this.minVal;
    }


    @property public void max(int val) // setter
    {
        this.maxVal = val;
        SendMessageA(this.hwnd, TBM_SETRANGEMAX, 1, this.maxVal);
    }

    @property public int max() // getter
    {
        return this.maxVal;
    }


    @property void value(int newval) // setter
    {
        this.val = newval;
        SendMessageA(this.hwnd, TBM_SETPOS, 1, this.val);
    }

    @property int value() // getter
    {
        return this.val;
    }


    @property public void orientation(ORIENTATION ori) // setter
    {
        if (this.orient == ori) {
            // Don't do anything
            return;
        }
        this.orient = ori;
        recreateHandle();
    }

    @property public ORIENTATION orientation() // getter
    {
        return this.orient;
    }


    Event!(TrackBar, EventArgs) valueChanged;


    public static enum ORIENTATION {
        HORIZONTAL = TBS_HORZ,
        VERTICAL = TBS_VERT
    }

    private bool ticks = true, tip = true;
    private int val, minVal = 0, maxVal = 100;
    private ORIENTATION orient = ORIENTATION.HORIZONTAL;

}

class ValueChangedEventArgs : EventArgs
{

    this(int oldval, int newval) pure nothrow
    {
        this.oldVal = oldval;
        this.newVal = newval;
    }


    @property public int oldValue() pure nothrow // getter
    {
        return oldVal;
    }


    @property public int newValue() pure nothrow // getter
    {
        return newVal;
    }


    private int oldVal, newVal;
}