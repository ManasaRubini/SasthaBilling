# -*- coding: utf-8 -*-
from datetime import datetime
import os
import sys
import base64
import json
import logging
from pathlib import Path
from jinja2 import Template
from playwright.sync_api import sync_playwright

logger = logging.getLogger("uvicorn.error")

# Setup project directories
UTILS_DIR = Path(__file__).resolve().parent
FONTS_DIR = UTILS_DIR / "fonts"
FONT_PATH = FONTS_DIR / "NotoSansTamil-Regular.ttf"

# Load templates using Path resolution
APP_DIR = UTILS_DIR.parent
TEMPLATES_DIR = APP_DIR / "templates"
RECEIPT_TEMPLATE_PATH = TEMPLATES_DIR / "receipt.html"
REPORT_TEMPLATE_PATH = TEMPLATES_DIR / "report.html"

# Load font base64 helper
def get_font_base64() -> str:
    if FONT_PATH.exists():
        try:
            with open(FONT_PATH, "rb") as f:
                return base64.b64encode(f.read()).decode("utf-8")
        except Exception as e:
            logger.error(f"Error reading font file: {e}")
    else:
        logger.warning(f"Font file not found at: {FONT_PATH}")
    return ""

FONT_BASE64 = get_font_base64()

def _run_via_subprocess(func_name: str, data: dict, report_type: str = None) -> bytes:
    import subprocess
    import tempfile
    
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w", encoding="utf-8") as f:
        json.dump({"data": data, "report_type": report_type}, f)
        temp_json_path = f.name
        
    temp_pdf_path = temp_json_path + ".pdf"
    
    try:
        script_path = os.path.abspath(__file__)
        result = subprocess.run(
            [sys.executable, script_path, func_name, temp_json_path, temp_pdf_path],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode != 0:
            raise RuntimeError(f"PDF generation subprocess failed. Stderr: {result.stderr}")
            
        with open(temp_pdf_path, "rb") as f:
            pdf_bytes = f.read()
        return pdf_bytes
    finally:
        for p in (temp_json_path, temp_pdf_path):
            if os.path.exists(p):
                try:
                    os.remove(p)
                except Exception:
                    pass

def generate_receipt_pdf(bill_data: dict, force_local: bool = False) -> bytes:
    if sys.platform == 'win32' and not force_local:
        return _run_via_subprocess("generate_receipt_pdf", bill_data)
        
    # Handle date parsing
    bill_date = bill_data.get('bill_date', datetime.now())
    if isinstance(bill_date, str):
        bill_date = datetime.fromisoformat(bill_date)
    date_str = bill_date.strftime("%d-%m-%Y %I:%M %p")
    
    amount = bill_data.get('amount', 0)
    amount_words_str = amount_in_words(float(amount))
    
    # Read template file
    if not RECEIPT_TEMPLATE_PATH.exists():
        raise FileNotFoundError(f"Receipt template missing at {RECEIPT_TEMPLATE_PATH}")
        
    with open(RECEIPT_TEMPLATE_PATH, "r", encoding="utf-8") as f:
        template_content = f.read()
        
    # Render with Jinja2
    template = Template(template_content)
    bill_dict = {
        "receipt_no": bill_data.get("receipt_no", ""),
        "bill_type": bill_data.get("bill_type", ""),
        "category": bill_data.get("category", ""),
        "payment_method": bill_data.get("payment_method", ""),
        "transaction_id": bill_data.get("transaction_id"),
        "devotee_name": bill_data.get("devotee_name", ""),
        "father_name": bill_data.get("father_name", ""),
        "mobile": bill_data.get("mobile", ""),
        "village": bill_data.get("village", ""),
        "amount": amount,
        "remarks": bill_data.get("remarks"),
        "staff_name": bill_data.get("staff_name", "")
    }
    
    html_content = template.render(
        bill=bill_dict,
        formatted_date=date_str,
        amount_words=amount_words_str,
        font_base64=FONT_BASE64
    )
    
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
            
            # Wait for font and page layout
            page.evaluate("document.fonts.ready")
            page.wait_for_load_state("networkidle")
            
            # Output A5 PDF
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
    except Exception as e:
        logger.error(f"Playwright receipt PDF generation error: {e}")
        raise e
    finally:
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception:
                pass

def amount_in_words(amount: float) -> str:
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
    if sys.platform == 'win32' and not force_local:
        return _run_via_subprocess("generate_report_pdf", report_data, report_type)
        
    if not REPORT_TEMPLATE_PATH.exists():
        raise FileNotFoundError(f"Report template missing at {REPORT_TEMPLATE_PATH}")
        
    with open(REPORT_TEMPLATE_PATH, "r", encoding="utf-8") as f:
        template_content = f.read()
        
    template = Template(template_content)
    html_content = template.render(
        report_type=report_type,
        report=report_data,
        generated_on=datetime.now().strftime("%d-%m-%Y %I:%M %p"),
        font_base64=FONT_BASE64
    )
    
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
            
            # Wait for fonts to load
            page.evaluate("document.fonts.ready")
            page.wait_for_load_state("networkidle")
            
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
    except Exception as e:
        logger.error(f"Playwright report PDF generation error: {e}")
        raise e
    finally:
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception:
                pass

if __name__ == "__main__":
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
