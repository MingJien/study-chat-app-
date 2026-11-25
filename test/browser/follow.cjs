const {chromium}=require(process.env.TV2_PLAYWRIGHT || 'playwright');
const {click,fill,messageVisible,actionOnLast}=require('./study.cjs');
const origin='http://127.0.0.1:8765';
const back=p=>p.getByRole('button',{name:/^Back(?: Back)?$/}).click();

async function run(){
  const browser=await chromium.launch({channel:process.env.TV2_BROWSER || 'msedge'});
  const pages=[];
  const stamp=Date.now().toString(36);
  const room='Thực hành '+stamp, question='Khi nào hủy stream? '+stamp;
  const answer='Hủy khi đóng màn hình '+stamp;
  try{
    for(const user of ['Minh An','Hải Bình','Lan Chi']){
      const p=await browser.newPage({viewport:{width:520,height:860}});
      pages.push(p);
      await p.goto(origin);
      await click(p,user);
      await p.getByRole('tab',{name:'Phòng học'}).click();
    }
    const [a,b,c]=pages;
    await click(a,'Tạo phòng');await fill(a,'',room);await click(a,'Lưu');
    for(const p of pages){
      await p.bringToFront();
      await fill(p,'Tìm phòng học',room);
      await p.getByRole('button',{name:new RegExp(room)}).first().click();
      await p.getByRole('textbox',{name:'Nhập tin nhắn…'}).waitFor();
    }
    await click(a,'Thêm vào tin nhắn');await click(a,'Đặt câu hỏi học tập');
    await fill(a,'Nhập tin nhắn…',question);await click(a,'Gửi tin nhắn');
    await click(c,'Mình cũng đang bí');
    await messageVisible(a,'1 bạn cùng vướng');
    await back(c);
    await actionOnLast(b,'Trả lời');
    await fill(b,'Nhập tin nhắn…',answer);await click(b,'Gửi tin nhắn');
    await messageVisible(a,answer);await actionOnLast(a,'Chốt làm đáp án cho câu hỏi');
    const notice=c.getByRole('button',{name:/Câu bạn theo dõi đã có lời giải/});
    await notice.click();
    await messageVisible(c,answer);
    await click(c,'Hẹn ngày ôn');await click(c,'Lưu lịch ôn');
    await click(c,'Tự ôn câu này');await click(c,'Lật xem lời giải');
    await messageVisible(c,answer);
    await c.reload();
    await c.getByRole('button',{name:'Câu mình đang theo dõi'}).click();
    const followedRow=c.getByRole('button',{name:new RegExp(stamp)});
    await followedRow.click();
    await c.getByText(/Ngày ôn riêng của bạn/).waitFor();
    await actionOnLast(b,'Thu hồi với mọi người');await click(b,'Thu hồi');
    await c.getByText('Đang chờ người hỏi chốt lời giải.').waitFor();
    await click(c,'Bỏ theo dõi câu hỏi');
    await c.getByRole('heading',{name:'Câu mình đang theo dõi'}).waitFor();
    await followedRow.waitFor({state:'detached'});
    console.log('PASS · three students, follow, live solution, private review, reload, recall and unfollow');
  }catch(e){
    for(const p of pages) console.error((await p.locator('body').ariaSnapshot()).slice(-1400));
    throw e;
  }finally{await browser.close();}
}
run().catch(e=>{console.error(e);process.exitCode=1;});
