// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.timer;

private import dfl.event;
private import dfl.base;
private import dfl.application;

private import core.sys.windows.windows;


///
class Timer // docmain
{
	//EventHandler tick;
	Event!(Timer, EventArgs) tick; ///
	
	
	///
	@property void enabled(bool on) // setter
	{
		if(on)
			start();
		else
			stop();
	}
	
	/// ditto
	@property bool enabled() // getter
	{
		return timerId != 0;
	}
	
	
	///
	final @property void interval(uint timeout) // setter
	{
		if(!timeout)
			throw new DflException("Invalid timer interval");
		
		if(this._timeout != timeout)
		{
			this._timeout = timeout;
			
			if(timerId)
			{
				// I don't know if this is the correct behavior.
				// Reset the timer for the new timeout...
				stop();
				start();
			}
		}
	}
	
	/// ditto
	final @property size_t interval() // getter
	{
		return _timeout;
	}
	
	
	///
	final void start()
	{
		if(timerId)
			return;
		
		assert(_timeout > 0);
		
		timerId = SetTimer(null, 0, _timeout, &timerProc);
		if(!timerId)
			throw new DflException("Unable to start timer");
		allTimers[timerId] = this;
	}
	
	/// ditto
	final void stop()
	{
		if(timerId)
		{
			//delete allTimers[timerId];
			allTimers.remove(timerId);
			KillTimer(null, timerId);
			timerId = 0;
		}
	}
	
	
	///
	this()
	{
	}
	
	/// ditto
	this(void delegate(Timer) dg)
	{
		this();
		if(dg)
		{
			this._dg = dg;
			tick.addHandler(&_dgcall);
		}
	}
	
	/// ditto
	this(void delegate(Object, EventArgs) dg)
	{
		assert(dg !is null);
		
		this();
		tick.addHandler(dg);
	}
	
	/// ditto
	this(void delegate(Timer, EventArgs) dg)
	{
		assert(dg !is null);
		
		this();
		tick.addHandler(dg);
	}
	
	
	~this()
	{
		dispose();
	}
	
	
	protected:
	
	void dispose()
	{
		stop();
	}
	
	
	///
	void onTick(EventArgs ea)
	{
		tick(this, ea);
	}
	
	
	private:
	uint _timeout = 100;
	ulong timerId = 0;
	void delegate(Timer) _dg;
	
	
	void _dgcall(Object sender, EventArgs ea)
	{
		assert(_dg !is null);
		_dg(this);
	}
}


private:

Timer[size_t] allTimers;


extern(Windows) void timerProc(HWND hwnd, UINT uMsg, size_t idEvent, DWORD dwTime) nothrow
{
	try
	{
		if(idEvent in allTimers)
		{
			allTimers[idEvent].onTick(EventArgs.empty);
		}
		else
		{
			debug(APP_PRINT)
				cprintf("Unknown timer 0x%X.\n", idEvent);
		}
	}
	catch(Throwable e)
	{
		Application.onThreadException(e);
	}
}

