"""
pdf_builder.py
--------------
PDF utility functions for GDD document generation using fpdf2.
Provides page setup, text rendering, table rendering, TOC generation,
and header/footer utilities.
"""

from typing import List, Dict, Tuple, Optional, Any
import os

try:
    from fpdf import FPDF, XPos, YPos
    FPDF_AVAILABLE = True
except ImportError:
    FPDF_AVAILABLE = False
    FPDF = object  # Stub for type hints


def _sanitize_text(text: str) -> str:
    """Replace Unicode characters that Helvetica (latin-1) can't render."""
    replacements = {
        "\u2014": "--",   # em dash
        "\u2013": "-",    # en dash
        "\u2018": "'",    # left single quote
        "\u2019": "'",    # right single quote
        "\u201C": '"',    # left double quote
        "\u201D": '"',    # right double quote
        "\u2026": "...",  # ellipsis
        "\u2022": "*",    # bullet
        "\u00D7": "x",    # multiplication sign
        "\u2192": "->",   # right arrow
        "\u2190": "<-",   # left arrow
        "\u2191": "^",    # up arrow
        "\u2193": "v",    # down arrow
        "\u2713": "[v]",  # check mark
        "\u2717": "[x]",  # cross mark
        "\u2605": "*",    # black star
        "\u00B7": ".",    # middle dot
        "\u2260": "!=",   # not equal
        "\u2264": "<=",   # less than or equal
        "\u2265": ">=",   # greater than or equal
        "\u03A3": "Sigma",  # sigma
        "\U0001F3AE": "[Game]",  # game controller emoji
        "\u26A0": "[!]",  # warning sign
    }
    for char, replacement in replacements.items():
        text = text.replace(char, replacement)
    # Fallback: replace any remaining non-latin-1 chars
    return text.encode("latin-1", errors="replace").decode("latin-1")


# ─────────────────────────────────────────────
# COLOR DEFINITIONS (R, G, B)
# ─────────────────────────────────────────────

class PDFColors:
    """Color constants for PDF generation."""
    HEADING_1 = (26, 60, 94)
    HEADING_2 = (41, 89, 133)
    HEADING_3 = (55, 111, 161)
    BODY = (33, 33, 33)
    CAPTION = (100, 100, 100)
    TABLE_HEADER_BG = (26, 60, 94)
    TABLE_HEADER_TEXT = (255, 255, 255)
    TABLE_ROW_ALT = (240, 245, 250)
    TABLE_ROW_NORMAL = (255, 255, 255)
    TABLE_BORDER = (180, 195, 210)
    CALLOUT_NOTE_BG = (235, 244, 255)
    CALLOUT_NOTE_BORDER = (41, 89, 133)
    CALLOUT_WARN_BG = (255, 248, 220)
    CALLOUT_WARN_BORDER = (255, 160, 0)
    COVER_TITLE = (26, 60, 94)
    COVER_ACCENT = (41, 89, 133)
    WHITE = (255, 255, 255)
    BLACK = (0, 0, 0)
    LIGHT_GREY = (240, 240, 240)
    MID_GREY = (160, 160, 160)


# ─────────────────────────────────────────────
# PAGE CONSTANTS
# ─────────────────────────────────────────────

class PDFLayout:
    """Page layout constants (millimeters for fpdf2)."""
    PAGE_WIDTH = 210       # A4 width
    PAGE_HEIGHT = 297      # A4 height
    MARGIN_LEFT = 25       # ~1 inch
    MARGIN_RIGHT = 25
    MARGIN_TOP = 25
    MARGIN_BOTTOM = 25
    CONTENT_WIDTH = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT  # 160mm

    # Font sizes (pt)
    H1_SIZE = 22
    H2_SIZE = 16
    H3_SIZE = 13
    H4_SIZE = 11
    BODY_SIZE = 10
    CAPTION_SIZE = 8
    CODE_SIZE = 9
    FOOTER_SIZE = 8
    HEADER_SIZE = 8
    COVER_TITLE_SIZE = 32
    COVER_TAGLINE_SIZE = 14

    # Spacing (mm)
    LINE_HEIGHT_BODY = 6
    LINE_HEIGHT_H1 = 12
    LINE_HEIGHT_H2 = 10
    LINE_HEIGHT_H3 = 8
    PARA_SPACE = 4
    SECTION_SPACE = 8


