"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkProfile = void 0;
const checkProfile = (user, type = "basic") => {
    const profile = user?.profile || user; // fallback cực quan trọng
    const missingFields = [];
    if (!profile.phone?.trim())
        missingFields.push("phone");
    if (!profile.gender?.trim())
        missingFields.push("gender");
    if (!profile.address?.trim())
        missingFields.push("address");
    if (type === "medical") {
        if (!profile.healthInsurance?.trim())
            missingFields.push("healthInsurance");
    }
    if (type === "derma") {
        if (!profile.skinType?.trim())
            missingFields.push("skinType");
        if (!profile.skinCondition?.trim())
            missingFields.push("skinCondition");
    }
    return {
        isComplete: missingFields.length === 0,
        missingFields,
        level: type,
    };
};
exports.checkProfile = checkProfile;
