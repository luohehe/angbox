# NeverOB Logo Design Specification

## Brand Overview

**App Name:** NeverOB
**Tagline:** "Stay In Play"
**Meaning:** "Never Out of Bounds" - An AI-powered golf swing analyzer that helps golfers improve accuracy and consistency.

---

## Logo Concept

### Design Philosophy
- **Tech-Forward**: Circuit patterns, clean lines, digital aesthetic
- **Golf DNA**: Golf ball element, green color palette, swing motion
- **Modern & Minimal**: Simple shapes, no clutter, scalable
- **Premium Feel**: Dark backgrounds, gradient accents, subtle glows

### Primary Logo Elements

```
┌─────────────────────────────────────┐
│                              ┌──✓   │  ← Boundary corner (in-bounds indicator)
│                              │      │
│         ╭───────────╮               │
│        ╱  ● ─── ●    ╲              │  ← Tech golf ball with circuit pattern
│       │   │     │     │             │
│       │  ●──●──●──●   │             │
│        ╲     │     ╱               │
│         ╰───────────╯               │
│              │                      │
│         ╭────╯                      │  ← Swing path arc (dashed)
│                                     │
│       Never OB                      │  ← Text: "Never" light, "OB" bold green
│                                     │
└─────────────────────────────────────┘
```

---

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| NeverOB Green | `#00D26A` | rgb(0, 210, 106) | Primary brand, logo, CTAs |
| NeverOB Dark | `#0A1628` | rgb(10, 22, 40) | Backgrounds, contrast |
| NeverOB Teal | `#00BFA5` | rgb(0, 191, 165) | Gradient end, accents |

### Secondary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Pure White | `#FFFFFF` | rgb(255, 255, 255) | Text, highlights |
| Light Gray | `#E0E0E0` | rgb(224, 224, 224) | Secondary text |
| Success | `#4CAF50` | rgb(76, 175, 80) | Positive scores |
| Warning | `#FF9800` | rgb(255, 152, 0) | Medium scores |
| Error | `#F44336` | rgb(244, 67, 54) | Low scores |

### Gradients

```css
/* Primary Gradient */
background: linear-gradient(135deg, #00D26A 0%, #00BFA5 100%);

/* Dark Background */
background: linear-gradient(180deg, #0A1628 0%, #0D1B2A 100%);

/* Glow Effect */
box-shadow: 0 0 40px rgba(0, 210, 106, 0.3);
```

---

## Typography

### Logo Text
- **Font Family:** SF Pro Rounded (iOS) / Inter (fallback)
- **"Never":** Weight 500 (Medium), White/Light
- **"OB":** Weight 700 (Bold), NeverOB Green

### App UI
- **Headers:** SF Pro Rounded Bold
- **Body:** SF Pro Text Regular
- **Scores:** SF Pro Rounded Bold (larger sizes)

---

## App Icon Specifications

### iOS App Icon Sizes

| Size | Usage |
|------|-------|
| 1024×1024 | App Store |
| 180×180 | iPhone @3x |
| 120×120 | iPhone @2x |
| 167×167 | iPad Pro @2x |
| 152×152 | iPad @2x |
| 76×76 | iPad @1x |
| 87×87 | Spotlight @3x |
| 80×80 | Spotlight @2x |
| 60×60 | Notification @3x |
| 40×40 | Notification @2x |

### Icon Design Rules

1. **Corner Radius:** iOS handles automatically (don't include in asset)
2. **Safe Zone:** Keep main elements within 80% of icon area
3. **No Text:** App icon should work without "NeverOB" text at small sizes
4. **Contrast:** Ensure visibility on both light and dark wallpapers

### Icon Composition

```
┌────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  Dark background with subtle grid
│ ▓                ▓ │
│ ▓    ╭──────╮    ▓ │
│ ▓   ╱ ◉──◉  ╲   ▓ │  Tech golf ball (centered)
│ ▓  │  ◉──◉   │  ▓ │
│ ▓   ╲ ◉──◉  ╱   ▓ │
│ ▓    ╰──────╯    ▓ │
│ ▓       ╰─╮      ▓ │  Swing arc
│ ▓         ╰───── ▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└────────────────────┘
        + ┌──✓ corner accent (top-right)
```

---

## Logo Variations

### 1. Primary App Icon
- Dark background
- Tech golf ball centered
- Subtle grid pattern
- Corner "in-bounds" accent

### 2. Horizontal Logo (for headers)
```
[Golf Ball Icon]  Never OB
```

### 3. Stacked Logo (for splash screens)
```
     [Golf Ball Icon]
        Never OB
      Stay In Play
```

### 4. Minimal Icon (for small spaces)
- Circular green gradient
- Simple "N" letter or golf ball silhouette

---

## Usage Guidelines

### Do's ✓
- Use on dark backgrounds for best impact
- Maintain aspect ratio when scaling
- Use official color values
- Allow adequate padding around logo

### Don'ts ✗
- Don't stretch or distort
- Don't change colors
- Don't add effects (shadows, outlines)
- Don't place on busy backgrounds

---

## Implementation

### SwiftUI Reference
See `Theme/NeverOBLogo.swift` for SwiftUI implementation of logo components.

### Export Formats
- **App Icon:** PNG (all iOS sizes)
- **Vector:** SVG for marketing materials
- **Dark/Light:** Provide both versions for different contexts

---

## File Checklist

- [ ] AppIcon.appiconset (all sizes)
- [ ] Logo-horizontal.svg
- [ ] Logo-stacked.svg
- [ ] Logo-icon-only.svg
- [ ] Brand-colors.ase (Adobe Swatch)
- [ ] Style-guide.pdf
