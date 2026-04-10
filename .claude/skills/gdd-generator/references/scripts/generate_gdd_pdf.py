"""
generate_gdd_pdf.py
-------------------
Generates a professional Game Design Document as a print-ready .pdf file.

Usage:
    python scripts/generate_gdd_pdf.py --title "My Game" --output "MyGame_GDD_v01.pdf"
    python scripts/generate_gdd_pdf.py --config gdd_content.json --output "MyGame_GDD_v01.pdf"
    python scripts/generate_gdd_pdf.py --docx existing_gdd.docx --output output.pdf

Requirements:
    pip install fpdf2

    OR for docx conversion fallback:
    pip install docx2pdf  (requires LibreOffice on Linux/Mac, Word on Windows)

The script can either:
  (a) Generate a PDF directly from content using fpdf2
  (b) Convert an existing .docx to PDF via docx2pdf (if available)
  (c) Generate from a JSON config file
"""

import argparse
import json
import os
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

try:
    from utils.pdf_builder import (
        GDDDocument, PDFColors, PDFLayout,
        render_heading_1, render_heading_2, render_heading_3,
        render_body_text, render_bullet_point, render_code_block,
        render_callout_box, render_table, render_cover_page, render_toc
    )
    PDF_BUILDER_AVAILABLE = True
except ImportError:
    PDF_BUILDER_AVAILABLE = False

try:
    from utils.section_registry import (
        SECTIONS, SECTION_ORDER, validate_gdd_content,
        validate_data_sensibility, estimate_content_size,
    )
    REGISTRY_AVAILABLE = True
except ImportError:
    REGISTRY_AVAILABLE = False

try:
    from fpdf import FPDF, XPos, YPos
    FPDF_AVAILABLE = True
except ImportError:
    FPDF_AVAILABLE = False

try:
    import docx2pdf
    DOCX2PDF_AVAILABLE = True
except ImportError:
    DOCX2PDF_AVAILABLE = False


# ─────────────────────────────────────────────
# PDF GENERATION FROM CONTENT
# ─────────────────────────────────────────────

def _parse_and_render_content(pdf: "GDDDocument", content: str) -> None:
    """
    Parse content string and render to PDF.
    Handles: headings (## prefix), bullets (- prefix), code blocks (```),
    tables (| rows), callout boxes (> 🎮 prefix), open questions.
    """
    if not content or not FPDF_AVAILABLE:
        return

    lines = content.split("\n")
    in_code = False
    code_buffer = []
    in_table = False
    table_rows = []

    i = 0
    while i < len(lines):
        line = lines[i]

        # Code block
        if line.strip().startswith("```"):
            if in_code:
                in_code = False
                if code_buffer and PDF_BUILDER_AVAILABLE:
                    render_code_block(pdf, "\n".join(code_buffer))
                code_buffer = []
            else:
                in_code = True
            i += 1
            continue

        if in_code:
            code_buffer.append(line)
            i += 1
            continue

        # Table
        if line.strip().startswith("|"):
            if not in_table:
                in_table = True
                table_rows = []
            if not all(c in "-| " for c in line.strip()):
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                table_rows.append(cells)
            i += 1
            continue
        elif in_table:
            in_table = False
            if len(table_rows) >= 2 and PDF_BUILDER_AVAILABLE:
                headers = table_rows[0]
                rows = table_rows[1:]
                n_cols = len(headers)
                col_w = PDFLayout.CONTENT_WIDTH / n_cols if n_cols > 0 else PDFLayout.CONTENT_WIDTH
                render_table(pdf, headers, rows, [col_w] * n_cols)
            table_rows = []

        # Designer Note
        if line.strip().startswith("> 🎮") or line.strip().startswith("> Designer"):
            text = line.strip().lstrip("> 🎮").strip()
            if text.startswith("Designer's Note:"):
                text = text[len("Designer's Note:"):].strip()
            if PDF_BUILDER_AVAILABLE:
                render_callout_box(
                    pdf, "🎮 Designer's Note", text,
                    PDFColors.CALLOUT_NOTE_BG, PDFColors.CALLOUT_NOTE_BORDER
                )
            i += 1
            continue

        # Open question
        if "[OPEN QUESTION:" in line or "[PLAYTEST:" in line:
            if PDF_BUILDER_AVAILABLE:
                render_callout_box(
                    pdf, "⚠ Open Question", line.strip(),
                    PDFColors.CALLOUT_WARN_BG, PDFColors.CALLOUT_WARN_BORDER
                )
            i += 1
            continue

        # Headings
        if line.startswith("### ") and PDF_BUILDER_AVAILABLE:
            render_heading_3(pdf, line[4:])
        elif line.startswith("## ") and PDF_BUILDER_AVAILABLE:
            render_heading_2(pdf, line[3:])

        # Bullets
        elif line.strip().startswith("- ") or line.strip().startswith("* "):
            bullet_text = line.strip().lstrip("-").lstrip("*").strip()
            if PDF_BUILDER_AVAILABLE:
                render_bullet_point(pdf, bullet_text)

        # Empty line
        elif not line.strip():
            if PDF_BUILDER_AVAILABLE:
                pdf.ln(2)

        # Regular paragraph
        elif line.strip() and PDF_BUILDER_AVAILABLE:
            render_body_text(pdf, line.strip())

        i += 1

    # Flush open table
    if in_table and len(table_rows) >= 2 and PDF_BUILDER_AVAILABLE:
        headers = table_rows[0]
        rows = table_rows[1:]
        n_cols = len(headers)
        col_w = PDFLayout.CONTENT_WIDTH / n_cols if n_cols > 0 else PDFLayout.CONTENT_WIDTH
        render_table(pdf, headers, rows, [col_w] * n_cols)


