# Proposal: CLAUDE.md section 4, palette v4 (for VU to approve)

CLAUDE.md was NOT edited. The T-028 art uses palette v4 (112 colors, a strict superset of palette v3 with 64 colors, which is a superset of the 32-color v2 set; see shared/style-bible/pixel-cozy-v4.md). This proposal replaces the earlier palette v3 proposal.

## Current text (section 4, "Mỹ thuật và VFX")
```
- Mỹ thuật và VFX: tuân theo style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc: bảng màu khóa 47 màu, nền 640x360 scale nguyên, hướng sáng từ trên trái, animation chỉnh thời lượng từng frame, VFX 3 lớp Flash/Core/Residue).
```

## Proposed replacement
```
- Mỹ thuật và VFX: tuân theo style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc, phong cách cozy modern pixel: palette v4, 112 màu, xem shared/style-bible/pixel-cozy-v4.md; nền 640x360 scale nguyên, hướng sáng từ trên trái, animation chỉnh thời lượng từng frame, VFX 3 lớp Flash/Core/Residue).
```

The sentence "Mọi asset phải qua bước ép bảng màu trước khi nhập vào dự án." needs no wording change: `tools/check_palette.gd` now validates the 112-color set, that colors 1-64 still equal v3 (and 1-32 equal v2), that every generated PNG uses only those colors, and that alpha is binary.

Note: the shipped pixel-office game used a 32-color palette (palette-v2.json) before T-022; the "47" in CLAUDE.md predates it.
