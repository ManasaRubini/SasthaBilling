# -*- coding: utf-8 -*-
import os
import sys
import csv
import re

# Add current directory to python path to import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models.models import Devotee

def clean_header(header):
    return header.strip().lower().replace(" ", "_").replace("'", "").replace("\"", "")

def read_csv(file_path):
    devotees = []
    with open(file_path, mode="r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        # Clean headers
        headers_map = {clean_header(h): h for h in reader.fieldnames or []}
        
        # Helper to find matching keys
        def get_value(row, keys):
            for k in keys:
                cleaned_k = clean_header(k)
                if cleaned_k in headers_map:
                    return row[headers_map[cleaned_k]]
            return None

        for row in reader:
            name = get_value(row, ["name", "devotee_name", "devotee name", "பெயர்"])
            if not name:
                continue  # Name is required
                
            father = get_value(row, ["father_name", "father name", "father", "தந்தை பெயர்"])
            mobile = get_value(row, ["mobile", "phone", "phone_number", "கைபேசி", "அலைபேசி எண்", "அலைபேசி"])
            address = get_value(row, ["address", "முகவரி"])
            village = get_value(row, ["village", "place", "ஊர்"])
            family_id = get_value(row, ["family_id", "family id", "family", "குடும்ப எண்"])

            devotees.append({
                "devotee_name": name.strip(),
                "father_name": father.strip() if father else None,
                "mobile": mobile.strip() if mobile else None,
                "address": address.strip() if address else None,
                "village": village.strip() if village else None,
                "family_id": family_id.strip() if family_id else None,
            })
    return devotees

def read_excel(file_path):
    try:
        import pandas as pd
    except ImportError:
        print("\n[ERROR] pandas is not installed. To import Excel files directly, please run:")
        print("    pip install pandas openpyxl")
        print("\nAlternatively, save your Excel sheet as a CSV file and run this script with the CSV file.")
        sys.exit(1)

    df = pd.read_excel(file_path)
    
    # Try to detect vertical layout with serial numbers in first column
    import re
    first_col_vals = df.iloc[:, 0].dropna().tolist()
    serial_count = 0
    for v in first_col_vals[:20]:
        try:
            if isinstance(v, (int, float)) and int(v) < 1000:
                serial_count += 1
            elif str(v).strip().isdigit() and int(str(v).strip()) < 1000:
                serial_count += 1
        except:
            pass
            
    if serial_count >= 3:
        print("Detected vertical address book layout (repeating serial numbers). Parsing...")
        devotees = []
        cur = None
        state = 'NONE'
        
        for val in df.iloc[:, 0].tolist():
            if pd.isna(val):
                continue
            
            is_serial = False
            try:
                if isinstance(val, (int, float)):
                    if int(val) < 10000:
                        is_serial = True
                elif str(val).strip().isdigit() and int(str(val).strip()) < 10000:
                    is_serial = True
            except:
                pass
                
            if is_serial:
                if cur and cur.get('devotee_name'):
                    devotees.append(cur)
                cur = {
                    'devotee_name': None,
                    'father_name': None,
                    'mobile': None,
                    'address': None,
                    'village': None,
                    'family_id': None
                }
                state = 'NAME'
            else:
                if cur is None:
                    continue
                if state == 'NAME':
                    cur['devotee_name'] = str(val).strip()
                    state = 'DETAILS'
                elif state == 'DETAILS':
                    v_str = str(val).strip()
                    if v_str.lower() in ['(blank)', 'blank', '-', 'nan']:
                        continue
                    
                    dig = re.sub(r'\D', '', v_str)
                    if len(dig) >= 9 and (len(dig) / len(v_str)) > 0.6:
                        cur['mobile'] = v_str
                    else:
                        cur['address'] = (cur['address'] + ', ' + v_str) if cur['address'] else v_str
                        
        if cur and cur.get('devotee_name'):
            devotees.append(cur)
            
        return devotees

    # Clean headers for standard tabular files
    df.columns = [clean_header(str(c)) for c in df.columns]
    
    # Helper to find matching keys
    def get_column(keys):
        for k in keys:
            if k in df.columns:
                return k
        return None

    name_col = get_column(["name", "devotee_name", "devotee name", "பெயர்"])
    if not name_col:
        print("[ERROR] Could not find a 'Name' or 'Devotee Name' column in the Excel file.")
        print(f"Columns found in file: {list(df.columns)}")
        sys.exit(1)

    father_col = get_column(["father_name", "father name", "father", "தந்தை பெயர்"])
    mobile_col = get_column(["mobile", "phone", "phone_number", "கைபேசி", "அலைபேசி எண்", "அலைபேசி"])
    address_col = get_column(["address", "முகவரி"])
    village_col = get_column(["village", "place", "ஊர்"])
    family_col = get_column(["family_id", "family id", "family", "குடும்ப எண்"])

    devotees = []
    for _, row in df.iterrows():
        name = str(row[name_col]).strip()
        if not name or name == "nan" or name == "":
            continue

        father = str(row[father_col]).strip() if father_col and pd.notna(row[father_col]) else None
        mobile = str(row[mobile_col]).strip() if mobile_col and pd.notna(row[mobile_col]) else None
        address = str(row[address_col]).strip() if address_col and pd.notna(row[address_col]) else None
        village = str(row[village_col]).strip() if village_col and pd.notna(row[village_col]) else None
        family_id = str(row[family_col]).strip() if family_col and pd.notna(row[family_col]) else None

        devotees.append({
            "devotee_name": name,
            "father_name": father if father != "nan" else None,
            "mobile": mobile if mobile != "nan" else None,
            "address": address if address != "nan" else None,
            "village": village if village != "nan" else None,
            "family_id": family_id if family_id != "nan" else None,
        })
def clean_mobile_and_extra(mobile_str, address_str):
    if not mobile_str:
        return None, address_str
        
    mobile_str = str(mobile_str).strip()
    if len(mobile_str) <= 15:
        return mobile_str, address_str
        
    # Split by common separators: space, comma, slash, semicolon
    parts = re.split(r'[\s,/;]+', mobile_str)
    first_num = None
    extra_nums = []
    
    for p in parts:
        p_clean = re.sub(r'\D', '', p)
        if len(p_clean) >= 9:
            if not first_num:
                first_num = p
            else:
                extra_nums.append(p)
        else:
            if p.strip() and p.strip().lower() not in ['nan']:
                extra_nums.append(p)
                
    if not first_num:
        return mobile_str[:15], address_str
        
    if extra_nums:
        extra_info = "Extra Phone: " + ", ".join(extra_nums)
        if address_str and str(address_str).lower() != 'nan':
            address_str = f"{address_str} ({extra_info})"
        else:
            address_str = extra_info
            
    return first_num[:15], address_str

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python import_devotees.py <path_to_excel_or_csv_file>")
        sys.exit(1)

    file_path = sys.argv[1]
    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        sys.exit(1)

    _, ext = os.path.splitext(file_path.lower())
    
    print("Reading file...")
    if ext == ".csv":
        devotees_data = read_csv(file_path)
    elif ext in [".xlsx", ".xls"]:
        devotees_data = read_excel(file_path)
    else:
        print("[ERROR] Unsupported file extension. Please use .csv or .xlsx")
        sys.exit(1)

    if not devotees_data:
        print("[WARNING] No valid devotee records found in the file.")
        sys.exit(0)

    print(f"Found {len(devotees_data)} devotee records to import.")
    
    db = SessionLocal()
    try:
        print("Fetching existing devotees from database to check duplicates...")
        existing_devotees = db.query(Devotee.devotee_name, Devotee.mobile).all()
        existing_combos = set((name, mobile) for name, mobile in existing_devotees)
        existing_names = set(name for name, _ in existing_devotees)

        print("Filtering records...")
        to_insert = []
        for data in devotees_data:
            # Clean mobile and append extra numbers to address
            mobile, address = clean_mobile_and_extra(data["mobile"], data["address"])
            data["mobile"] = mobile
            data["address"] = address

            name = data["devotee_name"]

            if mobile:
                if (name, mobile) in existing_combos:
                    continue
            else:
                if name in existing_names:
                    continue

            to_insert.append(data)

        success_count = len(to_insert)
        if to_insert:
            print(f"Uploading {success_count} records to database...")
            for data in to_insert:
                devotee = Devotee(
                    devotee_name=data["devotee_name"],
                    father_name=data["father_name"],
                    mobile=data["mobile"],
                    address=data["address"],
                    village=data["village"],
                    family_id=data["family_id"]
                )
                db.add(devotee)
            db.commit()
            print(f"\n[SUCCESS] Imported {success_count} new devotees successfully! (Skipped duplicates)")
        else:
            print("\n[INFO] All records in the Excel file are already present in the database. No new records to import.")
    except Exception as e:
        db.rollback()
        print(f"\n[ERROR] Database import failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
