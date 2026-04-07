---
name: test
description: 通用测试工程技能。提供测试用例生成、测试执行、HTML报告生成、测试覆盖策略等能力。触发条件：用户提及"测试"、"编写测试"、"test"、"测试报告"、"生成测试用例"、"执行测试"、"/test"命令时触发。
---


  包含内容：
  - 测试用例生成：根据代码分析生成Python测试文件
  - 测试执行：远程/本地执行，支持分层测试
  - HTML报告：生成可视化测试报告（支持上传到MinIO/S3等）
  - 测试覆盖策略：按模块优先级、分类、标记执行
  - 断言设计规范：严格的断言模式
# 通用测试工程技能

## 功能概览

1. **测试用例生成** - 分析代码结构，生成符合 pytest 规范的 Python 测试文件
2. **测试执行** - 支持本地/远程执行，分层测试（单元/集成/端到端）
3. **HTML报告生成** - 生成可视化报告，支持上传到对象存储
4. **测试覆盖策略** - 按优先级、分类、标记执行测试

---

## 核心原则

1. **断言必须严格** - 验证具体字段、类型、业务逻辑，禁止 `!= None` 式的宽松断言
2. **测试覆盖率优先** - 先检查是否有测试，再决定生成还是复用
3. **真实环境测试** - 集成测试使用真实配置，不进行不必要的 Mock
4. **测试前同步代码** - 远程执行时确保代码是最新的

---

## 1. 测试用例生成

### 执行步骤

1. **分析代码结构**
   - 识别模块类型（工具/Agent/服务）
   - 确定公开接口和参数
   - 分析输入输出类型

2. **生成测试文件**

生成符合 pytest 规范的测试文件：

```python
import pytest
import uuid
from typing import Any


class Test{ModuleName}:
    """模块测试类"""

    @pytest.fixture
    def chat_id(self):
        """生成独立chat_id"""
        return f"test_{uuid.uuid4().hex[:8]}"

    def test_{case_name}(self, chat_id: str):
        """
        测试用例: {description}
        模式: {mode}
        优先级: {priority}
        """
        # Given: 准备测试环境
        # When: 执行被测函数
        # Then: 验证结果

        assert result is not None, "结果不能为空"
        # 使用具体断言，不要只检查 != None
```

3. **断言设计规范**

✅ **正确的断言**：
```python
# 1. 验证返回值结构
assert isinstance(result, dict), "必须返回字典"

# 2. 验证核心字段存在
assert "id" in result, "必须包含id字段"
assert "data" in result, "必须包含data字段"

# 3. 验证字段类型
assert isinstance(result["id"], str), "id必须是str类型"
assert isinstance(result["score"], (int, float)), "score必须是数值"

# 4. 验证业务逻辑
assert result["score"] >= 0, "score必须非负"
assert 0 <= result["score"] <= 1, "score必须在0-1之间"

# 5. 验证边界条件
assert len(result) <= top_k, "结果数量不能超过top_k"
```

❌ **禁止的断言**：
```python
assert result is not None          # ❌ 太宽松
assert len(result) > 0             # ❌ 缺少具体验证
assert hasattr(result, 'field')    # ❌ 不验证实际值
if result: pass                   # ❌ 不验证内容
```

### 测试文件结构

```
tests/
├── tools/                      # 工具测试
│   └── test_{module}.py
├── agents/                     # Agent测试
│   └── test_{agent}.py
├── integration/                # 集成测试
│   └── test_{feature}.py
└── conftest.py                 # pytest配置和fixtures
```

### pytest 标记

```python
@pytest.mark.unit              # 单元测试（快速，可本地执行）
@pytest.mark.integration       # 集成测试（需要真实环境）
@pytest.mark.slow              # 慢速测试
@pytest.mark.remote            # 需要远程执行
```

---

## 2. 测试执行

### 远程执行

```bash
# 1. 同步代码
scp -P 2223 <file> user@host:/path/to/project/

# 2. 执行特定测试
ssh user@host -p 2223 "cd /path/to/project && python3 -m pytest tests/<path> -v"

# 3. 执行带标记的测试
ssh user@host -p 2223 "cd /path/to/project && python3 -m pytest tests/ -v -m 'unit'"
```

### 本地执行

```bash
# 单元测试（快速）
pytest tests/ -v -m "unit"

# 集成测试（需要环境）
pytest tests/ -v -m "integration"

# 跳过慢速测试
pytest tests/ -v -m "not slow"

# 执行特定文件
pytest tests/tools/test_module.py -v
```

### 分层测试

