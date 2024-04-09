///

// I suppose Mr. Christopher E. Miller forgot to add copyright information here? - D.O

///
module dfl.toolbar;

private import dfl.base;
private import dfl.control;
private import dfl.drawing;
private import dfl.application;
private import dfl.event;
private import dfl.collections;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;

private import std.string : icmp;
private import std.conv : to;


version(DFL_NO_IMAGELIST)
{
}
else
{
    private import dfl.imagelist;
}

version(DFL_NO_MENUS)
    version = DFL_TOOLBAR_NO_MENU;

version(DFL_TOOLBAR_NO_MENU)
{
}
else
{
    private import dfl.menu;
}


///
enum ToolBarButtonStyle: ubyte
{
    PUSH_BUTTON = TBSTYLE_BUTTON, ///
    TOGGLE_BUTTON = TBSTYLE_CHECK, /// ditto
    SEPARATOR = TBSTYLE_SEP, /// ditto
    //DROP_DOWN_BUTTON = TBSTYLE_DROPDOWN, /// ditto
    DROP_DOWN_BUTTON = TBSTYLE_DROPDOWN | BTNS_WHOLEDROPDOWN, /// ditto
}


///
class ToolBarButton
{
    ///
    this()
    {
        Application.ppin(cast(void*)this);
    }

    ///
    this(wstring text)
    {
        this();
        this.text = text;
    }


    version(DFL_NO_IMAGELIST)
    {
    }
    else
    {
        ///
        final @property void imageIndex(int index) // setter
        {
            this._imgidx = index;
        }

        /// ditto
        final @property int imageIndex() // getter
        {
            return _imgidx;
        }
    }


    ///
    @property void text(wstring newText) // setter
    {
        _text = newText;
    }

    /// ditto
    @property wstring text() // getter
    {
        return _text;
    }


    ///
    final @property void style(ToolBarButtonStyle st) // setter
    {
        this._style = st;
    }

    /// ditto
    final @property ToolBarButtonStyle style() // getter
    {
        return _style;
    }


    override string toString()
    {
        return to!string(text);
    }


    wstring toWString()
    {
        return text;
    }


    override bool opEquals(Object o)
    {
        return this.toString() == o.toString();
    }


    bool opEquals(wstring val)
    {
        return text == val;
    }


    override int opCmp(Object o)
    {
        return icmp(text, o.toString());
    }


    int opCmp(wstring val)
    {
        return icmp(text, val);
    }


    ///
    final @property void tag(Object o) // setter
    {
        _tag = o;
    }

    /// ditto
    final @property Object tag() // getter
    {
        return _tag;
    }


    version(DFL_TOOLBAR_NO_MENU)
    {
    }
    else
    {
        ///
        final @property void dropDownMenu(ContextMenu cmenu) // setter
        {
            _cmenu = cmenu;
        }

        /// ditto
        final @property ContextMenu dropDownMenu() // getter
        {
            return _cmenu;
        }
    }


    ///
    final @property ToolBar parent() // getter
    {
        return tbar;
    }


    ///
    final @property Rect rectangle() // getter
    {
        if(!visible)
            return Rect(0, 0, 0, 0); // ?
        assert(tbar !is null);
        RECT rect;
        tbar.prevwproc(TB_GETITEMRECT, tbar.buttons.indexOf(this), cast(LPARAM)&rect); // Fails if item is hidden.
        return Rect(&rect); // Should return all 0`s if TB_GETITEMRECT failed.
    }


    ///
    final @property void visible(bool byes) // setter
    {
        if(byes)
            _state &= ~TBSTATE_HIDDEN;
        else
            _state |= TBSTATE_HIDDEN;

        if(tbar && tbar.created)
            tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
    }

    /// ditto
    final @property bool visible() // getter
    {
        if(!tbar || !tbar.created)
            return false;
        return true; // To-do: get actual hidden state.
    }


    ///
    final @property void enabled(bool byes) // setter
    {
        if(byes)
            _state |= TBSTATE_ENABLED;
        else
            _state &= ~TBSTATE_ENABLED;

        if(tbar && tbar.created)
            tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
    }

    /// ditto
    final @property bool enabled() // getter
    {
        if(_state & TBSTATE_ENABLED)
            return true;
        return false;
    }


