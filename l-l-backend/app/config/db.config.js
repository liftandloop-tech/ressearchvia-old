import mongoose from "mongoose"

const MONGO_CLIENT = async () => {
    mongoose.set("strictQuery", false);
    return mongoose.connect(process.env.DB_URL, {
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