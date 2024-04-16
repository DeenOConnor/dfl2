// Written by Deen O'Connor

module dfl.splitbutton;

private import dfl.base;
private import dfl.button; // Based on a regular button
private import dfl.collections;
private import dfl.control;
private import dfl.event;
private import dfl.drawing;

import std.conv : to;

import core.sys.windows.windows;
import core.sys.windows.commctrl;

class SplitButton : ButtonBase {


    /*
    These exist in core.sys.windows.commctrl, but the way
    they're defined there is weird, so they're copied here
    */
    private static enum BS_SPLITBUTTON = 0x0000_000C;
    private static enum BS_DEFSPLITBUTTON = 0x0000_000D;
    private static enum BCN_DROPDOWN = BCN_FIRST + 0x0002;
    private static enum BCM_SETSPLITINFO = BCM_FIRST + 0x0007;
    private static enum TPM_VERPOSANIMATION = 0x1000;
    private struct BUTTON_SPLITINFO
    {
        UINT mask;
        HIMAGELIST himlGlyph;
        UINT uSplitStyle;
        SIZE size;
    }
    private struct NMBCDROPDOWN {
      NMHDR hdr;
      RECT rcButton;
    }


    this() {
        this.icollection = createItemCollection();
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        // BS_DEFPUSHBUTTON is appied in ButtonBase
        cp.style &= ~BS_DEFPUSHBUTTON;
        cp.style &= ~BS_PUSHBUTTON;
        if (this.isDefault) {
            cp.style |= BS_DEFSPLITBUTTON;
        } else {
            cp.style |= BS_SPLITBUTTON;
        }
    }

    // performClick is defined in Button, not in ButtonBase
    void performClick()
    {
        if(!enabled || !visible || !isHandleCreated) // ?
            return; // ?
        onClick(EventArgs.empty);
    }

    override @property void text(wstring txt) // setter
    {
        super.text = txt;
    }

    public @property int selectedIndex() {
        return this.selectedItemIndex;
    }

    alias Control.text text; // Overload.

    protected override void onReflectedMessage(ref Message m)
    {
        if (m.msg == WM_NOTIFY) {
            NMHDR* info = cast(NMHDR*)m.lParam;
            if (info.code == BCN_DROPDOWN) {
                NMBCDROPDOWN* msgStruct = cast(NMBCDROPDOWN*)m.lParam;
                RECT points = msgStruct.rcButton;
                MapWindowPoints(this.hwnd, HWND_DESKTOP, cast(POINT*)&points, 2);

                auto menu = CreatePopupMenu();
                MENUINFO menuInfo;
                menuInfo.cbSize = MENUINFO.sizeof;
                menuInfo.fMask = MIM_STYLE | MIM_BACKGROUND;
                menuInfo.dwStyle = MNS_NOCHECK;
                menuInfo.hbrBack = GetSysColorBrush(COLOR_INFOBK);
                SetMenuInfo(menu, &menuInfo);

                foreach(i, item; this.icollection._items) {
                    auto menuText = item.text.dup ~ '\0';
                    MENUITEMINFOW itemInfo;
                    itemInfo.cbSize = MENUITEMINFOW.sizeof;
                    itemInfo.fMask = MIIM_STRING | MIIM_ID;
                    itemInfo.fType = MFT_STRING;
                    itemInfo.fState = MFS_ENABLED;
                    itemInfo.wID = to!uint(i);
                    itemInfo.dwTypeData = menuText.ptr;
                    itemInfo.cch = cast(uint)menuText.length;
                    InsertMenuItemW(menu, -1, 1, &itemInfo);
                }

                TrackPopupMenuEx(menu, TPM_LEFTBUTTON, points.left, points.bottom, this.hwnd, null);
            }
        }
        super.onReflectedMessage(m);
    }

    protected override void wndProc(ref Message m) {
        switch(m.msg) {
            case WM_COMMAND:
                uint sel = cast(uint)(m.wParam);
                this.selectedItemIndex = sel;
                this.text(this.icollection._items[sel].text);
            break;
            default:
        }
        super.wndProc(m);
    }

    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);
        if (imageList !is null) {
            ImageList_Destroy(imageList);
        }
        //imageList = ImageList_Create();
        currentInfo.mask = MASK.STYLE;
        currentInfo.himlGlyph = null;
        //currentInfo.uSplitStyle = STYLE.NOSPLIT; // BCN_DROPDOWN doesn't work with BCSS_NOSPLIT
        SendMessageW(this.hwnd, BCM_SETSPLITINFO, 0, cast(LPARAM)&currentInfo);
    }

    private static enum MASK : int {
        GLYPH = 0x0001, // BCSIF_GLYPH
        IMAGE = 0x0002, // BCSIF_IMAGE
        STYLE = 0x0004, // BCSIF_STYLE
        SIZE = 0x0008, // BCSIF_SIZE
    }

    private static enum STYLE : int {
        NOSPLIT = 0x0001, // BCSS_NOSPLIT
        STRETCH = 0x0002, // BCSS_STRETCH
        ALIGNLEFT = 0x0004, // BCSS_ALIGNLEFT
        IMAGE = 0x0008, // BCSS_IMAGE
    }

    private BUTTON_SPLITINFO currentInfo;
    private HIMAGELIST imageList = null;
    //private Image[] glyphs; // Use this?
    private MASK mask = MASK.GLYPH;
    private STYLE style = STYLE.NOSPLIT;
    
    // Copied from ComboBox

    private ObjectCollection icollection;
    private bool sorted = false;

    private int selectedItemIndex = -1;


    final @property ObjectCollection items() // getter
    {
        return icollection;
    }

    
    protected ObjectCollection createItemCollection()
    {
        return new ObjectCollection(this);
    }


    static class ObjectCollection
    {
        protected this(SplitButton btn)
        {
            this.btn = btn;
        }


        protected this(SplitButton btn, Control[] range)
        {
            this.btn = btn;
            addRange(range);
        }


        protected this(SplitButton btn, wstring[] range)
        {
            this.btn = btn;
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
            if(btn.sorted)
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
            foreach(wstring s; range)
            {
                add(s);
            }
        }


        private:

        SplitButton btn;
        Control[] _items = [];


        this()
        {
        }


        LRESULT insert2(WPARAM idx, wstring val)
        {
            insert(cast(int)idx, val);
            return idx;
        }


        LRESULT add2(Control val)
        {
            int i;
            if(btn.sorted)
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
            if(btn.isHandleCreated)
            {
            }
        }


        void _removed(size_t idx, Control val)
        {
            if(size_t.max == idx) // Clear all.
            {
                if(btn.isHandleCreated)
                {
                }
            }
            else
            {
                if(btn.isHandleCreated)
                {
                }
            }
        }


        public:

        mixin ListWrapArray!(Control, _items,
            _blankListCallback!(Control), _added,
            _blankListCallback!(Control), _removed,
            true, false, false, false) _wraparray;
    }

}