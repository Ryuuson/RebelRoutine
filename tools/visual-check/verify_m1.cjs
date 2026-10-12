const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert/strict');
const root=path.resolve(__dirname,'../..');
function erase(s){return s.replace(/^import .*;\r?\n/gm,'').replace(/^export \{.*;\r?\n/gm,'').replace(/export (?=class)/g,'').replace(/\b(private|readonly)\s+/g,'').replace(/(\w+)\?(?=\s*:)/g,'$1').replace(/:\s*(?:Promise<[^>]+>|(?:common\.UIAbilityContext|preferences\.Preferences|relationalStore\.(?:RdbStore|ResultSet)|picker\.(?:DocumentViewPicker|DocumentSaveOptions|DocumentSelectOptions)|fs\.File|Uint8Array|ArrayBuffer|string|number|boolean|void|Date|Error|HabitRecord|ActionRecord|PinnedTask|TraitPoints|TraitTotal|TraitDefinition|TraitHit|LocalTraitAnalyzer|RoutineSnapshot|RoutineBackup)(?:\[\])*(?:\s*\|\s*undefined)?)(?![\w.])/g,'').replace(/\s+as (?:HabitRecord|PinnedTask|ActionRecord|TraitTotal|RoutineSnapshot|RoutineBackup)(?:\[\])*/g,'');}
let rows=new Map(),transaction,fail=false;const files=new Map(),legacy=new Map();
const db={executeSql:async(sql,a)=>{if(sql.startsWith('CREATE'))return;rows.set(a[0],a[1]);if(fail)throw Error('disk failure');},querySql:async(sql,a)=>({goToFirstRow:()=>rows.has(a[0]),getString:()=>rows.get(a[0]),close:()=>{}}),beginTransaction:()=>{transaction=new Map(rows)},commit:()=>{transaction=undefined},rollBack:()=>{rows=transaction}};
const defs=['knowledge','proficiency','charm','kindness','health'].map(key=>({key}));
const ctx={Date,console,ArrayBuffer,Uint8Array,util:{TextDecoder:{create:()=>({decodeToString:b=>new TextDecoder('utf-8',{fatal:true}).decode(b)})}},TRAIT_DEFINITIONS:defs,LocalTraitAnalyzer:class{async analyzeLegacy(){return {hits:[{key:'proficiency'}]}}},relationalStore:{SecurityLevel:{S1:1},getRdbStore:async()=>db},preferences:{getPreferences:async()=>({get:async(k,d)=>legacy.has(k)?legacy.get(k):d,getAll:async()=>Object.fromEntries(legacy),put:async(k,v)=>legacy.set(k,v),flush:async()=>{}})},fs:{OpenMode:{READ_ONLY:0,READ_WRITE:1,CREATE:2,TRUNC:4},accessSync:p=>files.has(p),openSync:p=>{ctx.fileOffset=0;return {fd:p}},writeSync:(p,v)=>files.set(p,v),fsyncSync:()=>{},closeSync:()=>{},statSync:p=>({size:Buffer.byteLength(files.get(p))}),readSync:(p,b)=>{const data=Buffer.from(files.get(p));const n=Math.min(b.byteLength,13,data.length-ctx.fileOffset);new Uint8Array(b).set(data.subarray(ctx.fileOffset,ctx.fileOffset+n));ctx.fileOffset+=n;return n},readTextSync:()=>{throw Error('URI must use fd')}},picker:{DocumentSaveOptions:class{},DocumentSelectOptions:class{},DocumentViewPicker:class{async save(){return ctx.saveUris??[]}async select(){return ctx.selectUris??[]}}}};
vm.createContext(ctx);
const ts=require(path.join(process.env.DEVECO_SDK_HOME || 'E:/Program Files/Huawei/DevEco Studio/sdk',
  'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript'));
const noteModule={};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(root,'entry/src/main/ets/data/NoteValidation.ets'),'utf8'),
  {compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:noteModule,require:()=>({})});
