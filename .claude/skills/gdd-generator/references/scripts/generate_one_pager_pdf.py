"""
generate_one_pager_pdf.py
--------------------------
Generates a single-page game concept PDF optimized for cold outreach,
press kits, and conference leave-behinds.

Usage:
    python scripts/generate_one_pager_pdf.py --title "My Game" --output "MyGame_OnePager.pdf"
    python scripts/generate_one_pager_pdf.py --config one_pager_content.json --output "MyGame_OnePager.pdf"

Requirements:
    pip install fpdf2

Layout (A4 portrait):
  ┌─────────────────────────────────────┐
  │ [TOP BAR: accent color]             │
  │ [GAME TITLE]    [Studio / Date]     │
  │ [Tagline — italic]                  │
  ├──────────────┬──────────────────────┤
  │ Genre        │ Audience             │
  │ Platform     │ Monetization         │
  ├──────────────┴──────────────────────┤
  │ [HOOK — 2 sentences]                │
  ├─────────────────────────────────────┤
  │ CORE LOOP — 3 sentences             │
  ├─────────────────────────────────────┤
  │ KEY FEATURES (4 × 1 line each)      │
  ├────────────────┬────────────────────┤
  │ COMPARABLE     │ TEAM / STATUS      │
  │ TITLES (3)     │                    │
  ├────────────────┴────────────────────┤
  │ [FOOTER: studio / contact / date]   │
  └─────────────────────────────────────┘
"""

import argparse
import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

try:
    from fpdf import FPDF, XPos, YPos
    FPDF_AVAILABLE = True
except ImportError:
    FPDF_AVAILABLE = False

try:
    from utils.section_registry import validate_data_sensibility
    REGISTRY_AVAILABLE = True
except ImportError:
    REGISTRY_AVAILABLE = False


# ─────────────────────────────────────────────
# COLORS & LAYOUT
# ─────────────────────────────────────────────

class OP_Colors:
    """One-pager specific color palette."""
    BG_WHITE = (255, 255, 255)
    BG_LIGHT = (247, 250, 255)
    ACCENT_DARK = (26, 60, 94)       # Dark navy
    ACCENT_MID = (41, 89, 133)       # Mid blue
    ACCENT_GOLD = (200, 150, 40)     # Gold
    TEXT_DARK = (20, 20, 30)         # Near black
    TEXT_MID = (70, 70, 90)          # Dark grey
    TEXT_LIGHT = (130, 130, 150)     # Medium grey
    BORDER = (180, 195, 215)         # Light blue-grey
    POSITIVE = (39, 120, 71)         # Dark green
    SECTION_BG = (235, 242, 255)     # Section header bg


class OP_Layout:
    """One-pager layout constants (mm)."""
    W = 210       # A4 width
    H = 297       # A4 height
    ML = 12       # Margin left
    MR = 12       # Margin right
    MT = 0        # Margin top (managed manually)
    MB = 0        # Margin bottom
    CW = W - ML - MR   # Content width: 186mm
    COL_L = 90         # Left column width (in two-column layout)
    COL_R = CW - COL_L - 3  # Right column width (3mm gap)


def _sanitize_text(text: str) -> str:
    """Replace Unicode characters that Helvetica (latin-1) can't render."""
    replacements = {
        "\u2014": "--", "\u2013": "-", "\u2018": "'", "\u2019": "'",
        "\u201C": '"', "\u201D": '"', "\u2026": "...", "\u2022": "*",
        "\u00D7": "x", "\u2192": "->", "\u2190": "<-", "\u00B7": ".",
        "\u2605": "*", "\U0001F3AE": "[Game]", "\u26A0": "[!]",
    }
    for char, replacement in replacements.items():
        text = text.replace(char, replacement)
    return text.encode("latin-1", errors="replace").decode("latin-1")


