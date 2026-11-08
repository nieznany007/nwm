const {chromium}=require('/opt/codex/cua_node/lib/node_modules/playwright');
const fs=require('fs');const {execFileSync}=require('child_process');
(async()=>{const b=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const p=await b.newPage({viewport:{width:1100,height:800}});await p.goto('http://127.0.0.1:8898/',{waitUntil:'domcontentloaded'});
async function read(name){await p.waitForTimeout(2500);const url=await p.locator('canvas').first().evaluate(c=>c.toDataURL());const path='/workspace/work/'+name+'.png';fs.writeFileSync(path,Buffer.from(url.split(',')[1],'base64'));execFileSync('python3',['-c',"from PIL import Image; import sys; p=sys.argv[1]; im=Image.open(p).convert('L').point(lambda x: 255 if x>100 else 0); im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST).save(p)",path]);return execFileSync('tesseract',[path,'stdout','--psm','6'],{encoding:'utf8',stdio:['ignore','pipe','ignore']});}
await p.keyboard.press('Enter'); await p.waitForTimeout(3000); let before=await read('hello-before');if(!/Hello.*Flipper One/i.test(before))throw Error('Hello UI absent: '+before);
await p.keyboard.press('Enter');let after=await read('hello-after');
if(!/Hello.*Flipper One/i.test(after))throw Error('Hello title disappeared');
execFileSync('python3',['-c',"from PIL import Image,ImageChops; a=Image.open('/workspace/work/hello-before.png').crop((920,155,1010,213)); b=Image.open('/workspace/work/hello-after.png').crop((920,155,1010,213)); assert ImageChops.difference(a,b).getbbox(), 'Counter pixels unchanged'"]);
await p.screenshot({path:'/workspace/work/hello-final.png'});console.log('PASS: Hello title visible before and after Enter; counter region changed');await b.close();})().catch(e=>{console.error(e);process.exit(1)});
