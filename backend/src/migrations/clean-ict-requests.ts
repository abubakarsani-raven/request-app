import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { ICTService } from '../ict/ict.service';

async function clean() {
  console.log('🧹 Starting cleanup: Delete all ICT requests...');
  console.log('📡 Connecting to database...');
  
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  
  // Wait a bit for database connection to be established
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  const ictService = app.get(ICTService);

  try {
    // Get the ICT request model directly
    const ictRequestModel = (ictService as any).ictRequestModel;
    
    // Test database connection
    const testConnection = await ictRequestModel.findOne().limit(1).exec();
    console.log('✅ Database connection established');

    // Count total requests
    const totalCount = await ictRequestModel.countDocuments().exec();
    console.log(`📊 Found ${totalCount} ICT requests`);

    if (totalCount === 0) {
      console.log('✨ No requests to delete. Database is already clean.');
      return;
    }

    // Delete all ICT requests
    const result = await ictRequestModel.deleteMany({}).exec();
    
    console.log(`\n✨ Cleanup completed!`);
    console.log(`   - Deleted: ${result.deletedCount} requests`);
    
    // Also clean up related notifications if needed
    const notificationModel = (ictService as any).notificationModel;
    if (notificationModel) {
      const notificationResult = await notificationModel.deleteMany({
        requestType: 'ICT',
      }).exec();
      console.log(`   - Deleted: ${notificationResult.deletedCount} related notifications`);
    }
  } catch (error) {
    console.error('❌ Cleanup failed:', error);
    if (error instanceof Error) {
      console.error('Error message:', error.message);
      console.error('Error stack:', error.stack);
    }
    throw error;
  } finally {
    console.log('🔌 Closing database connection...');
    await app.close();
  }
}

clean()
  .then(() => {
    console.log('✅ Cleanup script finished successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Cleanup script failed:', error);
    process.exit(1);
  });

