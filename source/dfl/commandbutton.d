// Written by Deen O'Connor

module dfl.commandbutton;


private import dfl.base;
private import dfl.button; // Based on a regular button
private import dfl.control;
private import dfl.event;
private import dfl.drawing;

import core.sys.windows.windows;
import core.sys.windows.commctrl;


class CommandButton : ButtonBase {

    /*
    These exist in core.sys.windows.commctrl, but the way
    they're defined there is weird, so they're copied here
    */
    private static enum BS_COMMANDLINK = 0x0000_000E;
    private static enum BS_DEFCOMMANDLINK = 0x0000_000F;


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        // BS_DEFPUSHBUTTON is appied in ButtonBase
        cp.style &= ~BS_DEFPUSHBUTTON;
        cp.style &= ~BS_PUSHBUTTON;
        if (this.isDefault) {
            cp.style |= BS_DEFCOMMANDLINK;
        } else {
            cp.style |= BS_COMMANDLINK;
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

    alias Control.text text; // Overload.

    @property wstring note()
    {
        return this.lowtext;
    }

    @property void note(wstring txt)
    {
        this.lowtext = txt;
        SendMessageW(hwnd, BCM_FIRST+0x9, 0, cast(LPARAM)this.lowtext.ptr); // BCM_SETNOTE
    }

    ///
    @property Image image() // getter
    {
        return _img;
    }

    /// ditto
    @property void image(Image img) // setter
    {
        _img = null; // In case of exception.
        LONG imgst = 0;
        if(img)
        {
            switch(img._imgtype(null))
            {
                case 1:
                    imgst = BS_BITMAP;
                    break;

                case 2:
                    imgst = BS_ICON;
                    break;

                default:
                    throw new DflException("Unsupported image format");
            }
        }

        _img = img;
        if(img)
        {
            if(isHandleCreated)
                setImg(imgst);
        }
    }


    private void setImg(LONG bsImageStyle)
    in
    {
        assert(isHandleCreated);
    }
    do
    {
        WPARAM wparam = 0;
        LPARAM lparam = 0;

        if(!_img)
            return;
        HGDIOBJ hgo;
        switch(_img._imgtype(&hgo))
        {
            case 1:
                wparam = IMAGE_BITMAP;
                break;

            case 2:
                wparam = IMAGE_ICON;
                break;

            default:
                return;
        }
        lparam = cast(LPARAM)hgo;

        SendMessageA(handle, BM_SETIMAGE, wparam, lparam);
        invalidate();
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        setImg(_bstyle());
        note(note());
    }


private:
    wstring lowtext = ""; // For BCM_SETNOTE
    Image _img = null;

}