class GDDDocument(FPDF if FPDF_AVAILABLE else object):
    """
    Custom FPDF subclass for GDD generation with header/footer support.
    """

    def __init__(self, game_title: str = "Game Design Document",
                 version: str = "v0.1", date: str = "2025"):
        if not FPDF_AVAILABLE:
            raise ImportError("fpdf2 is required. Install with: pip install fpdf2")
        super().__init__(orientation="P", unit="mm", format="A4")
        self.game_title = game_title
        self.version = version
        self.date = date
        self.toc_entries: List[Dict[str, Any]] = []
        self.set_margins(
            PDFLayout.MARGIN_LEFT,
            PDFLayout.MARGIN_TOP,
            PDFLayout.MARGIN_RIGHT
        )
        self.set_auto_page_break(auto=True, margin=PDFLayout.MARGIN_BOTTOM)
        self._setup_fonts()

    def _setup_fonts(self) -> None:
        """Register fonts. Uses built-in Helvetica and Courier as fallbacks."""
        # fpdf2 has built-in Helvetica, Times, Courier
        # For better typography, add custom fonts here if available
        pass

    def cell(self, w=None, h=None, text="", *args, **kwargs):
        """Override cell to sanitize Unicode text for latin-1 fonts."""
        return super().cell(w, h, _sanitize_text(str(text)), *args, **kwargs)

    def multi_cell(self, w, h=None, text="", *args, **kwargs):
        """Override multi_cell to sanitize Unicode text for latin-1 fonts."""
        return super().multi_cell(w, h, _sanitize_text(str(text)), *args, **kwargs)

    def get_string_width(self, s, normalized=False):
        """Override to sanitize text before measuring width."""
        return super().get_string_width(_sanitize_text(str(s)), normalized)

    def header(self) -> None:
        """Render page header on every page (except cover page)."""
        if self.page_no() <= 1:
            return
        self.set_font("Helvetica", size=PDFLayout.HEADER_SIZE)
        self.set_text_color(*PDFColors.CAPTION)
        self.set_y(10)
        header_text = f"{self.game_title}  |  Game Design Document  |  {self.version}"
        self.cell(
            PDFLayout.CONTENT_WIDTH, 5,
            header_text, align="R",
            new_x=XPos.LMARGIN, new_y=YPos.NEXT
        )
        # Separator line
        self.set_draw_color(*PDFColors.TABLE_BORDER)
        self.set_line_width(0.3)
        self.line(
            PDFLayout.MARGIN_LEFT,
            self.get_y(),
            PDFLayout.PAGE_WIDTH - PDFLayout.MARGIN_RIGHT,
            self.get_y()
        )
        self.ln(3)

    def footer(self) -> None:
        """Render page footer with page numbers."""
        if self.page_no() <= 1:
            return
        self.set_y(-15)
        # Separator line
        self.set_draw_color(*PDFColors.TABLE_BORDER)
        self.set_line_width(0.3)
        self.line(
            PDFLayout.MARGIN_LEFT,
            self.get_y(),
            PDFLayout.PAGE_WIDTH - PDFLayout.MARGIN_RIGHT,
            self.get_y()
        )
        self.ln(2)
        self.set_font("Helvetica", size=PDFLayout.FOOTER_SIZE)
        self.set_text_color(*PDFColors.CAPTION)
        # Left: confidential
        self.cell(
            PDFLayout.CONTENT_WIDTH / 3, 5,
            "CONFIDENTIAL", align="L"
        )
        # Center: page number
        self.cell(
            PDFLayout.CONTENT_WIDTH / 3, 5,
            f"Page {self.page_no()}", align="C"
        )
        # Right: date
        self.cell(
            PDFLayout.CONTENT_WIDTH / 3, 5,
            self.date, align="R"
        )

    def add_toc_entry(self, title: str, level: int, page: int) -> None:
        """Register a TOC entry for later rendering."""
        self.toc_entries.append({
            "title": title,
            "level": level,
            "page": page
        })


