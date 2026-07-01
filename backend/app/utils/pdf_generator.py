# -*- coding: utf-8 -*-
from datetime import datetime
from io import BytesIO
import os
from playwright.sync_api import sync_playwright
FONT_PATH = os.path.join(os.path.dirname(__file__), "fonts/NotoSansTamil-Regular.ttf")
RECEIPT_HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ta">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Tamil:wght@400;700&display=swap" rel="stylesheet">
    <style>
        @font-face {
            font-family: 'TamilFont';
            src: url('fonts/NotoSansTamil-Regular.ttf') format('truetype');
        }
        body {
            font-family: 'TamilFont', 'Noto Sans Tamil', sans-serif;
            margin: 0;
            padding: 0;
            color: #1A1A1A;
            background-color: transparent;
            font-size: 9px;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }
        .container {
            width: 100%;
            box-sizing: border-box;
        }
        .center {
            text-align: center;
        }
        .om-symbol {
            font-size: 20px;
            margin-bottom: 2px;
        }
        .temple-title {
            font-size: 13px;
            color: #CC4400; /* DARK_ORANGE */
            margin: 0 0 1px 0;
            line-height: 16px;
            font-weight: bold;
        }
        .temple-subtitle {
            font-size: 8px;
            color: #1A1A1A; /* DARK */
            margin: 0 0 1px 0;
        }
        .divider-thick {
            border: none;
            height: 2px;
            background-color: #FF6B00; /* SAFFRON */
            margin: 8px 0;
        }
        .receipt-banner {
            background-color: #FF6B00; /* SAFFRON */
            color: white;
            text-align: center;
            padding: 6px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
            margin-bottom: 8px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 8px;
        }
        .info-table {
            background-color: #FFF8F0; /* CREAM */
        }
        .info-table td {
            border: 0.5px solid #DDDDDD;
            padding: 4px 5px;
            vertical-align: middle;
        }
        .label-col {
            width: 37.8%; /* 50mm of 132mm */
            color: #666666;
            font-size: 8px;
        }
        .value-col {
            width: 62.2%; /* 82mm of 132mm */
            font-size: 9px;
        }
        .devotee-header {
            background-color: #D4A017; /* GOLD */
            color: white;
            text-align: center;
            padding: 4px;
            font-size: 9px;
            font-weight: bold;
            margin-bottom: 0;
        }
        .devotee-table {
            background-color: white;
            margin-top: 0;
        }
        .devotee-table td {
            border: 0.5px solid #DDDDDD;
            padding: 4px 5px;
            vertical-align: middle;
        }
        .amount-box {
            background-color: #FFE0B2; /* LIGHT_ORANGE */
            border: 2px solid #FF6B00; /* SAFFRON */
            border-radius: 6px;
            padding: 8px;
            text-align: center;
            font-size: 18px;
            color: #CC4400; /* DARK_ORANGE */
            font-weight: bold;
            margin-bottom: 4px;
        }
        .amount-words {
            font-size: 8px;
            color: #CC4400; /* DARK_ORANGE */
            text-align: center;
            margin-bottom: 8px;
        }
        .remarks {
            font-size: 8px;
            color: #555555;
            margin-bottom: 8px;
        }
        .divider-thin {
            border: none;
            height: 0.5px;
            background-color: #CCCCCC;
            margin: 6px 0;
        }
        .staff-table td {
            padding: 2px 0;
            vertical-align: middle;
        }
        .divider-footer {
            border: none;
            height: 1px;
            background-color: #D4A017; /* GOLD */
            margin: 8px 0 6px 0;
        }
        .footer-text {
            font-size: 7px;
            color: #888888;
            text-align: center;
            margin: 0 0 2px 0;
        }
        .blessing-text {
            font-size: 8px;
            color: #FF6B00; /* SAFFRON */
            text-align: center;
            margin-top: 4px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="center om-symbol">🕉</div>
        <div class="center temple-title">செம்புகுட்டி சாஸ்தா திருக்கோவில்</div>
        <div class="center temple-subtitle">Sembugutti Saastha Thirukoil</div>
        <div class="center temple-subtitle">Billing & Receipt Management System</div>
        
        <hr class="divider-thick">
        
        <div class="receipt-banner">
            ரசீது எண் / RECEIPT NO: {receipt_no}
        </div>
        
        <table class="info-table">
            <tr>
                <td class="label-col">தேதி / Date</td>
                <td class="value-col">{date_str}</td>
            </tr>
            <tr>
                <td class="label-col">பில் வகை / Type</td>
                <td class="value-col">{bill_type}</td>
            </tr>
            <tr>
                <td class="label-col">வகை / Category</td>
                <td class="value-col">{category}</td>
            </tr>
            <tr>
                <td class="label-col">பணம் செலுத்தும் முறை</td>
                <td class="value-col">{payment_method}</td>
            </tr>
            {transaction_row}
        </table>
        
        <div class="devotee-header">
            பக்தர் விவரம் / DEVOTEE DETAILS
        </div>
        
        <table class="devotee-table">
            <tr>
                <td class="label-col">பெயர் / Name</td>
                <td class="value-col">{devotee_name}</td>
            </tr>
            <tr>
                <td class="label-col">தந்தை பெயர்</td>
                <td class="value-col">{father_name}</td>
            </tr>
            <tr>
                <td class="label-col">கைபேசி / Mobile</td>
                <td class="value-col">{mobile}</td>
            </tr>
            <tr>
                <td class="label-col">ஊர் / Village</td>
                <td class="value-col">{village}</td>
            </tr>
        </table>
        
        <div class="amount-box">
            ₹ {amount_str}
        </div>
        
        <div class="amount-words">
            ({amount_words_str})
        </div>
        
        {remarks_section}
        
        <hr class="divider-thin">
        
        <table class="staff-table">
            <tr>
                <td class="label-col">பணியாளர் / Staff:</td>
                <td class="value-col">{staff_name}</td>
            </tr>
        </table>
        
        <hr class="divider-footer">
        
        <div class="footer-text">இந்த ரசீது கணினி மூலம் உருவாக்கப்பட்டது</div>
        <div class="footer-text">This is a computer-generated receipt</div>
        <div class="blessing-text">🙏 தெய்வ ஆசி உங்களுக்கு கிடைக்கட்டும் 🙏</div>
    </div>
</body>
</html>
"""
REPORT_HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ta">
<head>
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Tamil:wght@400;700&display=swap" rel="stylesheet">
    <style>
        @font-face {
            font-family: 'TamilFont';
            src: url('fonts/NotoSansTamil-Regular.ttf') format('truetype');
        }
        body {
            font-family: 'TamilFont', 'Noto Sans Tamil', sans-serif;
            margin: 0;
            padding: 0;
            color: #1A1A1A;
            background-color: transparent;
            font-size: 9px;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }
        .container {
            width: 100%;
            box-sizing: border-box;
        }
        .center {
            text-align: center;
        }
        .title {
            font-size: 16px;
            color: #CC4400; /* DARK_ORANGE */
            margin: 0 0 4px 0;
            font-weight: bold;
        }
        .subtitle {
            font-size: 12px;
            color: #1A1A1A; /* DARK */
            margin: 0 0 5px 0;
        }
        .divider-thick {
            border: none;
            height: 2px;
            background-color: #FF6B00; /* SAFFRON */
            margin: 10px 0;
        }
        table.report-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        table.report-table th {
            background-color: #FF6B00; /* SAFFRON */
            color: white;
            font-size: 10px;
            font-weight: bold;
            padding: 5px;
            border: 0.5px solid #DDDDDD;
            text-align: center;
        }
        table.report-table td {
            font-size: 9px;
            padding: 5px;
            border: 0.5px solid #DDDDDD;
            text-align: center;
        }
        table.report-table tr:nth-child(even) td {
            background-color: #FFF8F0; /* CREAM */
        }
        table.report-table tr:nth-child(odd) td {
            background-color: white;
        }
        thead {
            display: table-header-group;
        }
        tr {
            page-break-inside: avoid;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="center title">செம்புகுட்டி சாஸ்தா திருக்கோவில்</div>
        <div class="center subtitle">{report_type} Report</div>
        
        <hr class="divider-thick">
        
        {table_content}
    </div>
</body>
</html>
"""
def _run_via_subprocess(func_name: str, data: dict, report_type: str = None) -> bytes:
    import subprocess
    import json
    import sys
    import tempfile
    
    # Write data to a temp JSON file
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w", encoding="utf-8") as f:
        json.dump({"data": data, "report_type": report_type}, f)
        temp_json_path = f.name
        
    temp_pdf_path = temp_json_path + ".pdf"
    
    try:
        # Call pdf_generator.py as a script
        script_path = os.path.abspath(__file__)
        result = subprocess.run(
            [sys.executable, script_path, func_name, temp_json_path, temp_pdf_path],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode != 0:
            raise RuntimeError(f"PDF generation subprocess failed with code {result.returncode}. Stderr: {result.stderr}")
            
        with open(temp_pdf_path, "rb") as f:
            pdf_bytes = f.read()
        return pdf_bytes
    finally:
        # Cleanup temp files
        for p in (temp_json_path, temp_pdf_path):
            if os.path.exists(p):
                try:
                    os.remove(p)
                except Exception:
                    pass
def generate_receipt_pdf(bill_data: dict, force_local: bool = False) -> bytes:
    import sys
    if sys.platform == 'win32' and not force_local:
        return _run_via_subprocess("generate_receipt_pdf", bill_data)
    # Handle date parsing
    bill_date = bill_data.get('bill_date', datetime.now())
    if isinstance(bill_date, str):
        bill_date = datetime.fromisoformat(bill_date)
    date_str = bill_date.strftime("%d-%m-%Y %I:%M %p")
    
    # Handle transaction ID row
    transaction_row = ""
    if bill_data.get('transaction_id'):
        transaction_row = f"""
        <tr>
            <td class="label-col">பரிவர்த்தனை எண்</td>
            <td class="value-col">{bill_data['transaction_id']}</td>
        </tr>
        """
        
    # Handle remarks section
    remarks_section = ""
    if bill_data.get('remarks'):
        remarks_section = f"""
        <div class="remarks">
            குறிப்பு: {bill_data['remarks']}
        </div>
        """
        
    # Format amount
    amount = bill_data.get('amount', 0)
    amount_str = f"{float(amount):,.2f}"
    amount_words_str = amount_in_words(float(amount))
    
    # Fill receipt template
    html_content = RECEIPT_HTML_TEMPLATE
    html_content = html_content.replace("{receipt_no}", bill_data.get('receipt_no', ''))
    html_content = html_content.replace("{date_str}", date_str)
    html_content = html_content.replace("{bill_type}", bill_data.get('bill_type', ''))
    html_content = html_content.replace("{category}", bill_data.get('category', '-'))
    html_content = html_content.replace("{payment_method}", bill_data.get('payment_method', ''))
    html_content = html_content.replace("{transaction_row}", transaction_row)
    html_content = html_content.replace("{devotee_name}", bill_data.get('devotee_name', ''))
    html_content = html_content.replace("{father_name}", bill_data.get('father_name', '-'))
    html_content = html_content.replace("{mobile}", bill_data.get('mobile', '-'))
    html_content = html_content.replace("{village}", bill_data.get('village', '-'))
    html_content = html_content.replace("{amount_str}", amount_str)
    html_content = html_content.replace("{amount_words_str}", amount_words_str)
    html_content = html_content.replace("{remarks_section}", remarks_section)
    html_content = html_content.replace("{staff_name}", bill_data.get('staff_name', ''))
    # Render with Playwright
    base_dir = os.path.dirname(os.path.abspath(__file__))
    temp_file_path = os.path.join(base_dir, "temp_receipt.html")
    with open(temp_file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
        
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context()
            page = context.new_page()
            
            file_url = f"file:///{temp_file_path.replace(os.sep, '/')}"
            page.goto(file_url)
            page.wait_for_load_state("networkidle")
            
            # Output A5 PDF (148mm x 210mm) with 6mm top/bottom & 8mm left/right margins
            pdf_bytes = page.pdf(
                width="148mm",
                height="210mm",
                margin={
                    "top": "6mm",
                    "bottom": "6mm",
                    "left": "8mm",
                    "right": "8mm"
                },
                print_background=True
            )
            browser.close()
            return pdf_bytes
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
def amount_in_words(amount: float) -> str:
    """Convert amount to words (simplified)"""
    ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
            "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
            "Seventeen", "Eighteen", "Nineteen"]
    tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]
    
    int_amount = int(amount)
    
    if int_amount == 0:
        return "Zero Rupees Only"
    
    def helper(n):
        if n == 0:
            return ""
        elif n < 20:
            return ones[n]
        elif n < 100:
            return tens[n // 10] + (" " + ones[n % 10] if n % 10 else "")
        elif n < 1000:
            return ones[n // 100] + " Hundred" + (" " + helper(n % 100) if n % 100 else "")
        elif n < 100000:
            return helper(n // 1000) + " Thousand" + (" " + helper(n % 1000) if n % 1000 else "")
        elif n < 10000000:
            return helper(n // 100000) + " Lakh" + (" " + helper(n % 100000) if n % 100000 else "")
        else:
            return helper(n // 10000000) + " Crore" + (" " + helper(n % 10000000) if n % 10000000 else "")
    
    return helper(int_amount) + " Rupees Only"
def generate_report_pdf(report_data: dict, report_type: str, force_local: bool = False) -> bytes:
    import sys
    if sys.platform == 'win32' and not force_local:
        return _run_via_subprocess("generate_report_pdf", report_data, report_type)
    headers = report_data.get('headers', [])
    rows = report_data.get('rows', [])
    
    # Build HTML table content
    table_content = '<table class="report-table">'
    if headers:
        table_content += "<thead><tr>"
        for header in headers:
            table_content += f"<th>{header}</th>"
        table_content += "</tr></thead>"
    
    if rows:
        table_content += "<tbody>"
        for row in rows:
            table_content += "<tr>"
            for cell in row:
                table_content += f"<td>{cell}</td>"
            table_content += "</tr>"
        table_content += "</tbody>"
    table_content += "</table>"
    
    # Fill report template
    html_content = REPORT_HTML_TEMPLATE
    html_content = html_content.replace("{report_type}", report_type)
    html_content = html_content.replace("{table_content}", table_content)
    # Render with Playwright
    base_dir = os.path.dirname(os.path.abspath(__file__))
    temp_file_path = os.path.join(base_dir, "temp_report.html")
    with open(temp_file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
        
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context()
            page = context.new_page()
            
            file_url = f"file:///{temp_file_path.replace(os.sep, '/')}"
            page.goto(file_url)
            page.wait_for_load_state("networkidle")
            
            # Output A4 PDF (210mm x 297mm) with 15mm margins
            pdf_bytes = page.pdf(
                format="A4",
                margin={
                    "top": "15mm",
                    "bottom": "15mm",
                    "left": "15mm",
                    "right": "15mm"
                },
                print_background=True
            )
            browser.close()
            return pdf_bytes
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
if __name__ == "__main__":
    import sys
    import json
    
    if len(sys.argv) < 4:
        print("Usage: python pdf_generator.py [function_name] [json_input_path] [pdf_output_path]", file=sys.stderr)
        sys.exit(1)
        
    func_name = sys.argv[1]
    json_path = sys.argv[2]
    pdf_path = sys.argv[3]
    
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            payload = json.load(f)
            
        if func_name == "generate_receipt_pdf":
            pdf_bytes = generate_receipt_pdf(payload["data"], force_local=True)
        elif func_name == "generate_report_pdf":
            pdf_bytes = generate_report_pdf(payload["data"], payload["report_type"], force_local=True)
        else:
            print(f"Unknown function name: {func_name}", file=sys.stderr)
            sys.exit(1)
            
        with open(pdf_path, "wb") as f:
            f.write(pdf_bytes)
        sys.exit(0)
    except Exception as e:
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
