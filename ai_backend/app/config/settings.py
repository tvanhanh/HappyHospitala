# app/config/settings.py
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, 'models', 'skin_cancer_epoch_20.keras')

LABELS = ['akiec', 'bcc', 'bkl', 'df', 'mel', 'nv', 'vasc']
AGE_MIN = 0.0
AGE_MAX = 85.0

EXPECTED_META_COLS = [
    'age_scaled',
    'sex_female', 'sex_male', 'sex_unknown',
    'localization_abdomen', 'localization_acral', 'localization_back', 'localization_chest',
    'localization_ear', 'localization_face', 'localization_foot',
    'localization_genital', 'localization_hand', 'localization_lower extremity',
    'localization_neck', 'localization_scalp', 'localization_trunk',
    'localization_unknown', 'localization_upper extremity'
]