    ///
    final @property void pushed(bool byes) // setter
    {
        if(byes)
            _state = (_state & ~TBSTATE_INDETERMINATE) | TBSTATE_CHECKED;
        else
            _state &= ~TBSTATE_CHECKED;

        if(tbar && tbar.created)
            tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
    }

    /// ditto
    final @property bool pushed() // getter
    {
        if(TBSTATE_CHECKED == (_state & TBSTATE_CHECKED))
            return true;
        return false;
    }


    ///
    final @property void partialPush(bool byes) // setter
    {
        if(byes)
            _state = (_state & ~TBSTATE_CHECKED) | TBSTATE_INDETERMINATE;
        else
            _state &= ~TBSTATE_INDETERMINATE;

        if(tbar && tbar.created)
            tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
    }

    /// ditto
    final @property bool partialPush() // getter
    {
        if(TBSTATE_INDETERMINATE == (_state & TBSTATE_INDETERMINATE))
            return true;
        return false;
    }


    private:
    ToolBar tbar;
    int _id = 0;
    wstring _text;
    Object _tag;
    ToolBarButtonStyle _style = ToolBarButtonStyle.PUSH_BUTTON;
    BYTE _state = TBSTATE_ENABLED;
    version(DFL_TOOLBAR_NO_MENU)
    {
    }
    else
    {
        ContextMenu _cmenu;
    }
    version(DFL_NO_IMAGELIST)
    {
    }
    else
    {
        int _imgidx = -1;
    }
}


///
class ToolBarButtonClickEventArgs: EventArgs
{
    this(ToolBarButton tbbtn)
    {
        _btn = tbbtn;
    }


    ///
    final @property ToolBarButton button() // getter
    {
        return _btn;
    }


    private:
    ToolBarButton _btn;
}


///
class ToolBar: ControlSuperClass // docmain
{
    class ToolBarButtonCollection
    {
        protected this()
        {
        }


        private:

        ToolBarButton[] _buttons;


        void _adding(size_t idx, ToolBarButton val)
        {
            if(val.tbar)
                throw new DflException("ToolBarButton already belongs to a ToolBar");
        }


        void _added(size_t idx, ToolBarButton val)
        {
            val.tbar = tbar;
            val._id = tbar._allocTbbID();

            if(created)
            {
                _ins(idx, val);
            }
        }


        void _removed(size_t idx, ToolBarButton val)
        {
            if(size_t.max == idx) // Clear all.
            {
            }
            else
            {
                if(created)
                {
                    prevwproc(TB_DELETEBUTTON, idx, 0);
                }
                val.tbar = null;
            }
        }


        public:

        mixin ListWrapArray!(ToolBarButton, _buttons,
            _adding, _added,
            _blankListCallback!(ToolBarButton), _removed,
            true, false, false,
            true); // CLEAR_EACH
    }


    private @property ToolBar tbar()
    {
        return this;
    }


    this()
    {
        _initToolbar();

        _tbuttons = new ToolBarButtonCollection();

        dock = DockStyle.TOP;

        wclassStyle = toolbarClassStyle;
    }


    ///
    final @property ToolBarButtonCollection buttons() // getter
    {
        return _tbuttons;
    }


    ///
    final @property Size imageSize() // getter
    {
        version(DFL_NO_IMAGELIST)
        {
        }
        else
        {
            if(_imglist)
                return _imglist.imageSize;
        }
        return Size(16, 16); // ?
    }


    version(DFL_NO_IMAGELIST)
    {
    }
    else
    {
        ///
        final @property void imageList(ImageList imglist) // setter
        {
            if(isHandleCreated)
            {
                prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM)imglist.handle);
            }