def generate_gdd_pdf_from_content(
    game_data: Dict,
    output_path: str,
    include_toc: bool = True,
    strict: bool = False
) -> str:
    """
    Generate a GDD PDF directly from content using fpdf2.

    Args:
        game_data: Dictionary with game metadata and sections content
        output_path: Output PDF file path
        include_toc: Whether to generate a table of contents page

    Returns:
        Absolute path to generated PDF.
    """
    if not FPDF_AVAILABLE:
        raise ImportError(
            "fpdf2 is required. Install with:\n"
            "  pip install fpdf2"
        )
    if not PDF_BUILDER_AVAILABLE:
        raise ImportError("pdf_builder utils not found. Check scripts/utils/pdf_builder.py")

    # Pre-export validation
    sections_to_validate = game_data.get("sections", {})
    if REGISTRY_AVAILABLE and sections_to_validate:
        for warning in validate_gdd_content(sections_to_validate):
            print(f"  WARNING: {warning}")
        sensibility_warnings = validate_data_sensibility(
            sections_to_validate, strict=strict
        )
        for warning in sensibility_warnings:
            print(f"  WARNING: {warning}")
        if strict and sensibility_warnings:
            raise SystemExit(
                "STRICT MODE: Export aborted due to unsourced metrics or "
                "placeholders in business sections. Fix the warnings above "
                "or remove --strict to export with warnings."
            )
        size_info = estimate_content_size(sections_to_validate)
        for warning in size_info["warnings"]:
            print(f"  WARNING: {warning}")

    game_title = game_data.get("game_title", "Untitled Game")
    tagline = game_data.get("tagline", "A new gaming experience")
    genre = game_data.get("genre", "Genre TBD")
    platform = game_data.get("platform", "Platform TBD")
    audience = game_data.get("audience", "Audience TBD")
    studio = game_data.get("studio_name", "Studio Name")
    version = game_data.get("version", "v0.1")
    date = game_data.get("date", datetime.now().strftime("%B %Y"))

    pdf = GDDDocument(game_title=game_title, version=version, date=date)

    # Cover page
    render_cover_page(
        pdf, game_title, tagline, genre, platform, audience,
        studio, version, date
    )

    # TOC placeholder (approximate — fpdf2 doesn't support dynamic TOC)
    if include_toc:
        pdf.add_page()
        render_heading_1(pdf, "Table of Contents")
        render_body_text(
            pdf,
            "[ Note: Page numbers in this TOC are approximate. "
            "For a fully linked TOC, open the .docx version in Microsoft Word. ]"
        )
        # Will be populated after all content is rendered
        toc_placeholder_page = pdf.page_no()

    # Sections
    sections_content = game_data.get("sections", {})
    section_order = SECTION_ORDER if REGISTRY_AVAILABLE else list(sections_content.keys())

    for section_key in section_order:
        content = sections_content.get(section_key, "")
        section_name = section_key.replace("_", " ").title()
        section_num = 0

        if REGISTRY_AVAILABLE and section_key in SECTIONS:
            sdef = SECTIONS[section_key]
            section_name = sdef["name"]
            section_num = sdef["order"]

            if not content:
                # Generate placeholder
                content = (
                    f"[{section_name} — content placeholder. "
                    f"Target: {sdef['recommended_words']} words. "
                    f"Required elements: {', '.join(sdef['key_elements'][:5])}]"
                )

        pdf.add_page()
        heading_text = f"{section_num}. {section_name}" if section_num else section_name
        render_heading_1(pdf, heading_text)

        if isinstance(content, str):
            _parse_and_render_content(pdf, content)
        elif isinstance(content, dict):
            _parse_and_render_content(pdf, content.get("content", ""))

    # Set PDF metadata
    pdf.set_title(f"{game_title} — Game Design Document")
    pdf.set_author(game_data.get("lead_designer", "Design Team"))
    pdf.set_subject(f"Game Design Document — {genre} — {platform}")
    pdf.set_keywords(f"GDD, game design, {genre}, {platform}, {game_title}")
    pdf.set_creator("game-design-document generator")

    # Render TOC now that pages are known
    if include_toc and pdf.toc_entries:
        # Insert TOC after cover — fpdf2 can't insert, so append as appendix
        render_toc(pdf)

    output_dir = os.path.dirname(os.path.abspath(output_path))
    os.makedirs(output_dir, exist_ok=True)
    pdf.output(output_path)
    abs_path = os.path.abspath(output_path)
    print(f"✓ PDF generated: {abs_path}")
    return abs_path


