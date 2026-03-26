const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to trigger a Push Notification whenever a new object is saved to /notifications/{ownerId}/{pushId}
 * It grabs the Owner's tokens and delivers the payload equipped with the Custom Audio.
 */
exports.sendNotificationOnNewDatabaseEntry = functions.database
    .ref('/notifications/{ownerId}/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const ownerId = context.params.ownerId;
        const notificationData = snapshot.val();

        // 1. Fetch the owner's FCM tokens
        const tokensSnapshot = await admin.database()
            .ref(`/users/${ownerId}/fcmTokens`)
            .once('value');

        if (!tokensSnapshot.exists()) {
            console.log(`No tokens found for user ${ownerId}`);
            return null;
        }

        const tokens = Object.keys(tokensSnapshot.val());

        // 2. Prepare the Notification Payload
        const payload = {
            notification: {
                title: notificationData.title || "New Alert",
                body: notificationData.body || "You have a new action waiting.",
                // Custom Audio routing for iOS and Android
                sound: "notification_sound.mp3"
            },
            data: {
                type: notificationData.type || "regular",
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            }
        };

        // 3. Send securely via FCM
        try {
            const response = await admin.messaging().sendToDevice(tokens, payload);
            console.log(`Successfully sent ${response.successCount} messages. Failed: ${response.failureCount}`);
            return response;
        } catch (error) {
            console.error('Error sending push notification:', error);
            return null;
        }
    });
