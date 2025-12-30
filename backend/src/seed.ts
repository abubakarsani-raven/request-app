import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import { DepartmentsService } from './departments/departments.service';
import { OfficesService } from './offices/offices.service';
import { VehiclesService } from './vehicles/vehicles.service';
import { ICTService } from './ict/ict.service';
import { DepartmentDocument } from './departments/schemas/department.schema';
import { OfficeDocument } from './offices/schemas/office.schema';
import { UserRole } from './shared/types';

export async function runSeed() {
  const app = await NestFactory.createApplicationContext(AppModule);
  
  const usersService = app.get(UsersService);
  const departmentsService = app.get(DepartmentsService);
  const officesService = app.get(OfficesService);
  const vehiclesService = app.get(VehiclesService);
  const ictService = app.get(ICTService);

  try {
    console.log('🌱 Starting seed process...');

    // Create default department if it doesn't exist
    let department = await departmentsService.findByCode('ADMIN');
    if (!department) {
      // Department doesn't exist, create it
      department = await departmentsService.create({
        name: 'Administration',
        code: 'ADMIN',
      });
      console.log('✅ Created default department: Administration (ADMIN)');
    } else {
      console.log('✅ Default department already exists');
    }

    // Create head office if it doesn't exist
    let headOffice = await officesService.findHeadOffice();
    if (!headOffice) {
      const createdOffice = await officesService.create({
        name: 'Head Office',
        address: 'Main Headquarters',
        latitude: 6.4471,
        longitude: 3.3650,
        description: 'Main headquarters - all trip requests start from here',
        isHeadOffice: true,
      });
      headOffice = createdOffice as any as OfficeDocument;
      console.log('✅ Created head office');
    } else {
      console.log('✅ Head office already exists');
    }

    // Create default admin user if it doesn't exist
    const existingUser = await usersService.findByEmail('admin@example.com');
    if (existingUser) {
      console.log('✅ Default admin user already exists');
      console.log('📧 Email: admin@example.com');
      console.log('🔑 Password: 12345678');
    } else {
      // User doesn't exist, create it
      // Note: UsersService.create() will hash the password automatically
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const adminUser = await usersService.create({
        email: 'admin@example.com',
        password: '12345678',
        name: 'Admin User',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 1,
        roles: [UserRole.ADMIN],
      });

      console.log('✅ Created default admin user');
      console.log('📧 Email: admin@example.com');
      console.log('🔑 Password: 12345678');
      console.log('👤 Name: Admin User');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: ADMIN');
    }

    // Create second admin user if it doesn't exist
    const existingAdmin2 = await usersService.findByEmail('administrator@example.com');
    if (existingAdmin2) {
      console.log('✅ Second admin user already exists');
      console.log('📧 Email: administrator@example.com');
      console.log('🔑 Password: Admin@2024');
    } else {
      // User doesn't exist, create it
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const adminUser2 = await usersService.create({
        email: 'administrator@example.com',
        password: 'Admin@2024',
        name: 'System Administrator',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 1,
        roles: [UserRole.ADMIN],
      });

      console.log('✅ Created second admin user');
      console.log('📧 Email: administrator@example.com');
      console.log('🔑 Password: Admin@2024');
      console.log('👤 Name: System Administrator');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: ADMIN');
    }

    // Create driver user if it doesn't exist
    const existingDriver = await usersService.findByEmail('driver@example.com');
    if (existingDriver) {
      console.log('✅ Driver user already exists');
      console.log('📧 Email: driver@example.com');
      console.log('🔑 Password: Driver@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const driverUser = await usersService.create({
        email: 'driver@example.com',
        password: 'Driver@2024',
        name: 'John Driver',
        phone: '+2349012345678',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 20, // Regular staff level
        roles: [UserRole.DRIVER],
      });

      console.log('✅ Created driver user');
      console.log('📧 Email: driver@example.com');
      console.log('🔑 Password: Driver@2024');
      console.log('👤 Name: John Driver');
      console.log('📞 Phone: +2349012345678');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: DRIVER');

      // Create driver record
      const driverRecord = await vehiclesService.createDriver({
        name: 'John Driver',
        phone: '+2349012345678',
        licenseNumber: 'DL-2024-001',
        isAvailable: true,
      });

      console.log('✅ Created driver record');
      console.log('👤 Driver Name: John Driver');
      console.log('📞 Phone: +2349012345678');
      console.log('🚗 License Number: DL-2024-001');
    }

    // Create supervisor user if it doesn't exist
    const existingSupervisor = await usersService.findByEmail('supervisor@example.com');
    if (existingSupervisor) {
      console.log('✅ Supervisor user already exists');
      console.log('📧 Email: supervisor@example.com');
      console.log('🔑 Password: Supervisor@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const supervisorUser = await usersService.create({
        email: 'supervisor@example.com',
        password: 'Supervisor@2024',
        name: 'Jane Supervisor',
        phone: '+2349012345679',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 15, // Supervisor level
        roles: [UserRole.SUPERVISOR],
      });

      console.log('✅ Created supervisor user');
      console.log('📧 Email: supervisor@example.com');
      console.log('🔑 Password: Supervisor@2024');
      console.log('👤 Name: Jane Supervisor');
      console.log('📞 Phone: +2349012345679');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: SUPERVISOR');
    }

    // Create DDICT user if it doesn't exist
    const existingDDICT = await usersService.findByEmail('ddict@example.com');
    if (existingDDICT) {
      console.log('✅ DDICT user already exists');
      console.log('📧 Email: ddict@example.com');
      console.log('🔑 Password: DDICT@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const ddictUser = await usersService.create({
        email: 'ddict@example.com',
        password: 'DDICT@2024',
        name: 'ICT Director',
        phone: '+2349012345680',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 5, // High level for DDICT
        roles: [UserRole.DDICT],
      });

      console.log('✅ Created DDICT user');
      console.log('📧 Email: ddict@example.com');
      console.log('🔑 Password: DDICT@2024');
      console.log('👤 Name: ICT Director');
      console.log('📞 Phone: +2349012345680');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: DDICT');
    }

    // Create SO (Store Officer) user if it doesn't exist
    const existingSO = await usersService.findByEmail('storeofficer@example.com');
    if (existingSO) {
      console.log('✅ Store Officer user already exists');
      console.log('📧 Email: storeofficer@example.com');
      console.log('🔑 Password: SO@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const soUser = await usersService.create({
        email: 'storeofficer@example.com',
        password: 'SO@2024',
        name: 'Store Officer',
        phone: '+2349012345681',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 10, // Store Officer level
        roles: [UserRole.SO],
      });

      console.log('✅ Created Store Officer user');
      console.log('📧 Email: storeofficer@example.com');
      console.log('🔑 Password: SO@2024');
      console.log('👤 Name: Store Officer');
      console.log('📞 Phone: +2349012345681');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: SO');
    }

    // Create DGS user if it doesn't exist
    const existingDGS = await usersService.findByEmail('dgs@example.com');
    if (existingDGS) {
      console.log('✅ DGS user already exists');
      console.log('📧 Email: dgs@example.com');
      console.log('🔑 Password: DGS@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const dgsUser = await usersService.create({
        email: 'dgs@example.com',
        password: 'DGS@2024',
        name: 'Director General Services',
        phone: '+2349012345677',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 17, // Highest level for DGS
        roles: [UserRole.DGS],
      });

      console.log('✅ Created DGS user');
      console.log('📧 Email: dgs@example.com');
      console.log('🔑 Password: DGS@2024');
      console.log('👤 Name: Director General Services');
      console.log('📞 Phone: +2349012345677');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: DGS');
      console.log('📊 Level: 17');
    }

    // Create DDGS user if it doesn't exist
    const existingDDGS = await usersService.findByEmail('ddgs@example.com');
    if (existingDDGS) {
      console.log('✅ DDGS user already exists');
      console.log('📧 Email: ddgs@example.com');
      console.log('🔑 Password: DDGS@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const ddgsUser = await usersService.create({
        email: 'ddgs@example.com',
        password: 'DDGS@2024',
        name: 'Deputy Director General Services',
        phone: '+2349012345682',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 16, // Level 15+ for DDGS
        roles: [UserRole.DDGS],
      });

      console.log('✅ Created DDGS user');
      console.log('📧 Email: ddgs@example.com');
      console.log('🔑 Password: DDGS@2024');
      console.log('👤 Name: Deputy Director General Services');
      console.log('📞 Phone: +2349012345682');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: DDGS');
      console.log('📊 Level: 16');
    }

    // Create ADGS user if it doesn't exist
    const existingADGS = await usersService.findByEmail('adgs@example.com');
    if (existingADGS) {
      console.log('✅ ADGS user already exists');
      console.log('📧 Email: adgs@example.com');
      console.log('🔑 Password: ADGS@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const adgsUser = await usersService.create({
        email: 'adgs@example.com',
        password: 'ADGS@2024',
        name: 'Assistant Director General Services',
        phone: '+2349012345683',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 15, // Level 15+ for ADGS
        roles: [UserRole.ADGS],
      });

      console.log('✅ Created ADGS user');
      console.log('📧 Email: adgs@example.com');
      console.log('🔑 Password: ADGS@2024');
      console.log('👤 Name: Assistant Director General Services');
      console.log('📞 Phone: +2349012345683');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: ADGS');
      console.log('📊 Level: 15');
    }

    // Create TO (Transport Officer) user if it doesn't exist
    const existingTO = await usersService.findByEmail('transportofficer@example.com');
    if (existingTO) {
      console.log('✅ Transport Officer user already exists');
      console.log('📧 Email: transportofficer@example.com');
      console.log('🔑 Password: TO@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const toUser = await usersService.create({
        email: 'transportofficer@example.com',
        password: 'TO@2024',
        name: 'Transport Officer',
        phone: '+2349012345684',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 10, // Any level is acceptable for TO
        roles: [UserRole.TO],
      });

      console.log('✅ Created Transport Officer user');
      console.log('📧 Email: transportofficer@example.com');
      console.log('🔑 Password: TO@2024');
      console.log('👤 Name: Transport Officer');
      console.log('📞 Phone: +2349012345684');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: TO');
      console.log('📊 Level: 10');
    }

    // Create ICT Admin user if it doesn't exist
    const existingICTAdmin = await usersService.findByEmail('ictadmin@example.com');
    if (existingICTAdmin) {
      console.log('✅ ICT Admin user already exists');
      console.log('📧 Email: ictadmin@example.com');
      console.log('🔑 Password: ICTAdmin@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const ictAdminUser = await usersService.create({
        email: 'ictadmin@example.com',
        password: 'ICTAdmin@2024',
        name: 'ICT Administrator',
        phone: '+2349012345685',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 5,
        roles: [UserRole.ICT_ADMIN],
      });

      console.log('✅ Created ICT Admin user');
      console.log('📧 Email: ictadmin@example.com');
      console.log('🔑 Password: ICTAdmin@2024');
      console.log('👤 Name: ICT Administrator');
      console.log('📞 Phone: +2349012345685');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: ICT_ADMIN');
      console.log('📊 Level: 5');
    }

    // Create Store Admin user if it doesn't exist
    const existingStoreAdmin = await usersService.findByEmail('storeadmin@example.com');
    if (existingStoreAdmin) {
      console.log('✅ Store Admin user already exists');
      console.log('📧 Email: storeadmin@example.com');
      console.log('🔑 Password: StoreAdmin@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const storeAdminUser = await usersService.create({
        email: 'storeadmin@example.com',
        password: 'StoreAdmin@2024',
        name: 'Store Administrator',
        phone: '+2349012345686',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 5,
        roles: [UserRole.STORE_ADMIN],
      });

      console.log('✅ Created Store Admin user');
      console.log('📧 Email: storeadmin@example.com');
      console.log('🔑 Password: StoreAdmin@2024');
      console.log('👤 Name: Store Administrator');
      console.log('📞 Phone: +2349012345686');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: STORE_ADMIN');
      console.log('📊 Level: 5');
    }

    // Create Transport Admin user if it doesn't exist
    const existingTransportAdmin = await usersService.findByEmail('transportadmin@example.com');
    if (existingTransportAdmin) {
      console.log('✅ Transport Admin user already exists');
      console.log('📧 Email: transportadmin@example.com');
      console.log('🔑 Password: TransportAdmin@2024');
    } else {
      const departmentDoc = department as any as DepartmentDocument;
      const officeDoc = headOffice as any as OfficeDocument;
      const transportAdminUser = await usersService.create({
        email: 'transportadmin@example.com',
        password: 'TransportAdmin@2024',
        name: 'Transport Administrator',
        phone: '+2349012345687',
        departmentId: (departmentDoc._id || departmentDoc.id).toString(),
        officeId: (officeDoc._id || officeDoc.id).toString(),
        level: 5,
        roles: [UserRole.TRANSPORT_ADMIN],
      });

      console.log('✅ Created Transport Admin user');
      console.log('📧 Email: transportadmin@example.com');
      console.log('🔑 Password: TransportAdmin@2024');
      console.log('👤 Name: Transport Administrator');
      console.log('📞 Phone: +2349012345687');
      console.log('🏢 Department: Administration');
      console.log('🔐 Role: TRANSPORT_ADMIN');
      console.log('📊 Level: 5');
    }

    // Create vehicles (independent of drivers)
    console.log('🚗 Seeding vehicles...');
    const officeDocForVehicles = headOffice as any as OfficeDocument;
    const officeIdForVehicles = (officeDocForVehicles._id || officeDocForVehicles.id).toString();

    const vehicles = [
      {
        plateNumber: 'ABC-123-XY',
        make: 'Toyota',
        model: 'Camry',
        type: 'Sedan',
        year: 2022,
        capacity: 5,
        status: 'available',
        isPermanent: false,
        officeId: officeIdForVehicles,
        isAvailable: true,
      },
      {
        plateNumber: 'XYZ-456-AB',
        make: 'Honda',
        model: 'Accord',
        type: 'Sedan',
        year: 2023,
        capacity: 5,
        status: 'available',
        isPermanent: false,
        officeId: officeIdForVehicles,
        isAvailable: true,
      },
      {
        plateNumber: 'DEF-789-GH',
        make: 'Toyota',
        model: 'Hiace',
        type: 'Van',
        year: 2021,
        capacity: 14,
        status: 'available',
        isPermanent: false,
        officeId: officeIdForVehicles,
        isAvailable: true,
      },
      {
        plateNumber: 'GHI-012-JK',
        make: 'Nissan',
        model: 'Pathfinder',
        type: 'SUV',
        year: 2022,
        capacity: 7,
        status: 'available',
        isPermanent: false,
        officeId: officeIdForVehicles,
        isAvailable: true,
      },
    ];

    for (const vehicleData of vehicles) {
      const existingVehicles = await vehiclesService.findAllVehicles();
      const vehicleExists = existingVehicles.some((v: any) => v.plateNumber === vehicleData.plateNumber);
      
      if (!vehicleExists) {
        await vehiclesService.createVehicle(vehicleData);
        console.log(`  ✅ Created vehicle: ${vehicleData.plateNumber} (${vehicleData.make} ${vehicleData.model} ${vehicleData.year})`);
      } else {
        console.log(`  ⏭️  Vehicle already exists: ${vehicleData.plateNumber}`);
      }
    }
    console.log('✅ Vehicle seeding completed!');

    // Seed ICT Inventory Items
    console.log('📦 Seeding ICT inventory items...');
    const ictItems = [
      // Toner/Cartridges (some low stock)
      {
        name: 'HP LaserJet 85A Black Toner Cartridge',
        description: 'High-yield black toner cartridge for HP LaserJet printers',
        category: 'Toner/Cartridges',
        quantity: 3, // Low stock (threshold: 5)
        brand: 'HP',
        model: 'HP 85A',
        sku: 'HP-85A-BLK',
        unit: 'pieces',
        location: 'Warehouse A, Shelf 3',
        lowStockThreshold: 5,
        supplier: 'HP Supplies',
        supplierContact: 'supplies@hp.com',
        cost: 25.99,
        isAvailable: true,
      },
      {
        name: 'Canon PGI-280 Black Ink Cartridge',
        description: 'Standard black ink cartridge for Canon PIXMA printers',
        category: 'Toner/Cartridges',
        quantity: 45,
        brand: 'Canon',
        model: 'PGI-280',
        sku: 'CAN-PGI-280-BLK',
        unit: 'pieces',
        location: 'Warehouse A, Shelf 3',
        lowStockThreshold: 10,
        supplier: 'Canon Direct',
        supplierContact: 'orders@canon.com',
        cost: 18.50,
        isAvailable: true,
      },
      {
        name: 'Epson 252XL Black Ink Cartridge',
        description: 'Extra large capacity black ink cartridge',
        category: 'Toner/Cartridges',
        quantity: 2, // Low stock (threshold: 5)
        brand: 'Epson',
        model: '252XL',
        sku: 'EPS-252XL-BLK',
        unit: 'pieces',
        location: 'Warehouse A, Shelf 3',
        lowStockThreshold: 5,
        supplier: 'Epson Supplies',
        supplierContact: 'supplies@epson.com',
        cost: 22.99,
        isAvailable: true,
      },
      {
        name: 'HP 305 Color Ink Cartridge Set',
        description: 'CMYK color ink cartridge set for HP printers',
        category: 'Toner/Cartridges',
        quantity: 8,
        brand: 'HP',
        model: 'HP 305',
        sku: 'HP-305-COLOR',
        unit: 'sets',
        location: 'Warehouse A, Shelf 3',
        lowStockThreshold: 5,
        supplier: 'HP Supplies',
        supplierContact: 'supplies@hp.com',
        cost: 45.99,
        isAvailable: true,
      },
      // Printers
      {
        name: 'HP LaserJet Pro M404dn',
        description: 'Monochrome laser printer with duplex printing',
        category: 'Printers',
        quantity: 5,
        brand: 'HP',
        model: 'LaserJet Pro M404dn',
        sku: 'HP-M404DN',
        unit: 'pieces',
        location: 'Warehouse B, Section 1',
        lowStockThreshold: 2,
        supplier: 'HP Enterprise',
        supplierContact: 'enterprise@hp.com',
        cost: 299.99,
        isAvailable: true,
      },
      {
        name: 'Canon PIXMA TR8620 All-in-One',
        description: 'All-in-one printer with scanning and fax capabilities',
        category: 'Printers',
        quantity: 3,
        brand: 'Canon',
        model: 'PIXMA TR8620',
        sku: 'CAN-TR8620',
        unit: 'pieces',
        location: 'Warehouse B, Section 1',
        lowStockThreshold: 2,
        supplier: 'Canon Direct',
        supplierContact: 'orders@canon.com',
        cost: 199.99,
        isAvailable: true,
      },
      // Cables (some low stock)
      {
        name: 'USB-C to USB-A Cable',
        description: '3ft USB-C to USB-A charging and data cable',
        category: 'Cables',
        quantity: 4, // Low stock (threshold: 10)
        brand: 'Generic',
        model: 'USB-C-3FT',
        sku: 'CBL-USB-C-3FT',
        unit: 'pieces',
        location: 'Warehouse C, Bin 5',
        lowStockThreshold: 10,
        supplier: 'Electronics Co',
        supplierContact: 'sales@electronics.com',
        cost: 5.99,
        isAvailable: true,
      },
      {
        name: 'HDMI 2.0 Cable',
        description: '6ft High-Speed HDMI cable with Ethernet',
        category: 'Cables',
        quantity: 25,
        brand: 'Generic',
        model: 'HDMI-2.0-6FT',
        sku: 'CBL-HDMI-6FT',
        unit: 'pieces',
        location: 'Warehouse C, Bin 5',
        lowStockThreshold: 10,
        supplier: 'Electronics Co',
        supplierContact: 'sales@electronics.com',
        cost: 12.99,
        isAvailable: true,
      },
      {
        name: 'Ethernet Cat6 Cable',
        description: '10ft Cat6 Ethernet network cable',
        category: 'Cables',
        quantity: 6, // Low stock (threshold: 10)
        brand: 'Generic',
        model: 'CAT6-10FT',
        sku: 'CBL-CAT6-10FT',
        unit: 'pieces',
        location: 'Warehouse C, Bin 5',
        lowStockThreshold: 10,
        supplier: 'Electronics Co',
        supplierContact: 'sales@electronics.com',
        cost: 8.99,
        isAvailable: true,
      },
      {
        name: 'USB-A to Micro USB Cable',
        description: '6ft USB-A to Micro USB charging cable',
        category: 'Cables',
        quantity: 15,
        brand: 'Generic',
        model: 'USB-MICRO-6FT',
        sku: 'CBL-USB-MICRO-6FT',
        unit: 'pieces',
        location: 'Warehouse C, Bin 5',
        lowStockThreshold: 10,
        supplier: 'Electronics Co',
        supplierContact: 'sales@electronics.com',
        cost: 4.99,
        isAvailable: true,
      },
      // Computer Accessories
      {
        name: 'Logitech M705 Wireless Mouse',
        description: 'Wireless mouse with 3-year battery life',
        category: 'Computer Accessories',
        quantity: 12,
        brand: 'Logitech',
        model: 'M705',
        sku: 'LOG-M705',
        unit: 'pieces',
        location: 'Warehouse D, Shelf 2',
        lowStockThreshold: 5,
        supplier: 'Logitech Direct',
        supplierContact: 'orders@logitech.com',
        cost: 39.99,
        isAvailable: true,
      },
      {
        name: 'Microsoft Ergonomic Keyboard',
        description: 'Ergonomic keyboard with split design',
        category: 'Computer Accessories',
        quantity: 8,
        brand: 'Microsoft',
        model: 'Sculpt Ergonomic',
        sku: 'MS-SCULPT-KB',
        unit: 'pieces',
        location: 'Warehouse D, Shelf 2',
        lowStockThreshold: 5,
        supplier: 'Microsoft Store',
        supplierContact: 'orders@microsoft.com',
        cost: 79.99,
        isAvailable: true,
      },
      {
        name: 'USB Hub 4-Port',
        description: '4-port USB 3.0 hub with power adapter',
        category: 'Computer Accessories',
        quantity: 20,
        brand: 'Generic',
        model: 'USB-HUB-4P',
        sku: 'ACC-USB-HUB-4',
        unit: 'pieces',
        location: 'Warehouse D, Shelf 2',
        lowStockThreshold: 5,
        supplier: 'Electronics Co',
        supplierContact: 'sales@electronics.com',
        cost: 15.99,
        isAvailable: true,
      },
      // Network Equipment
      {
        name: 'TP-Link AC1750 Router',
        description: 'Dual-band WiFi router with gigabit ports',
        category: 'Network Equipment',
        quantity: 6,
        brand: 'TP-Link',
        model: 'Archer A7',
        sku: 'TPL-AC1750',
        unit: 'pieces',
        location: 'Warehouse E, Section 3',
        lowStockThreshold: 3,
        supplier: 'TP-Link Direct',
        supplierContact: 'orders@tp-link.com',
        cost: 59.99,
        isAvailable: true,
      },
      {
        name: 'Netgear 8-Port Switch',
        description: '8-port gigabit Ethernet switch',
        category: 'Network Equipment',
        quantity: 4,
        brand: 'Netgear',
        model: 'GS308',
        sku: 'NET-GS308',
        unit: 'pieces',
        location: 'Warehouse E, Section 3',
        lowStockThreshold: 3,
        supplier: 'Netgear Store',
        supplierContact: 'orders@netgear.com',
        cost: 29.99,
        isAvailable: true,
      },
      // Storage Devices
      {
        name: 'SanDisk 64GB USB 3.0 Flash Drive',
        description: '64GB USB 3.0 flash drive',
        category: 'Storage Devices',
        quantity: 2, // Low stock (threshold: 5)
        brand: 'SanDisk',
        model: 'Ultra 64GB',
        sku: 'SD-USB-64GB',
        unit: 'pieces',
        location: 'Warehouse F, Bin 2',
        lowStockThreshold: 5,
        supplier: 'SanDisk Direct',
        supplierContact: 'orders@sandisk.com',
        cost: 12.99,
        isAvailable: true,
      },
      {
        name: 'Seagate 1TB External HDD',
        description: '1TB portable external hard drive USB 3.0',
        category: 'Storage Devices',
        quantity: 7,
        brand: 'Seagate',
        model: 'Backup Plus 1TB',
        sku: 'SEA-EXT-1TB',
        unit: 'pieces',
        location: 'Warehouse F, Bin 2',
        lowStockThreshold: 3,
        supplier: 'Seagate Direct',
        supplierContact: 'orders@seagate.com',
        cost: 59.99,
        isAvailable: true,
      },
      {
        name: 'Samsung 256GB SSD',
        description: '256GB SATA III internal SSD',
        category: 'Storage Devices',
        quantity: 5,
        brand: 'Samsung',
        model: '870 EVO 256GB',
        sku: 'SAM-SSD-256GB',
        unit: 'pieces',
        location: 'Warehouse F, Bin 2',
        lowStockThreshold: 3,
        supplier: 'Samsung Direct',
        supplierContact: 'orders@samsung.com',
        cost: 49.99,
        isAvailable: true,
      },
      // Monitors/Displays
      {
        name: 'Dell 24-inch Monitor',
        description: '24-inch Full HD LED monitor',
        category: 'Monitors/Displays',
        quantity: 3,
        brand: 'Dell',
        model: 'P2422H',
        sku: 'DEL-24-P2422H',
        unit: 'pieces',
        location: 'Warehouse G, Section 1',
        lowStockThreshold: 2,
        supplier: 'Dell Direct',
        supplierContact: 'orders@dell.com',
        cost: 199.99,
        isAvailable: true,
      },
      {
        name: 'HP 27-inch Monitor',
        description: '27-inch Full HD IPS monitor',
        category: 'Monitors/Displays',
        quantity: 4,
        brand: 'HP',
        model: 'EliteDisplay E273',
        sku: 'HP-27-E273',
        unit: 'pieces',
        location: 'Warehouse G, Section 1',
        lowStockThreshold: 2,
        supplier: 'HP Enterprise',
        supplierContact: 'enterprise@hp.com',
        cost: 249.99,
        isAvailable: true,
      },
      // Other
      {
        name: 'Webcam HD 1080p',
        description: 'HD 1080p webcam with microphone',
        category: 'Other',
        quantity: 1, // Low stock (threshold: 3)
        brand: 'Logitech',
        model: 'C920',
        sku: 'LOG-C920',
        unit: 'pieces',
        location: 'Warehouse H, Shelf 1',
        lowStockThreshold: 3,
        supplier: 'Logitech Direct',
        supplierContact: 'orders@logitech.com',
        cost: 79.99,
        isAvailable: true,
      },
      {
        name: 'Laptop Stand Adjustable',
        description: 'Adjustable aluminum laptop stand',
        category: 'Other',
        quantity: 10,
        brand: 'Generic',
        model: 'LAP-STAND-ADJ',
        sku: 'ACC-LAP-STAND',
        unit: 'pieces',
        location: 'Warehouse H, Shelf 1',
        lowStockThreshold: 5,
        supplier: 'Office Supplies Co',
        supplierContact: 'sales@officesupplies.com',
        cost: 24.99,
        isAvailable: true,
      },
    ];

    let createdCount = 0;
    let skippedCount = 0;

    for (const itemData of ictItems) {
      try {
        // Check if item with same SKU already exists
        const existingItems = await ictService.findAllItems();
        const exists = existingItems.some(
          (item: any) => item.sku && item.sku === itemData.sku,
        );

        if (exists) {
          skippedCount++;
          continue;
        }

        await ictService.createItem(itemData);
        createdCount++;
        console.log(`  ✅ Created: ${itemData.name} (${itemData.category})`);
      } catch (error: any) {
        console.error(`  ❌ Failed to create ${itemData.name}:`, error.message);
      }
    }

    console.log(`📦 ICT Inventory seeding completed!`);
    console.log(`   Created: ${createdCount} items`);
    console.log(`   Skipped: ${skippedCount} items (already exist)`);
    console.log(`   Low stock items: ${ictItems.filter((i) => i.quantity <= i.lowStockThreshold).length} items`);

    console.log('✨ Seed process completed successfully!');
  } catch (error) {
    console.error('❌ Error during seed process:', error);
    throw error;
  } finally {
    await app.close();
  }
}

// Only run if executed directly (not imported)
if (require.main === module) {
  runSeed()
    .then(() => {
      console.log('✅ Seed completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Seed failed:', error);
      process.exit(1);
    });
}