            _imglist = imglist;
        }

        /// ditto
        final @property ImageList imageList() // getter
        {
            return _imglist;
        }
    }


    ///
    Event!(ToolBar, ToolBarButtonClickEventArgs) buttonClick;


    ///
    protected void onButtonClick(ToolBarButtonClickEventArgs ea)
    {
        buttonClick(this, ea);
    }


    protected override void onReflectedMessage(ref Message m)
    {
        switch(m.msg)
        {
            case WM_NOTIFY:
                {
                    auto nmh = cast(LPNMHDR)m.lParam;
                    switch(nmh.code)
                    {
                        case NM_CLICK:
                            {
                                auto nmm = cast(LPNMMOUSE)nmh;
                                if(nmm.dwItemData)
                                {
                                    auto tbb = cast(ToolBarButton)cast(void*)nmm.dwItemData;
                                    scope ToolBarButtonClickEventArgs bcea = new ToolBarButtonClickEventArgs(tbb);
                                    onButtonClick(bcea);
                                }
                            }
                            break;

                        case TBN_DROPDOWN:
                            version(DFL_TOOLBAR_NO_MENU) // This condition might be removed later.
                            {
                            }
                            else // Ditto.
                            {
                                auto nmtb = cast(LPNMTOOLBARA)nmh; // NMTOOLBARA/NMTOOLBARW doesn't matter here; string fields not used.
                                auto tbb = buttomFromID(nmtb.iItem);
                                if(tbb)
                                {
                                    version(DFL_TOOLBAR_NO_MENU) // Keep this here in case the other condition is removed.
                                    {
                                    }
                                    else // Ditto.
                                    {
                                        if(tbb._cmenu)
                                        {
                                            auto brect = tbb.rectangle;
                                            tbb._cmenu.show(this, pointToScreen(Point(brect.x, brect.bottom)));
                                            // Note: showing a menu also triggers a click!
                                        }
                                    }
                                }
                            }
                            m.result = TBDDRET_DEFAULT;
                            return;

                        default:
                    }
                }
                break;

            default:
                super.onReflectedMessage(m);
        }
    }


    protected override @property Size defaultSize() // getter
    {
        return Size(100, 16);
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        cp.className = TOOLBAR_CLASSNAME;
    }


    // Used internally
    final ToolBarButton buttomFromID(int id) // package
    {
        foreach(tbb; _tbuttons._buttons)
        {
            if(id == tbb._id)
                return tbb;
        }
        return null;
    }


    package int _lastTbbID = 0;

    package final int _allocTbbID()
    {
        for(int j = 0; j != 250; j++)
        {
            _lastTbbID++;
            if(_lastTbbID >= short.max)
                _lastTbbID = 1;

            if(!buttomFromID(_lastTbbID))
                return _lastTbbID;
        }
        return 0;
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        prevwproc(TB_BUTTONSTRUCTSIZE, TBBUTTON.sizeof, 0);

        version(DFL_NO_IMAGELIST)
        {
        }
        else
        {
            if(_imglist)
                prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM)_imglist.handle);
        }

        foreach(idx, tbb; _tbuttons._buttons)
        {
            _ins(idx, tbb);
        }
    }


    protected override void prevWndProc(ref Message msg)
    {
        msg.result = CallWindowProcW(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
    }


    private:

    ToolBarButtonCollection _tbuttons;

    version(DFL_NO_IMAGELIST)
    {
    }
    else
    {
        ImageList _imglist;
    }


    void _ins(size_t idx, ToolBarButton tbb)
    {
        // To change: TB_SETBUTTONINFO

        TBBUTTON xtb;
        version(DFL_NO_IMAGELIST)
        {
            xtb.iBitmap = -1;
        }
        else
        {
            xtb.iBitmap = tbb._imgidx;
        }
        xtb.idCommand = tbb._id;
        xtb.dwData = cast(DWORD)cast(void*)tbb;
        xtb.fsState = tbb._state;
        xtb.fsStyle = TBSTYLE_AUTOSIZE | tbb._style; // TBSTYLE_AUTOSIZE factors in the text's width instead of default button size.
        LRESULT lresult;
        // MSDN says iString can be either an int offset or pointer to a string buffer.
        if(tbb._text.length)
            xtb.iString = cast(typeof(xtb.iString))tbb._text.ptr;
        lresult = prevwproc(TB_INSERTBUTTONA, idx, cast(LPARAM)&xtb);
    }


    package:
    final:
    LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
    {
        return CallWindowProcW(toolbarPrevWndProc, hwnd, msg, wparam, lparam);
    }
}


private
{
    enum TOOLBAR_CLASSNAME = "DFL_ToolBar";

    WNDPROC toolbarPrevWndProc;

    LONG toolbarClassStyle;

    void _initToolbar()
    {
        if(!toolbarPrevWndProc)
        {
            _initCommonControls(ICC_BAR_CLASSES);

            WNDCLASSW info;
            toolbarPrevWndProc = superClass(HINSTANCE.init, "ToolbarWindow32", TOOLBAR_CLASSNAME, info);
            if(!toolbarPrevWndProc)
                _unableToInit(TOOLBAR_CLASSNAME);
            toolbarClassStyle = info.style;
        }
    }
}