# ─────────────────────────────────────────────
# CONTENT RENDERING FUNCTIONS
# ─────────────────────────────────────────────

def render_heading_1(pdf: "GDDDocument", text: str) -> None:
    """Render an H1 heading: large, dark navy, page-break-before."""
    if not FPDF_AVAILABLE:
        return
    pdf.ln(PDFLayout.SECTION_SPACE)
    pdf.set_font("Helvetica", "B", PDFLayout.H1_SIZE)
    pdf.set_text_color(*PDFColors.HEADING_1)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH,
        PDFLayout.LINE_HEIGHT_H1,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    # Underline
    y = pdf.get_y()
    pdf.set_draw_color(*PDFColors.HEADING_1)
    pdf.set_line_width(0.5)
    pdf.line(
        PDFLayout.MARGIN_LEFT, y,
        PDFLayout.PAGE_WIDTH - PDFLayout.MARGIN_RIGHT, y
    )
    pdf.ln(4)
    # Register TOC entry
    pdf.add_toc_entry(text, 1, pdf.page_no())


def render_heading_2(pdf: "GDDDocument", text: str) -> None:
    """Render an H2 heading: medium, mid blue."""
    if not FPDF_AVAILABLE:
        return
    pdf.ln(PDFLayout.PARA_SPACE)
    pdf.set_font("Helvetica", "B", PDFLayout.H2_SIZE)
    pdf.set_text_color(*PDFColors.HEADING_2)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH,
        PDFLayout.LINE_HEIGHT_H2,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(2)
    pdf.add_toc_entry(text, 2, pdf.page_no())


def render_heading_3(pdf: "GDDDocument", text: str) -> None:
    """Render an H3 heading: small, light blue, bold."""
    if not FPDF_AVAILABLE:
        return
    pdf.ln(2)
    pdf.set_font("Helvetica", "B", PDFLayout.H3_SIZE)
    pdf.set_text_color(*PDFColors.HEADING_3)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH,
        PDFLayout.LINE_HEIGHT_H3,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(1)


def render_body_text(pdf: "GDDDocument", text: str) -> None:
    """Render a body paragraph: Helvetica 10pt, dark grey."""
    if not FPDF_AVAILABLE:
        return
    pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH,
        PDFLayout.LINE_HEIGHT_BODY,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(PDFLayout.PARA_SPACE)


def render_bullet_point(pdf: "GDDDocument", text: str, indent: int = 0) -> None:
    """Render a bullet point with optional nesting indent."""
    if not FPDF_AVAILABLE:
        return
    indent_mm = 5 + (indent * 5)
    bullet = "•  " if indent == 0 else "–  "
    pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.set_x(PDFLayout.MARGIN_LEFT + indent_mm)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH - indent_mm,
        PDFLayout.LINE_HEIGHT_BODY,
        f"{bullet}{text}",
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )


def render_code_block(pdf: "GDDDocument", text: str) -> None:
    """Render a code/formula block with grey background and monospace font."""
    if not FPDF_AVAILABLE:
        return
    pdf.ln(2)
    # Background rectangle
    x = PDFLayout.MARGIN_LEFT + 5
    y = pdf.get_y()
    line_count = text.count("\n") + 1
    box_height = line_count * PDFLayout.LINE_HEIGHT_BODY + 4

    pdf.set_fill_color(*PDFColors.LIGHT_GREY)
    pdf.rect(x, y, PDFLayout.CONTENT_WIDTH - 10, box_height, "F")

    pdf.set_xy(x + 3, y + 2)
    pdf.set_font("Courier", size=PDFLayout.CODE_SIZE)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH - 16,
        PDFLayout.LINE_HEIGHT_BODY,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(4)


