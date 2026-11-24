// Optional release smoke test. See docs/members/tv2/README.md.
const {chromium} = require(process.env.TV2_PLAYWRIGHT || 'playwright');
const {randomUUID} = require('node:crypto');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const origin = 'http://127.0.0.1:8765';
const service = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:';
const runId = randomUUID().slice(0, 6);
const password = randomUUID();
const out = path.resolve('.local-data/evidence');
const record = process.argv.includes('--record');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const label = (p, name) => p.getByRole('button', {name, exact:true});

async function identity(method, body) {
  const res = await fetch(service+method+'?key=demo-key', {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const data = await res.json();
  assert.ok(res.ok, data.error?.message);
  return data;
}
async function database(u, method, key, body) {
  const url = new URL('/'+key+'.json', 'http://127.0.0.1:9000');
  url.searchParams.set('ns','demo-classroom-tv2-default-rtdb');
  url.searchParams.set('auth',u.idToken);
  const res = await fetch(url,{method,body:body===undefined?undefined:JSON.stringify(body)});
  const data = await res.json();
  assert.ok(res.ok, data?.error);
  return data;
}
async function fill(page, name, value) {
  await page.getByRole('textbox',{name}).click();
  await page.keyboard.press('Control+A');
  await page.keyboard.insertText(value);
}
async function send(page, message) {
  await fill(page,'Nhập tin nhắn…',message);
  await label(page,'Gửi tin nhắn').click();
}
async function expectText(page, text) {
  await page.getByText(text,{exact:false}).first().waitFor({timeout:20000});
}
async function caption(page, text, seconds=11) {
  if (!record) return;
  await page.evaluate(text=>{
    const el=document.getElementById('demo-caption')||document.body.appendChild(document.createElement('div'));
    el.id='demo-caption'; el.setAttribute('aria-hidden','true');
    Object.assign(el.style,{position:'fixed',top:'65px',right:'12px',maxWidth:'270px',padding:'10px 14px',background:'#153e37',color:'white',font:'16px/1.35 Arial',borderRadius:'10px',zIndex:9999,pointerEvents:'none',boxShadow:'0 3px 12px #0003'});
    el.textContent=text;
  },text);
  await sleep(seconds*1000);
  await page.evaluate(()=>document.getElementById('demo-caption')?.remove());
}
async function waitForSessions(user, count) {
  const end=Date.now()+20000;
  while(Date.now()<end){
    const sessions=await database(user,'GET','presence/'+user.localId+'/sessions');
    if(Object.keys(sessions || {}).length===count) return;
    await sleep(180);
  }
  throw Error('Presence did not reach '+count+' active session(s)');
}
async function connect(page, enabled) {
  await page.evaluate(enabled=>{
    const api=window.firebase_database;
    const db=api.getDatabase(window.firebase_core.getApp());
    (enabled?api.goOnline:api.goOffline)(db);
  },enabled);
}
async function run() {
  fs.mkdirSync(out,{recursive:true});
  const browser=await chromium.launch({channel:process.env.TV2_BROWSER || 'msedge',headless:true});
  const first=await browser.newContext({viewport:{width:880,height:720},...(record && {recordVideo:{dir:out,size:{width:880,height:720}}})});
  const second=await browser.newContext({viewport:{width:390,height:760}});
  const [p,q]=await Promise.all([first.newPage(),second.newPage()]);
  const video=p.video();
  const errors=[];
  for(const page of [p,q]) page.on('pageerror',err=>errors.push(err.message));
  const emailA='anh-'+runId+'@example.test',emailB='minh-'+runId+'@example.test';
  const nameA='Lan Anh',nameB='Minh Khang '+runId,roomName='Lập trình ứng dụng mobile '+runId;
  try {
    const b=await identity('signUp',{email:emailB,password,returnSecureToken:true});
    await identity('update',{idToken:b.idToken,displayName:nameB});
    await database(b,'PUT','profiles/'+b.localId,{uid:b.localId,displayName:nameB,avatarId:'avatar_minh'});
    await Promise.all([p.goto(origin),q.goto(origin)]);
    await caption(p,'Hai cửa sổ độc lập kết nối cùng Firebase Emulator. Mỗi sinh viên sử dụng một phiên đăng nhập.');
    await label(p,'Chưa có tài khoản? Đăng ký').click();
    await fill(p,'Email sinh viên',emailA); await fill(p,'Mật khẩu',password);
    await label(p,'Tạo tài khoản').click();
    await fill(p,'Tên hiển thị',nameA); await label(p,'Vào Study Chat').click();
    await p.getByRole('textbox',{name:'Tìm hội thoại'}).waitFor();
    const a=await identity('signInWithPassword',{email:emailA,password,returnSecureToken:true});
    await fill(q,'Email sinh viên',emailB);await fill(q,'Mật khẩu',password);await label(q,'Đăng nhập').click();
    await waitForSessions(a,1);await waitForSessions(b,1);
    await caption(p,'Tài khoản mới chưa có hội thoại. Chọn Bạn học để bắt đầu chat riêng.');
    await p.getByRole('tab',{name:'Bạn học'}).click();
    await fill(p,'Tìm sinh viên',nameB);
    await caption(p,'Danh bạ truyền UID cho module TV2. Tên hiển thị chỉ dùng để chọn người.');
    await label(p,'Nhắn tin với '+nameB).click();
    await p.getByRole('textbox',{name:'Nhập tin nhắn…'}).waitFor();
    await caption(p,'Chat riêng có đúng hai thành viên. Chấm trạng thái lấy từ những phiên Firebase đang kết nối.');
    const hello='Khang ơi, nhóm mình ôn StreamBuilder lúc mấy giờ?';
    const reply='19 giờ nhé. Mình sẽ chuẩn bị ví dụ cho phần nhận tin.';
    await send(p,hello);
    await q.getByRole('button',{name:new RegExp(hello.slice(0,12))}).click();
    await expectText(q,hello);
    await send(q,reply);await expectText(p,reply);
    await p.screenshot({path:path.join(out,'chat.png')});
    await caption(p,'Tin thứ hai đến từ tài khoản ở cửa sổ còn lại. Cả hai tin dùng thời gian của Firebase.');
    const extra=await first.newPage();await extra.goto(origin);await waitForSessions(a,2);
    await extra.close();await waitForSessions(a,1);
    await caption(p,'Đã đóng một tab của Lan Anh. Kết nối còn lại vẫn giữ tài khoản ở trạng thái trực tuyến.');
    await connect(p,false);await expectText(p,'Đang xem tin đã lưu');
    assert.equal(await label(p,'Gửi tin nhắn').isDisabled(),true);
    await expectText(p,reply);
    await p.screenshot({path:path.join(out,'offline.png')});
    await caption(p,'Đã ngắt kết nối RTDB. SQLite hiển thị các tin đã nhận và nút gửi bị khóa.');
    const later='Mình đã cập nhật đề cương ôn tập rồi nhé.';
    await send(q,later);await expectText(q,later);
    await connect(p,true);await expectText(p,later);
    await caption(p,'Sau khi kết nối lại, tin gửi trong lúc Lan Anh ngoại tuyến tự xuất hiện.');
    await label(p,'Back').click();await p.getByRole('tab',{name:'Phòng học'}).click();
    await label(p,'Tạo phòng').click();
    await p.getByRole('textbox').last().click();await p.keyboard.insertText(roomName);await label(p,'Lưu').click();
    await p.getByRole('button',{name:new RegExp(roomName)}).first().waitFor();
    await caption(p,'Phòng học mới có mã riêng. Người tạo là chủ phòng và là thành viên đầu tiên.');
    const row=p.getByRole('button',{name:new RegExp(roomName)}).first();
    await row.click();
    await p.getByRole('textbox',{name:'Nhập tin nhắn…'}).waitFor();
    await label(q,'Back').click();await q.getByRole('tab',{name:'Phòng học'}).click();
    await q.getByRole('button',{name:new RegExp(roomName)}).first().click();
    const groupText='Nhóm mình dùng phòng này để trao đổi bài thực hành tuần 6.';
    await send(p,groupText);await expectText(q,groupText);
    await send(q,'Mình đã vào phòng. Hẹn cả nhóm lúc 19 giờ!');await expectText(p,'Hẹn cả nhóm');
    await caption(p,'Cùng một màn chat phục vụ cả phòng học. Người vừa tham gia nhận tin ngay.');
    const rooms=await database(a,'GET','rooms');const cid=Object.keys(rooms).find(k=>rooms[k].roomName===roomName);
    await database(a,'PUT','roomNotices/'+cid,{roomId:cid,content:'Ôn tập lúc 19 giờ · Chủ đề StreamBuilder',updatedBy:a.localId,updatedAt:{'.sv':'timestamp'}});
    await expectText(p,'Ôn tập lúc 19 giờ');await expectText(q,'Ôn tập lúc 19 giờ');
    await q.screenshot({path:path.join(out,'group-mobile.png')});
    await caption(p,'Thông báo ghim nằm trên lịch sử tin. Chủ phòng được chỉnh sửa, thành viên được xem.');
    await label(p,'Back').click();await p.getByRole('tab',{name:'Tin nhắn'}).click();
    await p.getByRole('button',{name:new RegExp(roomName)}).first().waitFor();
    await p.screenshot({path:path.join(out,'list.png')});
    await caption(p,'Danh sách ghép DM và phòng học, sắp theo tin cuối. Dùng các bộ lọc để tìm nhanh.');
    await p.getByRole('checkbox',{name:'Chat riêng'}).click();
    await caption(p,'Bộ lọc Chat riêng giữ lại hội thoại hai người. Cache danh sách và tin nhắn đều có khóa chủ tài khoản.');
    await label(p,'Đổi sáng / tối').click();await p.reload();await p.getByRole('textbox',{name:'Tìm hội thoại'}).waitFor();
    await p.getByRole('button',{name:new RegExp(roomName)}).first().waitFor();
    await p.screenshot({path:path.join(out,'dark.png')});
    await caption(p,'Chế độ tối và phiên đăng nhập được khôi phục sau khi tải lại trang.');
    await label(p,'Tài khoản').click();await p.getByText('Đăng xuất',{exact:true}).click();
    await label(p,'Đăng nhập').waitFor();await waitForSessions(a,0);
    await caption(p,'Đăng xuất đóng listener và dọn presence. Bản ghi đã lưu được phân vùng theo UID.',12);
    assert.deepEqual(errors,[]);
    console.log('PASS · registration, DM both ways, multitab presence, SQLite offline, reconnect, group, pin, theme, session and sign-out');
  } catch(e) {
    console.error('A',await p.locator('body').ariaSnapshot(),'B',await q.locator('body').ariaSnapshot());
    throw e;
  } finally {
    await second.close();await first.close();await browser.close();
  }
  if(record) await video.saveAs(path.join(out,'demo-tv2.webm'));
}
run().catch(e=>{console.error(e);process.exitCode=1;});

