/**
 * Check Reservations in Firestore
 * 
 * This script shows what reservations exist and their balance_due values
 * Run with: node check_reservations.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkReservations() {
  try {
    console.log('Checking reservations in Firestore...\n');
    
    // Get all reservations
    const reservationsSnapshot = await db.collection('reservations')
      .orderBy('check_in_date', 'desc')
      .limit(20)
      .get();
    
    console.log(`Found ${reservationsSnapshot.size} reservations:\n`);
    
    if (reservationsSnapshot.empty) {
      console.log('No reservations found!');
      process.exit(0);
    }
    
    reservationsSnapshot.forEach(doc => {
      const data = doc.data();
      const reservationId = doc.id;
      const guestId = data.guest_id;
      const roomId = data.room_id;
      const status = data.status || 'unknown';
      const totalPrice = data.total_price || 0;
      const balanceDue = data.balance_due !== undefined ? data.balance_due : 'not set';
      const checkInDate = data.check_in_date;
      const checkOutDate = data.check_out_date;
      
      console.log(`Reservation ID: ${reservationId}`);
      console.log(`  Guest ID: ${guestId}`);
      console.log(`  Room ID: ${roomId}`);
      console.log(`  Status: ${status}`);
      console.log(`  Check-in: ${checkInDate}`);
      console.log(`  Check-out: ${checkOutDate}`);
      console.log(`  Total Price: $${totalPrice}`);
      console.log(`  Balance Due: ${balanceDue === 'not set' ? 'NOT SET' : '$' + balanceDue}`);
      console.log(`  Will show in POS: ${(balanceDue !== 'not set' && balanceDue > 0) || totalPrice > 0 ? 'YES' : 'NO'}`);
      console.log('');
    });
    
    // Count by status
    const statusCounts = {};
    reservationsSnapshot.forEach(doc => {
      const status = doc.data().status || 'unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });
    
    console.log('Status breakdown:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`  ${status}: ${count}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkReservations();

