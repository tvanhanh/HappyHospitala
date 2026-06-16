// import mongoose from 'mongoose';
// import dotenv from 'dotenv';
// import Appointment from './models/Appointment';
// import Doctor from './models/Doctor';
// import User from './models/User';

// dotenv.config();

// async function run() {
//   try {
//     await mongoose.connect(process.env.MONGO_URI as string);
//     console.log("Connected to MongoDB!");

//     // Reference modelName to force registration
//     console.log("Forcing registration of User:", User.modelName);
//     console.log("Forcing registration of Doctor:", Doctor.modelName);
//     console.log("Registered model names:", mongoose.modelNames());

//     // Fetch raw appointment first
//     const rawApp = await mongoose.connection.db!.collection('appointments').findOne({}, { sort: { createdAt: -1 } });
//     console.log("Raw appointment doctor ID:", rawApp?.doctor);

//     // Query via Mongoose and populate doctor
//     const app = await Appointment.findOne({}).sort({ createdAt: -1 }).populate({
//       path: "doctor",
//       populate: {
//         path: "userId",
//         select: "fullName avatar"
//       }
//     });

//     if (!app) {
//       console.log("No appointments found via Mongoose.");
//       process.exit(0);
//     }

//     console.log("Populated Mongoose Appointment:");
//     console.log("  Doctor field type:", typeof app.doctor);
//     console.log("  Doctor value:", app.doctor);

//     if (app.doctor) {
//       const doc = app.doctor as any;
//       console.log("  Doctor Profile ID:", doc._id);
//       console.log("  Doctor userId field:", doc.userId);
//     }

//     process.exit(0);
//   } catch (err) {
//     console.error("Error:", err);
//     process.exit(1);
//   }
// }

// run();
