// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.splitter;

private import dfl.control;
private import dfl.base;
private import dfl.drawing;
private import dfl.event;

private import core.sys.windows.windows;


///
class SplitterEventArgs: EventArgs
{
    ///
    this(int x, int y, int splitX, int splitY)
    {
        _x = x;
        _y = y;
        _splitX = splitX;
        _splitY = splitY;
    }


    ///
    final @property int x() // getter
    {
        return _x;
    }


    ///
    final @property int y() // getter
    {
        return _y;
    }


    ///
    final @property void splitX(int val) // setter
    {
        _splitX = val;
    }

    /// ditto
    final @property int splitX() // getter
    {
        return _splitX;
    }


    ///
    final @property void splitY(int val) // setter
    {
        _splitY = val;
    }

    /// ditto
    final @property int splitY() // getter
    {
        return _splitY;
    }


    private:
    int _x, _y, _splitX, _splitY;
}


///
class Splitter: Control // docmain
{
    this()
    {
        this.dock = DockStyle.LEFT;

        if(HBRUSH.init == hbrxor)
            inithbrxor();
    }


    override @property void dock(DockStyle ds) // setter
    {
        switch(ds)
        {
            case DockStyle.LEFT:
            case DockStyle.RIGHT:
                cursor = Cursors.vSplit;
                break;

            case DockStyle.TOP:
            case DockStyle.BOTTOM:
                cursor = Cursors.hSplit;
                break;

            default:
                throw new DflException("Invalid splitter dock");
        }

        super.dock(ds);
    }

    alias Control.dock dock; // Overload.


    package void initsplit(int sx, int sy)
    {
        capture = true;

        downing = true;

        switch(dock)
        {
            case DockStyle.TOP:
            case DockStyle.BOTTOM:
                downpos = sy;
                lastpos = 0;
                drawxorClient(0, lastpos);
                break;

            default: // LEFT / RIGHT.
                downpos = sx;
                lastpos = 0;
                drawxorClient(lastpos, 0);
        }
    }


    final void resumeSplit(int sx, int sy) // package
    {
        if(Control.mouseButtons & MouseButtons.LEFT)
        {
            initsplit(sx, sy);

            if(cursor)
                Cursor.current = cursor;
        }
    }

    /// ditto
    final void resumeSplit() // package
    {
        Point pt = pointToClient(Cursor.position);
        return resumeSplit(pt.x, pt.y);
    }


    ///
    @property void movingGrip(bool byes) // setter
    {
        if(mgrip == byes)
            return;

        this.mgrip = byes;

        if(created)
        {
            invalidate();
        }
    }

    /// ditto
    @property bool movingGrip() // getter
    {
        return mgrip;
    }

    deprecated alias movingGrip moveingGrip;
    deprecated alias movingGrip moveGrip;
    deprecated alias movingGrip sizingGrip;


    protected override void onPaint(PaintEventArgs ea)
    {
        super.onPaint(ea);

        if(mgrip)
        {
            ea.graphics.drawMoveGrip(displayRectangle, DockStyle.LEFT == dock || DockStyle.RIGHT == dock);
        }
    }


    protected override void onResize(EventArgs ea)
    {
        if(mgrip)
        {
            invalidate();
        }

        resize(this, ea);
    }


    protected override void onMouseDown(MouseEventArgs mea)
    {
        super.onMouseDown(mea);

        if(mea.button == MouseButtons.LEFT && 1 == mea.clicks)
        {
            initsplit(mea.x, mea.y);
        }
    }


    protected override void onMouseMove(MouseEventArgs mea)
    {
        super.onMouseMove(mea);

        if(downing)
        {
            switch(dock)
            {
                case DockStyle.TOP:
                case DockStyle.BOTTOM:
                    drawxorClient(0, mea.y - downpos, 0, lastpos);
                    lastpos = mea.y - downpos;
                    break;

                default: // LEFT / RIGHT.
                    drawxorClient(mea.x - downpos, 0, lastpos, 0);
                    lastpos = mea.x - downpos;
            }

            scope sea = new SplitterEventArgs(mea.x, mea.y, left, top);
            onSplitterMoving(sea);
        }
    }


    protected override void onMove(EventArgs ea)
    {
        super.onMove(ea);

        if(downing) // ?
        {
            Point curpos = Cursor.position;
            curpos = pointToClient(curpos);
            scope sea = new SplitterEventArgs(curpos.x, curpos.y, left, top);
            onSplitterMoved(sea);
        }
    }


    final Control getSplitControl() // package
    {
        Control splat; // Splitted.
        final switch(this.dock())
        {
            case DockStyle.LEFT:
                foreach(Control ctrl; parent.controls())
                {
                    if(DockStyle.LEFT != ctrl.dock)
                        continue;
                    if(ctrl == cast(Control)this)
                        return splat;
                    splat = ctrl;
                }
                break;

            case DockStyle.RIGHT:
                foreach(Control ctrl; parent.controls())
                {
                    if(DockStyle.RIGHT != ctrl.dock)
                        continue;
                    if(ctrl == cast(Control)this)
                        return splat;
                    splat = ctrl;
                }
                break;

            case DockStyle.TOP:
                foreach(Control ctrl; parent.controls())
                {
                    if(DockStyle.TOP != ctrl.dock)
                        continue;
                    if(ctrl == cast(Control)this)
                        return splat;
                    splat = ctrl;
                }
                break;

            case DockStyle.BOTTOM:
                foreach(Control ctrl; parent.controls())
                {
                    if(DockStyle.BOTTOM != ctrl.dock)
                        continue;
                    if(ctrl == cast(Control)this)
                        return splat;
                    splat = ctrl;
                }
                break;

            case DockStyle.FILL:
                assert(0, "DockStyle.FILL is not allowed in Splitter");
                break;

            case DockStyle.NONE:
                assert(0, "DockStyle.NONE is not allowed in Splitter");
                break;
        }
        return null;
    }


