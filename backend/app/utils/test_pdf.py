# -*- coding: utf-8 -*-
import os
import urllib.request
from pdf_generator import generate_receipt_pdf, generate_report_pdf
def setup_font():
    """Download Noto Sans Tamil font if it is not present locally."""
    font_dir = os.path.join(os.path.dirname(__file__), "fonts")
    os.makedirs(font_dir, exist_ok=True)
    font_path = os.path.join(font_dir, "NotoSansTamil-Regular.ttf")
    
    if not os.path.exists(font_path):
        print("Tamil font not found locally. Downloading Noto Sans Tamil...")
        url = "https://github.com/notofonts/tamil/raw/main/fonts/NotoSansTamil/hinted/ttf/NotoSansTamil-Regular.ttf"
        try:
            # We can download it using urllib
            urllib.request.urlretrieve(url, font_path)
            print(f"Font downloaded successfully to: {font_path}")
        except Exception as e:
            print(f"Warning: Failed to download font: {e}")
            print("The PDF generator will fall back to using Google Fonts via the web link in the HTML template.")
def run_tests():
    setup_font()
    
    print("\n--- Test 1: Generating Receipt PDF (A5) ---")
    bill_data = {
        "receipt_no": "SSKT-20260701-0005",
        "bill_date": "2026-07-01T12:00:00",
        "bill_type": "அர்ச்சனை / Archana",
        "category": "சிறப்பு அர்ச்சனை / Special",
        "payment_method": "UPI (GPay/PhonePe)",
        "transaction_id": "TXN9876543210",
        "devotee_name": "மனோஜ் குமார் / Manoj Kumar",
        "father_name": "ராமச்சந்திரன் / Ramachandran",
        "mobile": "9876543210",
        "village": "சென்னை / Chennai",
        "amount": 250.00,
        "remarks": "ஸ்தல அபிஷேகம் மற்றும் சிறப்பு அர்ச்சனை",
        "staff_name": "அன்பழகன் / Anbazhagan"
    }
    
    try:
        receipt_pdf_bytes = generate_receipt_pdf(bill_data)
        receipt_output_path = os.path.join(os.path.dirname(__file__), "output_receipt.pdf")
        with open(receipt_output_path, "wb") as f:
            f.write(receipt_pdf_bytes)
        print(f"Success! Receipt PDF saved to: {receipt_output_path}")
    except Exception as e:
        print(f"Error generating receipt PDF: {e}")
        import traceback
        traceback.print_exc()
    print("\n--- Test 2: Generating Report PDF (A4) ---")
    report_data = {
        "headers": ["வ.எண் / S.No", "ரசீது எண் / Receipt No", "பக்தர் பெயர் / Devotee", "பில் வகை / Type", "தொகை / Amount (₹)"],
        "rows": [
            ["1", "SSKT-20260701-0001", "மனோஜ் / Manoj", "அர்ச்சனை / Archana", "100.00"],
            ["2", "SSKT-20260701-0002", "கார்த்திக் / Karthik", "அபிஷேகம் / Abishegam", "500.00"],
            ["3", "SSKT-20260701-0003", "சுரேஷ் / Suresh", "நன்கொடை / Donation", "1,000.00"],
            ["4", "SSKT-20260701-0004", "அன்பு / Anbu", "விளக்கு பூஜை / Pooja", "150.00"]
        ]
    }
    
    try:
        report_pdf_bytes = generate_report_pdf(report_data, "Daily Collection")
        report_output_path = os.path.join(os.path.dirname(__file__), "output_report.pdf")
        with open(report_output_path, "wb") as f:
            f.write(report_pdf_bytes)
        print(f"Success! Report PDF saved to: {report_output_path}")
    except Exception as e:
        print(f"Error generating report PDF: {e}")
        import traceback
        traceback.print_exc()
if __name__ == "__main__":
    run_tests()
