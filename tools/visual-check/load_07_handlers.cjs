// Load real controller/commands with the installed SDK TypeScript compiler.
// Only SDK boundaries, clock and UI mounting are substituted.
const fs = require('fs'), path = require('path'), vm = require('vm');
const root = path.resolve(__dirname, '../..');
const sdk = path.join(process.env.DEVECO_SDK_HOME || 'E:/Program Files/Huawei/DevEco Studio/sdk',
  'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const ts = require(sdk);
const Engine = require('./verify_m1.cjs');
const definitions = ['knowledge','proficiency','charm','kindness','health'].map((key,i)=>({key,label:['知识','灵巧','魅力','体贴','健康'][i]}));
const cache = {};
const clock={current:'2026-09-30'};
function load(file) {
  if (cache[file]) return cache[file];
  let source = fs.readFileSync(path.join(root,'entry/src/main/ets',file+'.ets'),'utf8');
  if(file.endsWith('FocusView')) source=source.slice(source.indexOf('export class FocusClock'));
  if(file.endsWith('MorganaDialog')) source=source.slice(source.indexOf('export class DialogueFeedback')).split('\n@Component')[0];
  const code=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
  const exports={};cache[file]=exports;
  const req=id=>{
    if(id.includes('RoutineEngine')) return {RoutineEngine:Engine};
    if(id.includes('TraitAnalyzer')) return {TRAIT_DEFINITIONS:definitions,LocalTraitAnalyzer:class{async analyze(){return {hits:[{key:'knowledge'}]}}}};
    if(id.includes('DayUtil')) {
      const actual=load('common/DayUtil');
      return {...actual,dayKey:()=>clock.current,
        yesterdayKey:()=>actual.offsetDay(clock.current,-1),shiftDay:n=>actual.offsetDay(clock.current,n)};
    }
    if(id.includes('Theme'))return {FOCUS_SECONDS:1500,SEGMENT_COUNT:16};
    if(id.startsWith('@kit.'))return {};
    return load(path.posix.normalize(path.posix.join(path.posix.dirname(file),id)));
  };
  const context={exports,require:req,Date,console,setInterval,clearInterval,setTimeout,clearTimeout,
    Observed:ctor=>ctor,FOCUS_SECONDS:1500,SEGMENT_COUNT:16,PageActions:cache['common/PageActions']?.PageActions,
    MorganaEvent:{Undo:0,RankUp:1,Clear:2,Complete:3,Focus:4},MorganaFeedback:class{clear(){}}};
  vm.runInNewContext(code,context,{filename:file+'.ets'});return exports;
}
function extract(source,name){
  const start=source.search(new RegExp('^  (?:private )?(?:async )?'+name+'\\(','m'));
  if(start<0)throw Error('Missing production handler '+name);
  const text=source.slice(start), open=text.indexOf('{');let depth=0,quote='';
  for(let i=open;i<text.length;i++){
    const ch=text[i];
    if(quote){if(ch==='\\')i++;else if(ch===quote)quote='';continue;}
    if("'\"`".includes(ch)){quote=ch;continue;}
    if(ch==='{')depth++;
    if(ch==='}'&&!--depth)return text.slice(0,i+1);
  }
  throw Error('Unclosed production handler '+name);
}
const page=fs.readFileSync(path.join(root,'entry/src/main/ets/pages/Index.ets'),'utf8');
const core=['snapshot','adopt','mutate','showError','refreshToday','startDayTimer','clearDayTimer','onPageShow','onPageHide','switchPage','openWorkspace','closeWorkspace','onBackPress'];
const coreSource=core.map(n=>extract(page,n).replace(/dayKey\(\)/g,'this.dayKey()')).join('\n');
const code=ts.transpileModule('class Subject {\n'+coreSource+'\n}; globalThis.Subject=Subject;',
  {compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText;
const timers=new Map();let timerId=0;
const context={RoutineEngine:Engine,TRAIT_DEFINITIONS:definitions,FOCUS_SECONDS:1500,timers,
  setInterval:(callback,delay)=>{timers.set(++timerId,{callback,delay});return timerId},clearInterval:id=>timers.delete(id),
  makeTraitTotal:(key,score)=>({key,score}),makeHabitRecord:(id,day,title,subtitle,done,awardedTraits,assignedTraits,assignedPoints,awardedPoints)=>({id,day,title,subtitle,done,awardedTraits,assignedTraits,assignedPoints,awardedPoints})};
vm.createContext(context);vm.runInContext(code,context);
Object.defineProperty(context,'CommissionEngine',{get:()=>load('data/CommissionEngine').CommissionEngine});
const {PageActions}=load('common/PageActions');
for(const [file,group] of [['Queries','queries'],['DraftState','draft'],['LifecycleActions','lifecycle'],['DataActions','data'],['UiFeedback','feedback']]) {
  const Type=load('common/'+file)[file];
  for(const name of Object.getOwnPropertyNames(Type.prototype))if(name!=='constructor') {
    context.Subject.prototype[name]=function(...args){return this.actionsUI[group][name](...args)};
  }
}
context.Subject.prototype.updateCompletedCount=function(){return this.actionsUI.updateCompletedCount()};
context.Subject.prototype.formattedTime=function(){return this.actionsUI.focus.formattedTime()};
function subject(){
  clock.current='2026-09-30';
  const app=new context.Subject();
  app.state=new (load('common/RoutineState').RoutineState)();
  for(const key of Object.keys(app.state))Object.defineProperty(app,key,{get:()=>app.state[key],set:value=>{app.state[key]=value},configurable:true});
  Object.assign(app,{habits:[],pinnedTasks:[],traitTotals:definitions.map(t=>({key:t.key,score:0})),
    mainPage:'今日',pendingConfirm:'',workspace:'',workspaceStack:[],libraryFilter:'全部',composerOpen:false,newTaskDraft:'',draftSubtitle:'',draftTraits:['auto'],draftDay:'',draftDone:false,draftError:'',draftDateOpen:false,draftTraitOpen:false,actionMenuId:-1,historyLimit:20,completedCount:0,isFocusing:false,remainingSeconds:1500,actions:[],today:'2026-09-30',renderEpoch:0,dataError:'',revision:0,activeDay:'2026-09-30',dataReady:true,mutationBusy:false,store:{saveSnapshot:async s=>Engine.validate(s)},editingHabitId:-1,editingPinnedId:-1,draftPoints:[],editPoints:[],pinnedEditPoints:[],
    dayKey:()=>clock.current,yesterdayKey:()=>load('common/DayUtil').offsetDay(clock.current,-1),saveHabits:async()=>{},queueFeedback:()=>{},
    getUIContext:()=>({getFocusController:()=>({clearFocus:()=>{},requestFocus:id=>{app.focusRequested=id;}}),getPromptAction:()=>({showToast:message=>{app.lastToast=message.message;}})})});
  app.dayTimerId=-1;
  Object.assign(app,{historyLimit:14,optionsOpen:false,actionMenuLegacy:false,sheetMode:'actions',recordTargetDay:''});
  app.actionsUI=new PageActions(app);
  app.actionsUI.dialogue.queueFeedback=(...args)=>app.queueFeedback(...args);
  Object.defineProperty(app,'analyzer',{get:()=>app.actionsUI.analyzer,set:v=>app.actionsUI.analyzer=v});
  return app;
}
module.exports={subject,context,clock,load};