def render_callout_box(
    pdf: "GDDDocument",
    label: str,
    text: str,
    bg_color: Tuple[int, int, int] = PDFColors.CALLOUT_NOTE_BG,
    border_color: Tuple[int, int, int] = PDFColors.CALLOUT_NOTE_BORDER
) -> None:
    """Render a callout box (Designer Note or Open Question)."""
    if not FPDF_AVAILABLE:
        return
    pdf.ln(2)
    x = PDFLayout.MARGIN_LEFT
    y = pdf.get_y()

    # Estimate height needed
    pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)
    # Rough estimate: 6mm per line, average 60 chars/line in 150mm width
    char_width_approx = 2.5
    chars_per_line = int((PDFLayout.CONTENT_WIDTH - 10) / char_width_approx)
    line_estimate = max(3, len(text) // chars_per_line + 2)
    box_height = line_estimate * 5 + 6

    # Background
    pdf.set_fill_color(*bg_color)
    pdf.rect(x, y, PDFLayout.CONTENT_WIDTH, box_height, "F")

    # Left border stripe
    pdf.set_fill_color(*border_color)
    pdf.rect(x, y, 3, box_height, "F")

    # Label
    pdf.set_xy(x + 6, y + 3)
    pdf.set_font("Helvetica", "B", PDFLayout.BODY_SIZE)
    pdf.set_text_color(*border_color)
    pdf.cell(40, 5, f"{label}:", new_x=XPos.RIGHT, new_y=YPos.LAST)

    # Text (inline after label)
    pdf.set_font("Helvetica", "I", PDFLayout.BODY_SIZE)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH - 50,
        5,
        text,
        new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(4)


def render_table(
    pdf: "GDDDocument",
    headers: List[str],
    rows: List[List[str]],
    col_widths: Optional[List[float]] = None
) -> None:
    """
    Render a table with styled header row and alternating row colors.

    Args:
        pdf: GDDDocument instance
        headers: List of column header strings
        rows: List of rows, each a list of cell strings
        col_widths: Optional list of column widths in mm. Defaults to equal division.
    """
    if not FPDF_AVAILABLE:
        return

    n_cols = len(headers)
    if col_widths is None:
        col_widths = [PDFLayout.CONTENT_WIDTH / n_cols] * n_cols

    pdf.ln(2)

    # Header row
    pdf.set_fill_color(*PDFColors.TABLE_HEADER_BG)
    pdf.set_text_color(*PDFColors.TABLE_HEADER_TEXT)
    pdf.set_font("Helvetica", "B", PDFLayout.BODY_SIZE)
    pdf.set_draw_color(*PDFColors.TABLE_BORDER)

    for i, (header, width) in enumerate(zip(headers, col_widths)):
        is_last = (i == n_cols - 1)
        pdf.cell(
            width, 7, header,
            border="TBLR",
            fill=True,
            align="C",
            new_x=XPos.RIGHT if not is_last else XPos.LMARGIN,
            new_y=YPos.LAST if not is_last else YPos.NEXT
        )

    # Data rows
    pdf.set_text_color(*PDFColors.BODY)
    pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)

    for row_idx, row in enumerate(rows):
        # Check if we need a page break
        if pdf.get_y() > PDFLayout.PAGE_HEIGHT - PDFLayout.MARGIN_BOTTOM - 15:
            pdf.add_page()
            # Re-render header on new page
            pdf.set_fill_color(*PDFColors.TABLE_HEADER_BG)
            pdf.set_text_color(*PDFColors.TABLE_HEADER_TEXT)
            pdf.set_font("Helvetica", "B", PDFLayout.BODY_SIZE)
            for i, (header, width) in enumerate(zip(headers, col_widths)):
                is_last = (i == n_cols - 1)
                pdf.cell(
                    width, 7, header,
                    border="TBLR",
                    fill=True,
                    align="C",
                    new_x=XPos.RIGHT if not is_last else XPos.LMARGIN,
                    new_y=YPos.LAST if not is_last else YPos.NEXT
                )
            pdf.set_text_color(*PDFColors.BODY)
            pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)

        fill = row_idx % 2 == 1
        if fill:
            pdf.set_fill_color(*PDFColors.TABLE_ROW_ALT)
        else:
            pdf.set_fill_color(*PDFColors.TABLE_ROW_NORMAL)

        for i, (cell_text, width) in enumerate(zip(row, col_widths)):
            is_last = (i == n_cols - 1)
            pdf.cell(
                width, 6, str(cell_text),
                border="TBLR",
                fill=True,
                new_x=XPos.RIGHT if not is_last else XPos.LMARGIN,
                new_y=YPos.LAST if not is_last else YPos.NEXT
            )

    pdf.ln(4)


