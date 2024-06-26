// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.menu;

private import dfl.control;
private import dfl.base;
private import dfl.event;
private import dfl.drawing;
private import dfl.application;
private import dfl.collections;

private import core.sys.windows.windows;

private import std.string : icmp;
private import std.conv : to;


version (DFL_NO_MENUS) {
} else {
    ///
    class ContextMenu : Menu // docmain
    {
        ///
        final void show(Control control, Point pos) {
            SetForegroundWindow(control.handle);
            TrackPopupMenu(hmenu, TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_RIGHTBUTTON,
                pos.x, pos.y, 0, control.handle, null);
        }

        //EventHandler popup;
        Event!(ContextMenu, EventArgs) popup; ///

        // Used internally.
        this(HMENU hmenu, bool owned = true) {
            super(hmenu, owned);

            _init();
        }

        this() {
            super(CreatePopupMenu());

            _init();
        }

        ~this() {
            Application.removeMenu(this);

            debug (APP_PRINT)
                cprintf("~ContextMenu\n");
        }

        protected override void onReflectedMessage(ref Message m) {
            super.onReflectedMessage(m);

            switch (m.msg) {
            case WM_INITMENU:
                assert(cast(HMENU) m.wParam == handle);

                popup(this, EventArgs.empty);
                break;

            default:
            }
        }

    private:
        void _init() {
            Application.addContextMenu(this);
        }
    }

    ///
    class MenuItem : Menu // docmain
    {
        ///
        final @property void text(wstring txt) // setter
        {
            if (!menuItems.length && txt == SEPARATOR_TEXT) {
                _type(_type() | MFT_SEPARATOR);
            } else {
                if (mparent) {
                    MENUITEMINFOW mii;

                    if (fType & MFT_SEPARATOR)
                        fType = ~MFT_SEPARATOR;
                    mii.cbSize = mii.sizeof;
                    mii.fMask = MIIM_TYPE | MIIM_STATE; // Not setting the state can cause implicit disabled/gray if the text was empty.
                    mii.fType = fType;
                    mii.fState = fState;

                    mparent._setInfo(mid, false, &mii, txt);
                }
            }

            mtext = txt;
        }

        /// ditto
        final @property wstring text() // getter
        {
            // if(mparent) fetch text ?
            return mtext;
        }

        ///
        final @property void parent(Menu m) // setter
        {
            m.menuItems.add(this);
        }

        /// ditto
        final @property Menu parent() // getter
        {
            return mparent;
        }

        package final void _setParent(Menu newParent) {
            assert(!mparent);
            mparent = newParent;

            if (cast(int) mindex > mparent.menuItems.length)
                mindex = cast(int) mparent.menuItems.length;

            _setParent();
        }

        private void _setParent() {
            MENUITEMINFOW mii;
            MenuItem miparent;

            mii.cbSize = mii.sizeof;
            mii.fMask = MIIM_TYPE | MIIM_STATE | MIIM_ID | MIIM_SUBMENU;
            mii.fType = fType;
            mii.fState = fState;
            mii.wID = mid;
            mii.hSubMenu = handle;
            miparent = cast(MenuItem) mparent;
            if (miparent && !miparent.hmenu) {
                miparent.hmenu = CreatePopupMenu();

                if (miparent.parent() && miparent.parent.hmenu) {
                    MENUITEMINFOW miiPopup;

                    miiPopup.cbSize = miiPopup.sizeof;
                    miiPopup.fMask = MIIM_SUBMENU;
                    miiPopup.hSubMenu = miparent.hmenu;
                    miparent.parent._setInfo(miparent._menuID, false, &miiPopup);
                }
            }
            mparent._insert(mindex, true, &mii, (fType & MFT_SEPARATOR) ? null : mtext);
        }

        package final void _unsetParent() {
            assert(mparent);
            assert(mparent.menuItems.length > 0);
            assert(mparent.hmenu);

            // Last child menu item, make the parent non-popup now.
            if (mparent.menuItems.length == 1) {
                MenuItem miparent;

                miparent = cast(MenuItem) mparent;
                if (miparent && miparent.hmenu) {
                    MENUITEMINFOW miiPopup;

                    miiPopup.cbSize = miiPopup.sizeof;
                    miiPopup.fMask = MIIM_SUBMENU;
                    miiPopup.hSubMenu = null;
                    miparent.parent._setInfo(miparent._menuID, false, &miiPopup);

                    miparent.hmenu = null;
                }
            }

            mparent = null;
        }


        ///
        final @property void barBreak(bool byes) // setter
        {
            if (byes)
                _type(_type() | MFT_MENUBARBREAK);
            else
                _type(_type() & ~MFT_MENUBARBREAK);
        }

        /// ditto
        final @property bool barBreak() // getter
        {
            return (_type() & MFT_MENUBARBREAK) != 0;
        }


        ///
        final @property void breakItem(bool byes) // setter
        {
            if (byes)
                _type(_type() | MFT_MENUBREAK);
            else
                _type(_type() & ~MFT_MENUBREAK);
        }

        /// ditto
        final @property bool breakItem() // getter
        {
            return (_type() & MFT_MENUBREAK) != 0;
        }


        ///
        final @property void checked(bool byes) // setter
        {
            if (byes)
                _state(_state() | MFS_CHECKED);
            else
                _state(_state() & ~MFS_CHECKED);
        }

        /// ditto
        final @property bool checked() // getter
        {
            return (_state() & MFS_CHECKED) != 0;
        }


        ///
        final @property void defaultItem(bool byes) // setter
        {
            if (byes)
                _state(_state() | MFS_DEFAULT);
            else
                _state(_state() & ~MFS_DEFAULT);
        }

        /// ditto
        final @property bool defaultItem() // getter
        {
            return (_state() & MFS_DEFAULT) != 0;
        }


        ///
        final @property void enabled(bool byes) // setter
        {
            if (byes)
                _state(_state() & ~MFS_GRAYED);
            else
                _state(_state() | MFS_GRAYED);
        }

        /// ditto
        final @property bool enabled() // getter
        {
            return (_state() & MFS_GRAYED) == 0;
        }


        ///
        final @property void index(int idx) // setter
        { // Note: probably fails when the parent exists because mparent is still set and menuItems.insert asserts it's null.
            if (mparent) {
                if (cast(uint) idx > mparent.menuItems.length)
                    throw new DflException("Invalid menu index");

                mparent._remove(mid, MF_BYCOMMAND);
                mparent.menuItems._delitem(mindex);
                mparent.menuItems.insert(idx, this);
            }
        }

        /// ditto
        final @property int index() // getter
        {
            return mindex;
        }


        override @property bool isParent() // getter
        {
            return handle != null; // ?
        }


        deprecated final @property void mergeOrder(int ord) // setter
        {
        }

        deprecated final @property int mergeOrder() // getter
        {
            return 0;
        }

        // TODO: mergeType().

        ///
        // Returns a NUL char if none.
        final @property char mnemonic() // getter
        {
            bool singleAmp = false;

            foreach (char ch; mtext) {
                if (singleAmp) {
                    if (ch == '&')
                        singleAmp = false;
                    else
                        return ch;
                } else {
                    if (ch == '&')
                        singleAmp = true;
                }
            }

            return 0;
        }

        /+
        // TODO: implement owner drawn menus.

        final @property void ownerDraw(bool byes) // setter
        {

        }

        final @property bool ownerDraw() // getter
        {

        }
        +/

        ///
        final @property void radioCheck(bool byes) // setter
        {
            auto par = parent;
            auto pidx = index;
            if (par)
                par.menuItems._removing(pidx, this);

            if (byes) //_type(_type() | MFT_RADIOCHECK);
                fType |= MFT_RADIOCHECK;
            else //_type(_type() & ~MFT_RADIOCHECK);
                fType &= ~MFT_RADIOCHECK;

            if (par)
                par.menuItems._added(pidx, this);
        }

        /// ditto
        final @property bool radioCheck() // getter
        {
            return (_type() & MFT_RADIOCHECK) != 0;
        }

        // TODO: shortcut(), showShortcut().

        /+
        // TODO: need to fake this ?

        final @property void visible(bool byes) // setter
        {
            // ?
            mvisible = byes;
        }

        final @property bool visible() // getter
        {
            return mvisible;
        }
        +/

        ///
        final void performClick() {
            onClick(EventArgs.empty);
        }


        ///
        final void performSelect() {
            onSelect(EventArgs.empty);
        }


        // Used internally.
        this(HMENU hmenu, bool owned = true) // package
        {
            super(hmenu, owned);
            _init();
        }


        ///
        this(MenuItem[] items) {
            if (items.length) {
                HMENU hm = CreatePopupMenu();
                super(hm);
            } else {
                super();
            }
            _init();

            menuItems.addRange(items);
        }


        /// ditto
        this(wstring text) {
            _init();

            this.text = text;
        }


        /// ditto
        this(wstring text, MenuItem[] items) {
            if (items.length) {
                HMENU hm = CreatePopupMenu();
                super(hm);
            } else {
                super();
            }
            _init();

            this.text = text;

            menuItems.addRange(items);
        }


        /// ditto
        this() {
            _init();
        }


        ~this() {
            Application.removeMenu(this);

            debug (APP_PRINT)
                cprintf("~MenuItem\n");
        }


        override string toString() {
            return to!string(text);
        }

        wstring toWString() {
            return text;
        }


        override bool opEquals(Object o) {
            return this.toString() == o.toString();
        }

        bool opEquals(wstring val) {
            return text == val;
        }

        override int opCmp(Object o) {
            return icmp(text, o.toString());
        }

        int opCmp(wstring val) {
            return icmp(text, val);
        }


        protected override void onReflectedMessage(ref Message m) {
            super.onReflectedMessage(m);

            switch (m.msg) {
            case WM_COMMAND:
                assert(LOWORD(m.wParam) == mid);

                onClick(EventArgs.empty);
                break;

            case WM_MENUSELECT:
                onSelect(EventArgs.empty);
                break;

            case WM_INITMENUPOPUP:
                assert(!HIWORD(m.lParam));
                assert(cast(HMENU) m.wParam == handle);

                onPopup(EventArgs.empty);
                break;

            default:
            }
        }


        Event!(MenuItem, EventArgs) click; ///
        Event!(MenuItem, EventArgs) popup; ///
        Event!(MenuItem, EventArgs) select; ///

    protected:

        ///
        final @property int menuID() // getter
        {
            return mid;
        }

        package final @property int _menuID() {
            return mid;
        }

        ///
        void onClick(EventArgs ea) {
            click(this, ea);
        }

        ///
        void onPopup(EventArgs ea) {
            popup(this, ea);
        }

        ///
        void onSelect(EventArgs ea) {
            select(this, ea);
        }

    private:

        int mid; // Menu ID.
        wstring mtext;
        Menu mparent;
        UINT fType = 0; // MFT_*
        UINT fState = 0;
        int mindex = -1; //0;

        enum SEPARATOR_TEXT = "-";

        static assert(!MFS_UNCHECKED);
        static assert(!MFT_STRING);

        void _init() {
            mid = Application.addMenuItem(this);
        }


        @property void _type(UINT newType) // setter
        {
            if (mparent) {
                MENUITEMINFOW mii;

                mii.cbSize = mii.sizeof;
                mii.fMask = MIIM_TYPE;
                mii.fType = newType;

                mparent._setInfo(mid, false, &mii);
            }

            fType = newType;
        }

        @property UINT _type() // getter
        {
            // if(mparent) fetch value ?
            return fType;
        }


        @property void _state(UINT newState) // setter
        {
            if (mparent) {
                MENUITEMINFOW mii;

                mii.cbSize = mii.sizeof;
                mii.fMask = MIIM_STATE;
                mii.fState = newState;

                mparent._setInfo(mid, false, &mii);
            }

            fState = newState;
        }

        @property UINT _state() // getter
        {
            // if(mparent) fetch value ? No: Windows seems to add disabled/gray when the text is empty.
            return fState;
        }
    }

    ///
    abstract class Menu : Object // docmain
    {
        ///
        static class MenuItemCollection {
            protected this(Menu owner) {
                _owner = owner;
            }

            package final void _additem(MenuItem mi) {
                // Fix indices after this point.
                int idx;
                idx = mi.index + 1; // Note, not orig idx.
                if (idx < items.length) {
                    foreach (MenuItem onmi; items[idx .. items.length]) {
                        onmi.mindex++;
                    }
                }
            }

            // Note: clear() doesn't call this. Update: does now.
            package final void _delitem(int idx) {
                // Fix indices after this point.
                if (idx < items.length) {
                    foreach (MenuItem onmi; items[idx .. items.length]) {
                        onmi.mindex--;
                    }
                }
            }

            void add(MenuItem mi) {
                mi.mindex = cast(int) length;
                insert(mi.mindex, mi);
            }

            void add(wstring value) {
                add(new MenuItem(value));
            }

            void addRange(MenuItem[] items) {
                return _wraparray.addRange(items);
            }

            void addRange(wstring[] items) {
                _wraparray.addRange(items);
            }

            // TODO: finish.

        package:

            Menu _owner;
            MenuItem[] items; // Kept populated so the menu can be moved around.

            void _added(int idx, MenuItem val) {
                val.mindex = idx;
                val._setParent(_owner);
                _additem(val);
            }

            void _removing(int idx, MenuItem val) {
                if (int.max == idx) // Clear all.
                {
                } else {
                    val._unsetParent();
                    _owner._remove(idx, MF_BYPOSITION);
                    _delitem(idx);
                }
            }

        public:

            mixin ListWrapArray!(MenuItem, items,
                _blankListCallback!(MenuItem), _added,
                _removing, _blankListCallback!(MenuItem),
                true, false, false,
                true) _wraparray; // CLEAR_EACH
        }

        // Extra.
        deprecated final void opCatAssign(MenuItem mi) {
            menuItems.insert(cast(int) menuItems.length, mi);
        }

        private void _init() {
            items = new MenuItemCollection(this);
        }

        // Menu item that isn't popup (yet).
        protected this() {
            _init();
        }

        // Used internally.
        this(HMENU hmenu, bool owned = true) // package
        {
            this.hmenu = hmenu;
            this.owned = owned;

            _init();
        }

        // Used internally.
        this(HMENU hmenu, MenuItem[] items) // package
        {
            this.owned = true;
            this.hmenu = hmenu;

            _init();

            menuItems.addRange(items);
        }

        // Don't call directly.
        @disable this(MenuItem[] items);

        ~this() {
            if (owned)
                DestroyMenu(hmenu);
        }

        ///
        final @property void tag(Object o) // setter
        {
            ttag = o;
        }

        /// ditto
        final @property Object tag() // getter
        {
            return ttag;
        }

        ///
        final @property HMENU handle() // getter
        {
            return hmenu;
        }

        ///
        final @property MenuItemCollection menuItems() // getter
        {
            return items;
        }

        ///
        @property bool isParent() // getter
        {
            return false;
        }

        ///
        protected void onReflectedMessage(ref Message m) {
        }

        package final void _reflectMenu(ref Message m) {
            onReflectedMessage(m);
        }

        /+ package +/
        protected void _setInfo(UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii, wstring typeData = null) // package
        {
            if (typeData !is null) {
                lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData)) typeData.ptr;
                SetMenuItemInfoW(hmenu, uItem, fByPosition, lpmii);
            } else {
                SetMenuItemInfoW(hmenu, uItem, fByPosition, lpmii);
            }
        }

        /+ package +/
        protected void _insert(UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii, wstring typeData = null) // package
        {
            if (typeData !is null) {
                lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData)) typeData.ptr;
                InsertMenuItemW(hmenu, uItem, fByPosition, lpmii);
            } else {
                InsertMenuItemW(hmenu, uItem, fByPosition, lpmii);
            }
        }

        /+ package +/
        protected void _remove(UINT uPosition, UINT uFlags) // package
        {
            RemoveMenu(hmenu, uPosition, uFlags);
        }

        package HMENU hmenu;

    private:
        bool owned = true;
        MenuItemCollection items;
        Object ttag;
    }

    ///
    class MainMenu : Menu // docmain
    {
        // Used internally.
        this(HMENU hmenu, bool owned = true) {
            super(hmenu, owned);
        }

        ///
        this() {
            super(CreateMenu());
        }

        /// ditto
        this(MenuItem[] items) {
            super(CreateMenu(), items);
        }

        /+ package +/
        protected override void _setInfo(UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii, wstring typeData = null) // package
        {
            Menu._setInfo(uItem, fByPosition, lpmii, typeData);

            if (hwnd)
                DrawMenuBar(hwnd);
        }

        /+ package +/
        protected override void _insert(UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii, wstring typeData = null) // package
        {
            Menu._insert(uItem, fByPosition, lpmii, typeData);

            if (hwnd)
                DrawMenuBar(hwnd);
        }

        /+ package +/
        protected override void _remove(UINT uPosition, UINT uFlags) // package
        {
            Menu._remove(uPosition, uFlags);

            if (hwnd)
                DrawMenuBar(hwnd);
        }

    private:

        HWND hwnd = HWND.init;

        package final void _setHwnd(HWND hwnd) {
            this.hwnd = hwnd;
        }
    }
}
