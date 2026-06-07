const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, 'lib');

const replacements = {
  "'/login'": "'/auth/login'",
  "'/register'": "'/auth/register'",
  "'/forgot-password'": "'/auth/forgot_password'",
  "'/change-password-reset'": "'/auth/change_password_reset'",
  "'/change-password-page'": "'/auth/change_password_page'",
  "'/admin/add-doctor'": "'/admin/add-doctor'", 
  "'/home/appointments'": "'/patient/appointments'",
  "'/home/profile'": "'/patient/profile'",
  "'/home/discussion'": "'/patient/discussion'",
  "'/home/results'": "'/patient/results'",
  "'/patient/doctor_list'": "'/patient/doctor_list'", 
  "'/patient/specialties_screen'": "'/patient/specialties_screen'",
  "'/patient/medical_facilities_screen'": "'/patient/medical_facilities_screen'",
  "'/patient/medical-records'": "'/patient/medical-records'",
  "'/patient/profile-screen'": "'/patient/profile-screen'",
  "'/patient/diagnosis_result_screen'": "'/patient/diagnosis_result_screen'",
  "'/patient/faq'": "'/patient/faq'",
};

function processDirectory(directory) {
  const files = fs.readdirSync(directory);
  for (const file of files) {
    const fullPath = path.join(directory, file);
    if (fs.statSync(fullPath).isDirectory()) {
      processDirectory(fullPath);
    } else if (fullPath.endsWith('.dart')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let changed = false;
      for (const [oldStr, newStr] of Object.entries(replacements)) {
        if (content.includes(oldStr)) {
          content = content.split(oldStr).join(newStr);
          changed = true;
        }
      }
      if (changed) {
        fs.writeFileSync(fullPath, content, 'utf8');
        console.log(`Updated ${fullPath}`);
      }
    }
  }
}

processDirectory(libDir);
console.log('Done mapping routes.');
