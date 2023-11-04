// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.listbox;

static import std.algorithm;

private import dfl.control;
private import dfl.base;
private import dfl.application;
private import dfl.drawing;
private import dfl.event;
private import dfl.collections;

private import core.stdc.string : memmove;
private import std.string : toStringz, fromStringz;
private import std.conv : to;
private import core.sys.windows.windows;


private extern(Windows) void _initListbox();


alias StringObject ListString;


///
abstract class ListControl: ControlSuperClass // docmain
{
    ///
    final wstring getItemText(Control item)
    {
        return item.toWString();
    }


    Event!(ListControl, EventArgs) selectedValueChanged; ///


    ///
    abstract @property void selectedIndex(int idx); // setter
    /// ditto
    abstract @property int selectedIndex(); // getter

    ///
    abstract @property void selectedValue(Control val); // setter
    /// ditto

    ///
    abstract @property void selectedValue(wstring str); // setter
    /// ditto
    abstract @property Control selectedValue(); // getter


    static @property Color defaultBackColor() // getter
    {
        return SystemColors.window;
    }


    override @property Color backColor() // getter
    {
        if(Color.empty == backc)
            return defaultBackColor;
        return backc;
    }

    alias Control.backColor backColor; // Overload.


    static @property Color defaultForeColor() //getter
    {
        return SystemColors.windowText;
    }


    override @property Color foreColor() // getter
    {
        if(Color.empty == forec)
            return defaultForeColor;
        return forec;
    }

    alias Control.foreColor foreColor; // Overload.


    this()
    {
    }


    protected:

    ///
    void onSelectedValueChanged(EventArgs ea)
    {
        selectedValueChanged(this, ea);
    }


    ///
    // Index change causes the value to be changed.
    void onSelectedIndexChanged(EventArgs ea)
    {
        onSelectedValueChanged(ea); // This appears to be correct.
    }
}


///
enum SelectionMode: ubyte
{
    ONE, ///
    NONE, /// ditto
    MULTI_SIMPLE, /// ditto
    MULTI_EXTENDED, /// ditto
}


///
class ListBox: ListControl // docmain
{
    ///
    static class SelectedIndexCollection
    {
        deprecated alias length count;

        @property int length() // getter
        {
            if(!lbox.isHandleCreated)
                return 0;

            if(lbox.isMultSel())
            {
                return cast(int)lbox.prevwproc(LB_GETSELCOUNT, 0, 0);
            }
            else
            {
                return (lbox.selectedIndex == -1) ? 0 : 1;
            }
        }


        int opIndex(int idx)
        {
            foreach(int onidx; this)
            {
                if(!idx)
                    return onidx;
                idx--;
            }

            // If it's not found it's out of bounds and bad things happen.
            assert(0);
        }


        bool contains(int idx)
        {
            return indexOf(idx) != -1;
        }


        int indexOf(int idx)
        {
            int i = 0;
            foreach(int onidx; this)
            {
                if(onidx == idx)
                    return i;
                i++;
            }
            return -1;
        }


        int opApply(int delegate(ref int) dg)
        {
            int result = 0;

            if(lbox.isMultSel())
            {
                int[] items;
                items = new int[length];
                if(items.length != lbox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
                    throw new DflException("Unable to enumerate selected list items");
                foreach(int _idx; items)
                {
                    int idx = _idx; // Prevent ref.
                    result = dg(idx);
                    if(result)
                        break;
                }
            }
            else
            {
                int idx;
                idx = lbox.selectedIndex;
                if(-1 != idx)
                    result = dg(idx);
            }
            return result;
        }

        mixin OpApplyAddIndex!(opApply, int);


        protected this(ListBox lb)
        {
            lbox = lb;
        }


        package:
        ListBox lbox;
    }


    ///
    static class SelectedObjectCollection
    {
        deprecated alias length count;

        @property int length() // getter
        {
            if(!lbox.isHandleCreated)
                return 0;

            if(lbox.isMultSel())
            {
                return cast(int)lbox.prevwproc(LB_GETSELCOUNT, 0, 0);
            }
            else
            {
                return (lbox.selectedIndex == -1) ? 0 : 1;
            }
        }


