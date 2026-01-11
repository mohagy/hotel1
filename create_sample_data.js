/**
 * Create Sample Reservation and Booking Data
 * 
 * This script creates sample guests, rooms, and reservations in Firestore
 * Run with: node create_sample_data.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createSampleData() {
  try {
    console.log('Creating sample reservation and booking data...\n');
    
    // Helper to format date as YYYY-MM-DD
    const formatDate = (date) => {
      return date.toISOString().split('T')[0];
    };
    
    // Get current date
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Step 1: Check/Create rooms (we need rooms to create reservations)
    console.log('Step 1: Checking/Creating rooms...');
    const sampleRooms = [
      { room_number: '101', floor: 1, room_type: 'single', capacity: 1, price_per_night: 100, status: 'available' },
      { room_number: '102', floor: 1, room_type: 'double', capacity: 2, price_per_night: 150, status: 'available' },
      { room_number: '201', floor: 2, room_type: 'double', capacity: 2, price_per_night: 150, status: 'available' },
      { room_number: '202', floor: 2, room_type: 'suite', capacity: 4, price_per_night: 250, status: 'available' },
      { room_number: '301', floor: 3, room_type: 'deluxe', capacity: 2, price_per_night: 300, status: 'available' },
      { room_number: '302', floor: 3, room_type: 'suite', capacity: 4, price_per_night: 250, status: 'available' },
    ];
    
    const roomIds = [];
    let roomIdCounter = 1;
    
    for (const roomData of sampleRooms) {
      try {
        // Check if room exists by room_number
        const existingQuery = await db.collection('rooms')
          .where('room_number', '==', roomData.room_number)
          .limit(1)
          .get();
        
        let roomId;
        if (!existingQuery.empty) {
          roomId = parseInt(existingQuery.docs[0].id);
          console.log(`  ✓ Room ${roomData.room_number} already exists (ID: ${roomId})`);
        } else {
          roomId = roomIdCounter++;
          await db.collection('rooms').doc(roomId.toString()).set({
            ...roomData,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`  ✓ Created room ${roomData.room_number} (ID: ${roomId})`);
        }
        roomIds.push(roomId);
      } catch (error) {
        console.error(`  ✗ Error with room ${roomData.room_number}:`, error.message);
      }
    }
    
    console.log(`\nTotal rooms: ${roomIds.length}\n`);
    
    // Step 2: Check/Create sample guests
    console.log('Step 2: Checking/Creating guests...');
    const sampleGuests = [
      { first_name: 'John', last_name: 'Doe', email: 'john.doe@email.com', phone: '+1-555-0101', id_type: 'passport', id_number: 'P123456', country: 'USA', guest_type: 'regular' },
      { first_name: 'Jane', last_name: 'Smith', email: 'jane.smith@email.com', phone: '+1-555-0102', id_type: 'driver_license', id_number: 'DL789012', country: 'USA', guest_type: 'vip' },
      { first_name: 'Michael', last_name: 'Johnson', email: 'michael.j@email.com', phone: '+1-555-0103', id_type: 'passport', id_number: 'P345678', country: 'Canada', guest_type: 'regular' },
      { first_name: 'Sarah', last_name: 'Williams', email: 'sarah.w@email.com', phone: '+1-555-0104', id_type: 'national_id', id_number: 'NID901234', country: 'UK', guest_type: 'corporate' },
      { first_name: 'Robert', last_name: 'Brown', email: 'robert.b@email.com', phone: '+1-555-0105', id_type: 'passport', id_number: 'P567890', country: 'USA', guest_type: 'regular' },
      { first_name: 'Emily', last_name: 'Davis', email: 'emily.d@email.com', phone: '+1-555-0106', id_type: 'driver_license', id_number: 'DL123456', country: 'USA', guest_type: 'vip' },
    ];
    
    const guestIds = [];
    let guestIdCounter = 1;
    
    for (const guestData of sampleGuests) {
      try {
        // Check if guest exists by email
        const existingQuery = await db.collection('guests')
          .where('email', '==', guestData.email)
          .limit(1)
          .get();
        
        let guestId;
        if (!existingQuery.empty) {
          guestId = parseInt(existingQuery.docs[0].id);
          console.log(`  ✓ Guest ${guestData.first_name} ${guestData.last_name} already exists (ID: ${guestId})`);
        } else {
          // Find next available guest ID
          const allGuests = await db.collection('guests').get();
          const existingIds = allGuests.docs.map(doc => parseInt(doc.id)).filter(id => !isNaN(id));
          guestId = existingIds.length > 0 ? Math.max(...existingIds) + 1 : guestIdCounter++;
          
          await db.collection('guests').doc(guestId.toString()).set({
            ...guestData,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`  ✓ Created guest ${guestData.first_name} ${guestData.last_name} (ID: ${guestId})`);
        }
        guestIds.push(guestId);
      } catch (error) {
        console.error(`  ✗ Error with guest ${guestData.first_name} ${guestData.last_name}:`, error.message);
      }
    }
    
    console.log(`\nTotal guests: ${guestIds.length}\n`);
    
    // Step 3: Create sample reservations
    console.log('Step 3: Creating reservations...');
    const reservations = [
      {
        guest_index: 0, // John Doe
        room_index: 0, // Room 101
        check_in_date: new Date(today),
        check_out_date: new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000), // 2 nights
        status: 'checked_in',
        total_price: 200,
      },
      {
        guest_index: 1, // Jane Smith
        room_index: 1, // Room 102
        check_in_date: new Date(today),
        check_out_date: new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000), // 3 nights
        status: 'checked_in',
        total_price: 450,
      },
      {
        guest_index: 2, // Michael Johnson
        room_index: 2, // Room 201
        check_in_date: new Date(today.getTime() + 1 * 24 * 60 * 60 * 1000), // Tomorrow
        check_out_date: new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000), // 3 nights
        status: 'reserved',
        total_price: 450,
      },
      {
        guest_index: 3, // Sarah Williams
        room_index: 3, // Room 202
        check_in_date: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
        check_out_date: new Date(today.getTime() + 8 * 24 * 60 * 60 * 1000), // 3 nights
        status: 'reserved',
        total_price: 750,
      },
      {
        guest_index: 4, // Robert Brown
        room_index: 4, // Room 301
        check_in_date: new Date(today.getTime() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
        check_out_date: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        status: 'checked_out',
        total_price: 600,
      },
      {
        guest_index: 5, // Emily Davis
        room_index: 5, // Room 302
        check_in_date: new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        check_out_date: new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000), // 3 nights
        status: 'reserved',
        total_price: 750,
      },
    ];
    
    let reservationIdCounter = 1;
    let createdCount = 0;
    
    for (const resData of reservations) {
      try {
        const guestId = guestIds[resData.guest_index];
        const roomId = roomIds[resData.room_index];
        
        if (!guestId || !roomId) {
          console.log(`  ✗ Skipping reservation - missing guest or room`);
          continue;
        }
        
        // Find next available reservation ID
        const allReservations = await db.collection('reservations').get();
        const existingIds = allReservations.docs.map(doc => parseInt(doc.id)).filter(id => !isNaN(id));
        const reservationId = existingIds.length > 0 ? Math.max(...existingIds) + 1 : reservationIdCounter++;
        
        const numberOfNights = Math.floor((resData.check_out_date.getTime() - resData.check_in_date.getTime()) / (24 * 60 * 60 * 1000));
        
        await db.collection('reservations').doc(reservationId.toString()).set({
          guest_id: guestId,
          room_id: roomId,
          check_in_date: formatDate(resData.check_in_date),
          check_out_date: formatDate(resData.check_out_date),
          status: resData.status,
          total_price: resData.total_price,
          number_of_nights: numberOfNights,
          balance_due: resData.total_price,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`  ✓ Created reservation ${reservationId} (${resData.status}) - Guest ${guestId}, Room ${roomId}, ${numberOfNights} nights, $${resData.total_price}`);
        createdCount++;
      } catch (error) {
        console.error(`  ✗ Error creating reservation:`, error.message);
      }
    }
    
    console.log(`\n✅ Created ${createdCount} reservations`);
    console.log('\n✅ Sample data creation complete!');
    console.log('\nNext steps:');
    console.log('1. Refresh your app');
    console.log('2. Go to Guests screen to see the sample guests');
    console.log('3. Go to Reservations screen to see the sample reservations');
    console.log('4. Go to POS Management to see the reservation counts');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createSampleData();