    protected override void onMouseUp(MouseEventArgs mea)
    {
        if(downing)
        {
            capture = false;

            downing = false;

            if(mea.button != MouseButtons.LEFT)
            {
                // Abort.
                switch(dock)
                {
                    case DockStyle.TOP:
                    case DockStyle.BOTTOM:
                        drawxorClient(0, lastpos);
                        break;

                    default: // LEFT / RIGHT.
                        drawxorClient(lastpos, 0);
                }
                super.onMouseUp(mea);
                return;
            }

            int adj, val, vx;
            auto splat = getSplitControl(); // Splitted.
            if(splat)
            {
                switch(this.dock())
                {
                    case DockStyle.LEFT:
                        drawxorClient(lastpos, 0);
                        val = left - splat.left + mea.x - downpos;
                        if(val < msize)
                            val = msize;
                        splat.width = val;
                        break;

                    case DockStyle.RIGHT:
                        drawxorClient(lastpos, 0);
                        adj = right - splat.left + mea.x - downpos;
                        val = splat.width - adj;
                        vx = splat.left + adj;
                        if(val < msize)
                        {
                            vx -= msize - val;
                            val = msize;
                        }
                        splat.bounds = Rect(vx, splat.top, val, splat.height);
                        break;

                    case DockStyle.TOP:
                        drawxorClient(0, lastpos);
                        val = top - splat.top + mea.y - downpos;
                        if(val < msize)
                            val = msize;
                        splat.height = val;
                        break;

                    case DockStyle.BOTTOM:
                        drawxorClient(0, lastpos);
                        adj = bottom - splat.top + mea.y - downpos;
                        val = splat.height - adj;
                        vx = splat.top + adj;
                        if(val < msize)
                        {
                            vx -= msize - val;
                            val = msize;
                        }
                        splat.bounds = Rect(splat.left, vx, splat.width, val);
                        break;

                    default:
                }
            }

            // This is needed when the moved control first overlaps the splitter and the splitter
            // gets bumped over, causing a little area to not be updated correctly.
            // I'll fix it someday.
            parent.invalidate(true);

            // Event..
        }

        super.onMouseUp(mea);
    }


    ///
    final @property void minSize(int min) // setter
    {
        msize = min;
    }

    /// ditto
    final @property int minSize() // getter
    {
        return msize;
    }


    ///
    final @property void splitPosition(int pos) // setter
    {
        auto splat = getSplitControl(); // Splitted.
        if(splat)
        {
            switch(this.dock())
            {
                case DockStyle.LEFT:
                case DockStyle.RIGHT:
                    splat.width = pos;
                    break;

                case DockStyle.TOP:
                case DockStyle.BOTTOM:
                    splat.height = pos;
                    break;

                default:
            }
        }
    }

    /// ditto
    // -1 if not docked to a control.
    final @property int splitPosition() // getter
    {
        auto splat = getSplitControl(); // Splitted.
        if(splat)
        {
            switch(this.dock())
            {
                case DockStyle.LEFT:
                case DockStyle.RIGHT:
                    return splat.width;

                case DockStyle.TOP:
                case DockStyle.BOTTOM:
                    return splat.height;

                default:
            }
        }
        return -1;
    }


    Event!(Splitter, SplitterEventArgs) splitterMoved; ///
    Event!(Splitter, SplitterEventArgs) splitterMoving; ///


    protected:

    override @property Size defaultSize() // getter
    {
        int sx = GetSystemMetrics(SM_CXSIZEFRAME);
        int sy = GetSystemMetrics(SM_CYSIZEFRAME);
        // Need a bit extra room for the move-grips.
        if(sx < 5)
            sx = 5;
        if(sy < 5)
            sy = 5;
        return Size(sx, sy);
    }


    ///
    void onSplitterMoving(SplitterEventArgs sea)
    {
        splitterMoving(this, sea);
    }


    ///
    void onSplitterMoved(SplitterEventArgs sea)
    {
        splitterMoving(this, sea);
    }


    private:

    bool downing = false;
    bool mgrip = true;
    int downpos;
    int lastpos;
    int msize = 25; // Min size of control that's being sized from the splitter.
    int mextra = 25; // Min size of the control on the opposite side.

    static HBRUSH hbrxor;


    static void inithbrxor()
    {
        static ubyte[] bmbits = [0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0,
            0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0, ];

        HBITMAP hbm;
        hbm = CreateBitmap(8, 8, 1, 1, bmbits.ptr);
        hbrxor = CreatePatternBrush(hbm);
        DeleteObject(hbm);
    }


    static void drawxor(HDC hdc, Rect r)
    {
        SetBrushOrgEx(hdc, r.x, r.y, null);
        HGDIOBJ hbrold = SelectObject(hdc, hbrxor);
        PatBlt(hdc, r.x, r.y, r.width, r.height, PATINVERT);
        SelectObject(hdc, hbrold);
    }


    void drawxorClient(HDC hdc, int x, int y)
    {
        POINT pt;
        pt.x = x;
        pt.y = y;
        MapWindowPoints(handle, parent.handle, &pt, 1);

        drawxor(hdc, Rect(pt.x, pt.y, width, height));
    }


    void drawxorClient(int x, int y, int xold = int.min, int yold = int.min)
    {
        HDC hdc;
        hdc = GetDCEx(parent.handle, null, DCX_CACHE);

        if(xold != int.min)
            drawxorClient(hdc, xold, yold);

        drawxorClient(hdc, x, y);

        ReleaseDC(null, hdc);
    }
}

