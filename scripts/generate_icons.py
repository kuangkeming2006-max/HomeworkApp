"""Reproducible monochrome app icon artwork. Pillow is a development-only renderer."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "Resources/Assets.xcassets/AppIcon.appiconset"


def render(background, foreground, filename):
    scale = 3
    image = Image.new("RGB", (1024 * scale, 1024 * scale), background)
    draw = ImageDraw.Draw(image)

    def line(points, width):
        coordinates = [(x * scale, y * scale) for x, y in points]
        draw.line(coordinates, fill=foreground, width=width * scale, joint="curve")
        radius = width * scale / 2
        for x, y in coordinates:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=foreground)

    draw.rounded_rectangle((250 * scale, 170 * scale, 774 * scale, 854 * scale), radius=66 * scale,
                           outline=foreground, width=44 * scale)
    line([(360, 337), (658, 337)], 32)
    line([(360, 438), (564, 438)], 32)
    line([(356, 648), (458, 744), (659, 544)], 48)
    image.resize((1024, 1024), Image.Resampling.LANCZOS).save(TARGET / filename)


def main():
    TARGET.mkdir(parents=True, exist_ok=True)
    render("#FAFAFA", "#101010", "icon.png")
    render("#101010", "#FAFAFA", "icon-dark.png")
    render("#000000", "#FFFFFF", "icon-tinted.png")
    images = []
    for filename, appearance in [("icon.png", None), ("icon-dark.png", "dark"), ("icon-tinted.png", "tinted")]:
        value = dict(filename=filename, idiom="universal", platform="ios", size="1024x1024")
        if appearance:
            value["appearances"] = [dict(appearance="luminosity", value=appearance)]
        images.append(value)
    (TARGET / "Contents.json").write_text(json.dumps(dict(images=images, info=dict(author="xcode", version=1)), indent=2) + "\n")


if __name__ == "__main__":
    main()