def convert_docx_to_pdf(docx_path: str, output_path: str, *, trusted: bool = False) -> str:
    """
    Convert an existing .docx file to PDF using docx2pdf.
    Requires either Word (Windows/Mac) or LibreOffice (Linux).

    WARNING: This delegates document parsing to external desktop software
    (Word/LibreOffice). Only use with trusted .docx files that you or your
    team created. Do not process untrusted or user-uploaded documents.

    Args:
        docx_path: Path to input .docx file
        output_path: Path for output .pdf file
        trusted: Must be True to confirm the .docx source is trusted.
                 Pass --trust-docx on the CLI to set this.

    Returns:
        Absolute path to generated PDF.
    """
    if not trusted:
        raise ValueError(
            "DOCX-to-PDF conversion requires --trust-docx flag.\n"
            "This conversion delegates to Word/LibreOffice which can execute "
            "macros or embedded content. Only use with .docx files you created "
            "or trust. Pass --trust-docx to confirm."
        )

    if not DOCX2PDF_AVAILABLE:
        raise ImportError(
            "docx2pdf is required for DOCX→PDF conversion.\n"
            "Install with: pip install docx2pdf\n"
            "Also requires Microsoft Word (Windows/Mac) or LibreOffice (Linux)."
        )

    if not os.path.exists(docx_path):
        raise FileNotFoundError(f"DOCX file not found: {docx_path}")

    output_dir = os.path.dirname(os.path.abspath(output_path))
    os.makedirs(output_dir, exist_ok=True)

    print(f"Converting {docx_path} to PDF...")
    docx2pdf.convert(docx_path, output_path)
    abs_path = os.path.abspath(output_path)
    print(f"✓ PDF converted: {abs_path}")
    return abs_path


# ─────────────────────────────────────────────
# CLI ENTRY POINT
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate a Game Design Document PDF",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate PDF from title (template):
  python generate_gdd_pdf.py --title "Echo Chamber" --output "EchoChamber_GDD.pdf"

  # Generate from JSON config:
  python generate_gdd_pdf.py --config gdd_content.json --output "MyGame_GDD.pdf"

  # Convert existing DOCX to PDF:
  python generate_gdd_pdf.py --docx MyGame_GDD.docx --output MyGame_GDD.pdf
        """
    )
    parser.add_argument("--title", help="Game title")
    parser.add_argument("--studio", default="Studio Name", help="Studio name")
    parser.add_argument("--genre", default="Genre TBD", help="Genre")
    parser.add_argument("--platform", default="Platform TBD", help="Platform")
    parser.add_argument("--audience", default="Audience TBD", help="Audience")
    parser.add_argument("--tagline", default="", help="Tagline")
    parser.add_argument("--version", default="v0.1", help="Document version")
    parser.add_argument("--config", help="JSON config file")
    parser.add_argument("--docx", help="Existing .docx file to convert to PDF")
    parser.add_argument("--output", default="GDD_output.pdf", help="Output PDF path")
    parser.add_argument("--no-toc", action="store_true", help="Skip TOC page")
    parser.add_argument("--strict", action="store_true",
                        help="Fail export if unsourced metrics or placeholders remain in business sections")
    parser.add_argument(
        "--trust-docx", action="store_true",
        help="Confirm that the .docx file is from a trusted source (required for --docx conversion)"
    )

    args = parser.parse_args()

    # Convert docx → pdf mode
    if args.docx:
        try:
            convert_docx_to_pdf(args.docx, args.output, trusted=args.trust_docx)
        except Exception as e:
            print(f"ERROR: {e}")
            sys.exit(1)
        return

    if not FPDF_AVAILABLE:
        print("ERROR: fpdf2 is not installed. Install with: pip install fpdf2")
        sys.exit(1)

    # Load content
    if args.config:
        try:
            with open(args.config, "r", encoding="utf-8") as f:
                game_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"ERROR loading config: {e}")
            sys.exit(1)
    elif args.title:
        game_data = {
            "game_title": args.title,
            "tagline": args.tagline or f"A {args.genre} experience",
            "genre": args.genre,
            "platform": args.platform,
            "audience": args.audience,
            "studio_name": args.studio,
            "version": args.version,
            "date": datetime.now().strftime("%B %Y"),
        }
    else:
        parser.print_help()
        print("\nERROR: Provide --title, --config, or --docx")
        sys.exit(1)

    try:
        generate_gdd_pdf_from_content(
            game_data=game_data,
            output_path=args.output,
            include_toc=not args.no_toc,
            strict=args.strict
        )
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
