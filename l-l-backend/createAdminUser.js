import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from './app/models/userModel.js';

dotenv.config();

const createAdmin = async () => {
    try {
        const dbUrl = process.env.DB_URL || 'mongodb://root:Research%4028@72.60.221.95:27017/researchvia?authSource=admin';

        await mongoose.connect(dbUrl);
        console.log('Connected to DB');

        const adminEmail = 'info@researchvia.in';
        const adminPass = 'Research@12';

        const adminData = {
            fullName: 'Super Admin',
            email: adminEmail,
            phone: '0000000000',
            userType: 'super_admin',
            userObject: {
                emailAddress: adminEmail,
                password: adminPass, // Storing plaintext as per existing auth logic :(
                firstName: 'Super',
                lastName: 'Admin'
            },
            userStatus: 'ACTIVE',
            registrationStatus: 'ACTIVE',
            kycStatus: 'VERIFIED',
            adminAccessGranted: true,
            account_type: 'ADMIN_PROVISIONED',
            role: 'super_admin' // Just in case
        };

        // Upsert the user
        const result = await User.findOneAndUpdate(
            { email: adminEmail },
            { $set: adminData },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        console.log('Admin user created/updated successfully:', result.email);
        console.log('ID:', result._id);
        console.log('User Type:', result.userType);

        process.exit(0);
    } catch (error) {
        console.error('Error creating admin:', error);
        process.exit(1);
    }
};

createAdmin();