| 层级 | 标记 | 说明 | 执行频率 |
|------|------|------|----------|
| Layer 1 | @pytest.mark.unit | 工具/Agent单元测试 | 每次PR |
| Layer 2 | @pytest.mark.integration | 集成测试 | 每日回归 |
| Layer 3 | @pytest.mark.e2e | 端到端测试 | 每周完整测试 |

---

## 3. HTML报告生成

### 使用方法

```python
from tests.framework.report_generator import ReportGenerator, generate_test_report

# 简单用法
result = generate_test_report(test_results, upload=True)
print(result['url'])  # 直接返回可访问的URL

# 自定义用法
generator = ReportGenerator(minio_config={
    "endpoint": "192.168.110.69:9000",
    "access_key": "minioadmin",
    "secret_key": "minioadmin",
    "bucket_name": "chat",
})
html = generator.generate_html_report(summary, details)
url = generator.upload_to_minio(html)
print(url)
```

### 报告内容

完整版报告包含：
- 测试摘要（总数/通过/失败/通过率）
- 按分类统计（条形图）
- 详细结果表（可过滤）
- 失败详情（错误信息和堆栈）
- 工具调用链（tool_calls）
- LLM思考链（thought_chain）
- 断言详情（逐条结果）

### 报告访问

报告生成后可选择：
1. **上传到对象存储**：返回直接可访问的 URL
2. **保存到本地**：生成 HTML 文件供下载
3. **scp 传输**：从远程服务器下载到本地

---

## 4. 测试覆盖策略

### 策略配置文件

通过 `tests/test_strategy.yaml` 配置：

```yaml
focus_modules:
  - module: "data.processing"
    priority: "P0"
    reason: "核心数据处理"

test_modes:
  unit: true
  integration: true
  e2e: false

strategy:
  continue_on_fail: true
  retry_failed: 1
  timeout: 300
```

### 执行策略

| 策略项 | 说明 | 默认值 |
|--------|------|--------|
| continue_on_fail | 失败时继续执行 | true |
| retry_failed | 失败重试次数 | 1 |
| timeout | 单个测试超时(秒) | 300 |

### 模块分类

| 分类 | 说明 |
|------|------|
| data.* | 数据处理模块 |
| file.* | 文件系统模块 |
| network.* | 网络通信模块 |
| agent.* | Agent模块 |
| execution.* | 执行环境模块 |

### 优先级

| 优先级 | 说明 | 执行条件 |
|--------|------|----------|
| P0 | 核心功能 | 任何测试前先执行 |
| P1 | 重要功能 | 常规测试执行 |
| P2 | 一般功能 | 完整测试时执行 |

---

## 5. 测试用例模板

### 基础测试类模板

```python
# -*- coding: utf-8 -*-
"""
{module_name} 模块测试
"""

import pytest
import uuid
from typing import Any


class Test{ModuleName}:
    """{module_name} 模块测试类"""

    @pytest.fixture
    def test_id(self):
        """生成测试ID"""
        return f"test_{uuid.uuid4().hex[:8]}"

    def test_{case_name}(self, test_id: str):
        """
        测试用例: {description}
        """
        # Given: 准备测试环境
        # When: 执行被测功能
        # Then: 验证结果
        pass

    def test_{case_name}_with_invalid_input(self, test_id: str):
        """测试无效输入"""
        with pytest.raises(ValueError, match=".*"):
            pass
```

### 参数化测试

```python
@pytest.mark.parametrize("input,expected", [
    ("valid_input", "expected_result"),
    ("another_input", "another_result"),
])
def test_with_params(input, expected):
    assert process(input) == expected
```

### 异步测试

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation():
    result = await async_function()
    assert result is not None
```

---

## 快速命令

### 生成测试并执行
```bash
# 分析代码生成测试
# ... (根据项目具体工具执行)

# 执行测试
pytest tests/ -v
```

### 生成报告
```python
from tests.framework.report_generator import generate_test_report
result = generate_test_report(results)
print(result['url'])
```

### 按策略执行
```bash
# 按优先级执行
pytest tests/ -v -k "P0 or P1"

# 按模块执行
pytest tests/ -v -k "data_processing"
```

---

## 注意事项

1. **断言要具体**：验证字段、类型、值，不要只检查 `!= None`
2. **测试要独立**：每个测试用例应该独立运行，不依赖其他测试
3. **准备测试数据**：使用 fixtures 管理测试数据
4. **记录失败原因**：详细记录失败信息，便于调试
5. **定期清理**：删除过时的测试用例