#!/usr/bin/env python3
"""Patch embedded browser input ordering without changing ELF offsets."""
from pathlib import Path
import os,shutil,sys
p=Path(sys.argv[1] if len(sys.argv)>1 else '/usr/bin/flipctl')
data=p.read_bytes();marker=b'QEMU_INPUT_QUEUE_V1'
if marker in data:
 print('Remote input queue already installed');sys.exit(0)
start=b'/// Post one key event. The same endpoint the panel\'s own buttons feed.\n'
end=b'/// Wire a set of buttons carrying'
a=data.find(start)
if a<0 or data.count(start)!=1:raise SystemExit('Unrecognized flipctl; input patch skipped')
b=data.find(end,a)
if b<0 or b-a>2048:raise SystemExit('Unrecognized remote input block')
new=b'''//QEMU_INPUT_QUEUE_V1
let q=Promise.resolve();function flipperSend(key,down){return q=q.then(()=>fetch('input',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key,down})})).catch(()=>{});}
'''
if len(new)>b-a:raise SystemExit('Input patch exceeds original block')
patched=data[:a]+new+b' '*(b-a-len(new))+data[b:]
assert len(patched)==len(data)
tmp=p.with_name(p.name+'.qemu-input.tmp');shutil.copy2(p,tmp);tmp.write_bytes(patched);os.replace(tmp,p)
print('Installed ordered browser input; ELF size and offsets preserved')
