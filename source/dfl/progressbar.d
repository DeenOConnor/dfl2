// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.progressbar;

private import dfl.base;
private import dfl.control;
private import dfl.drawing;
private import dfl.application;
private import dfl.event;

private import core.sys.windows.commctrl;
private import core.sys.windows.windows;

// Application._initProgressbar();
private extern(Windows) void _initProgressbar();


///
class ProgressBar: ControlSuperClass // docmain
{
    this()
    {
        _initProgressbar();

        wexstyle |= WS_EX_CLIENTEDGE;
        wclassStyle = progressbarClassStyle;
    }


    ///
    final @property void maximum(int max) // setter
    {
        if(max <= 0 /+ || max < _min +/)
        {
            //bad_max:
            //throw new DflException("Unable to set progress bar maximum value");
            if(max)
                return;
        }

        if(created)
        {
            prevwproc(PBM_SETRANGE, 0, MAKELPARAM(_min, max));
        }

        _max = max;

        if(_val > max)
            _val = max; // ?
    }

    /// ditto
    final @property int maximum() // getter
    {
        return _max;
    }


    ///
    final @property void minimum(int min) // setter
    {
        if(min < 0 /+ || min > _max +/)
        {
            //bad_min:
            //throw new DflException("Unable to set progress bar minimum value");
            return;
        }

        if(created)
        {
            prevwproc(PBM_SETRANGE, 0, MAKELPARAM(min, _max));
        }

        _min = min;

        if(_val < min)
            _val = min; // ?
    }

    /// ditto
    final @property int minimum() // getter
    {
        return _min;
    }


    ///
    final @property void step(int stepby) // setter
    {
        if(stepby <= 0 /+ || stepby > _max +/)
        {
            //bad_max:
            //throw new DflException("Unable to set progress bar step value");
            if(stepby)
                return;
        }

        if(created)
        {
            prevwproc(PBM_SETSTEP, stepby, 0);
        }

        _step = stepby;
    }

    /// ditto
    final @property int step() // getter
    {
        return _step;
    }


    ///
    final @property void value(int setval) // setter
    {
        if(setval < _min || setval > _max)
        {
            //throw new DflException("Progress bar value out of minimum/maximum range");
            //return;
            if(setval > _max)
                setval = _max;
            else
                setval = _min;
        }

        if(created)
        {
            prevwproc(PBM_SETPOS, setval, 0);
        }

        _val = setval;
    }

    /// ditto
    final @property int value() // getter
    {
        return _val;
    }


    ///
    final void increment(int incby)
    {
        int newpos = _val + incby;
        if(newpos < _min)
            newpos = _min;
        if(newpos > _max)
            newpos = _max;

        if(created)
        {
            prevwproc(PBM_SETPOS, newpos, 0);
        }

        _val = newpos;
    }


    ///
    final void performStep()
    {
        increment(_step);
    }


    protected override void onHandleCreated(EventArgs ea)
    {
        super.onHandleCreated(ea);

        if(_min != MIN_INIT || _max != MAX_INIT)
        {
            prevwproc(PBM_SETRANGE, 0, MAKELPARAM(_min, _max));
        }

        if(_step != STEP_INIT)
        {
            prevwproc(PBM_SETSTEP, _step, 0);
        }

        if(_val != VAL_INIT)
        {
            prevwproc(PBM_SETPOS, _val, 0);
        }
    }


    protected override @property Size defaultSize() // getter
    {
        return Size(100, 23);
    }


    static @property Color defaultForeColor() // getter
    {
        return SystemColors.highlight;
    }


    protected override void createParams(ref CreateParams cp)
    {
        super.createParams(cp);

        cp.className = PROGRESSBAR_CLASSNAME;
    }


    protected override void prevWndProc(ref Message msg)
    {
        msg.result = CallWindowProcW(progressbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
    }


    final @property ProgressBar.STYLES style() {
        return this.currentStyle;
    }

    final @property void style(ProgressBar.STYLES newStyle) {
        this.currentStyle = newStyle;

        auto windowStyle = GetWindowLongPtrW(handle, GWL_STYLE);
        final switch (newStyle)
        {
            case STYLES.BLOCKS:
                SetWindowLongPtrW(handle, GWL_STYLE, windowStyle & ~PBS_SMOOTH & ~PBS_MARQUEE);
                prevwproc(PBM_SETPOS, _val, 0);
                recreateHandle();
                break;
            case STYLES.SMOOTH:
                SetWindowLongPtrW(handle, GWL_STYLE, windowStyle | PBS_SMOOTH & ~PBS_MARQUEE);
                prevwproc(PBM_SETPOS, _val, 0);
                recreateHandle();
                break;
            case STYLES.MARQUEE:
                this.state(STATE.NORMAL); // If not NORMAL then there's no animation
                SetWindowLongPtr@(handle, GWL_STYLE, windowStyle | PBS_MARQUEE);
        }
        bool isMarquee = newStyle == STYLES.MARQUEE;
        prevwproc(PBM_SETMARQUEE, isMarquee, this.speed * (isMarquee ? 1 : 0));
    }


    final @property int animationSpeed() {
        return this.speed;
    }

    final @property void animationSpeed(int newSpeed) {
        this.speed = newSpeed;
        if (this.currentStyle == STYLES.MARQUEE) {
            prevwproc(PBM_SETMARQUEE, true, this.speed);
        }
    }


    final @property ProgressBar.STATE state() {
        return this.currentState;
    }

    final @property void state(ProgressBar.STATE newState) {
        this.currentState = newState;
        prevwproc(WM_USER+16, this.state, 0); // PBM_SETSTATE message
    }


    static enum STYLES {
        BLOCKS = 0,
        SMOOTH = PBS_SMOOTH,
        MARQUEE = PBS_MARQUEE
    }


    static enum  STATE : int {
        NORMAL = 1, // PBST_NORMAL
        ERROR = 2, // PBST_ERROR
        PAUSED = 3 // PBST_PAUSED
    }

    private:

    enum MIN_INIT = 0;
    enum MAX_INIT = 100;
    enum STEP_INIT = 10;
    enum VAL_INIT = 0;
    ProgressBar.STYLES currentStyle = STYLES.BLOCKS;
    int speed = 0;
    ProgressBar.STATE currentState = STATE.NORMAL;

    int _min = MIN_INIT, _max = MAX_INIT, _step = STEP_INIT, _val = VAL_INIT;


    package final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
    {
        return CallWindowProcW(progressbarPrevWndProc, hwnd, msg, wparam, lparam);
    }
}

