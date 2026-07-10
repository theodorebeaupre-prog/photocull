# PhotoCull app icon — Icon Composer layers

Concept: **"The sorted stack"** — a fanned stack of photos with the keeper on
top, marked by the green check (the same green as keep decisions in the app).

Four flat SVG layers, 1024×1024 full-bleed. Icon Composer applies the squircle
mask, Liquid Glass materials, shadows and the dark/clear/tinted variants — that
is why the layers carry **no baked shadows or highlights**.

## Assembly in Icon Composer

1. New macOS icon document.
2. Drag the layers in, bottom → top:
   1. `01-background.svg` — or skip it and use Composer's built-in gradient
      picker with the same stops: `#6366F1` → `#8B5CF6`, 135°.
   2. `02-cards-back.svg`
   3. `03-card-top.svg`
   4. `04-badge-check.svg`
3. Suggested settings:
   - `02` + `03` in one group with a subtle **specular** and small shadow —
     the cards should feel like stacked glass plates.
   - `04` (badge) as its own top group with the strongest specular — it's the
     focal point.
   - Check the **dark** and **tinted** previews: the white card and green
     badge must stay legible; if the tinted mode washes out the check, mark
     the badge layer's fill as untinted/fixed.
4. Export as `AppIcon.icon` into the Xcode project root, then in `project.yml`
   keep `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` (Xcode 26 compiles
   `.icon` files directly).

## Palette

| Element | Hex |
|---|---|
| Background gradient | `#6366F1` → `#8B5CF6` |
| Back card (deep) | `#C7CDF9` |
| Back card (mid) | `#E4E7FC` |
| Top card | `#FFFFFF` |
| Photo sky | `#DBEAFE` |
| Sun | `#FCD34D` |
| Mountains | `#64748B` |
| Keeper badge | `#34C759` (Apple system green) |
