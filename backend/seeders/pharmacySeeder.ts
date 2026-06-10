import mongoose from 'mongoose';
import dotenv from 'dotenv';
import connectDB from '../config/db';
import Category from '../models/category';
import Medicine from '../models/medicine';

dotenv.config();

const seedPharmacy = async () => {
  try {
    await connectDB();
    console.log('MongoDB Connected for Pharmacy Seeding...');

    // Clear existing Category and Medicine data
    await Category.deleteMany({});
    await Medicine.deleteMany({});
    console.log('Cleared existing pharmacy data.');

    // 1. Create categories
    const categoriesData = [
      {
        categoryCode: 'CAT-01',
        name: 'Nội tiết - Tiểu đường',
        description: 'Các loại thuốc hỗ trợ điều trị nội tiết và đái tháo đường'
      },
      {
        categoryCode: 'CAT-02',
        name: 'Da liễu',
        description: 'Kem bôi, thuốc đặc trị các bệnh ngoài da'
      },
      {
        categoryCode: 'CAT-03',
        name: 'Giảm đau & Hạ sốt',
        description: 'Thuốc giảm đau, hạ sốt kháng viêm thông thường'
      }
    ];

    const seededCategories = await Category.insertMany(categoriesData);
    console.log('Seeded categories successfully.');

    // Map categories to IDs
    const diabetesCatId = seededCategories.find(c => c.categoryCode === 'CAT-01')!._id;
    const dermatologyCatId = seededCategories.find(c => c.categoryCode === 'CAT-02')!._id;
    const painReliefCatId = seededCategories.find(c => c.categoryCode === 'CAT-03')!._id;

    // 2. Create medicines with categories references
    const medicinesData = [
      {
        medicineCode: 'MED-001',
        name: 'Glucophage',
        activeIngredient: 'Metformin 500mg',
        categoryId: diabetesCatId,
        routeOfAdministration: 'Uống',
        unit: 'Viên',
        stockLevel: 1200,
        reorderLevel: 200,
        unitPrice: 1500,
        expiryDate: new Date('2028-12-31'),
        manufacturer: 'Merck'
      },
      {
        medicineCode: 'MED-002',
        name: 'Diamicron MR',
        activeIngredient: 'Gliclazide 30mg',
        categoryId: diabetesCatId,
        routeOfAdministration: 'Uống',
        unit: 'Viên',
        stockLevel: 80,
        reorderLevel: 100,
        unitPrice: 3500,
        expiryDate: new Date('2027-08-15'),
        manufacturer: 'Servier'
      },
      {
        medicineCode: 'MED-003',
        name: 'Nizoral Cream',
        activeIngredient: 'Ketoconazole 2%',
        categoryId: dermatologyCatId,
        routeOfAdministration: 'Bôi ngoài da',
        unit: 'Tuýp',
        stockLevel: 150,
        reorderLevel: 30,
        unitPrice: 35000,
        expiryDate: new Date('2027-11-30'),
        manufacturer: 'Janssen'
      },
      {
        medicineCode: 'MED-004',
        name: 'Hapacol 650',
        activeIngredient: 'Paracetamol 650mg',
        categoryId: painReliefCatId,
        routeOfAdministration: 'Uống',
        unit: 'Viên',
        stockLevel: 4500,
        reorderLevel: 500,
        unitPrice: 800,
        expiryDate: new Date('2029-06-30'),
        manufacturer: 'Dược Hậu Giang'
      },
      {
        medicineCode: 'MED-005',
        name: 'Gofen 400',
        activeIngredient: 'Ibuprofen 400mg',
        categoryId: painReliefCatId,
        routeOfAdministration: 'Uống',
        unit: 'Viên',
        stockLevel: 180,
        reorderLevel: 200,
        unitPrice: 2500,
        expiryDate: new Date('2028-05-18'),
        manufacturer: 'Mega We Care'
      }
    ];

    await Medicine.insertMany(medicinesData);
    console.log('Seeded medicines successfully linked to categories!');
    
    process.exit(0);
  } catch (error) {
    console.error('Seeding pharmacy database failed:', error);
    process.exit(1);
  }
};

seedPharmacy();
