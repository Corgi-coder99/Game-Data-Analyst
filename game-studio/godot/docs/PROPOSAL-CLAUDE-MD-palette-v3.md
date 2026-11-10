# Proposal: CLAUDE.md section 4, palette v3 (for VU to approve)

CLAUDE.md was NOT edited. The T-022 art uses palette v3 (64 colors, a strict superset of the 32-color v2 set; see shared/style-bible/pixel-office-v3.md).

## Current text (section 4, "Mỹ thuật và VFX")
```
- Mỹ thuật và VFX: tuân theo style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc: bảng màu khóa 47 màu, nền 640x360 scale nguyên, hướng sáng từ trên trái, animation chỉnh thời lượng từng frame, VFX 3 lớp Flash/Core/Residue).
```

## Proposed replacement
```
- Mỹ thuật và VFX: tuân theo style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc: palette v3, 64 màu, xem shared/style-bible/pixel-office-v3.md; nền 640x360 scale nguyên, hướng sáng từ trên trái, animation chỉnh thời lượng từng frame, VFX 3 lớp Flash/Core/Residue).
```

The sentence "Mọi asset phải qua bước ép bảng màu trước khi nhập vào dự án." needs no wording change: `tools/check_palette.gd` now validates the 64-color set and that colors 1-32 still equal v2.

Note: the shipped pixel-office game used a 32-color palette (palette-v2.json); the "47" in CLAUDE.md predates it.
