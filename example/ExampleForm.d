module exampleform;

import std.stdio;
import std.conv;

/*
Generated by Entice Designer
Entice Designer written by Christopher E. Miller
www.dprogramming.com/entice.php
*/

import dfl.all;
import mytab;

class ExampleForm: dfl.form.Form
{
    // Do not modify or move this block of variables.
    //~Entice Designer variables begin here.
    dfl.groupbox.GroupBox groupBox1;
    dfl.button.Button button1;
    dfl.button.CheckBox checkBox1;
    dfl.button.RadioButton radioButton1;
    dfl.label.Label label1;
    dfl.textbox.TextBox textBox1;
    dfl.richtextbox.RichTextBox richTextBox1;
    dfl.progressbar.ProgressBar progressBar1;
    dfl.listbox.ListBox listBox1;
    dfl.combobox.ComboBox comboBox1;
    dfl.listview.ListView listView1;
    dfl.tabcontrol.TabControl tabControl1;
    dfl.tabcontrol.TabPage panel3;
    dfl.button.Button button4;
    dfl.button.CheckBox checkBox2;
    dfl.textbox.TextBox textBox2;
    dfl.picturebox.PictureBox pictureBox2;
    dfl.treeview.TreeView treeView1;
    dfl.splitter.Splitter splitter2;
    dfl.panel.Panel panel2;
    dfl.button.Button button2;
    dfl.textbox.TextBox textBox3;
    dfl.splitbutton.SplitButton splitButton1;
    dfl.commandbutton.CommandButton commandButton1;
    dfl.trackbar.TrackBar trackBar1;
    //~Entice Designer variables end here.

    MyTab tabPage1;
    //MyTab tabPage2;

    this() {
        this(false);
    }

    this(bool darkMode)
    {
        if (darkMode) {
            Application.setDarkModeForWindow(this);
        }

        initializeExampleForm();

        //@  Other ExampleForm initialization code here.

        tabPage1 = new MyTab();
        tabControl1.tabPages.add(tabPage1);
    }


