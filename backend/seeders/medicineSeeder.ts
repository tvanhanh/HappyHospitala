import mongoose from "mongoose";
import dotenv from "dotenv";
import connectDB from "../config/db";
import Medicine from "../models/medicine";

dotenv.config();

const medicines = [
  // 1. Diabetes / Endocrinology
  {
    medicineCode: "MED-001",
    name: "Glucophage",
    activeIngredient: "Metformin 500mg",
    category: "Thuốc tiểu đường",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 1500,
    reorderLevel: 200,
    unitPrice: 1500,
    expiryDate: new Date("2028-12-31"),
    manufacturer: "Merck"
  },
  {
    medicineCode: "MED-002",
    name: "Diamicron MR",
    activeIngredient: "Gliclazide 30mg",
    category: "Thuốc tiểu đường",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 80, // Low stock to test alerts
    reorderLevel: 100,
    unitPrice: 3500,
    expiryDate: new Date("2027-08-15"),
    manufacturer: "Servier"
  },
  {
    medicineCode: "MED-003",
    name: "Lantus SoloStar",
    activeIngredient: "Insulin glargine 100 U/mL",
    category: "Thuốc tiểu đường",
    routeOfAdministration: "Tiêm",
    unit: "Hộp",
    stockLevel: 45,
    reorderLevel: 15,
    unitPrice: 320000,
    expiryDate: new Date("2027-04-20"),
    manufacturer: "Sanofi"
  },
  {
    medicineCode: "MED-004",
    name: "Jardiance",
    activeIngredient: "Empagliflozin 10mg",
    category: "Thuốc tiểu đường",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 600,
    reorderLevel: 100,
    unitPrice: 22000,
    expiryDate: new Date("2028-01-10"),
    manufacturer: "Boehringer Ingelheim"
  },
  // 2. Dermatology
  {
    medicineCode: "MED-005",
    name: "Nizoral Cream",
    activeIngredient: "Ketoconazole 2%",
    category: "Da liễu",
    routeOfAdministration: "Bôi ngoài da",
    unit: "Tuýp",
    stockLevel: 120,
    reorderLevel: 30,
    unitPrice: 35000,
    expiryDate: new Date("2027-11-30"),
    manufacturer: "Janssen"
  },
  {
    medicineCode: "MED-006",
    name: "Klenzit MS",
    activeIngredient: "Adapalene 0.1%",
    category: "Da liễu",
    routeOfAdministration: "Bôi ngoài da",
    unit: "Tuýp",
    stockLevel: 5, // Low stock to test low-stock alerts
    reorderLevel: 20,
    unitPrice: 95000,
    expiryDate: new Date("2027-09-01"),
    manufacturer: "Glenmark"
  },
  {
    medicineCode: "MED-007",
    name: "Kortan Salic",
    activeIngredient: "Salicylic acid 5%",
    category: "Da liễu",
    routeOfAdministration: "Bôi ngoài da",
    unit: "Tuýp",
    stockLevel: 150,
    reorderLevel: 25,
    unitPrice: 25000,
    expiryDate: new Date("2026-08-01"), // Expiring soon to test expiration warnings
    manufacturer: "Dược Hậu Giang"
  },
  // 3. General / Pain relief
  {
    medicineCode: "MED-008",
    name: "Hapacol 650",
    activeIngredient: "Paracetamol 650mg",
    category: "Giảm đau hạ sốt",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 5000,
    reorderLevel: 500,
    unitPrice: 800,
    expiryDate: new Date("2029-06-30"),
    manufacturer: "Dược Hậu Giang"
  },
  {
    medicineCode: "MED-009",
    name: "Panadol Extra",
    activeIngredient: "Paracetamol 500mg, Caffeine 65mg",
    category: "Giảm đau hạ sốt",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 3500,
    reorderLevel: 500,
    unitPrice: 1200,
    expiryDate: new Date("2029-03-15"),
    manufacturer: "GSK"
  },
  {
    medicineCode: "MED-010",
    name: "Gofen 400",
    activeIngredient: "Ibuprofen 400mg",
    category: "Giảm đau kháng viêm",
    routeOfAdministration: "Uống",
    unit: "Viên",
    stockLevel: 180, // Low stock to test alerts
    reorderLevel: 200,
    unitPrice: 2500,
    expiryDate: new Date("2028-05-18"),
    manufacturer: "Mega We Care"
  },
  {
    medicineCode: "MED-011",
    name: "Voltaren Emulgel",
    activeIngredient: "Diclofenac sodium 1%",
    category: "Giảm đau kháng viêm",
    routeOfAdministration: "Bôi ngoài da",
    unit: "Tuýp",
    stockLevel: 85,
    reorderLevel: 20,
    unitPrice: 75000,
    expiryDate: new Date("2027-10-12"),
    manufacturer: "Novartis"
  },
  {
    medicineCode: "MED-012",
    name: "Augmentin 1g",
    activeIngredient: "Amoxicillin 875mg, Clavulanic acid 125mg",
    category: "Kháng sinh",
    routeOfAdministration: "Uống",
    unit: "Hộp",
    stockLevel: 300,
    reorderLevel: 50,
    unitPrice: 280000,
    expiryDate: new Date("2027-02-28"),
    manufacturer: "GSK"
  }
];

const seedMedicines = async () => {
  try {
    await connectDB();
    console.log("MongoDB Connected for Medicine Seeding...");

    // Clear existing medicines to avoid unique key index duplication errors
    await Medicine.deleteMany({});
    console.log("Cleared existing medicines.");

    await Medicine.insertMany(medicines);
    console.log("Medicines seeded successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Medicine seeding failed:", error);
    process.exit(1);
  }
};

seedMedicines();
