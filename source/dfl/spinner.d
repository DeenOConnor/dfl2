// Written by Deen O'Connor

module dfl.spinner;

private import dfl.application;
private import dfl.base;
private import dfl.control;
private import dfl.drawing : Rect;
private import dfl.event;
private import dfl.textbox;
private import dfl.trackbar : ValueChangedEventArgs;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;


// Application._initUpDown();
private extern(Windows) void _initUpDown();

// The Up-Down part of the Spinner control
class Spinner : ControlSuperClass {

    this()
    {
        this.bud = new TextBox();
        bud._style(bud._style | ES_NUMBER);

        _initUpDown();
        wstyle &= ~WS_CLIPCHILDREN & ~WS_CLIPSIBLINGS;
        wstyle |= UDS_WRAP | UDS_ARROWKEYS | UDS_SETBUDDYINT;
        wclassStyle = updownClassStyle;
        super();
    }

    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);
        cp.className = UPDOWN_CLASSNAME;
        cp.style |= UDS_ALIGNRIGHT;
        
        this.bud.parent = this.parent;
    }


    protected override void onReflectedMessage(ref Message m)
    {
        switch(m.msg)
        {
            case UDM_SETPOS:
            case UDM_SETPOS32:
                int oldval = this.position;
                this.position = cast(int)m.lParam;
                valueChanged(this, new ValueChangedEventArgs(oldval, this.position));
                break;
            default:
        }

        super.onReflectedMessage(m);
    }


    protected override void wndProc(ref Message m)
    {
        switch(m.msg)
        {
            case UDM_SETPOS:
            case UDM_SETPOS32:
                int oldval = this.position;
                this.position = cast(int)m.lParam;
                valueChanged(this, new ValueChangedEventArgs(oldval, this.position));
                break;
            default:
        }

        super.wndProc(m);
    }


    protected override void prevWndProc(ref Message m)
    {
        m.result = CallWindowProcW(updownPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        SendMessageW(this.hwnd, UDM_SETUNICODEFORMAT, 0, 0);
        this.buddy(this.bud);
        this.range(this.minVal, this.maxVal);
        this.value(this.value);
        super.onHandleCreated(ea);
    }
    
    override protected void setBoundsCore(int x, int y, int width, int height, BoundsSpecified specified)
    {
        this.buddy.bounds = Rect(x, y, width, height);
        
        super.setBoundsCore(x, y, width, height, specified);
    }

    private @property void buddy(TextBox c) // setter
    {
        this.bud = c;
        SendMessageW(this.hwnd, UDM_SETBUDDY, cast(size_t)c.hwnd, 0);
        //recreateHandle();
    }

    @property TextBox buddy() // getter
    {
        return this.bud;
    }

    @property void base(bool byes) // setter
    {
        this.isHex = byes;
        SendMessageW(this.hwnd, UDM_SETBASE, 10 + 6 * byes, 0);
    }

    @property bool hex() // getter
    {
        return this.isHex;
    }

    @property void min(int val) // getter
    {
        this.minVal = val;
        this.range(this.minVal, this.maxVal);
    }

    @property int min() // getter
    {
        return this.min;
    }

    @property void max(int val) // getter
    {
        this.maxVal = val;
        this.range(this.minVal, this.maxVal);
    }

    @property int max() // getter
    {
        return this.maxVal;
    }

    void range(int minimum, int maximum) // setter
    {
        this.minVal = minimum;
        this.maxVal = maximum;
        SendMessageW(this.hwnd, UDM_SETRANGE32, this.minVal, this.maxVal);
    }

    @property void value(uint pos) // setter
    {
        this.position = pos;
        SendMessageW(this.hwnd, UDM_SETPOS32, 0, pos);
    }

    @property int value() // getter
    {
        this.position = cast(int)SendMessageW(this.hwnd, UDM_GETPOS32, 0, 0);
        return this.position;
    }

    Event!(Spinner, EventArgs) valueChanged;

    private TextBox bud;
    private bool isHex = false;
    private int minVal = -1000, maxVal = 100000, position = 0;
}