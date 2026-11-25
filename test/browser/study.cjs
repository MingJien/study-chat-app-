// Run against the local F5 preview after tools/demo_accounts.py.
const {chromium} = require(process.env.TV2_PLAYWRIGHT || 'playwright');
const assert = require('node:assert/strict');

const name = (page, value) => page.getByLabel(value, {exact:true})
  .or(page.getByText(value, {exact:true})).first();
async function click(page, value) {
  await page.bringToFront();
  await name(page,value).click();
}
async function messageVisible(page, value) {
  await page.getByText(value,{exact:true}).or(
    page.getByRole('group',{name:new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'))})
  ).first().waitFor();
}
async function fill(page, label, value) {
  await page.bringToFront();
  const field=page.getByRole('textbox',{name:label,exact:true});
  for(let attempt=0;attempt<3;attempt++){
    await field.click();
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
    await page.keyboard.press('Control+A');
    await page.keyboard.insertText(value);
    if(await field.inputValue()===value)return;
  }
  throw Error('Field did not accept text: '+label);
}
async function openChat(page,peer){
  await page.getByRole('tab',{name:'Bạn học'}).click();
  await fill(page,'Tìm sinh viên',peer);
  await click(page,'Nhắn tin với '+peer);
}
async function actionOnLast(page, action){
  await page.bringToFront();
  await page.getByRole('button',{name:'Tùy chọn tin nhắn'}).last().click();
  await click(page,action);
}
async function run(){
  const browser=await chromium.launch({channel:process.env.TV2_BROWSER||'msedge',headless:true});
  const stamp=Date.now().toString(36);
  const question='Cấu trúc nào lấy phần tử vào sau ra trước? '+stamp;
  const answer='Ngăn xếp · '+stamp;
  try{
    const a=await browser.newPage({viewport:{width:890,height:840}});
    const b=await browser.newPage({viewport:{width:410,height:820}});
    await Promise.all([a.goto('http://127.0.0.1:8765'),b.goto('http://127.0.0.1:8765')]);
    await click(a,'Minh An');await click(b,'Hải Bình');
    await openChat(a,'Hải Bình');await openChat(b,'Minh An');
    await click(a,'Thêm vào tin nhắn');await click(a,'Đặt câu hỏi học tập');
    await fill(a,'Nhập tin nhắn…',question);await click(a,'Gửi tin nhắn');
    await messageVisible(b,question);
    await actionOnLast(b,'Trả lời');
    await fill(b,'Nhập tin nhắn…',answer);await click(b,'Gửi tin nhắn');
    await messageVisible(a,answer);
    await actionOnLast(a,'Chốt làm đáp án cho câu hỏi');
    await click(a,'Công cụ hội thoại');await click(a,'Thẻ tự ôn');
    await name(a,'Lật xem đáp án').waitFor();
    let found=false;
    while(true){
      const targetCard=await name(a,question).isVisible();
      await click(a,'Lật xem đáp án');
      await name(a,'Đã nhớ').waitFor();
      if(targetCard){
        await name(a,answer).waitFor();
        found=true;
      }
      await click(a,'Đã nhớ');
      await name(a,'Lật xem đáp án').or(name(a,'Hoàn tất')).first().waitFor();
      if(await name(a,'Hoàn tất').isVisible())break;
    }
    assert.ok(found,'Deck should contain the accepted answer');
    await click(a,'Hoàn tất');
    await actionOnLast(b,'Thu hồi với mọi người');
    await click(b,'Thu hồi');await messageVisible(a,'Tin nhắn đã thu hồi');
    assert.equal(await a.getByText(answer,{exact:true}).count(),0);
    const filename='de-cuong-'+stamp+'.txt';
    const bytes=Buffer.from('Nội dung ôn tập '+stamp,'utf8');
    await click(a,'Thêm vào tin nhắn');
    const chooser=a.waitForEvent('filechooser');
    await click(a,'Gửi tệp hoặc ảnh · tối đa 1 MiB');
    await (await chooser).setFiles({name:filename,mimeType:'text/plain',buffer:bytes});
    await messageVisible(b,filename);
    const downloading=b.waitForEvent('download');
    await b.getByRole('button',{name:'Tải tệp',exact:true}).last().click();
    const download=await downloading;
    assert.equal(download.suggestedFilename(),filename);
    const downloaded=[];
    for await(const chunk of await download.createReadStream()) downloaded.push(chunk);
    assert.deepEqual(Buffer.concat(downloaded),bytes);
    console.log('PASS: quick accounts, question, reply, accepted answer, revision, recall and file round trip across browsers');
  }finally{await browser.close();}
}
module.exports={click,fill,messageVisible,actionOnLast};
if(require.main===module) run().catch(err=>{console.error(err);process.exitCode=1;});
