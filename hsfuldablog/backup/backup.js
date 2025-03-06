const cron = require('node-cron');
const { MongoClient } = require('mongodb');
const { exec } = require('child_process');
const path = require('path');

// Get MongoDB URI from environment variable
const MONGO_URI = process.env.MONGO_URI;
const BACKUP_DIR = '/backup';

// Schedule backup every 15 minutes
cron.schedule('*/15 * * * *', async () => {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupPath = path.join(BACKUP_DIR, `backup-${timestamp}`);
    
    console.log(`Starting backup at ${timestamp}`);
    
    try {
        // Connect to MongoDB
        const client = await MongoClient.connect(MONGO_URI);
        const db = client.db();
        
        // Get all collections
        const collections = await db.listCollections().toArray();
        
        // Backup each collection
        for (const collection of collections) {
            const data = await db.collection(collection.name).find({}).toArray();
            
            // Save to backup directory
            require('fs').writeFileSync(
                `${backupPath}-${collection.name}.json`,
                JSON.stringify(data, null, 2)
            );
        }
        
        await client.close();
        console.log(`Backup completed successfully at ${timestamp}`);
    } catch (error) {
        console.error('Backup failed:', error);
    }
});

console.log('Backup service started');