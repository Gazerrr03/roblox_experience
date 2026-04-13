"""
section_registry.py
-------------------
Canonical registry of all 19 GDD sections with metadata for ordering,
validation, and document generation. Import this in all generator scripts.
"""

import re
from typing import TypedDict, List, Optional


class SectionDef(TypedDict):
    name: str
    order: int
    required: bool
    min_words: int
    recommended_words: str  # e.g. "400-600"
    key_elements: List[str]
    template_file: Optional[str]
    genre_adaptations: dict  # genre -> notes
    skip_conditions: List[str]  # conditions under which section is omitted


SECTIONS: dict[str, SectionDef] = {
    "cover_page": {
        "name": "Cover Page",
        "order": 1,
        "required": True,
        "min_words": 0,
        "recommended_words": "N/A",
        "key_elements": [
            "game_title",
            "tagline",
            "genre_platform_audience",
            "version_number",
            "document_date",
            "studio_name",
            "lead_designers",
            "confidentiality_notice",
            "version_history_table",
        ],
        "template_file": "assets/cover_page_spec.md",
        "genre_adaptations": {},
        "skip_conditions": [],
    },
    "executive_summary": {
        "name": "Executive Summary",
        "order": 2,
        "required": True,
        "min_words": 200,
        "recommended_words": "400-600",
        "key_elements": [
            "elevator_pitch",
            "unique_value_proposition",
            "at_a_glance_table",
            "comparable_titles",
            "team_overview",
            "market_gap_statement",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "mobile_f2p": "Emphasize D1/D7/D30 retention targets and monetization KPIs",
            "esports": "Emphasize competitive scene potential and spectator support",
        },
        "skip_conditions": [],
    },
    "game_overview": {
        "name": "Game Overview",
        "order": 3,
        "required": True,
        "min_words": 400,
        "recommended_words": "600-1000",
        "key_elements": [
            "high_concept_statement",
            "core_fantasy",
            "experience_pillars",
            "session_flow_narrative",
            "comparable_titles_analysis",
            "target_demographic",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "narrative": "Expand experience pillars to include story pillars",
            "mobile": "Emphasize session length targets",
        },
        "skip_conditions": [],
    },
    "core_gameplay_loop": {
        "name": "Core Gameplay Loop",
        "order": 4,
        "required": True,
        "min_words": 500,
        "recommended_words": "800-1500",
        "key_elements": [
            "micro_loop",
            "macro_loop",
            "meta_loop",
            "loop_diagrams",
            "session_length_target",
            "engagement_hooks",
            "loop_failure_states",
            "loop_onboarding",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "idle": "Meta loop becomes primary focus; micro loop is minimal",
            "roguelike": "Death-and-restart is part of the loop; document meta-progression",
            "mobile": "Micro loop must fit 8-12 minute session target",
        },
        "skip_conditions": [],
    },
    "game_mechanics": {
        "name": "Game Mechanics",
        "order": 5,
        "required": True,
        "min_words": 800,
        "recommended_words": "1500-3000",
        "key_elements": [
            "primary_interaction_mechanic",
            "movement_system",
            "resource_management",
            "upgrade_modification_mechanic",
            "social_interaction_mechanic",
            "economy_transaction_mechanic",
            "procedural_systems",
        ],
        "template_file": "templates/mechanics_specification_template.md",
        "genre_adaptations": {
            "action": "Combat timing and input windows are critical — spec every frame",
            "strategy": "Decision trees and information availability are the core mechanic",
            "narrative": "Dialogue and choice systems are core mechanics",
            "idle": "Mechanic is minimal; focus on progression triggers",
        },
        "skip_conditions": [],
    },
    "progression_system": {
        "name": "Progression System",
        "order": 6,
        "required": True,
        "min_words": 400,
        "recommended_words": "800-1500",
        "key_elements": [
            "progression_hierarchy",
            "xp_earn_rates_per_archetype",
            "time_to_milestone_table",
            "power_curve",
            "xp_formula",
            "content_gates",
            "catch_up_mechanisms",
            "prestige_endgame",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "arcade": "Progression is score-based, not level-based; simplify section",
            "mobile_f2p": "Progression gates drive monetization; document conversion touch points",
            "roguelike": "Per-run progression vs meta-progression — document both separately",
        },
        "skip_conditions": ["arcade_no_progression"],
    },
    "content_design": {
        "name": "Content Design",
        "order": 7,
        "required": True,
        "min_words": 400,
        "recommended_words": "800-1500",
        "key_elements": [
            "content_scope_overview",
            "levels_zones_worlds",
            "enemy_npc_types",
            "items_equipment",
            "abilities_skills",
            "procedural_content_rules",
            "content_creation_guidelines",
            "launch_content_minimum",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "procedural": "Document generation rules and seed systems",
            "narrative": "Expand level design to include narrative beats per level",
        },
        "skip_conditions": [],
    },
    "narrative_world": {
        "name": "Narrative & World",
        "order": 8,
        "required": False,
        "min_words": 50,
        "recommended_words": "500-1200",
        "key_elements": [
            "setting_overview",
            "lore_depth_classification",
            "story_structure",
            "key_characters",
            "narrative_gameplay_integration",
            "worldbuilding_constraints",
            "writing_tone_guide",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "narrative": "Expand to full story bible; include branching dialogue specification",
            "arcade": "Single paragraph stating narrative is minimal",
            "sports": "Setting is real-world; focus on presentation and commentary style",
        },
        "skip_conditions": ["narrative_none"],
    },
    "ux_interface": {
        "name": "User Experience & Interface",
        "order": 9,
        "required": True,
        "min_words": 400,
        "recommended_words": "800-1500",
        "key_elements": [
            "screen_inventory",
            "ftue_flow",
            "hud_layout",
            "navigation_hierarchy",
            "accessibility_requirements",
        ],
        "template_file": "templates/ux_flow_template.md",
        "genre_adaptations": {
            "mobile": "Thumb zones, portrait/landscape, gesture controls are mandatory",
            "vr": "Spatial UI replaces flat UI; comfort guidelines required",
            "console": "Controller navigation, platform UI guidelines (PS/Xbox/Switch)",
        },
        "skip_conditions": [],
    },
    "art_direction": {
        "name": "Art Direction",
        "order": 10,
        "required": True,
        "min_words": 300,
        "recommended_words": "500-800",
        "key_elements": [
            "visual_style_statement",
            "visual_influences",
            "color_palette",
            "character_art_guidelines",
            "environment_art_guidelines",
            "ui_art_style",
            "animation_style",
            "do_not_create_list",
        ],
        "template_file": "templates/art_direction_template.md",
        "genre_adaptations": {
            "vr": "Add comfort guidelines: motion sickness considerations for art choices",
            "mobile": "Performance constraints limit visual complexity; document poly budget",
        },
        "skip_conditions": [],
    },
    "audio_design": {
        "name": "Audio Design",
        "order": 11,
        "required": True,
        "min_words": 150,
        "recommended_words": "300-500",
        "key_elements": [
            "music_direction",
            "sfx_philosophy",
            "voice_acting_scope",
            "adaptive_audio",
            "audio_budget",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "rhythm": "Audio is core mechanic; this section triples in length",
            "esports": "Competitive audio clarity is critical; callout audio spec required",
        },
        "skip_conditions": [],
    },
    "multiplayer_design": {
        "name": "Multiplayer Design",
        "order": 12,
        "required": False,
        "min_words": 400,
        "recommended_words": "800-2000",
        "key_elements": [
            "network_model",
            "tick_rate",
            "matchmaking_system",
            "lobby_party_system",
            "social_features",
            "anti_cheat",
            "platform_requirements",
            "latency_tolerance",
            "disconnect_handling",
        ],
        "template_file": "templates/technical_requirements_template.md",
        "genre_adaptations": {
            "competitive": "Ranked ladder, MMR system, seasonal resets — all required",
            "coop": "Async vs sync co-op distinction; difficulty scaling with player count",
            "mmo": "Expand into full MMO social architecture document",
        },
        "skip_conditions": ["single_player_only"],
    },
    "monetization_strategy": {
        "name": "Monetization Strategy",
        "order": 13,
        "required": True,
        "min_words": 300,
        "recommended_words": "600-1200",
        "key_elements": [
            "revenue_model_selection",
            "player_segment_revenue_model",
            "iap_catalog",
            "premium_currency_rates",
            "battle_pass_structure",
            "ethical_guidelines",
            "regional_pricing",
            "kpi_targets",
        ],
        "template_file": "templates/monetization_strategy_template.md",
        "genre_adaptations": {
            "premium": "Simplify to price point, DLC strategy, sale cadence",
            "mobile_f2p": "Expand to 4+ pages; live ops events monetization required",
            "esports": "Battle pass + cosmetics only; no gameplay advantages",
        },
        "skip_conditions": [],
    },
    "economy_design": {
        "name": "Economy Design",
        "order": 14,
        "required": False,
        "min_words": 300,
        "recommended_words": "600-1200",
        "key_elements": [
            "currency_types",
            "faucet_sink_balance",
            "daily_earn_rates",
            "pricing_architecture",
            "inflation_risk_assessment",
            "exchange_rate_design",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "idle": "Economy is the entire game; expand to 8+ pages",
            "mmo": "Gold sink/faucet economy with player-driven market — complex document",
        },
        "skip_conditions": ["premium_no_economy"],
    },
    "technical_requirements": {
        "name": "Technical Requirements",
        "order": 15,
        "required": True,
        "min_words": 300,
        "recommended_words": "500-1000",
        "key_elements": [
            "engine_selection",
            "platform_targets",
            "hardware_specifications",
            "network_architecture",
            "third_party_services",
            "analytics_events",
            "build_pipeline",
            "technical_risks",
        ],
        "template_file": "templates/technical_requirements_template.md",
        "genre_adaptations": {
            "mobile": "Battery, thermal, and data usage specs required",
            "vr": "90Hz minimum, reprojection policy, comfort specs",
        },
        "skip_conditions": [],
    },
    "competitive_analysis": {
        "name": "Competitive Analysis",
        "order": 16,
        "required": True,
        "min_words": 400,
        "recommended_words": "600-1000",
        "key_elements": [
            "competitor_identification",
            "competitor_profiles",
            "feature_comparison_matrix",
            "positioning_map",
            "market_gap_analysis",
            "differentiation_statement",
            "lessons_learned",
            "market_timing",
        ],
        "template_file": "templates/competitive_analysis_template.md",
        "genre_adaptations": {},
        "skip_conditions": [],
    },
    "development_roadmap": {
        "name": "Development Roadmap",
        "order": 17,
        "required": True,
        "min_words": 200,
        "recommended_words": "400-800",
        "key_elements": [
            "prototype_milestone",
            "vertical_slice_milestone",
            "alpha_milestone",
            "beta_milestone",
            "launch_milestone",
            "post_launch_plan",
            "critical_path",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {
            "live_service": "Post-launch live ops calendar is as important as launch milestone",
        },
        "skip_conditions": [],
    },
    "risk_assessment": {
        "name": "Risk Assessment",
        "order": 18,
        "required": True,
        "min_words": 200,
        "recommended_words": "400-600",
        "key_elements": [
            "risk_register_table",
            "design_risks",
            "technical_risks",
            "market_risks",
            "team_risks",
            "external_risks",
        ],
        "template_file": "templates/gdd_master_structure.md",
        "genre_adaptations": {},
        "skip_conditions": [],
    },
    "appendices": {
        "name": "Appendices",
        "order": 19,
        "required": True,
        "min_words": 100,
        "recommended_words": "As needed",
        "key_elements": [
            "glossary",
            "revision_history",
            "open_questions_log",
        ],
        "template_file": None,
        "genre_adaptations": {},
        "skip_conditions": [],
    },
}


# Ordered list of section keys for document generation
SECTION_ORDER: List[str] = sorted(SECTIONS.keys(), key=lambda k: SECTIONS[k]["order"])


def get_required_sections() -> List[str]:
    """Return list of section keys that are required."""
    return [k for k, v in SECTIONS.items() if v["required"]]


def get_optional_sections() -> List[str]:
    """Return list of section keys that are optional."""
    return [k for k, v in SECTIONS.items() if not v["required"]]


def get_section_for_genre(genre: str) -> List[str]:
    """
    Return an ordered list of section keys appropriate for a given genre.
    Skips sections whose skip_conditions match the genre.

    Args:
        genre: Genre string (e.g., 'mobile_f2p', 'single_player_narrative', 'competitive_fps')

    Returns:
        Ordered list of section keys to include.
    """
    single_player_genres = {"single_player", "narrative", "arcade", "puzzle"}
    premium_no_economy = {"premium_singleplayer", "puzzle_premium"}

    skip = set()

    # Determine skip conditions based on genre
    if any(g in genre.lower() for g in single_player_genres):
        skip.add("single_player_only")

    if any(g in genre.lower() for g in {"premium", "paid"}) and "economy" not in genre.lower():
        skip.add("premium_no_economy")

    if "no_narrative" in genre.lower() or "arcade" in genre.lower():
        skip.add("narrative_none")

    result = []
    for key in SECTION_ORDER:
        section = SECTIONS[key]
        if any(cond in skip for cond in section["skip_conditions"]):
            continue
        result.append(key)

    return result


def validate_gdd_content(content: dict) -> List[str]:
    """
    Validate a GDD content dictionary against the section registry.
    Returns a list of validation warnings.

    Args:
        content: Dict mapping section keys to content strings.

    Returns:
        List of warning strings.
    """
    warnings = []

    for key, section in SECTIONS.items():
        if not section["required"]:
            continue
        if key not in content:
            warnings.append(f"MISSING required section: {section['name']}")
            continue

        section_text = content[key]
        word_count = len(section_text.split())

        if word_count < section["min_words"]:
            warnings.append(
                f"THIN CONTENT in '{section['name']}': "
                f"{word_count} words (minimum: {section['min_words']})"
            )

        for element in section["key_elements"]:
            # Basic check: element name as keyword in content
            element_hint = element.replace("_", " ").lower()
            if element_hint not in section_text.lower():
                warnings.append(
                    f"POSSIBLY MISSING element '{element}' in section '{section['name']}'"
                )

    return warnings


def validate_data_sensibility(content: dict, *, strict: bool = False) -> List[str]:
    """
    Check business-facing sections for numeric claims that lack source or
    assumption markers, and for placeholder patterns that indicate incomplete
    content. Returns warnings for unsourced metrics and placeholders.

    Args:
        content: Dict mapping section keys to content strings.
        strict: If True, treat warnings as errors (callers should check and
                exit non-zero when strict mode is enabled).

    Returns:
        List of warning strings about unsourced claims and placeholders.
    """
    warnings = []
    business_sections = {
        "executive_summary", "monetization_strategy", "economy_design",
        "competitive_analysis", "development_roadmap",
    }

    # Patterns that look like real-world numeric claims
    numeric_patterns = [
        re.compile(r"\$\d+[\d,.]*[BMKbmk]", re.IGNORECASE),  # $15B, $2.5M
        re.compile(r"\d+[\d,.]*\s*(billion|million|thousand)", re.IGNORECASE),
        re.compile(r"\b\d+[%]\s*(retention|conversion|churn|ARPU|ARPPU|DAU|MAU|CCU)", re.IGNORECASE),
        re.compile(r"\bARPU\s*[\$:]?\s*\$?\d+", re.IGNORECASE),
        re.compile(r"\bARPPU\s*[\$:]?\s*\$?\d+", re.IGNORECASE),
        re.compile(r"\bD[17]\d*\s+retention\s+\d+", re.IGNORECASE),
        re.compile(r"\bmarket\s+size\b", re.IGNORECASE),
    ]

    # Patterns that indicate placeholders (not real sources/values)
    placeholder_patterns = [
        re.compile(r"\bSOURCE NEEDED\b", re.IGNORECASE),
        re.compile(r"\$X(\.X)?[BMKbmk]\b"),           # $X.XB, $XB, etc.
        re.compile(r"\bXX[MK]\b"),                     # XXM, XXK
        re.compile(r"\bQ\[X\]\s+20\d{2}\b"),           # Q[X] 202X-like
        re.compile(r"\[X\]"),                           # bracket placeholder
        re.compile(r"\bTBD\b", re.IGNORECASE),
    ]

    source_markers = ["[source:", "[assumption:", "[user-provided:"]

    for key in business_sections:
        if key not in content:
            continue

        section_text = content[key]
        if not isinstance(section_text, str):
            section_text = str(section_text)

        text_lower = section_text.lower()
        has_any_numeric = False
        has_placeholders = any(p.search(section_text) for p in placeholder_patterns)

        for pattern in numeric_patterns:
            matches = pattern.findall(section_text)
            if matches:
                has_any_numeric = True
                break

        if has_any_numeric or has_placeholders:
            if not any(marker in text_lower for marker in source_markers):
                section_name = SECTIONS[key]["name"] if key in SECTIONS else key
                prefix = "STRICT ERROR" if strict else "UNSOURCED METRICS"
                detail = []
                if has_any_numeric:
                    detail.append("numeric business claims")
                if has_placeholders:
                    detail.append("placeholder values")
                warnings.append(
                    f"{prefix} in '{section_name}': "
                    f"Contains {' and '.join(detail)} without [Source: ...] or "
                    f"[Assumption: ...] markers. Add attribution before external use."
                )

    return warnings


def estimate_content_size(content: dict) -> dict:
    """
    Compute rough size indicators for pre-export validation.

    Args:
        content: Dict mapping section keys to content strings.

    Returns:
        Dict with size metrics: total_words, section_count, table_count,
        max_section_words, warnings.
    """
    total_words = 0
    table_count = 0
    max_section_words = 0
    max_section_name = ""
    section_count = 0
    warnings = []

    for key, text in content.items():
        if not isinstance(text, str):
            text = str(text)

        section_count += 1
        words = len(text.split())
        total_words += words
        table_count += text.count("\n|")

        if words > max_section_words:
            max_section_words = words
            max_section_name = key

    if total_words > 50000:
        warnings.append(
            f"LARGE DOCUMENT: {total_words:,} words total. "
            f"PDF rendering may be slow. Consider using DOCX-first workflow."
        )
    if table_count > 50:
        warnings.append(
            f"MANY TABLES: {table_count} tables detected. "
            f"PDF table layout may have formatting issues for wide tables."
        )
    if max_section_words > 8000:
        warnings.append(
            f"LONG SECTION: '{max_section_name}' has {max_section_words:,} words. "
            f"Consider splitting into subsections for readability."
        )

    return {
        "total_words": total_words,
        "section_count": section_count,
        "table_count": table_count,
        "max_section_words": max_section_words,
        "max_section_name": max_section_name,
        "warnings": warnings,
    }


def print_section_outline(sections: Optional[List[str]] = None) -> str:
    """
    Generate a human-readable outline of sections.

    Args:
        sections: List of section keys to include. Defaults to all sections.

    Returns:
        Formatted outline string.
    """
    if sections is None:
        sections = SECTION_ORDER

    lines = ["# GDD Section Outline\n"]
    for key in sections:
        if key not in SECTIONS:
            continue
        s = SECTIONS[key]
        req = "Required" if s["required"] else "Optional"
        lines.append(f"{s['order']:2d}. **{s['name']}** ({req}) — {s['recommended_words']} words")
        for elem in s["key_elements"][:3]:
            lines.append(f"    - {elem.replace('_', ' ').title()}")
        if len(s["key_elements"]) > 3:
            lines.append(f"    - ... +{len(s['key_elements']) - 3} more elements")
        lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    print("=== GDD Section Registry ===\n")
    print(f"Total sections: {len(SECTIONS)}")
    print(f"Required sections: {len(get_required_sections())}")
    print(f"Optional sections: {len(get_optional_sections())}")
    print()
    print(print_section_outline())