def render_toc(pdf: "GDDDocument") -> None:
    """
    Render a table of contents from registered TOC entries.
    Should be called after all content is added; TOC page numbers are approximate.
    """
    if not FPDF_AVAILABLE:
        return

    pdf.add_page()
    render_heading_1(pdf, "Table of Contents")

    for entry in pdf.toc_entries:
        level = entry["level"]
        title = entry["title"]
        page = entry["page"]

        if level == 1:
            pdf.set_font("Helvetica", "B", PDFLayout.BODY_SIZE + 1)
            pdf.set_text_color(*PDFColors.HEADING_1)
            indent = 0
        elif level == 2:
            pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)
            pdf.set_text_color(*PDFColors.BODY)
            indent = 8
        else:
            pdf.set_font("Helvetica", "I", PDFLayout.BODY_SIZE - 1)
            pdf.set_text_color(*PDFColors.CAPTION)
            indent = 15

        pdf.set_x(PDFLayout.MARGIN_LEFT + indent)
        title_width = PDFLayout.CONTENT_WIDTH - indent - 20
        pdf.cell(title_width, 6, title)

        # Dot leaders
        pdf.set_font("Helvetica", size=PDFLayout.BODY_SIZE)
        pdf.set_text_color(*PDFColors.CAPTION)
        pdf.cell(15, 6, str(page), align="R",
                 new_x=XPos.LMARGIN, new_y=YPos.NEXT)


def render_cover_page(
    pdf: "GDDDocument",
    game_title: str,
    tagline: str,
    genre: str,
    platform: str,
    audience: str,
    studio_name: str,
    version: str,
    date: str
) -> None:
    """Render a professional cover page."""
    if not FPDF_AVAILABLE:
        return

    pdf.add_page()

    # Top accent bar
    pdf.set_fill_color(*PDFColors.COVER_ACCENT)
    pdf.rect(0, 0, PDFLayout.PAGE_WIDTH, 8, "F")

    # Vertical center — game title
    pdf.set_y(70)
    pdf.set_font("Helvetica", "B", PDFLayout.COVER_TITLE_SIZE)
    pdf.set_text_color(*PDFColors.COVER_TITLE)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH, 16, game_title,
        align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )

    # Separator line
    y = pdf.get_y() + 4
    pdf.set_draw_color(*PDFColors.COVER_ACCENT)
    pdf.set_line_width(1.5)
    mid = PDFLayout.PAGE_WIDTH / 2
    pdf.line(mid - 40, y, mid + 40, y)
    pdf.ln(8)

    # Tagline
    pdf.set_font("Helvetica", "I", PDFLayout.COVER_TAGLINE_SIZE)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH, 10, tagline,
        align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.ln(12)

    # Genre / Platform / Audience line
    pdf.set_font("Helvetica", size=10)
    pdf.set_text_color(*PDFColors.CAPTION)
    meta = f"{genre}  ·  {platform}  ·  {audience}"
    pdf.cell(PDFLayout.CONTENT_WIDTH, 6, meta, align="C",
             new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(30)

    # Studio and document info block
    pdf.set_font("Helvetica", "B", 11)
    pdf.set_text_color(*PDFColors.COVER_TITLE)
    pdf.cell(PDFLayout.CONTENT_WIDTH, 7, studio_name, align="C",
             new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.set_font("Helvetica", size=10)
    pdf.set_text_color(*PDFColors.BODY)
    pdf.cell(PDFLayout.CONTENT_WIDTH, 6, f"Game Design Document  ·  {version}  ·  {date}",
             align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(15)

    # Confidentiality notice
    pdf.set_font("Helvetica", "I", 8)
    pdf.set_text_color(*PDFColors.MID_GREY)
    confidential = (
        "CONFIDENTIAL — For internal use and authorized partners only. "
        "Do not distribute without written permission."
    )
    pdf.multi_cell(
        PDFLayout.CONTENT_WIDTH, 5, confidential,
        align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )

    # Bottom accent bar
    pdf.set_fill_color(*PDFColors.COVER_ACCENT)
    pdf.rect(0, PDFLayout.PAGE_HEIGHT - 8, PDFLayout.PAGE_WIDTH, 8, "F")
