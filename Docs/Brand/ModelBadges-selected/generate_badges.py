#!/usr/bin/env python3
"""Generate the approved abbreviation-first Prompt Dock model badges."""

from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parent

MODELS = [
    # Image models
    ("GPT", "GPT Image", "#84D8C4"),
    ("NB", "Nano Banana", "#EACB62"),
    ("MJ", "Midjourney", "#8DB6E8"),
    ("FX", "FLUX", "#C895E8"),
    ("SR", "Seedream", "#E99675"),
    ("ID", "Ideogram", "#83C8A0"),
    ("GRK", "Grok Imagine", "#D899B8"),
    ("QW", "Qwen Image", "#849EED"),
    ("SD", "Stable Diffusion", "#87C3CC"),
    ("RC", "Recraft", "#78BE98"),
    ("PHX", "Phoenix", "#E69A71"),
    ("LO", "Lucid Origin", "#B493E1"),
    ("FFI", "Firefly Image", "#EB8A69"),

    # Video models
    ("VEO", "Veo", "#70CCAA"),
    ("KL", "Kling", "#E9A35D"),
    ("SE", "Seedance", "#E87988"),
    ("RW", "Runway Gen", "#9D95E9"),
    ("HL", "Hailuo", "#65B9DD"),
    ("RAY", "Luma Ray", "#EAC664"),
    ("WAN", "Wan", "#8DC979"),
    ("FFV", "Firefly Video", "#E87963"),
    ("PK", "Pika", "#E89AAC"),
    ("PV", "PixVerse", "#879FE8"),
    ("VD", "Vidu", "#72C4D1"),
    ("HY", "Hunyuan Video", "#80B6E5"),
    ("LTX", "LTX Video", "#A58BE0"),

    # Audio and voice models
    ("SU", "Suno", "#E99B5A"),
    ("UD", "Udio", "#8D89E9"),
    ("EM", "Eleven Music", "#70BFAE"),
    ("LY", "Lyria", "#D889B6"),
    ("SA", "Stable Audio", "#82BDC8"),
    ("MMS", "MiniMax Speech", "#E58D84"),
    ("MMM", "MiniMax Music", "#E8A76B"),
    ("FA", "Fish Audio", "#68B8D0"),
    ("SON", "Cartesia Sonic", "#85C596"),
    ("PD", "PlayDialog", "#988EE5"),
    ("MF", "Murf Falcon", "#76BBAA"),
    ("E11", "Eleven v3", "#72C6B7"),
]


def font_size(code: str) -> int:
    return 38 if len(code) == 2 else 32


def badge_body(code: str, accent: str, prefix: str = "") -> str:
    size = font_size(code)
    spacing = "-1.2" if len(code) == 2 else "-1.4"
    return f'''<defs>
    <linearGradient id="{prefix}surface" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#292C2F"/>
      <stop offset="0.56" stop-color="#17191B"/>
      <stop offset="1" stop-color="#0B0C0D"/>
    </linearGradient>
    <linearGradient id="{prefix}accent" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{accent}" stop-opacity="0.88"/>
      <stop offset="1" stop-color="{accent}"/>
    </linearGradient>
  </defs>
  <rect width="128" height="128" rx="35" fill="url(#{prefix}surface)"/>
  <rect x="0.75" y="0.75" width="126.5" height="126.5" rx="34.25"
        fill="none" stroke="#FFFFFF" stroke-opacity="0.15" stroke-width="1.5"/>
  <text x="64" y="75" text-anchor="middle"
        font-family="SF Pro Display, SF Pro Text, Helvetica Neue, Arial, sans-serif"
        font-size="{size}" font-weight="750" letter-spacing="{spacing}"
        fill="#F7F7F4">{escape(code)}</text>
  <rect x="46" y="95" width="36" height="4" rx="2" fill="url(#{prefix}accent)"/>'''


def badge_svg(code: str, accent: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 128 128">
  {badge_body(code, accent)}
</svg>
'''


def review_svg() -> str:
    width = 1600
    rows = (len(MODELS) + 4) // 5
    height = 196 + rows * 232 + 96
    items = []
    for index, (code, name, accent) in enumerate(MODELS):
        col = index % 5
        row = index // 5
        x = 86 + col * 300
        y = 196 + row * 232
        items.append(f'''<g transform="translate({x} {y})">
          <g transform="scale(1.09375)">{badge_body(code, accent, f"m{index}-")}</g>
          <text x="70" y="172" text-anchor="middle"
                font-family="SF Pro Text, Helvetica Neue, Arial, sans-serif"
                font-size="18" font-weight="700" fill="#1C1D1F">{escape(name)}</text>
          <text x="70" y="198" text-anchor="middle"
                font-family="SF Pro Text, Helvetica Neue, Arial, sans-serif"
                font-size="12" font-weight="650" letter-spacing="1.2" fill="{accent}">{escape(code)}</text>
        </g>''')

    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
      <defs>
        <linearGradient id="page" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#F8F8F9"/>
          <stop offset="1" stop-color="#ECEDEF"/>
        </linearGradient>
      </defs>
      <rect width="{width}" height="{height}" fill="url(#page)"/>
      <text x="72" y="76" font-family="SF Pro Display, SF Pro Text, Helvetica Neue, Arial, sans-serif"
            font-size="34" font-weight="760" fill="#17181A">Prompt Dock · Model Badges</text>
      <text x="72" y="116" font-family="SF Pro Text, Helvetica Neue, Arial, sans-serif"
            font-size="17" font-weight="530" fill="#75797E">缩写优先 · 统一结构 · {len(MODELS)} 个模型家族 · 不含聚合平台</text>
      {''.join(items)}
      <text x="72" y="{height - 44}" font-family="SF Pro Text, Helvetica Neue, Arial, sans-serif"
            font-size="13" font-weight="600" fill="#85898E">Prompt Dock / Selected model badge system</text>
      <text x="1528" y="{height - 44}" text-anchor="end" font-family="SF Pro Text, Helvetica Neue, Arial, sans-serif"
            font-size="13" font-weight="650" fill="#A0A3A7">{len(MODELS)} / MODELS</text>
    </svg>
'''


def main() -> None:
    for code, _, accent in MODELS:
        if code == "GPT":
            continue
        (ROOT / f"{code}.svg").write_text(badge_svg(code, accent), encoding="utf-8")
    (ROOT / "ModelBadges-selected-review.svg").write_text(review_svg(), encoding="utf-8")
    print(f"Generated or refreshed {len(MODELS) - 1} badges and one review sheet")


if __name__ == "__main__":
    main()