ctx.NoteValidation=noteModule.NoteValidation;
Object.defineProperties(ctx,{
  CommissionValidation:{get:()=>require('./load_07_handlers.cjs').load('data/CommissionValidation').CommissionValidation},
  CommissionEngine:{get:()=>require('./load_07_handlers.cjs').load('data/CommissionEngine').CommissionEngine}
});
for(const name of ['RoutineEngine','RoutineStore'])vm.runInContext(erase(fs.readFileSync(path.join(root,'entry/src/main/ets/data/'+name+'.ets'),'utf8'))+'\nglobalThis.'+name+'='+name,ctx);
module.exports=ctx.RoutineEngine;
const E=ctx.RoutineEngine,json=x=>JSON.stringify(x),equal=(a,b)=>assert.equal(json(a),json(b));
const original={version:2,revision:0,activeDay:'2026-09-30',habits:[{id:1,day:'2026-09-29',title:'复习电路',subtitle:'',done:false,assignedTraits:['knowledge','proficiency'],assignedPoints:[{key:'knowledge',points:3},{key:'proficiency',points:2}]}],pinnedTasks:[],actions:[],traitTotals:defs.map(t=>({key:t.key,score:0}))};
const score=(s,k)=>s.traitTotals.find(t=>t.key===k).score;
(async()=>{
assert.equal(E.bucket(original.habits[0],original.activeDay),'待处理');assert.ok(E.validDay('2028-02-29'));assert.ok(!E.validDay('2026-02-29'));assert.ok(!E.validDay('2026-13-01'));
let s=E.complete(original,1,original.activeDay,['knowledge','proficiency'],original.habits[0].assignedPoints);
assert.equal(s.habits[0].day,'2026-09-29');assert.equal(s.habits[0].activityDay,'2026-09-30');assert.equal(score(s,'knowledge'),3);assert.equal(score(s,'proficiency'),2);assert.equal(original.habits[0].done,false);
s=E.lifecycle(E.lifecycle(s,1,'delete'),1,'delete');assert.equal(score(s,'knowledge'),0);
s=E.lifecycle(E.lifecycle(s,1,'restore'),1,'restore');assert.equal(score(s,'knowledge'),3);
s.habits[0].archived=true;assert.equal(E.bucket(s.habits[0],s.activeDay),'已完成');assert.equal(score(s,'knowledge'),3);s=E.lifecycle(s,1,'reopen');
assert.throws(()=>E.lifecycle(s,1,'archive'));assert.throws(()=>E.lifecycle(s,1,'cancel'));
let edit=E.clone(s).habits[0];edit.activityDay='2026-09-28';edit.awardedTraits=['knowledge'];edit.awardedPoints=[{key:'knowledge',points:7}];s=E.edit(s,edit);assert.equal(score(s,'knowledge'),7);assert.equal(score(s,'proficiency'),0);
const inconsistent=E.clone(s);inconsistent.traitTotals.find(t=>t.key==='knowledge').score=0;assert.equal(score(E.edit(inconsistent,inconsistent.habits[0]),'knowledge'),0);assert.equal(score(E.lifecycle(E.lifecycle(inconsistent,1,'delete'),1,'restore'),'knowledge'),0);
s=E.complete(s,1,s.activeDay,[],[]);assert.equal(score(s,'knowledge'),0);assert.equal(s.habits[0].activityDay,undefined);
s.habits[0].cancelled=true;assert.equal(E.bucket(s.habits[0],s.activeDay),'已取消');s=E.lifecycle(s,1,'reopen');assert.equal(E.bucket(s.habits[0],s.activeDay),'待处理');s.habits[0].day=undefined;assert.equal(E.bucket(s.habits[0],s.activeDay),'未安排');s.habits[0].day='2027-01-01';assert.equal(E.bucket(s.habits[0],s.activeDay),'未来');
assert.equal(E.lifecycle(E.lifecycle(s,1,'delete'),1,'purge').habits.length,0);
equal(E.readBackup(json({format:'RebelRoutine',exportedAt:Date.now(),state:s})),s);
let csv=E.clone(s);csv.habits[0].title='中文,"标题"\n第二行';assert.ok(E.csv(csv).includes('"中文,""标题""\n第二行"'));assert.ok(E.csv(csv).startsWith('\uFEFF'));
for(const bad of [null,{}, {...original,version:99},{...original,activeDay:'bad'},{...original,habits:[{...original.habits[0],assignedPoints:[{key:'knowledge',points:-1}]}]},{...original,traitTotals:[{key:'knowledge',score:'3'}]},{...original,habits:[original.habits[0],original.habits[0]]}])assert.throws(()=>E.validate(bad));
legacy.set('habits',json([{id:10,title:'手工',subtitle:'',done:true}]));legacy.set('active_day','2026-09-29');legacy.set('traits',json([{key:'proficiency',score:8}]));
const store=new ctx.RoutineStore({filesDir:'/private'});const migrated=await store.loadSnapshot('2026-09-30');
assert.equal(migrated.habits[0].activityDay,'2026-09-29');assert.equal(migrated.habits[0].inferredDay,true);assert.equal(migrated.habits[0].createdAt,undefined);assert.equal(migrated.pinnedTasks.length,1);assert.equal(score(migrated,'proficiency'),8);assert.equal(migrated.habits[0].awardedPoints[0].points,1);assert.equal(files.get('/private/legacy-preferences-before-m1.json'),json(Object.fromEntries(legacy)));
equal(await store.loadSnapshot('2026-10-01'),migrated);await store.replaceSnapshot(original);equal(await store.loadSnapshot('2026-09-30'),original);equal(await store.previousRestore(),migrated);
// Spy on the actual production boundaries, including the object passed between them.
const order=[],realMigrate=E.migrate,realValidate=E.validate;let migratedInput;
E.migrate=function(raw){order.push('migrate');migratedInput=realMigrate.call(E,raw);return migratedInput};
E.validate=function(raw){if(raw===migratedInput)order.push('validate migrated');return realValidate.call(E,raw)};
try {
  E.readBackup(json({format:'RebelRoutine',exportedAt:Date.now(),state:original}));
  assert.deepEqual(order,['migrate','validate migrated']);order.length=0;
  await store.readRow(1);assert.deepEqual(order,['migrate','validate migrated']);
} finally {E.migrate=realMigrate;E.validate=realValidate;}
ctx.saveUris=[];assert.equal(await store.exportFile(migrated,false),false);
ctx.saveUris=['/exports/full.json'];assert.equal(await store.exportFile(migrated,false),true);equal(E.readBackup(files.get('/exports/full.json')),migrated);
ctx.saveUris=['/exports/records.csv'];assert.equal(await store.exportFile(migrated,true),true);assert.ok(files.get('/exports/records.csv').startsWith('\uFEFF'));
ctx.selectUris=[];assert.equal(await store.selectBackup(),undefined);
ctx.selectUris=['/exports/full.json'];equal(await store.selectBackup(),migrated);
files.set('/exports/bad.json','{"format":"wrong"}');ctx.selectUris=['/exports/bad.json'];await assert.rejects(()=>store.selectBackup());equal(await store.loadSnapshot('2026-09-30'),migrated);
const before=new Map(rows);fail=true;await assert.rejects(()=>store.saveSnapshot(original));equal(Array.from(rows),Array.from(before));await assert.rejects(()=>store.replaceSnapshot(original));equal(Array.from(rows),Array.from(before));fail=false;
rows=new Map();legacy.set('habits','bad json');await assert.rejects(()=>new ctx.RoutineStore({filesDir:'/corrupt'}).loadSnapshot('2026-09-30'));assert.equal(rows.has(1),false);assert.equal(legacy.get('habits'),'bad json');
const early=new Date(2026,9,1,1,2);const local=E.clone(original);local.habits[0].createdAt=early.getTime();local.actions=[{id:91,text:'凌晨记录',summary:'',traits:[],createdAt:early.getTime()}];assert.ok(E.csv(local).includes('2026-10-01 01:02'));assert.ok(E.csv(local).includes('"2026-10-01","否"'));assert.equal(E.migrate(original),original);assert.throws(()=>E.migrate({...original,version:3}));
rows=new Map();legacy.set('habits',json([{id:12,title:'手工',subtitle:'',day:'2026-09-28',activityDay:'2026-09-27',inferredDay:false,done:true,assignedTraits:['kindness'],assignedPoints:[{key:'kindness',points:4}]}]));const kept=await store.loadSnapshot('2026-09-30');assert.equal(kept.habits[0].activityDay,'2026-09-27');assert.equal(kept.habits[0].inferredDay,false);equal(kept.habits[0].awardedTraits,['kindness']);assert.equal(kept.habits[0].awardedPoints[0].points,4);
rows.set(1,'{broken raw JSON');await assert.rejects(()=>store.loadSnapshot('2026-09-30'));ctx.saveUris=['/exports/raw.json'];assert.equal(await store.exportRaw(),true);assert.equal(files.get('/exports/raw.json'),'{broken raw JSON');await store.replaceSnapshot(original);equal(await store.loadSnapshot('2026-09-30'),original);assert.equal(rows.get(2),'{broken raw JSON');
const upgraded=await store.loadM2Snapshot('2026-09-30');assert.ok(upgraded.m2);equal(upgraded.traitTotals,original.traitTotals);
equal(JSON.parse(files.get('/private/snapshot-before-m2.json')),original);equal(await store.loadM2Snapshot('2026-10-01'),upgraded);
await store.replaceSnapshot(original);const undoM2=await store.previousM2Restore();equal(undoM2,upgraded);
rows.set(1,json(original));const preUpgrade=new Map(rows);fail=true;
await assert.rejects(()=>store.loadM2Snapshot('2026-10-01'));equal(Array.from(rows),Array.from(preUpgrade));fail=false;
const retried=await store.loadM2Snapshot('2026-10-01');equal(retried.traitTotals,original.traitTotals);equal(retried.habits,original.habits);
equal(await store.loadM2Snapshot('2026-10-01'),retried);
// Notes use the same atomic snapshot row and full backup; old backups may omit them.
const withNotes=E.clone(retried);withNotes.notes=[{id:88,title:'随笔',body:'中文正文\n"第二行"',createdAt:10,updatedAt:11}];
await store.saveSnapshot(withNotes);equal((await store.loadM2Snapshot('2026-10-03')).notes,withNotes.notes);
ctx.saveUris=['/exports/notes.json'];await store.exportFile(withNotes,false);
ctx.selectUris=ctx.saveUris;equal((await store.selectBackup()).notes,withNotes.notes);
await store.replaceSnapshot(original);equal((await store.previousM2Restore()).notes,withNotes.notes);
const noteRows=new Map(rows);fail=true;await assert.rejects(()=>store.saveSnapshot({...withNotes,notes:[]}));
equal(Array.from(rows),Array.from(noteRows));fail=false;
console.log('PASS: production transitions, M1/M2 migration, backup preservation, CSV, restore undo and transaction rollback. SDK calls mocked.');
})().catch(e=>{console.error(e);process.exitCode=1});


