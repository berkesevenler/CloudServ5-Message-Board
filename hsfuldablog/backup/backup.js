const cron = require('node-cron');
const { MongoClient } = require('mongodb');
const fs = require('fs');
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
        // Connect to MongoDB with the same options as backend
        const client = await MongoClient.connect(MONGO_URI, {
            tls: true,
            tlsAllowInvalidCertificates: true,
            connectTimeoutMS: 10000,
            socketTimeoutMS: 45000,
            serverSelectionTimeoutMS: 10000,
            retryWrites: true,
            w: "majority"
        });

        const db = client.db("messageboard");
        console.log("Connected to MongoDB messageboard database");
        
        // Get all collections
        const collections = await db.listCollections().toArray();
        
        // Backup each collection
        for (const collection of collections) {
            const data = await db.collection(collection.name).find({}).toArray();
            
            // Save to backup directory
            fs.writeFileSync(
                `${backupPath}-${collection.name}.json`,
                JSON.stringify(data, null, 2)
            );
            console.log(`Backed up collection: ${collection.name}`);
        }
        
        await client.close();
        console.log(`Backup completed successfully at ${timestamp}`);
    } catch (error) {
        console.error('Backup failed:', error);
    }
});

console.log('Backup service started');