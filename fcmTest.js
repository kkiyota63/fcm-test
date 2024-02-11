//./fcmTest.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const registrationToken = 'FCMトークン';  

const message = {
  notification: {
    title: 'テスト通知',
    body: 'テストのプッシュ通知です'
  },
  data: {
    testData: '通知に含めたいデータなど',
  },
  token: registrationToken,
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });