import cron from "node-cron";
import Appointment from "../models/Appointment";

export const startCronJobs = () => {
  cron.schedule("* * * * *", async () => {
    console.log("⏰ Checking missed appointments...");

    const now = new Date();

    const result = await Appointment.updateMany(
      {
        status: "confirmed",
        $expr: {
          $lt: [
            {
              $toDate: {
                $concat: ["$date", "T", "$time"]
              }
            },
            now
          ]
        }
      },
      {
        $set: { status: "missed" }
      }
    );

    console.log(`✅ Updated ${result.modifiedCount} appointments to missed`);
  });
};