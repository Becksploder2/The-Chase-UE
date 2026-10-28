const {app,BrowserWindow}=require('electron');
const path=require('path');
app.whenReady().then(()=>{const win=new BrowserWindow({width:1280,height:850,minWidth:980,minHeight:650,backgroundColor:'#080d1e',autoHideMenuBar:true,webPreferences:{nodeIntegration:false,contextIsolation:true,sandbox:true}});win.loadFile(path.join(__dirname,'src','index.html'));});
app.on('window-all-closed',()=>{if(process.platform!=='darwin')app.quit()});