    void initializeExampleForm()
    {
        // Do not manually modify this function.
        //~Entice Designer 0.8.5.02 code begins here.
        //~DFL Form
        text = "Dark Mode Form";
        clientSize = dfl.all.Size(624, 369);
        //~DFL dfl.groupbox.GroupBox=groupBox1
        groupBox1 = new dfl.groupbox.GroupBox();
        groupBox1.name = "groupBox1";
        groupBox1.text = "Group box";
        groupBox1.bounds = dfl.all.Rect(8, 8, 344, 140);
        groupBox1.parent = this;
        //~DFL dfl.button.Button=button1
        button1 = new dfl.button.Button();
        button1.name = "button1";
        button1.text = "Button1";
        button1.bounds = dfl.all.Rect(16, 27, 75, 23);
        button1.parent = groupBox1;
        //~DFL dfl.button.CheckBox=checkBox1
        checkBox1 = new dfl.button.CheckBox();
        checkBox1.name = "checkBox1";
        checkBox1.text = "Check box";
        checkBox1.bounds = dfl.all.Rect(104, 27, 75, 23);
        checkBox1.parent = groupBox1;
        //~DFL dfl.button.RadioButton=radioButton1
        radioButton1 = new dfl.button.RadioButton();
        radioButton1.name = "radioButton1";
        radioButton1.text = "Radio button";
        radioButton1.bounds = dfl.all.Rect(192, 27, 83, 23);
        radioButton1.parent = groupBox1;
        //~DFL dfl.label.Label=label1
        label1 = new dfl.label.Label();
        label1.name = "label1";
        label1.text = "Label";
        label1.bounds = dfl.all.Rect(288, 27, 36, 23);
        label1.parent = groupBox1;
        //~DFL dfl.textbox.TextBox=textBox1
        textBox1 = new dfl.textbox.TextBox();
        textBox1.name = "textBox1";
        textBox1.text = "Text box";
        textBox1.bounds = dfl.all.Rect(16, 67, 96, 23);
        textBox1.parent = groupBox1;
        //~DFL dfl.richtextbox.RichTextBox=richTextBox1
        richTextBox1 = new dfl.richtextbox.RichTextBox();
        richTextBox1.name = "richTextBox1";
        richTextBox1.text = "Rich text box";
        richTextBox1.bounds = dfl.all.Rect(120, 59, 208, 72);
        richTextBox1.parent = groupBox1;
        //~DFL dfl.progressbar.ProgressBar=progressBar1
        progressBar1 = new dfl.progressbar.ProgressBar();
        progressBar1.name = "progressBar1";
        progressBar1.bounds = dfl.all.Rect(16, 107, 92, 23);
        progressBar1.parent = groupBox1;
		progressBar1.minimum = 0;
		progressBar1.maximum = 100;
		progressBar1.step = 5;
		progressBar1.value = 0;
        //~DFL dfl.listbox.ListBox=listBox1
        listBox1 = new dfl.listbox.ListBox();
        listBox1.name = "listBox1";
        listBox1.bounds = dfl.all.Rect(8, 152, 120, 95);
        listBox1.parent = this;
        //~DFL dfl.combobox.ComboBox=comboBox1
        comboBox1 = new dfl.combobox.ComboBox();
        comboBox1.name = "comboBox1";
        comboBox1.text = "Combo box";
        comboBox1.dropDownStyle = dfl.all.ComboBoxStyle.DROP_DOWN_LIST;
        comboBox1.bounds = dfl.all.Rect(136, 152, 80, 21);
        comboBox1.parent = this;
        //~DFL dfl.listview.ListView=listView1
        listView1 = new dfl.listview.ListView();
        listView1.name = "listView1";
        listView1.bounds = dfl.all.Rect(224, 152, 128, 95);
        listView1.parent = this;
        //~DFL dfl.tabcontrol.TabControl=tabControl1
        tabControl1 = new dfl.tabcontrol.TabControl();
        tabControl1.name = "tabControl1";
        tabControl1.bounds = dfl.all.Rect(360, 16, 256, 232);
        tabControl1.parent = this;
        //~DFL dfl.tabcontrol.TabPage:dfl.panel.Panel=panel3
        panel3 = new dfl.tabcontrol.TabPage();
        panel3.text = "panel3";
        panel3.name = "panel3";
        panel3.borderStyle = dfl.all.BorderStyle.FIXED_SINGLE;
        //panel3.bounds = dfl.all.Rect(12, 12, 232, 208);
        //panel3.parent = tabControl1;
        tabControl1.tabPages.add(panel3);
        //~DFL dfl.button.Button=button4
        button4 = new dfl.button.Button();
        button4.name = "button4";
        button4.text = "Button in panel in tab control";
        button4.bounds = dfl.all.Rect(8, 8, 211, 23);
        button4.parent = panel3;
        //~DFL dfl.button.CheckBox=checkBox2
        checkBox2 = new dfl.button.CheckBox();
        checkBox2.name = "checkBox2";
        checkBox2.text = "Check box in panel in tab control";
        checkBox2.bounds = dfl.all.Rect(8, 40, 211, 23);
        checkBox2.parent = panel3;
        //~DFL dfl.textbox.TextBox=textBox2
        textBox2 = new dfl.textbox.TextBox();
        textBox2.name = "textBox2";
        textBox2.text = "Text box in panel in tab control";
        textBox2.bounds = dfl.all.Rect(8, 72, 208, 23);
        textBox2.parent = panel3;
        //~DFL dfl.picturebox.PictureBox=pictureBox2
        pictureBox2 = new dfl.picturebox.PictureBox();
        pictureBox2.name = "pictureBox2";
        pictureBox2.bounds = dfl.all.Rect(136, 184, 80, 64);
        pictureBox2.parent = this;
        //~DFL dfl.treeview.TreeView=treeView1
        treeView1 = new dfl.treeview.TreeView();
        treeView1.name = "treeView1";
        treeView1.bounds = dfl.all.Rect(8, 256, 120, 100);
        treeView1.parent = this;
        //~DFL dfl.splitter.Splitter=splitter2
        splitter2 = new dfl.splitter.Splitter();
        splitter2.name = "splitter2";
        splitter2.dock = dfl.all.DockStyle.BOTTOM;
        splitter2.bounds = dfl.all.Rect(0, 361, 624, 8);
        splitter2.parent = this;
        //~DFL dfl.panel.Panel=panel2
        panel2 = new dfl.panel.Panel();
        panel2.name = "panel2";
        panel2.borderStyle = dfl.all.BorderStyle.FIXED_3D;
        panel2.bounds = dfl.all.Rect(136, 256, 480, 96);
        panel2.parent = this;
        //~DFL dfl.button.Button=button2
        button2 = new dfl.button.Button();
        button2.name = "button2";
        button2.text = "Button in panel";
        button2.bounds = dfl.all.Rect(8, 8, 99, 23);
        button2.parent = panel2;
        //~DFL dfl.textbox.TextBox=textBox3
        textBox3 = new dfl.textbox.TextBox();
        textBox3.name = "textBox3";
        textBox3.text = "Text box in panel";
        textBox3.bounds = dfl.all.Rect(112, 8, 120, 23);
        textBox3.parent = panel2;
        //~DFL dfl.button.SplitButton=splitbutton1
        splitButton1 = new dfl.splitbutton.SplitButton();
        splitButton1.name = "splitButton1";
        splitButton1.text = "Split Button";
        splitButton1.bounds = dfl.all.Rect(8, 35, 99, 23);
        splitButton1.parent = panel2;
        //~DFL dfl.trackbar.TrackBar=trackBar1
        trackBar1 = new dfl.trackbar.TrackBar();
        trackBar1.name = "trackBar1";
        trackBar1.bounds = dfl.all.Rect(112, 35, 99, 23);
        //trackBar1.max = 5;
        //trackBar1.showTip = false;
        trackBar1.parent = panel2;
        //~DFL dfl.commandbutton.CommandButton=commandButton1
        commandButton1 = new dfl.commandbutton.CommandButton();
        commandButton1.name = "commandButton1";
        commandButton1.text = "Commandlink button";
        commandButton1.note = "in panel";
        commandButton1.bounds = dfl.all.Rect(235, 8, 225, 70);
        commandButton1.parent = panel2;
        //~Entice Designer 0.8.5.02 code ends here.

        comboBox1.items.add(new Control("BLOCKS"w));
        comboBox1.items.add(new Control("SMOOTH"w));
        comboBox1.items.add(new Control("MARQUEE"w));
        comboBox1.selectedIndex = 0;

        splitButton1.items.add(new Control("test 1"w));
        splitButton1.items.add(new Control("test 2"w));
        splitButton1.items.add(new Control("test 3"w));

        void comboBox1_selectedValueChanged (Object sender, EventArgs evt) {
            //writeln("Invalidating form");
            auto selectedItem = comboBox1.selectedItem.toWString();
            switch (selectedItem) {
                case "BLOCKS"w:
                    progressBar1.style = ProgressBar.STYLES.BLOCKS;
                    break;
                case "SMOOTH"w:
                    progressBar1.style = ProgressBar.STYLES.SMOOTH;
                    break;
                case "MARQUEE"w:
                    progressBar1.style = ProgressBar.STYLES.MARQUEE;
                    break;
                default:
                    break;
            }
            progressBar1.value = 0;

        }

        void button1_click (Object sender, EventArgs evt) {
            //writeln("Invalidating form");
            final switch (progressBar1.state) {
                case ProgressBar.STATE.NORMAL:
                    progressBar1.state = ProgressBar.STATE.PAUSED;
                    break;
                case ProgressBar.STATE.PAUSED:
                    progressBar1.state = ProgressBar.STATE.ERROR;
                    break;
                case ProgressBar.STATE.ERROR:
                    progressBar1.state = ProgressBar.STATE.NORMAL;
                    break;
            }
        }

        void button2_click (Object sender, EventArgs evt) {
            if (progressBar1.value == 100) {
                progressBar1.value = 0;
            } else {
                progressBar1.performStep();
            }
            writeln(progressBar1.value);
        }

        void button4_click (Object sender, EventArgs evt) {
            commandButton1.note = textBox2.text;
            writefln("Set commandButton1 note to '%s'", textBox2.text);
        }

        void checkBox1_click (Object sender, EventArgs evt) {
            label1.text("lABEL");
            label1.invalidate(false);
        }

        void radioButton1_click (Object sender, EventArgs evt) {
            label1.text("Label");
            label1.invalidate(false);
        }

        void trackBar1_valueChanged (Object sender, EventArgs evt) {
            writefln("Trackbar value is %d", trackBar1.value);
        }

        void splitButton1_click (Object sender, EventArgs evt) {
            writefln("SplitButton clicked with text '%s'", splitButton1.text);
        }

        comboBox1.selectedValueChanged.addHandler(&comboBox1_selectedValueChanged);
        button1.click.addHandler(&button1_click);
        button2.click.addHandler(&button2_click);
        button4.click.addHandler(&button4_click);
        checkBox1.click.addHandler(&checkBox1_click);
        radioButton1.click.addHandler(&radioButton1_click);
        trackBar1.valueChanged.addHandler(&trackBar1_valueChanged);
        splitButton1.click.addHandler(&splitButton1_click);
    }
}


int main()
{
    int result = 0;

    try
    {
        //Application.enableDarkMode();

        //@  Other application initialization code here.

        ExampleForm form;
        form = new ExampleForm(true);
        
        //Application.setDarkModeForControls(form);

        // Make sure there's no double initialization! This breaks ProgressBar and this is only what i know about!
        //form.initializeExampleForm();

        /*
        if (FreeConsole !is null) {
            FreeConsole();
        }
        */

        Application.run(form);
    }
    catch(Exception o)
    {
        msgBox(to!wstring(o.toString()), "Fatal Error"w, MsgBoxButtons.OK, MsgBoxIcon.ERROR);

        result = 1;
    }

    return result;
}