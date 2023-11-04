// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.statusbar;


private import dfl.control;
private import dfl.base;
private import dfl.event;
private import dfl.collections;
private import dfl.application;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;

private import std.string : icmp;
private import std.conv : to;

private extern(Windows) void _initStatusbar();



///
enum StatusBarPanelBorderStyle: ubyte
{
    NONE, ///
    SUNKEN, /// ditto
    RAISED /// ditto
}


///
class StatusBarPanel: Object
{
    ///
    this(wstring text)
    {
        this._txt = text;
    }

    /// ditto
    this(wstring text, int width)
    {
        this._txt = text;
        this._width = width;
    }

    /// ditto
    this()
    {
    }


    override string toString() {
        return to!string(_txt);
    }

    wstring toWString()
    {
        return _txt;
    }


    override bool opEquals(Object o)
    {
        return _txt == to!wstring(o.toString()); // ?
    }

    bool opEquals(StatusBarPanel pnl)
    {
        return _txt == pnl._txt;
    }

    bool opEquals(wstring val)
    {
        return _txt == val;
    }


    override int opCmp(Object o)
    {
        return icmp(_txt, to!string(o.toString())); // ?
    }

    int opCmp(StatusBarPanel pnl)
    {
        return icmp(_txt, pnl._txt);
    }

    int opCmp(wstring val)
    {
        return icmp(_txt, val);
    }


    ///
    final @property void borderStyle(StatusBarPanelBorderStyle bs) // setter
    {
        switch(bs)
        {
            case StatusBarPanelBorderStyle.NONE:
                _utype = (_utype & ~SBT_POPOUT) | SBT_NOBORDERS;
                break;

            case StatusBarPanelBorderStyle.RAISED:
                _utype = (_utype & ~SBT_NOBORDERS) | SBT_POPOUT;
                break;

            case StatusBarPanelBorderStyle.SUNKEN:
                _utype &= ~(SBT_NOBORDERS | SBT_POPOUT);
                break;

            default:
                assert(0);
        }

        if(_parent && _parent.isHandleCreated)
        {
            _parent.panels._fixtexts(); // Also fixes styles.
        }
    }

    /// ditto
    final @property StatusBarPanelBorderStyle borderStyle() // getter
    {
        if(_utype & SBT_POPOUT)
            return StatusBarPanelBorderStyle.RAISED;
        if(_utype & SBT_NOBORDERS)
            return StatusBarPanelBorderStyle.NONE;
        return StatusBarPanelBorderStyle.RAISED;
    }


    ///
    final @property StatusBar parent() // getter
    {
        return _parent;
    }


    ///
    final @property void text(wstring txt) // setter
    {
        if(_parent && _parent.isHandleCreated)
        {
            int idx = _parent.panels.indexOf(this);
            assert(-1 != idx);
            _parent._sendidxtext(idx, _utype, txt);
        }

        this._txt = txt;
    }

    /// ditto
    final @property wstring text() // getter
    {
        return _txt;
    }


    ///
    final @property void width(int w) // setter
    {
        _width = w;

        if(_parent && _parent.isHandleCreated)
        {
            _parent.panels._fixwidths();
        }
    }

    /// ditto
    final @property int width() // getter
    {
        return _width;
    }


    private:

    wstring _txt = null;
    int _width = 100;
    StatusBar _parent = null;
    WPARAM _utype = 0; // StatusBarPanelBorderStyle.SUNKEN.
}


///
class StatusBar: ControlSuperClass // docmain
{
    ///
    class StatusBarPanelCollection
    {
        protected this(StatusBar sb)
        in
        {
            assert(sb.lpanels is null);
        }
        do
        {
            this.sb = sb;
        }


        private:

        StatusBar sb;
        package StatusBarPanel[] _panels;


        package void _fixwidths()
        {
            assert(isHandleCreated);

            UINT[20] _pws = void;
            UINT[] pws = _pws;
            if(_panels.length > _pws.length)
                pws = new UINT[_panels.length];
            UINT right = 0;
            foreach(idx, pnl; _panels)
            {
                if(-1 == pnl.width)
                {
                    pws[idx] = -1;
                }
                else
                {
                    right += pnl.width;
                    pws[idx] = right;
                }
            }
            sb.prevwproc(SB_SETPARTS, cast(WPARAM)_panels.length, cast(LPARAM)pws.ptr);
        }


