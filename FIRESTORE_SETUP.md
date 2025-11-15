# Firestore Setup Guide - Creating Rooms

## Method 1: Automatic Creation (Recommended)

The app automatically creates rooms when you run it. The code in `lib/services/booking_service.dart` will:

1. Clear existing rooms
2. Create all 7 rooms automatically
3. Load them on the home page

**Just run the app and the rooms will be created automatically!**

---

## Method 2: Manual Creation in Firestore Console

If you want to manually create rooms in Firestore Console, follow these steps:

### Step 1: Open Firestore Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **daydream-20e85**
3. Click on **Firestore Database** in the left menu

### Step 2: Create Collection
1. Click **Start collection** (if no collections exist)
2. Collection ID: `rooms`
3. Click **Next**

### Step 3: Add Each Room Document

For each room, create a document with the following structure:

#### Room 1: Poolside Villa
- **Document ID**: `room1`
- **Fields**:
  ```
  name: "Poolside Villa" (string)
  description: "Luxurious villa with direct pool access and stunning resort views. Features a private terrace overlooking the infinity pool and tropical gardens. Perfect for couples seeking a romantic getaway." (string)
  price: 349.99 (number)
  capacity: 2 (number)
  amenities: ["WiFi", "TV", "AC", "Mini Bar", "Pool Access", "Private Terrace", "Room Service"] (array)
  imageUrl: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 2: Ocean View Suite
- **Document ID**: `room2`
- **Fields**:
  ```
  name: "Ocean View Suite" (string)
  description: "Spacious suite with breathtaking ocean views and modern amenities. Wake up to the sound of waves and enjoy stunning sunsets from your private balcony. Includes premium bedding and luxury bathroom." (string)
  price: 299.99 (number)
  capacity: 2 (number)
  amenities: ["WiFi", "TV", "AC", "Ocean View", "Balcony", "Mini Bar", "Room Service"] (array)
  imageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 3: Infinity Pool Penthouse
- **Document ID**: `room3`
- **Fields**:
  ```
  name: "Infinity Pool Penthouse" (string)
  description: "Exclusive penthouse with private infinity pool overlooking the resort. Features a spacious living area, fully equipped kitchen, and premium furnishings. Ideal for families or groups seeking ultimate luxury." (string)
  price: 599.99 (number)
  capacity: 4 (number)
  amenities: ["WiFi", "TV", "AC", "Private Pool", "Kitchen", "Balcony", "Living Room", "Premium Bedding"] (array)
  imageUrl: "https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 4: Tropical Garden Bungalow
- **Document ID**: `room4`
- **Fields**:
  ```
  name: "Tropical Garden Bungalow" (string)
  description: "Charming bungalow nestled in lush tropical gardens with pool access. Features traditional design with modern comforts. Perfect for those seeking tranquility and natural beauty." (string)
  price: 199.99 (number)
  capacity: 2 (number)
  amenities: ["WiFi", "TV", "AC", "Garden View", "Pool Access", "Private Entrance", "Outdoor Seating"] (array)
  imageUrl: "https://images.unsplash.com/photo-1564501049412-61c2a3083791?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 5: Luxury Pool Suite
- **Document ID**: `room5`
- **Fields**:
  ```
  name: "Luxury Pool Suite" (string)
  description: "Elegant suite with direct access to the resort's main pool area. Features contemporary design, premium amenities, and stunning pool views. Includes complimentary breakfast and poolside service." (string)
  price: 249.99 (number)
  capacity: 2 (number)
  amenities: ["WiFi", "TV", "AC", "Pool View", "Pool Access", "Breakfast Included", "Room Service", "Mini Bar"] (array)
  imageUrl: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 6: Family Pool Villa
- **Document ID**: `room6`
- **Fields**:
  ```
  name: "Family Pool Villa" (string)
  description: "Spacious family villa with private pool and multiple bedrooms. Perfect for families with children. Features a fully equipped kitchen, living area, and direct pool access. Includes family-friendly amenities." (string)
  price: 449.99 (number)
  capacity: 6 (number)
  amenities: ["WiFi", "TV", "AC", "Private Pool", "Kitchen", "Multiple Bedrooms", "Living Room", "Garden", "Family Friendly"] (array)
  imageUrl: "https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

#### Room 7: Beachfront Deluxe
- **Document ID**: `room7`
- **Fields**:
  ```
  name: "Beachfront Deluxe" (string)
  description: "Premium beachfront room with stunning ocean and pool views. Steps away from the beach and resort pool. Features modern design, premium bedding, and luxury bathroom with ocean view." (string)
  price: 279.99 (number)
  capacity: 2 (number)
  amenities: ["WiFi", "TV", "AC", "Beach Access", "Pool View", "Ocean View", "Premium Bedding", "Luxury Bathroom"] (array)
  imageUrl: "https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" (string)
  isAvailable: true (boolean)
  ```

### Step 4: How to Add Fields in Firestore Console

For each field:
1. Click **Add field**
2. Enter field name (e.g., `name`)
3. Select field type:
   - **string** for text fields
   - **number** for prices and capacity
   - **array** for amenities (add each item separately)
   - **boolean** for isAvailable
4. Enter the value
5. Click **Save**

### Step 5: For Array Fields (amenities)

When adding the `amenities` array:
1. Select type: **array**
2. Click **Add item** for each amenity
3. Enter each amenity as a string item in the array

---

## Quick Reference: All Room Data

| Room ID | Name | Price | Capacity | Image URL |
|---------|------|-------|----------|-----------|
| room1 | Poolside Villa | $349.99 | 2 | [Image](https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room2 | Ocean View Suite | $299.99 | 2 | [Image](https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room3 | Infinity Pool Penthouse | $599.99 | 4 | [Image](https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room4 | Tropical Garden Bungalow | $199.99 | 2 | [Image](https://images.unsplash.com/photo-1564501049412-61c2a3083791?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room5 | Luxury Pool Suite | $249.99 | 2 | [Image](https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room6 | Family Pool Villa | $449.99 | 6 | [Image](https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |
| room7 | Beachfront Deluxe | $279.99 | 2 | [Image](https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80) |

---

## Troubleshooting

### If rooms don't appear:
1. Check Firestore security rules allow read access
2. Verify the collection name is exactly `rooms` (lowercase)
3. Check that `isAvailable` is set to `true`
4. Ensure all required fields are present
5. Check the app's debug console for error messages

### Firestore Security Rules
Make sure your Firestore rules allow reading:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Notes

- The app will automatically create these rooms when you run it
- If you manually create them, the app will still work
- The `forceInitializeRooms()` method will overwrite any existing rooms
- All rooms have the "Book Now" button functionality built-in

