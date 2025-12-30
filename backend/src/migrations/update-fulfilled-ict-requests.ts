import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { ICTService } from '../ict/ict.service';
import { WorkflowStage, RequestStatus } from '../shared/types';

async function migrate() {
  console.log('🔄 Starting migration: Update fulfilled ICT requests workflow stage...');
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

    // Find all ICT requests that need updating:
    // 1. Status is FULFILLED but workflowStage is not FULFILLMENT
    // 2. All items are fulfilled but workflowStage is not FULFILLMENT
    const requests = await ictRequestModel.find({
      $or: [
        {
          status: RequestStatus.FULFILLED,
          workflowStage: { $ne: WorkflowStage.FULFILLMENT },
        },
        {
          status: RequestStatus.APPROVED,
          workflowStage: { $ne: WorkflowStage.FULFILLMENT },
        },
      ],
    }).exec();

    console.log(`📊 Found ${requests.length} requests to check...`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const request of requests) {
      // Check if all items are fulfilled
      const allItemsFulfilled = request.items.every(
        (item: any) => (item.fulfilledQuantity || 0) >= (item.requestedQuantity || item.quantity || 0),
      );

      // Update if:
      // 1. Status is FULFILLED, or
      // 2. All items are fulfilled (even if status is APPROVED)
      if (request.status === RequestStatus.FULFILLED || allItemsFulfilled) {
        if (request.workflowStage !== WorkflowStage.FULFILLMENT) {
          const oldStage = request.workflowStage;
          request.workflowStage = WorkflowStage.FULFILLMENT;
          
          // Also ensure status is FULFILLED if all items are fulfilled
          if (allItemsFulfilled && request.status !== RequestStatus.FULFILLED) {
            request.status = RequestStatus.FULFILLED;
          }
          
          await request.save();
          console.log(`✅ Updated request ${request._id}: ${oldStage} → FULFILLMENT (status: ${request.status})`);
          updatedCount++;
        } else {
          skippedCount++;
        }
      } else {
        skippedCount++;
      }
    }

    console.log(`\n✨ Migration completed!`);
    console.log(`   - Updated: ${updatedCount} requests`);
    console.log(`   - Skipped: ${skippedCount} requests`);
  } catch (error) {
    console.error('❌ Migration failed:', error);
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

migrate()
  .then(() => {
    console.log('✅ Migration script finished successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Migration script failed:', error);
    process.exit(1);
  });

