//QEMU_INPUT_QUEUE_V1
let q=Promise.resolve();function flipperSend(key,down){return q=q.then(()=>fetch('input',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key,down})})).catch(()=>{});}
