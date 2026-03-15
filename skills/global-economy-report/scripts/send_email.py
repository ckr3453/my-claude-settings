#!/usr/bin/env python3
"""Global Economy Report 이메일 전송 스크립트"""

import argparse
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from pathlib import Path

try:
    import markdown
    HAS_MARKDOWN = True
except ImportError:
    HAS_MARKDOWN = False
    import re


def load_config(config_path: str) -> dict:
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def load_report(report_path: str) -> str:
    with open(report_path, 'r', encoding='utf-8') as f:
        return f.read()


def send_email(config: dict, subject: str, body_text: str, body_html: str = None):
    # 수신자 목록 (단일 또는 복수)
    recipients = config.get('recipient_emails', [])
    if not recipients:
        # 하위 호환성: 단일 수신자
        recipients = [config.get('recipient_email')]

    message = MIMEMultipart('alternative')
    message['Subject'] = subject
    message['From'] = config['sender_email']
    message['To'] = ', '.join(recipients)

    # Plain text
    text_part = MIMEText(body_text, 'plain', 'utf-8')
    message.attach(text_part)

    # HTML (optional)
    if body_html:
        html_part = MIMEText(body_html, 'html', 'utf-8')
        message.attach(html_part)

    with smtplib.SMTP(config['smtp_server'], config['smtp_port']) as server:
        server.starttls()
        server.login(config['sender_email'], config['sender_password'])
        server.send_message(message)

    print(f"Email sent successfully to {', '.join(recipients)}")


def main():
    parser = argparse.ArgumentParser(description='Send Global Economy Report via email')
    parser.add_argument('--config', required=True, help='Path to config.json')
    parser.add_argument('--report', required=True, help='Path to report markdown file')
    args = parser.parse_args()

    config = load_config(args.config)
    report_content = load_report(args.report)

    today = datetime.now().strftime('%Y-%m-%d')
    subject = f'[글로벌 경제 리포트] {today}'

    # Convert to HTML
    body_html = None
    css = """body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans KR', sans-serif; line-height: 1.8; max-width: 800px; margin: 0 auto; padding: 20px; color: #333; background: #fff; }
h1 { color: #1a1a2e; border-bottom: 3px solid #0066cc; padding-bottom: 12px; font-size: 24px; margin-top: 0; }
h2 { color: #16213e; margin-top: 32px; font-size: 20px; border-left: 4px solid #0066cc; padding-left: 12px; }
h3 { color: #1a1a2e; font-size: 18px; margin-top: 24px; }
h4 { color: #444; font-size: 15px; margin-bottom: 4px; margin-top: 16px; }
p { margin: 6px 0; }
a { color: #0066cc; text-decoration: none; }
hr { border: none; border-top: 1px solid #e0e0e0; margin: 24px 0; }
code { background: #f4f4f8; padding: 2px 6px; border-radius: 3px; font-size: 13px; }
ul, ol { padding-left: 20px; }
li { margin: 4px 0; }
table { border-collapse: collapse; width: 100%; margin: 12px 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background: #f4f4f8; }
blockquote { border-left: 3px solid #ccc; margin: 12px 0; padding: 8px 16px; color: #666; background: #fafafa; }
strong { color: #1a1a2e; }"""

    if HAS_MARKDOWN:
        html_body = markdown.markdown(
            report_content,
            extensions=['tables', 'fenced_code', 'nl2br', 'sane_lists', 'toc'],
            output_format='html5',
        )
    else:
        # Fallback: basic markdown to HTML conversion without external dependencies
        lines = report_content.split('\n')
        html_parts = []
        in_list = False
        paragraph = []

        def flush_paragraph():
            if paragraph:
                text = '<br>'.join(paragraph)
                html_parts.append(f'<p>{text}</p>')
                paragraph.clear()

        for line in lines:
            stripped = line.strip()
            # Headings
            if stripped.startswith('#### '):
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
                content = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', stripped[5:])
                html_parts.append(f'<h4>{content}</h4>')
            elif stripped.startswith('### '):
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
                html_parts.append(f'<h3>{stripped[4:]}</h3>')
            elif stripped.startswith('## '):
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
                html_parts.append(f'<h2>{stripped[3:]}</h2>')
            elif stripped.startswith('# '):
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
                html_parts.append(f'<h1>{stripped[2:]}</h1>')
            elif stripped == '---':
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
                html_parts.append('<hr>')
            elif stripped.startswith('- '):
                flush_paragraph()
                if not in_list:
                    html_parts.append('<ul>')
                    in_list = True
                content = stripped[2:]
                content = re.sub(r'\[([^\]]+)\]\((https?://[^\)]+)\)', r'<a href="\2">\1</a>', content)
                content = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', content)
                html_parts.append(f'<li>{content}</li>')
            elif stripped == '':
                flush_paragraph()
                if in_list:
                    html_parts.append('</ul>')
                    in_list = False
            else:
                # Regular text line
                content = stripped
                content = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', content)
                content = re.sub(r'\[([^\]]+)\]\((https?://[^\)]+)\)', r'<a href="\2">\1</a>', content)
                content = re.sub(r'^(https?://\S+)$', r'<a href="\1">\1</a>', content)
                paragraph.append(content)

        flush_paragraph()
        if in_list:
            html_parts.append('</ul>')
        html_body = '\n'.join(html_parts)

    body_html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>{css}</style>
</head>
<body>
{html_body}
</body>
</html>"""

    send_email(config, subject, report_content, body_html)

    # 전송 성공 후 Temp 폴더 내 이전 보고서 파일 전체 삭제
    import tempfile
    temp_dir = Path(tempfile.gettempdir())
    for old_file in temp_dir.glob('global_economy_report_*.md'):
        old_file.unlink()
        print(f"Deleted: {old_file}")


if __name__ == '__main__':
    main()
