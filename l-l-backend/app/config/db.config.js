import mongoose from "mongoose"

const MONGO_CLIENT = async () => {
    mongoose.set("strictQuery", false);
    let dbUrl = (process.env.DB_URL || '').trim();
    if (dbUrl.includes('root:') && !dbUrl.includes('authSource=')) {
        dbUrl += (dbUrl.includes('?') ? (dbUrl.endsWith('?') ? 'authSource=admin' : '&authSource=admin') : '?authSource=admin');
    }
    return mongoose.connect(dbUrl, {
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000,
        connectTimeoutMS: 10000,
        heartbeatFrequencyMS: 10000,
    })
        .then(() => console.log('database connected successfully'))
        .catch(err => {
            console.error(`database connection failed: ${err}`);
            throw err;
        });
};

export default MONGO_CLIENT;