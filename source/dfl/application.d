// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

///
module dfl.application;

private import dfl.base;
private import dfl.form;
private import dfl.event;
private import dfl.control;
private import dfl.drawing;
private import dfl.label;
private import dfl.button;
private import dfl.textbox;
private import dfl.environment;
private import dfl.resources;
private import dfl.menu;

private import core.sys.windows.commctrl;
private import core.sys.windows.ole2;
private import core.sys.windows.winbase;
private import core.sys.windows.windef;
private import core.sys.windows.windows;

private import core.stdc.stdlib : abort;
private import core.memory;

private import std.string;
private import std.conv;
private import std.file : thisExePath;
private import std.path : dirName;
private import std.stdio : writef, writefln, writeln;



debug(APP_PRINT)
{
    pragma(msg, "DFL: debug app print");

    version(DFL_LIB)
        static assert(0);
}


///
class ApplicationContext // docmain
{
    ///
    this()
    {
    }


    ///
    // If onMainFormClose isn't overridden, the message
    // loop terminates when the main form is destroyed.
    this(Form mainForm)
    {
        mform = mainForm;
        mainForm.closed.addHandler(&onMainFormClosed);
    }


    ///
    final @property void mainForm(Form mainForm) // setter
    {
        if(mform)
            mform.closed.addHandler(&onMainFormClosed);

        mform = mainForm;

        if(mainForm)
            mainForm.closed.addHandler(&onMainFormClosed);
    }

    /// ditto
    final @property Form mainForm() nothrow // getter
    {
        return mform;
    }


    ///
    Event!(Object, EventArgs) threadExit;


    ///
    final void exitThread()
    {
        exitThreadCore();
    }


    protected:

    ///
    void exitThreadCore()
    {
        threadExit(this, EventArgs.empty);
    }


    ///
    void onMainFormClosed(Object sender, EventArgs args)
    {
        exitThreadCore();
    }


    private:
    Form mform; // The context form.
}


private extern(Windows) nothrow
{
    alias UINT function(LPCWSTR lpPathName, LPCWSTR lpPrefixString, UINT uUnique,
        LPWSTR lpTempFileName) GetTempFileNameWProc;
    alias DWORD function(DWORD nBufferLength, LPWSTR lpBuffer) GetTempPathWProc;
    alias HANDLE function(PACTCTXW pActCtx) CreateActCtxWProc;
    alias BOOL function(HANDLE hActCtx, ULONG_PTR* lpCookie) ActivateActCtxProc;
}


version(NO_WINDOWS_HUNG_WORKAROUND)
{
}
else
{
    version = WINDOWS_HUNG_WORKAROUND;
}


// Compatibility with previous DFL versions.
// Set version=DFL_NO_COMPAT to disable.
enum DflCompat
{
    NONE = 0,

    // Adding to menus is the old way.
    MENU_092 = 0x1,

    // Controls don't recreate automatically when necessary.
    CONTROL_RECREATE_095 = 0x2,

    // Nothing.
    CONTROL_KEYEVENT_096 = 0x4,

    // When a Form is in showDialog, changing the dialogResult from NONE doesn't close the form.
    FORM_DIALOGRESULT_096 = 0x8,

    // Call onLoad/load and focus a control at old time.
    FORM_LOAD_096 = 0x10,

    // Parent controls now need to be container-controls; this removes that limit.
    CONTROL_PARENT_096 = 0x20,
}


///
final class Application // docmain
{
    private this() {}


    static:

