#!/usr/bin/python
# -*- coding: utf-8 -*-


import wx
import os
import shutil
from wx import html

class PrestoFrame(wx.Frame):
    def __init__(self,parent):
        self.title = "PRime"
        wx.Frame.__init__(self,parent,-1,self.title,wx.DefaultPosition,size=(600,600),style= wx.SYSTEM_MENU | wx.CAPTION | wx.CLOSE_BOX | wx.MINIMIZE_BOX)
        self.toolbar = None
        self.toolbox = None
        self.tool_pane = wx.Panel(self,-1,(0,50),(80,512),style= wx.TAB_TRAVERSAL|wx.NO_BORDER)
        self.image_pane = wx.Panel(self,-1,(80,50),(512,512),style= wx.TAB_TRAVERSAL|wx.NO_BORDER)
        self.tool_pane.SetBackgroundColour("gray")
        self.image_pane.SetBackgroundColour("white")
        self.initStatusBar()
        self.createMenuBar()
        self.createToolBox()
        self.createToolBar()
        self.Bind(wx.EVT_CLOSE,self.OnCloseWindow)
        text = wx.StaticText(self.tool_pane,-1,"FILTERS",(10,20),(80,80))
        self.State = "0"
        self.in_filename = None
	self.filt_filename = 'C/filt_image.bmp'
        self.Show(True)

    def initStatusBar(self):
        self.statusbar = self.CreateStatusBar()

    def menuData(self):
        data = [("&File",(
                  ("&Open",wx.ID_OPEN,"Open Image",self.OnOpen),
                  ("&Save",wx.ID_SAVE,"Save Image",self.OnSave),
                  ("&Save&As",wx.ID_SAVE,"Save Image As",self.OnSaveAs),
                  ("","","",""),
                  ("&Quit",wx.ID_EXIT,"Quit",self.OnCloseWindow))),
                ("&Edit",(
                  ("&Laplace",-1,"Laplace Filter",self.OnOpen), 
                  ("&Gaussian",-1,"Gaussian Filter",self.OnOpen),
                  ("&Sobel",-1,"Sobel Filter",self.OnOpen),
                  ("&Inverter",-1,"Inverter",self.OnOpen),
                  ("&Thresholder",-1,"Thresholder",self.OnOpen)
                )),
                ("&About",(
                  ("&About",-1,"About",self.OnAbout),
               ))]
        return data

    def createMenuBar(self):
        menuBar = wx.MenuBar()
        for eachMenuData in self.menuData():
            menuLabel = eachMenuData[0]
            menuItems = eachMenuData[1]
            menuBar.Append(self.createMenu(menuItems), menuLabel)
        self.SetMenuBar(menuBar)

    def createMenu(self,menuData):
        menu = wx.Menu()
        for eachItem in menuData:
            if len(eachItem) == 2:
                label = eachItem[0]
                subMenu = self.createMenu(eachItem[1])
                menu.AppendMenu(wx.NewId(), label, subMenu)
            else:
                self.createMenuItem(menu, *eachItem)
        return menu

    def createMenuItem(self,menu,label,item_id,status,handler,kind=wx.ITEM_NORMAL):
        if not label:
            menu.AppendSeparator()
            return
        menuItem = menu.Append(item_id,label,status,kind)
        self.Bind(wx.EVT_MENU,handler,menuItem)

    def OnCloseWindow(self,event):
        self.Destroy()

    def OnOpen(self,event):
        dlg = wx.FileDialog(self, "Open Image file...", os.getcwd(),style=wx.OPEN,wildcard="Image files (*.bmp) |*.bmp")
        if dlg.ShowModal() == wx.ID_OK:
            self.in_filename = dlg.GetPath()
	if self.in_filename:
            img = wx.Image(self.in_filename, wx.BITMAP_TYPE_ANY)
            imageCtrl = wx.StaticBitmap(self.image_pane, wx.ID_ANY,wx.BitmapFromImage(img))
        dlg.Destroy()

    def OnSaveAs(self,event):
            dlg = wx.FileDialog(self,"Save project as...",os.getcwd(),style=wx.SAVE|wx.OVERWRITE_PROMPT)
            tmpfile = 'tmpfile'
            if dlg.ShowModal() == wx.ID_OK:
                filename = dlg.GetPath()
		if filename:
                    shutil.copyfile(self.filt_filename,tmpfile)
	            try:
   	                with open(filename):
       	    	            os.remove(filename)
	            except:
   	                pass
	            shutil.copyfile(self.filt_filename,filename) #need to change here.
                    os.remove(tmpfile)
        	    self.in_filename = filename
                    self.State = "1"
            dlg.Destroy()


    def OnSave(self,event):
        if self.State == 1:
            filename = self.in_filename
	    if filename:
	        try:
   	            with open(filename):
       	                os.remove(filename)
	        except:
   	            pass
	        shutil.copyfile(self.filt_filename,filename) #need to change here.
        	self.in_filename = filename
        else:
            self.OnSaveAs(event)

    def createToolBar(self):
        self.toolbar = wx.ToolBar(self,-1,(0,0),(512,50),wx.TB_HORIZONTAL)
	#self.toolbar.SetMargins( [4,4] ) 
        ftool = self.toolbar.AddLabelTool(wx.ID_ANY, 'Open', wx.Bitmap('icons/folder.png'),wx.NullBitmap, wx.ITEM_NORMAL, "","Open Image" ) 
        stool = self.toolbar.AddLabelTool(wx.ID_ANY, 'Save', wx.Bitmap('icons/save.png'),wx.NullBitmap, wx.ITEM_NORMAL, "", "Save Image" )
        itool = self.toolbar.AddLabelTool(wx.ID_ANY, 'Info', wx.Bitmap('icons/info.png'),wx.NullBitmap, wx.ITEM_NORMAL,"", "Info" )
	qtool = self.toolbar.AddLabelTool(wx.ID_ANY, 'Quit', wx.Bitmap('icons/exit.png'),wx.NullBitmap, wx.ITEM_NORMAL,"", "Quit" )
        self.toolbar.Realize()
        self.Bind(wx.EVT_TOOL, self.OnOpen, ftool)
        self.Bind(wx.EVT_TOOL, self.OnSaveAs, stool)
        self.Bind(wx.EVT_TOOL, self.OnAbout, itool)
	self.Bind(wx.EVT_TOOL, self.OnCloseWindow, qtool)

    def createToolBox(self):
        self.toolbox = wx.ToolBar(self,-1,(0,100), (80,451), wx.TB_VERTICAL)
	#self.toolbox.SetMargins( [4,4] ) 
	tfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Thresholder', wx.Bitmap('icons/thresholder.png'),wx.NullBitmap, wx.ITEM_NORMAL,"", "Thresholder" )
	ifilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Inverter', wx.Bitmap('icons/inverter.jpeg'),wx.NullBitmap, wx.ITEM_NORMAL,"", "Inverter" )
        lfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Laplace', wx.Bitmap('icons/laplace.gif'),wx.NullBitmap, wx.ITEM_NORMAL, "","Laplace Filter" ) 
        gfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Gaussian', wx.Bitmap('icons/gaussian.png'),wx.NullBitmap, wx.ITEM_NORMAL, "", "Gaussian Filter" )
        sfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Sobel', wx.Bitmap('icons/sobel.png'),wx.NullBitmap, wx.ITEM_NORMAL,"", "Sobel Filter" )
	bfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Box', wx.Bitmap('icons/box.jpeg'),wx.NullBitmap, wx.ITEM_NORMAL,"", "box" )
	rfilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Slicer', wx.Bitmap('icons/slicer.jpeg'),wx.NullBitmap, wx.ITEM_NORMAL,"", "slicer" )
	efilt = self.toolbox.AddLabelTool(wx.ID_ANY, 'Emboss', wx.Bitmap('icons/emboss.jpeg'),wx.NullBitmap, wx.ITEM_NORMAL,"", "emboss" )
        self.toolbox.Realize()
        self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"laplace","c"), lfilt)
        self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"gaussian","c"), gfilt)
        self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"sobel","c"), sfilt)
	self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"thresholder","s"), tfilt)
	self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"inverter","s"), ifilt)
	self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"box","c"), bfilt)
	self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"slicer","s"), rfilt)
	self.Bind(wx.EVT_TOOL, lambda event: self.OnFilter(event,"emboss","c"), efilt)

    def OnAbout(self,event):
        dlg = PRestoAbout(self)
        dlg.ShowModal()
        dlg.Destroy()

    def OnFilter(self,event,filt_name,filt_type):
	try:
   	    with open(self.filt_filename):
       	    	os.remove(self.filt_filename)
	except:
   	    pass
	os.system("C/./filter "+self.in_filename+" "+self.filt_filename+" "+"bitstreams/"+filt_name+"_partial.bin"+" "+filt_type);
        img = wx.Image(self.filt_filename, wx.BITMAP_TYPE_ANY)
        imageCtrl = wx.StaticBitmap(self.image_pane, wx.ID_ANY,wx.BitmapFromImage(img))

class PRestoAbout(wx.Dialog):
    text = '''
<html>
<body bgcolor = "#ACAA60">
<center><table bgcolor = "#455481" width="100%"cellspacing="0"
cellpadding="0" border-"1">
<tr>
<td align="center"><h1>PRime</h1></td>
</tr>
</table>
</center>
<p><b>PR based Image Manipulation Environment:</b> A demonstration platform for image processing using FPGA partial reconfiguration </b></p>
<p>Copyright &copy 2012-2013 Vipin K & Suhaib Fahmy, Nanyang Technological University, Singapore</p>
</body>
</html>
'''
    def __init__(self,parent):
        
        wx.Dialog.__init__(self,parent,-1,'About PResto',size=(400,300))
        html = wx.html.HtmlWindow(self)
        html.SetPage(self.text)
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(html,1,wx.EXPAND|wx.ALL,5)
        self.SetSizer(sizer)
        self.Layout()

def main():
  ex = wx.App()
  PrestoFrame(None)
  ex.MainLoop()

if __name__ == '__main__':
  main()
