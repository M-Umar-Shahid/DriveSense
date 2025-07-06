// functions/index.js

const functions = require('firebase-functions');
const admin     = require('firebase-admin');
admin.initializeApp();

// Helper to send a push notification via FCM (unchanged)
async function sendPush(toUid, title, body, data) {
  const userSnap = await admin.firestore().collection('users').doc(toUid).get();
  const userData = userSnap.data();
  const token    = userData ? userData.fcmToken : null;
  if (!token) return;
  await admin.messaging().send({ token, notification: { title, body }, data });
}

// 1) New Join-Company Request
exports.onJoinRequest = functions.firestore
  .document('requests/{reqId}')
  .onCreate(async (snap, ctx) => {
    const { type, fromId, toId } = snap.data();
    if (type !== 'join_company') return;
    const driverSnap = await admin.firestore().collection('users').doc(fromId).get();
    const name = driverSnap.data()?.displayName || 'A driver';
    await sendPush(toId, 'New Join Request', `${name} wants to join your company.`, { refId: ctx.params.reqId, type });
  });

// 2) New Hire-Driver Request
exports.onHireRequest = functions.firestore
  .document('requests/{reqId}')
  .onCreate(async (snap, ctx) => {
    const { type, fromId, toId } = snap.data();
    if (type !== 'hire_driver') return;
    const companySnap = await admin.firestore().collection('users').doc(fromId).get();
    const name = companySnap.data()?.displayName || 'A company';
    await sendPush(toId, 'New Hire Request', `${name} sent you a hire request.`, { refId: ctx.params.reqId, type });
  });

// 3) New Chat Message
exports.onChatMessage = functions.firestore
  .document('companies/{companyId}/chats/{chatId}/messages/{msgId}')
  .onCreate(async (snap, ctx) => {
    const { senderId, text } = snap.data();
    // find the other participant
    const chatDoc = await admin.firestore()
      .collection('companies').doc(ctx.params.companyId)
      .collection('chats').doc(ctx.params.chatId)
      .get();
    const participants = chatDoc.data()?.participantIds || [];
    const recipientId  = participants.find(id => id !== senderId);
    if (!recipientId) return;
    const senderSnap = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderSnap.data()?.displayName || 'Someone';
    const preview = text.length > 30 ? text.substring(0,30) + '…' : text;
    await sendPush(recipientId, 'New Message', `${senderName}: ${preview}`, { refId: ctx.params.chatId, type: 'chat' });
  });
