const vm=require('vm'),fs=require('fs'),assert=require('assert');
(async()=>{const calls=[],releases=[];const context={window:{},fetch:(url,o)=>{calls.push(JSON.parse(o.body));return new Promise(r=>releases.push(r));}};
vm.runInNewContext(fs.readFileSync('/workspace/work/remote-input-queue.js','utf8'),context);
const send=context.flipperSend;const down=send('ok',true),up=send('ok',false);
await new Promise(setImmediate);assert.strictEqual(calls.length,1);assert.strictEqual(calls[0].down,true);
releases.shift()({ok:true});await down;await new Promise(setImmediate);assert.strictEqual(calls.length,2);assert.strictEqual(calls[1].down,false);
releases.shift()({ok:true});await up;console.log('PASS: key-up waits until key-down request completes');})().catch(e=>{console.error(e);process.exit(1)});
