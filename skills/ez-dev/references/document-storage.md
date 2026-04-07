# 文档存储规则

★ Insight ─────────────────────────────────────
 superpower skill 产出的文档必须存储在 `.dev_doc/<feature>/` 对应路径下，禁止在其他位置存储开发文档。
 这样可以避免文档散落，便于追溯和维护。
─────────────────────────────────────────────────

---

## 统一存储位置规则

所有涉及 superpower skill 的输出文档，**必须存储在 `.dev_doc/<feature>/` 对应路径下**：

| 文档类型 | 存储路径 | 说明 |
|----------|----------|------|
| 需求文档 | `.dev_doc/<feature>/` | brainstorming 产出 |
| 需求确认 | `.dev_doc/<feature>/requirement.md` | 用户批准的需求文档 |
| 方案自审报告 | `.dev_doc/<feature>/design-review.md` | Phase 1.5 自审产出 |
| 设计文档 | `.dev_doc/<feature>/design.md` | Phase 2 产出 |
| 实现计划 | `.dev_doc/<feature>/plan.md` | Phase 3 产出 |
| 状态追踪 | `.dev_doc/<feature>/status.md` | Phase 状态锚点 |
| 测试报告 | `.dev_doc/<feature>/test-report.md` | Phase 5.1 测试结果 |
| 开发总结 | `.dev_doc/<feature>/summary.md` | Phase 6 完成时产出 |

---

## 禁止事项

- ❌ 禁止在根目录（如 `README.md`）存储开发文档
- ❌ 禁止在 worktree 外存储开发文档
- ❌ 禁止使用公共的 `.dev_doc/status.md`（多功能并行会相互覆盖）
- ❌ 禁止在其他位置（如 `/tmp`、用户目录）临时存储

---

## 引用方式

在 SKILL.md 各 Phase 中，统一引用本规则：

```
⚠️ 文档存储规则 — 参见 `references/document-storage.md`
```

无需重复完整规则，只需引用即可。
