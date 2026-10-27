const fs=require('fs'),path=require('path'),crypto=require('crypto'),cp=require('child_process');
const out=__dirname,root='C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest';
const sources=['lib/main.dart','lib/screens/welcome_screen.dart','lib/widgets/student_character_picker.dart','lib/widgets/main_navigation_scope.dart','lib/widgets/main_navigation_shell.dart','lib/screens/home_screen.dart','lib/screens/lessons_screen.dart','lib/screens/games_screen.dart','lib/screens/letter_mastery_check_screen.dart','lib/screens/letter_introduction_screen.dart','lib/models/letter_adventure.dart','lib/widgets/progress_journey_view.dart','lib/screens/parent_screen.dart','lib/widgets/parent_pin_form.dart','lib/services/parent_auth_service.dart','lib/screens/settings_screen.dart','lib/widgets/time_limit_overlay.dart','lib/services/screen_time_service.dart','lib/providers/app_provider.dart','pubspec.yaml'];
const baseline=sources.map(p=>{const b=fs.readFileSync(path.join(root,p));return{path:p,sha256:crypto.createHash('sha256').update(b).digest('hex')};});fs.writeFileSync(path.join(out,'source-evidence.json'),JSON.stringify({date:'2026-10-26',applicationVersion:'1.0.37+38',sourceFiles:baseline},null,2));
fs.writeFileSync(path.join(out,'git-before.txt'),cp.execFileSync('git',['status','--porcelain=v1','-uall'],{cwd:root,env:{...process.env,GIT_OPTIONAL_LOCKS:'0'}}));
const xml=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const parts=[];const ink='#243246',blue='#17628b',line='#45546a',pale='#eef5fa',amber='#fff4dc';
function text(x,y,lines,{size=25,weight=500,color=ink,anchor='middle',gap=32}={}){if(!Array.isArray(lines))lines=[lines];const start=y-(lines.length-1)*gap/2;parts.push('<text x="'+x+'" y="'+start+'" text-anchor="'+anchor+'" dominant-baseline="middle" font-size="'+size+'" font-weight="'+weight+'" fill="'+color+'">'+lines.map((s,i)=>'<tspan x="'+x+'" dy="'+(i?gap:0)+'">'+xml(s)+'</tspan>').join('')+'</text>');}
function node(x,y,lines,{w=330,h=105,type='process',fill='#ffffff',size=24}={}){let shape;if(type==='decision'){shape='<polygon points="'+x+','+(y-h/2)+' '+(x+w/2)+','+y+' '+x+','+(y+h/2)+' '+(x-w/2)+','+y+'" fill="'+fill+'" stroke="'+line+'" stroke-width="2.5"/>';}else{shape='<rect x="'+(x-w/2)+'" y="'+(y-h/2)+'" width="'+w+'" height="'+h+'" rx="'+(type==='terminal'?h/2:5)+'" fill="'+fill+'" stroke="'+line+'" stroke-width="2.5"/>';if(type==='subprocess')shape+='<path d="M '+(x-w/2+12)+' '+(y-h/2)+' V '+(y+h/2)+' M '+(x+w/2-12)+' '+(y-h/2)+' V '+(y+h/2)+'" stroke="'+line+'" stroke-width="2"/>';}
parts.push(shape);text(x,y,lines,{size,weight:type==='decision'?600:500,gap:31});}
function route(points,label='',lx,ly,{dash=false,arrow=true}={}){parts.push('<polyline points="'+points.map(p=>p.join(',')).join(' ')+'" fill="none" stroke="'+line+'" stroke-width="2.6" stroke-linejoin="round"'+(dash?' stroke-dasharray="8 7"':'')+(arrow?' marker-end="url(#arrow)"':'')+'/>');if(label){const width=label.length*11+16;parts.push('<rect x="'+(lx-width/2)+'" y="'+(ly-14)+'" width="'+width+'" height="28" fill="white"/>');text(lx,ly,label,{size:21,weight:500});}}
function connector(x,y,label){parts.push('<circle cx="'+x+'" cy="'+y+'" r="24" fill="white" stroke="'+blue+'" stroke-width="2.6"/>');text(x,y,label,{size:26,weight:700,color:blue});}
function lane(x,width,title){parts.push('<rect x="'+(x-width/2)+'" y="610" width="'+width+'" height="885" rx="12" fill="'+pale+'" stroke="#cfdae4" stroke-width="1.6"/>');}
parts.push('<rect width="2500" height="1900" fill="white"/>');
text(65,57,'KIDSPHONICS — APPLICATION FLOWCHART',{size:43,weight:700,anchor:'start',color:blue});
text(65,103,'Current application source • Version 1.0.37+38 • 26 October 2026',{size:24,anchor:'start',color:'#536579'});
text(65,139,'Home activities: Lessons / Quick Check / Games     Bottom navigation: Home / Progress / Parents / Settings',{size:23,anchor:'start'});
parts.push('<line x1="65" y1="163" x2="2435" y2="163" stroke="#cad5df" stroke-width="2"/>');
// Startup and first-use setup.
node(110,225,['START'],{w:150,h:65,type:'terminal',fill:pale});
node(380,225,['Splash screen','Load local data'],{w:260,h:85});
node(690,225,['Data loaded?'],{w:220,h:115,type:'decision',fill:amber});
node(1020,225,['Learner setup','complete?'],{w:250,h:120,type:'decision',fill:amber});
connector(1390,225,'A');
node(1670,225,['HOME / NAVIGATION'],{w:350,h:90,fill:'#e5f1f7'});
node(2220,225,['END'],{w:220,h:65,type:'terminal',fill:pale});
route([[185,225],[250,225]]);route([[510,225],[580,225]]);
route([[800,225],[895,225]],'Yes',847,207);route([[1145,225],[1366,225]],'Yes',1240,207);route([[1414,225],[1495,225]]);
route([[1845,225],[2110,225]],'Close / Android Back',1980,205);
node(690,365,['Show load error','Retry loading'],{w:250,h:85});
route([[690,282.5],[690,322.5]],'No',717,299);
route([[565,365],[380,365],[380,267.5]],'Retry',463,345);
node(1020,365,['Introduction','Choose character','and learner name'],{w:285,h:105,type:'subprocess',size:22});
route([[1020,285],[1020,312.5]],'No',1049,299);
node(1285,365,['Save setup','locally'],{w:180,h:85,size:23});
route([[1162.5,365],[1195,365]]);
route([[1375,365],[1390,365],[1390,249]]);
// Main activity selection; the branch lines are alternatives, not parallel tasks.
node(1250,485,['Choose an action'],{w:280,h:110,type:'decision',fill:amber,size:24});
route([[1670,270],[1670,485],[1390,485]]);
route([[1250,540],[1250,552]],'',0,0,{arrow:false});
route([[200,552],[2300,552]],'',0,0,{arrow:false});
for(const [x,title] of [[200,'LESSONS'],[620,'QUICK CHECK'],[1040,'GAMES'],[1460,'PROGRESS'],[1880,'PARENTS'],[2300,'SETTINGS']]){lane(x,370,title);route([[x,552],[x,606]],'',0,0,{arrow:false});const labelWidth=title.length*17+22;parts.push('<rect x="'+(x-labelWidth/2)+'" y="568" width="'+labelWidth+'" height="34" fill="white"/>');text(x,585,title,{size:26,weight:700,color:blue});}
// Lessons and Quick Check have separate entry connectors for cross-module links.
route([[200,606],[200,611]],'',0,0,{arrow:false});connector(200,635,'C');route([[200,659],[200,697.5]]);
node(200,750,['Select one of','6 lesson modules'],{type:'subprocess'});
route([[200,802.5],[200,867.5]]);
node(200,920,['Pictures / animation','Listen and interact']);
route([[200,972.5],[200,1087.5]]);
node(200,1140,['Record practice, listening','or word completion'],{size:22});
route([[200,1192.5],[200,1321]],'Back / navigation',200,1260);connector(200,1345,'A');
route([[620,606],[620,611]],'',0,0,{arrow:false});connector(620,635,'B');route([[620,659],[620,697.5]]);
node(620,750,['Recommended or','selected letter']);route([[620,802.5],[620,867.5]]);
node(620,920,['Complete the five','Quick Check tasks'],{type:'subprocess'});route([[620,972.5],[620,1067.5]]);
node(620,1120,['Score; update mastery','and eligible rewards once'],{size:22});route([[620,1172.5],[620,1230]]);
node(620,1290,['Continue / Try Again','Review Lesson / guided practice','View Progress / Home'],{type:'subprocess',h:120,size:20});
route([[620,1350],[620,1431]],'Back / navigation',620,1389);connector(620,1455,'A');
// Games are gated by parent settings; Flappy only records activity completion.
node(1040,700,['Games enabled','by parent?'],{type:'decision',w:300,h:130,fill:amber});
route([[1040,606],[1040,635]]);connector(840,700,'A');route([[890,700],[864,700]],'No',875,678);
route([[1040,765],[1040,867.5]],'Yes',1070,804);
node(1040,920,['Choose one of 11 games','Easy / Medium / Hard'],{type:'subprocess',size:22});
route([[1040,972.5],[1040,1067.5]]);node(1040,1120,['Play activity','Receive feedback']);
route([[1040,1172.5],[1040,1237.5]]);node(1040,1290,['Record applicable results','and eligible game rewards'],{size:22});
route([[1040,1342.5],[1040,1431]],'Back / navigation',1040,1385);connector(1040,1455,'A');
// Progress can open either a letter Quick Check or a related lesson.
route([[1460,606],[1460,647.5]]);node(1460,700,['View My Journey','My Letters / My Rewards'],{type:'subprocess',size:22});
route([[1460,752.5],[1460,855]]);node(1460,920,['Practice action?'],{type:'decision',w:300,h:130,fill:amber});
connector(1650,920,'B');route([[1610,920],[1626,920]],'Letter',1625,893);
connector(1270,920,'C');route([[1310,920],[1294,920]],'Lesson',1290,893);
route([[1460,985],[1460,1116]],'Browse only',1518,1040);connector(1460,1140,'A');
// PIN gate and management area.
route([[1880,606],[1880,647.5]]);node(1880,700,['Set up / unlock','4-digit Parent PIN'],{type:'subprocess'});
route([[1880,752.5],[1880,855]]);node(1880,920,['PIN accepted?'],{type:'decision',w:300,h:130,fill:amber});
route([[2030,920],[2085,920],[2085,700],[2045,700]],'No',2058,897);
route([[1880,985],[1880,1067.5]],'Yes',1911,1022);
node(1880,1120,['Parent Overview / Activity','Protected game / time controls'],{type:'subprocess',size:21});
route([[1880,1172.5],[1880,1237.5]]);node(1880,1290,['Save parent changes','End session when leaving'],{size:22});
route([[1880,1342.5],[1880,1431]],'Back / navigation',1880,1385);connector(1880,1455,'A');
route([[2300,606],[2300,640]]);node(2300,700,['Sound / display / character','Help / About / intro replay'],{type:'subprocess',h:120,size:22});
route([[2300,760],[2300,867.5]]);node(2300,920,['Save changed preferences','locally when applicable'],{size:22});
route([[2300,972.5],[2300,1116]],'Back / navigation',2300,1045);connector(2300,1140,'A');
// Global guard is drawn separately because it can interrupt every screen.
parts.push('<rect x="40" y="1530" width="2420" height="220" rx="12" fill="#fff8e9" stroke="#c4a661" stroke-width="2"/>');
text(70,1566,'GLOBAL DAILY-TIME-LIMIT GUARD — CAN COVER ANY SCREEN',{size:24,weight:700,anchor:'start',color:'#705319'});
for(const [x,lines] of [[350,['When the limit is reached','Pause covered screen']],[950,['Parent Unlock','Set up / verify Parent PIN']],[1550,['Parent grants more time','10 / 15 / 30 min or allow today']],[2150,['Resume the','covered screen']]])node(x,1650,lines,{w:450,h:85,type:x===950?'subprocess':'process',fill:'#fffdf7',size:23});
for(const x of [350,950,1550])route([[x+225,1650],[x+375,1650]]);
text(1250,1720,'Incorrect PIN or cancelled unlock: remain blocked. Exit closes the app. Parent authentication follows the same setup / unlock rules.',{size:22});
text(65,1795,'CONNECTORS:  A = Home / navigation     B = Quick Check letter selection     C = Lessons selection',{size:24,weight:600,anchor:'start',color:blue});
text(65,1832,'Double-bordered box = summarized subprocess. Diamond = decision. Matching lettered circles join the flow without long crossing arrows.',{size:22,anchor:'start'});
text(65,1867,'Lesson practice is separate from mastery. Progress and preferences are saved on-device; failed writes show Retry. This is the application flow.',{size:22,anchor:'start'});
const svg='<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" width="2500" height="1900" viewBox="0 0 2500 1900" role="img" aria-labelledby="title desc"><title id="title">KidsPhonics Application Flowchart</title><desc id="desc">Source-verified startup, onboarding, lessons, Quick Check, Games, Progress, Parents, Settings and global daily-time-limit flow.</desc><defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="'+line+'"/></marker></defs><g font-family="Arial, Helvetica, sans-serif">'+parts.join('')+'</g></svg>';
fs.writeFileSync(path.join(out,'KidsPhonics_Application_Flowchart.svg'),svg);
const html='<!DOCTYPE html><html><head><meta charset="UTF-8"><title>KidsPhonics Application Flowchart</title><style>html,body{margin:0;padding:0;background:white}svg{display:block;width:100%;height:auto}@page{size:A3 landscape;margin:10mm}@media print{svg{width:100%;height:277mm}html,body{width:100%;height:auto}}</style></head><body>'+svg.replace(/^<\?xml[^>]+>/,'')+'</body></html>';
fs.writeFileSync(path.join(out,'KidsPhonics_Application_Flowchart.html'),html);console.log(JSON.stringify({svg:path.join(out,'KidsPhonics_Application_Flowchart.svg'),width:2500,height:1900,sourceFiles:sources.length}));
