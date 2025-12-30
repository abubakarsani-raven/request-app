# User Credentials

This document contains all default user credentials for the Request Management System.

## ⚠️ Security Notice
**These are default credentials for development/testing purposes.**
- Change all passwords in production
- Do not commit this file to public repositories
- Use strong, unique passwords for production environments

---

## Admin Users

### Main Administrator
- **Email:** `admin@example.com`
- **Password:** `12345678`
- **Name:** Admin User
- **Role:** ADMIN
- **Level:** 1
- **Phone:** N/A

### System Administrator
- **Email:** `administrator@example.com`
- **Password:** `Admin@2024`
- **Name:** System Administrator
- **Role:** ADMIN
- **Level:** 1
- **Phone:** N/A

---

## Director General Services (DGS)

### Director General Services
- **Email:** `dgs@example.com`
- **Password:** `DGS@2024`
- **Name:** Director General Services
- **Role:** DGS
- **Level:** 17
- **Phone:** +2349012345677

---

## Deputy Director General Services (DDGS)

### Deputy Director General Services
- **Email:** `ddgs@example.com`
- **Password:** `DDGS@2024`
- **Name:** Deputy Director General Services
- **Role:** DDGS
- **Level:** 16
- **Phone:** +2349012345682

---

## Assistant Director General Services (ADGS)

### Assistant Director General Services
- **Email:** `adgs@example.com`
- **Password:** `ADGS@2024`
- **Name:** Assistant Director General Services
- **Role:** ADGS
- **Level:** 15
- **Phone:** +2349012345683

---

## ICT Department

### Deputy Director ICT (DDICT)
- **Email:** `ddict@example.com`
- **Password:** `DDICT@2024`
- **Name:** ICT Director
- **Role:** DDICT
- **Level:** 5
- **Phone:** +2349012345680

### ICT Administrator
- **Email:** `ictadmin@example.com`
- **Password:** `ICTAdmin@2024`
- **Name:** ICT Administrator
- **Role:** ICT_ADMIN
- **Level:** 5
- **Phone:** +2349012345685

---

## Store Department

### Store Officer (SO)
- **Email:** `storeofficer@example.com`
- **Password:** `SO@2024`
- **Name:** Store Officer
- **Role:** SO
- **Level:** 10
- **Phone:** +2349012345681

### Store Administrator
- **Email:** `storeadmin@example.com`
- **Password:** `StoreAdmin@2024`
- **Name:** Store Administrator
- **Role:** STORE_ADMIN
- **Level:** 5
- **Phone:** +2349012345686

---

## Transport Department

### Transport Officer (TO)
- **Email:** `transportofficer@example.com`
- **Password:** `TO@2024`
- **Name:** Transport Officer
- **Role:** TO
- **Level:** 10
- **Phone:** +2349012345684

### Transport Administrator
- **Email:** `transportadmin@example.com`
- **Password:** `TransportAdmin@2024`
- **Name:** Transport Administrator
- **Role:** TRANSPORT_ADMIN
- **Level:** 5
- **Phone:** +2349012345687

---

## Staff Users

### Supervisor
- **Email:** `supervisor@example.com`
- **Password:** `Supervisor@2024`
- **Name:** Jane Supervisor
- **Role:** SUPERVISOR
- **Level:** 15
- **Phone:** +2349012345679

### Driver
- **Email:** `driver@example.com`
- **Password:** `Driver@2024`
- **Name:** John Driver
- **Role:** DRIVER
- **Level:** 20
- **Phone:** +2349012345678
- **License Number:** DL-2024-001
- **Note:** Vehicles are independent of drivers. Drivers are assigned to vehicles when trips are created.

---

## Vehicles

The following vehicles are seeded independently (not assigned to any driver):

1. **ABC-123-XY** - Toyota Camry 2022 (Sedan, 5 seats) - Available
2. **XYZ-456-AB** - Honda Accord 2023 (Sedan, 5 seats) - Available
3. **DEF-789-GH** - Toyota Hiace 2021 (Van, 14 seats) - Available
4. **GHI-012-JK** - Nissan Pathfinder 2022 (SUV, 7 seats) - Available

**Note:** Vehicles and drivers are independent. Vehicles are assigned to drivers when trip requests are created and approved.

---

## Summary by Role

| Role | Email | Password | Level |
|------|-------|----------|-------|
| ADMIN | admin@example.com | 12345678 | 1 |
| ADMIN | administrator@example.com | Admin@2024 | 1 |
| DGS | dgs@example.com | DGS@2024 | 17 |
| DDGS | ddgs@example.com | DDGS@2024 | 16 |
| ADGS | adgs@example.com | ADGS@2024 | 15 |
| DDICT | ddict@example.com | DDICT@2024 | 5 |
| ICT_ADMIN | ictadmin@example.com | ICTAdmin@2024 | 5 |
| SO | storeofficer@example.com | SO@2024 | 10 |
| STORE_ADMIN | storeadmin@example.com | StoreAdmin@2024 | 5 |
| TO | transportofficer@example.com | TO@2024 | 10 |
| TRANSPORT_ADMIN | transportadmin@example.com | TransportAdmin@2024 | 5 |
| SUPERVISOR | supervisor@example.com | Supervisor@2024 | 15 |
| DRIVER | driver@example.com | Driver@2024 | 20 |

---

## Quick Reference

**Most Common Login Credentials:**
- **Admin:** `admin@example.com` / `12345678`
- **DGS:** `dgs@example.com` / `DGS@2024`
- **DDGS:** `ddgs@example.com` / `DDGS@2024`
- **Supervisor:** `supervisor@example.com` / `Supervisor@2024`
- **Driver:** `driver@example.com` / `Driver@2024`

---

## Notes

- All users are assigned to the "Administration" department
- All users are assigned to the "Head Office"
- Passwords are hashed using bcrypt (10 rounds) in the database
- Users can have multiple roles (e.g., a user can be both SUPERVISOR and DDGS)
- Level determines approval hierarchy (lower number = higher authority)
- Vehicles are created independently and are available for assignment when trips are requested