        void _fixtexts()
        {
            assert(isHandleCreated);

            foreach(idx, pnl; _panels)
            {
                sb.prevwproc(SB_SETTEXTA, cast(WPARAM)idx | pnl._utype, cast(LPARAM)pnl._txt.ptr);
            }
        }


        void _setcurparts()
        {
            assert(isHandleCreated);

            _fixwidths();

            _fixtexts();
        }


        void _removed(size_t idx, Object val)
        {
            if(size_t.max == idx) // Clear all.
            {
                if(sb.isHandleCreated)
                {
                    sb.prevwproc(SB_SETPARTS, 0, 0); // 0 parts.
                }
            }
            else
            {
                if(sb.isHandleCreated)
                {
                    _setcurparts();
                }
            }
        }


        void _added(size_t idx, StatusBarPanel val)
        {
            if(val._parent)
                throw new DflException("StatusBarPanel already belongs to a StatusBar");

            val._parent = sb;

            if(sb.isHandleCreated)
            {
                _setcurparts();
            }
        }


        void _adding(size_t idx, StatusBarPanel val)
        {
            if(_panels.length >= 254) // Since SB_SETTEXT with 255 has special meaning.
                throw new DflException("Too many status bar panels");
        }


        public:

        mixin ListWrapArray!(StatusBarPanel, _panels,
            _adding, _added,
            _blankListCallback!(StatusBarPanel), _removed,
            true, /+true+/ false, false) _wraparray;
    }


    ///
    this()
    {
        _initStatusbar();

        _issimple = true;
        wstyle |= SBARS_SIZEGRIP;
        wclassStyle = statusbarClassStyle;
        //height = ?;
        dock = DockStyle.BOTTOM;

        lpanels = new StatusBarPanelCollection(this);
    }


    override @property void dock(DockStyle ds) // setter
    {
        switch(ds)
        {
            case DockStyle.BOTTOM:
            case DockStyle.TOP:
                super.dock = ds;
                break;

            default:
                throw new DflException("Invalid status bar dock");
        }
    }

    alias Control.dock dock; // Overload.


    ///
    final @property StatusBarPanelCollection panels() // getter
    {
        return lpanels;
    }


    ///
    final @property void showPanels(bool byes) // setter
    {
        if(!byes == _issimple)
            return;

        if(isHandleCreated)
        {
            prevwproc(SB_SIMPLE, cast(WPARAM)!byes, 0);

            if(!byes)
            {
                _sendidxtext(255, 0, _simpletext);
            }
        }

        _issimple = !byes;
    }

    /// ditto
    final @property bool showPanels() // getter
    {
        return !_issimple;
    }


    ///
    final @property void sizingGrip(bool byes) // setter
    {
        if(byes == sizingGrip)
            return;

        if(byes)
            _style(_style() | SBARS_SIZEGRIP);
        else
            _style(_style() & ~SBARS_SIZEGRIP);
    }

    /// ditto
    final @property bool sizingGrip() // getter
    {
        if(wstyle & SBARS_SIZEGRIP)
            return true;
        return false;
    }


    override @property void text(wstring txt) // setter
    {
        if(isHandleCreated && !showPanels)
        {
            _sendidxtext(255, 0, txt);
        }

        this._simpletext = txt;

        onTextChanged(EventArgs.empty);
    }

    /// ditto
    override @property wstring text() // getter
    {
        return this._simpletext;
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        if(_issimple)
        {
            prevwproc(SB_SIMPLE, cast(WPARAM)true, 0);
            panels._setcurparts();
            if(_simpletext.length)
                _sendidxtext(255, 0, _simpletext);
        }
        else
        {
            panels._setcurparts();
            prevwproc(SB_SIMPLE, cast(WPARAM)false, 0);
        }
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        cp.className = STATUSBAR_CLASSNAME;
    }


    protected override void prevWndProc(ref Message msg)
    {
        msg.result = CallWindowProcA(statusbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
    }


    private:

    StatusBarPanelCollection lpanels;
    wstring _simpletext = null;
    bool _issimple = true;


    package:
    final:

    LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
    {
        return CallWindowProcA(statusbarPrevWndProc, hwnd, msg, wparam, lparam);
    }


    void _sendidxtext(int idx, WPARAM utype, wstring txt)
    {
        assert(isHandleCreated);

        prevwproc(SB_SETTEXTA, cast(WPARAM)idx | utype, cast(LPARAM)txt.ptr);
    }
}

