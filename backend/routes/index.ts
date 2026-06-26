import { Router } from 'express';
import auth_routes from './auth_routes';
import admin_routes from './adminRoutes';
import patient_routes from './patientRoutes';
import doctor_routes from './doctor_routes';
import appointment_routes from './appointment_routes';

// System-wide routes
import specialty_routes from './specialtyRoutes';
import room_routes from './roomRoutes';
import slider_routes from './sliderRoutes';
import promotion_routes from "./promotionRoutes";
import salary_routes from "./salaryRoutes";
import premium_routes from "./premiumRoutes";
import advertisement_routes from "./advertisementRoutes";
import report_routes from "./reportRoutes";
import room_assignment_routes from "./roomAssignmentRoutes";
import doctor_approval_routes from "./doctorApprovalRoutes";
import pharmacyRouter from './pharmacy';
import scheduleRouter from './scheduleRoutes';
import ai_routes from './aiRoutes';
import qaRouter from './qaRoutes';

const router = Router();

// 1. Authentication
router.use('/auth', auth_routes);
router.use('/', pharmacyRouter);

// 2. Role-based Endpoints
router.use('/admin', admin_routes);
router.use('/admin/patients', patient_routes); // admin-facing patient list
router.use('/patient', patient_routes);
router.use('/doctor', doctor_routes);
router.use('/doctors', doctor_routes); // keep both for backward compatibility

// 3. Domain-specific Endpoints (shared resources)
router.use('/appointments', appointment_routes);
router.use('/specialties', specialty_routes);
router.use('/rooms', room_routes);
router.use('/sliders', slider_routes);
router.use('/promotions', promotion_routes);
router.use('/salaries', salary_routes);
router.use('/premiums', premium_routes);
router.use('/advertisements', advertisement_routes);
router.use('/reports', report_routes);
router.use('/room-assignments', room_assignment_routes);
router.use('/doctor-approval', doctor_approval_routes);
router.use('/schedules', scheduleRouter);
router.use('/ai', ai_routes);
router.use('/qa', qaRouter);
router.use('/services', require('./serviceRoutes').default);
export default router;
