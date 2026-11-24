import assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomUUID } from 'node:crypto';

const base = 'http://127.0.0.1:9000';
const namespace = 'demo-classroom-tv2-default-rtdb';
const stamp = { '.sv': 'timestamp' };
const unique = randomUUID();
function url(path, user, query = {}) {
  const endpoint = new URL('/' + path + '.json', base);
  endpoint.search = new URLSearchParams({ns: namespace, ...(user && {auth:user.idToken}), ...query});
  return endpoint;
}
async function request(user, method, path, body, query) {
  return fetch(url(path, user, query), {method, headers:{'Content-Type':'application/json'}, body: body === undefined ? undefined : JSON.stringify(body)});
}
async function ok(response) {
  const res = await response;
  const body = await res.text();
  assert.equal(res.status, 200, body);
  return JSON.parse(body);
}
async function denied(response) {
  assert.ok([401,403].includes((await response).status), 'Expected permission denial');
}
async function student(name) {
  const res=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:name+'-'+unique+'@example.test',password:randomUUID(),returnSecureToken:true})});
  const user=await ok(res);
  await ok(request(user,'PUT','profiles/'+user.localId,{uid:user.localId,displayName:name}));
  return user;
}
test('TV2 · Firebase Auth, RTDB và quyền theo hội thoại',async t=>{
  const [a,b,c]=await Promise.all(['An','Binh','Chi'].map(student));
  const [first,second]=[a.localId,b.localId].sort();
  const id='dm_'+first+'|'+second, room='room_'+unique;
  const dm={['directChats/'+id]:{first,second},['userDirectChats/'+first+'/'+id]:true,['userDirectChats/'+second+'/'+id]:true};
  const list={orderBy:'"createdAt"',limitToLast:'30'};
  const msg=(sender,content)=>({senderId:sender.localId,content,createdAt:stamp});
  await t.test('T05/T06 · hai chiều đồng thời dùng chung hội thoại và hai chỉ mục',async()=>{
    await Promise.all([a,b].map(u=>ok(request(u,'PATCH','',dm))));
    for(const uid of [a,b]) assert.equal((await ok(request(uid,'GET','userDirectChats/'+uid.localId)))[id],true);
    await denied(request(c,'GET','directChats/'+id));
    await denied(request(c,'PUT','userDirectChats/'+c.localId+'/'+id,true));
  });
  await t.test('T07/T09 · hai người gửi đồng thời, stream nhận sự kiện và thứ tự ổn định',async()=>{
    const ctl=new AbortController();
    try {
      const feed=await fetch(url('messages/'+id,b,list),{headers:{Accept:'text/event-stream'},signal:ctl.signal});
      assert.equal(feed.status,200);
      const reader=feed.body.getReader(), decoder=new TextDecoder();
      await reader.read();
      await Promise.all([[a,'m1'],[b,'m2']].map(([u,k])=>ok(request(u,'PUT','messages/'+id+'/'+k,msg(u,k)))));
      const timer=setTimeout(()=>ctl.abort(),5000);
      try {
        let text='';
        while(!text.includes('m1') || !text.includes('m2')) text+=decoder.decode((await reader.read()).value);
      } finally {clearTimeout(timer);}
      const messages=await ok(request(b,'GET','messages/'+id,undefined,list));
      assert.equal(Object.keys(messages).length,2);
      assert.equal(typeof messages.m1.createdAt,'number');
    } finally {ctl.abort();}
  });
  await t.test('T08/T16 · kiểm tra quyền, độ dài, thời gian, tính bất biến và giới hạn truy vấn',async()=>{
    for(const value of ['', ' \t\n ', 'x'.repeat(501)]) await denied(request(a,'PUT','messages/'+id+'/invalid',msg(a,value)));
    await ok(request(a,'PUT','messages/'+id+'/max',msg(a,'x'.repeat(500))));
    await denied(request(a,'PUT','messages/'+id+'/wrong',msg(b,'test')));
    await denied(request(a,'PUT','messages/'+id+'/clock',{...msg(a,'test'),createdAt:1}));
    await denied(request(a,'DELETE','messages/'+id+'/m1'));
    await denied(request(a,'PUT','messages/'+id+'/m1',msg(a,'edit')));
    await denied(request(c,'GET','messages/'+id,undefined,list));
    await denied(request(null,'PUT','messages/'+id+'/guest',msg(a,'test')));
    await denied(request(b,'GET','messages/'+id));
  });
  await t.test('T15–T18 · thành viên phòng, rời phòng và thông báo ghim',async()=>{
    const roomInfo={roomId:room,roomName:'Lập trình mobile',subject:'Flutter',ownerId:a.localId,createdAt:stamp};
    await ok(request(a,'PATCH','',{['rooms/'+room]:roomInfo,['roomMembers/'+room+'/'+a.localId]:{uid:a.localId,role:'owner'}}));
    await ok(request(b,'PUT','roomMembers/'+room+'/'+b.localId,{uid:b.localId,role:'member'}));
    await ok(request(a,'PUT','messages/'+room+'/m1',msg(a,'xin chào')));
    assert.equal((await ok(request(b,'GET','messages/'+room,undefined,list))).m1.content,'xin chào');
    await denied(request(c,'GET','messages/'+room,undefined,list));
    await denied(request(c,'PUT','messages/'+room+'/m2',msg(c,'test')));
    const notice={roomId:room,content:'Nộp bài thứ Sáu',updatedBy:a.localId,updatedAt:stamp};
    await ok(request(a,'PUT','roomNotices/'+room,notice));
    assert.equal((await ok(request(b,'GET','roomNotices/'+room))).content,notice.content);
    await denied(request(b,'PUT','roomNotices/'+room,{...notice,updatedBy:b.localId}));
    await ok(request(b,'DELETE','roomMembers/'+room+'/'+b.localId));
    await denied(request(b,'GET','messages/'+room,undefined,list));
    await denied(request(a,'DELETE','roomMembers/'+room+'/'+a.localId));
  });
  await t.test('T19 · các phiên độc lập, chỉ chủ tài khoản được ghi presence',async()=>{
    const path='presence/'+a.localId;
    for(const key of ['tab1','tab2']) await ok(request(a,'PUT',path+'/sessions/'+key,true));
    await ok(request(a,'PATCH',path,{'sessions/tab1':null,lastSeen:stamp}));
    assert.deepEqual((await ok(request(b,'GET',path))).sessions,{tab2:true});
    await denied(request(c,'DELETE',path+'/sessions/tab2'));
  });
});