    ///
    // Enables visual styles through writing and applying a manifest file
    // Left for compatibility with Entice Designer
    // Styles should be already enabled with a linker directive
    void enableVisualStyles()
    {
        enum MANIFEST = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
                <description>DFL manifest</description>
                <dependency>
                    <dependentAssembly>
                        <assemblyIdentity
                            type="win32"
                            name="Microsoft.Windows.Common-Controls"
                            version="6.0.0.0"
                            processorArchitecture="*"
                            publicKeyToken="6595b64144ccf1df"
                            language="*"
                        />
                    </dependentAssembly>
                </dependency>
            </assembly>`;
        DWORD pathlen;
        wchar[MAX_PATH] pathbuf = void;
        pathlen = GetTempPathW(pathbuf.length, pathbuf.ptr);
        if(pathlen != 0)
        {
            DWORD manifestlen;
            wchar[MAX_PATH] manifestbuf = void;
            manifestlen = GetTempFileNameW(pathbuf.ptr, "dmf", 0, manifestbuf.ptr);
            if(manifestlen != 0)
            {
                HANDLE hf;
                hf = CreateFileW(manifestbuf.ptr, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, HANDLE.init);
                if(hf != INVALID_HANDLE_VALUE && hf !is null)
                {
                    DWORD written;
                    auto wfStatus = WriteFile(hf, MANIFEST.ptr, MANIFEST.length, &written, null);
                    CloseHandle(hf);
                    if(wfStatus != 0)
                    {
                        ACTCTXW ac;
                        HANDLE hac;

                        ac.cbSize = ACTCTXW.sizeof;
                        ac.dwFlags = 0;
                        ac.lpSource = manifestbuf.ptr;

                        hac = CreateActCtxW(&ac);
                        if(hac != INVALID_HANDLE_VALUE)
                        {
                            ULONG_PTR ul;
                            ActivateActCtx(hac, &ul);

                            INITCOMMONCONTROLSEX icce;
                            icce.dwSize = INITCOMMONCONTROLSEX.sizeof;
                            icce.dwICC = ICC_STANDARD_CLASSES;
                            InitCommonControlsEx(&icce); // import core.sys.windows.commctrl

                            // Ensure the actctx is actually associated with the message queue...
                            PostMessageA(null, wmDfl, 0, 0);
                            {
                                MSG msg;
                                PeekMessageA(&msg, null, wmDfl, wmDfl, PM_REMOVE);
                            }
                        }
                        else
                        {
                            debug(APP_PRINT)
                            writeln("CreateActCtxW failed.");
                        }
                    }
                    DeleteFileW(manifestbuf.ptr);
                }
            }
        }
    }


    /*
        It seems that DFL uses its own common controls derivatives, which makes OpenThemeData consistently return null
        This means that a lot in dfl.application and dfl.drawing will have to be rewritten almost completely
        So for now there's no dark theme (or even properly following system theme really)
    */

    private {
        alias extern(Windows) int function(void*, char*, void*) f_SetWindowTheme;
        // Even more experimental, might not work with Windows versions less than Win 11 build 22000
        alias extern(Windows) int function(void*, DWORD, LPCVOID, DWORD) f_DwmSetWindowAttribute;
        alias extern(Windows) int function() f_DwmFlush;
        alias int function() nothrow f_IsAppThemed;
        alias void* function(void*, const(wchar*)) f_OpenThemeData;
        alias int function(void*, int, int, int, uint*) f_GetThemeColor;
        alias int function(void* hTheme) f_CloseThemeData;

        static HMODULE hUxTheme;

        static bool uxThemeInitialized = false;

        static bool initUxFunctions() {
            if (!uxThemeInitialized && !initUxTheme()) {
                return false;
            }

            SetWindowTheme = cast(f_SetWindowTheme) GetProcAddress(hUxTheme, toStringz("SetWindowTheme"));
            IsAppThemed = cast(f_IsAppThemed) GetProcAddress(hUxTheme, "IsAppThemed");
            OpenThemeData = cast(f_OpenThemeData) GetProcAddress(hUxTheme, "OpenThemeData");
            GetThemeColor = cast(f_GetThemeColor) GetProcAddress(hUxTheme, "GetThemeColor");
            CloseThemeData = cast(f_CloseThemeData) GetProcAddress(hUxTheme, "CloseThemeData");

            if (hDwmapi !is null) {
                DwmSetWindowAttribute = cast(f_DwmSetWindowAttribute) GetProcAddress(hDwmapi, toStringz("DwmSetWindowAttribute"));
                DwmFlush = cast(f_DwmFlush) GetProcAddress(hDwmapi, toStringz("DwmFlush"));
            }

            if (SetWindowTheme is null) {
                debug {
                    writeln("Could not retrieve all needed functions");
                }
                return false;
            }

            return true;
        }
    }

    static f_SetWindowTheme SetWindowTheme;
    static f_IsAppThemed IsAppThemed;
    static f_OpenThemeData OpenThemeData;
    static f_GetThemeColor GetThemeColor;
    static f_CloseThemeData CloseThemeData;
    static f_DwmSetWindowAttribute DwmSetWindowAttribute;
    static f_DwmFlush DwmFlush;
    static HMODULE hDwmapi;

    static bool initUxTheme() {
        if (uxThemeInitialized) {
            return true;
        }

        hUxTheme = GetModuleHandleA(toStringz("uxtheme.dll"));
        hDwmapi = LoadLibraryA("dwmapi.dll");

        if (hUxTheme is null) {
            hUxTheme = LoadLibraryA("uxtheme.dll");
        }

        if (hUxTheme is null) {
            debug {
                writeln("Could not load uxtheme.dll, sticking to default settings!");
            }
        }

        uxThemeInitialized = hUxTheme !is null;
        return uxThemeInitialized;
    }

    /// Experimental feature!
    void setDarkModeForWindow(Form form) {
        if (!uxThemeInitialized) {
            bool initRes = initUxTheme();
            initRes &= initUxFunctions();

            if (!initRes) {
                debug {
                    writeln("Can't use uxtheme features because it could not be initialized!");
                }
            }
        }

        if (DwmSetWindowAttribute !is null) {
            int yes_please = 1;
            DwmSetWindowAttribute(form.handle(), 20, &yes_please, yes_please.sizeof);
        }
    }


    /// Path of the executable including its file name.
    @property string executablePath() // getter
    {
        return thisExePath();
    }


    /// Directory containing the executable.
    @property string startupPath() // getter
    {
        return dirName(thisExePath());
    }


    // Used internally.
    string getSpecialPath(string name) // package
    {
        HKEY hk;
        if(ERROR_SUCCESS != RegOpenKeyA(HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders".ptr, &hk))
        {
            throw new DflException("Unable to obtain " ~ name ~ " directory information");
        }
        scope(exit)
            RegCloseKey(hk);

        uint type, sz;
        RegQueryValueExA(hk, name.ptr, null, &type, null, &sz);
        if(!sz || (REG_SZ != type && REG_EXPAND_SZ != type))
            throw new DflException("Unable to obtain " ~ name ~ " directory information");

        char[] s = new char[sz];
        if(ERROR_SUCCESS != RegQueryValueExA(hk, name.ptr, null, null, cast(LPBYTE)s.ptr, &sz))
            throw new DflException("Unable to obtain " ~ name ~ " directory information");

        return to!string(fromStringz(s));
    }


    /// Application data base directory path, usually `C:\Documents and Settings\<user>\Application Data`; this directory might not exist yet.
    @property string userAppDataBasePath() // getter
    {
        return getSpecialPath("AppData");
    }


    ///
    @property bool messageLoop() nothrow // getter
    {
        return (threadFlags & TF.RUNNING) != 0;
    }


    ///
    void addMessageFilter(IMessageFilter mf)
    {
        IMessageFilter[] fs = filters;
        fs ~= mf;
        filters = fs;
    }

    /// ditto
    void removeMessageFilter(IMessageFilter mf)
    {
        uint i;
        for(i = 0; i != filters.length; i++)
        {
            if(mf is filters[i])
            {
                if(!i)
                    filters = filters[1 .. filters.length];
                else if(i == filters.length - 1)
                    filters = filters[0 .. i];
                else
                    filters = filters[0 .. i] ~ filters[i + 1 .. filters.length];
                break;
            }
        }
    }


    package bool _doEvents(bool* keep)
    {
        if(threadFlags & (TF.STOP_RUNNING | TF.QUIT))
            return false;

        try
        {
            Message msg;

            while(PeekMessageA(&msg._winMsg, HWND.init, 0, 0, PM_REMOVE))
            {
                gotMessage(msg);

                if(msg.msg == WM_QUIT)
                {
                    threadFlags = threadFlags | TF.QUIT;
                    return false;
                }
                if(threadFlags & TF.STOP_RUNNING)
                {
                    return false;
                }
                if(!*keep)
                {
                    break;
                }
            }

            // Execution continues after this so it's not idle.
        }
        catch(Throwable e)
        {
            onThreadException(e);
        }

        return (threadFlags & TF.QUIT) == 0;
    }


    /// Process all messages in the message queue. Returns false if the application should exit.
    bool doEvents()
    {
        bool keep = true;
        return _doEvents(&keep);
    }

    /// ditto
    bool doEvents(uint msDelay)
    {
        if(msDelay <= 3)
            return doEvents();
        struct TMR { public import dfl.timer; }
        scope tmr = new TMR.Timer();
        bool keep = true;
        tmr.interval = msDelay;
        auto callback = (TMR.Timer sender, EventArgs ea) { sender.stop(); keep = false; };
        tmr.tick.addHandler(callback);
        tmr.start();
        while(keep)
        {
            Application.waitForEvent();
            if(!_doEvents(&keep))
                return false;
        }
        return true;
    }


    /// Run the application.
    void run()
    {
        run(new ApplicationContext);
    }

    /// ditto
    void run(void delegate() whileIdle)
    {
        run(new ApplicationContext, whileIdle);
    }

    /// ditto
    void run(ApplicationContext appcon)
    {
        void whileIdle()
        {
            waitForEvent();
        }


        run(appcon, &whileIdle);
    }

    /// ditto
    // -whileIdle- is called repeatedly while there are no messages in the queue.
    // Application.idle events are suppressed; however, the -whileIdle- handler
    // may manually fire the Application.idle event.
    void run(ApplicationContext appcon, void delegate() whileIdle)
    {
        if(threadFlags & TF.RUNNING)
        {
            assert(0, "Cannot have more than one message loop per thread");
        }

        if(threadFlags & TF.QUIT)
        {
            assert(0, "The application is shutting down");
        }

        version(CUSTOM_MSG_HOOK)
        {
            HHOOK _msghook = SetWindowsHookExA(WH_CALLWNDPROCRET, &globalMsgHook, null, GetCurrentThreadId());
            if(!_msghook)
                throw new DflException("Unable to get window messages");
            msghook = _msghook;
        }


        void threadJustExited(Object sender, EventArgs ea)
        {
            exitThread();
        }


        ctx = appcon;
        ctx.threadExit.addHandler(&threadJustExited);
        try
        {
            threadFlags = threadFlags | TF.RUNNING;

            if(ctx.mainForm)
            {
                ctx.mainForm.show();
            }

            for(;;)
            {
                try
                {
                    still_running:
                    while(!(threadFlags & (TF.QUIT | TF.STOP_RUNNING)))
                    {
                        Message msg;

                        while(PeekMessageA(&msg._winMsg, HWND.init, 0, 0, PM_REMOVE))
                        {
                            gotMessage(msg);

                            if(msg.msg == WM_QUIT)
                            {
                                threadFlags = threadFlags | TF.QUIT;
                                break still_running;
                            }

                            if(threadFlags & (TF.QUIT | TF.STOP_RUNNING))
                                break still_running;
                        }

                        whileIdle();
                    }

                    // Stopped running.
                    threadExit(typeid(Application), EventArgs.empty);
                    threadFlags = threadFlags & ~(TF.RUNNING | TF.STOP_RUNNING);
                    return;
                }
                catch(Throwable e)
                {
                    onThreadException(e);
                }
            }
        }
        finally
        {
            threadFlags = threadFlags & ~(TF.RUNNING | TF.STOP_RUNNING);

            ApplicationContext tctx;
            tctx = ctx;
            ctx = null;

            version(CUSTOM_MSG_HOOK)
                UnhookWindowsHookEx(msghook);

            tctx.threadExit.removeHandler(&threadJustExited);
        }
    }

    /// ditto
    // Makes the form -mainForm- visible.
    void run(Form mainForm, void delegate() whileIdle)
    {
        ApplicationContext appcon = new ApplicationContext(mainForm);
        run(appcon, whileIdle);
    }

    /// ditto
    void run(Form mainForm)
    {
        ApplicationContext appcon = new ApplicationContext(mainForm);
        run(appcon);
    }


    ///
    void exit()
    {
        PostQuitMessage(0);
    }


    /// Exit the thread's message loop and return from run.
    // Actually only stops the current run() loop.
    void exitThread()
    {
        threadFlags = threadFlags | TF.STOP_RUNNING;
    }


    // Will be null if not in a successful Application.run.
    package @property ApplicationContext context() nothrow // getter
    {
        return ctx;
    }


    ///
    HINSTANCE getInstance()
    {
        if(!hinst)
            _initInstance();
        return hinst;
    }

    /// ditto
    void setInstance(HINSTANCE inst)
    {
        if(hinst)
        {
            if(inst != hinst)
                throw new DflException("Instance is already set");
            return;
        }

        if(inst)
        {
            _initInstance(inst);
        }
        else
        {
            _initInstance(); // ?
        }
    }


    // ApartmentState oleRequired() ...


    private static class ErrForm: Form
    {
        protected override void onLoad(EventArgs ea)
        {
            okBtn.focus();
        }


        protected override void onClosing(CancelEventArgs cea)
        {
            cea.cancel = !errdone;
        }


        enum PADDING = 10;


        void onOkClick(Object sender, EventArgs ea)
        {
            errdone = true;
            ctnu = true;
            dispose();
        }


        void onCancelClick(Object sender, EventArgs ea)
        {
            errdone = true;
            ctnu = false;
            dispose();
        }

        this(string errmsg) {
            this(to!wstring(errmsg));
        }

        this(wstring errmsg)
        {
            text = "Error";
            clientSize = Size(340, 150);
            startPosition = FormStartPosition.CENTER_SCREEN;
            formBorderStyle = FormBorderStyle.FIXED_DIALOG;
            minimizeBox = false;
            maximizeBox = false;
            controlBox = false;

            Label label;
            with(label = new Label)
            {
                bounds = Rect(PADDING, PADDING, this.clientSize.width - PADDING * 2, 40);
                label.text = "An application exception has occured. Click Continue to allow "w ~
                    "the application to ignore this error and attempt to continue."w;
                parent = this;
            }

            with(errBox = new TextBox)
            {
                text = errmsg;
                bounds = Rect(PADDING, 40 + PADDING, this.clientSize.width - PADDING * 2, 50);
                errBox.backColor = this.backColor;
                readOnly = true;
                multiline = true;
                parent = this;
            }

            with(okBtn = new Button)
            {
                width = 100;
                location = Point(this.clientSize.width - width - PADDING - width - PADDING,
                    this.clientSize.height - height - PADDING);
                text = "&Continue"w;
                parent = this;
                click.addHandler(&onOkClick);
            }
            acceptButton = okBtn;

            with(new Button)
            {
                width = 100;
                location = Point(this.clientSize.width - width - PADDING,
                    this.clientSize.height - height - PADDING);
                text = "&Quit"w;
                parent = this;
                click.addHandler(&onCancelClick);
            }

            autoScale = true;
        }


        bool doContinue()
        {
            assert(!isHandleCreated);

            show();

            Message msg;
            for(;;)
            {
                WaitMessage();
                if(PeekMessageA(&msg._winMsg, handle, 0, 0, PM_REMOVE | PM_NOYIELD))
                {
                    gotMessage(msg);
                }

                if(!isHandleCreated)
                    break;
            }

            return ctnu;
        }


        override string toString()
        {
            return to!string(errBox.text);
        }


        private:
        bool errdone = false;
        bool ctnu = false;
        Button okBtn;
        TextBox errBox;
    }


    ///
    bool showDefaultExceptionDialog(Object e)
    {
        {
            if((new ErrForm(e.toString())).doContinue())
            {
                return true;
            }
        }

        return false;
    }


    ///
    void onThreadException(Throwable e) nothrow
    {
        try
        {
            static bool except = false;

            version(WINDOWS_HUNG_WORKAROUND)
            {
                version(WINDOWS_HUNG_WORKAROUND_NO_IGNORE)
                {
                }
                else
                {
                    if(cast(WindowsHungDflException)e)
                        return;
                }
            }

            if(except)
            {
                writef("Error: %s\n", e.toString());

                abort();
            }

            except = true;
            if(threadException.hasHandlers)
            {
                threadException(typeid(Application), new ThreadExceptionEventArgs(e));
                except = false;
                return;
            }
            else
            {
                // No thread exception handlers, display a dialog.
                if(showDefaultExceptionDialog(e))
                {
                    except = false;
                    return;
                }
            }
            writefln("Error: %*s", e.toString());
            Environment.exit(1);
        }
        catch (Throwable e)
        {
        }
    }


    ///
    Event!(Object, EventArgs) idle; // Finished processing and is now idle.
    ///
    Event!(Object, ThreadExceptionEventArgs) threadException;
    ///
    Event!(Object, EventArgs) threadExit;


    ///
    void addHotkey(Keys k,void delegate(Object sender, KeyEventArgs ea) dg)
    {
        if (auto pkid = k in hotkeyId)
        {
            immutable kid = *pkid;
            hotkeyHandler[kid].addHandler(dg);
        }
        else
        {
            int kid = 0;
            foreach (aak, aav; hotkeyHandler)
            {
                if (!aav.hasHandlers)
                {
                    kid = aak;
                    break;
                }
                ++kid;
            }
            immutable mod = (k&Keys.MODIFIERS)>>16,
                      keycode = k&Keys.KEY_CODE;
            if (RegisterHotKey(null, kid, mod, keycode))
            {
                hotkeyId[k] = kid;
                if (auto h = kid in hotkeyHandler)
                {
                    (*h).addHandler(dg);
                }
                else
                {
                    typeof(hotkeyHandler[kid]) e;
                    e.addHandler(dg);
                    hotkeyHandler[kid] = e;
                }
            }
            else
            {
                throw new DflException("Hotkey cannot resistered.");
            }
        }
    }


    ///
    void removeHotkey(Keys k, void delegate(Object sender, KeyEventArgs ea) dg)
    {
        if (auto pkid = k in hotkeyId)
        {
            immutable kid = *pkid;
            hotkeyHandler[kid].removeHandler(dg);
            if (!hotkeyHandler[kid].hasHandlers)
            {
                if (UnregisterHotKey(null, kid) == 0)
                {
                    throw new DflException("Hotkey cannot unresistered.");
                }
                hotkeyHandler.remove(kid);
                hotkeyId.remove(k);
            }
        }
    }


    ///
    void removeHotkey(Keys k)
    {
        if (auto pkid = k in hotkeyId)
        {
            immutable kid = *pkid;
            foreach (hnd; hotkeyHandler[kid])
            {
                hotkeyHandler[kid].removeHandler(hnd);
            }
            assert(!hotkeyHandler[kid].hasHandlers);
            if (UnregisterHotKey(null, kid) == 0)
            {
                throw new DflException("Hotkey cannot unresistered.");
            }
            hotkeyHandler.remove(kid);
            hotkeyId.remove(k);
        }
    }


    ///
    struct HotkeyRegister
    {
    static:
        ///
        alias void delegate(Object c, KeyEventArgs e) Handler;


        ///
        void addHandler(Keys k, Handler dg)
        {
            addHotkey(k, dg);
        }


        ///
        struct IndexedCatAssigner
        {
            Keys k;


            ///
            void opCatAssign(Handler dg)
            {
                addHandler(k, dg);
            }
        }


        ///
        IndexedCatAssigner opIndex(Keys k)
        {
            return IndexedCatAssigner(k);
        }


        ///
        void removeHandler(Keys k, Handler dg)
        {
            removeHotkey(k, dg);
        }


        ///
        void removeHandler(Keys k)
        {
            removeHotkey(k);
        }
    }


    /// helper
    HotkeyRegister hotkeys;


    static ~this()
    {
        foreach (key; hotkeyId.keys)
        {
            removeHotkey(key);
        }
        hotkeyId = null;
    }

    // Returns null if not found.
    package Control lookupHwnd(HWND hwnd) nothrow
    {
        auto pc = hwnd in controls;
        if(pc)
            return *pc;
        return null;
    }


    // Also makes a great zombie.
    package void removeHwnd(HWND hwnd)
    {
        //delete controls[hwnd];
        controls.remove(hwnd);
    }


    version(DFL_NO_ZOMBIE_FORM)
    {
    }
    else
    {
        package enum ZOMBIE_PROP = "DFL_Zombie";

        // Doesn't do any good since the child controls still reference this control.
        package void zombieHwnd(Control c)
        in
        {
            assert(c !is null);
            assert(c.isHandleCreated);
            assert(lookupHwnd(c.handle));
        }
        do
        {
            SetPropA(c.handle, ZOMBIE_PROP.ptr, cast(HANDLE)cast(void*)c);
            removeHwnd(c.handle);
        }


        package void unzombieHwnd(Control c)
        in
        {
            assert(c !is null);
            assert(c.isHandleCreated);
            assert(!lookupHwnd(c.handle));
        }
        do
        {
            RemovePropA(c.handle, ZOMBIE_PROP.ptr);
            controls[c.handle] = c;
        }


        // Doesn't need to be a zombie.
        package void zombieKill(Control c)
        in
        {
            assert(c !is null);
        }
        do
        {
            if(c.isHandleCreated)
            {
                RemovePropA(c.handle, ZOMBIE_PROP.ptr);
            }
        }
    }


    version(DFL_NO_MENUS)
    {
    }
    else
    {
        // Returns its new unique menu ID.
        package int addMenuItem(MenuItem menu)
        {
            if(nmenus == END_MENU_ID - FIRST_MENU_ID)
                throw new DflException("Out of menus");

            typeof(menus) tempmenus;

            // TODO: sort menu IDs in 'menus' so that looking for free ID is much faster.

            prevMenuID++;
            if(prevMenuID >= END_MENU_ID || prevMenuID <= FIRST_MENU_ID)
            {
                prevMenuID = FIRST_MENU_ID;
                previdloop:
                for(;;)
                {
                    for(size_t iw; iw != nmenus; iw++)
                    {
                        MenuItem mi;
                        mi = cast(MenuItem)menus[iw];
                        if(mi)
                        {
                            if(prevMenuID == mi._menuID)
                            {
                                prevMenuID++;
                                continue previdloop;
                            }
                        }
                    }
                    break;
                }
            }
            tempmenus = cast(Menu*)GC.realloc(menus, Menu.sizeof * (nmenus + 1));
            if(!tempmenus)
            {
                throw new DflException("Out of memory");
            }
            menus = tempmenus;

            menus[nmenus++] = menu;

            return prevMenuID;
        }


        package void addContextMenu(ContextMenu menu)
        {
            if(nmenus == END_MENU_ID - FIRST_MENU_ID)
                throw new DflException("Out of menus");

            typeof(menus) tempmenus;
            int idx;

            idx = nmenus;
            nmenus++;
            tempmenus = cast(Menu*)GC.realloc(menus, Menu.sizeof * nmenus);
            if(!tempmenus)
            {
                nmenus--;
                throw new DflException("Out of memory");
            }
            menus = tempmenus;

            menus[idx] = menu;
        }


        package void removeMenu(Menu menu)
        {
            uint idx;

            for(idx = 0; idx != nmenus; idx++)
            {
                if(menus[idx] is menu)
                {
                    goto found;
                }
            }
            return;

            found:
            if(nmenus == 1)
            {
                GC.free(menus);
                menus = null;
                nmenus--;
            }
            else
            {
                if(idx != nmenus - 1)
                    menus[idx] = menus[nmenus - 1]; // Move last one in its place

                nmenus--;
                menus = cast(Menu*)GC.realloc(menus, Menu.sizeof * nmenus);
                assert(menus != null); // Memory shrink shouldn't be a problem.
            }
        }


        package MenuItem lookupMenuID(int menuID)
        {
            uint idx;
            MenuItem mi;

            for(idx = 0; idx != nmenus; idx++)
            {
                mi = cast(MenuItem)menus[idx];
                if(mi && mi._menuID == menuID)
                    return mi;
            }
            return null;
        }


        package Menu lookupMenu(HMENU hmenu)
        {
            uint idx;

            for(idx = 0; idx != nmenus; idx++)
            {
                if(menus[idx].handle == hmenu)
                    return menus[idx];
            }
            return null;
        }
    }


    package void creatingControl(Control ctrl) nothrow
    {
        TlsSetValue(tlsControl, cast(Control*)ctrl);
    }


    version(DFL_NO_RESOURCES)
    {
    }
    else
    {
        ///
        @property Resources resources() // getter
        {
            static Resources rc = null;

            if(!rc)
            {
                synchronized
                {
                    if(!rc)
                    {
                        rc = new Resources(getInstance());
                    }
                }
            }
            return rc;
        }
    }


    private UINT gctimer = 0;
    private DWORD gcinfo = 1;


    ///
    @property void autoCollect(bool byes) // setter
    {
        if(byes)
        {
            if(!autoCollect)
            {
                gcinfo = 1;
            }
        }
        else
        {
            if(autoCollect)
            {
                gcinfo = 0;
                KillTimer(HWND.init, gctimer);
                gctimer = 0;
            }
        }
    }

    /// ditto
    @property bool autoCollect() nothrow // getter
    {
        return gcinfo > 0;
    }


    package void _waitMsg()
    {
        if(threadFlags & (TF.STOP_RUNNING | TF.QUIT))
            return;

        idle(typeid(Application), EventArgs.empty);
        WaitMessage();
    }

    package deprecated alias _waitMsg waitMsg;


    ///
    // Because waiting for an event enters an idle state,
    // this function fires the -idle- event.
    void waitForEvent()
    {
        if(!autoCollect)
        {
            _waitMsg();
            return;
        }

        if(1 == gcinfo)
        {
            gcinfo = gcinfo.max;
            assert(!gctimer);
            gctimer = to!int(SetTimer(HWND.init, 0, 200, &_gcTimeout));
        }

        _waitMsg();

        if(GetTickCount() > gcinfo)
        {
            gcinfo = 1;
        }
    }


    version(DFL_NO_COMPAT)
        package enum _compat = DflCompat.NONE;
    else
        package DflCompat _compat = DflCompat.NONE;


    deprecated void setCompat(DflCompat dflcompat)
    {
        version(DFL_NO_COMPAT)
        {
            assert(0, "Compatibility disabled"); // version=DFL_NO_COMPAT
        }
        else
        {
            if(messageLoop)
            {
                assert(0, "setCompat"); // Called too late, must enable compatibility sooner.
            }

            _compat |= dflcompat;
        }
    }


    private static size_t _doref(void* p, int by)
    {
        assert(1 == by || -1 == by);

        size_t result;

        synchronized
        {
            auto pref = p in _refs;
            if(pref)
            {
                size_t count;
                count = *pref;

                assert(count || -1 != by);

                if(-1 == by)
                    count--;
                else
                    count++;

                if(!count)
                {
                    result = 0;
                    _refs.remove(p);
                }
                else
                {
                    result = count;
                    _refs[p] = count;
                }
            }
            else if(1 == by)
            {
                _refs[p] = 1;
                result = 1;
            }
        }

        return result;
    }


    package size_t refCountInc(void* p)
    {
        return _doref(p, 1);
    }


    // Returns the new ref count.
    package size_t refCountDec(void* p)
    {
        return _doref(p, -1);
    }


    package void ppin(void* p)
    {
        // It seems that at the moment of writing this there's no need for pinning
    }


    package void punpin(void* p)
    {
        // It seems that at the moment of writing this there's no need for unpinning
    }


    private:
    static:
    size_t[void*] _refs;
    IMessageFilter[] filters;
    DWORD tlsThreadFlags;
    DWORD tlsControl;
    DWORD tlsFilter; // IMessageFilter[]*.
    version(CUSTOM_MSG_HOOK)
        DWORD tlsHook; // HHOOK.
    Control[HWND] controls;
    HINSTANCE hinst;
    ApplicationContext ctx = null;
    int[Keys] hotkeyId;
    Event!(Object, KeyEventArgs)[int] hotkeyHandler;

    version(DFL_NO_MENUS)
    {
    }
    else
    {
        // Menus.
        enum short FIRST_MENU_ID = 200;
        enum short END_MENU_ID = 10000;

        // Controls.
        enum ushort FIRST_CTRL_ID = END_MENU_ID + 1;
        enum ushort LAST_CTRL_ID = 65500;


        ushort prevMenuID = FIRST_MENU_ID;
        uint nmenus = 0; // Number of -menus-.
        Menu* menus = null; // WARNING: malloc()'d memory!


        // Destroy all menu handles at program exit because Windows will not
        // unless it is assigned to a window.
        // Note that this is probably just a 16bit issue, but it still appeared in the 32bit docs.
        private void sdtorFreeAllMenus()
        {
            foreach(Menu m; menus[0 .. nmenus])
            {
                DestroyMenu(m.handle);
            }
            nmenus = 0;
            GC.free(menus);
            menus = null;
        }
    }


    private struct TlsFilterValue
    {
        IMessageFilter[] filters;
    }


    version(CUSTOM_MSG_HOOK)
    {
        @property void msghook(HHOOK hhook) // setter
        {
            TlsSetValue(tlsHook, cast(LPVOID)hhook);
        }


        @property HHOOK msghook() nothrow // getter
        {
            return cast(HHOOK)TlsGetValue(tlsHook);
        }
    }


    Control getCreatingControl() nothrow
    {
        return cast(Control)cast(Control*)TlsGetValue(tlsControl);
    }


    // Thread flags.
    enum TF: DWORD
    {
        RUNNING = 1, // Application.run is in affect.
        STOP_RUNNING = 2,
        QUIT = 4, // Received WM_QUIT.
    }


    @property TF threadFlags() nothrow // getter
    {
        return cast(TF)cast(DWORD)TlsGetValue(tlsThreadFlags);
    }


    @property void threadFlags(TF flags) // setter
    {
        if(!TlsSetValue(tlsThreadFlags, cast(LPVOID)cast(DWORD)flags))
            assert(0);
    }


    void gotMessage(ref Message msg)
    {
        void handleHotkey()
        {
            immutable kid = cast(int)msg.wParam,
                      mod = cast(uint) (msg.lParam&0x0000ffff),
                      keycode = cast(uint)((msg.lParam&0xffff0000)>>16);
            assert(kid < hotkeyHandler.length);
            hotkeyHandler[kid](
                typeid(Application),
                new KeyEventArgs(cast(Keys)((mod << 16) | keycode)));
        }
        // Don't bother with this extra stuff if there aren't any filters.
        if(filters.length)
        {
            try
            {
                // Keep a local reference so that handlers
                // may be added and removed during filtering.
                IMessageFilter[] local = filters;

                foreach(IMessageFilter mf; local)
                {
                    // Returning true prevents dispatching.
                    if(mf.preFilterMessage(msg))
                    {
                        Control ctrl;
                        ctrl = lookupHwnd(msg.hWnd);
                        if(ctrl)
                        {
                            ctrl.mustWndProc(msg);
                        }
                        else if (msg.msg == WM_HOTKEY)
                        {
                            handleHotkey();
                        }
                        return;
                    }
                }
            }
            catch(Throwable o)
            {
                Control ctrl;
                ctrl = lookupHwnd(msg.hWnd);
                if(ctrl)
                    ctrl.mustWndProc(msg);
                throw o;
            }
        }
        if (msg.msg == WM_HOTKEY)
        {
            handleHotkey();
        }
        TranslateMessage(&msg._winMsg);
        DispatchMessageA(&msg._winMsg);
    }
}


package:


extern(Windows) void _gcTimeout(HWND hwnd, UINT uMsg, size_t idEvent, DWORD dwTime) nothrow
{
    KillTimer(hwnd, Application.gctimer);
    Application.gctimer = 0;

    debug {
        writeln("Auto-collecting");
    }
    try {
        GC.collect();
    } catch (Exception ex) {
        // Do nothing
    }

    Application.gcinfo = GetTickCount() + 4000;
}


// Note: phobos-only.
debug(SHOW_MESSAGE_INFO)
{
    private import std.stdio, std.string;


    void showMessageInfo(ref Message m)
    {
        void writeWm(string wmName)
        {
            writef("Message %s=%d(0x%X)\n", wmName, m.msg, m.msg);
        }


        switch(m.msg)
        {
            case WM_NULL: writeWm("WM_NULL"); break;
            case WM_CREATE: writeWm("WM_CREATE"); break;
            case WM_DESTROY: writeWm("WM_DESTROY"); break;
            case WM_MOVE: writeWm("WM_MOVE"); break;
            case WM_SIZE: writeWm("WM_SIZE"); break;
            case WM_ACTIVATE: writeWm("WM_ACTIVATE"); break;
            case WM_SETFOCUS: writeWm("WM_SETFOCUS"); break;
            case WM_KILLFOCUS: writeWm("WM_KILLFOCUS"); break;
            case WM_ENABLE: writeWm("WM_ENABLE"); break;
            case WM_SETREDRAW: writeWm("WM_SETREDRAW"); break;
            case WM_SETTEXT: writeWm("WM_SETTEXT"); break;
            case WM_GETTEXT: writeWm("WM_GETTEXT"); break;
            case WM_GETTEXTLENGTH: writeWm("WM_GETTEXTLENGTH"); break;
            case WM_PAINT: writeWm("WM_PAINT"); break;
            case WM_CLOSE: writeWm("WM_CLOSE"); break;
            case WM_QUERYENDSESSION: writeWm("WM_QUERYENDSESSION"); break;
            case WM_QUIT: writeWm("WM_QUIT"); break;
            case WM_QUERYOPEN: writeWm("WM_QUERYOPEN"); break;
            case WM_ERASEBKGND: writeWm("WM_ERASEBKGND"); break;
            case WM_SYSCOLORCHANGE: writeWm("WM_SYSCOLORCHANGE"); break;
            case WM_ENDSESSION: writeWm("WM_ENDSESSION"); break;
            case WM_SHOWWINDOW: writeWm("WM_SHOWWINDOW"); break;
            //case WM_WININICHANGE: writeWm("WM_WININICHANGE"); break;
            case WM_SETTINGCHANGE: writeWm("WM_SETTINGCHANGE"); break;
            case WM_DEVMODECHANGE: writeWm("WM_DEVMODECHANGE"); break;
            case WM_ACTIVATEAPP: writeWm("WM_ACTIVATEAPP"); break;
            case WM_FONTCHANGE: writeWm("WM_FONTCHANGE"); break;
            case WM_TIMECHANGE: writeWm("WM_TIMECHANGE"); break;
            case WM_CANCELMODE: writeWm("WM_CANCELMODE"); break;
            case WM_SETCURSOR: writeWm("WM_SETCURSOR"); break;
            case WM_MOUSEACTIVATE: writeWm("WM_MOUSEACTIVATE"); break;
            case WM_CHILDACTIVATE: writeWm("WM_CHILDACTIVATE"); break;
            case WM_QUEUESYNC: writeWm("WM_QUEUESYNC"); break;
            case WM_GETMINMAXINFO: writeWm("WM_GETMINMAXINFO"); break;
            case WM_NOTIFY: writeWm("WM_NOTIFY"); break;
            case WM_INPUTLANGCHANGEREQUEST: writeWm("WM_INPUTLANGCHANGEREQUEST"); break;
            case WM_INPUTLANGCHANGE: writeWm("WM_INPUTLANGCHANGE"); break;
            case WM_TCARD: writeWm("WM_TCARD"); break;
            case WM_HELP: writeWm("WM_HELP"); break;
            case WM_USERCHANGED: writeWm("WM_USERCHANGED"); break;
            case WM_NOTIFYFORMAT: writeWm("WM_NOTIFYFORMAT"); break;
            case WM_CONTEXTMENU: writeWm("WM_CONTEXTMENU"); break;
            case WM_STYLECHANGING: writeWm("WM_STYLECHANGING"); break;
            case WM_STYLECHANGED: writeWm("WM_STYLECHANGED"); break;
            case WM_DISPLAYCHANGE: writeWm("WM_DISPLAYCHANGE"); break;
            case WM_GETICON: writeWm("WM_GETICON"); break;
            case WM_SETICON: writeWm("WM_SETICON"); break;
            case WM_NCCREATE: writeWm("WM_NCCREATE"); break;
            case WM_NCDESTROY: writeWm("WM_NCDESTROY"); break;
            case WM_NCCALCSIZE: writeWm("WM_NCCALCSIZE"); break;
            case WM_NCHITTEST: writeWm("WM_NCHITTEST"); break;
            case WM_NCPAINT: writeWm("WM_NCPAINT"); break;
            case WM_NCACTIVATE: writeWm("WM_NCACTIVATE"); break;
            case WM_GETDLGCODE: writeWm("WM_GETDLGCODE"); break;
            case WM_NCMOUSEMOVE: writeWm("WM_NCMOUSEMOVE"); break;
            case WM_NCLBUTTONDOWN: writeWm("WM_NCLBUTTONDOWN"); break;
            case WM_NCLBUTTONUP: writeWm("WM_NCLBUTTONUP"); break;
            case WM_NCLBUTTONDBLCLK: writeWm("WM_NCLBUTTONDBLCLK"); break;
            case WM_NCRBUTTONDOWN: writeWm("WM_NCRBUTTONDOWN"); break;
            case WM_NCRBUTTONUP: writeWm("WM_NCRBUTTONUP"); break;
            case WM_NCRBUTTONDBLCLK: writeWm("WM_NCRBUTTONDBLCLK"); break;
            case WM_NCMBUTTONDOWN: writeWm("WM_NCMBUTTONDOWN"); break;
            case WM_NCMBUTTONUP: writeWm("WM_NCMBUTTONUP"); break;
            case WM_NCMBUTTONDBLCLK: writeWm("WM_NCMBUTTONDBLCLK"); break;
            case WM_KEYDOWN: writeWm("WM_KEYDOWN"); break;
            case WM_KEYUP: writeWm("WM_KEYUP"); break;
            case WM_CHAR: writeWm("WM_CHAR"); break;
            case WM_DEADCHAR: writeWm("WM_DEADCHAR"); break;
            case WM_SYSKEYDOWN: writeWm("WM_SYSKEYDOWN"); break;
            case WM_SYSKEYUP: writeWm("WM_SYSKEYUP"); break;
            case WM_SYSCHAR: writeWm("WM_SYSCHAR"); break;
            case WM_SYSDEADCHAR: writeWm("WM_SYSDEADCHAR"); break;
            case WM_IME_STARTCOMPOSITION: writeWm("WM_IME_STARTCOMPOSITION"); break;
            case WM_IME_ENDCOMPOSITION: writeWm("WM_IME_ENDCOMPOSITION"); break;
            case WM_IME_COMPOSITION: writeWm("WM_IME_COMPOSITION"); break;
            case WM_INITDIALOG: writeWm("WM_INITDIALOG"); break;
            case WM_COMMAND: writeWm("WM_COMMAND"); break;
            case WM_SYSCOMMAND: writeWm("WM_SYSCOMMAND"); break;
            case WM_TIMER: writeWm("WM_TIMER"); break;
            case WM_HSCROLL: writeWm("WM_HSCROLL"); break;
            case WM_VSCROLL: writeWm("WM_VSCROLL"); break;
            case WM_INITMENU: writeWm("WM_INITMENU"); break;
            case WM_INITMENUPOPUP: writeWm("WM_INITMENUPOPUP"); break;
            case WM_MENUSELECT: writeWm("WM_MENUSELECT"); break;
            case WM_MENUCHAR: writeWm("WM_MENUCHAR"); break;
            case WM_ENTERIDLE: writeWm("WM_ENTERIDLE"); break;
            case WM_CTLCOLORMSGBOX: writeWm("WM_CTLCOLORMSGBOX"); break;
            case WM_CTLCOLOREDIT: writeWm("WM_CTLCOLOREDIT"); break;
            case WM_CTLCOLORLISTBOX: writeWm("WM_CTLCOLORLISTBOX"); break;
            case WM_CTLCOLORBTN: writeWm("WM_CTLCOLORBTN"); break;
            case WM_CTLCOLORDLG: writeWm("WM_CTLCOLORDLG"); break;
            case WM_CTLCOLORSCROLLBAR: writeWm("WM_CTLCOLORSCROLLBAR"); break;
            case WM_CTLCOLORSTATIC: writeWm("WM_CTLCOLORSTATIC"); break;
            case WM_MOUSEMOVE: writeWm("WM_MOUSEMOVE"); break;
            case WM_LBUTTONDOWN: writeWm("WM_LBUTTONDOWN"); break;
            case WM_LBUTTONUP: writeWm("WM_LBUTTONUP"); break;
            case WM_LBUTTONDBLCLK: writeWm("WM_LBUTTONDBLCLK"); break;
            case WM_RBUTTONDOWN: writeWm("WM_RBUTTONDOWN"); break;
            case WM_RBUTTONUP: writeWm("WM_RBUTTONUP"); break;
            case WM_RBUTTONDBLCLK: writeWm("WM_RBUTTONDBLCLK"); break;
            case WM_MBUTTONDOWN: writeWm("WM_MBUTTONDOWN"); break;
            case WM_MBUTTONUP: writeWm("WM_MBUTTONUP"); break;
            case WM_MBUTTONDBLCLK: writeWm("WM_MBUTTONDBLCLK"); break;
            case WM_PARENTNOTIFY: writeWm("WM_PARENTNOTIFY"); break;
            case WM_ENTERMENULOOP: writeWm("WM_ENTERMENULOOP"); break;
            case WM_EXITMENULOOP: writeWm("WM_EXITMENULOOP"); break;
            case WM_NEXTMENU: writeWm("WM_NEXTMENU"); break;
            case WM_SETFONT: writeWm("WM_SETFONT"); break;
            case WM_GETFONT: writeWm("WM_GETFONT"); break;
            case WM_USER: writeWm("WM_USER"); break;
            case WM_NEXTDLGCTL: writeWm("WM_NEXTDLGCTL"); break;
            case WM_CAPTURECHANGED: writeWm("WM_CAPTURECHANGED"); break;
            case WM_WINDOWPOSCHANGING: writeWm("WM_WINDOWPOSCHANGING"); break;
            case WM_WINDOWPOSCHANGED: writeWm("WM_WINDOWPOSCHANGED"); break;
            case WM_DRAWITEM: writeWm("WM_DRAWITEM"); break;
            case WM_CLEAR: writeWm("WM_CLEAR"); break;
            case WM_CUT: writeWm("WM_CUT"); break;
            case WM_COPY: writeWm("WM_COPY"); break;
            case WM_PASTE: writeWm("WM_PASTE"); break;
            case WM_MDITILE: writeWm("WM_MDITILE"); break;
            case WM_MDICASCADE: writeWm("WM_MDICASCADE"); break;
            case WM_MDIICONARRANGE: writeWm("WM_MDIICONARRANGE"); break;
            case WM_MDIGETACTIVE: writeWm("WM_MDIGETACTIVE"); break;
            case WM_MOUSEWHEEL: writeWm("WM_MOUSEWHEEL"); break;
            case WM_MOUSEHOVER: writeWm("WM_MOUSEHOVER"); break;
            case WM_MOUSELEAVE: writeWm("WM_MOUSELEAVE"); break;
            case WM_PRINT: writeWm("WM_PRINT"); break;
            case WM_PRINTCLIENT: writeWm("WM_PRINTCLIENT"); break;
            case WM_MEASUREITEM: writeWm("WM_MEASUREITEM"); break;

            default:
                if(m.msg >= WM_USER && m.msg <= 0x7FFF)
                {
                    writeWm("WM_USER+" ~ std.string.toString(m.msg - WM_USER));
                }
                else if(m.msg >=0xC000 && m.msg <= 0xFFFF)
                {
                    writeWm("RegisterWindowMessage");
                }
                else
                {
                    writeWm("?");
                }
        }

        Control ctrl;
        ctrl = Application.lookupHwnd(m.hWnd);
        writef("HWND=%d(0x%X) %s WPARAM=%d(0x%X) LPARAM=%d(0x%X)\n\n",
            cast(size_t)m.hWnd, cast(size_t)m.hWnd,
            ctrl ? ("DFLname='" ~ ctrl.name ~ "'") : "<nonDFL>",
            m.wParam, m.wParam,
            m.lParam, m.lParam);

        debug(MESSAGE_PAUSE)
        {
            Sleep(50);
        }
    }
}


extern(Windows) LRESULT dflWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{    
    if(msg == wmDfl)
    {
        switch(wparam)
        {
            case WPARAM_DFL_INVOKE:
                {
                    InvokeData* pinv;
                    pinv = cast(InvokeData*)lparam;
                    try
                    {
                        pinv.result = pinv.dg(pinv.args);
                    }
                    catch(Throwable e)
                    {
                        try
                        {
                            pinv.exception = e;
                        }
                        catch(Throwable e2)
                        {
                            Application.onThreadException(e2);
                        }
                    }
                }
                return LRESULT_DFL_INVOKE;

            case WPARAM_DFL_INVOKE_SIMPLE:
                {
                    InvokeSimpleData* pinv;
                    pinv = cast(InvokeSimpleData*)lparam;
                    try
                    {
                        pinv.dg();
                    }
                    catch(Throwable e)
                    {
                        try
                        {
                            pinv.exception = e;
                        }
                        catch(Throwable e2)
                        {
                            Application.onThreadException(e2);
                        }
                    }
                }
                return LRESULT_DFL_INVOKE;

            case WPARAM_DFL_DELAY_INVOKE:
                try
                {
                    (cast(void function())lparam)();
                }
                catch(Throwable e)
                {
                    Application.onThreadException(e);
                }
                break;

            case WPARAM_DFL_DELAY_INVOKE_PARAMS:
                {
                    DflInvokeParam* p;
                    p = cast(DflInvokeParam*)lparam;
                    try
                    {
                        p.fp(Application.lookupHwnd(hwnd), p.params.ptr[0 .. p.nparams]);
                    }
                    catch(Throwable e)
                    {
                        Application.onThreadException(e);
                    }
                    GC.free(p);
                }
                break;

            default:
        }
    }

    Message dm = Message(hwnd, msg, wparam, lparam);
    Control ctrl;

    debug(SHOW_MESSAGE_INFO)
        showMessageInfo(dm);

    if(msg == WM_NCCREATE)
    {
        ctrl = Application.getCreatingControl();
        if(!ctrl)
        {
            debug(APP_PRINT)
                cprintf("Unable to add window 0x%X.\n", hwnd);
            return dm.result;
        }
        Application.creatingControl(null); // Reset.

        Application.controls[hwnd] = ctrl;
        ctrl.hwnd = hwnd;
        debug(APP_PRINT)
            cprintf("Added window 0x%X.\n", hwnd);

        goto do_msg;
    }

    ctrl = Application.lookupHwnd(hwnd);

    if(!ctrl)
    {
        // Zombie...
        dm.result = 1;
        version(DFL_NO_ZOMBIE_FORM)
        {
        }
        else
        {
            ctrl = cast(Control)cast(void*)GetPropA(hwnd, Application.ZOMBIE_PROP.ptr);
            if(ctrl) {
                try {
                    ctrl.mustWndProc(dm);
                } catch (Exception ex) {
                    assert(0, "Exception thrown in window proc!");
                }
            }
        }
        return dm.result;
    }

    if(ctrl)
    {
        do_msg:
        try
        {
            ctrl.mustWndProc(dm);
            if(!ctrl.preProcessMessage(dm))
                ctrl._wndProc(dm);
        }
        catch (Throwable e)
        {
            Application.onThreadException(e);
        }
    }
    return dm.result;
}


version(CUSTOM_MSG_HOOK)
{
    alias CWPRETSTRUCT CustomMsg;


    // Needs to be re-entrant.
    extern(Windows) LRESULT globalMsgHook(int code, WPARAM wparam, LPARAM lparam)
    {
        if(code == HC_ACTION)
        {
            CustomMsg* msg = cast(CustomMsg*)lparam;
            Control ctrl;

            switch(msg.message)
            {
                // ...
            }
        }

        return CallNextHookEx(Application.msghook, code, wparam, lparam);
    }
}
else
{
}


enum LRESULT LRESULT_DFL_INVOKE = 0x95FADF; // Magic number.


struct InvokeData
{
    Object delegate(Object[]) dg;
    Object[] args;
    Object result;
    Throwable exception = null;
}


struct InvokeSimpleData
{
    void delegate() dg;
    Throwable exception = null;
}


UINT wmDfl;

enum: WPARAM
{
    WPARAM_DFL_INVOKE = 78,
    WPARAM_DFL_DELAY_INVOKE = 79,
    WPARAM_DFL_DELAY_INVOKE_PARAMS = 80,
    WPARAM_DFL_INVOKE_SIMPLE = 81,
}

struct DflInvokeParam
{
    void function(Control, size_t[]) fp;
    size_t nparams;
    size_t[1] params;
}


version(DFL_NO_WM_GETCONTROLNAME)
{
}
else
{
    UINT wmGetControlName;
}


alias HANDLE HTHEME;

extern(Windows)
{    
    alias HTHEME function(HWND) GetWindowThemeProc;
    alias BOOL function(HTHEME hTheme, int iPartId, int iStateId) IsThemeBackgroundPartiallyTransparentProc;
    alias HRESULT function(HWND hwnd, HDC hdc, RECT* prc) DrawThemeParentBackgroundProc;
    alias void function(DWORD dwFlags) SetThemeAppPropertiesProc;
}


// Set version = SUPPORTS_MOUSE_TRACKING if it is guaranteed to be supported.
// TrackMouseEventProc trackMouseEvent;

// Set version = SUPPORTS_OPACITY if it is guaranteed to be supported.
// SetLayeredWindowAttributesProc setLayeredWindowAttributes;

/+
GetWindowThemeProc getWindowTheme;
IsThemeBackgroundPartiallyTransparentProc isThemeBackgroundPartiallyTransparent;
DrawThemeParentBackgroundProc drawThemeParentBackground;
SetThemeAppPropertiesProc setThemeAppProperties;
+/


enum CONTROL_CLASSNAME = "DFL_Control";
enum FORM_CLASSNAME = "DFL_Form";
enum TEXTBOX_CLASSNAME = "DFL_TextBox";
enum LISTBOX_CLASSNAME = "DFL_ListBox";
//enum LABEL_CLASSNAME = "DFL_Label";
enum BUTTON_CLASSNAME = "DFL_Button";
enum MDICLIENT_CLASSNAME = "DFL_MdiClient";
enum RICHTEXTBOX_CLASSNAME = "DFL_RichTextBox";
enum COMBOBOX_CLASSNAME = "DFL_ComboBox";
enum TREEVIEW_CLASSNAME = "DFL_TreeView";
enum TABCONTROL_CLASSNAME = "DFL_TabControl";
enum LISTVIEW_CLASSNAME = "DFL_ListView";
enum STATUSBAR_CLASSNAME = "DFL_StatusBar";
enum PROGRESSBAR_CLASSNAME = "DFL_ProgressBar";
enum TRACKBAR_CLASSNAME = "DFL_TrackBar";

WNDPROC textBoxPrevWndProc;
WNDPROC listboxPrevWndProc;
//WNDPROC labelPrevWndProc;
WNDPROC buttonPrevWndProc;
WNDPROC mdiclientPrevWndProc;
WNDPROC richtextboxPrevWndProc;
WNDPROC comboboxPrevWndProc;
WNDPROC treeviewPrevWndProc;
WNDPROC tabcontrolPrevWndProc;
WNDPROC listviewPrevWndProc;
WNDPROC statusbarPrevWndProc;
WNDPROC progressbarPrevWndProc;
WNDPROC trackbarPrevWndProc;

LONG textBoxClassStyle;
LONG listboxClassStyle;
//LONG labelClassStyle;
LONG buttonClassStyle;
LONG mdiclientClassStyle;
LONG richtextboxClassStyle;
LONG comboboxClassStyle;
LONG treeviewClassStyle;
LONG tabcontrolClassStyle;
LONG listviewClassStyle;
LONG statusbarClassStyle;
LONG progressbarClassStyle;
LONG trackbarClassStyle;

HMODULE hmodRichtextbox;

enum UINT WNDCLASS_STYLE = 0x0008;


extern(Windows)
{
    alias BOOL function(LPINITCOMMONCONTROLSEX lpInitCtrls) InitCommonControlsExProc;
}


// For this to work properly on Windows 95, Internet Explorer 4.0 must be installed.
void _initCommonControls(DWORD dwControls)
{
    version(SUPPORTS_COMMON_CONTROLS_EX)
    {
        pragma(msg, "DFL: extended common controls supported at compile time");

        alias InitCommonControlsEx initProc;
    }
    else
    {
        // Make sure InitCommonControlsEx() is in comctl32.dll,
        // otherwise use the old InitCommonControls().

        HMODULE hmodCommonControls;
        InitCommonControlsExProc initProc;

        hmodCommonControls = LoadLibraryA("comctl32.dll");
        if(!hmodCommonControls)
            goto no_comctl32;

        initProc = cast(InitCommonControlsExProc)GetProcAddress(hmodCommonControls, "InitCommonControlsEx");
        if(!initProc)
        {
            no_comctl32:
            InitCommonControls();
            return;
        }
    }

    INITCOMMONCONTROLSEX icce;
    icce.dwSize = INITCOMMONCONTROLSEX.sizeof;
    icce.dwICC = dwControls;
    initProc(&icce);
}


extern(C)
{
    size_t C_refCountInc(void* p)
    {
        return Application._doref(p, 1);
    }


    // Returns the new ref count.
    size_t C_refCountDec(void* p)
    {
        return Application._doref(p, -1);
    }
}


static this()
{
    Application.tlsThreadFlags = TlsAlloc();
    Application.tlsControl = TlsAlloc();
    Application.tlsFilter = TlsAlloc();
    version(CUSTOM_MSG_HOOK)
        Application.tlsHook = TlsAlloc();

    wmDfl = RegisterWindowMessageA("WM_DFL");
    if(!wmDfl)
        wmDfl = WM_USER + 0x7CD;

    version(DFL_NO_WM_GETCONTROLNAME)
    {
    }
    else
    {
        wmGetControlName = RegisterWindowMessageA("WM_GETCONTROLNAME");
    }

    OleInitialize(null); // Needs to be linked with ole32.lib.

    HMODULE user32 = GetModuleHandleA("user32.dll");

    version(SUPPORTS_MOUSE_TRACKING)
    {
        pragma(msg, "DFL: mouse tracking supported at compile time");

        trackMouseEvent = &TrackMouseEvent;
    }
    else
    {
    }

    version(SUPPORTS_OPACITY)
    {
        pragma(msg, "DFL: opacity supported at compile time");

        setLayeredWindowAttributes = &SetLayeredWindowAttributes;
    }
    else
    {
    }
}


static ~this()
{
    version(DFL_NO_MENUS)
    {
    }
    else
    {
        Application.sdtorFreeAllMenus();
    }

    if(hmodRichtextbox)
        FreeLibrary(hmodRichtextbox);
}


void _unableToInit(string what)
{
    what = what[4 .. what.length];
    throw new DflException("Unable to initialize " ~ what);
}


void _initInstance()
{
    return _initInstance(GetModuleHandleA(null));
}


void _initInstance(HINSTANCE inst)
in
{
    assert(!Application.hinst);
    assert(inst);
}
do
{
    Application.hinst = inst;

    WNDCLASSA wc;
    wc.style = WNDCLASS_STYLE;
    wc.hInstance = inst;
    wc.lpfnWndProc = &dflWndProc;

    // Control wndclass.
    wc.lpszClassName = CONTROL_CLASSNAME.ptr;
    if(!RegisterClassA(&wc))
        _unableToInit(CONTROL_CLASSNAME);

    // Form wndclass.
    wc.cbWndExtra = DLGWINDOWEXTRA;
    wc.lpszClassName = FORM_CLASSNAME.ptr;
    if(!RegisterClassA(&wc))
        _unableToInit(FORM_CLASSNAME);
}


extern(Windows)
{
    void _initTextBox()
    {
        if(!textBoxPrevWndProc)
        {
            WNDCLASSW info;
            textBoxPrevWndProc = superClass(HINSTANCE.init, "EDIT", TEXTBOX_CLASSNAME, info);
            if(!textBoxPrevWndProc)
                _unableToInit(TEXTBOX_CLASSNAME);
            textBoxClassStyle = info.style;
        }
    }


    void _initListbox()
    {
        if(!listboxPrevWndProc)
        {
            WNDCLASSW info;
            listboxPrevWndProc = superClass(HINSTANCE.init, "LISTBOX", LISTBOX_CLASSNAME, info);
            if(!listboxPrevWndProc)
                _unableToInit(LISTBOX_CLASSNAME);
            listboxClassStyle = info.style;
        }
    }


    void _initButton()
    {
        if(!buttonPrevWndProc)
        {
            WNDCLASSW info;
            buttonPrevWndProc = superClass(HINSTANCE.init, "BUTTON", BUTTON_CLASSNAME, info);
            if(!buttonPrevWndProc)
                _unableToInit(BUTTON_CLASSNAME);
            buttonClassStyle = info.style;
        }
    }


    void _initMdiclient()
    {
        if(!mdiclientPrevWndProc)
        {
            WNDCLASSW info;
            mdiclientPrevWndProc = superClass(HINSTANCE.init, "MDICLIENT", MDICLIENT_CLASSNAME, info);
            if(!mdiclientPrevWndProc)
                _unableToInit(MDICLIENT_CLASSNAME);
            mdiclientClassStyle = info.style;
        }
    }


    void _initRichtextbox()
    {
        if(!richtextboxPrevWndProc)
        {
            bool rich5 = true;
            if(!hmodRichtextbox)
            {
                hmodRichtextbox = LoadLibraryA("msftedit.dll");
                if(!hmodRichtextbox) {
                    rich5 = false;
                    hmodRichtextbox = LoadLibraryA("riched20.dll");
                    if(!hmodRichtextbox) {
                        throw new DflException("Unable to load 'riched20.dll'");
                    }
                }
            }

            wstring classname = rich5 ? "RICHEDIT50W"w : "RichEdit20W"w;

            WNDCLASSW info;
            richtextboxPrevWndProc = superClass(HINSTANCE.init, classname, RICHTEXTBOX_CLASSNAME, info);
            if(!richtextboxPrevWndProc)
                _unableToInit(RICHTEXTBOX_CLASSNAME);
            richtextboxClassStyle = info.style;
        }
    }


    void _initCombobox()
    {
        if(!comboboxPrevWndProc)
        {
            WNDCLASSW info;
            comboboxPrevWndProc = superClass(HINSTANCE.init, "COMBOBOX", COMBOBOX_CLASSNAME, info);
            if(!comboboxPrevWndProc)
                _unableToInit(COMBOBOX_CLASSNAME);
            comboboxClassStyle = info.style;
        }
    }


    void _initTreeview()
    {
        if(!treeviewPrevWndProc)
        {
            _initCommonControls(ICC_TREEVIEW_CLASSES);

            WNDCLASSW info;
            treeviewPrevWndProc = superClass(HINSTANCE.init, "SysTreeView32", TREEVIEW_CLASSNAME, info);
            if(!treeviewPrevWndProc)
                _unableToInit(TREEVIEW_CLASSNAME);
            treeviewClassStyle = info.style;
        }
    }


    void _initTabcontrol()
    {
        if(!tabcontrolPrevWndProc)
        {
            _initCommonControls(ICC_TAB_CLASSES);

            WNDCLASSW info;
            tabcontrolPrevWndProc = superClass(HINSTANCE.init, "SysTabControl32", TABCONTROL_CLASSNAME, info);
            if(!tabcontrolPrevWndProc)
                _unableToInit(TABCONTROL_CLASSNAME);
            tabcontrolClassStyle = info.style;
        }
    }


    void _initListview()
    {
        if(!listviewPrevWndProc)
        {
            _initCommonControls(ICC_LISTVIEW_CLASSES);

            WNDCLASSW info;
            listviewPrevWndProc = superClass(HINSTANCE.init, "SysListView32", LISTVIEW_CLASSNAME, info);
            if(!listviewPrevWndProc)
                _unableToInit(LISTVIEW_CLASSNAME);
            listviewClassStyle = info.style;
        }
    }


    void _initStatusbar()
    {
        if(!statusbarPrevWndProc)
        {
            _initCommonControls(ICC_WIN95_CLASSES);

            WNDCLASSW info;
            statusbarPrevWndProc = superClass(HINSTANCE.init, "msctls_statusbar32", STATUSBAR_CLASSNAME, info);
            if(!statusbarPrevWndProc)
                _unableToInit(STATUSBAR_CLASSNAME);
            statusbarClassStyle = info.style;
        }
    }


    void _initProgressbar()
    {
        if(!progressbarPrevWndProc)
        {
            _initCommonControls(ICC_PROGRESS_CLASS);

            WNDCLASSW info;
            progressbarPrevWndProc = superClass(HINSTANCE.init, "msctls_progress32", PROGRESSBAR_CLASSNAME, info);
            if(!progressbarPrevWndProc)
                _unableToInit(PROGRESSBAR_CLASSNAME);
            progressbarClassStyle = info.style;
        }
    }

    void _initTrackBar()
    {
        if (!trackbarPrevWndProc)
        {
            _initCommonControls(ICC_BAR_CLASSES);

            WNDCLASSW info;
            trackbarPrevWndProc = superClass(HINSTANCE.init, "msctls_trackbar32", TRACKBAR_CLASSNAME, info);
            if(!trackbarPrevWndProc)
                _unableToInit(TRACKBAR_CLASSNAME);
            trackbarClassStyle = info.style;
        }
    }
}


public:

// Returns the old wndProc.
WNDPROC superClass(HINSTANCE hinst, wstring className, wstring newClassName, out WNDCLASSW getInfo) // package
{
    WNDPROC wndProc;

    if(!GetClassInfoW(hinst, className.ptr, &getInfo))
        throw new DflException("Unable to obtain information for window class '" ~ to!string(className) ~ "'");

    wndProc = getInfo.lpfnWndProc;
    getInfo.lpfnWndProc = &dflWndProc;

    getInfo.style &= ~CS_GLOBALCLASS;
    getInfo.hCursor = HCURSOR.init;
    getInfo.lpszClassName = newClassName.ptr;
    getInfo.hInstance = Application.getInstance();

    if(RegisterClassW(&getInfo) == 0)
        return null;
    return wndProc;
}

//NewAdd:
public:

bool is64() 
{
    size_t a;
    return  a.sizeof == 8 ? true : false;
}