# -*- coding: utf-8 -*-
import os
import sys
import csv

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
    # Clean headers
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
    return devotees

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
        success_count = 0
        for data in devotees_data:
            # Check if devotee already exists (by name and mobile to avoid duplicates)
            exists = False
            if data["mobile"]:
                exists = db.query(Devotee).filter(
                    Devotee.devotee_name == data["devotee_name"],
                    Devotee.mobile == data["mobile"]
                ).first() is not None
            else:
                exists = db.query(Devotee).filter(
                    Devotee.devotee_name == data["devotee_name"]
                ).first() is not None

            if exists:
                # Skip duplicate
                continue

            devotee = Devotee(
                devotee_name=data["devotee_name"],
                father_name=data["father_name"],
                mobile=data["mobile"],
                address=data["address"],
                village=data["village"],
                family_id=data["family_id"]
            )
            db.add(devotee)
            success_count += 1

        db.commit()
        print(f"\n[SUCCESS] Imported {success_count} new devotees successfully! (Skipped duplicates)")
    except Exception as e:
        db.rollback()
        print(f"\n[ERROR] Database import failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