class OnePager(FPDF if FPDF_AVAILABLE else object):
    """Custom FPDF for single-page game concept sheet."""

    def __init__(self):
        if not FPDF_AVAILABLE:
            raise ImportError("fpdf2 is required. Install with: pip install fpdf2")
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_margins(OP_Layout.ML, 0, OP_Layout.MR)
        self.set_auto_page_break(auto=False)
        self.add_page()

    def cell(self, w=None, h=None, text="", *args, **kwargs):
        """Override cell to sanitize Unicode text for latin-1 fonts."""
        return super().cell(w, h, _sanitize_text(str(text)), *args, **kwargs)

    def multi_cell(self, w, h=None, text="", *args, **kwargs):
        """Override multi_cell to sanitize Unicode text for latin-1 fonts."""
        return super().multi_cell(w, h, _sanitize_text(str(text)), *args, **kwargs)

    def get_string_width(self, s, normalized=False):
        """Override to sanitize text before measuring width."""
        return super().get_string_width(_sanitize_text(str(s)), normalized)

    def section_label(self, text: str, y: float, full_width: bool = True) -> float:
        """
        Draw a section header bar.
        Returns new Y position after the bar.
        """
        self.set_fill_color(*OP_Colors.ACCENT_DARK)
        self.set_text_color(*OP_Colors.BG_WHITE)
        self.set_font("Helvetica", "B", 7.5)
        self.set_xy(OP_Layout.ML, y)
        width = OP_Layout.CW if full_width else OP_Layout.COL_L
        self.cell(width, 4.5, f"  {text.upper()}", fill=True,
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        return self.get_y()

    def divider(self, y: float) -> None:
        """Draw a horizontal divider line."""
        self.set_draw_color(*OP_Colors.BORDER)
        self.set_line_width(0.2)
        self.line(OP_Layout.ML, y, OP_Layout.W - OP_Layout.MR, y)

    def body_text(self, x: float, y: float, w: float, text: str,
                  size: float = 9.0, color: Tuple = OP_Colors.TEXT_DARK,
                  bold: bool = False, italic: bool = False, h: float = 4.5) -> float:
        """
        Render wrapped body text. Returns Y position after text.
        """
        style = ""
        if bold:
            style += "B"
        if italic:
            style += "I"
        self.set_font("Helvetica", style, size)
        self.set_text_color(*color)
        self.set_xy(x, y)
        self.multi_cell(w, h, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        return self.get_y()

    def badge(self, x: float, y: float, text: str,
              bg: Tuple = OP_Colors.ACCENT_MID,
              text_color: Tuple = OP_Colors.BG_WHITE,
              size: float = 7.5) -> float:
        """Draw a small colored badge/pill."""
        self.set_font("Helvetica", "B", size)
        text_w = self.get_string_width(text) + 4
        self.set_fill_color(*bg)
        self.set_text_color(*text_color)
        self.set_xy(x, y)
        self.cell(text_w, 4.5, text, fill=True)
        return x + text_w + 2


# ─────────────────────────────────────────────
# LAYOUT BUILDER
# ─────────────────────────────────────────────

def build_one_pager(op: "OnePager", content: Dict) -> None:
    """
    Render all sections of the one-pager.
    Layout flows from top to bottom with fixed section heights.
    """

    # ── TOP BAR ──────────────────────────────────────────────
    op.set_fill_color(*OP_Colors.ACCENT_DARK)
    op.rect(0, 0, OP_Layout.W, 7, "F")

    # Studio name in top bar
    op.set_font("Helvetica", size=7)
    op.set_text_color(*OP_Colors.BG_WHITE)
    op.set_xy(OP_Layout.ML, 1.5)
    studio = content.get("studio_name", "Studio Name")
    date_str = content.get("date", datetime.now().strftime("%B %Y"))
    op.cell(OP_Layout.CW, 4, f"{studio}  ·  {date_str}", align="R")

    y = 7

    # ── GAME TITLE ────────────────────────────────────────────
    y += 4
    op.set_font("Helvetica", "B", 22)
    op.set_text_color(*OP_Colors.ACCENT_DARK)
    op.set_xy(OP_Layout.ML, y)
    title = content.get("game_title", "GAME TITLE")
    op.cell(OP_Layout.CW, 12, title, align="L")
    y += 11

    # ── TAGLINE ───────────────────────────────────────────────
    op.set_font("Helvetica", "I", 9.5)
    op.set_text_color(*OP_Colors.TEXT_MID)
    op.set_xy(OP_Layout.ML, y)
    tagline = content.get("tagline", "A new gaming experience")
    op.cell(OP_Layout.CW, 5.5, tagline)
    y += 6

    # Gold accent line under title block
    op.set_draw_color(*OP_Colors.ACCENT_GOLD)
    op.set_line_width(0.7)
    op.line(OP_Layout.ML, y, OP_Layout.ML + 50, y)
    y += 3

    # ── METADATA ROW (Genre / Platform | Audience / Monetization) ──
    op.set_fill_color(*OP_Colors.SECTION_BG)
    op.rect(OP_Layout.ML, y, OP_Layout.CW, 10, "F")

    meta_items = [
        ("Genre", content.get("genre", "Genre TBD")),
        ("Platform", content.get("platform", "Platform TBD")),
        ("Audience", content.get("audience", "Audience TBD")),
        ("Monetization", content.get("monetization", "F2P / Battle Pass")),
    ]
    col_w = OP_Layout.CW / 4
    for i, (label, value) in enumerate(meta_items):
        x = OP_Layout.ML + i * col_w
        op.set_font("Helvetica", "B", 6.5)
        op.set_text_color(*OP_Colors.ACCENT_MID)
        op.set_xy(x + 1, y + 1)
        op.cell(col_w - 2, 4, label.upper())

        op.set_font("Helvetica", size=7.5)
        op.set_text_color(*OP_Colors.TEXT_DARK)
        op.set_xy(x + 1, y + 4.5)
        op.cell(col_w - 2, 4, value)

    y += 12

    op.divider(y)
    y += 2

    # ── HOOK ────────────────────────────────────────────────
    y = op.section_label("HOOK", y)
    hook = content.get("hook", "[2-sentence hook. First: the experience. Second: why it's different.]")
    y = op.body_text(OP_Layout.ML + 1, y + 1, OP_Layout.CW - 2, hook, size=8.5, h=4.2)
    y += 1

    op.divider(y)
    y += 2

    # ── CORE LOOP ────────────────────────────────────────────
    y = op.section_label("CORE GAMEPLAY LOOP", y)
    loop = content.get(
        "core_loop",
        "[3 sentences: micro loop → macro loop → return motivation]"
    )
    y = op.body_text(OP_Layout.ML + 1, y + 1, OP_Layout.CW - 2, loop, size=8.5, h=4.2)
    y += 1

    op.divider(y)
    y += 2

    # ── KEY FEATURES ─────────────────────────────────────────
    y = op.section_label("KEY FEATURES", y)
    features = content.get("key_features", [
        ("Feature 1", "[One specific sentence about this mechanic]"),
        ("Feature 2", "[One specific sentence about the innovation]"),
        ("Feature 3", "[One specific sentence about the hook]"),
        ("Feature 4", "[One specific sentence about the social/retention driver]"),
    ])
    for feature_name, feature_desc in features[:4]:
        op.set_xy(OP_Layout.ML + 1, y + 1)
        op.set_font("Helvetica", "B", 8.0)
        op.set_text_color(*OP_Colors.ACCENT_GOLD)
        label_w = op.get_string_width(f"★ {feature_name}: ") + 1
        op.cell(label_w, 4.2, f"★ {feature_name}: ")

        op.set_font("Helvetica", size=8.0)
        op.set_text_color(*OP_Colors.TEXT_DARK)
        feature_x = OP_Layout.ML + 1 + label_w
        op.set_xy(feature_x, y + 1)
        op.multi_cell(OP_Layout.CW - label_w - 2, 4.2, feature_desc,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y = op.get_y()

    y += 1
    op.divider(y)
    y += 2

    # ── TWO-COLUMN: COMPARABLE TITLES | TEAM / STATUS ────────
    col_y_start = y
    left_x = OP_Layout.ML
    right_x = OP_Layout.ML + OP_Layout.COL_L + 3

    # Left column: Comparable Titles
    op.section_label("COMPARABLE TITLES", y, full_width=False)
    y_left = y + 5

    comps = content.get("comparable_titles", [
        ("Game A × Game B", "but [your key differentiator]"),
        ("Game C", "for [what you take from it]"),
        ("Game D", "for [the market validation it provides]"),
    ])
    for comp_name, comp_desc in comps[:3]:
        op.set_xy(left_x + 1, y_left)
        op.set_font("Helvetica", "B", 8.0)
        op.set_text_color(*OP_Colors.ACCENT_MID)
        op.cell(OP_Layout.COL_L - 2, 4, comp_name)
        y_left += 4
        op.set_xy(left_x + 2, y_left)
        op.set_font("Helvetica", "I", 7.5)
        op.set_text_color(*OP_Colors.TEXT_MID)
        op.multi_cell(OP_Layout.COL_L - 4, 3.8, comp_desc,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y_left = op.get_y() + 1

    # Right column header
    op.set_fill_color(*OP_Colors.ACCENT_DARK)
    op.set_text_color(*OP_Colors.BG_WHITE)
    op.set_font("Helvetica", "B", 7.5)
    op.set_xy(right_x, y)
    op.cell(OP_Layout.COL_R, 4.5, "  TEAM / STATUS", fill=True)
    y_right = y + 5

    # Team info
    team_info = content.get("team_info", [
        f"Team: {content.get('team_size', '6 developers')}",
        f"Lead: {content.get('lead_credential', '[Name] — shipped [Title]')}",
        f"Status: {content.get('dev_status', 'Vertical slice in progress')}",
        f"Funding: {content.get('funding_status', 'Seeking seed round')}",
    ])
    for item in team_info[:5]:
        op.set_xy(right_x + 1, y_right)
        op.set_font("Helvetica", size=8.0)
        op.set_text_color(*OP_Colors.TEXT_DARK)
        op.multi_cell(OP_Layout.COL_R - 2, 4.2, item,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y_right = op.get_y()

    # Advance y to whichever column ended lower
    y = max(y_left, y_right) + 2
    op.divider(y)

    # ── FOOTER ────────────────────────────────────────────────
    # Always at bottom of page
    footer_y = OP_Layout.H - 12
    op.set_fill_color(*OP_Colors.ACCENT_DARK)
    op.rect(0, footer_y, OP_Layout.W, 12, "F")

    contact = content.get("contact_email", "contact@studio.com")
    website = content.get("website", "studio.gg")
    location = content.get("location", "Remote")
    footer_text = f"{studio}  ·  {contact}  ·  {website}  ·  {location}"

    op.set_font("Helvetica", size=7)
    op.set_text_color(*OP_Colors.BG_WHITE)
    op.set_xy(OP_Layout.ML, footer_y + 4)
    op.cell(OP_Layout.CW, 4, footer_text, align="C")


# ─────────────────────────────────────────────
# MAIN GENERATION FUNCTION
# ─────────────────────────────────────────────

def generate_one_pager(game_data: Dict, output_path: str, strict: bool = False) -> str:
    """
    Generate a single-page PDF concept sheet.

    Args:
        game_data: Dictionary with game metadata and one-pager content.
        output_path: Output PDF path.
        strict: If True, fail export if unsourced metrics or placeholders remain.

    Returns:
        Absolute path to generated file.
    """
    if not FPDF_AVAILABLE:
        raise ImportError(
            "fpdf2 is required. Install with:\n"
            "  pip install fpdf2"
        )

    # Pre-export validation
    if REGISTRY_AVAILABLE:
        sections_to_validate = game_data.get("sections", {})
        if sections_to_validate:
            sensibility_warnings = validate_data_sensibility(
                sections_to_validate, strict=strict
            )
            for warning in sensibility_warnings:
                print(f"  WARNING: {warning}")
            if strict and sensibility_warnings:
                raise SystemExit(
                    "STRICT MODE: Export aborted due to unsourced metrics or "
                    "placeholders. Fix the warnings above or remove --strict."
                )

    op = OnePager()
    build_one_pager(op, game_data)

    output_dir = os.path.dirname(os.path.abspath(output_path))
    os.makedirs(output_dir, exist_ok=True)
    op.output(output_path)
    abs_path = os.path.abspath(output_path)
    print(f"✓ One-pager generated: {abs_path}")
    return abs_path


# ─────────────────────────────────────────────
# CLI ENTRY POINT
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate a single-page game concept PDF",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python generate_one_pager_pdf.py --title "Echo Chamber" --output "EchoChamber_OnePager.pdf"
  python generate_one_pager_pdf.py --config one_pager.json --output "MyGame_OnePager.pdf"
        """
    )
    parser.add_argument("--title", help="Game title")
    parser.add_argument("--studio", default="Studio Name", help="Studio name")
    parser.add_argument("--genre", default="Genre TBD", help="Genre")
    parser.add_argument("--platform", default="PC, Console, Mobile", help="Platform")
    parser.add_argument("--audience", default="Ages 18-35, midcore gamers", help="Audience")
    parser.add_argument("--tagline", default="", help="Tagline")
    parser.add_argument("--config", help="JSON config file with one-pager content")
    parser.add_argument("--output", default="one_pager.pdf", help="Output PDF path")
    parser.add_argument("--strict", action="store_true",
                        help="Fail export if unsourced metrics or placeholders remain")

    args = parser.parse_args()

    if not FPDF_AVAILABLE:
        print("ERROR: fpdf2 is not installed. Install with: pip install fpdf2")
        sys.exit(1)

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
            "tagline": args.tagline or f"A new {args.genre} experience",
            "genre": args.genre,
            "platform": args.platform,
            "audience": args.audience,
            "studio_name": args.studio,
            "date": datetime.now().strftime("%B %Y"),
            "contact_email": "contact@studio.com",
            "website": "studio.gg",
        }
    else:
        parser.print_help()
        print("\nERROR: Provide --title or --config")
        sys.exit(1)

    try:
        generate_one_pager(game_data=game_data, output_path=args.output, strict=args.strict)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