        Object opIndex(int idx)
        {
            foreach(Object obj; this)
            {
                if(!idx)
                    return obj;
                idx--;
            }

            // If it's not found it's out of bounds and bad things happen.
            assert(0);
        }


        bool contains(Object obj)
        {
            return indexOf(obj) != -1;
        }


        bool contains(wstring str)
        {
            return indexOf(str) != -1;
        }


        int indexOf(Object obj)
        {
            int idx = 0;
            foreach(Object onobj; this)
            {
                if(onobj == obj) // Not using is.
                    return idx;
                idx++;
            }
            return -1;
        }


        int indexOf(wstring str)
        {
            int idx = 0;
            foreach(Object onobj; this)
            {
                if(to!wstring(onobj.toString()) == str)
                    return idx;
                idx++;
            }
            return -1;
        }


        // Used internally.
        int _opApply(int delegate(ref Object) dg) // package
        {
            int result = 0;

            if(lbox.isMultSel())
            {
                int[] items;
                items = new int[length];
                if(items.length != lbox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
                    throw new DflException("Unable to enumerate selected list items");
                foreach(int idx; items)
                {
                    Object obj;
                    obj = lbox.items[idx];
                    result = dg(obj);
                    if(result)
                        break;
                }
            }
            else
            {
                Object obj;
                obj = lbox.selectedItem;
                if(obj)
                    result = dg(obj);
            }
            return result;
        }


        // Used internally.
        int _opApply(int delegate(ref wstring) dg) // package
        {
            int result = 0;

            if(lbox.isMultSel())
            {
                int[] items;
                items = new int[length];
                if(items.length != lbox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
                    throw new DflException("Unable to enumerate selected list items");
                foreach(int idx; items)
                {
                    wstring str = ""w;
                    // Test this!
                    if (is(lbox.items[idx] == Object) || is(lbox.items[idx] == Control)) {
                        str = (cast(Control)lbox.items[idx]).toWString();
                    } else if (is(lbox.items[idx] == wstring) || is(lbox.items[idx] == string)) {
                        str = to!wstring(lbox.items[idx]);
                    }                    
                    result = dg(str);
                    if(result)
                        break;
                }
            }
            else
            {
                Object obj;
                wstring str;
                obj = lbox.selectedItem;
                if(obj)
                {
                    str = to!wstring(obj.toString());
                    result = dg(str);
                }
            }
            return result;
        }

        mixin OpApplyAddIndex!(_opApply, wstring);

        mixin OpApplyAddIndex!(_opApply, Object);

        // Had to do it this way because: DMD 1.028: -H is broken for mixin identifiers
        // Note that this way probably prevents opApply from being overridden.
        alias _opApply opApply;


        protected this(ListBox lb)
        {
            lbox = lb;
        }


        package:
        ListBox lbox;
    }


    ///
    enum int DEFAULT_ITEM_HEIGHT = 13;
    ///
    enum int NO_MATCHES = LB_ERR;


    protected override @property Size defaultSize() // getter
    {
        return Size(120, 95);
    }


    ///
    @property void borderStyle(BorderStyle bs) // setter
    {
        final switch(bs)
        {
            case BorderStyle.FIXED_3D:
                _style(_style() & ~WS_BORDER);
                _exStyle(_exStyle() | WS_EX_CLIENTEDGE);
                break;

            case BorderStyle.FIXED_SINGLE:
                _exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
                _style(_style() | WS_BORDER);
                break;

            case BorderStyle.NONE:
                _style(_style() & ~WS_BORDER);
                _exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
                break;
        }

        if(isHandleCreated)
        {
            redrawEntire();
        }
    }

    /// ditto
    @property BorderStyle borderStyle() // getter
    {
        if(_exStyle() & WS_EX_CLIENTEDGE)
            return BorderStyle.FIXED_3D;
        else if(_style() & WS_BORDER)
            return BorderStyle.FIXED_SINGLE;
        return BorderStyle.NONE;
    }


    ///
    @property void drawMode(DrawMode dm) // setter
    {
        LONG wl = _style() & ~(LBS_OWNERDRAWVARIABLE | LBS_OWNERDRAWFIXED);

        final switch(dm)
        {
            case DrawMode.OWNER_DRAW_VARIABLE:
                wl |= LBS_OWNERDRAWVARIABLE;
                break;

            case DrawMode.OWNER_DRAW_FIXED:
                wl |= LBS_OWNERDRAWFIXED;
                break;

            case DrawMode.NORMAL:
                break;
        }

        _style(wl);

        _crecreate();
    }

    /// ditto
    @property DrawMode drawMode() // getter
    {
        LONG wl = _style();

        if(wl & LBS_OWNERDRAWVARIABLE)
            return DrawMode.OWNER_DRAW_VARIABLE;
        if(wl & LBS_OWNERDRAWFIXED)
            return DrawMode.OWNER_DRAW_FIXED;
        return DrawMode.NORMAL;
    }


    ///
    final @property void horizontalExtent(int he) // setter
    {
        if(isHandleCreated)
            prevwproc(LB_SETHORIZONTALEXTENT, he, 0);

        hextent = he;
    }

    /// ditto
    final @property int horizontalExtent() // getter
    {
        if(isHandleCreated)
            hextent = cast(int)prevwproc(LB_GETHORIZONTALEXTENT, 0, 0);
        return hextent;
    }


    ///
    final @property void horizontalScrollbar(bool byes) // setter
    {
        if(byes)
            _style(_style() | WS_HSCROLL);
        else
            _style(_style() & ~WS_HSCROLL);

        _crecreate();
    }

    /// ditto
    final @property bool horizontalScrollbar() // getter
    {
        return (_style() & WS_HSCROLL) != 0;
    }


    ///
    final @property void integralHeight(bool byes) //setter
    {
        if(byes)
            _style(_style() & ~LBS_NOINTEGRALHEIGHT);
        else
            _style(_style() | LBS_NOINTEGRALHEIGHT);

        _crecreate();
    }

    /// ditto
    final @property bool integralHeight() // getter
    {
        return (_style() & LBS_NOINTEGRALHEIGHT) == 0;
    }


    ///
    // This function has no effect if the drawMode is OWNER_DRAW_VARIABLE.
    final @property void itemHeight(int h) // setter
    {
        if(drawMode == DrawMode.OWNER_DRAW_VARIABLE)
            return;

        iheight = h;

        if(isHandleCreated)
            prevwproc(LB_SETITEMHEIGHT, 0, MAKELPARAM(h, 0));
    }

    /// ditto
    // Return value is meaningless when drawMode is OWNER_DRAW_VARIABLE.
    final @property int itemHeight() // getter
    {
        return iheight;
    }


    ///
    final @property ObjectCollection items() // getter
    {
        return icollection;
    }


    ///
    final @property void multiColumn(bool byes) // setter
    {
        // TODO: is this the correct implementation?

        if(byes)
            _style(_style() | LBS_MULTICOLUMN | WS_HSCROLL);
        else
            _style(_style() & ~(LBS_MULTICOLUMN | WS_HSCROLL));

        _crecreate();
    }

    /// ditto
    final @property bool multiColumn() // getter
    {
        return (_style() & LBS_MULTICOLUMN) != 0;
    }


    ///
    final @property void scrollAlwaysVisible(bool byes) // setter
    {
        if(byes)
            _style(_style() | LBS_DISABLENOSCROLL);
        else
            _style(_style() & ~LBS_DISABLENOSCROLL);

        _crecreate();
    }

    /// ditto
    final @property bool scrollAlwaysVisible() // getter
    {
        return (_style() & LBS_DISABLENOSCROLL) != 0;
    }


    override @property void selectedIndex(int idx) // setter
    {
        if(isHandleCreated)
        {
            if(isMultSel())
            {
                if(idx == -1)
                {
                    // Remove all selection.

                    // Not working right.
                    //prevwproc(LB_SELITEMRANGE, false, MAKELPARAM(0, ushort.max));

                    // Get the indices directly because deselecting them during
                    // selidxcollection.foreach could screw it up.

                    int[] items;

                    items = new int[selidxcollection.length];
                    if(items.length != prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
                        throw new DflException("Unable to clear selected list items");

                    foreach(int _idx; items)
                    {
                        prevwproc(LB_SETSEL, false, _idx);
                    }
                }
                else
                {
                    // ?
                    prevwproc(LB_SETSEL, true, idx);
                }
            }
            else
            {
                prevwproc(LB_SETCURSEL, idx, 0);
            }
        }
    }

    override @property int selectedIndex() // getter
    {
        if(isHandleCreated)
        {
            if(isMultSel())
            {
                if(selidxcollection.length)
                    return selidxcollection[0];
            }
            else
            {
                LRESULT result;
                result = prevwproc(LB_GETCURSEL, 0, 0);
                if(LB_ERR != result) // Redundant.
                    return cast(int)result;
            }
        }
        return -1;
    }


    ///
    final @property void selectedItem(Control o) // setter
    {
        int i;
        i = items.indexOf(o);
        if(i != -1)
            selectedIndex = i;
    }

    /// ditto
    final @property void selectedItem(wstring str) // setter
    {
        int i;
        i = items.indexOf(str);
        if(i != -1)
            selectedIndex = i;
    }

    final @property Control selectedItem() // getter
    {
        int idx;
        idx = selectedIndex;
        if(idx == -1)
            return null;
        return items[idx];
    }


    override @property void selectedValue(Control val) // setter
    {
        selectedItem = val;
    }

    override @property void selectedValue(wstring str) // setter
    {
        selectedItem = str;
    }

    override @property Control selectedValue() // getter
    {
        return selectedItem;
    }


    ///
    final @property SelectedIndexCollection selectedIndices() // getter
    {
        return selidxcollection;
    }


    ///
    final @property SelectedObjectCollection selectedItems() // getter
    {
        return selobjcollection;
    }


    ///
    @property void selectionMode(SelectionMode selmode) // setter
    {
        LONG wl = _style() & ~(LBS_NOSEL | LBS_EXTENDEDSEL | LBS_MULTIPLESEL);

        final switch(selmode)
        {
            case SelectionMode.ONE:
                break;

            case SelectionMode.MULTI_SIMPLE:
                wl |= LBS_MULTIPLESEL;
                break;

            case SelectionMode.MULTI_EXTENDED:
                wl |= LBS_EXTENDEDSEL;
                break;

            case SelectionMode.NONE:
                wl |= LBS_NOSEL;
                break;
        }

        _style(wl);

        _crecreate();
    }

    /// ditto
    @property SelectionMode selectionMode() // getter
    {
        LONG wl = _style();

        if(wl & LBS_NOSEL)
            return SelectionMode.NONE;
        if(wl & LBS_EXTENDEDSEL)
            return SelectionMode.MULTI_EXTENDED;
        if(wl & LBS_MULTIPLESEL)
            return SelectionMode.MULTI_SIMPLE;
        return SelectionMode.ONE;
    }


    ///
    final @property void sorted(bool byes) // setter
    {
        _sorting = byes;
    }

    /// ditto
    final @property bool sorted() // getter
    {
        return _sorting;
    }


    ///
    final @property void topIndex(int idx) // setter
    {
        if(isHandleCreated)
            prevwproc(LB_SETTOPINDEX, idx, 0);
    }

    /// ditto
    final @property int topIndex() // getter
    {
        if(isHandleCreated)
            return cast(int)prevwproc(LB_GETTOPINDEX, 0, 0);
        return 0;
    }


    ///
    final @property void useTabStops(bool byes) // setter
    {
        if(byes)
            _style(_style() | LBS_USETABSTOPS);
        else
            _style(_style() & ~LBS_USETABSTOPS);

        _crecreate();
    }

    /// ditto
    final @property bool useTabStops() // getter
    {
        return (_style() & LBS_USETABSTOPS) != 0;
    }


    ///
    final void beginUpdate()
    {
        prevwproc(WM_SETREDRAW, false, 0);
    }

    /// ditto
    final void endUpdate()
    {
        prevwproc(WM_SETREDRAW, true, 0);
        invalidate(true); // Show updates.
    }


    package final bool isMultSel()
    {
        return (_style() & (LBS_EXTENDEDSEL | LBS_MULTIPLESEL)) != 0;
    }


    ///
    final void clearSelected()
    {
        if(created)
            selectedIndex = -1;
    }


    ///
    final int finstring(wstring str, int startIndex)
    {
        // TODO: find string if control not created ?

        int result = NO_MATCHES;

        if(created)
        {
            result = cast(int)prevwproc(LB_FINDSTRING, startIndex, cast(LPARAM)str.ptr);
            if(result == LB_ERR) // Redundant.
                result = NO_MATCHES;
        }

        return result;
    }

    /// ditto
    final int finstring(wstring str)
    {
        return finstring(str, -1); // Start at beginning.
    }


    ///
    final int finstringExact(wstring str, int startIndex)
    {
        // TODO: find string if control not created ?

        int result = NO_MATCHES;

        if(created)
        {
            result = cast(int)prevwproc(LB_FINDSTRINGEXACT, startIndex, cast(LPARAM)str.ptr);
            if(result == LB_ERR) // Redundant.
                result = NO_MATCHES;
        }

        return result;
    }

    /// ditto
    final int finstringExact(wstring str)
    {
        return finstringExact(str, -1); // Start at beginning.
    }


    ///
    final int getItemHeight(int idx)
    {
        int result = cast(int)prevwproc(LB_GETITEMHEIGHT, idx, 0);
        if(LB_ERR == result)
            throw new DflException("Unable to obtain item height");
        return result;
    }


    ///
    final Rect getItemRectangle(int idx)
    {
        RECT rect;
        if(LB_ERR == cast(int)prevwproc(LB_GETITEMRECT, idx, cast(LPARAM)&rect))
        {
            return Rect(0, 0, 0, 0); // ?
        }
        return Rect(&rect);
    }


    ///
    final bool getSelected(int idx)
    {
        return prevwproc(LB_GETSEL, idx, 0) > 0;
    }


    ///
    final int indexFromPoint(int x, int y)
    {
        // LB_ITEMFROMPOINT is "nearest", so also check with the item rectangle to
        // see if the point is directly in the item.

        // Maybe use LBItemFromPt() from common controls.

        int result = NO_MATCHES;

        if(created)
        {
            result = cast(int)prevwproc(LB_ITEMFROMPOINT, 0, MAKELPARAM(x, y));
            if(!HIWORD(result)) // In client area
            {
                if(result < 0 || !getItemRectangle(result).contains(x, y))
                    result = NO_MATCHES;
            }
            else // Outside client area.
            {
                result = NO_MATCHES;
            }
        }

        return result;
    }

    /// ditto
    final int indexFromPoint(Point pt)
    {
        return indexFromPoint(pt.x, pt.y);
    }


    ///
    final void setSelected(int idx, bool byes)
    {
        if(created)
             prevwproc(LB_SETSEL, byes, idx);
    }


    ///
    protected ObjectCollection createItemCollection()
    {
        return new ObjectCollection(this);
    }


    ///
    void sort()
    {
        if(icollection._items.length)
        {
            Control[] itemscopy;
            itemscopy = icollection._items.dup;
            std.algorithm.sort( itemscopy );

            items.clear();

            beginUpdate();
            scope(exit)
                endUpdate();

            foreach(i, Control o; itemscopy)
            {
                items.insert(to!int(i), o);
            }
        }
    }


    ///
    static class ObjectCollection
    {
        protected this(ListBox lbox)
        {
            this.lbox = lbox;
        }

        // Only allow controls to be inserted into a listbox
        protected this(ListBox lbox, Control[] range)
        {
            this.lbox = lbox;
            addRange(range);
        }


        protected this(ListBox lbox, wstring[] range)
        {
            this.lbox = lbox;
            addRange(range);
        }


        void add(Control value)
        {
            add2(value);
        }

        void add(wstring value)
        {
            add(new Control(value));
        }


        void addRange(Control[] range)
        {
            if(lbox.sorted)
            {
                foreach(Control value; range)
                {
                    add(value);
                }
            }
            else
            {
                _wraparray.addRange(range);
            }
        }

        void addRange(wstring[] range)
        {
            foreach(wstring value; range)
            {
                add(value);
            }
        }


        private:

        ListBox lbox;
        Control[] _items;


        LRESULT insert2(WPARAM idx, wstring val)
        {
            insert(cast(int)idx, val);
            return idx;
        }


        LRESULT add2(Control val)
        {
            int i;
            if(lbox.sorted)
            {
                for(i = 0; i != _items.length; i++)
                {
                    if(val < _items[i])
                        break;
                }
            }
            else
            {
                i = cast(int)_items.length;
            }

            insert(i, val);

            return i;
        }

        LRESULT add2(wstring val)
        {
            return add2(new Control(val));
        }


        void _added(size_t idx, Control val)
        {
            if(lbox.created)
            {
                lbox.prevwproc(LB_INSERTSTRING, idx, cast(LPARAM)toStringz(val.toString())); // Can this be unsafeAnsiz()?
            }
        }


        void _removed(size_t idx, Control val)
        {
            if(size_t.max == idx) // Clear all.
            {
                if(lbox.created)
                {
                    lbox.prevwproc(LB_RESETCONTENT, 0, 0);
                }
            }
            else
            {
                if(lbox.created)
                {
                    lbox.prevwproc(LB_DELETESTRING, cast(WPARAM)idx, 0);
                }
            }
        }


        public:

        mixin ListWrapArray!(Control, _items,
            _blankListCallback!(Control), _added,
            _blankListCallback!(Control), _removed,
            true, false, false) _wraparray;
    }


    this()
    {
        _initListbox();

        // Default useTabStops and vertical scrolling.
        wstyle |= WS_TABSTOP | LBS_USETABSTOPS | LBS_HASSTRINGS | WS_VSCROLL | LBS_NOTIFY;
        wexstyle |= WS_EX_CLIENTEDGE;
        ctrlStyle |= ControlStyles.SELECTABLE;
        wclassStyle = listboxClassStyle;

        icollection = createItemCollection();
        selidxcollection = new SelectedIndexCollection(this);
        selobjcollection = new SelectedObjectCollection(this);
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        // Set the Ctrl ID to the HWND so that it is unique
        // and WM_MEASUREITEM will work properly.
        SetWindowLongW(hwnd, GWL_ID, cast(LONG)hwnd);

        if(hextent != 0)
            prevwproc(LB_SETHORIZONTALEXTENT, hextent, 0);

        if(iheight != DEFAULT_ITEM_HEIGHT)
            prevwproc(LB_SETITEMHEIGHT, 0, MAKELPARAM(iheight, 0));

        Message m;
        m.hWnd = handle;
        m.msg = LB_INSERTSTRING;
        // Note: duplicate code.
            foreach(size_t i, Object obj; icollection._items)
            {
                m.wParam = i;
                m.lParam = cast(LPARAM)to!wstring((obj.toString())).ptr; // Can this be unsafeAnsiz? // <--

                prevWndProc(m);
                if(m.result < 0)
                    throw new DflException("Unable to add list item");
            }
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        cp.className = LISTBOX_CLASSNAME;
    }


    Event!(ListBox, DrawItemEventArgs) drawItem; ///
    Event!(ListBox, MeasureItemEventArgs) measureItem; ///


    protected:

    ///
    void onDrawItem(DrawItemEventArgs dieh)
    {
        drawItem(this, dieh);
    }


    ///
    void onMeasureItem(MeasureItemEventArgs miea)
    {
        measureItem(this, miea);
    }


    package final void _WmDrawItem(DRAWITEMSTRUCT* dis)
    in
    {
        assert(dis.hwndItem == handle);
        assert(dis.CtlType == ODT_LISTBOX);
    }
    do
    {
        DrawItemState state;
        state = cast(DrawItemState)dis.itemState;

        if(dis.itemID == -1)
        {
            FillRect(dis.hDC, &dis.rcItem, hbrBg);
            if(state & DrawItemState.FOCUS)
                DrawFocusRect(dis.hDC, &dis.rcItem);
        }
        else
        {
            DrawItemEventArgs diea;
            Color bc, fc;

            if(state & DrawItemState.SELECTED)
            {
                bc = Color.systemColor(COLOR_HIGHLIGHT);
                fc = Color.systemColor(COLOR_HIGHLIGHTTEXT);
            }
            else
            {
                bc = backColor;
                fc = foreColor;
            }

            prepareDc(dis.hDC);
            diea = new DrawItemEventArgs(new Graphics(dis.hDC, false), wfont,
                Rect(&dis.rcItem), dis.itemID, state, fc, bc);

            onDrawItem(diea);
        }
    }


    package final void _WmMeasureItem(MEASUREITEMSTRUCT* mis)
    in
    {
        assert(mis.CtlType == ODT_LISTBOX);
    }
    do
    {
        MeasureItemEventArgs miea;
        scope Graphics gpx = new CommonGraphics(handle(), GetDC(handle));
        miea = new MeasureItemEventArgs(gpx, mis.itemID, iheight);
        miea.itemWidth = mis.itemWidth;

        onMeasureItem(miea);

        mis.itemHeight = miea.itemHeight;
        mis.itemWidth = miea.itemWidth;
    }


    override void prevWndProc(ref Message msg)
    {
        msg.result = CallWindowProcW(listboxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
    }


    protected override void onReflectedMessage(ref Message m)
    {
        super.onReflectedMessage(m);

        switch(m.msg)
        {
            case WM_DRAWITEM:
                _WmDrawItem(cast(DRAWITEMSTRUCT*)m.lParam);
                m.result = 1;
                break;

            case WM_MEASUREITEM:
                _WmMeasureItem(cast(MEASUREITEMSTRUCT*)m.lParam);
                m.result = 1;
                break;

            case WM_COMMAND:
                assert(cast(HWND)m.lParam == handle);
                switch(HIWORD(m.wParam))
                {
                    case LBN_SELCHANGE:
                        onSelectedIndexChanged(EventArgs.empty);
                        break;

                    case LBN_SELCANCEL:
                        onSelectedIndexChanged(EventArgs.empty);
                        break;

                    default:
                }
                break;

            default:
        }
    }


    override void wndProc(ref Message msg)
    {
        switch(msg.msg)
        {
            case LB_ADDSTRING:
                msg.result = icollection.add2(to!wstring(fromStringz(cast(wchar*)msg.lParam))); // TODO: fix. // Needed in D2.
                return;

            case LB_INSERTSTRING:
                msg.result = icollection.insert2(msg.wParam, to!wstring(fromStringz(cast(wchar*)msg.lParam))); // TODO: fix. // Needed in D2.
                return;

            case LB_DELETESTRING:
                icollection.removeAt(cast(int)msg.wParam);
                msg.result = icollection.length;
                return;

            case LB_RESETCONTENT:
                icollection.clear();
                return;

            case LB_SETITEMDATA:
                // Cannot set item data from outside DFL.
                msg.result = LB_ERR;
                return;

            case LB_ADDFILE:
                msg.result = LB_ERR;
                return;

            case LB_DIR:
                msg.result = LB_ERR;
                return;

            default:
        }
        super.wndProc(msg);
    }


    private:
    int hextent = 0;
    int iheight = DEFAULT_ITEM_HEIGHT;
    ObjectCollection icollection;
    SelectedIndexCollection selidxcollection;
    SelectedObjectCollection selobjcollection;
    bool _sorting = false;


    package:
    final:
    LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
    {
        return CallWindowProcW(listboxPrevWndProc, hwnd, msg, wparam, lparam);
    }
}

